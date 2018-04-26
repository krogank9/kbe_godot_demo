extends "res://kbe_plugin/App.gd"

#KBEngine processing thread
class KBEThread:
	var app_
	var over = false
	
	func _init(app):
		app_ = app
	
	func run(thread_userdata):
		KBEngine.Dbg.INFO_MSG("KBEThread::run()")
		over = false
		
		app_.process()
		
		over = true
		KBEngine.Dbg.INFO_MSG("KBEThread::end()")

var _t = null
var kbethread = null

var threadUpdateHZ = 10

#removes cycles to do division in main loop
var threadUpdatePeriod = 1000.0 / threadUpdateHZ

#Whether the plug-in exits
var _isbreak = false

var _lasttime = OS.get_ticks_msec()

func _init(args).(args):
	threadUpdateHZ = args.threadUpdateHZ
	threadUpdatePeriod = 1000.0 / threadUpdateHZ
	
	kbethread = KBEThread.new(self)
	_t = Thread.new()
	_t.start(kbethread, "run")
	
func reset():
	_isbreak = false
	_lasttime = OS.get_ticks_msec()
	
	.reset()

func breakProcess():
	_isbreak = true

func isbreak():
	return _isbreak

func process():
	while not isbreak():
		.process()
		_thread_wait()
	
	Dbg.WARNING_MSG("KBEngineAppThread::process(): break!")

#Prevents full CPU and requires threads to wait for a while
func _thread_wait():
	var time_passed = OS.get_ticks_msec() - _lasttime
	
	var diff = threadUpdatePeriod - time_passed
	
	if diff < 0:
		diff = 0
	
	OS.delay_msec(diff)
	_lasttime = OS.get_ticks_msec()

func destroy():
	Dbg.WARNING_MSG("KBEngineAppThread::destroy()")
	breakProcess()
	
	var i = 0
	while not kbethread.over and i < 50:
		OS.delay_msec(100)
		i += 1
	
	if _t != null:
		pass#_t.Abort() #no way to abort thread in godot...
	_t = null
	
	.destroy()