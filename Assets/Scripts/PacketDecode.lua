--if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then require("lldebugger").start() end

local channel, pointerData, videoStreamIndex = ...

require("Setup")

local libav = require("libav.libav")

local pointerDataPointer = ffi.cast("uintptr_t*", pointerData:getFFIPointer())
local formatContextPointer = ffi.new("AVFormatContext*", ffi.cast("void*", pointerDataPointer[0]))
local decoderContextPointer = ffi.new("AVCodecContext*", ffi.cast("void*", pointerDataPointer[1]))
local swsContextPointer = ffi.new("struct SwsContext*", ffi.cast("void*", pointerDataPointer[2]))

local frameQueue = {}

for index = 3, pointerData:getSize()/ffi.sizeof("uintptr_t") - 1, 1 do
	table.insert(frameQueue, ffi.new("AVFrame*", ffi.cast("void*", pointerDataPointer[index])))
end

pointerData:release()
pointerData = nil
pointerDataPointer = nil

local avErrorBuffer = ffi.new("char[256]")
local function GetAVErrorString(errorCode)
	libav.avutil.av_strerror(errorCode, avErrorBuffer, 256)

	return ffi.string(avErrorBuffer).." (Error Code: "..tostring(errorCode)..")"
end

local packetPointer = libav.avcodec.av_packet_alloc()
local framePointer = libav.avutil.av_frame_alloc()

local endOfStream = false
local decoderFlushed = false

local queueFront = 1
local queueBack = 1
local queueSize = 0

local command = nil

while true do
	if command == "Pop" then
		if queueSize > 0 then
			channel:supply(queueFront)

			queueFront = queueFront == #frameQueue and 1 or (queueFront + 1)
			queueSize = queueSize - 1
		elseif endOfStream then
			channel:supply(-1)
		else
			channel:supply(0)
		end
	elseif command == "Flush" then
		libav.avcodec.avcodec_flush_buffers(decoderContextPointer)

		queueFront = 1
		queueBack = 1
		queueSize = 0
	elseif command == "Exit" then
		break
	end

	if
		command == "Stop" or
		queueSize == #frameQueue or
		(queueSize == 0 and endOfStream)
	then
		repeat
			command = channel:demand()
		until command ~= "Stop"
	else
		command = channel:pop()
	end

	if queueSize < #frameQueue then
		local errorCode = 0

		libav.avcodec.av_packet_unref(packetPointer)
		local packetReadResult = libav.avformat.av_read_frame(formatContextPointer, packetPointer)

		if packetReadResult == libav.avformat.AVERROR_EOF then
			if not endOfStream then
				libav.avcodec.avcodec_send_packet(decoderContextPointer, nil)
			end

			endOfStream = true
		else
			if packetReadResult == 0 then
				if packetPointer.stream_index == videoStreamIndex then
					local packetSendResult = libav.avcodec.avcodec_send_packet(decoderContextPointer, packetPointer)

					if packetSendResult == 0 then
						decoderFlushed = false
					elseif packetSendResult == libav.avcodec.AVERROR_EINVAL then
						libav.avcodec.avcodec_send_packet(decoderContextPointer, nil)
						decoderFlushed = false
					elseif packetSendResult ~= libav.avcodec.AVERROR_EAGAIN then
						errorCode = packetSendResult
					end
				else
					goto End
				end
			else
				errorCode = packetReadResult
			end

			endOfStream = false
		end

		if not decoderFlushed then
			local frameReceiveResult = libav.avcodec.avcodec_receive_frame(decoderContextPointer, framePointer)

			if frameReceiveResult == 0 then
				errorCode = libav.swscale.sws_scale_frame(swsContextPointer, frameQueue[queueBack], framePointer)

				if errorCode >= 0 then
					libav.avutil.av_frame_copy_props(frameQueue[queueBack], framePointer)

					queueBack = queueBack == #frameQueue and 1 or (queueBack + 1)
					queueSize = queueSize + 1
				end
			elseif frameReceiveResult == libav.avcodec.AVERROR_EOF then
				decoderFlushed = true
			elseif frameReceiveResult ~= libav.avcodec.AVERROR_EAGAIN then
				errorCode = frameReceiveResult
			end
		end

		if errorCode < 0 then
			Log.Warn("PacketDecode", GetAVErrorString(errorCode))
		end
	end
	
	::End::
end

libav.avcodec.av_packet_free(ffi.new("AVPacket*[1]", packetPointer))
libav.avutil.av_frame_free(ffi.new("AVFrame*[1]", framePointer))