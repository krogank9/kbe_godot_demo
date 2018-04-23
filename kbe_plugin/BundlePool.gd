class Bundle:
	var stream = KBEngine.MemoryStream.new()
	var streamList = []
	var numMessage = 0
	var messageLength = 0
	var msgtype = null
	var _curMsgStreamIndex = 0
	
	func clear():
		stream = KBEngine.MemoryStream.createObject()
		streamList = []
		numMessage = 0
		messageLength = 0
		msgtype = null
		_curMsgStreamIndex = 0
	
	static func createObject():
		return KBEngine.BundlePool.createObject()
	func reclaimObject():
		clear()
		KBEngine.BundlePool.reclaimObject(self)
		
	#####################################################
	
	func newMessage(mt):
		fini(false)
		
		msgtype = mt
		numMessage += 1
		
		writeUint16(msgtype.id)
		
		if msgtype.msglen == -1:
			writeUint16(0)
			messageLength = 0
		
		_curMsgStreamIndex = 0
	
	func writeMsgLength():
		if msgtype.msglen != -1:
			return
		
		var _stream = stream
		if _curMsgStreamIndex > 0:
			_stream = streamList[len(streamList) - _curMsgStreamIndex]
		#_stream.data_array[2] = messageLength & 0xff
		#_stream.data_array[3] = (messageLength >> 8) & 0xff
		_stream.seek(2)
		_stream.put_u16(messageLength)
	
	func fini(issend):
		if numMessage > 0:
			writeMsgLength()
			streamList.append(stream)
			stream = KBEngine.MemoryStream.createObject()
		
		if issend:
			numMessage = 0
			msgtype = null
		
		_curMsgStreamIndex = 0
	
	func send(networkInterface):
		fini(true)
		
		if networkInterface.valid():
			for _stream in streamList:
				networkInterface.send(_stream)
		else:
			KBEngine.Dbg.ERROR_MSG("Bundle::send: invalid networkInterface!")
		
		#Put unused MemoryStreams back into buffer pool to reduce garbage collection
		for _stream in streamList:
			_stream.reclaimObject()
		
		streamList.clear()
		stream.clear()
		
		#When the sending is completed, it is considered that the bundle is no longer in use.
		#So we will put it back into the pool of objects to reduce the consumption of garbage collection.
		#If you need to continue to use it, you should re-Bundle.createObject(),
		#If you don't use createObject() directly outside, you may get inexplicable problems.
		#Only use this note to alert the user.
		KBEngine.BundlePool.reclaimObject(self)
		
	func checkStream(v):
		if v > stream.space():
			streamList.append(stream)
			stream = KBEngine.MemoryStream.createObject()
			_curMsgStreamIndex += 1
		messageLength += v
	
	#####################################################
	
	func writeInt8(v):
		checkStream(1)
		stream.writeInt8(v)
	
	func writeInt16(v):
		checkStream(2)
		stream.writeInt16(v)
	
	func writeInt32(v):
		checkStream(4)
		stream.writeInt32(v)
		
	func writeInt64(v):
		checkStream(8)
		stream.writeInt64(v)
	
	func writeUint8(v):
		checkStream(1)
		stream.writeUint8(v)
	
	func writeUint16(v):
		checkStream(2)
		stream.writeUint16(v)
	
	func writeUint32(v):
		checkStream(4)
		stream.writeUint32(v)
		
	func writeUint64(v):
		checkStream(8)
		stream.writeUint64(v)
	
	func writeFloat(v):
		checkStream(4)
		stream.writeFloat(v)
	
	func writeDouble(v):
		checkStream(8)
		stream.writeDouble(v)
	
	func writeString(v):
		checkStream(len(v) + 1)
		stream.writeString(v)
	
	func writeBlob(v):
		checkStream(4 + len(v))
		stream.writeBlob(v)

var _Bundles = []

func createObject():
	if len(_Bundles) > 0:
		return _Bundles.pop_back()
	else:
		return Bundle.new()

func reclaimObject(obj):
	_Bundles.push_back(obj)
