local Video = {}

local function GetAVErrorString(errorCode)
	local errorDescriptionHandle = ffi.new("char[256]")
	libav.avutil.av_strerror(errorCode, errorDescriptionHandle, 256)

	return ffi.string(errorDescriptionHandle)
end

function Video.CreateFromHandle(sourceHandle)
	if libav.avformat.avformat_find_stream_info(sourceHandle, nil) >= 0 then
		local codecHandleHandle = ffi.new("const AVCodec*[1]")
		
		local streamIndex = libav.avformat.av_find_best_stream(
			sourceHandle, libav.avutil.AVMEDIA_TYPE_VIDEO, -1, -1, codecHandleHandle, 0
		)

		if streamIndex >= 0 then
			local videoStreamHandle = sourceHandle.streams[streamIndex]
			local codecParametersHandle = videoStreamHandle.codecpar
				
			local codecContextHandle = libav.avcodec.avcodec_alloc_context3(codecHandleHandle[0])
			libav.avcodec.avcodec_parameters_to_context(codecContextHandle, codecParametersHandle)

			if libav.avcodec.avcodec_open2(codecContextHandle, codecHandleHandle[0], nil) == 0 then
				local parserContextHandle = libav.avcodec.av_parser_init(codecContextHandle.codec_id)

				if parserContextHandle ~= nil then
					local self = Class.CreateInstance(nil, Video)

					self._SourceHandle = sourceHandle
					self._VideoStreamHandle = videoStreamHandle
					self._EndOfStream = false

					self._CodecContextHandle = codecContextHandle
					self._ParserContextHandle = parserContextHandle

					self._Width = codecParametersHandle.width
					self._Height = codecParametersHandle.height
					self._TimeBase = videoStreamHandle.time_base.num / videoStreamHandle.time_base.den
					self._Duration =  tonumber(sourceHandle.duration / libav.avutil.AV_TIME_BASE)

					self._PacketTime = 0
					self._FrameTime = 0

					self._PacketHandle = libav.avcodec.av_packet_alloc()
					self._FrameHandle = libav.avutil.av_frame_alloc()
					
					self._YImageData = love.image.newImageData(self._Width, self._Height, "r8")
					self._YImage = love.graphics.newImage(self._YImageData)
					
					self._UVImageData = love.image.newImageData(self._Width * 0.5, self._Height, "r8")
					self._UVImage = love.graphics.newImage(self._UVImageData)
					
					self._RGBAImage = love.graphics.newCanvas(self._Width, self._Height)

					self._RefreshedRGBAImage = false
					self._RefreshedYUVImage = false

					self._LivestreamHandle = nil
					self._LivestreamVideoStreamHandle = nil

					return self
				else
					Log.Error(Enum.LogCategory.Video, "Unable to initialise packet parser context!")
				end
			else
				Log.Error(Enum.LogCategory.Video, "Unable to setup codec context!")
			end

			libav.avcodec.avcodec_free_context(ffi.new("AVCodecContext*[1]", codecContextHandle))
		elseif streamIndex == libav.avutil.AVERROR_STREAM_NOT_FOUND then
			Log.Error(Enum.LogCategory.Video, "Source doesnt contain a valid video stream!")
		else
			Log.Error(Enum.LogCategory.Video, "No supported decoder for video stream!")
		end
	else
		Log.Error(Enum.LogCategory.Video, "Unable to determine stream information!")
	end
end

function Video.CreateFromURL(url)
	local sourceHandleHandle = ffi.new("AVFormatContext*[1]")
	local status = libav.avformat.avformat_open_input(sourceHandleHandle, url, nil, nil)

	if status == 0 then
		return Video.CreateFromHandle(sourceHandleHandle[0])
	else
		Log.Error(Enum.LogCategory.Video, "Failed to open url %s! %s", url, GetAVErrorString(status))
	end
end

function Video:IsEndOfStream()
	return self._EndOfStream
end

function Video:GetYUVImages()
	return self._YImage, self._UVImage, self._YImageData, self._UVImageData
end

function Video:GetRGBAImage()
	return self._RGBAImage
end

function Video:GetPacketTime()
	return self._PacketTime
end

function Video:GetFrameTime()
	return self._FrameTime
end

function Video:SetTime(time)
	time = math.clamp(time, 0, self._Duration)

	if libav.avformat.av_seek_frame(
		self._SourceHandle,
		self._VideoStreamHandle.index,
		time / self._TimeBase,
		0
	) >= 0 or libav.avformat.av_seek_frame(
		self._SourceHandle,
		self._VideoStreamHandle.index,
		time / self._TimeBase,
		libav.avutil.AVSEEK_FLAG_BACKWARD
	) >= 0 then
		libav.avcodec.avcodec_flush_buffers(self._CodecContextHandle)

		self._EndOfStream = false

		return true
	else
		Log.Error(Enum.LogCategory.Video, "Failed to set video time!")
	end

	return false
end

function Video:RefreshRGBAImage()
	if not self._RefreshedRGBAImage then
		love.graphics.push("all")

		love.graphics.setScissor()
		love.graphics.setCanvas(self._RGBAImage)
		love.graphics.setBlendMode("replace", "premultiplied")

		love.graphics.setShader(UserInterface.Shaders.YUV2RGBA)
		UserInterface.Shaders.YUV2RGBA:send("uvImage", self._UVImage)

		love.graphics.draw(self._YImage)

		love.graphics.pop()

		self._RefreshedRGBAImage = true
	end
end

function Video:RefreshYUVImages()
	if not self._RefreshedYUVImage then
		local frame = self._FrameHandle

		local width = frame.width
		local height = frame.height

		local yDataByteCount = width * height

		local halfWidth = frame.width * 0.5
		local halfHeight = frame.height * 0.5

		local uvDataByteCount = halfWidth * halfHeight

		local yImageDataHandle = ffi.cast("uint8_t*", self._YImageData:getFFIPointer())
		local uvImageDataHandle = ffi.cast("uint8_t*", self._UVImageData:getFFIPointer())

		if frame.linesize[0] == width then
			ffi.copy(yImageDataHandle, frame.data[0], yDataByteCount)
		else
			for y = 0, height - 1, 1 do
				ffi.copy(
					yImageDataHandle + y * width,
					frame.data[0] + y * frame.linesize[0],
					width
				)
			end
		end

		if frame.linesize[1] == halfWidth then
			ffi.copy(uvImageDataHandle, frame.data[1], uvDataByteCount)
		else
			for y = 0, halfHeight - 1, 1 do
				ffi.copy(
					uvImageDataHandle + y * halfWidth,
					frame.data[1] + y * frame.linesize[1],
					halfWidth
				)
			end
		end

		if frame.linesize[2] == halfWidth then
			ffi.copy(uvImageDataHandle + uvDataByteCount, frame.data[2], uvDataByteCount)
		else
			local vImageDataHandle = uvImageDataHandle + uvDataByteCount
			for y = 0, halfHeight - 1, 1 do
				ffi.copy(
					vImageDataHandle + y * halfWidth,
					frame.data[2] + y * frame.linesize[2],
					halfWidth
				)
			end
		end

		self._YImage:replacePixels(self._YImageData)
		self._UVImage:replacePixels(self._UVImageData)

		self._RefreshedYUVImage = true
	end
end

function Video:GetNextPacket()
	if not self._EndOfStream then
		local parsedPacketHandle = self._PacketHandle
		local unparsedPacketHandle = libav.avcodec.av_packet_alloc()

		libav.avcodec.av_packet_unref(parsedPacketHandle)

		local success = true
		local errorMessage = nil

		while true do
			local status = libav.avformat.av_read_frame(self._SourceHandle, unparsedPacketHandle)

			if unparsedPacketHandle.stream_index == self._VideoStreamHandle.index then
				if status == 0 then
					local parsedPacketDataHandle = ffi.new("uint8_t*[1]")
					local parsedPacketDataSizeHandle = ffi.new("int[1]")

					while parsedPacketDataSizeHandle[0] == 0 do
						local bytesConsumed = libav.avcodec.av_parser_parse2(
							self._ParserContextHandle, self._CodecContextHandle,
							parsedPacketDataHandle, parsedPacketDataSizeHandle,
							unparsedPacketHandle.data, unparsedPacketHandle.size,
							unparsedPacketHandle.pts, unparsedPacketHandle.dts, unparsedPacketHandle.pos
						)

						unparsedPacketHandle.data = unparsedPacketHandle.data + bytesConsumed
						unparsedPacketHandle.size = unparsedPacketHandle.size - bytesConsumed
					end

					libav.avcodec.av_new_packet(parsedPacketHandle, parsedPacketDataSizeHandle[0])
					ffi.copy(parsedPacketHandle.data, parsedPacketDataHandle[0], parsedPacketDataSizeHandle[0])
					parsedPacketHandle.pts = unparsedPacketHandle.pts
					parsedPacketHandle.dts = unparsedPacketHandle.dts
					parsedPacketHandle.pos = unparsedPacketHandle.pos
					parsedPacketHandle.stream_index = unparsedPacketHandle.stream_index
					
					self._PacketTime = tonumber(parsedPacketHandle.pts) * self._TimeBase

					break
				elseif status == libav.avutil.AVERROR_EOF then
					libav.avcodec.avcodec_send_packet(self._CodecContextHandle, nil)
				
					self._EndOfStream = true

					break
				else
					success = false
					errorMessage = GetAVErrorString(status)
					
					break
				end
			end
		end

		libav.avcodec.av_packet_free(ffi.new("AVPacket*[1]", unparsedPacketHandle))

		return success, errorMessage
	end

	return true
end

function Video:GetNextFrame()
	if self._EndOfStream then
		if libav.avcodec.avcodec_receive_frame(self._CodecContextHandle, self._FrameHandle) == 0 then
			self._RefreshedRGBAImage = false
			self._RefreshedYUVImage = false
			
			return true, false, false
		else
			return true, false, true
		end
	else
		status = libav.avcodec.avcodec_send_packet(self._CodecContextHandle, self._PacketHandle)

		if status == 0 then
			status = libav.avcodec.avcodec_receive_frame(self._CodecContextHandle, self._FrameHandle)

			if status == 0 then
				self._RefreshedRGBAImage = false
				self._RefreshedYUVImage = false

				self._FrameTime = tonumber(self._FrameHandle.pts) * self._TimeBase

				return true, false, false
			elseif status == libav.avutil.AVERROR_EAGAIN then			
				return true, true, false
			else
				Log.Error(Enum.LogCategory.Video, "Failed to receive frame! %s", GetAVErrorString(status))

				return false
			end
		else
			Log.Error(Enum.LogCategory.Video, "Failed to decode packet! %s", GetAVErrorString(status))

			return false
		end
	end
end

function Video:StartLivestream(url)
	if self._LivestreamHandle == nil then
		local livestreamHandleHandle = ffi.new("AVFormatContext*[1]")		
		libav.avformat.avformat_alloc_output_context2(livestreamHandleHandle, nil, "mpegts", url)

		local livestreamHandle = livestreamHandleHandle[0]
		local livestreamVideoStreamHandle = libav.avformat.avformat_new_stream(livestreamHandle, nil)
		
		self._LivestreamHandle = livestreamHandle
		self._LivestreamVideoStreamHandle = livestreamVideoStreamHandle

		libav.avcodec.avcodec_parameters_copy(livestreamVideoStreamHandle.codecpar, self._VideoStreamHandle.codecpar)
		livestreamVideoStreamHandle.codecpar.codec_tag = 0

		local pbHandleHandle = ffi.new("AVIOContext*[1]")
		libav.avformat.avio_open2(
			pbHandleHandle, livestreamHandle.url, libav.avformat.AVIO_FLAG_WRITE, nil, nil
		)
		livestreamHandle.pb = pbHandleHandle[0]

		local response = libav.avformat.avformat_write_header(livestreamHandle, nil)

		return true
	end

	return false
end

function Video:IsLivestreaming()
	return self._LivestreamHandle ~= nil
end

function Video:SendPacketToLivestream()
	if self._LivestreamHandle ~= nil then
		local packetHandle = libav.avcodec.av_packet_alloc()

		libav.avcodec.av_packet_ref(packetHandle, self._PacketHandle)

		packetHandle.pts = libav.avutil.av_rescale_q(
			packetHandle.pts, self._VideoStreamHandle.time_base, self._LivestreamVideoStreamHandle.time_base
		)

		packetHandle.dts = libav.avutil.av_rescale_q(
			packetHandle.dts, self._VideoStreamHandle.time_base, self._LivestreamVideoStreamHandle.time_base
		)

		packetHandle.duration = libav.avutil.av_rescale_q(
			packetHandle.duration, self._VideoStreamHandle.time_base, self._LivestreamVideoStreamHandle.time_base
		)

		packetHandle.stream_index = self._LivestreamVideoStreamHandle.index

		libav.avformat.av_interleaved_write_frame(self._LivestreamHandle, packetHandle)

		libav.avcodec.av_packet_free(ffi.new("AVPacket*[1]", packetHandle))
	end
end

function Video:StopLivestream()
	if self._LivestreamHandle ~= nil then
		libav.avformat.av_write_trailer(self._LivestreamHandle);
		libav.avformat.avio_close(self._LivestreamHandle.pb)

		libav.avformat.avformat_free_context(self._LivestreamHandle)

		self._LivestreamHandle = nil
		self._LivestreamVideoStreamHandle = nil
	end
end

function Video:GetWidth()
	return self._Width
end

function Video:GetHeight()
	return self._Height
end

function Video:GetDuration()
	return self._Duration
end

function Video:Destroy()
	if not self._Destroyed then
		self:StopLivestream()

		libav.avformat.avformat_close_input(ffi.new("AVFormatContext*[1]", self._SourceHandle))
		self._SourceHandle = nil

		self._VideoStreamHandle = nil

		libav.avcodec.avcodec_free_context(ffi.new("AVCodecContext*[1]", self._CodecContextHandle))
		self._CodecContextHandle = nil

		libav.avcodec.av_parser_close(self._ParserContextHandle)
		self._ParserContextHandle = nil

		libav.avcodec.av_packet_free(ffi.new("AVPacket*[1]", self._PacketHandle))
		self._PacketHandle = nil

		libav.avutil.av_frame_free(ffi.new("AVFrame*[1]", self._FrameHandle))
		self._FrameHandle = nil

		self._YImageData:release()
		self._YImageData = nil

		self._YImage:release()
		self._YImage = nil
				
		self._UVImageData:release()
		self._UVImageData = nil

		self._UVImage:release()
		self._UVImage = nil

		self._RGBAImage:release()
		self._RGBAImage = nil
		
		self._Destroyed = true
	end
end

return Class.CreateClass(Video, "Video")