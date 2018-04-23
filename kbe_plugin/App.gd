var Helpers
var Callback
var Dbg
var Event
var Messages
var Bundle
var MemoryStream
var EntityDef
var DataTypes
var Property
var Method
var EntityCall

var _networkInterface = null

var _args = null

enum CLIENT_TYPE {
	#phone, tablet
	CLIENT_TYPE_MOBILE		= 1,
	
	CLIENT_TYPE_WIN			= 2,
	CLIENT_TYPE_LINUX		= 3,
	CLIENT_TYPE_MAC			= 4,
	
	#HTML5/Flash
	CLIENT_TYPE_BROWSER		= 5,
	
	#debug testing bot
	CLIENT_TYPE_BOTS		= 6,
	
	#mini client (lightweight plugin)
	CLIENT_TYPE_MINI		= 7
}

var username = "kbengine"
var password = "123456"

#Whether the local message protocol is being loaded
var loadingLocalMessages_ = false

#Whether the local message protocol has been loaded
var loginappMessageImported_ = false
var baseappMessageImported_ = false
var entitydefImported_ = false
var isImportServerErrorsDescr_ = false

#Server-assigned baseapp address
var baseappIP = ""
var baseappPort = 0

#Current status
var currserver = ""
var currstate = ""

#Bind the account bound to the server for downstream
# login and client upstream login
#This information is extended by the user
var _serverdatas = []
var _clientdatas = []

#Communication protocol encryption, blowfish protocol
var _encryptedKey = []

#Server and client version number and protocol MD5
var serverVersion = ""
var clientVersion = "1.1.5"
var serverScriptVersion = ""
var clientScriptVersion = "0.1.0"
var serverProtocolMD5 = ""
var serverEntitydefMD5 = ""

#Persistent plug-in information, ex: server protocol cache
var _persistentInfos = null

#Current player's entity id/type
var entity_uuid = 0
var entity_id = 0
var entity_type = ""

var _controlledEntities = []

#The current player's last synced position on the server
var _entityServerPos = Vector3(0,0,0)

#space data, spaceData API ref:
#http://kbengine.org/assets/other/kbengine_api.html?search=spaceData
var _spacedatas = {}

#All entities are stored here, entity API ref:
#http://kbengine.org/assets/other/kbengine_api.html#keywords.html#entity
var entities = {}

#We can find the entity through a one-byte index when
# the player View scope is less than 256 entities
var _entityIDAliasIDList = []
var _bufferedCreateEntityMessage = {}

#Describe the error message returned by the server
class ServerErr:
	var name
	var descr
	var id

#Error description corresponding to all server error codes
var serverErrs = {}

var _lastTickTime = OS.get_ticks_msec()
var _lastTickCBTime = OS.get_ticks_msec()
var _lastUpdateToServerTime = OS.get_ticks_msec()

#The id of the player's current space, and the space's
# corresponding resource
var spaceID = 0
var spaceResPath = ""
var isLoadedGeometry = false

#According to the standard, each client part should contain this attribute
var component = "client"

func _init(args):
	Helpers = KBEngine.Helpers
	Callback = Helpers.Callback
	Dbg = KBEngine.Dbg
	Event = KBEngine.Event
	Messages = KBEngine.Messages
	Bundle = KBEngine.Bundle
	MemoryStream = KBEngine.MemoryStream
	EntityDef = KBEngine.EntityDef
	DataTypes = KBEngine.DataTypes
	Property = KBEngine.Property
	Method = KBEngine.Method
	EntityCall = KBEngine.EntityCall
	
	KBEngine.app = self
	_args = args
	
	resetMessages()
	
	initNetwork()
	
	installEvents()
	
	# KBE persistence (cached protocol, entitydef)
	if _args.persistentDataPath != "":
		_persistentInfos = KBEngine.PersistentInfos.new(_args.persistentDataPath)
		
func initNetwork():
	KBEngine.Messages.bindFixedMessage()
	_networkInterface = KBEngine.NetworkInterface.new()

func installEvents():
	Event.registerIn("createAccount", self, "createAccount")
	Event.registerIn("login", self, "login")
	Event.registerIn("reloginBaseapp", self, "reloginBaseapp")
	Event.registerIn("resetPassword", self, "resetPassword")
	Event.registerIn("bindAccountEmail", self, "bindAccountEmail")
	Event.registerIn("newPassword", self, "newPassword")
	
	#internal events:
	Event.registerIn("_closeNetwork", self, "_closeNetwork")

func getInitArgs():
	return _args

func destroy():
	Dbg.WARNING_MSG("KBEngine::destroy()")
	
	reset()
	Event.deregisterIn(self)
	resetMessages()
	
	KBEngine.app = null
	
func networkInterface():
	return _networkInterface
	
func serverdatas():
	return _serverdatas

func entityServerPos(pos):
	_entityServerPos = pos

func resetMessages():
	loadingLocalMessages_ = false
	loginappMessageImported_ = false
	baseappMessageImported_ = false
	entitydefImported_ = false
	isImportServerErrorsDescr_ = false
	serverErrs.clear()
	Messages.clear()
	KBEngine.EntityDef.clear()
	Dbg.DEBUG_MSG("KBEngine::resetMessages()")

func reset():
	Event.clearFiredEvents()
	
	clearEntities(true)
	
	currserver = ""
	currstate = ""
	_serverdatas = []
	serverVersion = ""
	serverScriptVersion = ""
	
	entity_uuid = 0
	entity_id = 0
	entity_type = ""
	
	_entityIDAliasIDList.clear()
	_bufferedCreateEntityMessage.clear()
	
	_lastTickTime = OS.get_ticks_msec()
	_lastTickCBTime = OS.get_ticks_msec()
	_lastUpdateToServerTime = OS.get_ticks_msec()
	
	spaceID = 0
	spaceResPath = ""
	isLoadedGeometry = false
	
	if _networkInterface != null:
		_networkInterface.reset()
	
	_networkInterface = KBEngine.NetworkInterface.new()
	
	_spacedatas.clear()

func process():
	if _networkInterface != null:
		_networkInterface.process()
	
	#handle events thrown in by render layer
	Event.processInEvents()
	
	#Send heartbeat to server and synchronize character
	# information to server
	sendTick()

#Current player entity
func player():
	if entities.has(entity_id):
		return entities[entity_id]
	else:
		return null

func _closeNetwork(networkInterface):
	KBEngine.Dbg.WARNING_MSG("_closeNetwork()")
	networkInterface.close()

#Send heartbeat to server and synchronize player information to server
func sendTick():
	if _networkInterface == null or not _networkInterface.connected:
		return
	if not loginappMessageImported_ and not baseappMessageImported_:
		return
	
	var since_last_tick = OS.get_ticks_msec() - _lastTickTime
	
	#Update player position and orientation to server
	updatePlayerToServer()
	
	if since_last_tick/1000 > _args.serverHeartbeatTick:
		#If no callback was received from server in time for the next tick,
		# the client should be notified that the connection has dropped
		if _lastTickCBTime < _lastTickTime:
			Dbg.ERROR_MSG("KBEngine::sendTick(): Received appTick timeout")
			_networkInterface.close()
			return
		
		var Loginapp_onClientActiveTickMsg = null
		var Baseapp_onClientActiveTickMsg = null
		
		if Messages.messages.has("Loginapp_onClientActiveTick"):
			Loginapp_onClientActiveTickMsg = Messages.messages["Loginapp_onClientActiveTick"]
		if Messages.messages.has("Baseapp_onClientActiveTick"):
			Baseapp_onClientActiveTickMsg = Messages.messages["Baseapp_onClientActiveTick"]
		
		if currserver == "loginapp":
			if Loginapp_onClientActiveTickMsg != null:
				var bundle = Bundle.createObject()
				bundle.newMessage(Loginapp_onClientActiveTickMsg)
				bundle.send(_networkInterface)
		else:
			if Baseapp_onClientActiveTickMsg != null:
				var bundle = Bundle.createObject()
				bundle.newMessage(Baseapp_onClientActiveTickMsg)
				bundle.send(_networkInterface)
	
	_lastTickTime = OS.get_ticks_msec()
	
#Server heartbeat callback
func Client_onAppActiveTickCB():
	_lastTickCBTime = OS.get_ticks_msec()
	
#Shake hands with the server. After connecting to any process, you should handshake with it the first time.
func hello():
	var bundle = Bundle.createObject()
	if currserver == "loginapp":
		bundle.newMessage(Messages.messages["Loginapp_hello"])
	else:
		bundle.newMessage(Messages.messages["Baseapp_hello"])
	
	bundle.writeString(clientVersion)
	bundle.writeString(clientScriptVersion)
	bundle.writeBlob(_encryptedKey)
	bundle.send(_networkInterface)
	
#Callback from server after handshake
func Client_onHelloCB(stream):
	serverVersion = stream.readString()
	serverScriptVersion = stream.readString()
	serverProtocolMD5 = stream.readString()
	serverEntitydefMD5 = stream.readString()
	var ctype = stream.readInt32()
	
	Dbg.DEBUG_MSG("KBEngine::Client_onHelloCB: verInfo("+ str(serverVersion)
		+"), scriptVersion("+str(serverScriptVersion)+"), srvProtocolMD5("+str(serverProtocolMD5)
		+"), srvEntitydefMD5("+str(serverEntitydefMD5)+"), + ctype(" + str(ctype) + ")!")
	
	onServerDigest()
	
	if currserver == "baseapp":
		onLogin_baseapp()
	else:
		onLogin_loginapp()

#Engine version does not match
func Client_onVersionNotMatch(stream):
	serverVersion = stream.readString()
	
	Dbg.ERROR_MSG("Client_onVersionNotMatch: verInfo="+clientVersion+" (server: "+serverVersion+")")
	Event.fireAll("onVersionNotMatch", [clientVersion, serverVersion])
	
	if _persistentInfos != null:
		_persistentInfos.onVersionNotMatch(clientVersion, serverVersion)

#Script version does not match
func Client_onScriptVersionNotMatch(stream):
	serverScriptVersion = stream.readString()
	
	Dbg.ERROR_MSG("Client_onScriptVersionNotMatch: verInfo="+clientScriptVersion+" (server: "+serverScriptVersion+")")
	Event.fireAll("onScriptVersionNotMatch", [clientScriptVersion, serverScriptVersion])
	
	if _persistentInfos != null:
		_persistentInfos.onScriptVersionNotMatch(clientScriptVersion, serverScriptVersion)

#Kicked by server
func Client_onKicked(failedcode):
	Dbg.ERROR_MSG("Client_onKicked: failedcode="+str(failedcode))
	Event.fireAll("onKicked", [failedcode])

#Server Error Description Imported serv callback
func Client_onImportServerErrorsDescr(stream):
	var datas = stream.getBuffer()
	
	onImportServerErrorsDescr(stream)
	
	if _persistentInfos != null:
		_persistentInfos.onImportServerErrorsDescr(datas)

#Server Error Description Imported
func onImportServerErrorsDescr(stream):
	var size = stream.readUint16()
	while size > 0:
		size -= 1
		
		var e = ServerErr.new()
		e.id = stream.readUint16()
		e.name = PoolByteArray(stream.readBlob()).get_string_from_utf8()
		e.descr = PoolByteArray(stream.readBlob()).get_string_from_utf8()

		serverErrs[e.id] = e

#Log in to the server, you must log in to complete
# the loginapp and gateway (baseapp), the login
# process is completed
func login(username, password, datas):
	KBEngine.Dbg.DEBUG_MSG("App::login()")
	KBEngine.app.username = username
	KBEngine.app.password = password
	KBEngine.app._clientdatas = datas
	
	KBEngine.app.login_loginapp(true)

func login_loginapp(noconnect):
	if noconnect:
		reset()
		var cb = Callback.new(self, "onConnectTo_loginapp_callback")
		_networkInterface.connectTo(_args.ip, _args.port, cb, null)
	else:
		Dbg.DEBUG_MSG("KBEngine::login_loginapp(): sending login! username="+username)
		var bundle = Bundle.createObject()
		bundle.newMessage(Messages.messages["Loginapp_login"])
		bundle.writeInt8(_args.clientType)
		bundle.writeBlob(KBEngine.app._clientdatas)
		bundle.writeString(username)
		bundle.writeString(password)
		bundle.send(_networkInterface)

func onConnectTo_loginapp_callback(ip, port, success, userData):
	_lastTickCBTime = OS.get_ticks_msec()
	print("App::onConnectTo_loginapp_callback()")
	
	if not success:
		Dbg.ERROR_MSG("KBEngine::login_loginapp(): error connecting to %s:%s!" % [ip, port])
		return
	
	currserver = "loginapp"
	currstate = "login"
	
	Dbg.DEBUG_MSG("KBEngine::login_loginapp(): connection to %s:%s successful!" % [ip, port])
	
	hello()

func onLogin_loginapp():
	_lastTickCBTime = OS.get_ticks_msec()
	
	if not loginappMessageImported_:
		var bundle = Bundle.createObject()
		bundle.newMessage(Messages.messages["Loginapp_importClientMessages"])
		bundle.send(_networkInterface)
		Dbg.DEBUG_MSG("KBEngine::onLogin_loginapp(): sending importClientMessages ...")
		Event.fireOut("Loginapp_importClientMessages", [])
	else:
		onImportClientMessagesCompleted()

#Log in to the server and log in to the gateway (baseapp)
func login_baseapp(noconnect):
	if noconnect:
		Event.fireOut("onLoginBaseapp", [])
		
		var cb = Callback.new(self, "onConnectTo_baseapp_callback")
		_networkInterface.reset()
		_networkInterface = KBEngine.NetworkInterface.new()
		_networkInterface.connectTo(baseappIP, baseappPort, cb, null)
	else:
		var bundle = Bundle.createObject()
		bundle.newMessage(Messages.messages["Baseapp_loginBaseapp"])
		bundle.writeString(username)
		bundle.writeString(password)
		bundle.send(_networkInterface)

func onConnectTo_baseapp_callback(ip, port, success, userData):
	_lastTickCBTime = OS.get_ticks_msec()
	
	if not success:
		Dbg.ERROR_MSG("KBEngine::login_baseapp(): error connecting to %s:%s!" % [ip, port])
		return
	
	currserver = "baseapp"
	currstate = ""
	
	Dbg.DEBUG_MSG("KBEngine::login_baseapp(): connection to %s:%s successful!" % [ip, port])
	
	hello()

func onLogin_baseapp():
	_lastTickCBTime = OS.get_ticks_msec()
	
	if not baseappMessageImported_:
		var bundle = Bundle.createObject()
		bundle.newMessage(Messages.messages["Baseapp_importClientMessages"])
		bundle.send(_networkInterface)
		Dbg.DEBUG_MSG("KBEngine::onLogin_baseapp(): sending importClientMessages ...")
		Event.fireOut("Baseapp_importClientMessages", [])
	else:
		onImportClientMessagesCompleted()

#Log in to the gateway (baseapp)
#Some mobile applications are easily dropped. 
#You can use this function to quickly reestablish communication with the server.
func reloginBaseapp():
	if _networkInterface.valid():
		return
	
	Event.fireAll("onReloginBaseapp", [])
	var cb = Callback.new(self, "onReConnectTo_baseapp_callback")
	_networkInterface.connectTo(baseappIP, baseappPort, cb, null)

func onReConnectTo_baseapp_callback(ip, port, success, userData):
	if not success:
		Dbg.ERROR_MSG("KBEngine::reloginBaseapp(): error connecting to "+ip+":"+str(port)+"!")
		return
	
	Dbg.DEBUG_MSG("KBEngine::reloginBaseapp(): connection to "+ip+":"+str(port)+" successful!")
	
	var bundle = Bundle.createObject()
	bundle.newMessage(Messages.messages["Baseapp_reloginBaseapp"])
	bundle.writeString(username)
	bundle.writeString(password)
	bundle.writeUint64(entity_uuid)
	bundle.writeInt32(entity_id)
	bundle.send(_networkInterface)
	
	_lastTickCBTime = OS.get_ticks_msec()

#Importing message protocol from binary stream
func importMessagesFromMemoryStream(loginapp_clientMessages, baseapp_clientMessages, entitydefMessages, serverErrorsDescr):
	resetMessages()
	
	loadingLocalMessages_ = true
	var stream = MemoryStream.createObject()
	stream.append(loginapp_clientMessages, 0, len(loginapp_clientMessages))
	currserver = "loginapp"
	onImportClientMessages(stream)
	stream.reclaimObject()
	
	stream = MemoryStream.createObject()
	stream.append(baseapp_clientMessages, 0, len(baseapp_clientMessages))
	currserver = "baseapp"
	onImportClientMessages(stream)
	currserver = "loginapp"
	stream.reclaimObject()
	
	stream = MemoryStream.createObject()
	stream.append(serverErrorsDescr, 0, len(serverErrorsDescr))
	onImportServerErrorsDescr(stream)
	stream.reclaimObject()
	
	stream = MemoryStream.createObject()
	stream.append(entitydefMessages, 0, len(entitydefMessages))
	onImportClientEntityDef(stream)
	stream.reclaimObject()
	
	loadingLocalMessages_ = false
	loginappMessageImported_ = true
	baseappMessageImported_ = true
	entitydefImported_ = true
	isImportServerErrorsDescr_ = true
	
	currserver = ""
	Dbg.DEBUG_MSG("KBEngine::importMessagesFromMemoryStream(): completed successfuly!")
	return true


#Importing message protocol from binary stream is complete
func onImportClientMessagesCompleted():
	Dbg.DEBUG_MSG("KBEngine::onImportClientMessagesCompleted: successful! currserver=" + 
				currserver + ", currstate=" + currstate)
	
	if currserver == "loginapp":
		if not isImportServerErrorsDescr_ and not loadingLocalMessages_:
			Dbg.DEBUG_MSG("KBEngine::onImportClientMessagesCompleted(): send importServerErrorsDescr!")
			isImportServerErrorsDescr_ = true
			var bundle = Bundle.createObject()
			bundle.newMessage(Messages.messages["Loginapp_importServerErrorsDescr"])
			bundle.send(_networkInterface)
		
		if currstate == "login":
			login_loginapp(false)
		elif currstate == "autoimport":
			pass
		elif currstate == "resetpassword":
			resetpassword_loginapp(false)
		elif currstate == "createAccount":
			createAccount_loginapp(false)
		
		loginappMessageImported_ = true
	else:
		baseappMessageImported_ = true
		
		if not entitydefImported_ and not loadingLocalMessages_:
			Dbg.DEBUG_MSG("KBEngine::onImportClientMessagesCompleted: sending importEntityDef(" + str(entitydefImported_) + ") ...")
			var bundle = Bundle.createObject()
			bundle.newMessage(Messages.messages["Baseapp_importClientEntityDef"])
			bundle.send(_networkInterface)
			Event.fireOut("Baseapp_importClientEntityDef", [])
		else:
			onImportEntityDefCompleted()

#Creating entitydef supported data types from binary streams
func createDataTypeFromStreams(stream, canprint):
	var aliassize = stream.readUint16()
	Dbg.DEBUG_MSG("KBEngine::createDataTypeFromStreams: importAlias(size=" + str(aliassize) + ")!")
	
	while aliassize > 0:
		aliassize -= 1
		createDataTypeFromStream(stream, canprint)

	for datatype in EntityDef.datatypes.keys():
		if EntityDef.datatypes[datatype] != null:
			EntityDef.datatypes[datatype].bind()

func createDataTypeFromStream(stream, canprint):
	var utype = stream.readUint16()
	var name = stream.readString()
	var valname = stream.readString()
	
	#There are some anonymous types, we need to provide a unique name to put in the datatypes
	#Such as:
	#
	#<onRemoveAvatar>
	#	<Arg>	ARRAY <of> INT8 </of>		</Arg>
	#</onRemoveAvatar>
	if len(valname) == 0:
		valname = "Null_" + str(utype)
	
	if canprint:
		Dbg.DEBUG_MSG("KBEngine::Client_onImportClientEntityDef: importAlias(" + name + ":" + valname + ":" + str(utype) + ")!")
	
	if name == "FIXED_DICT":
		var datatype = DataTypes.FIXED_DICT.new()
		var keysize = stream.readUint8()
		datatype.implementedBy = stream.readString()
			
		while keysize > 0:
			keysize -= 1		
			var keyname = stream.readString()
			var keyutype = stream.readUint16()
			datatype.dicttype[keyname] = keyutype
		
		EntityDef.datatypes[valname] = datatype
	elif name == "ARRAY":
		var uitemtype = stream.readUint16()
		var datatype = KBEngine.DataTypes.ARRAY.new()
		datatype.vtype = uitemtype
		EntityDef.datatypes[valname] = datatype
	else:
		EntityDef.datatypes[valname] = KBEngine.Helpers.tryGetValue(EntityDef.datatypes, name)
	
	EntityDef.id2datatypes[utype] = EntityDef.datatypes[valname]
	
	#Add user-defined types to the mapping table
	EntityDef.datatype2id[valname] = utype

func Client_onImportClientEntityDef(stream):
	var data = stream.getBuffer()
	
	onImportClientEntityDef(stream)
	
	if _persistentInfos != null:
		_persistentInfos.onImportClientEntityDef(data)

func onImportClientEntityDef(stream):
	createDataTypeFromStreams(stream, true)
	
	while stream.length() > 0:
		var scriptmodule_name = stream.readString()
		var scriptUtype = stream.readUint16()
		var propertysize = stream.readUint16()
		var methodsize = stream.readUint16()
		var base_methodsize = stream.readUint16()
		var cell_methodsize = stream.readUint16()
		
		Dbg.DEBUG_MSG("KBEngine::Client_onImportClientEntityDef: import(" + scriptmodule_name + "), propertys(" + str(propertysize) + "), " +
						"clientMethods(" + str(methodsize) + "), baseMethods(" + str(base_methodsize) + "), cellMethods(" + str(cell_methodsize) + ")!")
		
		var module = KBEngine.ScriptModule.new(scriptmodule_name)
		EntityDef.moduledefs[scriptmodule_name] = module
		EntityDef.idmoduledefs[scriptUtype] = module
		
		var Class = module.script
		
		while propertysize > 0:
			propertysize -= 1
			
			var properUtype = stream.readUint16()
			var properFlags = stream.readUint32()
			var ialiasID = stream.readInt16()
			var name = stream.readString()
			var defaultValStr = stream.readString()
			var utype = EntityDef.id2datatypes[stream.readUint16()]
			
			var setmethod = "set_"+name
			if Class != null and not KBEngine.Helpers.methodExistsInClass(Class, setmethod):
				setmethod = null
			
			var savedata = Property.new()
			savedata.name = name
			savedata.utype = utype
			savedata.properUtype = properUtype
			savedata.properFlags = properFlags
			savedata.aliasID = ialiasID
			savedata.defaultValStr = defaultValStr
			savedata.setmethod = setmethod
			savedata.val = savedata.utype.parseDefaultValStr(savedata.defaultValStr)
			
			module.propertys[name] = savedata
			
			if ialiasID != -1:
				module.usePropertyDescrAlias = true
				module.idpropertys[ialiasID] = savedata
			else:
				module.usePropertyDescrAlias = false
				module.idpropertys[properUtype] = savedata
			
		while methodsize > 0:
			methodsize -= 1
			
			var methodUtype = stream.readUint16()
			var ialiasID = stream.readInt16()
			var name = stream.readString()
			var argssize = stream.readUint8()
			var args = []
			
			while argssize > 0:
				argssize -= 1
				args.append(EntityDef.id2datatypes[stream.readUint16()])
			
			var savedata = Method.new()
			savedata.name = name
			savedata.methodUtype = methodUtype
			savedata.aliasID = ialiasID
			savedata.args = args
			savedata.handler = null
			if Class != null and KBEngine.Helpers.methodExistsInClass(Class, name):
				savedata.handler = name
			
			module.methods[name] = savedata
			
			if ialiasID != -1:
				module.useMethodDescrAlias = true
				module.idmethods[ialiasID] = savedata
			else:
				module.useMethodDescrAlias = false
				module.idmethods[methodUtype] = savedata
			
		while base_methodsize > 0:
			base_methodsize -= 1
			
			var methodUtype = stream.readUint16()
			var ialiasID = stream.readInt16()
			var name = stream.readString()
			var argssize = stream.readUint8()
			var args = []
			
			while argssize > 0:
				argssize -= 1
				args.append(EntityDef.id2datatypes[stream.readUint16()])
			
			var savedata = Method.new()
			savedata.name = name
			savedata.methodUtype = methodUtype
			savedata.aliasID = ialiasID
			savedata.args = args
			
			module.base_methods[name] = savedata
			module.idbase_methods[methodUtype] = savedata
		
		while cell_methodsize > 0:
			cell_methodsize -= 1
			
			var methodUtype = stream.readUint16()
			var ialiasID = stream.readInt16()
			var name = stream.readString()
			var argssize = stream.readUint8()
			var args = []
			
			while argssize > 0:
				argssize -= 1
				args.append(EntityDef.id2datatypes[stream.readUint16()])
			
			var savedata = Method.new()
			savedata.name = name
			savedata.methodUtype = methodUtype
			savedata.aliasID = ialiasID
			savedata.args = args
			
			module.cell_methods[name] = savedata
			module.idcell_methods[methodUtype] = savedata
		
		if module.script == null:
			Dbg.ERROR_MSG("KBEngine::Client_onImportClientEntityDef: module(" + scriptmodule_name + ") not found!")
		
		for name in module.methods.keys():
			if module.script != null and not KBEngine.Helpers.methodExistsInClass(module.script, name):
				Dbg.WARNING_MSG(scriptmodule_name + ":: method(" + name + ") not implemented!")

	onImportEntityDefCompleted()

func onImportEntityDefCompleted():
	Dbg.DEBUG_MSG("KBEngine::onImportEntityDefCompleted: successful!")
	entitydefImported_ = true
	
	if not loadingLocalMessages_:
		login_baseapp(false)

#Error description by Error ID
func serverErr(id):
	if not serverErrs.has(id):
		return ""
	
	var e = serverErrs[id]
	return e.name + "[" + e.descr + "]"

#Import client message protocol from binary stream returned by the server
func Client_onImportClientMessages(stream):
	var data = stream.getBuffer()
	
	onImportClientMessages(stream)
	
	if _persistentInfos != null:
		_persistentInfos.onImportClientMessages(currserver, data)

func onImportClientMessages(stream):
	var msgcount = stream.readUint16()
	Dbg.DEBUG_MSG("KBEngine::Client_onImportClientMessages: start currserver=" + currserver + "(msgsize="+str(msgcount)+") ...")
	
	while msgcount > 0:
		msgcount -= 1
		
		var msgid = stream.readUint16()
		var msglen = stream.readInt16()
		
		var msgname = stream.readString()
		var argstype = stream.readInt8()
		var argsize = stream.readUint8()
		var argstypes = []
		
		while len(argstypes) < argsize:
			argstypes.append(stream.readUint8())
		
		var handler = null
		var isClientMethod = msgname.find("Client_") > -1
		
		if isClientMethod:
			handler = msgname
			if not self.has_method(handler):
				Dbg.WARNING_MSG("KBEngine::onImportClientMessages[%s]: interface(%s/%s/%s) not implemented!"
								% [currserver, msgname, msgid, msglen])
				handler = null
		
		if len(msgname) > 0:
			Messages.messages[msgname] = Messages.Message.new(msgid, msgname, msglen, argstype, argstypes, handler)
			
			if isClientMethod:
				Messages.clientMessages[msgid] = Messages.messages[msgname]
			else:
				if currserver == "loginapp":
					Messages.loginappMessages[msgid] = Messages.messages[msgname]
				else:
					Messages.baseappMessages[msgid] = Messages.messages[msgname]
		else:
			var msg = Messages.Message.new(msgid, msgname, msglen, argstype, argstypes, handler)
			
			if currserver == "loginapp":
				Messages.loginappMessages[msgid] = msg
			else:
				Messages.baseappMessages[msgid] = msg
	
	onImportClientMessagesCompleted()

func onOpenLoginapp_resetpassword():
	Dbg.DEBUG_MSG("KBEngine::onOpenLoginapp_resetpassword: successful!")
	currserver = "loginapp"
	currstate = "resetpassword"
	_lastTickCBTime = OS.get_ticks_msec()
	
	if not loginappMessageImported_:
		var bundle = Bundle.createObject()
		bundle.newMessage(Messages.messages["Loginapp_importClientMessages"])
		bundle.send(_networkInterface)
		Dbg.DEBUG_MSG("KBEngine::onOpenLoginapp_resetpassword: sending importClientMessages ...")
	else:
		onImportClientMessagesCompleted()

#Reset password, through loginapp
func resetPassword(username):
	KBEngine.app.username = username
	resetpassword_loginapp(true)

#Reset password, through loginapp
func resetpassword_loginapp(noconnect):
	if noconnect:
		reset()
		_networkInterface.connectTo(_args.ip, _args.port, Callback.new(self, "onConnectTo_resetpassword_callback"), null)
	else:
		var bundle = Bundle.createObject()
		bundle.newMessage(Messages.messages["Loginapp_reqAccountResetPassword"])
		bundle.writeString(username)
		bundle.send(_networkInterface)

func onConnectTo_resetpassword_callback(ip, port, success, userData):
	_lastTickCBTime = OS.get_ticks_msec()
	
	if not success:
		Dbg.ERROR_MSG("KBEngine::resetpassword_loginapp(): failed to connect to %s:%s!" % [ip, port])
		return
	
	Dbg.DEBUG_MSG("KBEngine::resetpassword_loginapp(): connection to %s:%s successful!" % [ip, port])
	onOpenLoginapp_resetpassword()

func Client_onReqAccountResetPasswordCB(failcode):
	if failcode != 0:
		Dbg.ERROR_MSG("KBEngine::Client_onReqAccountResetPasswordCB: " + username + " failed! code=" + str(failcode) + "!")
		return
	
	Dbg.DEBUG_MSG("KBEngine::Client_onReqAccountResetPasswordCB: " + username + " successful!")

#Bind Email via baseapp
func bindAccountEmail(emailAddress):
	var bundle = Bundle.createObject()
	bundle.newMessage(Messages.messages["Baseapp_reqAccountBindEmail"])
	bundle.writeInt32(entity_id)
	bundle.writeString(password)
	bundle.writeString(emailAddress)
	bundle.send(_networkInterface)

func Client_onReqAccountBindEmailCB(failcode):
	if failcode != 0:
		Dbg.ERROR_MSG("KBEngine::Client_onReqAccountBindEmailCB: " + username + " failed! code=" + str(failcode) + "!")
		return
	
	Dbg.DEBUG_MSG("KBEngine::Client_onReqAccountBindEmailCB: " + username + " successful!")

#Set the new password through the Baseapp.
#The player must be logged and online, so the operation is on baseapp.
func newPassword(old_password, new_password):
	var bundle = Bundle.createObject()
	bundle.newMessage(Messages.messages["Baseapp_reqAccountNewPassword"])
	bundle.writeInt32(entity_id)
	bundle.writeString(old_password)
	bundle.writeString(new_password)
	bundle.send(_networkInterface)

func Client_onReqAccountNewPasswordCB(failcode):
	if failcode != 0:
		Dbg.ERROR_MSG("KBEngine::Client_onReqAccountNewPasswordCB: " + username + " failed! code=" + str(failcode) + "!")
		return
	
	Dbg.DEBUG_MSG("KBEngine::Client_onReqAccountNewPasswordCB: " + username + " successful!")

func createAccount(username, password, datas):
	KBEngine.app.username = username
	KBEngine.app.password = password
	KBEngine.app._clientdatas = datas
	
	KBEngine.app.createAccount_loginapp(true)

#Create an account via loginapp
func createAccount_loginapp(noconnect):
	if noconnect:
		reset()
		var cb = KBEngine.Helpers.Callback.new(self, "onConnectTo_createAccount_callback")
		_networkInterface.connectTo(_args.ip, _args.port, cb, null)
	else:
		var bundle = Bundle.createObject()
		bundle.newMessage(Messages.messages["Loginapp_reqCreateAccount"])
		bundle.writeString(username)
		bundle.writeString(password)
		bundle.writeBlob(KBEngine.app._clientdatas)
		bundle.send(_networkInterface)

func onOpenLoginapp_createAccount():
	Dbg.DEBUG_MSG("KBEngine::onOpenLoginapp_createAccount: successful!")
	currserver = "loginapp"
	currstate = "createAccount"
	_lastTickCBTime = OS.get_ticks_msec()
	
	if not loginappMessageImported_:
		var bundle = Bundle.createObject()
		bundle.newMessage(Messages.messages["Loginapp_importClientMessages"])
		bundle.send(_networkInterface)
		Dbg.DEBUG_MSG("KBEngine::onOpenLoginapp_createAccount: sending importClientMessages ...")
	else:
		onImportClientMessagesCompleted()

		
func onConnectTo_createAccount_callback(ip, port, success, userData):
	_lastTickCBTime = OS.get_ticks_msec()
	
	if not success:
		Dbg.ERROR_MSG("KBEngine::createAccount_loginapp(): failed to connect to %s:%s!" % [ip, port])
		return
	
	Dbg.DEBUG_MSG("KBEngine::createAccount_loginapp(): connection to %s:%s successful!" % [ip, port])
	onOpenLoginapp_createAccount()

#Obtained server summary information, summary includes protocol MD5, entitydefMD5
func onServerDigest():
	if _persistentInfos != null:
		_persistentInfos.onServerDigest(currserver, serverProtocolMD5, serverEntitydefMD5)

#Login through loginapp failed
func Client_onLoginFailed(stream):
	var failcode = stream.readUint16()
	_serverdatas = stream.readBlob()
	Dbg.ERROR_MSG("KBEngine::Client_onLoginFailed: failcode(" + str(failcode) + "), datas(" + str(len(_serverdatas)) + ")!")
	Event.fireAll("onLoginFailed", [failcode])

#Login through loginapp succeeded
func Client_onLoginSuccessfully(stream):
	var accountName = stream.readString()
	username = accountName
	baseappIP = stream.readString()
	baseappPort = stream.readUint16()
	
	Dbg.DEBUG_MSG("KBEngine::Client_onLoginSuccessfully: accountName(" + accountName + "), addr(" + 
					baseappIP + ":" + str(baseappPort) + "), datas(" + str(len(_serverdatas)) + ")!")
	
	_serverdatas = stream.readBlob()
	login_baseapp(true)

#Failed to login to baseapp
func Client_onLoginBaseappFailed(failcode):
	Dbg.ERROR_MSG("KBEngine::Client_onLoginBaseappFailed: failcode(" + str(failcode) + ")!")
	Event.fireAll("onLoginBaseappFailed", [failcode])

#Failed to re-login to baseapp
func Client_onReloginBaseappFailed(failcode):
	Dbg.ERROR_MSG("KBEngine::Client_onReloginBaseappFailed: failcode(" + str(failcode) + ")!")
	Event.fireAll("onReloginBaseappFailed", [failcode])

#Re-login to baseapp succeeded
func Client_onReloginBaseappSuccessfully(stream):
	entity_uuid = stream.readUint64()
	Dbg.ERROR_MSG("KBEngine::Client_onReloginBaseappSuccessfully: name(" + username + ")!")
	Event.fireAll("onReloginBaseappSuccessfully", [])

#Server-side notification to create a character
func Client_onCreatedProxies(rndUUID, eid, entityType):
	Dbg.DEBUG_MSG("KBEngine::Client_onCreatedProxies: eid(" + str(eid) + "), entityType(" + str(entityType) + ")!")
	
	entity_uuid = rndUUID
	entity_id = eid
	entity_type = entityType
	
	if not entities.has(eid):
		var module = KBEngine.Helpers.tryGetValue(EntityDef.moduledefs, entityType)
		if module == null:
			Dbg.ERROR_MSG("KBEngine::Client_onCreatedProxies: module not found(" + str(entityType) + ")!")
			return
		
		var runclass = module.script
		if runclass == null:
			return
		
		var entity = runclass.new()
		entity.id = eid
		entity.className = entityType
		
		entity.baseEntityCall = EntityCall.new()
		entity.baseEntityCall.id = eid
		entity.baseEntityCall.className = entityType
		entity.baseEntityCall.type = EntityCall.ENTITYCALL_TYPE.ENTITYCALL_TYPE_BASE
		
		entities[eid] = entity
		
		var entityMessage = KBEngine.Helpers.tryGetValue(_bufferedCreateEntityMessage, eid)
		
		if entityMessage != null:
			Client_onUpdatePropertys(entityMessage)
			_bufferedCreateEntityMessage.erase(eid)
			entityMessage.reclaimObject()
		
		entity.__init__()
		entity.inited = true
		
		if _args.isOnInitCallPropertySetMethods:
			entity.callPropertysSetMethods()
	
	else:
		var entityMessage = KBEngine.Helpers.tryGetValue(_bufferedCreateEntityMessage, eid)
		
		if entityMessage != null:
			Client_onUpdatePropertys(entityMessage)
			_bufferedCreateEntityMessage.erase(eid)
			entityMessage.reclaimObject()

func findEntity(entityID):
	if entities.has(entityID):
		return entities[entityID]
	else:
		return null

#Get the ID of the View entity through the stream data
func getViewEntityIDFromStream(stream):
	if not _args.useAliasEntityID:
		return stream.readInt32()
	
	var id = 0
	if len(_entityIDAliasIDList) > 255:
		id = stream.readInt32()
	else:
		var aliasID = stream.readUint8()
		
		#If it is 0 and the previous step of the client was a re-login/reconnect operation, and the server entity is
		# online during the disconnection, this error can be ignored, because cellapp may have been sending
		# synchronization messages to baseapp, not waiting when the client is reconnected.
		#The server-side initialization step starts with a sync message. At this point, an error occurs.
		if aliasID >= len(_entityIDAliasIDList):
			return 0
		
		id = _entityIDAliasIDList[aliasID]
	
	return id

#Server updates entity attribute data (optimized)
func Client_onUpdatePropertysOptimized(stream):
	var eid = getViewEntityIDFromStream(stream)
	onUpdatePropertys_(eid, stream)

#Server updates entity attribute data
func Client_onUpdatePropertys(stream):
	var eid = stream.readInt32()
	onUpdatePropertys_(eid, stream)

func onUpdatePropertys_(eid, stream):
	if not entities.has(eid):
		if _bufferedCreateEntityMessage.has(eid):
			Dbg.ERROR_MSG("KBEngine::Client_onUpdatePropertys: entity(" + str(eid) + ") not found!")
			return
		
		var stream1 = MemoryStream.createObject()
		stream1.wpos = stream.wpos
		stream1.rpos = stream.rpos - 4
		stream1.putData(stream.getData(), 0, 0)
		_bufferedCreateEntityMessage[eid] = stream1
		return
	var entity = entities[eid]
	
	var sm = EntityDef.moduledefs[entity.className]
	var pdatas = sm.idpropertys
	
	while stream.length() > 0:
		var utype = 0
		
		if sm.usePropertyDescrAlias:
			utype = stream.readUint8()
		else:
			utype = stream.readUint16()
		
		var propertydata = pdatas[utype]
		utype = propertydata.properUtype
		var setmethod = propertydata.setmethod
		
		var val = propertydata.utype.createFromStream(stream)
		var oldval = entity.getDefinedPropertyByUType(utype)
		
		entity.setDefinedPropertyByUType(utype, val)
		if setmethod != null:
			if propertydata.isBase():
				if entity.inited:
					entity.call(setmethod, oldval)
			else:
				if entity.inWorld:
					entity.call(setmethod, oldval)
	
#The server calls an entity method (optimized)
func Client_onRemoteMethodCallOptimized(stream):
	var eid = getViewEntityIDFromStream(stream)
	onRemoteMethodCall_(eid, stream)

#The server calls an entity method
func Client_onRemoteMethodCall(stream):
	var eid = stream.readInt32()
	onRemoteMethodCall_(eid, stream)

func onRemoteMethodCall_(eid, stream):
	if not entities.has(eid):
		Dbg.ERROR_MSG("KBEngine::Client_onRemoteMethodCall: entity(" + str(eid) + ") not found!")
		return
	var entity = entities[eid]
	
	var methodUtype = 0
	
	if EntityDef.moduledefs[entity.className].useMethodDescrAlias:
		methodUtype = stream.readUint8()
	else:
		methodUtype = stream.readUint16()
	
	var methoddata = EntityDef.moduledefs[entity.className].idmethods[methodUtype]
	
	var args = []
	while len(args) < len(methoddata.args):
		args.append(methoddata.args[len(args)].createFromStream(stream))
	
	if methoddata.handler != null and entity.has_method(methoddata.handler):
		entity.callv(methoddata.handler, args)
	else:
		Dbg.ERROR_MSG("KBEngine::Client_onRemoteMethodCall: %s(%s), method not found(%s.%s) error!" % [entity.className, eid, entity.className, methoddata.name])

#The server notifies an entity that it has entered the world
# (if the entity is the current player then it means the player is
# created in a space for the first time, if it is another
# entity then it means the entity entered the player's View)
func Client_onEntityEnterWorld(stream):
	var eid = stream.readInt32()
	if entity_id > 0 and entity_id != eid:
		_entityIDAliasIDList.append(eid)
	
	var uentityType
	if len(EntityDef.idmoduledefs) > 255:
		uentityType = stream.readUint16()
	else:
		uentityType = stream.readUint8()
	
	var isOnGround = 1
	
	if stream.length() > 0:
		isOnGround = stream.readInt8()
	
	var entityType = EntityDef.idmoduledefs[uentityType].name
	
	if not entities.has(eid):
		if not _bufferedCreateEntityMessage.has(eid):
			Dbg.ERROR_MSG("KBEngine::Client_onEntityEnterWorld: entity(" + str(eid) + ") not found!")
			return
		var entityMessage = _bufferedCreateEntityMessage[eid]
		
		if not EntityDef.moduledefs.has(entityType):
			Dbg.ERROR_MSG("KBEngine::Client_onEntityEnterWorld: not found module(" + str(entityType) + ")!")
			return
		var module = EntityDef.moduledefs[entityType]
		
		var runclass = module.script
		if runclass == null:
			return
		
		var entity = runclass.new()
		entity.id = eid
		entity.className = entityType
		
		entity.cellEntityCall = EntityCall.new()
		entity.cellEntityCall.id = eid
		entity.cellEntityCall.className = entityType
		entity.cellEntityCall.type = EntityCall.ENTITYCALL_TYPE.ENTITYCALL_TYPE_CELL
		
		entities[eid] = entity
		
		Client_onUpdatePropertys(entityMessage)
		_bufferedCreateEntityMessage.erase(eid)
		entityMessage.reclaimObject()
		
		entity.isOnGround = isOnGround > 0
		entity.set_direction(entity.getDefinedProperty("direction"))
		entity.set_position(entity.getDefinedProperty("position"))
		
		entity.__init__()
		entity.inited = true
		entity.inWorld = true
		entity.enterWorld()
		
		if _args.isOnInitCallPropertySetMethods:
			entity.callPropertysSetMethods()
	
	else:
		var entity = entities[eid]
		if not entity.inWorld:
			#For safety sake, clear it here.
			#If giveClientTo switches control on the server, the previous
			# entity and also the switched entity entered the world, 
			# so information on the previous entity entering the world
			# may be left behind. (google translated..confusing)
			_entityIDAliasIDList.clear()
			clearEntities(false)
			entities[entity.id] = entity
			
			entity.cellEntityCall = EntityCall.new()
			entity.cellEntityCall.id = eid
			entity.cellEntityCall.className = entityType
			entity.cellEntityCall.type = EntityCall.ENTITYCALL_TYPE.ENTITYCALL_TYPE_CELL
			
			entity.set_direction(entity.getDefinedProperty("direction"))
			entity.set_position(entity.getDefinedProperty("position"))
			
			_entityServerPos = entity.position
			entity.isOnGround = isOnGround > 0
			entity.inWorld = true
			entity.enterWorld()
			
			if _args.isOnInitCallPropertySetMethods:
				entity.callPropertysSetMethods()

#The server informs an entity that it has left the world (optimized to get entity by alias)
func Client_onEntityLeaveWorldOptimized(stream):
	var eid = getViewEntityIDFromStream(stream)
	KBEngine.app.Client_onEntityLeaveWorld(eid)
	
#The server informs an entity that is has left the world
#(if the entity is the current player then it means the player left
# the space, if it's another entity then that entity left the player's View)
func Client_onEntityLeaveWorld(eid):
	if not entities.has(eid):
		Dbg.ERROR_MSG("KBEngine::Client_onEntityLeaveWorld: entity(" + str(eid) + ") not found!")
		return
	var entity = entities[eid]
	
	if entity.inWorld:
		entity.leaveWorld()
	
	if entity_id == eid:
		clearSpace(false)
		entity.cellEntityCall = null
	else:
		if _controlledEntities.has(entity):
			_controlledEntities.erase(entity)
			Event.fireOut("onLoseControlledEntity", [entity])
		
		entities.erase(eid)
		entity.onDestroy()
		_entityIDAliasIDList.erase(eid)

#The server notifies the current player that they have entered a new space
func Client_onEntityEnterSpace(stream):
	var eid = stream.readInt32()
	spaceID = stream.readUint32()
	
	var isOnGround = 1
	
	if stream.length() > 0:
		isOnGround = stream.readInt8()
	
	if not entities.has(eid):
		Dbg.ERROR_MSG("KBEngine::Client_onEntityEnterSpace: entity(" + str(eid) + ") not found!")
		return
	var entity = entities[eid]
	
	entity.isOnGround = isOnGround > 0
	_entityServerPos = entity.position
	entity.enterSpace()

#Server notifies current player that they have left a space
func Client_onEntityLeaveSpace(eid):
	if not entities.has(eid):
		Dbg.ERROR_MSG("KBEngine::Client_onEntityLeaveSpace: entity(" + str(eid) + ") not found!")
		return
	var entity = entities[eid]
	
	entity.leaveSpace()
	clearSpace(false)

#Account creation return result
func Client_onCreateAccountResult(stream):
	var retcode = stream.readUint16()
	var datas = stream.readBlob()
	
	Event.fireOut("onCreateAccountResult", [retcode, datas])
	
	if retcode != 0:
		Dbg.WARNING_MSG("KBEngine::Client_onCreateAccountResult: " + username + " creation failed! code=" + str(retcode) + "!")
		return
	
	Dbg.DEBUG_MSG("KBEngine::Client_onCreateAccountResult: " + username + " creation successful!")

#Tell the client: you are currently responsible (or no longer responsible)
# for controlling/synchronizing positions and directions
func Client_onControlEntity(eid, isControlled):
	if not entities.has(eid):
		Dbg.ERROR_MSG("KBEngine::Client_onControlEntity: entity(" + str(eid) + ") not found!")
		return
	var entity = entities[eid]
	
	isControlled = isControlled != 0
	if isControlled:
		#If the entity being controlled is the player himself, it means that the player
		# is controlled by someone else. If it is the player, he should not go into the controlled list
		if player().id != entity.id:
			_controlledEntities.Add(entity)
	else:
		_controlledEntities.erase(entity)
	
	entity.isControlled = isControlled
	
	entity.onControlled(isControlled)
	Event.fireOut("onControlled", [entity, isControlled])

#Update the position and orientation of the current player to the server.
# This mechanism can be turned off by the switch _syncPlayer
func updatePlayerToServer():
	if not _args.syncPlayer or spaceID == 0:
		return
	
	var now = OS.get_ticks_msec()
	var since_last_update = now - _lastUpdateToServerTime
	
	if since_last_update < 100:
		return
		
	var playerEntity = player()
	if playerEntity == null or playerEntity.inWorld == false or playerEntity.isControlled:
		return
	
	var update_lateness = since_last_update - 100
	_lastUpdateToServerTime = now - update_lateness
	
	var position = playerEntity.position
	var direction = playerEntity.direction
	
	var posHasChanged = position.distance_to(playerEntity._entityLastLocalPos) > 0.001
	var dirHasChanged = direction.distance_to(playerEntity._entityLastLocalDir) > 0.001
	
	if posHasChanged or dirHasChanged:
		playerEntity._entityLastLocalPos = position
		playerEntity._entityLastLocalDir = direction
		
		var bundle = Bundle.createObject()
		bundle.newMessage(Messages.messages["Baseapp_onUpdateDataFromClient"])
		bundle.writeFloat(position.x)
		bundle.writeFloat(position.y)
		bundle.writeFloat(position.z)
		
		bundle.writeFloat(KBEngine.Helpers.normalizeRads(direction.x))
		bundle.writeFloat(KBEngine.Helpers.normalizeRads(direction.y))
		bundle.writeFloat(KBEngine.Helpers.normalizeRads(direction.z))

		if playerEntity.isOnGround:
			bundle.writeUint8(1)
		else:
			bundle.writeUint8(0)
		bundle.writeUint32(spaceID)
		bundle.send(_networkInterface)
	
	#Start synchronizing all controlled entity positions
	for entity in _controlledEntities:
		position = entity.position
		direction = entity.direction
		
		posHasChanged = position.distance_to(entity._entityLastLocalPos) > 0.001
		dirHasChanged = direction.distance_to(entity._entityLastLocalDir) > 0.001

		if posHasChanged or dirHasChanged:
			entity._entityLastLocalPos = position
			entity._entityLastLocalDir = direction
			
			var bundle = Bundle.createObject()
			bundle.newMessage(Messages.messages["Baseapp_onUpdateDataFromClientForControlledEntity"])
			bundle.writeInt32(entity.id)
			bundle.writeFloat(position.x)
			bundle.writeFloat(position.y)
			bundle.writeFloat(position.z)
			
			bundle.writeFloat(KBEngine.Helpers.normalizeRads(direction.x))
			bundle.writeFloat(KBEngine.Helpers.normalizeRads(direction.y))
			bundle.writeFloat(KBEngine.Helpers.normalizeRads(direction.z))
	
			if entity.isOnGround:
				bundle.writeUint8(1)
			else:
				bundle.writeUint8(0)
			bundle.writeUint32(spaceID)
			bundle.send(_networkInterface)

#The current space adds a mapping resource for information such as geometry
#The client can load the corresponding scene through this resource information
func addSpaceGeometryMapping(uspaceID, respath):
	Dbg.DEBUG_MSG("KBEngine::addSpaceGeometryMapping: spaceID(" + str(uspaceID) + "), respath(" + str(respath) + ")!")
	
	isLoadedGeometry = true
	spaceID = uspaceID
	spaceResPath = respath
	Event.fireOut("addSpaceGeometryMapping", [spaceResPath])

func clearSpace(isall):
	_entityIDAliasIDList.clear()
	_spacedatas.clear()
	clearEntities(isall)
	isLoadedGeometry = false
	spaceID = 0

func clearEntities(isall):
	_controlledEntities.clear()
	
	if not isall:
		var player_entity = player()
		for eid in entities.keys():
			if eid == player_entity.id:
				continue
			
			var ent = entities[eid]
			if ent.inWorld:
				ent.leaveWorld()
			ent.onDestroy()
		
		entities.clear()
		entities[player_entity.id] = player_entity
	
	else:
		for eid in entities.keys():
			var ent = entities[eid]
			if ent.inWorld:
				ent.leaveWorld()
			ent.onDestroy()
		
		entities.clear()

#Server initializes client Spacedata, refer to API for more on SpaceData
func Client_initSpaceData(stream):
	clearSpace(false)
	spaceID = stream.readUint32()
	
	while stream.length() > 0:
		var key = stream.readString()
		var val = stream.readString()
		Client_setSpaceData(spaceID, key, val)
	
	Dbg.DEBUG_MSG("KBEngine::Client_initSpaceData: spaceID(" + str(spaceID) + "), size(" + str(len(_spacedatas)) + ")!")

#Server sets client's Spacedata, refer to API for more on SpaceData
func Client_setSpaceData(spaceID, key, val):
	Dbg.DEBUG_MSG("KBEngine::Client_setSpaceData: spaceID(" + str(spaceID) + "), key(" + str(key) + "), value(" + str(val) + ")!")
	_spacedatas[key] = val
	
	if key == "_mapping":
		addSpaceGeometryMapping(spaceID, val)
	
	Event.fireOut("onSetSpaceData", [spaceID, key, val])

#Server deletes client's Spacedata, refer to API for more on SpaceData
func Client_delSpaceData(spaceID, key):
	Dbg.DEBUG_MSG("KBEngine::Client_delSpaceData: spaceID(" + str(spaceID) + "), key(" + str(key) + ")")
	_spacedatas.erase(key)
	Event.fireOut("onDelSpaceData", [spaceID, key])

func getSpaceData(key):
	if _spacedatas.has(key):
		return _spacedatas[key]
	else:
		return ""

#Notification from server of forced entity destruction
func Client_onEntityDestroyed(eid):
	Dbg.DEBUG_MSG("KBEngine::Client_onEntityDestroyed: entity(" + str(eid) + ")")
	
	if not entities.has(eid):
		Dbg.ERROR_MSG("KBEngine::Client_onEntityDestroyed: entity(" + str(eid) + ") not found!")
		return
	var entity = entities[eid]
	
	if entity.inWorld:
		if entity_id == eid:
			clearSpace(false)
		entity.leaveWorld()
	
	if _controlledEntities.has(entity):
		_controlledEntities.erase(entity)
		Event.fireOut("onLoseControlledEntity", [entity])
	
	entities.erase(eid)
	entity.onDestroy()

#The server updates the player's base position.
#The client uses this base position plus a cheap
# value to calculate the coordinates of the player's
# surrounding entities.
func Client_onUpdateBasePos(x,y,z):
	_entityServerPos.x = x
	_entityServerPos.y = y
	_entityServerPos.z = z
	
	var entity = player()
	if entity != null and entity.isControlled:
		entity.position.x = _entityServerPos.x
		entity.position.y = _entityServerPos.y
		entity.position.z = _entityServerPos.z
		Event.fireOut("updatePosition", [entity])
		entity.onUpdateVolatileData()

func Client_onUpdateBasePosXZ(x,z):
	_entityServerPos.x = x
	_entityServerPos.z = z
	
	var entity = player()
	if entity != null and entity.isControlled:
		entity.position.x = _entityServerPos.x
		entity.position.z = _entityServerPos.z
		Event.fireOut("updatePosition", [entity])
		entity.onUpdateVolatileData()

func Client_onUpdateBaseDir(stream):
	var yaw = stream.readFloat()
	var pitch = stream.readFloat()
	var roll = stream.readFloat()
	
	var entity = player()
	if entity != null and entity.isControlled:
		entity.direction.x = roll
		entity.direction.y = pitch
		entity.direction.z = yaw
		Event.fireOut("set_direction", [entity])
		entity.onUpdateVolatileData()

func Client_onUpdateData(stream):
	var eid = getViewEntityIDFromStream(stream)
	if not entities.has(eid):
		Dbg.ERROR_MSG("KBEngine::Client_onUpdateData: entity(" + str(eid) + ") not found!")
		return

#The server forces a change in the player's coordinates
#For example: use avatar.position=(0,0,0) on the server,
# or force the player back to a position when the player's
# position and speed are abnormal
func Client_onSetEntityPosAndDir(stream):
	var eid = stream.readInt32()
	
	if not entities.has(eid):
		Dbg.ERROR_MSG("KBEngine::Client_onSetEntityPosAndDir: entity(" + str(eid) + ") not found!")
		return
	var entity = entities[eid]
	
	entity.position.x = stream.readFloat()
	entity.position.y = stream.readFloat()
	entity.position.z = stream.readFloat()
	
	entity.direction.x = stream.readFloat()
	entity.direction.y = stream.readFloat()
	entity.direction.z = stream.readFloat()
	
	var position = entity.getDefinedProperty("position")
	var direction = entity.getDefinedProperty("direction")
	var old_position = Vector3(position)
	var old_direction = Vector3(direction)
	
	position.x = entity.position.x
	position.y = entity.position.y
	position.z = entity.position.z

	direction.x = entity.direction.x
	direction.y = entity.direction.y
	direction.z = entity.direction.z
	
	entity.setDefinedProperty("position", position)
	entity.setDefinedProperty("direction", direction)
	
	entity._entityLastLocalPos = entity.position
	entity._entityLastLocalDir = entity.direction
	
	entity.set_direction(old_direction)
	entity.set_position(old_position)

func Client_onUpdateData_ypr(stream):
	var eid = getViewEntityIDFromStream(stream)
	
	var y = stream.readInt8()
	var p = stream.readInt8()
	var r = stream.readInt8()
	
	_updateVolatileData(eid, DataTypes.FLT_MAX, DataTypes.FLT_MAX, DataTypes.FLT_MAX, y, p, r, -1)

func Client_onUpdateData_yp(stream):
	var eid = getViewEntityIDFromStream(stream)
	
	var y = stream.readInt8()
	var p = stream.readInt8()
	
	_updateVolatileData(eid, DataTypes.FLT_MAX, DataTypes.FLT_MAX, DataTypes.FLT_MAX, y, p, DataTypes.FLT_MAX, -1)

func Client_onUpdateData_yr(stream):
	var eid = getViewEntityIDFromStream(stream)
	
	var y = stream.readInt8()
	var r = stream.readInt8()
	
	_updateVolatileData(eid, DataTypes.FLT_MAX, DataTypes.FLT_MAX, DataTypes.FLT_MAX, y, DataTypes.FLT_MAX, r, -1)

func Client_onUpdateData_pr(stream):
	var eid = getViewEntityIDFromStream(stream)
	
	var p = stream.readInt8()
	var r = stream.readInt8()
	
	_updateVolatileData(eid, DataTypes.FLT_MAX, DataTypes.FLT_MAX, DataTypes.FLT_MAX, DataTypes.FLT_MAX, p, r, -1)

func Client_onUpdateData_y(stream):
	var eid = getViewEntityIDFromStream(stream)
	
	var y = stream.readInt8()
	
	_updateVolatileData(eid, DataTypes.FLT_MAX, DataTypes.FLT_MAX, DataTypes.FLT_MAX, y, DataTypes.FLT_MAX, DataTypes.FLT_MAX, -1)

func Client_onUpdateData_p(stream):
	var eid = getViewEntityIDFromStream(stream)
	
	var p = stream.readInt8()
	
	_updateVolatileData(eid, DataTypes.FLT_MAX, DataTypes.FLT_MAX, DataTypes.FLT_MAX, DataTypes.FLT_MAX, p, DataTypes.FLT_MAX, -1)

func Client_onUpdateData_r(stream):
	var eid = getViewEntityIDFromStream(stream)
	
	var r = stream.readInt8()
	
	_updateVolatileData(eid, DataTypes.FLT_MAX, DataTypes.FLT_MAX, DataTypes.FLT_MAX, DataTypes.FLT_MAX, DataTypes.FLT_MAX, r, -1)

func Client_onUpdateData_xz(stream):
	var eid = getViewEntityIDFromStream(stream)
	
	var xz = stream.readPackXZ()
	
	_updateVolatileData(eid, xz[0], DataTypes.FLT_MAX, xz[1], DataTypes.FLT_MAX, DataTypes.FLT_MAX, DataTypes.FLT_MAX, 1)

func Client_onUpdateData_xz_ypr(stream):
	var eid = getViewEntityIDFromStream(stream)
	
	var xz = stream.readPackXZ()

	var y = stream.readInt8()
	var p = stream.readInt8()
	var r = stream.readInt8()
	
	_updateVolatileData(eid, xz[0], DataTypes.FLT_MAX, xz[1], y, p, r, 1)

func Client_onUpdateData_xz_yp(stream):
	var eid = getViewEntityIDFromStream(stream)
	
	var xz = stream.readPackXZ()

	var y = stream.readInt8()
	var p = stream.readInt8()
	
	_updateVolatileData(eid, xz[0], DataTypes.FLT_MAX, xz[1], y, p, DataTypes.FLT_MAX, 1)

func Client_onUpdateData_xz_yr(stream):
	var eid = getViewEntityIDFromStream(stream)
	
	var xz = stream.readPackXZ()

	var y = stream.readInt8()
	var r = stream.readInt8()
	
	_updateVolatileData(eid, xz[0], DataTypes.FLT_MAX, xz[1], y, DataTypes.FLT_MAX, r, 1)

func Client_onUpdateData_xz_pr(stream):
	var eid = getViewEntityIDFromStream(stream)
	
	var xz = stream.readPackXZ()

	var p = stream.readInt8()
	var r = stream.readInt8()
	
	_updateVolatileData(eid, xz[0], DataTypes.FLT_MAX, xz[1], DataTypes.FLT_MAX, p, r, 1)

func Client_onUpdateData_xz_y(stream):
	var eid = getViewEntityIDFromStream(stream)
	var xz = stream.readPackXZ()
	var yaw = stream.readInt8()
	_updateVolatileData(eid, xz[0], DataTypes.FLT_MAX, xz[1], yaw, DataTypes.FLT_MAX, DataTypes.FLT_MAX, 1)

func Client_onUpdateData_xz_p(stream):
	var eid = getViewEntityIDFromStream(stream)
	
	var xz = stream.readPackXZ()

	var p = stream.readInt8()
	
	_updateVolatileData(eid, xz[0], DataTypes.FLT_MAX, xz[1], DataTypes.FLT_MAX, p, DataTypes.FLT_MAX, 1)

func Client_onUpdateData_xz_r(stream):
	var eid = getViewEntityIDFromStream(stream)
	
	var xz = stream.readPackXZ()

	var r = stream.readInt8()
	
	_updateVolatileData(eid, xz[0], DataTypes.FLT_MAX, xz[1], DataTypes.FLT_MAX, DataTypes.FLT_MAX, r, 1)

func Client_onUpdateData_xyz(stream):
	var eid = getViewEntityIDFromStream(stream)
	
	var xz = stream.readPackXZ()
	var y = stream.readPackY()
	
	_updateVolatileData(eid, xz[0], y, xz[1], DataTypes.FLT_MAX, DataTypes.FLT_MAX, DataTypes.FLT_MAX, 0)

func Client_onUpdateData_xyz_ypr(stream):
	var eid = getViewEntityIDFromStream(stream)
	
	var xz = stream.readPackXZ()
	var y = stream.readPackY()
	
	var yaw = stream.readInt8()
	var p = stream.readInt8()
	var r = stream.readInt8()
	
	_updateVolatileData(eid, xz[0], y, xz[1], yaw, p, r, 0)

func Client_onUpdateData_xyz_yp(stream):
	var eid = getViewEntityIDFromStream(stream)
	
	var xz = stream.readPackXZ()
	var y = stream.readPackY()
	
	var yaw = stream.readInt8()
	var p = stream.readInt8()

	_updateVolatileData(eid, xz[0], y, xz[1], yaw, p, DataTypes.FLT_MAX, 0)

func Client_onUpdateData_xyz_yr(stream):
	var eid = getViewEntityIDFromStream(stream)
	
	var xz = stream.readPackXZ()
	var y = stream.readPackY()
	
	var yaw = stream.readInt8()
	var r = stream.readInt8()
	
	_updateVolatileData(eid, xz[0], y, xz[1], yaw, DataTypes.FLT_MAX, r, 0)

func Client_onUpdateData_xyz_pr(stream):
	var eid = getViewEntityIDFromStream(stream)
	
	var xz = stream.readPackXZ()
	var y = stream.readPackY()
	
	var p = stream.readInt8()
	var r = stream.readInt8()
	
	_updateVolatileData(eid, xz[0], y, xz[1], DataTypes.FLT_MAX, p, r, 0)

func Client_onUpdateData_xyz_y(stream):
	var eid = getViewEntityIDFromStream(stream)
	
	var xz = stream.readPackXZ()
	var y = stream.readPackY()
	
	var yaw = stream.readInt8()
	_updateVolatileData(eid, xz[0], y, xz[1], yaw, DataTypes.FLT_MAX, DataTypes.FLT_MAX, 0)

func Client_onUpdateData_xyz_p(stream):
	var eid = getViewEntityIDFromStream(stream)
	
	var xz = stream.readPackXZ()
	var y = stream.readPackY()
	
	var p = stream.readInt8()
	
	_updateVolatileData(eid, xz[0], y, xz[1], DataTypes.FLT_MAX, p, DataTypes.FLT_MAX, 0)

func Client_onUpdateData_xyz_r(stream):
	var eid = getViewEntityIDFromStream(stream)
	
	var xz = stream.readPackXZ()
	var y = stream.readPackY()
	
	var r = stream.readInt8()
	
	_updateVolatileData(eid, xz[0], y, xz[1], DataTypes.FLT_MAX, DataTypes.FLT_MAX, r, 0)

func _updateVolatileData(entityID, x, y, z, yaw, pitch, roll, isOnGround):
	if not entities.has(entityID):
		#If it is 0 and the previous step of the client was a re-login/reconnect operation, and the server entity is
		# online during the disconnection, this error can be ignored, because cellapp may have been sending
		# synchronization messages to baseapp, not waiting when the client is reconnected.
		#The server-side initialization step starts with a sync message. At this point, an error occurs.
		Dbg.ERROR_MSG("KBEngine::_updateVolatileData: entity(" + str(entityID) + ") not found!")
		return
	var entity = entities[entityID]
	
	# Less than 0 is not set
	if isOnGround >= 0:
		entity.isOnGround = isOnGround > 0
	
	var directionChanged = false
	
	if roll < DataTypes.FLT_MAX:
		directionChanged = true
		entity.direction.x = KBEngine.Helpers.int82angle(roll, false)
	if pitch < DataTypes.FLT_MAX:
		directionChanged = true
		entity.direction.y = KBEngine.Helpers.int82angle(pitch, false)
	if yaw < DataTypes.FLT_MAX:
		directionChanged = true
		entity.direction.z = KBEngine.Helpers.int82angle(yaw, false)
	
	if directionChanged == true:
		Event.fireOut("set_direction", [entity])
	
	var positionChanged = x < DataTypes.FLT_MAX or y < DataTypes.FLT_MAX or z < DataTypes.FLT_MAX
	if x >= DataTypes.FLT_MAX:
		x = 0.0
	if y >= DataTypes.FLT_MAX:
		y = 0.0
	if z >= DataTypes.FLT_MAX:
		z = 0.0
	
	if positionChanged:
		var pos = Vector3(x + _entityServerPos.x, y + _entityServerPos.y, z + _entityServerPos.z)
		
		entity.position = pos
		Event.fireOut("updatePosition", [entity])
	
	if directionChanged or positionChanged:
		entity.onUpdateVolatileData()

#The server informs the start of streaming data download
#Please refer to the API manual about onStreamDataStarted
func Client_onStreamDataStarted(id, datasize, descr):
	Event.fireOut("onStreamDataStarted", [id, datasize, descr])

func Client_onStreamDataRecv(stream):
	var resID = stream.readInt16()
	var datas = stream.readBlob()
	Event.fireOut("onStreamDataRecv", [resID, datas])

func Client_onStreamDataCompleted(id):
	Event.fireOut("onStreamDataCompleted", [id])
	
func validEmail(email):
	var regex = RegEx.new()
	regex.compile("^([\\w-\\.]+)@((\\[[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.)|(([\\w-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\\]?)$")
	return regex.search(email) != null