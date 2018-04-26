extends "res://kbe_plugin/Entity.gd"

func renderObj():
	return renderObj.get_ref()

func set_HP(old):
	var v = getDefinedProperty("HP")
	KBEngine.Event.fireOut("set_HP", [self, v])

func set_MP(old):
	var v = getDefinedProperty("MP")
	KBEngine.Event.fireOut("set_MP", [self, v])

func set_HP_Max(old):
	var v = getDefinedProperty("HP_Max")
	KBEngine.Event.fireOut("set_HP_Max", [self, v])

func set_MP_Max(old):
	var v = getDefinedProperty("MP_Max")
	KBEngine.Event.fireOut("set_MP_Max", [self, v])

func set_level(old):
	var v = getDefinedProperty("level")
	KBEngine.Event.fireOut("set_level", [self, v])

func set_name(old):
	var v = getDefinedProperty("name")
	KBEngine.Event.fireOut("set_name", [self, v])

func set_state(old):
	var v = getDefinedProperty("state")
	KBEngine.Event.fireOut("set_state", [self, v])

func set_subState(old):
	pass

func set_utype(old):
	pass

func set_uid(old):
	pass

func set_spaceUType(old):
	pass

func set_moveSpeed(old):
	var v = getDefinedProperty("moveSpeed")
	KBEngine.Event.fireOut("set_moveSpeed", [self, v])

func set_modelScale(old):
	var v = getDefinedProperty("modelScale")
	KBEngine.Event.fireOut("set_modelScale", [self, v])

func set_modelID(old):
	var v = getDefinedProperty("modelID")
	KBEngine.Event.fireOut("set_modelID", [self, v])

func set_forbids(old):
	pass

func recvDamage(attackerID, skillID, damageType, damage):
	var ent = KBEngine.app.findEntity(attackerID)
	KBEngine.Event.fireOut("recvDamage", [self, ent, skillID, damageType, damage])