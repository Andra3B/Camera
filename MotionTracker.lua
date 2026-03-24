local MotionTracker = {}

function MotionTracker.Create(width, height)	
	local self = Class.CreateInstance(Entity.Create(), MotionTracker)

	self._BackgroundCanvas = love.graphics.newCanvas(width, height)
	self._PreviousBackgroundCanvas = love.graphics.newCanvas(width, height)

	self._ReductionCanvases = {}

	self._MotionShapes = nil
	self._LargestMotionShape = nil
	self._MotionCoverage = 0

	self._MotionThreshold = 0.12
	self._ShapeMinimumArea = 0.03
	self._ShapeSearchRadius = 7
	self._AdaptionRate = 0.1
	
	self._MaxSubdivisions = math.floor(math.log(math.min(width, height))/math.log(2))
	self.Subdivisions = 5

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

	love.graphics.setCanvas(self._BackgroundCanvas)
	love.graphics.setShader(Shaders.BackgroundAdaption)
	Shaders.BackgroundAdaption:send("PreviousBackground", self._PreviousBackgroundCanvas)
	Shaders.BackgroundAdaption:send("AdaptionRate", self._AdaptionRate)
	love.graphics.draw(frame)

	local backgroundCanvas = self._BackgroundCanvas
	self._BackgroundCanvas = self._PreviousBackgroundCanvas
	self._PreviousBackgroundCanvas = backgroundCanvas

	self._MotionShapes = nil
	self._LargestMotionShape = nil

	love.graphics.pop()
end

function MotionTracker:GetBackground()
	return self._BackgroundCanvas
end

function MotionTracker:GetMotionMask()
	return self._ReductionCanvases[#self._ReductionCanvases]
end

function MotionTracker:GetMotionThreshold()
	return self._MotionThreshold
end

function MotionTracker:SetMotionThreshold(threshold)
	threshold = math.clamp(threshold, 0, 1)

	if threshold ~= self._MotionThreshold then
		self._MotionThreshold = threshold
	
		return true, self._MotionThreshold
	end
end

function MotionTracker:GetShapeMinimumArea()
	return self._ShapeMinimumArea
end

function MotionTracker:SetShapeMinimumArea(area)
	area = math.clamp(area, 0, 1)

	if area ~= self._ShapeMinimumArea then
		self._ShapeMinimumArea = area

		return true, self._ShapeMinimumArea
	end
end

function MotionTracker:GetShapeSearchRadius()
	return self._ShapeSearchRadius
end

function MotionTracker:SetShapeSearchRadius(radius)
	radius = math.max(radius, 1)

	if radius ~= self._ShapeSearchRadius then
		self._ShapeSearchRadius = radius
	
		return true, self._ShapeSearchRadius
	end
end

function MotionTracker:GetAdaptionRate()
	return self._AdaptionRate
end

function MotionTracker:SetAdaptionRate(rate)
	rate = math.clamp(rate, 0, 1)

	if rate ~= self._AdaptionRate then
		self._AdaptionRate = rate

		return true, self._AdaptionRate
	end
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
				-- Convert pixel position (x, y) to array index.
				local index = y*height + x
				-- Get pixel value from motion mask.
				local motion = blockGrid:getPixel(x, y)

				motionSum = motionSum + motion

				-- If pixel not visted (not assigned a shape) and is a motion pixel (0.95 for safety).
				if not visited[index] and motion > 0.95 then
					-- Create a new motion shape and add the shape to the list of motion shapes.
					shape = {x, y, x + 1, y + 1}
					table.insert(shapes, shape)

					-- Mark the pixel as a pixel that needs to be visited.
					table.insert(toVisit, x)
					table.insert(toVisit, y)

					-- Mark the pixel as visited so its not processed again.
					visited[index] = true
				end

				-- While there are still pixels to visit.
				while #toVisit > 0 do
					-- Get the next pixel to visit.
					local x2 = table.remove(toVisit, 1)
					local y2 = table.remove(toVisit, 1)

					-- For each neighbour pixel within the shape search radius.
					for subY = -self._ShapeSearchRadius, self._ShapeSearchRadius, 1 do
						for subX = -self._ShapeSearchRadius, self._ShapeSearchRadius, 1 do
							local x3, y3 = x2 + subX, y2 + subY
							local subIndex = y3*height + x3

							-- If neighbour position is within the mask and is not visited.
							if
								x3 >= 0 and x3 < width and y3 >= 0 and y3 < height and
								not visited[subIndex]
							then
								local subMotion = blockGrid:getPixel(x3, y3)
								
								-- Check neighbour is a motion pixel.
								if subMotion > 0.95 then
									-- Update extents of the motion shape to include this neighbour pixel.
									shape[1] = math.min(shape[1], x3)
									shape[2] = math.min(shape[2], y3)
									shape[3] = math.max(shape[3], x3 + 1)
									shape[4] = math.max(shape[4], y3 + 1)

									-- Mark the neighbour as a pixel that needs to be visited.
									table.insert(toVisit, x3)
									table.insert(toVisit, y3)

									-- Mark the neighbour as visited so its not processed again.
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
			local x1, y1, x2, y2 = unpack(shapes[index])
			
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

				shapes[index] = {Vector2.Create(x1, y1), Vector2.Create(x2, y2)}

				index = index + 1
			else
				table.remove(shapes, index)
			end
		end

		self._MotionShapes = shapes
		self._LargestMotionShape = shapes[largestShape]
		self._MotionCoverage = motionSum / (width*height)
	end
	
	return self._MotionShapes
end

function MotionTracker:GetLargestMotionShape()
	self:GetMotionShapes()

	return self._LargestMotionShape
end

function MotionTracker:GetMaxSubdivisions()
	return self._MaxSubdivisions
end

function MotionTracker:GetSubdivisions()
	return self._MaxSubdivisions - #self._ReductionCanvases - 1
end

function MotionTracker:SetSubdivisions(subdivisions)
	subdivisions = math.clamp(subdivisions, 0, self._MaxSubdivisions)

	if subdivisions ~= self.Subdivisions then
		local width, height = self._BackgroundCanvas:getDimensions()

		for _ = 1, #self._ReductionCanvases, 1 do
			table.remove(self._ReductionCanvases):release()
		end

		for _ = 0, self._MaxSubdivisions - subdivisions, 1 do
			local reductionCanvas = love.graphics.newCanvas(width, height, {format = "rgba8"})
			reductionCanvas:setWrap("clampzero")
			reductionCanvas:setFilter("nearest")
			
			table.insert(self._ReductionCanvases, reductionCanvas)

			width, height = math.floor(width*0.5), math.floor(height*0.5)
		end
	end
end

function MotionTracker:GetMotionCoverage()
	self:GetMotionShapes()

	return self._MotionCoverage
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
		self._LargestMotionShape = nil

		Entity.Destroy(self)
	end
end

return Class.CreateClass(MotionTracker, "MotionTracker", Entity)