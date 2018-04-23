var lastPrint = 0
func checkPrint(pause=true):
	if OS.get_ticks_msec() - lastPrint < 100 and pause:
		OS.delay_msec(80)
	lastPrint = OS.get_ticks_msec()

func ERROR_MSG(m):
	checkPrint()
	printerr("ERROR: "+m)
	
func DEBUG_MSG(m):
	checkPrint()
	print("DEBUG: "+m)

func WARNING_MSG(m):
	#checkPrint(false)
	print("WARNING: "+m)

func INFO_MSG(m):
	#checkPrint(false)
	print("INFO: "+m)
