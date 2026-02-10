local VideoWriter = {}

local function GetLibAVErrorString(errorCode)
	local errorDescriptionHandle = ffi.new("char[256]")
	libav.avutil.av_strerror(errorCode, errorDescriptionHandle, 256)

	return ffi.string(errorDescriptionHandle)
end

function VideoWriter.CreateFromURL(url, outputFormat, width, height, fps, options)
	local outputFormatHandle = libav.avformat.av_guess_format(outputFormat, url, nil)

	if outputFormatHandle ~= nil then
		local formatHandleHandle = ffi.new("AVFormatContext*[1]")
		libav.avformat.avformat_alloc_output_context2(formatHandleHandle, outputFormatHandle, nil, url)
		local formatHandle = formatHandleHandle[0]

		local encoderDetailsHandle = libav.avcodec.avcodec_find_encoder(
			outputFormatHandle.video_codec == libav.avcodec.AV_CODEC_ID_NONE and libav.avcodec.AV_CODEC_ID_H264 or outputFormatHandle.video_codec
		)

		if encoderDetailsHandle ~= nil then
			local videoStreamHandle = libav.avformat.avformat_new_stream(formatHandle, encoderDetailsHandle)
			local encoderHandle = libav.avcodec.avcodec_alloc_context3(encoderDetailsHandle)

			encoderHandle.codec_id = outputFormatHandle.video_codec
			encoderHandle.width = width
			encoderHandle.height = height
			encoderHandle.time_base = ffi.new("AVRational", {1, fps})
			encoderHandle.framerate = ffi.new("AVRational", {fps, 1})
			encoderHandle.pix_fmt = libav.avutil.AV_PIX_FMT_YUV420P
			encoderHandle.gop_size = 12
			encoderHandle.max_b_frames = 2

			if bit.band(outputFormatHandle.flags, libav.avformat.AVFMT_GLOBALHEADER) > 0 then
				encoderHandle.flags = bit.bor(encoderHandle.flags, libav.avcodec.AV_CODEC_FLAG_GLOBAL_HEADER)
			end
			
			local code = libav.avcodec.avcodec_open2(encoderHandle, encoderDetailsHandle, nil)
			
			if code >= 0 then
				libav.avcodec.avcodec_parameters_from_context(videoStreamHandle.codecpar, encoderHandle)

				videoStreamHandle.time_base = encoderHandle.time_base
				videoStreamHandle.avg_frame_rate = encoderHandle.framerate

				if bit.band(outputFormatHandle.flags, libav.avformat.AVFMT_NOFILE) == 0 then
					local ioHandle = ffi.new("AVIOContext*[1]")
					code = libav.avformat.avio_open(ioHandle, url, libav.avformat.AVIO_FLAG_WRITE)

					if code < 0 then
						Log.Critical(Enum.LogCategory.Video, "Failed to open \"%s\"! %s", url, GetLibAVErrorString(code))
						
						goto Cleanup
					end

					formatHandle.pb = ioHandle[0]
				end

				local formatOptionsHandleHandle = ffi.new("AVDictionary*[1]")

				if options then
					for key, value in pairs(options) do
						libav.avutil.av_dict_set(formatOptionsHandleHandle, key, value, 0)
					end
				end

				code = libav.avformat.avformat_write_header(formatHandle, formatOptionsHandleHandle)
				libav.avutil.av_dict_free(formatOptionsHandleHandle)

				if code >= 0 then
					local self = Class.CreateInstance(Entity.Create(), VideoWriter)

					self._FormatHandle = formatHandle

					self._VideoStreamHandle = videoStreamHandle
					self._VideoStreamEncoderHandle = encoderHandle

					self._EncoderParametersHandle = videoStreamHandle.codecpar

					self._FrameIndex = 0

					self._TempFrameHandle = nil
					self._ConversionContextHandle = nil

					return self
				else
					Log.Critical(Enum.LogCategory.Video, "Failed to write header to \"%s\"", url, GetLibAVErrorString(code))
				end
			else
				Log.Critical(Enum.LogCategory.Video, "Failed to create encoder for \"%s\"! %s", url, GetLibAVErrorString(code))
			end
		else
			Log.Critical(Enum.LogCategory.Video, "Encoder for \"%s\" output format could not be found!", outputFormat)
		end

		::Cleanup::
		libav.avformat.avformat_free_context(formatHandle)
	else
		Log.Critical(Enum.LogCategory.Video, "Output format \"%s\" is not supported!", outputFormat)
	end
end

function VideoWriter:WriteFrame(frameHandle, frameTimeBase)
	local readyFrameHandle = nil

	if
		frameHandle.format ~= self._VideoStreamEncoderHandle.pix_fmt or
		frameHandle.width ~= self._VideoStreamEncoderHandle.width or
		frameHandle.height ~= self._VideoStreamEncoderHandle.height
	then
		if not self._ConversionContextHandle then
			self._ConversionContextHandle = libav.swscale.sws_getContext(
				frameHandle.width, frameHandle.height, frameHandle.format,
				self._VideoStreamEncoderHandle.width, self._VideoStreamEncoderHandle.height, self._VideoStreamEncoderHandle.pix_fmt,
				libav.swscale.SWS_BILINEAR,
				nil, nil, nil
			)

			self._TempFrameHandle = libav.avutil.av_frame_alloc()
			self._TempFrameHandle.format = self._VideoStreamEncoderHandle.pix_fmt
			self._TempFrameHandle.width = self._VideoStreamEncoderHandle.width
			self._TempFrameHandle.height = self._VideoStreamEncoderHandle.height

			libav.avutil.av_frame_get_buffer(self._TempFrameHandle, 0)
		end

		libav.swscale.sws_scale(
			self._ConversionContextHandle,
			ffi.cast("const uint8_t* const*", frameHandle.data), frameHandle.linesize, 0, frameHandle.height,
			self._TempFrameHandle.data, self._TempFrameHandle.linesize
		)

		readyFrameHandle = self._TempFrameHandle
	else
		readyFrameHandle = frameHandle
	end
	
	readyFrameHandle.pts = self._FrameIndex
	self._FrameIndex = self._FrameIndex + 1

	local code = libav.avcodec.avcodec_send_frame(self._VideoStreamEncoderHandle, readyFrameHandle)

	if code >= 0 then
		local packetHandle = ffi.new("AVPacket[1]")
		libav.avcodec.av_init_packet(packetHandle)

		while (libav.avcodec.avcodec_receive_packet(self._VideoStreamEncoderHandle, packetHandle) == 0) do
			libav.avcodec.av_packet_rescale_ts(packetHandle, self._VideoStreamEncoderHandle.time_base, self._VideoStreamHandle.time_base)
			packetHandle[0].stream_index = self._VideoStreamHandle.index

			libav.avformat.av_interleaved_write_frame(self._FormatHandle, packetHandle)
			libav.avcodec.av_packet_unref(packetHandle)
		end

		return true
	else
		Log.Critical(Enum.LogCategory.Video, "Failed to encode frame! %s", GetLibAVErrorString(code))
	end

	return false
end

function VideoWriter:Destroy()
	if not self._Destroyed then
		libav.avcodec.avcodec_send_frame(self._VideoStreamEncoderHandle, nil)

		local packetHandle = ffi.new("AVPacket[1]")
		libav.avcodec.av_init_packet(packetHandle)

		while (libav.avcodec.avcodec_receive_packet(self._VideoStreamEncoderHandle, packetHandle) == 0) do
			packetHandle[0].stream_index = self._VideoStreamHandle.index

			libav.avformat.av_interleaved_write_frame(self._FormatHandle, packetHandle)
			libav.avcodec.av_packet_unref(packetHandle)
		end

		libav.avformat.av_write_trailer(self._FormatHandle)

		if bit.band(self._FormatHandle.oformat.flags, libav.avformat.AVFMT_NOFILE) == 0 then
			libav.avformat.avio_closep(ffi.new("AVIOContext*[1]", self._FormatHandle.pb))
		end

		libav.avformat.avformat_free_context(self._FormatHandle)
		self._FormatHandle = nil
		self._VideoStreamHandle = nil
		self._EncoderParametersHandle = nil

		libav.avcodec.avcodec_free_context(ffi.new("AVCodecContext*[1]", self._VideoStreamEncoderHandle))
		self._VideoStreamEncoderHandle = nil

		if self._TempFrameHandle then
			libav.avutil.av_frame_free(ffi.new("AVFrame*[1]", self._TempFrameHandle))
			self._TempFrameHandle = nil

			libav.swscale.sws_freeContext(self._ConversionContextHandle)
			self._ConversionContextHandle = nil
		end

		Entity.Destroy(self)
	end
end

return Class.CreateClass(VideoWriter, "VideoWriter", Entity)