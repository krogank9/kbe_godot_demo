extends Spatial

var UI
var PlayerScene = preload("res://Player.tscn")
var CharScene = preload("res://Char.tscn")

var player = null

func addInstance(scene, pos, dir):
	var node = scene.instance()
	add_child(node)
	node.translation = pos
	node.rotation = dir
	return node
	
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
	var speed = 10
	var direction = Vector3(0,0,0)
	if Input.is_action_pressed("ui_left"):
		player.rotation.y += 5 * delta
	elif Input.is_action_pressed("ui_right"):
		player.rotation.y -= 5 * delta
	
	if Input.is_action_pressed("ui_up"):
		direction.z -= 1
	elif Input.is_action_pressed("ui_down"):
		direction.z += 1
	var change = direction.normalized() * speed * delta
	player.translate_object_local(change)

func createPlayer():
	if player != null:
		return
	
	if KBEngine.app.entity_type != "Avatar":
		return
	var avatar = KBEngine.app.player()
	if avatar == null:
		return
	
	var pos = Vector3(avatar.position)
	if avatar.isOnGround:
		pos.y = 1.3

	player = addInstance(PlayerScene, pos, Vector3(avatar.direction))
	avatar.renderObj = player
	
	set_position(avatar)
	set_direction(avatar)
	
# world events

func addSpaceGeometryMapping(respath):
	UI.info("scene(%s), spaceID=%s" % [respath, KBEngine.app.spaceID])

func onEnterWorld(entity):
	if entity.isPlayer():
		return
	var y = entity.position.y
	if entity.isOnGround:
		y = 1.3
	var pos = Vector3(entity.position.x, y, entity.position.z)
	
	entity.renderObj = addInstance(CharScene, pos, convert_dir(entity.direction))
	entity.renderObj.set_name(entity.className+"_"+str(entity.id))

func onLeaveWorld(entity):
	if entity.renderObj == null:
		return
	
	entity.renderObj.queue_free()
	entity.renderObj = null
	
func set_position(entity):
	if entity.renderObj == null:
		return
	KBEngine.Dbg.DEBUG_MSG(str(entity.position))
	entity.renderObj.translation = Vector3(entity.position)

func set_direction(entity):
	if entity.renderObj == null:
		return
	
	entity.renderObj.rotation = convert_dir(entity.direction)

func updatePosition(entity):
	if entity.renderObj == null:
		return
	
	entity.renderObj.translation = Vector3(entity.position)

func onControlled(entity, isControlled):
	if entity.renderObj == null:
		return