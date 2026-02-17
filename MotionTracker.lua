local MotionTracker = {}

function MotionTracker.Create(width, height, subdivisions)	
	local self = Class.CreateInstance(Entity.Create(), MotionTracker)

	self._BackgroundCanvas = love.graphics.newCanvas(width, height)
	self._PreviousBackgroundCanvas = love.graphics.newCanvas(width, height)

	self._ReductionCanvases = {}
	
	self._MotionShapes = nil
	self._LargestMotionShape = 0
	self._AverageMotion = 0
	
	self._MotionThreshold = 0.1
	self._ShapeMinimumArea = 0.001
	self._NeighbourSearchRadius = 2
	self._AdaptionRate = 0.5
	
	local maxSubdivisions = math.floor(math.log(math.min(width, height))/math.log(2))
	for _ = 0, math.clamp(maxSubdivisions - subdivisions, 0, maxSubdivisions), 1 do
		local reductionCanvas = love.graphics.newCanvas(
			width, height,
			{format = "rgba8", readable = true}
		)
		reductionCanvas:setWrap("clampzero")
		reductionCanvas:setFilter("nearest")

		table.insert(self._ReductionCanvases, reductionCanvas)
		
		width = math.floor(width*0.5)
		height = math.floor(height*0.5)
	end

	return self
end

function MotionTracker:Update(frame, immediateBackgroundUpdate)
	love.graphics.push("all")
	love.graphics.reset()

	love.graphics.setCanvas(self._ReductionCanvases[1])
	love.graphics.setShader(Shaders.MotionMask)
	Shaders.MotionMask:send("Background", self._BackgroundCanvas)
	Shaders.MotionMask:send("MotionThreshold", self._MotionThreshold)
	love.graphics.draw(frame)

	love.graphics.setShader(Shaders.Reduction)

	for index = 2, #self._ReductionCanvases, 1 do
		local previousReductionCanvas = self._ReductionCanvases[index - 1]
		
		love.graphics.setCanvas(self._ReductionCanvases[index])
		Shaders.Reduction:send("TexelSize", {
			1/previousReductionCanvas:getWidth(),
			1/previousReductionCanvas:getHeight()
		})
		love.graphics.draw(previousReductionCanvas)
	end

	love.graphics.setCanvas(self._BackgroundCanvas)
	love.graphics.setShader(Shaders.BackgroundAdaption)
	Shaders.BackgroundAdaption:send("PreviousBackground", self._PreviousBackgroundCanvas)
	Shaders.BackgroundAdaption:send("AdaptionRate", immediateBackgroundUpdate and 1 or self._AdaptionRate)
	love.graphics.draw(frame)

	local backgroundCanvas = self._BackgroundCanvas
	self._BackgroundCanvas = self._PreviousBackgroundCanvas
	self._PreviousBackgroundCanvas = backgroundCanvas

	self._MotionShapes = nil

	love.graphics.pop()
end

function MotionTracker:GetDimensions()
	return self._MotionMask:getDimensions()
end

function MotionTracker:GetMotionMask()
	return self._MotionMask
end

function MotionTracker:GetMotionThreshold()
	return self._MotionThreshold
end

function MotionTracker:SetMotionThreshold(threshold)
	self._MotionThreshold = math.clamp(threshold, 0, 1)
end

function MotionTracker:GetShapeMinimumArea()
	return self._ShapeMinimumArea
end

function MotionTracker:SetShapeMinimumArea(area)
	self._ShapeMinimumArea = math.clamp(area, 0, 1)
end

function MotionTracker:GetAdaptionRate()
	return self._AdaptionRate
end

function MotionTracker:SetAdaptionRate(rate)
	self._AdaptionRate = math.clamp(rate, 0, 1)
end

function MotionTracker:GetMotionShapes()
	if not self._MotionShapes then
		local blockGrid = self._ReductionCanvases[#self._ReductionCanvases]:newImageData()
		local width, height = blockGrid:getDimensions()

		local shapes = {}

		local visited = {}
		local toVisit = {}

		local shape = nil

		local motionSum = 0

		for y = 0, height - 1, 1 do
			for x = 0, width - 1, 1 do
				local index = y*height + x
				local motion = blockGrid:getPixel(x, y)
				
				motionSum = motionSum + motion

				if not visited[index] and motion > 0.95 then
					shape = {x, y, x + 1, y + 1}
					table.insert(shapes, shape)

					table.insert(toVisit, x)
					table.insert(toVisit, y)

					visited[index] = true
				end

				while #toVisit > 0 do
					local x2 = table.remove(toVisit, 1)
					local y2 = table.remove(toVisit, 1)

					for subY = -self._NeighbourSearchRadius, self._NeighbourSearchRadius, 1 do
						for subX = -self._NeighbourSearchRadius, self._NeighbourSearchRadius, 1 do
							local x3, y3 = x2 + subX, y2 + subY
							local subIndex = y3*height + x3

							if
								x3 >= 0 and x3 < width and y3 >= 0 and y3 < height and
								not visited[subIndex]
							then
								local subMotion = blockGrid:getPixel(x3, y3)
								
								if subMotion > 0.95 then
									shape[1] = math.min(shape[1], x3)
									shape[2] = math.min(shape[2], y3)
									shape[3] = math.max(shape[3], x3 + 1)
									shape[4] = math.max(shape[4], y3 + 1)

									table.insert(toVisit, x3)
									table.insert(toVisit, y3)

									visited[subIndex] = true
								end
							end
						end
					end
				end
			end
		end

		blockGrid:release()
		
		local largestArea = 0
		local largestShape = 0

		local index = 1
		while index <= #shapes do
			local currentShape = shapes[index]
			local x1, y1, x2, y2 = unpack(currentShape)
			
			x1 = x1/width
			y1 = y1/height
			x2 = x2/width
			y2 = y2/height

			local area = (x2 - x1)*(y2 - y1)

			if area >= self._ShapeMinimumArea then
				if area > largestArea then
					largestArea = area
					largestShape = index
				end

				currentShape[1] = x1
				currentShape[2] = y1
				currentShape[3] = x2
				currentShape[4] = y2

				index = index + 1
			else
				table.remove(shapes, index)
			end
		end

		self._MotionShapes = shapes
		self._LargestMotionShape = largestShape
		self._AverageMotion = motionSum/(width*height)
	end
	
	return self._MotionShapes
end

function MotionTracker:GetLargestMotionShape()
	self:GetMotionShapes()

	return self._LargestMotionShape
end

function MotionTracker:GetAverageMotion()
	self:GetMotionShapes()

	return self._AverageMotion
end

function MotionTracker:Destroy()
	if not self._Destroyed then
		self._BackgroundCanvas:release()
		self._BackgroundCanvas = nil

		self._PreviousBackgroundCanvas:release()
		self._PreviousBackgroundCanvas = nil

		for index = 1, #self._ReductionCanvases, 1 do
			self._ReductionCanvases[index]:release()
		end

		self._ReductionCanvases = nil

		self._MotionShapes = nil

		Entity.Destroy(self)
	end
end

return Class.CreateClass(MotionTracker, "MotionTracker", Entity)