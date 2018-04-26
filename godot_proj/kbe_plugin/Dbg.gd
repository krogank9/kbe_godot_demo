var lastPrint = 0
func checkPrint(pause=false):
	if OS.get_ticks_msec() - lastPrint < 100 and pause:
		OS.delay_msec(80)
	lastPrint = OS.get_ticks_msec()

func skipPrint():
	return OS.get_ticks_msec() - lastPrint < 100

func ERROR_MSG(m):
	checkPrint(true)
	printerr("ERROR: "+m)
	
func DEBUG_MSG(m):
	checkPrint()
	print("DEBUG: "+m)

func WARNING_MSG(m):
	checkPrint()
	print("WARNING: "+m)

func INFO_MSG(m):
	checkPrint()
	print("INFO: "+m)
