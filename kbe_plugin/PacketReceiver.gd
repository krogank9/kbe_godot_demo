var Dbg = KBEngine.Dbg
var Event = KBEngine.Event

var messageReader = null
var _networkInterface = null

var RECV_BUFFER_MAX = 1000

func _init(networkInterface):
	_networkInterface = networkInterface
	RECV_BUFFER_MAX = KBEngine.app.getInitArgs().RECV_BUFFER_MAX
	messageReader = KBEngine.Messages.MessageReader.new()

func networkInterface():
	return _networkInterface

func process():
	if _networkInterface._socket.get_available_bytes() > 0:
		var result = _networkInterface._socket.get_partial_data(RECV_BUFFER_MAX)
		if result[0] == OK:
			#KBEngine.Dbg.DEBUG_MSG(KBEngine.Helpers.strArr(result[1]))
			messageReader.process(result[1], 0, len(result[1]))