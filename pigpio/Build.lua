require("FFILoader").CreateBindings({"gpio"}, "pigpio/pigpio.i", {{"pigpio", "pigpio"}}, ".", "pigpio", nil, nil)

print("pigpio built!")