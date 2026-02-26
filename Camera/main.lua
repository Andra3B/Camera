local livestreamReceiver = nil
local livestreamReceiverPort = nil

if jit.os == "Windows" then
	libav = require("libav.libav")

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
					livestreamIn = VideoReader.CreateFromURL("Assets/Videos/PeopleWalking.mp4", "mp4")
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
						"mpegts",
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
				"setsid sh -c 'rpicam-vid -t 0 -n --framerate 30 -b 3000000 --width 1280 --height 720 --inline --codec h264 -o - | ffmpeg -fflags nobuffer -flags low_delay -f h264 -i - -f mpegts udp://"..from:GetRemoteDetails()..":"..port.."' >/dev/null 2>&1 & echo $! > LivestreamPID.txt"
			)

			local livestreamFile = io.open("LivestreamPID.txt", "r")
			livestreamPID = tonumber(livestreamFile:read("*a"):match("%d+"))
			livestreamFile:close()
			os.remove("LivestreamPID.txt")

			livestreamReceiver = from
			livestreamReceiverPort = port
		end
	end

	function StopLivestream(from)
		if livestreamPID > 0 and livestreamReceiver == from then
			os.execute("kill -- -"..livestreamPID)
			livestreamPID = -1
		end
	end
end

local AppNetworkServer = nil

function love.load()
	AppNetworkServer = NetworkServer.Create()
	AppNetworkServer:Bind(nil, 64641)

	AppNetworkServer.Events:Listen("StartLivestream", StartLivestream)
	AppNetworkServer.Events:Listen("StopLivestream", StopLivestream)
	AppNetworkServer.Events:Listen("Disconnected", StopLivestream)
	AppNetworkServer.Events:Listen("All", function(command, from)
		if command == "Connected" then
			Log.Info("Camera", "Client %s:%d connected", from:GetRemoteDetails())
		elseif command == "Disconnected" then
			Log.Info("Camera", "Client %s:%d disconnected", from:GetRemoteDetails())
		else
			Log.Info("Camera", "Received command \"%s\" from %s:%d", command, from:GetRemoteDetails())
		end
	end)

	if jit.os == "Windows" then
		libav.avdevice.avdevice_register_all()
	else
		pigpio.gpioInitialise()

		AppNetworkServer.Events:Listen("SetAngle", function(from, angle)
			angle = tonumber(angle)
			
			if angle then
				pigpio.gpioServo(18, 1500 + (math.clamp(angle, -90, 90)/90)*800)
			end
		end)
	end

	Log.Info("Camera", "Camera ready")
	Log.Info("Camera", "Camera configured for \"%s\"", jit.os)

	AppNetworkServer:Listen()

	Log.Info("Camera", "Camera listening for clients on %s:%d", AppNetworkServer:GetLocalDetails())
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
end