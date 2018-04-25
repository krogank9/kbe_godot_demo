#Event class
#KBEngine plug-in layer interacts with Godot rendering
# layer through events

class Pair:
	var wref
	var funcname

class EventObj:
	var info
	var args

var mutex_events_out = Mutex.new()
var events_out = {}

var firedEvents_out = []
var doingEvents_out = []

var mutex_events_in = Mutex.new()
var events_in = {}

var firedEvents_in = []
var doingEvents_in = []

func lock_events_mutex(events_obj):
	if events_obj == events_in:
		mutex_events_in.lock()
	else:
		mutex_events_out.lock()

func unlock_events_mutex(events_obj):
	if events_obj == events_in:
		mutex_events_in.unlock()
	else:
		mutex_events_out.unlock()

func clear():
	events_out.clear()
	events_in.clear()
	clearFiredEvents()

func clearFiredEvents():
	lock_events_mutex(events_out)
	firedEvents_out.clear()
	unlock_events_mutex(events_out)
	
	doingEvents_out.clear()
	
	lock_events_mutex(events_in)
	firedEvents_in.clear()
	unlock_events_mutex(events_in)
	
	doingEvents_in.clear()
	
func hasRegisterOut(eventname):
	return _hasRegister(events_out, eventname)

func hasRegisterIn(eventname):
	return _hasRegister(events_in, eventname)
	
func _hasRegister(events, eventname):
	var has = false
	
	lock_events_mutex(events)
	has = events.has(eventname)
	unlock_events_mutex(events)
	
	return has
	
#Register to listen for events thrown out by the KBE plugin. (out = kbe->render)
#Usually registered by the rendering layer for things like
# monitoring the change in HP of a character.
#If the UI registers an HP change event, after the event is
# triggered, the HP value displayed can be changed according
# to the current updated HP value attached to the event
func registerOut(eventname, obj, funcname):
	return register(events_out, eventname, obj, funcname)

#Register to listen for events thrown in to the plugin by
# the rendering layer (in = render->kbe)
#For example: The login button is clicked on the UI layer,
# at which point an event needs to be triggered on the KBE
# plugin layer for it to handle the interaction with the server
func registerIn(eventname, obj, funcname):
	return register(events_in, eventname, obj, funcname)
	
func register(events, eventname, obj, funcname):
	deregister(events, eventname, obj, funcname)

	if not obj.has_method(funcname):
		KBEngine.Dbg.ERROR_MSG("Event::register: method '"+funcname+"' not found in "+str(obj))
		return false
	
	var pair = Pair.new()
	pair.wref = weakref(obj)
	pair.funcname = funcname
	
	lock_events_mutex(events)

	if not events.has(eventname):
		events[eventname] = [pair]
	else:
		events[eventname].append(pair)
	
	unlock_events_mutex(events)
	
	return true

func deregisterOut(eventname_or_obj, obj=null, funcname=null):
	if obj == null and funcname == null:
		return deregisterAll(events_out, eventname_or_obj)
	else:
		return deregister(events_out, eventname_or_obj, obj, funcname)

func deregisterIn(eventname_or_obj, obj=null, funcname=null):
	if obj == null and funcname == null:
		return deregisterAll(events_in, eventname_or_obj)
	else:
		return deregister(events_in, eventname_or_obj, obj, funcname)

func deregister(events, eventname, obj, funcname):
	lock_events_mutex(events)
	
	if not events.has(eventname):
		unlock_events_mutex(events)
		return false
	
	var lst = events[eventname]
	var i = 0
	while i < len(lst):
		if lst[i].wref.get_ref() == obj and lst[i].funcname == funcname:
			lst.remove(i)
			unlock_events_mutex(events)
			return true
		i += 1
	
	unlock_events_mutex(events)
	return false

func deregisterAll(events, obj):
	lock_events_mutex(events)
	
	for key in events.keys():
		var lst = events[key]
		var i = len(lst) - 1
		while i >= 0:
			if lst[i].wref.get_ref() == obj:
				lst.remove(i)
			i -= 1
	
	unlock_events_mutex(events)
	return true
	
func deregisterAllFromWeakref(events, wref):
	lock_events_mutex(events)
	
	for key in events.keys():
		var lst = events[key]
		var i = len(lst) - 1
		while i >= 0:
			if lst[i].wref == wref:
				lst.remove(i)
			i -= 1
	
	unlock_events_mutex(events)
	return true

func fireOut(eventname, args=null):
	if args == null:
		args = []
	#KBEngine.Dbg.DEBUG_MSG("Fired out event '%s'" % eventname)
	fire_(events_out, firedEvents_out, eventname, args)

func fireIn(eventname, args=[]):
	#KBEngine.Dbg.DEBUG_MSG("Fired in event '%s'" % eventname)
	fire_(events_in, firedEvents_in, eventname, args)

#Triggers events that can be received by both the plug-in and rendering layers
func fireAll(eventname, args=[]):
	fire_(events_in, firedEvents_in, eventname, args)
	fire_(events_out, firedEvents_out, eventname, args)

func fire_(events, firedEvents, eventname, args):
	lock_events_mutex(events)
	
	if not events.has(eventname):
		if events == events_in:
			KBEngine.Dbg.WARNING_MSG("Event::fireIn: event(%s) not found!" % eventname)
		else:
			KBEngine.Dbg.WARNING_MSG("Event::fireOut: event(%s) not found!" % eventname)
		unlock_events_mutex(events)
		return
	
	for el in events[eventname]:
		var eobj = EventObj.new()
		eobj.info = el
		eobj.args = args
		firedEvents.push_back(eobj)
	
	unlock_events_mutex(events)

func processOutEvents():
	lock_events_mutex(events_out)
	
	doingEvents_out = firedEvents_out
	firedEvents_out = []
	
	unlock_events_mutex(events_out)
	
	for eobj in doingEvents_out:
		var obj = eobj.info.wref.get_ref()
		if obj:
			obj.callv(eobj.info.funcname, eobj.args)
		else:
			deregisterAllFromWeakref(events_out, eobj.info.wref)
	doingEvents_out.clear()

func processInEvents():
	lock_events_mutex(events_in)
	
	doingEvents_in = firedEvents_in
	firedEvents_in = []
	
	unlock_events_mutex(events_in)
	
	for eobj in doingEvents_in:
		var obj = eobj.info.wref.get_ref()
		if obj:
			obj.callv(eobj.info.funcname, eobj.args)
		else:
			deregisterAllFromWeakref(events_in, eobj.info.wref)
	doingEvents_in.clear()