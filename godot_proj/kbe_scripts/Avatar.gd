extends "res://kbe_scripts/GameObject.gd"

func __init__():
	if isPlayer():
		KBEngine.Event.registerIn("updatePlayer", self, "updatePlayer")
		KBEngine.Event.registerIn("jump", self, "jump")
		KBEngine.Event.registerIn("relive", self, "relive")

var posAtLastUpdate = null
func updatePlayer(currSpaceID, x, y, z, yaw):
	if currSpaceID > 0 and currSpaceID != KBEngine.app.spaceID:
		return
	
	# don't change position if position was forced back
	if posAtLastUpdate == null or position == posAtLastUpdate:
		position.x = x
		position.y = y
		position.z = z
	
	posAtLastUpdate = Vector3(position)
	direction.z = yaw

func onJump():
	KBEngine.Event.fireOut("otherAvatarOnJump", [self])

func jump():
	cellCall("jump")
	
func relive(type):
	cellCall("relive", [type])