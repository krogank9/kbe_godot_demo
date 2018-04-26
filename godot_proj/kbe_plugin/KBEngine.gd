extends Node

var test = 5

#helpers
var Helpers = preload("res://kbe_plugin/Helpers.gd").new()
const TCP_PACKET_MAX = 1460

# preload all globals
var Dbg = preload("res://kbe_plugin/Dbg.gd").new()
var Includes = preload("res://kbe_plugin/Includes.gd")

var NetworkInterface = preload("res://kbe_plugin/NetworkInterface.gd")
var PacketSender = preload("res://kbe_plugin/PacketSender.gd")
var PacketReceiver = preload("res://kbe_plugin/PacketReceiver.gd")

var PersistentInfos = preload("res://kbe_plugin/PersistentInfos.gd")

var Method = preload("res://kbe_plugin/Method.gd")
var Event = preload("res://kbe_plugin/Event.gd").new()
var Property = preload("res://kbe_plugin/Property.gd")
var DataTypes = preload("res://kbe_plugin/DataTypes.gd").new()

var Entity = preload("res://kbe_plugin/Entity.gd")
var EntityCall = preload("res://kbe_plugin/EntityCall.gd")
var EntityDef = preload("res://kbe_plugin/EntityDef.gd").new()
var ScriptModule = preload("res://kbe_plugin/ScriptModule.gd")

var MemoryStreamPool = preload("res://kbe_plugin/MemoryStreamPool.gd").new()
var MemoryStream = MemoryStreamPool.MemoryStream
var BundlePool = preload("res://kbe_plugin/BundlePool.gd").new()
var Bundle = BundlePool.Bundle
var Messages = preload("res://kbe_plugin/Messages.gd").new()

var App = preload("res://kbe_plugin/App.gd")
var AppThread = preload("res://kbe_plugin/AppThread.gd")
var Args = preload("res://kbe_plugin/Args.gd").new()

var app = null

func _ready():
	Dbg.DEBUG_MSG("KBEngine::_init()")
	if Args.isMultiThreads:
		app = AppThread.new(Args)
	else:
		app = App.new(Args)

func _process(delta):
	#AppThread calls its own process()
	if not Args.isMultiThreads:
		app.process()
	
	Event.processOutEvents()