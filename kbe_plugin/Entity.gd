#KBEngine logic layer entity base class
#All game entities should extend this class

#The current player's last sync to the server's position and orientation
#These two properties are for the engine, do not modify elsewhere
var _entityLastLocalPos = Vector3(0,0,0)
var _entityLastLocalDir = Vector3(0,0,0)

var id = 0
var className = ""
var position = Vector3(0,0,0)
var direction = Vector3(0,0,0)
var velocity = 0

var isOnGround = true

var renderObj = null

var baseEntityCall = null
var cellEntityCall = null

var inWorld = false

#For the local player, it indicates whether he is controlled by other players;
#For other entities, indicates whether this machine controls the entity
var isControlled = false

#Set to true after __init__() call
var inited = false

#Entitydef property, the server is synchronized and stored here.
var defpropertys_ = {}

var iddefpropertys_ = {}

func _init():
	# kbengine not initialized, must be creating dummy entity for type checking
	if not KBEngine or not KBEngine.Helpers:
		return
	className = KBEngine.Helpers.getClassNameFromObj(self)
	for e in KBEngine.EntityDef.moduledefs[className].propertys.values():
		var newp = KBEngine.Property.new()
		newp.name = e.name
		newp.utype = e.utype
		newp.properUtype = e.properUtype
		newp.properFlags = e.properFlags
		newp.aliasID = e.aliasID
		newp.defaultValStr = e.defaultValStr
		newp.setmethod = e.setmethod
		newp.val = newp.utype.parseDefaultValStr(newp.defaultValStr)
		defpropertys_[e.name] = newp
		iddefpropertys_[e.properUtype] = newp

func onDestroy():
	pass

func isPlayer():
	return id == KBEngine.app.entity_id

func addDefinedProperty(name, v):
	var newp = KBEngine.Property.new()
	newp.name = name
	newp.properUtype = 0
	newp.val = v
	newp.setmethod = null
	defpropertys_[name] = newp

func getDefinedProperty(name):
	if not defpropertys_.has(name):
		return null
	else:
		return defpropertys_[name].val

func setDefinedProperty(name, val):
	defpropertys_[name].val = val

func getDefinedPropertyByUType(utype):
	if not iddefpropertys_.has(utype):
		return null
	else:
		return iddefpropertys_[utype].val

func setDefinedPropertyByUType(utype, val):
	iddefpropertys_[utype].val = val

#The Kbengine entity constructor that corresponds to the
# server script.
#This constructor exists because KBE needs to create a good
# entity and populate data such as attributes to tell the
# script layer to initialize
func __init__():
	pass

func callPropertysSetMethods():
	for prop in iddefpropertys_.values():
		var oldval = getDefinedPropertyByUType(prop.properUtype)
		var setmethod = prop.setmethod
		
		if setmethod != null:
			if prop.isBase():
				if inited and not inWorld:
					self.call(setmethod, oldval)
			else:
				if inWorld:
					if prop.isOwnerOnly() and not isPlayer():
						continue
					self.call(setmethod, oldval)

func baseCall(methodname, arguments=null):
	if arguments == null:
		arguments = []
	
	if KBEngine.app.currserver == "loginapp":
		KBEngine.Dbg.ERROR_MSG(className + "::baseCall(" + methodname + "), currserver=!" + KBEngine.app.currserver)
		return
	
	if not KBEngine.EntityDef.moduledefs.has(className):
		KBEngine.Dbg.ERROR_MSG("entity::baseCall:  entity-module(" + className + ") error, can not find in EntityDef.moduledefs")
		return
	var module = KBEngine.EntityDef.moduledefs[className]

	if not module.base_methods.has(methodname):
		KBEngine.Dbg.ERROR_MSG(className + "::baseCall(" + methodname + "), method not found")
		return
	var method = module.base_methods[methodname]
	
	var methodID = method.methodUtype
	
	if len(arguments) != len(method.args):
		KBEngine.Dbg.ERROR_MSG(className + "::baseCall(" + methodname + "): args(" + str(len(arguments)) + " != " + str(len(method.args)) + ") error, wrong number of arguments!")
		return
	
	baseEntityCall.newCall()
	baseEntityCall.bundle.writeUint16(methodID)
	
	for i in range(len(arguments)):
		if method.args[i].isSameType(arguments[i]):
			method.args[i].addToStream(baseEntityCall.bundle, arguments[i])
		else:
			var err_text = "arg" + str(i) + " ("+str(arguments[i])+") is not " + method.args[i].TYPENAME()
			KBEngine.Dbg.ERROR_MSG(className + "::baseCall(method=" + methodname + "): args type error(" + err_text + ")!")
			baseEntityCall.bundle = null
			return
	
	baseEntityCall.sendCall(null)

func cellCall(methodname, arguments):
	if KBEngine.app.currserver == "loginapp":
		KBEngine.Dbg.ERROR_MSG(className + "::cellCall(" + methodname + "), currserver=!" + KBEngine.app.currserver)
		return
	
	if not KBEngine.EntityDef.moduledefs.has(className):
		KBEngine.Dbg.ERROR_MSG("entity::cellCall:  entity-module(" + className + ") error, can not find in EntityDef.moduledefs")
		return
	var module = KBEngine.EntityDef.moduledefs[className]

	if not module.cell_methods.has(methodname):
		KBEngine.Dbg.ERROR_MSG(className + "::cellCall(" + methodname + "), method not found")
		return
	var method = module.cell_methods[methodname]
	
	var methodID = method.methodUtype
	
	if len(arguments) != len(method.args):
		KBEngine.Dbg.ERROR_MSG(className + "::cellCall(" + methodname + "): args(" + str(len(arguments)) + " != " + str(len(method.args)) + ") error, wrong number of arguments!")
		return
	
	if cellEntityCall == null:
		KBEngine.Dbg.ERROR_MSG(className + "::cellCall(" + methodname + "): no cell!")
		return
	
	cellEntityCall.newCall()
	cellEntityCall.bundle.writeUint16(methodID)
	
	for i in range(len(arguments)):
		if method.args[i].isSameType(arguments[i]):
			method.args[i].addToStream(baseEntityCall.bundle, arguments[i])
		else:
			var err_text = "arg" + String(i) + ": " + String(method.args[i])
			KBEngine.Dbg.ERROR_MSG(className + "::cellCall(method=" + methodname + "): args type error(" + err_text + ")!")
			cellEntityCall.bundle = null
			return
	
	cellEntityCall.sendCall(null)

func enterWorld():
	inWorld = true
	onEnterWorld()
	KBEngine.Event.fireOut("onEnterWorld", [self])

func onEnterWorld():
	pass

func leaveWorld():
	inWorld = false
	onLeaveWorld()
	KBEngine.Event.fireOut("onLeaveWorld", [self])

func onLeaveWorld():
	pass

func enterSpace():
	inWorld = true
	onEnterSpace()
	KBEngine.Event.fireOut("onEnterSpace", [self])
	
	#To immediately refresh the position of the 
	# render layer object
	KBEngine.Event.fireOut("set_position", [self])
	KBEngine.Event.fireOut("set_direction", [self])

func onEnterSpace():
	pass

func leaveSpace():
	inWorld = false
	onLeaveSpace()
	KBEngine.Event.fireOut("onLeaveSpace", [self])

func onLeaveSpace():
	pass

func set_position(old):
	position = getDefinedProperty("position")
	
	if isPlayer():
		KBEngine.app.entityServerPos(position)
	
	if inWorld:
		KBEngine.Event.fireOut("set_position", [self])

func onUpdateVolatileData():
	pass

func set_direction(old):
	direction = getDefinedProperty("direction")
	
	if inWorld:
		KBEngine.Event.fireOut("set_direction", [self])

#This callback method is called when the local entity
# control by the client has been enabled or disabled. 
#See the Entity.controlledBy() method in the CellApp
# server code for more infomation.
#param "isControlled_":
#For the player himself, it indicates whether he is controlled by other players;
#For other entities, indicates whether my machine controls the entity
func onControlled(isControlled_):
	pass