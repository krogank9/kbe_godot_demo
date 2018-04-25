########
# misc #
########

func makeByteArray(length):
	var arr = []
	while len(arr) < length:
		arr.append(0)
	return arr

func makeArray(type, length):
	var arr = []
	while len(arr) < length:
		arr.append(type.new())
	return arr

func arrayCopyShort(src, dest, length):
	var index = 0
	while index < length:
		dest[index] = src[index]
		index += 1

func arrayCopy(srcArr, srcIndex, destArr, destIndex, length):
	while length > 0:
		destArr[destIndex] = srcArr[srcIndex]
		srcIndex += 1
		destIndex += 1
		length -= 1

func strArr(arr):
	var s = "["
	for i in range(len(arr)):
		if i > 0:
			s += ", "
		s += str(arr[i])
		if i > 50:
			return s + (", ...(%s more)]" % (len(arr)-i))
	return s + "]"

func tryGetValue(dict, key):
	if dict.has(key):
		return dict[key]
	else:
		return null
		
class Callback:
	var obj
	var method
	func _init(obj, method):
		self.obj = obj
		self.method = method
	
	func call(args):
		obj.callv(method, args)
		
var mutexes = {}
func lock_mutex(name):
	if not mutexes.has(name):
		mutexes[name] = Mutex.new()
	mutexes[name].lock()
func unlock_mutex(name):
	if mutexes.has(name):
		mutexes[name].unlock()

########
# math #
########

class Vector4:
	var x = 0
	var y = 0
	var z = 0
	var w = 0
	
	func _init(x,y,z,w):
		self.x = x
		self.y = y
		self.z = z
		self.w = w

func int82angle(angle, half):
	var halfv = 128
	if half:
		halfv = 254
	
	halfv = angle * (PI / halfv)
	return halfv

func almostEqual(f1, f2, epsilon):
	return abs(f1 - f2) < epsilon
	
func normalizeRads(rads):
	while rads > PI:
		rads -= PI*2
	while rads < -PI:
		rads += PI*2
	return rads

#############
# bit magic #
#############

var sbuf = StreamPeerBuffer.new()

func int32ToFloat32(v):
	sbuf.clear()
	sbuf.put_32(v)
	sbuf.seek(0)
	return sbuf.get_float()

func float32ToInt32(v):
	sbuf.clear()
	sbuf.put_float(v)
	sbuf.seek(0)
	return sbuf.get_32()
	
#############
# kbe types #
#############

func list_files_in_directory_recur(path):
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()
	
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			if dir.dir_exists(file):
				var newdir = dir.get_current_dir()+"/"+file
				files += list_files_in_directory_recur(newdir)
			else:
				if not file.ends_with(".remap"):
					files.append(path+"/"+file)
		
	dir.list_dir_end()
		
	return files

func get_file_names(path_arr):
	var names = []
	for path in path_arr:
		var after_slash = path.find_last("/") + 1
		var dot = path.find_last(".")
		var name = path.substr(after_slash, dot - after_slash)
		names.append(name)
	return names

func load_files(path_arr):
	var loads = []
	for path in path_arr:
		loads.append( load(path) )
	return loads

func make_dict_from_arrs(keys, vals):
	var dict = {}
	var i = 0
	while i < len(keys):
		dict[keys[i]] = vals[i]
		i += 1
	return dict

func orderClassesByInheritance(classes, also_sort):
	var instances = []
	for c in classes:
		instances.append(c.new())
	
	var length = len(classes)
	var i = 0
	while i < length:
		var j = i + 1
		while j < length:
			if ((instances[j] is classes[i])
			and not (instances[i] is classes[j])):
				var tmp = instances[i]
				instances[i] = instances[j]
				instances[j] = tmp
				tmp = classes[i]
				classes[i] = classes[j]
				classes[j] = tmp
				tmp = also_sort[i]
				also_sort[i] = also_sort[j]
				also_sort[j] = tmp
			j += 1
		i += 1
	return classes

func reverse_dict(dict):
	var rev_dict = {}
	for key in dict.keys():
		rev_dict[dict[key]] = key
	return rev_dict

func instance_classes(classes):
	var instances = []
	for c in classes:
		instances.append(c.new())
	return instances

var kbe_scripts_paths = list_files_in_directory_recur("res://kbe_scripts")
var kbe_scripts_names = get_file_names(kbe_scripts_paths)
var kbe_scripts_classes = orderClassesByInheritance(load_files(kbe_scripts_paths), kbe_scripts_names)
var kbe_scripts_instances = instance_classes(kbe_scripts_classes)
var kbe_instances_dict = make_dict_from_arrs(kbe_scripts_classes, kbe_scripts_instances)
var kbe_scripts_dict = make_dict_from_arrs(kbe_scripts_names, kbe_scripts_classes)
var kbe_scripts_dict_rev = reverse_dict(kbe_scripts_dict)

func methodExistsInClass(kbe_class, methodname):
	if not kbe_instances_dict.has(kbe_class):
		return false
	var instance = kbe_instances_dict[kbe_class]
	return instance.has_method(methodname)

func getClass(kbe_obj):
	for c in kbe_scripts_classes:
		if kbe_obj is c:
			return c
	return KBEngine.Entity

func getClassNameFromObj(kbe_obj):
	var c = getClass(kbe_obj)
	if kbe_scripts_dict_rev.has(c):
		return kbe_scripts_dict_rev[c]
	else:
		return "Entity"

func getClassNameFromClass(kbe_class):
	if kbe_scripts_dict_rev.has(kbe_class):
		return kbe_scripts_dict_rev[kbe_class]
	else:
		return "Entity"