var _MemoryStreams = []

class MemoryStream extends StreamPeerBuffer:
	const BUFFER_MAX = 1460 * 4
	var rpos = 0
	var wpos = 0
			
	func _init():
		._init()
		.resize(BUFFER_MAX)

	static func createObject():
		return KBEngine.MemoryStreamPool.createObject()
	func reclaimObject():
		clear()
		KBEngine.MemoryStreamPool.reclaimObject(self)
		
	func getData():
		return data_array
		
	func putData(src, srcOffset, offset, length=-1):
		seek(offset)
		if length == -1:
			put_data(src.subarray(srcOffset, -1))
		else:
			put_data(src.subarray(srcOffset, srcOffset+length-1))
	
	func setData(data):
		data_array = data
	
	#####################################################
	
	func readInt8():
		seek(rpos)
		rpos += 1
		return get_8()
	
	func readInt16():
		seek(rpos)
		rpos += 2
		return get_16()
	
	func readInt32():
		seek(rpos)
		rpos += 4
		return get_32()
	
	func readInt64():
		seek(rpos)
		rpos += 8
		return get_64()
	
	func readUint8():
		seek(rpos)
		rpos += 1
		return get_u8()
	
	func readUint16():
		seek(rpos)
		rpos += 2
		return get_u16()
	
	func readUint32():
		seek(rpos)
		rpos += 4
		return get_u32()
	
	func readUint64():
		seek(rpos)
		rpos += 8
		return get_u64()
		
	func readFloat():
		seek(rpos)
		rpos += 4
		return get_float()
	
	func readDouble():
		seek(rpos)
		rpos += 8
		return get_double()
		
	func readString():
		seek(rpos)
		var bytes = PoolByteArray([])
		while length() > 0:
			var c = readUint8()
			if c == 0:
				break
			else:
				bytes.append(c)
		return bytes.get_string_from_ascii()
	
	func readBlob():
		seek(rpos)
		var size = readUint32()
		var destpos = rpos + size
		var data = []
		while rpos < destpos and length() > 0:
			data.append(readUint8())
		return data
	
	func readPackXZ():
		#bit shift magic copied from c#/javascript plugins
		var x = 0x40000000
		var z = 0x40000000
		
		var v1 = readUint8()
		var v2 = readUint8()
		var v3 = readUint8()
		
		var data = 0
		data |= (v1 << 16)
		data |= (v2 << 8)
		data |= v3
		
		x |= (data & 0x7ff000) << 3
		z |= (data & 0x0007ff) << 15
		
		x = KBEngine.Helpers.float32ToInt32(KBEngine.Helpers.int32ToFloat32(x) - 2.0)
		z = KBEngine.Helpers.float32ToInt32(KBEngine.Helpers.int32ToFloat32(z) - 2.0)
		
		x |= (data & 0x800000) << 8
		z |= (data & 0x000800) << 20
		return Vector2(
			KBEngine.Helpers.int32ToFloat32(x),
			KBEngine.Helpers.int32ToFloat32(z)
		)
	
	func readPackY():
		#bit shift magic copied from c#/javascript plugins
		var y = 0x40000000
		
		var data = readUint16()
		
		y |= (data & 0x7fff) << 12
		y = KBEngine.Helpers.float32ToInt32(KBEngine.Helpers.int32ToFloat32(y) - 2.0)
		y |= (data & 0x8000) << 16
		
		return KBEngine.Helpers.int32ToFloat32(y)
		
	#####################################################
	
	func writeInt8(v):
		seek(wpos)
		put_8(v)
		wpos += 1
	
	func writeInt16(v):
		seek(wpos)
		put_16(v)
		wpos += 2
	
	func writeInt32(v):
		seek(wpos)
		put_32(v)
		wpos += 4
	
	func writeInt64(v):
		seek(wpos)
		put_64(v)
		wpos += 8
	
	func writeUint8(v):
		seek(wpos)
		put_u8(v)
		wpos += 1
	
	func writeUint16(v):
		seek(wpos)
		put_u16(v)
		wpos += 2
	
	func writeUint32(v):
		seek(wpos)
		put_u32(v)
		wpos += 4
	
	func writeUint64(v):
		seek(wpos)
		put_u64(v)
		wpos += 8
		
	func writeFloat(v):
		seek(wpos)
		put_float(v)
		wpos += 4
	
	func writeDouble(v):
		seek(wpos)
		put_double(v)
		wpos += 8
	
	func writeBlob(v):
		seek(wpos)
		var size = len(v)
		if size+4 > space():
			KBEngine.Dbg.ERROR_MSG("MemoryStream::writeBlob: out of space")
			return
		
		writeUint32(size)
		if typeof(v) == TYPE_STRING:
			v = v.to_ascii() #no \0 terminator
		
		for _byte in v:
			writeUint8(_byte)
	
	func writeString(v):
		if len(v)+1 > space():
			KBEngine.Dbg.ERROR_MSG("MemoryStream::writeString: out of space")
			return
			
		var ascii = v.to_ascii() #no \0 terminator
		for c in ascii:
			writeUint8(c)
		writeUint8(0)
		
	#####################################################
	
	func append(bytes, offset, size):
		if space() < size:
			.resize(.get_size() + size*2)
		putData(bytes, offset, wpos, size)
		wpos += size
	
	func readSkip(v):
		rpos += v
	
	func space():
		return data_array.size() - wpos
	
	func length():
		return wpos - rpos
	
	func readEOF():
		return BUFFER_MAX - rpos <= 0
	
	func done():
		rpos = wpos

	func clear():
		rpos = 0
		wpos = 0
		if get_size() > BUFFER_MAX:
			.resize(BUFFER_MAX)
	
	func getBuffer():
		if rpos < wpos:
			return data_array.subarray(rpos, wpos-1)
		else:
			return PoolByteArray([])
		
	func toString():
		var s = ""
		var buf = getBuffer()
		for c in buf:
			if s.length() >= 400:
				s = ""
			s += c+" "
		return s

func createObject():
	if len(_MemoryStreams) > 0:
		return _MemoryStreams.pop_back()
	else:
		return MemoryStream.new();
		
func reclaimObject(obj):
	_MemoryStreams.push_back(obj)