local livestreamReceiver = nil
local livestreamReceiverPort = nil

if jit.os == "Windows" then
	function StartLivestream(_, _, from, port)
		os.execute(
			"ffmpeg -stream_loop -1 -re -i Assets/Videos/Cars.mp4 -c copy -f mpegts udp://"..from:GetRemoteDetails()..":"..port
		)

		Log.Info("Camera", "Livestream started")
	end

	function StopLivestream(_, _, from, port)
		Log.Info("Camera", "Livestream stopped")
	end
else
	pigpio = require("pigpio.pigpio")["1"]

	livestreamPID = -1
	
	function StartLivestream(_, _, from, port)
		if livestreamPID < 0 then
			os.execute(
				"setsid sh -c 'rpicam-vid -t 0 -n --framerate 30 -b 3000000 --width 1280 --height 720 --inline --codec h264 -o - | ffmpeg -fflags nobuffer -flags low_delay -f h264 -i - -f mpegts udp://"..from:GetRemoteDetails()..":"..port.."' >/dev/null 2>&1 & echo $! > LivestreamPID.txt"
			)

			local livestreamFile = io.open("LivestreamPID.txt", "r")
			livestreamPID = tonumber(livestreamFile:read("*a"):match("%d+"))
			livestreamFile:close()
			os.remove("LivestreamPID.txt")

			livestreamReceiver = from
			livestreamReceiverPort = port

			Log.Info("Camera", "Livestream started")
		end
	end

	function StopLivestream(_, _, from)
		if livestreamPID > 0 and livestreamReceiver == from then
			os.execute("kill -- -"..livestreamPID)
			livestreamPID = -1

			Log.Info("Camera", "Livestream stopped")
		end
	end
end

local AppNetworkServer = nil

local targetServoAngle = 0
local currentServoAngle = 0

function love.load()
	AppNetworkServer = NetworkServer.Create()
	AppNetworkServer:Bind(nil, 64641)

	if jit.os == "Windows" then
	else
		pigpio.gpioInitialise()

		AppNetworkServer.Events:Listen("SetAngle", function(_, _, from, angle)
			angle = tonumber(angle)
			
			if angle then
				targetServoAngle = math.clamp(angle, -90, 90)
			end
		end)
	end

	AppNetworkServer.Events:Listen("StartLivestream", StartLivestream)
	AppNetworkServer.Events:Listen("StopLivestream", StopLivestream)
	AppNetworkServer.Events:Listen("Connected", function(_, _, from)
		Log.Info("Camera", "Client %s:%d connected", from:GetRemoteDetails())
	end)
	AppNetworkServer.Events:Listen("Disconnected", function(_, _, from)
		StopLivestream(nil, nil, from)

		Log.Info("Camera", "Client %s:%d disconnected", from:GetRemoteDetails())
	end)

	Log.Info("Camera", "Camera ready")
	Log.Info("Camera", "Camera configured for \"%s\"", jit.os)

	AppNetworkServer:Listen()

	Log.Info("Camera", "Camera listening for clients on %s:%d", AppNetworkServer:GetLocalDetails())
end

function love.update(deltaTime)
	AppNetworkServer:RecursiveUpdate()

	currentServoAngle = (1 - deltaTime)*currentServoAngle + deltaTime*targetServoAngle
	pigpio.gpioServo(18, 1500 + math.clamp(currentServoAngle/90, -1, 1)*800)
end

function love.quit(exitCode)
	StopLivestream(livestreamReceiver)

	if pigpio then
		pigpio.gpioTerminate()
	end

	AppNetworkServer:Destroy()
end