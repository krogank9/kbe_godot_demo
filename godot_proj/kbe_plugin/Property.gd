enum EntityDataFlags {
	ED_FLAG_UNKNOWN = 0x00000000,
	ED_FLAG_CELL_PUBLIC = 0x00000001,
	ED_FLAG_CELL_PRIVATE = 0x00000002,
	ED_FLAG_ALL_CLIENTS = 0x00000004,
	ED_FLAG_CELL_PUBLIC_AND_OWN = 0x00000008,
	ED_FLAG_OWN_CLIENT = 0x00000010,
	ED_FLAG_BASE_AND_CLIENT = 0x00000020,
	ED_FLAG_BASE = 0x00000040,
	ED_FLAG_OTHER_CLIENTS = 0x00000080
};

var name = ""
var utype = null
var properUtype = 0
var properFlags = 0
var aliasID = -1

var defaultValStr = ""
var setmethod = null

var val = null

func isBase():
	return (properFlags == EntityDataFlags.ED_FLAG_BASE_AND_CLIENT
			|| properFlags == EntityDataFlags.ED_FLAG_BASE)

func isOwnerOnly():
	return (properFlags == EntityDataFlags.ED_FLAG_CELL_PUBLIC_AND_OWN
			|| properFlags == EntityDataFlags.ED_FLAG_OWN_CLIENT)

func isOtherOnly():
	return (properFlags == EntityDataFlags.ED_FLAG_OTHER_CLIENTS
			|| properFlags == EntityDataFlags.ED_FLAG_OTHER_CLIENTS)
