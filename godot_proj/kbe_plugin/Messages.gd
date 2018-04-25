var loginappMessages = {}
var baseappMessages = {}
var clientMessages = {}

var messages = {}

func clear():
	loginappMessages = {}
	baseappMessages = {}
	clientMessages = {}
	messages = {}
	
	bindFixedMessage()

#Arrange some fixed agreements in advance
#This allows handshaking and other interaction before
# the protocol is imported from the server.
func bindFixedMessage():
	messages["Loginapp_importClientMessages"] = Message.new(5, "importClientMessages", 0, 0, [], null)
	messages["Loginapp_hello"] = Message.new(4, "hello", -1, -1, [], null)
	
	messages["Baseapp_importClientMessages"] = Message.new(207, "importClientMessages", 0, 0, [], null)
	messages["Baseapp_importClientEntityDef"] = Message.new(208, "importClientMessages", 0, 0, [], null)
	messages["Baseapp_hello"] = Message.new(200, "hello", -1, -1, [], null)
	
	messages["Client_onHelloCB"] = Message.new(521, "Client_onHelloCB", -1, -1, [], "Client_onHelloCB")
	clientMessages[messages["Client_onHelloCB"].id] = messages["Client_onHelloCB"]
	
	messages["Client_onScriptVersionNotMatch"] = Message.new(522, "Client_onScriptVersionNotMatch", -1, -1, [], "Client_onScriptVersionNotMatch")
	clientMessages[messages["Client_onScriptVersionNotMatch"].id] = messages["Client_onScriptVersionNotMatch"]
	
	messages["Client_onVersionNotMatch"] = Message.new(523, "Client_onVersionNotMatch", -1, -1, [], "Client_onVersionNotMatch")
	clientMessages[messages["Client_onVersionNotMatch"].id] = messages["Client_onVersionNotMatch"]
	
	messages["Client_onImportClientMessages"] = Message.new(518, "Client_onImportClientMessages", -1, -1, [], "Client_onImportClientMessages")
	clientMessages[messages["Client_onImportClientMessages"].id] = messages["Client_onImportClientMessages"]
		
class Message:
	var id = 0
	var name = ""
	var msglen  = -1
	var handler = null
	var argtypes = null
	var argsType = 0
		
	func _init(msgid, msgname, length, argstype, msgargtypes, msghandler):
		self.id = msgid
		self.name = msgname
		self.msglen = length
		self.handler = msghandler
		self.argsType = argstype
		
		# Bind the deserialization method to all parameters 
		#  of the message, this method can convert the binary 
		#  stream to the value required by the parameter
		# It will be used when the server sends message data
		argtypes = []
		for msgargtype in msgargtypes:
			if KBEngine.EntityDef.id2datatypes.has(msgargtype):
				argtypes.append(KBEngine.EntityDef.id2datatypes[msgargtype])
			else:
				argtypes.append(KBEngine.DataTypes.BASE.new())
				KBEngine.Dbg.ERROR_MSG("Message::_init(): argtype(" + str(msgargtype) + ") not found!");
	
	func createFromStream(msgstream):
		if len(argtypes) <= 0:
			return [msgstream]
			
		var result = []
		for a in argtypes:
			result.append(a.createFromStream(msgstream))
		return result

	func handleMessage(msgstream):
		if len(argtypes) <= 0:
			if argsType < 0:
				KBEngine.app.callv(handler, [msgstream])
			else:
				KBEngine.app.callv(handler, [])
		else:
			KBEngine.app.callv(handler, createFromStream(msgstream))


#MessageReader class
#Parse out all message packets from the packet stream 
# and pass it to the corresponding message handler
class MessageReader:
	enum READ_STATE {
		# Message id
		READ_STATE_MSGID = 0,
		# Message length from 0-65535
		READ_STATE_MSGLEN = 1,
		# Use an extended length when the above length cannot meet the requirements
		READ_STATE_MSGLEN_EX = 2,
		# Content of the message
		READ_STATE_BODY = 3
	}
	
	var msgid = 0
	var msglen = 0
	var expectSize = 2
	var state = READ_STATE.READ_STATE_MSGID
	var stream = KBEngine.MemoryStream.new()
	
	func process(datas,	offset, length):
		var totallen = offset
		
		while length > 0 and expectSize > 0:
			if state == READ_STATE.READ_STATE_MSGID:
				if length >= expectSize:
					stream.putData(datas, totallen, stream.wpos, expectSize)
					totallen += expectSize
					stream.wpos += expectSize
					length -= expectSize
					msgid = stream.readUint16()
					stream.clear()
					
					var msg = KBEngine.Messages.clientMessages[msgid]
					
					if msg.msglen == -1:
						state = READ_STATE.READ_STATE_MSGLEN
						expectSize = 2
					elif msg.msglen == 0:
						#If it is a 0-parameter message, then there is no 
						# follow-up content to read, process this message 
						# and jump directly to the next message.
						msg.handleMessage(stream)
						
						state = READ_STATE.READ_STATE_MSGID
						expectSize = 2
					else:
						expectSize = msg.msglen
						state = READ_STATE.READ_STATE_BODY
				else:
					stream.putData(datas, totallen, stream.wpos, length)
					stream.wpos += length
					expectSize -= length
					break
			
			elif state == READ_STATE.READ_STATE_MSGLEN:
				if length >= expectSize:
					stream.putData(datas, totallen, stream.wpos, expectSize)
					totallen += expectSize;
					stream.wpos += expectSize
					length -= expectSize;
					
					msglen = stream.readUint16();
					stream.clear();
					
					# Length extension
					if msglen >= 65535:
						state = READ_STATE.READ_STATE_MSGLEN_EX;
						expectSize = 4;
					else:
						state = READ_STATE.READ_STATE_BODY;
						expectSize = msglen;
				
				else:
					stream.putData(datas, totallen, stream.wpos, length)
					stream.wpos += length
					expectSize -= length
					break
			
			elif state == READ_STATE.READ_STATE_MSGLEN_EX:
				if length >= expectSize:
					stream.putData(datas, totallen, stream.wpos, expectSize)
					stream.wpos += expectSize
					totallen += expectSize
					length -= expectSize
					
					expectSize = stream.readUint32()
					stream.clear()
					
					state = READ_STATE.READ_STATE_BODY
				else:
					stream.putData(datas, totallen, stream.wpos, length)
					stream.wpos += length
					expectSize -= length
					break
			
			elif state == READ_STATE.READ_STATE_BODY:
				if length >= expectSize:
					stream.append(datas, totallen, expectSize)
					totallen += expectSize
					length -= expectSize

					var msg = KBEngine.Messages.clientMessages[msgid]

					msg.handleMessage(stream)
					
					stream.clear()
					
					state = READ_STATE.READ_STATE_MSGID
					expectSize = 2
				else:
					stream.append (datas, totallen, length)
					expectSize -= length
					break