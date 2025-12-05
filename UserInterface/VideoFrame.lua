local Frame = require("UserInterface.Frame")

local VideoFrame = {}

function VideoFrame.Create()
	local self = Class.CreateInstance(Frame.Create(), VideoFrame)

	self._Video = nil
	self._VideoWriter = nil

	self._Playing = false
	self._Time = 0

	self._FrameHandle = nil

	self._VideoImageBuffer = nil
	self._VideoImageBufferHandle = nil

	self._VideoImage = nil

	return self
end

function VideoFrame:Update(deltaTime)
	Frame.Update(self, deltaTime)
	local video = self:GetVideo()

	if video and self._Playing then
		self._Time = self._Time + deltaTime
		
		if video.FrameTime - self._Time < 0 then
			while true do
				local packetHandle = video:ReadPacket()
				local frameHandle, needsAnotherPacket, endOfFrames = video:ReadFrame(packetHandle, self._VideoImageBufferHandle)

				if packetHandle then
					libav.avcodec.av_packet_free(ffi.new("AVPacket*[1]", packetHandle))
				end

				if frameHandle then
					self._VideoImage:replacePixels(self._VideoImageBuffer)

					if self._FrameHandle then
						libav.avutil.av_frame_free(ffi.new("AVFrame*[1]", self._FrameHandle))
					end

					self._FrameHandle = frameHandle

					if self._VideoWriter then
						self._VideoWriter:WriteFrame(frameHandle)
					end

					break
				elseif not needsAnotherPacket then
					self:SetPlaying(false)

					break
				end
			end
		end
	end
end

function VideoFrame:GetVideo()
	return self._Video
end

function VideoFrame:GetVideoWriter()
	return self._VideoWriter
end

function VideoFrame:SetVideoWriter(writer)
	self._VideoWriter = writer
end

function VideoFrame:GetBackgroundImage()
	return self._Video and self._VideoImage or Frame.GetBackgroundImage(self)
end

function VideoFrame:SetVideo(video)
	if self._Video then
		self._VideoImageBuffer:release()
		self._VideoImageBuffer = nil
		self._VideoImageBufferHandle = nil

		self._VideoImage:release()
		self._VideoImage = nil

		if self._FrameHandle then
			libav.avutil.av_frame_free(ffi.new("AVFrame*[1]", self._FrameHandle))
			self._FrameHandle = nil
		end
	end
	
	self._Video = video

	if video then
		self._VideoImageBuffer = love.image.newImageData(video.Width, video.Height, "rgba8")
		self._VideoImageBufferHandle = ffi.cast("uint8_t*", self._VideoImageBuffer:getFFIPointer())
		
		self._VideoImage = love.graphics.newImage(self._VideoImageBuffer)
	else
		self:SetPlaying(false)
	end
end

function VideoFrame:IsPlaying()
	return self._Playing
end

function VideoFrame:SetPlaying(playing)
	self._Playing = playing
end

function VideoFrame:GetFrameHandle()
	return self._FrameHandle
end

function VideoFrame:Destroy()
	if not self._Destroyed then
		local video = self._Video
		local videoWriter = self._VideoWriter

		if video then
			self:SetVideo(nil)

			video:Destroy()
		end

		if videoWriter then
			self:SetVideoWriter(nil)

			videoWriter:Destroy()
		end

		Frame.Destroy(self)
	end
end

return Class.CreateClass(VideoFrame, "VideoFrame", Frame)