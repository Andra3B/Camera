local MotionTracker = {}

function MotionTracker.Create(width, height)
	local self = Class.CreateInstance(Entity.Create(), MotionTracker)

	self._MotionMask = love.graphics.newCanvas(width, height)
	self._PreviousMotionMask = love.graphics.newCanvas(width, height)

	self._ReductionCanvases = {}

	repeat
		local reductionCanvas = love.graphics.newCanvas(width, height, {format = "rgba16f", readable = true})
		reductionCanvas:setWrap("clampzero")
		reductionCanvas:setFilter("nearest")

		table.insert(self._ReductionCanvases, reductionCanvas)

		width = math.ceil(width * 0.5)
		height = math.ceil(height * 0.5)
	until width == 1 and height == 1

	local reductionCanvas = love.graphics.newCanvas(1, 1, {format = "rgba16f", readable = true})
	reductionCanvas:setWrap("clampzero")
	reductionCanvas:setFilter("nearest")

	table.insert(self._ReductionCanvases, reductionCanvas)

	self._LowerThreshold = 0.01
	self._HigherThreshold = 0.2

	return self
end

function MotionTracker:Update(currentFrame)
	love.graphics.push("all")
	love.graphics.reset()

	local motionMask = self._MotionMask
	self._MotionMask = self._PreviousMotionMask
	self._PreviousMotionMask = motionMask

	love.graphics.setCanvas(self._MotionMask)
	love.graphics.setShader(Shaders.MotionMask)
	Shaders.MotionMask:send("PreviousMotionMask", self._PreviousMotionMask)
	Shaders.MotionMask:send("LowerThreshold", self._LowerThreshold)
	Shaders.MotionMask:send("HigherThreshold", self._HigherThreshold)
	love.graphics.draw(currentFrame)
	
	love.graphics.setBlendMode("replace")

	local encodeCanvas = self._ReductionCanvases[1]

	love.graphics.setCanvas(encodeCanvas)
	love.graphics.setShader(Shaders.COMEncode)
	love.graphics.draw(self._MotionMask)

	love.graphics.setShader(Shaders.Reduction)

	for index = 2, #self._ReductionCanvases, 1 do
		local previousReductionCanvas = self._ReductionCanvases[index - 1]

		love.graphics.setCanvas(self._ReductionCanvases[index])
		Shaders.Reduction:send("TexelSize", {1/previousReductionCanvas:getPixelWidth(), 1/previousReductionCanvas:getPixelHeight()})
		love.graphics.clear(1, 0, 0, 1)
		love.graphics.draw(previousReductionCanvas)
	end

	love.graphics.pop()
end

function MotionTracker:GetCenterOfMotion()
	local COMData = self._ReductionCanvases[#self._ReductionCanvases]:newImageData()
	local x, y, motionSum = COMData:getPixel(0, 0)
	COMData:release()

	return x, y
end

function MotionTracker:Destroy()
	if not self._Destroyed then

		self._MotionMask:release()
		self._MotionMask = nil

		self._PreviousMotionMask:release()
		self._PreviousMotionMask = nil

		for index = 1, #self._ReductionCanvases, 1 do
			self._ReductionCanvases[index]:release()
		end

		self._ReductionCanvases = nil

		Entity.Destroy(self)
	end
end

return Class.CreateClass(MotionTracker, "MotionTracker", Entity)