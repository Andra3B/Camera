libav = require("libav.libav")
VideoReader = require("VideoReader")

local appServer = nil

local targetServoAngle = 0
local currentServoAngle = 0

local servoAngularSpeed = 10

if jit.os == "Windows" then
	function StartLivestream(from, port)
		StopLivestream()

		os.execute([[start /B ffmpeg -f dshow -video_size 1280x720 -framerate 30 -i video="Integrated Camera" -an -flags low_delay -bf 0 -g 30 -keyint_min 30 -b:v 4M -maxrate 4M -bufsize 1M -fflags flush_packets -flush_packets 1 -muxdelay 0 -f mpegts "udp://]]..from:GetRemoteDetails()..":"..port..[[?pkt_size=1316&fifo_size=262144&overrun_nonfatal=1"]])
	end

	function StopLivestream()
		os.execute([[taskkill /IM ffmpeg.exe /F]])
	end
else
	function StartLivestream(from, port)
		StopLivestream()

		os.execute([[(rpicam-vid -t 0 --low-latency --inline --width 1280 --height 720 --framerate 30 --profile high --intra 10 --flush -o - | ffmpeg -hide_banner -loglevel error -fflags nobuffer -flags low_delay -framerate 30 -f h264 -i - -c copy -f mpegts -muxdelay 0 -flush_packets 1 "udp://]]..from:GetRemoteDetails()..":"..port..[[?pkt_size=1316&fifo_size=16384&overrun_nonfatal=1") > /dev/null 2>&1 & echo $! > Livestream.pid]])
	end
	
	function StopLivestream()
		os.execute([[kill -2 $(cat Livestream.pid) && rm -f Livestream.pid]])
	end
end

local function IncrementServoAngle(deltaAngle)	
	if deltaAngle then
		targetServoAngle = math.clamp(currentServoAngle + deltaAngle, -90, 90)
	end
end

local function SetServoAngularSpeed(speed)
	servoAngularSpeed = speed
end

function love.load()
	appServer = NetworkServer.Create()
	appServer:Bind(nil, 64641)

	VideoReader.Initialize()

	if not VideoReader.GetDefaultCameraURL() then
		if jit.os == "Windows" then
			function StartLivestream(from, port)
				StopLivestream()

				os.execute([[start /B ffmpeg -re -stream_loop -1 -i "Assets/Videos/Cars.mp4" -an -flags low_delay -bf 0 -g 30 -keyint_min 30 -b:v 4M -maxrate 4M -bufsize 1M -fflags flush_packets -flush_packets 1 -muxdelay 0 -f mpegts "udp://]]..from:GetRemoteDetails()..":"..port..[[?pkt_size=1316&fifo_size=262144&overrun_nonfatal=1"]])
			end
		end
	elseif jit.os == "Linux" then
		pigpio = require("pigpio.pigpio").pigpio

		pigpio.gpioInitialise()
	end

	appServer.Events:Listen("StartLivestream", function(_, _, from, port) StartLivestream(from, port) end)
	appServer.Events:Listen("StopLivestream", function(_, _, from) StopLivestream() end)
	appServer.Events:Listen("IncrementServoAngle", function(_, _, deltaAngle) IncrementServoAngle(tonumber(deltaAngle)) end)
	appServer.Events:Listen("SetServoAngularSpeed", function(_, _, speed)
		speed = tonumber(speed)

		if speed then
			servoAngularSpeed = speed
		end
	end)

	appServer.Events:Listen("Connected", function(_, _, from)
		Log.Info("Camera", "Client %s:%d connected", from:GetRemoteDetails())
	end)

	appServer.Events:Listen("Disconnected", function(_, _, from)
		StopLivestream()

		Log.Info("Camera", "Client %s:%d disconnected", from:GetRemoteDetails())
	end)
	
	StopLivestream()

	appServer:Listen()

	Log.Info("Camera", "Camera listening for clients on %s:%d", appServer:GetLocalDetails())
	Log.Info("Camera", "Camera ready")
end

function love.update(deltaTime)
	appServer:RecursiveUpdate()

	local targetAngleError = targetServoAngle - currentServoAngle
	currentServoAngle = currentServoAngle + math.sign(targetAngleError)*math.min(math.abs(targetAngleError), servoAngularSpeed*deltaTime)

	if pigpio then
		pigpio.gpioServo(18, 750 + ((currentServoAngle + 90)/180)*(2250 - 750))
	end
end

function love.quit(exitCode)
	StopLivestream()

	VideoReader.Deinitialize()

	if pigpio then
		pigpio.gpioTerminate()
	end

	appServer:Destroy()

	Log.Info("Camera", "Camera stopping")
end