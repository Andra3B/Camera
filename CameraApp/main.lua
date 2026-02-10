require("Setup")

socket = require("socket")
utf8 = require("utf8")

NetworkServer = require("NetworkServer")

local livestreamReceiver = nil
local livestreamReceiverPort = nil

if jit.os == "Windows" then
	libav = require("libav")

	VideoReader = require("VideoReader")
	VideoWriter = require("VideoWriter")

	livestreamIn = nil
	livestreamOut = nil
	livestreamFrameBuffer = nil
	livestreamFrameBufferHandle = nil
	livestreamTime = 0

	function StartLivestream(from, port)
		if not livestreamReceiver or livestreamReceiver == from then
			if not livestreamIn then
				livestreamTime = 0

				local url = VideoReader.GetCameraURL()

				if url then
					livestreamIn = VideoReader.CreateFromURL(url, "dshow")
				else
					livestreamIn = VideoReader.CreateFromURL("Assets/Videos/Cars.mp4", "mp4")
				end

				if livestreamFrameBufferHandle then
					livestreamFrameBuffer:release()
					livestreamFrameBuffer = nil
					livestreamFrameBufferHandle = nil
				end
			end

			if livestreamIn then
				if not livestreamFrameBufferHandle then
					livestreamFrameBuffer = love.image.newImageData(livestreamIn.Width, livestreamIn.Height, "rgba8")
					livestreamFrameBufferHandle = ffi.cast("uint8_t*", livestreamFrameBuffer:getFFIPointer())
				end

				if livestreamFrameBufferHandle then
					livestreamOut = VideoWriter.CreateFromURL(
						"udp://"..from:GetRemoteDetails()..":"..port,
						"h264",
						livestreamIn.Width, livestreamIn.Height,
						livestreamIn.FPS
					)

					livestreamReceiver = from
					livestreamReceiverPort = port
				end
			end
		end
	end

	function StopLivestream(from)
		if livestreamReceiver == from then
			if livestreamFrameBufferHandle then
				livestreamFrameBuffer:release()
				livestreamFrameBuffer = nil
				livestreamFrameBufferHandle = nil
			end

			if livestreamOut then
				livestreamOut:Destroy()
				livestreamOut = nil

				livestreamReceiver = nil
				livestreamReceiverPort = nil
			end

			if livestreamIn then
				livestreamIn:Destroy()
				livestreamIn = nil
			end
		end
	end
else
	pigpio = require("pigpio")

	livestreamPID = -1
	
	function StartLivestream(from, port)
		if livestreamPID < 0 then
			os.execute(
				"rpicam-vid -t 0 --codec h264 --nopreview --inline --width 1280 --height 720 -o udp://"..from:GetRemoteDetails()..":"..port.." > /dev/null 2>&1 & echo $! > LivestreamPID.txt"
			)

			local livestreamFile = io.open("LivestreamPID.txt", "r")
			livestreamPID = tonumber(livestreamFile:read("*a"):match("^%s*(%d+)%s*$"))
			livestreamFile:close()
			os.remove("LivestreamPID.txt")

			livestreamReceiver = from
			livestreamReceiverPort = port
		end
	end

	function StopLivestream(from)
		if livestreamPID > 0 and livestreamReceiver == from then
			livestreamPID = os.execute("kill "..livestreamPID)
			livestreamPID = -1
		end
	end
end

local AppNetworkServer = nil

function love.load()
	Log.Info(Enum.LogCategory.Camera, "Camera starting...")

	AppNetworkServer = NetworkServer.Create()
	AppNetworkServer:Bind(nil, 64641)

	AppNetworkServer.Events:Listen("StartLivestream", StartLivestream)
	AppNetworkServer.Events:Listen("StopLivestream", StopLivestream)
	AppNetworkServer.Events:Listen("Disconnect", StopLivestream)
	AppNetworkServer.Events:Listen("All", function(command, from)
		if command == "Disconnect" then
			Log.Info(Enum.LogCategory.Camera, "Client %s:%d disconnected", from:GetLocalDetails())
		else
			Log.Info(Enum.LogCategory.Camera, "Received command \"%s\" from %s:%d", command, from:GetLocalDetails())
		end
	end)


	if jit.os == "Windows" then
		libav.avdevice.avdevice_register_all()
	else
		AppNetworkServer.Events:Listen("SetServoAngle", function(from, angle)
			angle = tonumber(angle)
			
			if angle then
				pigpio.gpioServo(18, 1500 + (math.clamp(angle, -90, 90) / 90) * 800)
			end
		end)

		pigpio.gpioInitialise()
	end

	Log.Info(Enum.LogCategory.Camera, "Camera started")
	Log.Info(Enum.LogCategory.Camera, "Camera configured for \"%s\"", jit.os)

	AppNetworkServer:Listen()

	Log.Info(Enum.LogCategory.Camera, "Camera listening for clients on %s:%d", AppNetworkServer:GetLocalDetails())
end

function love.update(deltaTime)
	AppNetworkServer:Update()

	if livestreamFrameBufferHandle then
		livestreamTime = livestreamTime + deltaTime
		
		if livestreamTime > livestreamIn.FrameTime then
			while true do
				local packetHandle = livestreamIn:ReadPacket()
				local frameHandle, needsAnotherPacket, endOfFrames =
					livestreamIn:ReadFrame(packetHandle, livestreamFrameBufferHandle)

				if packetHandle then
					libav.avcodec.av_packet_free(ffi.new("AVPacket*[1]", packetHandle))
				end

				if frameHandle then
					livestreamOut:WriteFrame(frameHandle)

					break
				elseif not needsAnotherPacket then
					livestreamIn:Destroy()
					livestreamIn = nil

					StartLivestream(livestreamReceiver, livestreamReceiverPort)

					break
				end
			end
		end
	end
end


function love.quit(exitCode)
	StopLivestream(livestreamReceiver)

	if pigpio then
		pigpio.gpioTerminate()
	end

	AppNetworkServer:Destroy()

	Log.Info(Enum.LogCategory.Camera, "Server stopped!")
end

function love.run()
	love.load()

	love.timer.step()
	return function()
		love.event.pump()

		for name, a, b, c, d, e, f in love.event.poll() do
			if name == "quit" then
				a = a or 0

				love.quit(a)
				return a
			end

			local handler = love.handlers[name]

			if handler then
				handler(a, b, c, d, e, f)
			end
		end

		love.update(love.timer.step())

		if love.graphics.isActive() then
			love.draw()
		end

		love.timer.sleep(0.001)
	end
end