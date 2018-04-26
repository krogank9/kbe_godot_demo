extends Node

var _persistentDataPath = ""
var _isGood = false
var _digest = ""

func _init(path):
	if path.ends_with("/"):
		path = path.substr(0, len(path)-1)
	if not path.begins_with("user://"):
		path = "user://"+path
	Directory.new().make_dir_recursive(path)
	_persistentDataPath = path
	_isGood = loadAll()

func isGood():
	return _isGood

func _getSuffixBase():
	var ret = KBEngine.app.clientVersion + "."
	ret += KBEngine.app.clientScriptVersion + "."
	ret += KBEngine.app.getInitArgs().ip + "."
	ret += str(KBEngine.app.getInitArgs().port)
	return ret

func _getSuffix():
	return _digest + "." + _getSuffixBase()

func loadAll():
	var kbengine_digest = loadFile(_persistentDataPath, "kbengine.digest." + _getSuffixBase(), false)
	if len(kbengine_digest) <= 0:
		clearMessageFiles()
		return false
	
	_digest = kbengine_digest.get_string_from_ascii()
	
	var loginapp_onImportClientMessages = loadFile(_persistentDataPath, "loginapp_clientMessages." + _getSuffix(), false)
	var baseapp_onImportClientMessages = loadFile(_persistentDataPath, "baseapp_clientMessages." + _getSuffix(), false)
	var onImportServerErrorsDescr = loadFile(_persistentDataPath, "serverErrorsDescr." + _getSuffix(), false)
	var onImportClientEntityDef = loadFile(_persistentDataPath, "clientEntityDef." + _getSuffix(), false)
	
	if len(loginapp_onImportClientMessages) > 0 and len(baseapp_onImportClientMessages) > 0:
		if not KBEngine.app.importMessagesFromMemoryStream(loginapp_onImportClientMessages,
				baseapp_onImportClientMessages, onImportClientEntityDef, onImportServerErrorsDescr):
			clearMessageFiles()
			return false

	return true

func onImportClientMessages(currserver, data):
	if currserver == "loginapp":
		createFile(_persistentDataPath, "loginapp_clientMessages." + _getSuffix(), data)
	else:
		createFile(_persistentDataPath, "baseapp_clientMessages." + _getSuffix(), data)

func onImportServerErrorsDescr(data):
	createFile(_persistentDataPath, "serverErrorsDescr." + _getSuffix(), data)

func onImportClientEntityDef(data):
	createFile(_persistentDataPath, "clientEntityDef." + _getSuffix(), data)

func onVersionNotMatch(verInfo, serVerInfo):
	clearMessageFiles()

func onScriptVersionNotMatch(verInfo, serVerInfo):
	clearMessageFiles()

func onServerDigest(currserver, serverProtocolMD5, serverEntitydefMD5):
	#We don't need to check the base's protocol, because when
	# logging in to the loginapp, the old protocol has been deleted if there is a problem with the protocol.
	if currserver == "baseapp":
		return
	
	if _digest != serverProtocolMD5 + serverEntitydefMD5:
		_digest = serverProtocolMD5 + serverEntitydefMD5
		clearMessageFiles()
	else:
		return
	
	if len(loadFile(_persistentDataPath, "kbengine.digest." + _getSuffixBase(), false)) == 0:
		createFile(_persistentDataPath, "kbengine.digest." + _getSuffixBase(), (serverProtocolMD5 + serverEntitydefMD5).to_ascii())

func clearMessageFiles():
	deleteFile(_persistentDataPath, "kbengine.digest." + _getSuffixBase())
	deleteFile(_persistentDataPath, "loginapp_clientMessages." + _getSuffix())
	deleteFile(_persistentDataPath, "baseapp_clientMessages." + _getSuffix())
	deleteFile(_persistentDataPath, "serverErrorsDescr." + _getSuffix())
	deleteFile(_persistentDataPath, "clientEntityDef." + _getSuffix())
	KBEngine.app.resetMessages()

func createFile(path, name, data):
	deleteFile(path, name)
	KBEngine.Dbg.DEBUG_MSG("createFile: "+path+"/"+name)
	var f = File.new()
	f.open(path+"/"+name, File.WRITE)
	f.store_buffer(PoolByteArray(data))
	f.close()
	
func loadFile(path, name, shouldPrintErr):
	var f = File.new()
	f.open(path+"/"+name, File.READ)
	
	var err = f.get_error()
	if err != OK:
		if shouldPrintErr:
			KBEngine.Dbg.ERROR_MSG("loadFile: "+path+"/"+name)
			KBEngine.Dbg.ERROR_MSG(str(err))
		return PoolByteArray([])
	
	var datas = f.get_buffer(f.get_len())
	f.close()
	
	KBEngine.Dbg.DEBUG_MSG("loadFile: "+path+"/"+name +", datasize="+str(len(datas)))
	return datas

func deleteFile(path, name):
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.remove(name)