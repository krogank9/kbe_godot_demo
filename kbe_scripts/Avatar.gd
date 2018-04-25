extends "res://kbe_scripts/GameObject.gd"

func __init__():
	if isPlayer():
		KBEngine.Event.registerIn("updatePlayer", self, "updatePlayer")
		KBEngine.Event.registerIn("jump", self, "jump")
	
func updatePlayer(currSpaceID, x, y, z, yaw):
	if currSpaceID > 0 and currSpaceID != KBEngine.app.spaceID:
		return
	
	var newpos = Vector3(x,y,z)
	if newpos.distance_to(position) < 10:
		position.x = x
		position.y = y
		position.z = z
	
	direction.z = yaw

func onJump():
	KBEngine.Event.fireOut("otherAvatarOnJump", [self])

func jump():
	cellCall("jump")