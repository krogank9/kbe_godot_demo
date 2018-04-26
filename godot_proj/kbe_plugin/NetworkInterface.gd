var Dbg = KBEngine.Dbg
var Event = KBEngine.Event

var _socket = null
var _packetReceiver = null
var _packetSender = null

var connected = false

var connect_thread = null

class ConnectState:
	var connectIP = ""
	var connectPort = 0
	var connectCB = null
	var userData = null
	var socket = null
	var networkInterface = null
	var error = ""

func _init():
	reset()

func sock():
	return _socket
	
func reset():
	if valid():
		KBEngine.Dbg.DEBUG_MSG("NetworkInterface::reset(), closed socket from "+_socket.get_connected_host())
		_socket.disconnect_from_host()
	
	_socket = null
	_packetReceiver = null
	_packetSender = null
	connected = false

func close():
	if _socket != null:
		_socket.disconnect_from_host()
		_socket = null
		print("NetworkInterface::close() sending onDisconnected")
		Event.fireAll("onDisconnected", [])
	else:
		print("NetworkInterface::close() socket already nulled. not firing onDisconnected")
	connected = false

func packetReceiver():
	return _packetReceiver

func valid():
	return _socket != null and _socket.get_status() == StreamPeerTCP.STATUS_CONNECTED

func _onConnectionState(state):
	Event.deregisterIn(self)
	
	var success = state.error == "" and valid()
	if success:
		KBEngine.Dbg.DEBUG_MSG("NetworkInterface::_onConnectionState, connection to "
									+_socket.get_connected_host()+" was successful!")
		_socket.set_no_delay(true)
		_packetReceiver = KBEngine.PacketReceiver.new(self)
		#_packetReceiver.startRecv()
		connected = true
	else:
		reset()
		KBEngine.Dbg.DEBUG_MSG("NetworkInterface::_onConnectionState, Connection error! ip: "
								+state.connectIP+":"+str(state.connectPort)+", err: "+state.error)
	
	Event.fireAll("onConnectionState", [success])
	
	if state.connectCB != null:
		state.connectCB.call([state.connectIP, state.connectPort, success, state.userData])

func _asyncConnect(state):
	KBEngine.Dbg.DEBUG_MSG("NetWorkInterface::_asyncConnect(), will connect to "+state.connectIP+":"+str(state.connectPort)+" ...")
	
	var start = OS.get_ticks_msec()
	var result = state.socket.connect_to_host(state.connectIP, state.connectPort)
	while (state.socket.get_status() == StreamPeerTCP.STATUS_CONNECTING
			and OS.get_ticks_msec() - start < 5000):
		OS.delay_msec(10)
	if state.socket.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		KBEngine.Dbg.DEBUG_MSG("NetWorkInterface::_asyncConnect(), failed to connect to "+state.connectIP+":"+str(state.connectPort))
		state.error = "unable to connect"
	
	#_asyncConnectCB(state)
	Dbg.DEBUG_MSG("NetWorkInterface::_asyncConnectCB(), connection to '%s:%s' finished. error = '%s'"
					% [state.connectIP, str(state.connectPort), state.error])
	#state.connectCB.call([state.connectIP, state.connectPort, state.error == "", state.userData])
	Event.fireIn("_onConnectionState", [state]);

func connectTo(ip, port, callback, userData):
	if valid():
		KBEngine.WARNING_MSG("NetworkInterface::connectTo(): Already connected!")
		return
	
	if not ip.is_valid_ip_address():
		ip = "127.0.0.1"
	
	_socket = StreamPeerTCP.new()
	#_socket.SetSocketOption(System.Net.Sockets.SocketOptionLevel.Socket, SocketOptionName.ReceiveBuffer, KBEngineApp.app.getInitArgs().getRecvBufferSize() * 2);
	#_socket.SetSocketOption(System.Net.Sockets.SocketOptionLevel.Socket, SocketOptionName.SendBuffer, KBEngineApp.app.getInitArgs().getSendBufferSize()
	var state = ConnectState.new()
	state.connectIP = ip
	state.connectPort = port
	state.connectCB = callback
	state.userData = userData
	state.socket = _socket
	state.networkInterface = self
	
	Dbg.DEBUG_MSG("connecting to " + ip + ":" + str(port) + " ...")
	connected = false
	
	#Register an event callback that fires on the current thread
	Event.registerIn("_onConnectionState", self, "_onConnectionState")
	
	connect_thread = Thread.new()
	connect_thread.start(self, "_asyncConnect", state)

func send(stream):
	if not valid():
		Dbg.ERROR_MSG("Invalid socket")
		return
	
	if _packetSender == null:
		_packetSender = KBEngine.PacketSender.new(self)
	
	return _packetSender.send(stream)

func process():
	if not valid():
		return
	
	if _packetReceiver != null:
		_packetReceiver.process()