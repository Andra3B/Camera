local VideoReader = {}

VideoReader.Initialized = false

local avErrorBuffer
local function GetAVErrorString(errorCode)
	libav.avutil.av_strerror(errorCode, avErrorBuffer, 256)

	return ffi.string(avErrorBuffer).." (Error Code: "..tostring(errorCode)..")"
end

function VideoReader.GetDefaultCameraURL(format)
	format = format or (jit.os == "Windows" and "dshow" or "v4l2")
	local inputFormatPointer = libav.avformat.av_find_input_format(format)
	
	local url = nil
	if inputFormatPointer ~= nil then
		local inputDeviceListPointer = ffi.new("AVDeviceInfoList*[1]")
		local listCount = libav.avdevice.avdevice_list_input_sources(
			inputFormatPointer, nil, nil, inputDeviceListPointer
		)

		for deviceIndex = 0, listCount - 1, 1 do
			local deviceDetailsPointer = inputDeviceListPointer[0].devices[deviceIndex]

			local supportsVideo = false
			for typeIndex = 0, deviceDetailsPointer.nb_media_types - 1, 1 do
				if deviceDetailsPointer.media_types[typeIndex] == libav.avdevice.AVMEDIA_TYPE_VIDEO then
					supportsVideo = true
					
					break
				end
			end

			if supportsVideo then
				url = (jit.os == "Windows" and "video=" or "")..ffi.string(deviceDetailsPointer.device_description)

				break
			end
		end

		libav.avdevice.avdevice_free_list_devices(inputDeviceListPointer)
	end

	return url, format
end

function VideoReader.Initialize()
	if not VideoReader.Initialized then
		avErrorBuffer = ffi.new("char[256]")

		libav.avformat.avformat_network_init()
		libav.avdevice.avdevice_register_all()

		VideoReader.Initialized = true
	end
end

function VideoReader.Deinitialize()
	if VideoReader.Initialized then
		avErrorBuffer = nil

		libav.avformat.avformat_network_deinit()

		VideoReader.Initialized = false
	end
end

function VideoReader.Create(url, format, frameQueueCapacity, options)
	url = url or VideoReader.GetDefaultCameraURL(format)
	frameQueueCapacity = frameQueueCapacity or 8

	local errorCode = 0
	local optionsPointerPointer = ffi.new("AVDictionary*[1]")

	if options then
		errorCode = libav.avutil.av_dict_parse_string(
			optionsPointerPointer,
			options,
			"=", ",",
			libav.avutil.AV_DICT_APPEND
		)
	end

	if errorCode >= 0 then
		local formatContextPointer = libav.avformat.avformat_alloc_context()
		errorCode = libav.avformat.avformat_open_input(
			ffi.new("AVFormatContext*[1]", formatContextPointer),
			url,
			format and libav.avformat.av_find_input_format(format) or nil,
			optionsPointerPointer
		)

		local optionsPointer = optionsPointerPointer[0]

		if libav.avutil.av_dict_count(optionsPointer) > 0 then
			local message = "The following options were not found: "
			local previousOptionPointer = ffi.new("AVDictionaryEntry*")

			while true do
				previousOptionPointer = libav.avutil.av_dict_iterate(optionsPointer, previousOptionPointer)

				if previousOptionPointer == nil then
					break
				else
					message = message..ffi.string(previousOptionPointer.key)..", "
				end
			end

			Log.Warn("VideoReader", string.sub(message, 1, -3))
			libav.avutil.av_dict_free(optionsPointerPointer)
		end

		if errorCode >= 0 then
			libav.avformat.avformat_find_stream_info(formatContextPointer, nil)

			local decoderPointerPointer = ffi.new("const AVCodec*[1]")
			errorCode = libav.avformat.av_find_best_stream(
				formatContextPointer, libav.avformat.AVMEDIA_TYPE_VIDEO,
				-1, -1, decoderPointerPointer, 0
			)
			local decoderPointer = decoderPointerPointer[0]

			if errorCode >= 0 then
				local videoStreamIndex = errorCode

				local decoderContextPointer = libav.avcodec.avcodec_alloc_context3(decoderPointer)
				errorCode = libav.avcodec.avcodec_parameters_to_context(
					decoderContextPointer,
					formatContextPointer.streams[videoStreamIndex].codecpar
				)

				if errorCode >= 0 then
					errorCode = libav.avcodec.avcodec_open2(decoderContextPointer, decoderPointer, nil)

					if errorCode >= 0 then
						local swsContextPointer = libav.swscale.sws_getContext(
							decoderContextPointer.width, decoderContextPointer.height,
							decoderContextPointer.pix_fmt,
							decoderContextPointer.width, decoderContextPointer.height,
							libav.avutil.AV_PIX_FMT_RGBA,
							0, nil, nil, nil
						)

						if swsContextPointer ~= nil then
							local self = Class.CreateInstance(Entity.Create(), VideoReader)
			
							self._FormatContextPointer = formatContextPointer
							self._DecoderContextPointer = decoderContextPointer
							self._VideoStreamPointer = formatContextPointer.streams[videoStreamIndex]
							self._VideoStreamIndex = videoStreamIndex
							self._VideoStreamTimeBase = self._VideoStreamPointer.time_base.num/self._VideoStreamPointer.time_base.den
			
							self._SwsContextPointer = swsContextPointer

							self._FrameImageData = love.image.newImageData(
								decoderContextPointer.width,
								decoderContextPointer.height,
								"rgba8"
							)
							self._Frame = love.graphics.newImage(self._FrameImageData)
							self._FrameReferenceTime = nil

							self._AVFramePointerIndex = nil

							self._PacketDecodeThread = love.thread.newThread("PacketDecode.lua")
							self._PacketDecodeChannel = love.thread.newChannel()
			
							self._EndOfVideo = false


							self._FrameQueue = {}

							local pointerData = love.data.newByteData((3 + frameQueueCapacity)*ffi.sizeof("uintptr_t"))
							local pointerDataPointer = ffi.cast("uintptr_t*", pointerData:getFFIPointer())
							
							pointerDataPointer[0] = ffi.cast("uintptr_t", formatContextPointer)
							pointerDataPointer[1] = ffi.cast("uintptr_t", decoderContextPointer)
							pointerDataPointer[2] = ffi.cast("uintptr_t", swsContextPointer)

							for index = 3, frameQueueCapacity + 2, 1 do
								local framePointer = libav.avutil.av_frame_alloc()

								table.insert(self._FrameQueue, framePointer)
								pointerDataPointer[index] = ffi.cast("uintptr_t", framePointer)
							end

							self._PacketDecodeThread:start(
								self._PacketDecodeChannel,
								pointerData,
								self._VideoStreamIndex
							)

							return self
						else
							Log.Error("VideoReader", "Unable to create SwsContext")
						end
					end
				end

				libav.avcodec.avcodec_free_context(ffi.new("AVCodecContext*[1]", decoderContextPointer))
			end

			libav.avformat.avformat_close_input(ffi.new("AVFormatContext*[1]", formatContextPointer))
		end
	end

	Log.Error("VideoReader", GetAVErrorString(errorCode))
end

function VideoReader:GetFrame()
	return self._Frame
end

function VideoReader:GetFrameImageData()
	return self._FrameImageData
end

function VideoReader:GetAVFramePointer()
	return self._FrameQueue[self._AVFramePointerIndex]
end

function VideoReader:GetFrameReferenceTime()
	return self._FrameReferenceTime
end

function VideoReader:SetFrameReferenceTime(time)
	if time ~= self._FrameReferenceTime then
		self._FrameReferenceTime = time

		return true, time
	end
end

function VideoReader:GetWidth()
	return self._DecoderContextPointer.width
end

function VideoReader:GetHeight()
	return self._DecoderContextPointer.height
end

function VideoReader:GetFrameDuration()
	local framePointer = self._FrameQueue[self._AVFramePointerIndex]

	if framePointer then
		return tonumber(framePointer.duration)*self._VideoStreamTimeBase
	else
		return 0
	end
end

function VideoReader:GetDuration()
	return tonumber(self._VideoStreamPointer.duration)*self._VideoStreamTimeBase
end

function VideoReader:GetTime()
	local framePointer = self._FrameQueue[self._AVFramePointerIndex]

	if framePointer then
		return tonumber(framePointer.best_effort_timestamp)*self._VideoStreamTimeBase
	else
		return 0
	end
end

function VideoReader:SetTime(time)
	time = math.floor(time/self._VideoStreamTimeBase)
	self._PacketDecodeChannel:supply("Stop")

	local success = libav.avformat.av_seek_frame(
		self._FormatContextPointer,
		self._VideoStreamIndex,
		time,
		(time*self._VideoStreamTimeBase) < self.Time and libav.avformat.AVSEEK_FLAG_BACKWARD or 0
	)

	if success >= 0 then
		libav.avcodec.avcodec_flush_buffers(self._DecoderContextPointer)

		self._AVFramePointerIndex = nil

		self._PacketDecodeChannel:push("Flush")

		return true
	else
		self._PacketDecodeChannel:push("Start")

		return false
	end
end

function VideoReader:GetFrameQueueCapacity()
	return #self._FrameQueue
end

function VideoReader:IsEndOfVideo()
	return self._EndOfVideo
end

function VideoReader:Update(drop)
	self._PacketDecodeChannel:supply("Pop")
	local frameIndex = self._PacketDecodeChannel:demand()

	self._EndOfVideo = frameIndex == -1

	if not drop then
		if frameIndex > 0 then
			self._AVFramePointerIndex = frameIndex
			local framePointer = self._FrameQueue[frameIndex]

			if not self._FrameReferenceTime then
				self.FrameReferenceTime = love.timer.getTime()
			end

			ffi.copy(
				self._FrameImageData:getFFIPointer(),
				framePointer.data[0],
				framePointer.linesize[0]*framePointer.height
			)
			self._Frame:replacePixels(self._FrameImageData)
		else
			return false
		end
	else
		print("Video frame dropped!")
	end
	
	return true
end

function VideoReader:Destroy()
	if not self._Destroyed then
		self._PacketDecodeChannel:push("Exit")
		
		self._PacketDecodeThread:wait()
		self._PacketDecodeThread:release()
		self._PacketDecodeThread = nil

		self._PacketDecodeChannel:release()
		self._PacketDecodeChannel = nil

		for index = 1, #self._FrameQueue, 1 do
			libav.avutil.av_frame_free(ffi.new("AVFrame*[1]", self._FrameQueue[index]))
		end

		self._FrameQueue = nil

		self._FrameImageData:release()
		self._FrameImageData = nil

		self._Frame:release()
		self._Frame = nil

		libav.swscale.sws_free_context(ffi.new("SwsContext*[1]", self._SwsContextPointer))
		self._SwsContextPointer = nil

		libav.avcodec.avcodec_free_context(ffi.new("AVCodecContext*[1]", self._DecoderContextPointer))
		self._DecoderContextPointer = nil
		
		self._VideoStreamPointer = nil

		libav.avformat.avformat_close_input(ffi.new("AVFormatContext*[1]", self._FormatContextPointer))
		self._FormatContextPointer = nil
		
		Entity.Destroy(self)
	end
end

return Class.CreateClass(VideoReader, "VideoReader", Entity)