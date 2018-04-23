#Contains the properties and methods defined by an entity 
#Descriptive class of script module defined in an entitydef
# and the name and module ID of the entity script module

var name = ""
var usePropertyDescrAlias = false
var useMethodDescrAlias = false

var propertys = {}
var idpropertys = {}

var methods = {}
var base_methods = {}
var cell_methods = {}

var idmethods = {}
var idbase_methods = {}
var idcell_methods = {}

var script = null;

func _init(modulename):
	name = modulename
	
	if KBEngine.Helpers.kbe_scripts_dict.has(name):
		script = KBEngine.Helpers.kbe_scripts_dict[name]
		
	if script == null:
		KBEngine.Dbg.ERROR_MSG("can't load script: %s!" % name)