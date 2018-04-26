var FLT_MAX = 3.402823e+38
var FLT_MIN = -FLT_MAX

#The basic data types supported by entitydef
#The classes in this file abstract all support types and provide 
# serialization/deserialization of these types into/from binary data 
# (mainly used for packet and depacketization of network communication).

"""
var typeNamesDict = {
	BASE: "BASE",
	INT8: "INT8",
	INT16: "INT16",
	INT32: "INT32",
	INT64: "INT64",

	UINT8: "UINT8",
	UINT16: "UINT16",
	UINT32: "UINT32",
	UINT64: "UINT64",

	FLOAT: "FLOAT",
	DOUBLE: "DOUBLE",
	STRING: "STRING",
	
	VECTOR2: "VECTOR2",
	VECTOR3: "VECTOR3",
	VECTOR4: "VECTOR4",
	
	PYTHON: "PYTHON",
	UNICODE: "UNICODE",
	ENTITYCALL: "ENTITYCALL",
	BLOB: "BLOB",

	ARRAY: "ARRAY",
	FIXED_DICT: "FIXED_DICT",
}

func getBaseTypeName(type):
	if typeNamesDict.has(type):
		return typeNamesDict[type]
"""

class BASE:
	func TYPENAME():
		return "BASE"
		
	static func isNumeric(v):
		var type = typeof(v)
		return (type == TYPE_INT) or (type == TYPE_REAL) or (type == TYPE_BOOL)
	
	static func bind():
		pass
	func createFromStream(stream):
		return null
	func addToStream(stream, v):
		pass
	func parseDefaultValStr(v):
		return null
	func isSameType(v):
		return v == null

class INT8 extends BASE:
	func TYPENAME():
		return "INT8"

	func createFromStream(stream):
		return stream.readInt8()
	func addToStream(stream, v):
		stream.writeInt8(int(v))
	func parseDefaultValStr(v):
		return int(v)
	func isSameType(v):
		if not isNumeric(v):
			return false
		return v >= -128 and v <= 127

class INT16 extends BASE:
	func TYPENAME():
		return "INT16"
		
	func createFromStream(stream):
		return stream.readInt16()
	func addToStream(stream, v):
		stream.writeInt16(int(v))
	func parseDefaultValStr(v):
		return int(v)
	func isSameType(v):
		if not isNumeric(v):
			return false
		return v >= -32768 and v <= 32767

class INT32 extends BASE:
	func TYPENAME():
		return "INT32"
		
	func createFromStream(stream):
		return stream.readInt32()
	func addToStream(stream, v):
		stream.writeInt32(int(v))
	func parseDefaultValStr(v):
		return int(v)
	func isSameType(v):
		if not isNumeric(v):
			return false
		return v >= -2147483648 and v <= 2147483647

class INT64 extends BASE:
	func TYPENAME():
		return "INT64"
		
	func createFromStream(stream):
		return stream.readInt64()
	func addToStream(stream, v):
		stream.writeInt64(int(v))
	func parseDefaultValStr(v):
		return int(v)
	func isSameType(v):
		if not isNumeric(v):
			return false
		return v >= -9223372036854775808 and v <= 9223372036854775807
		
class UINT8 extends BASE:
	func TYPENAME():
		return "UINT8"
		
	func createFromStream(stream):
		return stream.readUint8()
	func addToStream(stream, v):
		stream.writeUint8(int(v))
	func parseDefaultValStr(v):
		return int(v)
	func isSameType(v):
		if not isNumeric(v):
			return false
		return v >= 0 and v <= 255

class UINT16 extends BASE:
	func TYPENAME():
		return "UINT16"
		
	func createFromStream(stream):
		return stream.readUint16()
	func addToStream(stream, v):
		stream.writeUint16(int(v))
	func parseDefaultValStr(v):
		return int(v)
	func isSameType(v):
		if not isNumeric(v):
			return false
		return v >= 0 and v <= 65535

class UINT32 extends BASE:
	func TYPENAME():
		return "UINT32"
		
	func createFromStream(stream):
		return stream.readUint32()
	func addToStream(stream, v):
		stream.writeUint32(int(v))
	func parseDefaultValStr(v):
		return int(v)
	func isSameType(v):
		if not isNumeric(v):
			return false
		return v >= 0 and v <= 4294967295

class UINT64 extends BASE:
	func TYPENAME():
		return "UINT64"
		
	func createFromStream(stream):
		return stream.readUint64()
	func addToStream(stream, v):
		stream.writeUint64(int(v))
	func parseDefaultValStr(v):
		return int(v)
	func isSameType(v):
		if not isNumeric(v):
			return false
		return v >= 0 and v <= 9223372036854775807#gdscript has no unsigned. max is same as signed64(v <= 18446744073709551615)

class FLOAT extends BASE:
	func TYPENAME():
		return "FLOAT"
		
	func createFromStream(stream):
		return stream.readFloat()
	func addToStream(stream, v):
		stream.writeFloat(float(v))
	func parseDefaultValStr(v):
		return float(v)
	func isSameType(v):
		return typeof(v) == TYPE_REAL

class DOUBLE extends BASE:
	func TYPENAME():
		return "DOUBLE"
		
	func createFromStream(stream):
		return stream.readDouble()
	func addToStream(stream, v):
		stream.writeDouble(float(v))
	func parseDefaultValStr(v):
		return float(v)
	func isSameType(v):
		return typeof(v) == TYPE_REAL

class STRING extends BASE:
	func TYPENAME():
		return "STRING"
		
	func createFromStream(stream):
		return stream.readString()
	func addToStream(stream, v):
		stream.writeString(str(v))
	func parseDefaultValStr(v):
		return v
	func isSameType(v):
		if typeof(v) != TYPE_STRING:
			return false
		return v.to_ascii().get_string_from_ascii() == v

class VECTOR2 extends BASE:
	func TYPENAME():
		return "VECTOR2"
		
	func createFromStream(stream):
		return Vector2(stream.readFloat(), stream.readFloat())
	func addToStream(stream, v):
		stream.writeFloat(v.x)
		stream.writeFloat(v.y)
	func parseDefaultValStr(v):
		return Vector2(0,0)
	func isSameType(v):
		return typeof(v) == TYPE_VECTOR2

class VECTOR3 extends BASE:
	func TYPENAME():
		return "VECTOR3"
		
	func createFromStream(stream):
		return Vector3(stream.readFloat(), stream.readFloat(), stream.readFloat())
	func addToStream(stream, v):
		stream.writeFloat(v.x)
		stream.writeFloat(v.y)
		stream.writeFloat(v.z)
	func parseDefaultValStr(v):
		return Vector3(0,0,0)
	func isSameType(v):
		return typeof(v) == TYPE_VECTOR3

class VECTOR4 extends BASE:
	func TYPENAME():
		return "VECTOR4"
		
	func createFromStream(stream):
		return KBEngine.Helpers.Vector4.new(stream.readFloat(), stream.readFloat(), stream.readFloat(), stream.readFloat())
	func addToStream(stream, v):
		stream.writeFloat(v.x)
		stream.writeFloat(v.y)
		stream.writeFloat(v.z)
		stream.writeFloat(v.w)
	func parseDefaultValStr(v):
		return KBEngine.Helpers.Vector4.new(0,0,0,0)
	func isSameType(v):
		return typeof(v) == TYPE_RID and v is KBEngine.Helpers.Vector4
		
class PYTHON extends BASE:
	func TYPENAME():
		return "PYTHON"
		
	func createFromStream(stream):
		return stream.readBlob()
	func addToStream(stream, v):
		stream.writeBlob(v)
	func parseDefaultValStr(v):
		return []
	func isSameType(v):
		return typeof(v) == TYPE_RAW_ARRAY
		
class UNICODE extends BASE:
	func TYPENAME():
		return "UNICODE"
		
	func createFromStream(stream):
		return PoolByteArray(stream.readBlob()).get_string_from_utf8()
	func addToStream(stream, v):
		stream.writeBlob(v.to_utf8())
	func parseDefaultValStr(v):
		return v
	func isSameType(v):
		return typeof(v) == TYPE_STRING
		
class ENTITYCALL extends BASE:
	func TYPENAME():
		return "ENTITYCALL"
		
	func createFromStream(stream):
		return stream.readBlob()
	func addToStream(stream, v):
		stream.writeBlob(v)
	func parseDefaultValStr(v):
		return []
	func isSameType(v):
		return typeof(v) == TYPE_RAW_ARRAY

class BLOB extends BASE:
	func TYPENAME():
		return "BLOB"
		
	func createFromStream(stream):
		return stream.readBlob()
	func addToStream(stream, v):
		stream.writeBlob(v)
	func parseDefaultValStr(v):
		return []
	func isSameType(v):
		return typeof(v) == TYPE_RAW_ARRAY
		
class ARRAY extends BASE:
	func TYPENAME():
		return "ARRAY"
		
	var vtype = null
	
	func bind():
		if typeof(vtype) == TYPE_RID and vtype is BASE:
			vtype.bind()
		elif KBEngine.EntityDef.id2datatypes.has(vtype):
			vtype = KBEngine.EntityDef.id2datatypes[vtype]

	func createFromStream(stream):
		var size = stream.readUint32()
		var datas = []
		while len(datas) < size:
			datas.append(vtype.createFromStream(stream))
		return datas
	func addToStream(stream, v):
		stream.writeUint32(len(v))
		for obj in v:
			vtype.addToStream(stream, obj)
	func parseDefaultValStr(v):
		return []
	func isSameType(v):
		if typeof(vtype) != TYPE_RID or not(vtype is BASE):
			KBEngine.Dbg.ERROR_MSG("KBEngine.DataTypes.ARRAY::isSameType: not yet bound! baseType(gdscript typeof)=%s" % [str(typeof(vtype))])
			return false
		
		if typeof(v) != TYPE_ARRAY:
			return false
		
		for obj in v:
			if not vtype.isSameType(obj):
				return false
		
		return true

class FIXED_DICT extends BASE:
	func TYPENAME():
		return "FIXED_DICT"
		
	var implementedBy = ""
	var dicttype = {}
	
	func bind():
		for itemkey in dicttype.keys():
			var type = dicttype[itemkey]
			if typeof(type) == TYPE_RID and type is BASE:
				type.bind()
			elif KBEngine.EntityDef.id2datatypes.has(type):
				dicttype[itemkey] = KBEngine.EntityDef.id2datatypes[type]

	func createFromStream(stream):
		var datas = {}
		for itemkey in dicttype.keys():
			datas[itemkey] = dicttype[itemkey].createFromStream(stream)
		return datas
	func addToStream(stream, v):
		for itemkey in dicttype.keys():
			dicttype[itemkey].addToStream(stream, v[itemkey])
	func parseDefaultValStr(v):
		var datas = {}
		for itemkey in dicttype.keys():
			datas[itemkey] = dicttype[itemkey].parseDefaultValStr("")
		return datas
	func isSameType(v):
		if typeof(v) != TYPE_DICTIONARY:
			return false
		
		for itemkey in dicttype.keys():
			if not(dicttype[itemkey].isSameType(v[itemkey])):
				return false
		return true