extends Button

func _pressed():
	KBEngine.Event.fireIn("relive", [0])