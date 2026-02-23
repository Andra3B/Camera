require("FFILoader").CreateBindings("gpio", "pigpio/pigpio.i", {"pigpio"}, ".", "pigpio", nil, nil)

print("pigpio built!")