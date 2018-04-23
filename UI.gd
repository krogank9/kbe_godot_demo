extends Control

var avatarList = []

func err(msg):
	$versionInfo.add_color_override("font_color", Color(1,0,0))
	$debugInfo.add_color_override("font_color", Color(1,0,0))
	$debugInfo.text = msg

func info(msg):
	$versionInfo.add_color_override("font_color", Color(0,1,0))
	$debugInfo.add_color_override("font_color", Color(0,1,0))
	$debugInfo.text = msg

func _ready():
	$loginWindow.show()
	$avatarWindow.hide()
	#connection events
	KBEngine.Event.registerOut("onKicked", self, "onKicked")
	KBEngine.Event.registerOut("onDisconnected", self, "onDisconnected")
	KBEngine.Event.registerOut("onConnectionState", self, "onConnectionState")
	
	#login events
	KBEngine.Event.registerOut("onCreateAccountResult", self, "onCreateAccountResult")
	KBEngine.Event.registerOut("onLoginFailed", self, "onLoginFailed")
	KBEngine.Event.registerOut("onVersionNotMatch", self, "onVersionNotMatch")
	KBEngine.Event.registerOut("onScriptVersionNotMatch", self, "onScriptVersionNotMatch")
	KBEngine.Event.registerOut("onLoginBaseappFailed", self, "onLoginBaseappFailed")
	KBEngine.Event.registerOut("onLoginSuccessfully", self, "onLoginSuccessfully")
	KBEngine.Event.registerOut("onReloginBaseappFailed", self, "onReloginBaseappFailed")
	KBEngine.Event.registerOut("onReloginBaseappSuccessfully", self, "onReloginBaseappSuccessfully")
	KBEngine.Event.registerOut("onLoginBaseapp", self, "onLoginBaseapp")
	KBEngine.Event.registerOut("Loginapp_importClientMessages", self, "Loginapp_importClientMessages")
	KBEngine.Event.registerOut("Baseapp_importClientMessages", self, "Baseapp_importClientMessages")
	KBEngine.Event.registerOut("Baseapp_importClientEntityDef", self, "Baseapp_importClientEntityDef")
	
	#avatar selection events (defined by python scripts on server)
	KBEngine.Event.registerOut("onReqAvatarList", self, "onReqAvatarList")
	KBEngine.Event.registerOut("onCreateAvatarResult", self, "onCreateAvatarResult")
	KBEngine.Event.registerOut("onRemoveAvatar", self, "onRemoveAvatar")


func _process(delta):
	if (KBEngine.app.serverVersion != "" and KBEngine.app.serverVersion != KBEngine.app.clientVersion):
		err("client/server version mismatch: client(%s) != server(%s)"%[KBEngine.app.clientVersion,KBEngine.app.serverVersion])
	elif (KBEngine.app.serverScriptVersion != "" and KBEngine.app.serverScriptVersion != KBEngine.app.clientScriptVersion):
		err("client/server script version mismatch: client(%s) != server(%s)"%[KBEngine.app.clientScriptVersion,KBEngine.app.serverScriptVersion])
		
	$versionInfo.text = "client version: " + KBEngine.app.clientVersion
	$versionInfo.text += "\nclient script version: " + KBEngine.app.clientScriptVersion
	$versionInfo.text += "\nserver version: " + KBEngine.app.serverVersion
	$versionInfo.text += "\nserver script version: " + KBEngine.app.serverScriptVersion
	
	_avatar_process()

func _on_loginButton_pressed():
	info("Connecting to server...")
	KBEngine.Event.fireIn("login", [$loginWindow/usernameEdit.text, $loginWindow/passwordEdit.text, "kbengine_unity3d_demo".to_utf8()])

func _on_createButton_pressed():
	info("Connecting to server...")
	KBEngine.Event.fireIn("createAccount", [$loginWindow/usernameEdit.text, $loginWindow/passwordEdit.text, "kbengine_unity3d_demo".to_utf8()])


##########
# Events #
##########

# connection events

var startRelogin = true

func onKicked(failedcode):
	err("kicked, disconnected! reason=" + KBEngine.app.serverErr(failedcode));
	$loginWindow.show()
	$avatarWindow.hide()
	get_node("../World").hide()

func onDisconnected():
	err("disconnected! will try to reconnect...");
	var timer = Timer.new()
	startRelogin = true
	timer.connect("timeout", self, "onReloginBaseappTimer")
	timer.set_wait_time(1)
	timer.one_shot = true
	timer.start()

func onReloginBaseappTimer():
	if $loginWindow.visible:
		err("disconnected!")
		return
		
	if startRelogin:
		KBEngine.app.reloginBaseapp()
		var timer = Timer.new()
		timer.connect("timeout", self, "onReloginBaseappTimer")
		timer.set_wait_time(1)
		timer.one_shot = true
		timer.start()

func onConnectionState(success):
	if !success:
		err("error connecting to (" + KBEngine.app.getInitArgs().ip + ":" + str(KBEngine.app.getInitArgs().port) + ")!");
	else:
		info("connected successfully, please wait...");
	
#login events

func onCreateAccountResult(retcode, datas):
	if retcode != 0:
		err("createAccount returned error! err="+KBEngine.app.serverErr(retcode))
	
	if KBEngine.app.validEmail($loginWindow/usernameEdit.text):
		info("createAccount successful, please activate your email!")
	else:
		info("createAccount successful!")
	
func onLoginFailed(failcode):
	if failcode == 20:
		err("login failed, err=" + KBEngine.app.serverErr(failcode) + ", " + PoolByteArray(KBEngine.app.serverdatas()).get_string_from_ascii());
	else:
		err("login failed, err=" + KBEngine.app.serverErr(failcode));

func onVersionNotMatch(verInfo, serVerInfo):
	err("")

func onScriptVersionNotMatch(verInfo, serVerInfo):
	err("")

func onLoginBaseappFailed(failcode):
	err("loginBaseapp failed, err="+KBEngine.app.serverErr(failcode))

func onLoginSuccessfully(rndUUID, eid, accountEntity):
	info("login successful!")
	clearAvatarList()
	$avatarWindow.show()
	$loginWindow.hide()
	#SceneManager.LoadScene("selavatars");

func onReloginBaseappFailed(failcode):
	err("relogin failed, err="+KBEngine.app.serverErr(failcode))
	startRelogin = false

func onReloginBaseappSuccessfully():
	info("relogin successful!")
	startRelogin = false

func onLoginBaseapp():
	info("connecting to Baseapp, please wait...")

func Loginapp_importClientMessages():
	info("Loginapp_importClientMessages ...")

func Baseapp_importClientMessages():
	info("Baseapp_importClientMessages ...")

func Baseapp_importClientEntityDef():
	info("Baseapp_importClientEntityDef ...")

#avatar selection events (defined by python scripts on server)

var selAvatarDBID = 0
class AvatarButton extends Button:
	var dbid
	var ui
	func _init(dbid, ui):
		self.dbid = dbid
		self.ui = ui
	func _pressed():
		ui.selAvatarDBID = self.dbid

func onReqAvatarList(newAvatarList):
	avatarList = newAvatarList
	clearAvatarList()
	var x = 0
	for dbid in avatarList.keys():
		var info = avatarList[dbid]
		var name = info["name"]
		var idbid = info["dbid"]
		var button = AvatarButton.new(idbid, self)
		$avatarWindow/AvatarList.add_child(button)
		button.text = name
		button.rect_size.x = 125
		button.rect_size.y = 35
		button.rect_position.x += x
		x += button.rect_size.x + 10

func onCreateAvatarResult(retcode, info, newAvatarList):
	if retcode != 0:
		err("Error creating avatar, errcode=" + str(retcode))
		return
	
	onReqAvatarList(newAvatarList)

func onRemoveAvatar(dbid, newAvatarList):
	if dbid == 0:
		err("Error deleting avatar")
	
	onReqAvatarList(newAvatarList)

#avatar selection code

func _avatar_process():
	if KBEngine.app.entity_type == "Account":
		var account = KBEngine.app.player();
		if account != null:
			avatarList = account.avatars
			if avatarList != account.avatars:
				onReqAvatarList(account.avatars)

func clearAvatarList():
	for child in $avatarWindow/AvatarList.get_children():
		child.queue_free()

func _on_EnterGame_pressed():
	if selAvatarDBID == 0:
		err("Please select an Avatar!")
	else:
		info("Please wait...")
		KBEngine.Event.fireIn("selectAvatarGame", [selAvatarDBID])
		$avatarWindow.hide()
		$loginWindow.hide()
		get_node("../World").show()
		#SceneManager.LoadScene("world");

func _on_CreateAvatar_pressed():
	$avatarWindow/createAvatarPanel.show()

func _on_RemoveAvatar_pressed():
	if selAvatarDBID == 0:
		err("Please select an Avatar to remove!")
	else:
		info("Please wait...")
		if len(avatarList) > 0:
			var avatarinfo = avatarList[selAvatarDBID]
			KBEngine.Event.fireIn("reqRemoveAvatar", [avatarinfo["name"]])

func _on_CreateAvatarConfirm_pressed():
	var name = $avatarWindow/createAvatarPanel/EditAvatarName.text
	if len(name) > 1:
		KBEngine.Event.fireIn("reqCreateAvatar", [1, name])
	else:
		err("avatar name is too short!")
	$avatarWindow/createAvatarPanel.hide()