local VideoReader = {}

local function GetLibAVErrorString(errorCode)
	local errorDescriptionHandle = ffi.new("char[256]")
	libav.avutil.av_strerror(errorCode, errorDescriptionHandle, 256)

	return ffi.string(errorDescriptionHandle)
end

function VideoReader.CreateFromURL(url, inputFormat, options)
	local inputFormatHandle = inputFormat and libav.avformat.av_find_input_format(inputFormat) or nil

	if inputFormat and inputFormatHandle == nil then
		Log.Critical(Enum.LogCategory.Video, "Input format \"%s\" is not supported!", inputFormat)
	else
		if not url then
			local inputDeviceListHandle = ffi.new("AVDeviceInfoList*[1]")
			local listCount = libav.avdevice.avdevice_list_input_sources(
				inputFormatHandle, nil, nil,
				inputDeviceListHandle
			)

			for deviceIndex = 0, listCount - 1, 1 do
				local deviceDetailsHandle = inputDeviceListHandle[0].devices[deviceIndex]

				local supportsVideo = false
				for typeIndex = 0, deviceDetailsHandle.nb_media_types - 1, 1 do
					if deviceDetailsHandle.media_types[typeIndex] == libav.avutil.AVMEDIA_TYPE_VIDEO then
						supportsVideo = true
						break
					end
				end

				if supportsVideo then
					url = (inputFormat == "dshow" and "video=" or "")..ffi.string(deviceDetailsHandle.device_description)
					break
				end
			end

			libav.avdevice.avdevice_free_list_devices(inputDeviceListHandle)

			if not url then
				Log.Critical(Enum.LogCategory.Video, "Failed to find a video input device!")
			end
		end

		local formatHandleHandle = ffi.new("AVFormatContext*[1]")
		local formatOptionsHandleHandle = ffi.new("AVDictionary*[1]")

		if options then
			for key, value in pairs(options) do
				libav.avutil.av_dict_set(formatOptionsHandleHandle, key, value, 0)
			end
		end

		local code = libav.avformat.avformat_open_input(
			formatHandleHandle,
			url,
			inputFormatHandle,
			formatOptionsHandleHandle
		)
		libav.avutil.av_dict_free(formatOptionsHandleHandle)

		if code >= 0 then
			local formatHandle = formatHandleHandle[0]

			code = libav.avformat.avformat_find_stream_info(formatHandle, nil)

			if code >= 0 then
				local decoderDetailsHandleHandle = ffi.new("const AVCodec*[1]")
				local videoStreamIndex = libav.avformat.av_find_best_stream(
					formatHandle,
					libav.avutil.AVMEDIA_TYPE_VIDEO,
					-1, -1,
					decoderDetailsHandleHandle,
					0
				)
				
				if videoStreamIndex >= 0 then
					local decoderHandle = libav.avcodec.avcodec_alloc_context3(decoderDetailsHandleHandle[0])
					local videoStreamHandle = formatHandle.streams[videoStreamIndex]
					local decoderParametersHandle = videoStreamHandle.codecpar
					libav.avcodec.avcodec_parameters_to_context(decoderHandle, decoderParametersHandle)

					code = libav.avcodec.avcodec_open2(decoderHandle, decoderDetailsHandleHandle[0], nil)

					if code >= 0 then
						local self = Class.CreateInstance(nil, VideoReader)

						self._FormatHandle = formatHandle

						self._VideoStreamIndex = videoStreamIndex
						self._VideoStreamDecoderHandle = decoderHandle

						self._DecoderParametersHandle = decoderParametersHandle

						self._FrameTime = 0
						self._FrameIndex = 0

						self._VideoStreamTimeBase = videoStreamHandle.time_base

						if videoStreamHandle.avg_frame_rate.num ~= 0 and videoStreamHandle.avg_frame_rate.den ~= 0 then
							self._VideoStreamFPS = videoStreamHandle.avg_frame_rate.num / videoStreamHandle.avg_frame_rate.den
						elseif videoStreamHandle.r_frame_rate.num ~= 0 and videoStreamHandle.r_frame_rate.den ~= 0 then
							self._VideoStreamFPS = videoStreamHandle.r_frame_rate.num / videoStreamHandle.r_frame_rate.den
						else
							self._VideoStreamFPS = 30
						end

						self._ConversionContextHandle = libav.swscale.sws_getContext(
							decoderParametersHandle.width, decoderParametersHandle.height, decoderParametersHandle.format,
							decoderParametersHandle.width, decoderParametersHandle.height, libav.avutil.AV_PIX_FMT_RGBA,
							libav.swscale.SWS_BILINEAR,
							nil, nil, nil
						)

						self._Destroyed = false

						return self
					else
						Log.Critical(Enum.LogCategory.Video, "Failed to create video stream decoder for \"%s\"! %s", url, GetLibAVErrorString(code))
					end
				else
					Log.Critical(Enum.LogCategory.Video, "Failed to find valid video stream and decoder details from \"%s\"", url, GetLibAVErrorString(videoStreamIndex))
				end
			else
				Log.Critical(Enum.LogCategory.Video, "Failed to read stream details from \"%s\"! %s", url, GetLibAVErrorString(code))
			end

			libav.avformat.avformat_close_input(ffi.new("AVFormatContext*[1]", formatHandle))
		else
			Log.Critical(Enum.LogCategory.Video, "Failed to open \"%s\"! %s", url, GetLibAVErrorString(code))
		end
	end
end

function VideoReader:GetWidth()
	return self._DecoderParametersHandle.width
end

function VideoReader:GetHeight()
	return self._DecoderParametersHandle.height
end

function VideoReader:GetFPS()
	return self._VideoStreamFPS
end

function VideoReader:GetFrameTime()
	return self._FrameTime
end

function VideoReader:GetTimeBase()
	return self._TimeBase
end

function VideoReader:ReadPacket()
	local packetHandle = libav.avcodec.av_packet_alloc()

	while true do
		libav.avcodec.av_packet_unref(packetHandle)
		local code = libav.avformat.av_read_frame(self._FormatHandle, packetHandle)

		if code >= 0 then
			if packetHandle.stream_index == self._VideoStreamIndex then
				return packetHandle, false
			end
		elseif code == libav.avutil.AVERROR_EOF then
			libav.avcodec.av_packet_free(ffi.new("AVPacket*[1]", packetHandle))

			return nil, true
		end
	end
end

function VideoReader:ReadFrame(packetHandle, rgbaBufferHandle)
	local rgbaFrameHandle, needAnotherPacket, endOfFrames = nil, false, false
	local code = libav.avcodec.avcodec_send_packet(self._VideoStreamDecoderHandle, packetHandle)

	if code >= 0 or code == libav.avcodec.AVERROR_EOF then
		local frameHandle = libav.avutil.av_frame_alloc()

		code = libav.avcodec.avcodec_receive_frame(self._VideoStreamDecoderHandle, frameHandle)

		if code >= 0 then
			rgbaFrameHandle = libav.avutil.av_frame_alloc()

			rgbaFrameHandle.format = libav.avutil.AV_PIX_FMT_RGBA
			rgbaFrameHandle.width = frameHandle.width
			rgbaFrameHandle.height = frameHandle.height
			
			if rgbaBufferHandle == nil then
				libav.avutil.av_frame_get_buffer(rgbaFrameHandle, 0)
			else
				rgbaFrameHandle.data[0] = rgbaBufferHandle
				rgbaFrameHandle.linesize[0] = frameHandle.width * 4
			end
			
			libav.swscale.sws_scale(
				self._ConversionContextHandle,
				ffi.cast("const uint8_t* const*", frameHandle.data), frameHandle.linesize, 0, frameHandle.height,
				rgbaFrameHandle.data, rgbaFrameHandle.linesize
			)

			self._FrameTime = self._FrameIndex * (1 / self._VideoStreamFPS)
			self._FrameIndex = self._FrameIndex + 1

		elseif code == libav.avutil.AVERROR_EAGAIN then
			needAnotherPacket = true
		elseif code == libav.avutil.AVERROR_EOF then
			endOfFrames = true
		else
			Log.Critical(Enum.LogCategory.Video, "Failed to get next frame! %s", GetLibAVErrorString(code))
		end

		libav.avutil.av_frame_free(ffi.new("AVFrame*[1]", frameHandle))
	else
		Log.Critical(Enum.LogCategory.Video, "Failed to decode packet! %s", GetLibAVErrorString(code))
	end
	
	return rgbaFrameHandle, needAnotherPacket, endOfFrames
end

function VideoReader:IsDestroyed()
	return self._Destroyed
end

function VideoReader:Destroy()
	if not self._Destroyed then
		libav.avformat.avformat_close_input(ffi.new("AVFormatContext*[1]", self._FormatHandle))
		self._FormatHandle = nil

		libav.avcodec.avcodec_free_context(ffi.new("AVCodecContext*[1]", self._VideoStreamDecoderHandle))
		self._VideoStreamDecoderHandle = nil

		self._DecoderParametersHandle = nil

		libav.swscale.sws_freeContext(self._ConversionContextHandle)
		self._ConversionContextHandle = nil
		
		self._VideoStreamTimeBase = nil

		self._Destroyed = true
	end
end

return Class.CreateClass(VideoReader, "VideoReader")