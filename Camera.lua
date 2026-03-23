local appServer = nil

local targetAngle = 0
local currentAngle = 0
local servoMoving = false
local servoSettleTimer = nil

local angularSpeed = 10

local settingsString = nil
local settings = {}

if jit.os == "Windows" then
	function StartLivestream(from, port)
		StopLivestream()

		os.execute([[start /B ffmpeg -f dshow -i video="Integrated Camera" -s 1280x720 -r 30 -b:v 1000k -an -bf 0 -g 30 -fflags flush_packets -flush_packets 1 -muxdelay 0 -f mpegts "tcp://]]..from:GetRemoteDetails()..":"..port..[[?tcp_nodelay=1&send_buffer_size=65536"]])
	end

	function StopLivestream()
		os.execute([[taskkill /IM ffmpeg.exe /F]])
	end
else
	function StartLivestream(from, port)
		StopLivestream()

		os.execute([[(rpicam-vid -t 0 --inline --width 1280 --height 720 --framerate 30 --denoise cdn_off --awb indoor --metering centre --flicker-period 20000 -o - | ffmpeg -i - -c:v copy -f mpegts "tcp://]]..from:GetRemoteDetails()..":"..port..[[?tcp_nodelay&send_buffer_size=10M") > /dev/null 2>&1 & echo $! > Livestream.pid]])
	end
	
	function StopLivestream()
		os.execute([[kill -2 $(cat Livestream.pid) && rm -f Livestream.pid]])
	end
end

local function SetSetting(name, value)
	local valueType = type(value)

	if name == "AngularSpeed" then
		angularSpeed = tonumber(value)
	elseif name == "ServoSettleTime" then
		servoSettleTimer.Duration = tonumber(value)
	end

	if valueType == "number" then
		settings[name] = tonumber(value)

		settingsString = string.gsub(
			settingsString,
			"&"..name..":Number,(.-),(.-),(.-),.-!",
			"&"..name..":Number,%1,%2,%3,"..value.."!"
		)
	elseif valueType == "boolean" then
		settings[name] = value == "true"

		settingsString = string.gsub(
			settingsString,
			"&"..name..":Boolean,.-!",
			"&"..name..":Boolean,"..value.."!"
		)
	elseif valueType == "string" then
		settings[name] = value

		settingsString = string.gsub(
			settingsString,
			"&"..name..":String,(.-),.-!",
			"&"..name..":String,%1,"..value.."!"
		)
	end
end

local function SaveSettings()
	local success, errorMessage
	local retry = 0

	repeat
		success, errorMessage = love.filesystem.write("Settings.txt", settingsString)
		retry = retry + 1
	until success or retry > 3

	if not success then
		Log.Error("Camera", "Failed to save settings to file! %s", errorMessage)
	end
end

function love.load()
	if not love.filesystem.getInfo("Settings.txt", "file") then
		local settingsString = love.filesystem.read("Assets/Other/DefaultCameraSettings.txt")

		if settingsString then
			love.filesystem.write("Settings.txt", settingsString)
		end
	end

	local cameraSettingsString, errorMessage = love.filesystem.read("Settings.txt")

	if not cameraSettingsString then
		error("Failed to read settings file! "..errorMessage)
	end

	settingsString = cameraSettingsString

	servoSettleTimer = Timer.Create(0.5, false)
	servoSettleTimer.Events:Listen("TimerElapsed", function()
		local client = appServer.Children[1]

		if client then
			client:Send("&ServoSettled!")
		end
	end)

	appServer = NetworkServer.Create()
	appServer:Bind(nil, 64641)

	if jit.os == "Linux" then
		pigpio = require("pigpio.pigpio").pigpio

		pigpio.gpioInitialise()
	end

	appServer.Events:Listen("StartLivestream", function(_, _, from, port) StartLivestream(from, port) end)
	appServer.Events:Listen("StopLivestream", function(_, _, from) StopLivestream() end)

	appServer.Events:Listen("IncrementAngle", function(_, _, from, deltaAngle)
		deltaAngle = tonumber(deltaAngle)

		if deltaAngle then
			targetAngle = math.clamp(currentAngle + deltaAngle, -90, 90)
			
			servoMoving = true
		end
	end)

	appServer.Events:Listen("SetAngle", function(_, _, from, angle)
		angle = tonumber(angle)

		if angle then
			targetAngle = math.clamp(angle, -90, 90)
		end
	end)

	appServer.Events:Listen("GetSettings", function(_, _, from)
		from:Send(NetworkServer.GetStringFromCommands({{"GetSettings", settingsString}}))
	end)

	appServer.Events:Listen("SetSetting", function(_, _, from, name, value)
		SetSetting(name, value)
	end)

	appServer.Events:Listen("SaveSettings", SaveSettings)

	appServer.Events:Listen("ChildAdded", function(_, _, from)
		from.IdleTime = settings.IdleTime
		from.PingPeriod = settings.PingPeriod

		Log.Info("Camera", "Client %s:%d connected", from:GetRemoteDetails())
	end)

	appServer.Events:Listen("Disconnected", function(_, _, from)
		StopLivestream()
		SaveSettings()

		Log.Info("Camera", "Client %s:%d disconnected", from:GetRemoteDetails())
	end)
	
	appServer.Events:Listen("All", function(_, _, command, from, ...)
		local ip, port = from:GetRemoteDetails()

		if command == "StartLivestream" then
			Log.Info("Camera", "Client %s:%d started a livestream", ip, port)
		elseif command == "StopLivestream" then
			Log.Info("Camera", "Client %s:%d stopped the livestream", ip, port)
		elseif command == "SetAngle" then
			Log.Info("Camera", "Client %s:%d set the servo angle to %d degrees", ip, port, ...)
		elseif command == "GetSettings" then
			Log.Info("Camera", "Client %s:%d requested settings", ip, port)
		elseif command == "SetSetting" then
			Log.Info("Camera", "Client %s:%d set \"%s\" to %d", ip, port, ...)
		elseif command == "SaveSettings" then
			Log.Info("Camera", "Client %s:%d requested settings to be saved", ip, port)
		end
	end)

	for line in string.gmatch(settingsString, "&[^\n]*") do
		line = string.sub(line, 1, -2)

		local settingDetails = NetworkClient.GetCommandsFromString(line)

		if settingDetails then
			settingDetails = settingDetails[1]

			local settingName = settingDetails[1]

			if settingDetails[2] == "Number" then
				local value = tonumber(settingDetails[6])
					
				if value then
					SetSetting(settingName, value)
				end
			elseif settingDetails[2] == "Boolean" then
				SetSetting(settingName, settingDetails[3])
			elseif settingDetails[2] == "String" then
				SetSetting(settingName, settingDetails[4])
			end
		end
	end

	StopLivestream()

	appServer:Listen()

	Log.Info("Camera", "Camera listening for clients on %s:%d", appServer:GetLocalDetails())
	Log.Info("Camera", "Camera ready")
end

function love.update(deltaTime)
	appServer:RecursiveUpdate()

	local targetAngleError = targetAngle - currentAngle
	currentAngle = currentAngle + math.sign(targetAngleError)*math.min(math.abs(targetAngleError), angularSpeed*deltaTime)

	if pigpio then
		pigpio.gpioServo(18, 750 + ((currentAngle + 90)/180)*(2250 - 750))
	end

	if servoMoving and targetAngleError == 0 then
		servoMoving = false

		servoSettleTimer:Reset()
		servoSettleTimer.Running = true
	end
end

function love.quit(exitCode)
	StopLivestream()	

	if pigpio then
		pigpio.gpioTerminate()
	end

	appServer:Destroy()

	servoSettleTimer:Destroy()

	SaveSettings()

	Log.Info("Camera", "Camera stopping")
end