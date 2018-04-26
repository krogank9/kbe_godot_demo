var Dbg = KBEngine.Dbg
var Event = KBEngine.Event

var messageReader = null
var _networkInterface = null

func _init(networkInterface):
	_networkInterface = networkInterface
	messageReader = KBEngine.Messages.MessageReader.new()

func networkInterface():
	return _networkInterface

func process():
	if _networkInterface._socket == null or _networkInterface._socket.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		return
	var avail = _networkInterface._socket.get_available_bytes()
	if avail > 0:
		var result = _networkInterface._socket.get_partial_data(avail)
		if result[0] == OK:
			#KBEngine.Dbg.DEBUG_MSG(KBEngine.Helpers.strArr(result[1]))
			messageReader.process(result[1], 0, len(result[1]))