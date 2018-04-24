extends Spatial

var UI
var PlayerScene = preload("res://Player.tscn")
var OtherPlayerScene = preload("res://OtherPlayer.tscn")
var CharScene = preload("res://Char.tscn")

var player = null
var playerYVel = 0
var groundHeight = 1.5

func addInstance(scene, pos, dir):
	var node = scene.instance()
	$Entities.add_child(node)
	node.translation = pos
	node.rotation = dir
	return node

func clearWorld():
	if player != null:
		player.queue_free()
		player = null
	for child in $Entities.get_children():
		child.queue_free()
	
func convert_dir(v):
	return Vector3(v.x, v.z, v.y)

func _ready():
	UI = get_node("../UI")
	# in world
	KBEngine.Event.registerOut("addSpaceGeometryMapping", self, "addSpaceGeometryMapping")
	KBEngine.Event.registerOut("onEnterWorld", self, "onEnterWorld")
	KBEngine.Event.registerOut("onLeaveWorld", self, "onLeaveWorld")
	KBEngine.Event.registerOut("set_position", self, "set_position")
	KBEngine.Event.registerOut("set_direction", self, "set_direction")
	KBEngine.Event.registerOut("updatePosition", self, "updatePosition")
	KBEngine.Event.registerOut("onControlled", self, "onControlled")

func _process(delta):
	createPlayer()
	if player != null:
		_player_process(delta)
	
func _player_process(delta):
	if player == null:
		return
	var speed = 10
	var direction = Vector3(0,0,0)
	var rotchange = 0
	if Input.is_action_pressed("ui_left"):
		rotchange = 5 * delta
	elif Input.is_action_pressed("ui_right"):
		rotchange = -5 * delta
	player.rotation.y += rotchange
	
	if Input.is_action_pressed("ui_up"):
		direction.z -= 1
	elif Input.is_action_pressed("ui_down"):
		direction.z += 1
	var change = direction.normalized() * speed * delta
	
	playerYVel -= 1*delta
	if player.translation.y <= groundHeight:
		player.translation.y = groundHeight
		playerYVel = 0
		KBEngine.app.player().isOnGround = true
	if Input.is_key_pressed(KEY_SPACE) and player.translation.y == groundHeight:
		playerYVel = 20*delta
		KBEngine.app.player().isOnGround = false
	change.y += playerYVel
	player.translate_object_local(change)
	
	UI.info("player pos: (%s,%s,%s)" % [KBEngine.app.player().position.x, KBEngine.app.player().position.y, KBEngine.app.player().position.z])
	KBEngine.Event.fireIn("updatePlayer", [KBEngine.app.spaceID, player.translation.x, player.translation.y, player.translation.z, player.rotation.y])

func createPlayer():
	if player != null:
		return
	
	if KBEngine.app.entity_type != "Avatar":
		return
	var avatar = KBEngine.app.player()
	if avatar == null or (avatar.position.x == 0 and avatar.position.y == 0 and avatar.position.z == 0):
		return
	
	var pos = Vector3(avatar.position)
	if avatar.isOnGround:
		pos.y = groundHeight

	player = addInstance(PlayerScene, pos, convert_dir(avatar.direction))
	avatar.renderObj = player
	
	set_position(avatar)
	set_direction(avatar)
	
# world events

func addSpaceGeometryMapping(respath):
	UI.info("scene(%s), spaceID=%s" % [respath, KBEngine.app.spaceID])

func onEnterWorld(entity):
	if entity.isPlayer():
		return
	
	var pos = Vector3(entity.position)
	if entity.isOnGround:
		pos.y = groundHeight
	
	if entity.className == "Avatar":
		entity.renderObj = addInstance(OtherPlayerScene, pos, convert_dir(entity.direction))
	else:
		entity.renderObj = addInstance(CharScene, pos, convert_dir(entity.direction))
	entity.renderObj.set_name(entity.className+"_"+str(entity.id))

func onLeaveWorld(entity):
	if entity.renderObj == null:
		return
	
	if entity.renderObj == player:
		player = null
	
	entity.renderObj.queue_free()
	entity.renderObj = null
	
func set_position(entity):
	if entity.renderObj == null:
		return

	var pos = Vector3(entity.position)
	if entity.isOnGround:
		pos.y = groundHeight
	entity.renderObj.translation = pos

func set_direction(entity):
	if entity.renderObj == null:
		return
	
	entity.renderObj.rotation = convert_dir(entity.direction)

func updatePosition(entity):
	if entity.renderObj == null:
		return
	
	var pos = Vector3(entity.position)
	if entity.isOnGround:
		pos.y = groundHeight
	entity.renderObj.translation = pos

func onControlled(entity, isControlled):
	if entity.renderObj == null:
		return