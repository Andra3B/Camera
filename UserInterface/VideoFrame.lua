local Frame = require("UserInterface.Frame")

local VideoFrame = {}

function VideoFrame.Create()
	local self = Class.CreateInstance(Frame.Create(), VideoFrame)

	self._Video = nil

	self._Playing = false
	self._Time = 0

	return self
end

function VideoFrame:Update(deltaTime)
	Frame.Update(self, deltaTime)

	if self._Playing then
		local video = self:GetVideo()

		if video then
			self._Time = self._Time + deltaTime

			if video.FrameTime - self._Time < 0 then
				local success, needsAnotherPacket, endOfFrames

				while true do
					success = video:GetNextPacket()

					if not success or video.EndOfStream then
						self:SetPlaying(false)

						break
					else
						if video.Livestreaming then
							video:SendPacketToLivestream()
						end

						success, needsAnotherPacket, endOfFrames = video:GetNextFrame()
						
						if success and not needsAnotherPacket then
							break
						end
					end
				end

				video:RefreshYUVImages()
			end
		end
	end
end

function VideoFrame:Draw()
	local video = self:GetVideo()

	if video then
		video:RefreshRGBAImage()
	end
	
	Frame.Draw(self)
end

function VideoFrame:GetVideo()
	return self._Video
end

function VideoFrame:GetBackgroundImage()
	return self._Video and self._Video:GetRGBAImage() or Frame.GetBackgroundImage(self)
end

function VideoFrame:SetVideo(video)
	self._Video = video
	self._Time = 0

	if not video then
		self._Playing = false
	end
end

function VideoFrame:IsPlaying()
	return self._Playing
end

function VideoFrame:SetPlaying(playing)
	self._Playing = playing
end

function VideoFrame:Destroy()
	if not self._Destroyed then
		if self._Video then
			self._Video:Destroy()
		end

		self._Video = nil

		Frame.Destroy(self)
	end
end

return Class.CreateClass(VideoFrame, "VideoFrame", Frame)