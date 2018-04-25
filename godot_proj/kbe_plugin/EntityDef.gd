var datatype2id = {}
var datatypes = {}
var id2datatypes = {}

var entityclass = {}

var moduledefs = {}
var idmoduledefs = {}

func clear():
	datatype2id.clear()
	datatypes.clear()
	id2datatypes.clear()
	entityclass.clear()
	moduledefs.clear()
	idmoduledefs.clear()
	
	initDataType()
	bindMessageDataType()

func initDataType():
	datatypes.clear()
	datatypes["INT8"] = KBEngine.DataTypes.INT8.new()
	datatypes["INT16"] = KBEngine.DataTypes.INT16.new()
	datatypes["INT32"] = KBEngine.DataTypes.INT32.new()
	datatypes["INT64"] = KBEngine.DataTypes.INT64.new()
	
	datatypes["UINT8"] = KBEngine.DataTypes.UINT8.new()
	datatypes["UINT16"] = KBEngine.DataTypes.UINT16.new()
	datatypes["UINT32"] = KBEngine.DataTypes.UINT32.new()
	datatypes["UINT64"] = KBEngine.DataTypes.UINT64.new()
	
	datatypes["FLOAT"] = KBEngine.DataTypes.FLOAT.new()
	datatypes["DOUBLE"] = KBEngine.DataTypes.DOUBLE.new()
	
	datatypes["STRING"] = KBEngine.DataTypes.STRING.new()
	datatypes["VECTOR2"] = KBEngine.DataTypes.VECTOR2.new()
	datatypes["VECTOR3"] = KBEngine.DataTypes.VECTOR3.new()
	datatypes["VECTOR4"] = KBEngine.DataTypes.VECTOR4.new()
	datatypes["PYTHON"] = KBEngine.DataTypes.PYTHON.new()
	datatypes["UNICODE"] = KBEngine.DataTypes.UNICODE.new()
	datatypes["ENTITYCALL"] = KBEngine.DataTypes.ENTITYCALL.new()
	datatypes["BLOB"] = KBEngine.DataTypes.BLOB.new()

func bindMessageDataType():
	if len(datatype2id) > 0:
		return
	
	datatype2id["STRING"] = 1
	datatype2id["STD::STRING"] = 1
	
	id2datatypes[1] = datatypes["STRING"]
	
	datatype2id["UINT8"] = 2
	datatype2id["BOOL"] = 2
	datatype2id["DATATYPE"] = 2
	datatype2id["CHAR"] = 2
	datatype2id["DETAIL_TYPE"] = 2
	datatype2id["ENTITYCALL_TYPE"] = 2
	
	id2datatypes[2] = datatypes["UINT8"]
	
	datatype2id["UINT16"] = 3
	datatype2id["UNSIGNED SHORT"] = 3
	datatype2id["SERVER_ERROR_CODE"] = 3
	datatype2id["ENTITY_TYPE"] = 3
	datatype2id["ENTITY_PROPERTY_UID"] = 3
	datatype2id["ENTITY_METHOD_UID"] = 3
	datatype2id["ENTITY_SCRIPT_UID"] = 3
	datatype2id["DATATYPE_UID"] = 3
	
	id2datatypes[3] = datatypes["UINT16"]
	
	datatype2id["UINT32"] = 4
	datatype2id["UINT"] = 4
	datatype2id["UNSIGNED INT"] = 4
	datatype2id["ARRAYSIZE"] = 4
	datatype2id["SPACE_ID"] = 4
	datatype2id["GAME_TIME"] = 4
	datatype2id["TIMER_ID"] = 4
	
	id2datatypes[4] = datatypes["UINT32"]
	
	datatype2id["UINT64"] = 5
	datatype2id["DBID"] = 5
	datatype2id["COMPONENT_ID"] = 5
	
	id2datatypes[5] = datatypes["UINT64"]
	
	datatype2id["INT8"] = 6
	datatype2id["COMPONENT_ORDER"] = 6
	
	id2datatypes[6] = datatypes["INT8"]
	
	datatype2id["INT16"] = 7
	datatype2id["SHORT"] = 7
	
	id2datatypes[7] = datatypes["INT16"]
	
	datatype2id["INT32"] = 8
	datatype2id["INT"] = 8
	datatype2id["ENTITY_ID"] = 8
	datatype2id["CALLBACK_ID"] = 8
	datatype2id["COMPONENT_TYPE"] = 8
	
	id2datatypes[8] = datatypes["INT32"]
	
	datatype2id["INT64"] = 9
	
	id2datatypes[9] = datatypes["INT64"]
	
	datatype2id["PYTHON"] = 10
	datatype2id["PY_DICT"] = 10
	datatype2id["PY_TUPLE"] = 10
	datatype2id["PY_LIST"] = 10
	datatype2id["ENTITYCALL"] = 10
	
	id2datatypes[10] = datatypes["PYTHON"]
	
	datatype2id["BLOB"] = 11
	
	id2datatypes[11] = datatypes["BLOB"]
	
	datatype2id["UNICODE"] = 12
	
	id2datatypes[12] = datatypes["UNICODE"]
	
	datatype2id["FLOAT"] = 13
	
	id2datatypes[13] = datatypes["FLOAT"]
	
	datatype2id["DOUBLE"] = 14
	
	id2datatypes[14] = datatypes["DOUBLE"]
	
	datatype2id["VECTOR2"] = 15
	
	id2datatypes[15] = datatypes["VECTOR2"]
	
	datatype2id["VECTOR3"] = 16
	
	id2datatypes[16] = datatypes["VECTOR3"]
	
	datatype2id["VECTOR4"] = 17
	
	id2datatypes[17] = datatypes["VECTOR4"]
	
	datatype2id["FIXED_DICT"] = 18
	# No binding is needed here, FIXED_DICT needs to dynamically 
	#  get ids based on different types of instantiation
	#id2datatypes[18] = datatypes["FIXED_DICT"]
	
	datatype2id["ARRAY"] = 19
	# No binding is needed here. ARRAY needs to dynamically 
	#  obtain ids based on different types of instantiation.
	#id2datatypes[19] = datatypes["ARRAY"]