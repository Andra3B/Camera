local MotionTracker = {}

function MotionTracker.Create(width, height, subdivisions)	
	local self = Class.CreateInstance(Entity.Create(), MotionTracker)

	self._BackgroundCanvas = love.graphics.newCanvas(width, height)

	self._FrameHistory = {}
	self._FrameHistoryIndex = 1

	for _ = 1, 5, 1 do
		table.insert(self._FrameHistory, love.graphics.newCanvas(width, height))
	end

	self._ReductionCanvases = {}
	
	self._MotionShapes = nil
	self._AverageMotion = nil
	
	self._MotionThreshold = 0.32
	self._ShapeMinimumArea = 0.08
	self._NeighbourSearchRadius = 5

	local maxSubdivisions = math.ceil(math.log(math.min(width, height))/math.log(2))
	for _ = 0, math.clamp(maxSubdivisions - subdivisions, 1, maxSubdivisions), 1 do
		local reductionCanvas = love.graphics.newCanvas(
			width, height,
			{format = "rgba8", readable = true}
		)
		reductionCanvas:setWrap("clampzero")
		reductionCanvas:setFilter("nearest")

		table.insert(self._ReductionCanvases, reductionCanvas)
		
		width = math.ceil(width*0.5)
		height = math.ceil(height*0.5)
	end

	return self
end

function MotionTracker:Update(frame)
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
	
	self._FrameHistoryIndex = self._FrameHistoryIndex == 5 and 1 or self._FrameHistoryIndex + 1

	love.graphics.setCanvas(self._FrameHistory[self._FrameHistoryIndex])
	love.graphics.setShader()
	love.graphics.draw(frame)

	love.graphics.setCanvas(self._BackgroundCanvas)
	love.graphics.setShader(Shaders.FivePointAverage)
	Shaders.FivePointAverage:send("FrameOne", self._FrameHistory[1])
	Shaders.FivePointAverage:send("FrameTwo", self._FrameHistory[2])
	Shaders.FivePointAverage:send("FrameThree", self._FrameHistory[3])
	Shaders.FivePointAverage:send("FrameFour", self._FrameHistory[4])
	Shaders.FivePointAverage:send("FrameFive", self._FrameHistory[5])
	love.graphics.draw(frame)

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
		
		for index, currentShape in pairs(shapes) do
			local x1, y1, x2, y2 = unpack(currentShape)
			
			x1 = x1/width
			y1 = y1/height
			x2 = x2/width
			y2 = y2/height

			if (x2 - x1)*(y2 - y1) >= self._ShapeMinimumArea then
				currentShape[1] = x1
				currentShape[2] = y1
				currentShape[3] = x2
				currentShape[4] = y2
			else
				table.remove(shapes, index)
			end
		end

		self._MotionShapes = shapes
		self._AverageMotion = motionSum/(width*height)
	end
	
	return self._MotionShapes
end

function MotionTracker:GetAverageMotion()
	self:GetMotionShapes()

	return self._AverageMotion
end

function MotionTracker:Destroy()
	if not self._Destroyed then
		self._BackgroundCanvas:release()
		self._BackgroundCanvas = nil

		for index = 1, #self._ReductionCanvases, 1 do
			self._ReductionCanvases[index]:release()
		end

		for index = 1, #self._FrameHistory, 1 do
			self._FrameHistory[index]:release()
		end

		self._ReductionCanvases = nil
		self._FrameHistory = nil

		self._MotionShapes = nil

		Entity.Destroy(self)
	end
end

return Class.CreateClass(MotionTracker, "MotionTracker", Entity)