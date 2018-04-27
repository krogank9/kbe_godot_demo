extends Spatial

onready var UI = get_node("../UI")
var PlayerScene = preload("res://Player.tscn")
var OtherPlayerScene = preload("res://OtherPlayer.tscn")
var CharScene = preload("res://Char.tscn")

var player = weakref(Reference.new())

var playerYVel = 0
var groundHeight = 1.5
var jumpVel = 20

func addInstance(scene, pos, dir):
	var node = scene.instance()
	$Entities.add_child(node)
	node.translation = pos
	node.rotation = dir
	return node

func clearWorld():
	if player.get_ref() != null:
		player.get_ref().queue_free()
	for child in $Entities.get_children():
		child.queue_free()
	
func convert_dir(v):
	return Vector3(v.x, v.z, v.y)

func convert_pos(v):
	return Vector3(v.x, v.y, v.z)

func _ready():
	# protocol world events
	KBEngine.Event.registerOut("addSpaceGeometryMapping", self, "addSpaceGeometryMapping")
	KBEngine.Event.registerOut("onEnterWorld", self, "onEnterWorld")
	KBEngine.Event.registerOut("onLeaveWorld", self, "onLeaveWorld")
	KBEngine.Event.registerOut("set_position", self, "set_position")
	KBEngine.Event.registerOut("set_direction", self, "set_direction")
	KBEngine.Event.registerOut("updatePosition", self, "updatePosition")
	KBEngine.Event.registerOut("onControlled", self, "onControlled")
	
	# script world events
	KBEngine.Event.registerOut("onAvatarEnterWorld", self, "onAvatarEnterWorld")
	KBEngine.Event.registerOut("set_HP", self, "set_HP")
	KBEngine.Event.registerOut("set_MP", self, "set_MP")
	KBEngine.Event.registerOut("set_HP_Max", self, "set_HP_Max")
	KBEngine.Event.registerOut("set_MP_Max", self, "set_MP_Max")
	KBEngine.Event.registerOut("set_level", self, "set_level")
	KBEngine.Event.registerOut("set_name", self, "set_entityName")
	KBEngine.Event.registerOut("set_state", self, "set_state")
	KBEngine.Event.registerOut("set_moveSpeed", self, "set_moveSpeed")
	KBEngine.Event.registerOut("set_modelScale", self, "set_modelScale")
	KBEngine.Event.registerOut("set_modelID", self, "set_modelID")
	KBEngine.Event.registerOut("recvDamage", self, "recvDamage")
	KBEngine.Event.registerOut("otherAvatarOnJump", self, "otherAvatarOnJump")
	KBEngine.Event.registerOut("onAddSkill", self, "onAddSkill")

func _process(delta):
	if self.visible:
		createPlayer()
		_player_process(delta)
	
func _player_process(delta):
	if player.get_ref() == null:
		return
	var _player = player.get_ref()
	
	var speed = _player.moveSpeed
	var direction = Vector3(0,0,0)
	var rotchange = 0
	if Input.is_action_pressed("ui_left"):
		rotchange = 5 * delta
	elif Input.is_action_pressed("ui_right"):
		rotchange = -5 * delta
	_player.rotation.y += rotchange
	
	if Input.is_action_pressed("ui_up"):
		direction.z -= 1
	elif Input.is_action_pressed("ui_down"):
		direction.z += 1
	var change = direction.normalized() * speed * delta
	
	_player.translate_object_local(change)
	_player.destPos = _player.translation
	
	if Input.is_key_pressed(KEY_SPACE) and _player.translation.y == groundHeight:
		player.get_ref().queueJump = true
		KBEngine.Event.fireIn("jump")
		#KBEngine.app.player().isOnGround = false
	
	#UI.info("player pos: (%s,%s,%s)" % [KBEngine.app.player().position.x, KBEngine.app.player().position.y, KBEngine.app.player().position.z])
	var pos = convert_pos(_player.translation)
	KBEngine.Event.fireIn("updatePlayer", [KBEngine.app.spaceID, pos.x, groundHeight, pos.z, _player.rotation.y])

func createPlayer():
	if player.get_ref() != null:
		return
	
	if KBEngine.app.entity_type != "Avatar":
		return
	print("creating player")
	var avatar = KBEngine.app.player()
	if avatar == null or (avatar.position.x == 0 and avatar.position.y == 0 and avatar.position.z == 0):
		return
	
	var pos = Vector3(avatar.position)
	if avatar.isOnGround:
		pos.y = groundHeight

	avatar.renderObj = addInstance(PlayerScene, pos, convert_dir(avatar.direction))
	player = weakref(avatar.renderObj)
	
	set_position(avatar)
	set_direction(avatar)
	
# protocol world events

func addSpaceGeometryMapping(respath):
	UI.info("scene(%s), spaceID=%s" % [respath, KBEngine.app.spaceID])

func onEnterWorld(entity):
	if entity.isPlayer():
		createPlayer()
		return
	
	var pos = convert_pos(entity.position)
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
	
	entity.renderObj.queue_free()
	
func set_position(entity):
	if entity.renderObj == null:
		return

	var pos = convert_pos(entity.position)
	if entity.isOnGround:
		pos.y = groundHeight
	entity.renderObj.destPos = pos
	entity.renderObj.translation.x = pos.x
	entity.renderObj.translation.z = pos.z

func set_direction(entity):
	if entity.renderObj == null:
		return
	
	entity.renderObj.rotation = convert_dir(entity.direction)

func updatePosition(entity):
	if entity.renderObj == null:
		return
	
	var pos = convert_pos(entity.position)
	if entity.isOnGround:
		pos.y = groundHeight
	entity.renderObj.destPos = pos

func onControlled(entity, isControlled):
	if entity.renderObj == null:
		return
		
# script world events

func set_HP(entity, val):
	if entity.renderObj == null:
		return
	entity.renderObj.HP = val

func set_MP(entity, val):
	pass

func set_HP_Max(entity, val):
	if entity.renderObj == null:
		return
	entity.renderObj.HP_max = val

func set_MP_Max(entity, val):
	pass

func set_level(entity, val):
	pass

func get_english_name(name):
	if name == "怪物1":
		return "Monster1"
	elif name == "怪物2":
		return "Monster2"
	elif name == "传送员":
		return "Transporter"
	elif name == "新手接待员":
		return "Novice receptionist"
	elif name == "传送门(teleport-local)":
		return "teleport-local"
	elif name == "传送门(teleport-back)":
		return "Portal (teleport back)"
	elif name == "传送门":
		return "Portal"
	else:
		return name
func set_entityName(entity, val):
	if entity.renderObj == null:
		return
	entity.renderObj.entity_name = get_english_name(val)

func set_state(entity, val):
	pass

func set_moveSpeed(entity, val):
	if entity.renderObj == null:
		return
	entity.renderObj.moveSpeed = val/10.0

func set_modelScale(entity, val):
	pass

func set_modelID(entity, val):
	pass

func recvDamage(entity, attacker, skillID, damageType, damage):
	pass

func otherAvatarOnJump(entity):
	if entity.renderObj == null:
		return
	entity.renderObj.queueJump = true

func onAddSkill(entity):
	pass