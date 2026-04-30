local VideoReader = {}

function VideoReader.Create(url, format, width, height, inputOptions, outputOptions)
	local self = Class.CreateInstance(Entity.Create(), VideoReader)

	self._Width = width
	self._Height = height

	self._FrameData = love.image.newImageData(width, height, "rgba8")
	self._FrameDataPointer = self._FrameData:getFFIPointer()
	self._Frame = love.graphics.newImage(self._FrameData)
	self._FrameCount = 0

	self._Error = nil

	self._DecoderCommandChannel = love.thread.newChannel()
	self._DecoderDataChannel = love.thread.newChannel()
	self._DecoderThread = love.thread.newThread("VideoDecoderThread.lua")

	self._DecoderThread:start(
		self._DecoderCommandChannel,
		self._DecoderDataChannel,
		(inputOptions or "").." -f "..format.." -i \""..url.."\" -f rawvideo -pix_fmt rgba -an -sn -vf scale="..width..":"..height.." "..(outputOptions or "").." -",
		width * height * 4
	)

	return self
end

function VideoReader:GetWidth()
	return self._Width
end

function VideoReader:GetHeight()
	return self._Height
end

function VideoReader:GetFrameData()
	return self._FrameData
end

function VideoReader:GetFrameDataPointer()
	return self._FrameDataPointer
end

function VideoReader:GetFrame()
	return self._Frame
end

function VideoReader:GetFrameCount()
	return self._FrameCount
end

function VideoReader:GetError()
	return self._Error
end

function VideoReader:Update(deltaTime)
	if not self._Error then
		self._Error = self._DecoderThread:getError()

		while self._DecoderDataChannel:getCount() > 1 do
			self._DecoderDataChannel:pop():release()
		end

		local frame = self._DecoderDataChannel:pop()

		if frame then
			ffi.copy(
				self._FrameDataPointer,
				frame:getFFIPointer(),
				self._Width * self._Height * 4
			)

			self._Frame:replacePixels(self._FrameData)

			self._FrameCount = self._FrameCount + 1

			return true
		end
	end

	return false
end

function VideoReader:ClearQueue()
	self._DecoderCommandChannel:supply("Stop")

	while self._DecoderDataChannel:getCount() > 0 do
		self._DecoderDataChannel:pop():release()
	end

	self._DecoderCommandChannel:start("Start")
end

function VideoReader:Destroy()
	if not self._Destroyed then
		self._FrameData:release()
		self._FrameData = nil

		self._FrameDataPointer = nil

		self._Frame:release()
		self._Frame = nil

		self._DecoderCommandChannel:push("Exit")
		
		self._DecoderCommandChannel:release()
		self._DecoderCommandChannel = nil
		
		while self._DecoderDataChannel:getCount() > 0 do
			self._DecoderDataChannel:pop():release()
		end
		
		self._DecoderDataChannel:release()
		self._DecoderDataChannel = nil
		
		self._DecoderThread = nil
		
		Entity.Destroy(self)
	end
end

return Class.CreateClass(VideoReader, "VideoReader", Entity)