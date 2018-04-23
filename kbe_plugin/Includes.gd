var Helpers
var Vector4
var Callback

var Dbg

var NetworkInterface
var PacketSender
var PacketReceiver

var PersistentInfos

var Method
var Event
var Property
var DataTypes

var Entity
var EntityCall
var EntityDef
var ScriptModule

var MemoryStreamPool
var MemoryStream
var BundlePool
var Bundle
var Messages

func _init():
	Helpers = KBEngine.Helpers
	Callback = Helpers.Callback
	Vector4 = Helpers.Vector4
	Dbg = KBEngine.Dbg
	
	NetworkInterface = KBEngine.NetworkInterface
	PacketSender = KBEngine.PacketSender
	PacketReceiver = KBEngine.PacketReceiver
	
	PersistentInfos = KBEngine.PersistentInfos
	
	Method = KBEngine.Method
	Event = KBEngine.Event
	Property = KBEngine.Property
	DataTypes = KBEngine.DataTypes
	
	Entity = KBEngine.Entity
	EntityCall = KBEngine.EntityCall
	EntityDef = KBEngine.EntityDef
	ScriptModule = KBEngine.ScriptModule
	
	MemoryStreamPool = KBEngine.MemoryStreamPool
	MemoryStream = MemoryStreamPool.MemoryStream
	BundlePool = KBEngine.BundlePool
	Bundle = BundlePool.Bundle
	Messages = KBEngine.Messages