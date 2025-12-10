local defines = FFILoader.LoadDefinitions(
	{"gpio"},
	"pigpio/pigpio.i"
)

local pigpio = FFILoader.CreateLibrary("pigpio", defines, true)

return pigpio