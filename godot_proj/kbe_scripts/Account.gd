extends "res://kbe_scripts/GameObject.gd"

var avatars = {}

func __init__():
	print("account __init__()")
	KBEngine.Event.registerIn("reqCreateAvatar", self, "reqCreateAvatar")
	KBEngine.Event.registerIn("reqRemoveAvatar", self, "reqRemoveAvatar")
	KBEngine.Event.registerIn("selectAvatarGame", self, "selectAvatarGame")
	
	KBEngine.Event.fireOut("onLoginSuccessfully", [KBEngine.app.entity_uuid, self.id, self])
	
	baseCall("reqAvatarList")
	
func onCreateAvatarResult(retcode, info):
	if retcode == 0:
		avatars[info["dbid"]] = info
		KBEngine.Dbg.DEBUG_MSG("Account::onCreateAvatarResult: name=" + info["name"])
	else:
		KBEngine.Dbg.ERROR_MSG("Account::onCreateAvatarResult: retcode=%s" % retcode)
	
	# ui event
	KBEngine.Event.fireOut("onCreateAvatarResult", [retcode, info, avatars])

func onRemoveAvatar(dbid):
	KBEngine.Dbg.DEBUG_MSG("Account::onRemoveAvatar: dbid=%s" % dbid)
	avatars.erase(dbid)
	KBEngine.Event.fireOut("onRemoveAvatar", [dbid, avatars])

func onReqAvatarList(infos):
	avatars.clear()
	var listinfos = infos["values"]
	
	KBEngine.Dbg.DEBUG_MSG("Account::onReqAvatarList: avatars size=%s" % len(listinfos))
	for i in range(len(listinfos)):
		var info = listinfos[i]
		KBEngine.Dbg.DEBUG_MSG("Account::onReqAvatarList: name%s=%s" % [ i, info["name"] ])
		avatars[info["dbid"]] = info
	
	# ui event
	KBEngine.Event.fireOut("onReqAvatarList", [avatars.duplicate()])

func reqCreateAvatar(roleType, name):
	KBEngine.Dbg.DEBUG_MSG("Account::reqCreateAvatar: roleType=%s" % roleType)
	baseCall("reqCreateAvatar", [roleType, name])

func reqRemoveAvatar(name):
	KBEngine.Dbg.DEBUG_MSG("Account::reqRemoveAvatar: name=" + name)
	baseCall("reqRemoveAvatar", [name])

func selectAvatarGame(dbid):
	KBEngine.Dbg.DEBUG_MSG("Account::selectAvatarGame: dbid=%s" % dbid)
	baseCall("selectAvatarGame", [dbid])