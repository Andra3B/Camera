local Frame = require("UserInterface.Frame")

local VideoFrame = {}

function VideoFrame.Create()
	local self = Class.CreateInstance(Frame.Create(), VideoFrame)

	self._Video = nil
	self._VideoVisible = true

	self._Playing = false
	self._Looping = false

	self._FrameUpdated = false

	self._Events:Listen("VideoVisibleChanged", VideoFrame.RefreshBackgroundImageAbsoluteValues)
	self._Events:Listen("VideoChanged", VideoFrame.RefreshBackgroundImageAbsoluteValues)

	return self
end

function VideoFrame:Update(deltaTime)
	Frame.Update(self, deltaTime)

	local video = self._Video

	if video and self._Playing then
		self._FrameUpdated = video:Update()
	end
end

function VideoFrame:GetFrameUpdated()
	local updated = self._FrameUpdated
	self._FrameUpdated = false

	return updated
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