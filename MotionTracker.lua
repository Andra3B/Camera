local MotionTracker = {}

function MotionTracker.Create(width, height)
	local self = Class.CreateInstance(nil, MotionTracker)

	self._DifferenceLuminanceCanvas = love.graphics.newCanvas(width, height)
	self._PreviousDifferenceLuminanceCanvas = love.graphics.newCanvas(width, height)

	self._BlurredDifferenceCanvas = love.graphics.newCanvas(width, height)

	self._MotionCanvas = love.graphics.newCanvas(width, height)
	self._PreviousMotionCanvas = love.graphics.newCanvas(width, height)

	self._MotionWeightedCanvas = love.graphics.newCanvas(width, height)
	self._ReductionCanvases = {}

	repeat
		width = math.ceil(width * 0.5)
		height = math.ceil(height * 0.5)

		table.insert(self._ReductionCanvases, love.graphics.newCanvas(width, height, {format = "rgba32f"}))
	until width == 1 and height == 1

	self._FilterFactor = 0.25
	self._FilterGain = 1.0
	self._LowerThreshold = 0.04
	self._HigherThreshold = 0.08
	self._Decay = 0.0

	self._Destroyed = false

	return self
end

function MotionTracker:Update(currentFrame)
	love.graphics.push("all")
	love.graphics.reset()

	local differenceLuminanceCanvas = self._DifferenceLuminanceCanvas
	self._DifferenceLuminanceCanvas = self._PreviousDifferenceLuminanceCanvas
	self._PreviousDifferenceLuminanceCanvas = differenceLuminanceCanvas

	-- Pass One
	love.graphics.setCanvas(self._DifferenceLuminanceCanvas)
	love.graphics.setShader(Shaders.MotionTrackingOne)
	Shaders.MotionTrackingOne:send("PreviousDifferenceLuminance", self._PreviousDifferenceLuminanceCanvas)
	Shaders.MotionTrackingOne:send("FilterFactor", self._FilterFactor)
	Shaders.MotionTrackingOne:send("FilterGain", self._FilterGain)
	love.graphics.draw(currentFrame)
	
	-- Pass Two
	love.graphics.setCanvas(self._BlurredDifferenceCanvas)
	love.graphics.setShader(Shaders.MotionTrackingTwo)
	Shaders.MotionTrackingTwo:send("Pixel", {
		1 / self._BlurredDifferenceCanvas:getWidth(),
		1 / self._BlurredDifferenceCanvas:getHeight()
	})
	love.graphics.draw(self._DifferenceLuminanceCanvas)

	local motionCanvas = self._MotionCanvas
	self._MotionCanvas = self._PreviousMotionCanvas
	self._PreviousMotionCanvas = motionCanvas

	-- Pass Three
	love.graphics.setCanvas(self._MotionCanvas)
	love.graphics.setShader(Shaders.MotionTrackingThree)
	Shaders.MotionTrackingThree:send("PreviousMotion", self._PreviousMotionCanvas)
	Shaders.MotionTrackingThree:send("LowerThreshold", self._LowerThreshold)
	Shaders.MotionTrackingThree:send("HigherThreshold", self._HigherThreshold)
	Shaders.MotionTrackingThree:send("Decay", self._Decay)
	love.graphics.draw(self._BlurredDifferenceCanvas)

	--[[
	-- Pass Four
	love.graphics.setCanvas(self._MotionWeightedCanvas)
	love.graphics.setShader(Shaders.MotionTrackingFour)
	love.graphics.draw(self._MotionCanvas)

	-- Pass Five
	love.graphics.setShader(Shaders.MotionTrackingFive)

	local sourceCanvas = self._MotionWeightedCanvas
	for _, reductionCanvas in ipairs(self._ReductionCanvases) do
		love.graphics.setCanvas(reductionCanvas)
		Shaders.MotionTrackingFive:send("SourcePixel", {
			1 / sourceCanvas:getWidth(),
			1 / sourceCanvas:getHeight()
		})
		love.graphics.draw(sourceCanvas)
		sourceCanvas = reductionCanvas
	end
	--]]

	love.graphics.pop()
end

function MotionTracker:GetCenterOfMotion()
	local centerOfMotionImage = self._ReductionCanvases[#self._ReductionCanvases]:newImageData()
	local xWeightSum, yWeightSum, weightSum = centerOfMotionImage:getPixel(0, 0)
	centerOfMotionImage:release()

	if weightSum > 0 then
		return xWeightSum / weightSum, yWeightSum / weightSum
	else
		return 0, 0
	end
end

function MotionTracker:IsDestroyed()
	return self._Destroyed
end

function MotionTracker:Destroy()
	if not self._Destroyed then
		self._DifferenceLuminanceCanvas:release()
		self._DifferenceLuminanceCanvas = nil

		self._PreviousDifferenceLuminanceCanvas:release()
		self._PreviousDifferenceLuminanceCanvas = nil

		self._BlurredDifferenceCanvas:release()
		self._BlurredDifferenceCanvas = nil

		self._MotionCanvas:release()
		self._MotionCanvas = nil

		self._PreviousMotionCanvas:release()
		self._PreviousMotionCanvas = nil

		self._MotionWeightedCanvas:release()
		self._MotionWeightedCanvas = nil

		for index = 1, #self._ReductionCanvases, 1 do
			self._ReductionCanvases[index]:release()
		end

		self._ReductionCanvases = nil

		self._Destroyed = true
	end
end

return Class.CreateClass(MotionTracker, "MotionTracker")