local Frame = require("UserInterface.Frame")

local VideoFrame = {}

function VideoFrame.Create()
	local self = Class.CreateInstance(Frame.Create(), VideoFrame)

	self._Video = nil
	self._VideoVisible = true

	self._Playing = false
	self._Time = 0
	
	self._FrameHandle = nil
	self._FrameChanged = false

	self._VideoImageBuffer = nil
	self._VideoImageBufferHandle = nil

	self._VideoImage = nil

	return self
end

function VideoFrame:Update(deltaTime)
	Frame.Update(self, deltaTime)
	local video = self._Video

	if video and self._Playing then
		self._Time = self._Time + deltaTime
		
		if self._Time > video.FrameTime then
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
					self._FrameChanged = true
					
					break
				elseif not needsAnotherPacket then
					self.Playing = false

					break
				end
			end
		end
	end
end

function VideoFrame:GetVideo()
	return self._Video
end

function VideoFrame:GetBackgroundImage()
	return self._VideoVisible and self._VideoImage or Frame.GetBackgroundImage(self)
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
		self.Playing = false
	end
end

function VideoFrame:IsVideoVisible()
	return self._VideoVisible
end

function VideoFrame:SetVideoVisible(visible)
	self._VideoVisible = visible
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

function VideoFrame:GetFrameChanged()
	local frameChanged = self._FrameChanged
	self._FrameChanged = false

	return frameChanged
end

function VideoFrame:GetVideoImage()
	return self._VideoImage
end

function VideoFrame:Destroy()
	if not self._Destroyed then
		local video = self._Video

		if video then
			self.Video = nil

			video:Destroy()
		end

		Frame.Destroy(self)
	end
end

return Class.CreateClass(VideoFrame, "VideoFrame", Frame, {
	["AbsoluteBackgroundImagePosition"] = {"Video", "VideoVisible"}
})