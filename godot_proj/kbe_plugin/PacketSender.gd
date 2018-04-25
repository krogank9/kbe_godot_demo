var Dbg = KBEngine.Dbg
var Event = KBEngine.Event

var _networkInterface = null
var _socket = null

var queued_data = []

var send_thread = Thread.new()
var _sending = false
var queue_mutex = Mutex.new()
var sending_mutex = Mutex.new()

# helper funcs
func len_queued_data():
	queue_mutex.lock()
	var tmp = len(queued_data)
	queue_mutex.unlock()
	return tmp

func push_queued_data(v):
	queue_mutex.lock()
	queued_data.push_front(v)
	queue_mutex.unlock()
	
func pop_queued_data():
	queue_mutex.lock()
	var tmp = queued_data.pop_back()
	queue_mutex.unlock()
	return tmp

func peek_queued_data():
	queue_mutex.lock()
	var tmp = queued_data.back()
	queue_mutex.unlock()
	return tmp

##### class functions

func _init(networkInterface):
	_networkInterface = networkInterface
	_socket = _networkInterface._socket
	send_thread.start(self, "_asyncSendQueue", null)

func networkInterface():
	return _networkInterface

func send(stream):
	if stream.length() <= 0:
		return true
	
	if len_queued_data() == 0:
		# try to send all data at once
		var sent = _socket.put_partial_data(stream.getBuffer())[1]
		#print("sent: "+KBEngine.Helpers.strArr(stream.getBuffer()))
		stream.rpos += sent

	if stream.length() > 0:
		push_queued_data(stream.getBuffer())
	
	return true

func _asyncSendQueue(thread_userdata):
	if _networkInterface == null or not _networkInterface.valid():
		Dbg.WARNING_MSG("PacketSender::_asyncSendQueue(): network interface invalid!")
		return
	
	while _socket != null and _socket.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		if len_queued_data() > 0:
			var result = _socket.put_data(peek_queued_data().getBuffer())
			if result != OK:
				Dbg.ERROR_MSG("PacketSender::_asyncSendQueue(): error(%s) sending buffer. disconnected!" % result)
				Event.fireIn("_closeNetwork", [_networkInterface])
				break
			pop_queued_data()
		else:
			OS.delay_msec(5)