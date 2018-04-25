enum ENTITYCALL_TYPE {
	ENTITYCALL_TYPE_CELL = 0,
	ENTITYCALL_TYPE_BASE = 1,
}

var id = 0
var className = ""
var type = ENTITYCALL_TYPE.ENTITYCALL_TYPE_CELL

var networkInterface_ = null
var bundle = null

func _init():
	networkInterface_ = KBEngine.app.networkInterface()
	
func __init__():
	pass
	
func isBase():
	return type == ENTITYCALL_TYPE.ENTITYCALL_TYPE_BASE

func isCell():
	return type == ENTITYCALL_TYPE.ENTITYCALL_TYPE_CELL

func newCall():
	if bundle == null:
		bundle = KBEngine.Bundle.createObject()
	
	if type == ENTITYCALL_TYPE.ENTITYCALL_TYPE_CELL:
		bundle.newMessage(KBEngine.Messages.messages["Baseapp_onRemoteCallCellMethodFromClient"])
	else:
		bundle.newMessage(KBEngine.Messages.messages["Entity_onRemoteMethodCall"])
	
	bundle.writeInt32(self.id)
	
	return bundle
	
func sendCall(inbundle):
	if inbundle == null:
		inbundle = bundle
	
	inbundle.send(networkInterface_)
	
	if inbundle == bundle:
		bundle = null