local Frame = require("UserInterface.Frame")

local VideoFrame = {}

function VideoFrame.Create()
	local self = Class.CreateInstance(Frame.Create(), VideoFrame)

	self._Video = nil
	self._VideoVisible = true

	self._Playing = false
	self._Looping = false

	self._FrameChanged = false

	self._Timer = 0

	self._Events:Listen("VideoVisibleChanged", VideoFrame.RefreshBackgroundImageAbsoluteValues)
	self._Events:Listen("VideoChanged", VideoFrame.RefreshBackgroundImageAbsoluteValues)

	return self
end

function VideoFrame:Update(deltaTime)
	Frame.Update(self, deltaTime)

	if self._Video and self._Playing then
		self._Timer = self._Timer - deltaTime

		if self._Timer <= 0.001 then
			if self._Video:Update() then
				self._Timer = self._Video.FrameDuration
				self._FrameChanged = true
			elseif self._Video.EndOfVideo then
				if self._Looping then
					self._Video.Time = 0
				else
					self.Playing = false
				end
			end
		end
	end
end

function VideoFrame:GetFrameChanged()
	local changed = self._FrameChanged
	self._FrameChanged = false

	return changed
end

function VideoFrame:GetBackgroundImage()
	return (self._VideoVisible and self._Video) and self._Video.Frame or Frame.GetBackgroundImage(self)
end

function VideoFrame:GetVideo()
	return self._Video
end

function VideoFrame:SetVideo(video)
	if video ~= self._Video then
		self._Video = video

		self.Playing = false
		self._Timer = 0

		return true, video
	end
end

function VideoFrame:IsVideoVisible()
	return self._VideoVisible
end

function VideoFrame:SetVideoVisible(visible)
	if visible ~= self._VideoVisible then
		self._VideoVisible = visible

		return true, visible
	end
end

function VideoFrame:IsPlaying()
	return self._Playing
end

function VideoFrame:SetPlaying(playing)
	if playing ~= self._Playing then
		self._Playing = playing

		return true, playing
	end
end

function VideoFrame:IsLooping()
	return self._Looping
end

function VideoFrame:SetLooping(looping)
	if looping ~= self._Looping then
		self._Looping = looping

		return true, looping
	end
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

return Class.CreateClass(VideoFrame, "VideoFrame", Frame)