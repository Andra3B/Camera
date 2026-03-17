local Frame = {}

Enum.Axis = Enum.Create({
	None = 1,
	X = 2,
	Y = 3
})

Enum.ScaleMode = Enum.Create({
	Stretch = 1,
	MaintainAspectRatio = 2
})

function Frame.Create(frame)
	local self = Class.CreateInstance(Object.Create(frame), Frame)

	self._RelativePosition = Vector2.Zero
	self._PixelPosition = Vector2.Zero
	self._AbsolutePosition = Vector2.Zero
	
	self._RelativeSize = Vector2.Zero
	self._PixelSize = Vector2.Zero
	self._AbsoluteSize = Vector2.Zero

	self._RelativeOrigin = Vector2.Zero
	self._PixelOrigin = Vector2.Zero

	self._ChildPixelOffset = Vector2.Zero
	self._ChildRelativeOffset = Vector2.Zero
	self._ChildAbsoluteOffset = Vector2.Zero

	self._BackgroundColour = Vector4.One
	self._BackgroundImage = nil
	self._BackgroundImageScale = 1
	self._BackgroundImageScaleMode = Enum.ScaleMode.Stretch

	self._BackgroundImageAbsolutePosition = Vector2.Zero
	self._BackgroundImageAbsoluteSize = Vector2.Zero

	self._ChildrenAbsolutePosition = Vector2.Zero
	self._ChildrenAbsoluteSize = Vector2.Zero

	self._BorderColour = Vector4.Create(0, 0, 0, 1)
	self._BorderThickness = 0

	self._CornerRelativeRadius = 0
	self._CornerPixelRadius = 0
	self._CornerAbsoluteRadius = 0

	self._AspectRatio = 1
	self._DominantAxis = Enum.Axis.None

	self._Visible = true

	self._Events:Listen("ParentChanged", Frame.RefreshAbsolutePosition)
	self._Events:Listen("ParentAbsolutePositionChanged", Frame.RefreshAbsolutePosition)
	self._Events:Listen("ParentAbsoluteSizeChanged", Frame.RefreshAbsolutePosition)
	self._Events:Listen("ParentChildAbsoluteOffsetChanged", Frame.RefreshAbsolutePosition)
	self._Events:Listen("AbsoluteSizeChanged", Frame.RefreshAbsolutePosition)
	self._Events:Listen("RelativePositionChanged", Frame.RefreshAbsolutePosition)
	self._Events:Listen("PixelPositionChanged", Frame.RefreshAbsolutePosition)
	self._Events:Listen("RelativeOriginChanged", Frame.RefreshAbsolutePosition)
	self._Events:Listen("PixelOriginChanged", Frame.RefreshAbsolutePosition)

	self._Events:Listen("ParentChanged", Frame.RefreshAbsoluteSize)
	self._Events:Listen("ParentAbsoluteSizeChanged", Frame.RefreshAbsoluteSize)
	self._Events:Listen("RelativeSizeChanged", Frame.RefreshAbsoluteSize)
	self._Events:Listen("PixelSizeChanged", Frame.RefreshAbsoluteSize)
	self._Events:Listen("DominantAxisChanged", Frame.RefreshAbsoluteSize)
	self._Events:Listen("AspectRatioChanged", Frame.RefreshAbsoluteSize)

	self._Events:Listen("ChildRelativeOffsetChanged", Frame.RefreshChildAbsoluteOffset)
	self._Events:Listen("ChildPixelOffsetChanged", Frame.RefreshChildAbsoluteOffset)
	self._Events:Listen("AbsoluteSizeChanged", Frame.RefreshChildAbsoluteOffset)

	self._Events:Listen("BackgroundImageChanged", Frame.RefreshBackgroundImageAbsoluteValues)
	self._Events:Listen("BackgroundImageScaleModeChanged", Frame.RefreshBackgroundImageAbsoluteValues)
	self._Events:Listen("BackgroundImageScaleChanged", Frame.RefreshBackgroundImageAbsoluteValues)
	self._Events:Listen("AbsolutePositionChanged", Frame.RefreshBackgroundImageAbsoluteValues)
	self._Events:Listen("AbsoluteSizeChanged", Frame.RefreshBackgroundImageAbsoluteValues)

	self._Events:Listen("ChildParentChanged", Frame.RefreshChildrenAbsoluteValues)
	self._Events:Listen("ChildAbsoluteOffsetChanged", Frame.RefreshChildrenAbsoluteValues)
	self._Events:Listen("AbsolutePositionChanged", Frame.RefreshChildrenAbsoluteValues)
	self._Events:Listen("ChildAbsolutePositionChanged", Frame.RefreshChildrenAbsoluteValues)
	self._Events:Listen("ChildAbsoluteSizeChanged", Frame.RefreshChildrenAbsoluteValues)

	self._Events:Listen("CornerRelativeRadiusChanged", Frame.RefreshCornerAbsoluteRadius)
	self._Events:Listen("CornerPixelRadiusChanged", Frame.RefreshCornerAbsoluteRadius)
	self._Events:Listen("AbsoluteSizeChanged", Frame.RefreshCornerAbsoluteRadius)

	if frame then
		self.RelativePosition = frame.RelativePosition
		self.PixelPosition = frame.PixelPosition

		self.RelativeSize = frame.RelativeSize
		self.PixelSize = frame.PixelSize

		self.RelativeOrigin = frame.RelativeOrigin
		self.PixelOrigin = frame.PixelOrigin

		self.ChildPixelOffset = frame.ChildPixelOffset
		self.ChildRelativeOffset = frame.ChildRelativeOffset

		self.BackgroundColour = frame.BackgroundColour
		self.BackgroundImage = frame.BackgroundImage
		self.BackgroundImageScale = frame.BackgroundImageScale
		self.BackgroundImageScaleMode = frame.BackgroundImageScaleMode

		self.BorderColour = frame.BorderColour
		self.BorderThickness = frame.BorderThickness

		self.CornerRelativeRadius = frame.CornerRelativeRadius
		self.CornerPixelRadius = frame.CornerPixelRadius
		self.CornerAbsoluteRadius = frame.CornerAbsoluteRadius

		self.AspectRatio = frame.AspectRatio
		self.DominantAxis = frame.DominantAxis

		self.Visible = frame.Visible

		self:Refresh()
	end

	return self
end

function Frame:Refresh()
	Object.Refresh()

	self._AbsoluteSize = nil
	self:RefreshAbsoluteSize()
end

function Frame:RefreshAbsolutePosition()
	local parentAbsolutePosition = nil
	local parentAbsoluteSize = nil
	local parentChildAbsoluteOffset = nil
	local parent = self._Parent

	if parent then
		parentAbsolutePosition = parent._AbsolutePosition
		parentAbsoluteSize = parent._AbsoluteSize
		parentChildAbsoluteOffset = parent._ChildAbsoluteOffset
	else
		parentAbsolutePosition = Vector2.Zero
		parentAbsoluteSize = Vector2.Create(love.graphics.getDimensions())
		parentChildAbsoluteOffset = Vector2.Zero
	end

	self.AbsolutePosition =
		parentAbsolutePosition +
		parentChildAbsoluteOffset +
		self._PixelPosition +
		parentAbsoluteSize*self._RelativePosition -
		self._AbsoluteSize*self._RelativeOrigin -
		self._PixelOrigin
end

function Frame:RefreshAbsoluteSize()
	local parent = self._Parent

	local absoluteSize = self._PixelSize +
		(parent and parent._AbsoluteSize or Vector2.Create(love.graphics.getDimensions()))*self._RelativeSize

	if self._DominantAxis == Enum.Axis.X then
		absoluteSize.Y = absoluteSize.X/self._AspectRatio
	elseif self._DominantAxis == Enum.Axis.Y then
		absoluteSize.X = absoluteSize.Y*self._AspectRatio
	end

	self.AbsoluteSize = absoluteSize
end

function Frame:RefreshChildAbsoluteOffset()
	self.ChildAbsoluteOffset = self._ChildPixelOffset + self._AbsoluteSize*self._ChildRelativeOffset
end

function Frame:RefreshBackgroundImageAbsoluteValues()
	local backgroundImage = self.BackgroundImage

	if backgroundImage then
		local absolutePosition = self._AbsolutePosition
		local absoluteSize = self._AbsoluteSize

		local backgroundImageAbsolutePosition = absolutePosition
		local backgroundImageAbsoluteSize = absoluteSize

		if self._BackgroundImageScaleMode == Enum.ScaleMode.MaintainAspectRatio then
			local width, height = backgroundImage:getDimensions()
			local scaleFactor = math.min(absoluteSize.X/width, absoluteSize.Y/height)

			backgroundImageAbsoluteSize = Vector2.Create(width*scaleFactor, height*scaleFactor)
			backgroundImageAbsolutePosition = absolutePosition + (absoluteSize - backgroundImageAbsoluteSize)*0.5
		end

		self.BackgroundImageAbsoluteSize = backgroundImageAbsoluteSize*self._BackgroundImageScale
		self.BackgroundImageAbsolutePosition = backgroundImageAbsolutePosition + backgroundImageAbsoluteSize*((1 - self._BackgroundImageScale)*0.5)
	else
		self.BackgroundImageAbsoluteSize = Vector2.Zero
		self.BackgroundImageAbsolutePosition = Vector2.Zero
	end
end

function Frame:RefreshChildrenAbsoluteValues()
	if #self._Children > 0 then
		local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge

		for _, child in pairs(self._Children) do
			local absolutePosition = child._AbsolutePosition - self._ChildAbsoluteOffset - self._AbsolutePosition
			local x1, y1 = absolutePosition:Unpack()
			local x2, y2 = (absolutePosition + child._AbsoluteSize):Unpack()

			minX = math.min(minX, x1)
			minY = math.min(minY, y1)
			maxX = math.max(maxX, x2)
			maxY = math.max(maxY, y2)
		end

		self.ChildrenAbsolutePosition = Vector2.Create(minX, minY)
		self.ChildrenAbsoluteSize = Vector2.Create(maxX - minX, maxY - minY)
	else
		self.ChildrenAbsolutePosition = Vector2.Zero
		self.ChildrenAbsoluteSize = Vector2.Zero
	end
end

function Frame:RefreshCornerAbsoluteRadius()
	self.CornerAbsoluteRadius = self._CornerPixelRadius + math.min(self.AbsoluteSize:Unpack())*self._CornerRelativeRadius*0.5
end

function Frame:Draw()
	local absolutePosition = self._AbsolutePosition
	local absoluteSize = self._AbsoluteSize
	local cornerAbsoluteRadius = self._CornerAbsoluteRadius

	local backgroundImage = self.BackgroundImage

	love.graphics.setColor(self.BackgroundColour:Unpack())
	love.graphics.rectangle(
		"fill",
		absolutePosition.X, absolutePosition.Y,
		absoluteSize.X, absoluteSize.Y,
		cornerAbsoluteRadius, cornerAbsoluteRadius
	)
	
	if backgroundImage then
		local width, height = backgroundImage:getDimensions()
		
		local backgroundImageAbsolutePosition = self._BackgroundImageAbsolutePosition
		local backgroundImageAbsoluteSize = self._BackgroundImageAbsoluteSize
		
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.draw(
			backgroundImage,
			backgroundImageAbsolutePosition.X, backgroundImageAbsolutePosition.Y,
			0,
			backgroundImageAbsoluteSize.X/width, backgroundImageAbsoluteSize.Y/height
		)
	end
end

function Frame:PostDraw()
end

function Frame:PostDescendantDraw()
	local absolutePosition = self._AbsolutePosition
	local absoluteSize = self._AbsoluteSize
	local cornerAbsoluteRadius = self._CornerAbsoluteRadius
	
	love.graphics.setScissor()

	local thickness = self.BorderThickness
	if thickness > 0 then
		local halfThickness = thickness*0.5

		love.graphics.setColor(self.BorderColour:Unpack())
		love.graphics.setLineWidth(thickness)
		love.graphics.rectangle(
			"line",
			absolutePosition.X - halfThickness, absolutePosition.Y - halfThickness,
			absoluteSize.X + thickness - 1, absoluteSize.Y + thickness,
			cornerAbsoluteRadius + halfThickness, cornerAbsoluteRadius + halfThickness
		)
	end
end

function Frame:RecursiveDraw()
	if self._Visible then
		local scissorTopLeftX, scissorTopLeftY, scissorWidth, scissorHeight = love.graphics.getScissor()
		
		if not scissorTopLeftX then
			scissorTopLeftX, scissorTopLeftY, scissorWidth, scissorHeight = 0, 0, love.graphics.getDimensions()
		end

		local scissorBottomRightX, scissorBottomRightY = scissorTopLeftX + scissorWidth, scissorTopLeftY + scissorHeight

		local newScissorTopLeft = self.AbsolutePosition
		local newScissorBottomRight = self.AbsolutePosition + self.AbsoluteSize
		
		if not (
			newScissorBottomRight.X < scissorTopLeftX or
			newScissorTopLeft.X > scissorBottomRightX or
			newScissorBottomRight.Y < scissorTopLeftY or
			newScissorTopLeft.Y > scissorBottomRightY
		) then
			love.graphics.push("all")

			local finalScissorTopLeftX = math.max(newScissorTopLeft.X, scissorTopLeftX)
			local finalScissorTopLeftY = math.max(newScissorTopLeft.Y, scissorTopLeftY)

			love.graphics.setScissor(
				finalScissorTopLeftX,
				finalScissorTopLeftY,
				math.min(newScissorBottomRight.X, scissorBottomRightX) - finalScissorTopLeftX,
				math.min(newScissorBottomRight.Y, scissorBottomRightY) - finalScissorTopLeftY
			)

			love.graphics.push("all")
			self:Draw()
			love.graphics.pop()
			love.graphics.push("all")
			self:PostDraw()
			love.graphics.pop()

			for _, child in ipairs(self:GetChildren()) do
				if Class.IsA(child, "Frame") then
					child:RecursiveDraw()
				end
			end

			self:PostDescendantDraw()

			love.graphics.pop()
		end
	end
end

function Frame:GetRelativePosition()
	return self._RelativePosition
end

function Frame:SetRelativePosition(position)
	if position ~= self._RelativePosition then
		self._RelativePosition = position

		return true, position
	end
end

function Frame:GetPixelPosition()
	return self._PixelPosition
end

function Frame:SetPixelPosition(position)
	if position ~= self._PixelPosition then
		self._PixelPosition = position

		return true, position
	end
end

function Frame:GetAbsolutePosition()
	return self._AbsolutePosition
end

function Frame:SetAbsolutePosition(position)
	if position ~= self._AbsolutePosition then
		self._AbsolutePosition = position

		return true, position
	end
end

function Frame:GetRelativeSize()
	return self._RelativeSize
end

function Frame:SetRelativeSize(size)
	if size ~= self._RelativeSize then
		self._RelativeSize = size

		return true, size
	end
end

function Frame:GetPixelSize()
	return self._PixelSize
end

function Frame:SetPixelSize(size)
	if size ~= self._PixelSize then
		self._PixelSize = size

		return true, size
	end
end

function Frame:GetAbsoluteSize()
	return self._AbsoluteSize
end

function Frame:SetAbsoluteSize(size)
	if size ~= self._AbsoluteSize then
		self._AbsoluteSize = size

		return true, size
	end
end

function Frame:GetRelativeOrigin()
	return self._RelativeOrigin
end

function Frame:SetRelativeOrigin(origin)
	if origin ~= self._RelativeOrigin then
		self._RelativeOrigin = origin

		return true, origin
	end
end

function Frame:GetPixelOrigin()
	return self._PixelOrigin
end

function Frame:SetPixelOrigin(origin)
	if origin ~= self._PixelOrigin then
		self._PixelOrigin = origin

		return true, origin
	end
end

function Frame:GetChildPixelOffset()
	return self._ChildPixelOffset
end

function Frame:SetChildPixelOffset(offset)
	if offset ~= self._ChildPixelOffset then
		self._ChildPixelOffset = offset

		return true, offset
	end
end

function Frame:GetChildRelativeOffset()
	return self._ChildRelativeOffset
end

function Frame:SetChildRelativeOffset(offset)
	if offset ~= self._ChildRelativeOffset then
		self._ChildRelativeOffset = offset

		return true, offset
	end
end

function Frame:GetChildAbsoluteOffset()
	return self._ChildAbsoluteOffset
end

function Frame:SetChildAbsoluteOffset(offset)
	if offset ~= self._ChildAbsoluteOffset then
		self._ChildAbsoluteOffset = offset

		return true, offset
	end
end

function Frame:GetBackgroundColour()
	return self._BackgroundColour
end

function Frame:SetBackgroundColour(colour)
	if colour ~= self._BackgroundColour then
		self._BackgroundColour = colour

		return true, colour
	end
end

function Frame:GetBackgroundImage()
	return self._BackgroundImage
end

function Frame:SetBackgroundImage(image)
	if image ~= self._BackgroundImage then
		self._BackgroundImage = image

		return true, image
	end
end

function Frame:GetBackgroundImageScaleMode()
	return self._BackgroundImageScaleMode
end

function Frame:SetBackgroundImageScaleMode(mode)
	if mode ~= self._BackgroundImageScaleMode then
		self._BackgroundImageScaleMode = mode

		return true, mode
	end
end

function Frame:GetBackgroundImageScale()
	return self._BackgroundImageScale
end

function Frame:SetBackgroundImageScale(scale)
	scale = math.max(0, scale)

	if scale ~= self._BackgroundImageScale then
		self._BackgroundImageScale = scale

		return true, scale
	end
end

function Frame:GetBackgroundImageAbsolutePosition()
	return self._BackgroundImageAbsolutePosition
end

function Frame:SetBackgroundImageAbsolutePosition(position)
	if position ~= self._BackgroundImageAbsolutePosition then
		self._BackgroundImageAbsolutePosition = position

		return true, position
	end
end

function Frame:GetBackgroundImageAbsoluteSize()
	return self._BackgroundImageAbsoluteSize
end

function Frame:SetBackgroundImageAbsoluteSize(size)
	if size ~= self._BackgroundImageAbsoluteSize then
		self._BackgroundImageAbsoluteSize = size

		return true, size
	end
end

function Frame:GetChildrenAbsolutePosition()
	return self._ChildrenAbsolutePosition
end

function Frame:SetChildrenAbsolutePosition(position)
	if position ~= self._ChildrenAbsolutePosition then
		self._ChildrenAbsolutePosition = position

		return true, position
	end
end

function Frame:GetChildrenAbsoluteSize()
	return self._ChildrenAbsoluteSize
end

function Frame:SetChildrenAbsoluteSize(size)
	if size ~= self._ChildrenAbsoluteSize then
		self._ChildrenAbsoluteSize = size

		return true, size
	end
end

function Frame:GetBorderColour()
	return self._BorderColour
end

function Frame:SetBorderColour(colour)
	if colour ~= self._BorderColour then
		self._BorderColour = colour

		return true, colour
	end
end

function Frame:GetBorderThickness()
	return self._BorderThickness
end

function Frame:SetBorderThickness(thickness)
	if thickness ~= self._BorderThickness then
		self._BorderThickness = thickness

		return true, thickness
	end
end

function Frame:GetCornerRelativeRadius()
	return self._CornerRelativeRadius
end

function Frame:SetCornerRelativeRadius(radius)
	if radius ~= self._CornerRelativeRadius then
		self._CornerRelativeRadius = radius

		return true, radius
	end
end

function Frame:GetCornerPixelRadius()
	return self._CornerPixelRadius
end

function Frame:SetCornerPixelRadius(radius)
	if radius ~= self._CornerPixelRadius then
		self._CornerPixelRadius = radius

		return true, radius
	end
end

function Frame:GetCornerAbsoluteRadius()
	return self._CornerAbsoluteRadius
end

function Frame:SetCornerAbsoluteRadius(radius)
	if radius ~= self._CornerAbsoluteRadius then
		self._CornerAbsoluteRadius = radius

		return true, radius
	end
end

function Frame:GetAspectRatio()
	return self._AspectRatio
end

function Frame:SetAspectRatio(ratio)
	if ratio ~= self._AspectRatio then
		self._AspectRatio = ratio

		return true, ratio
	end
end

function Frame:GetDominantAxis()
	return self._DominantAxis
end

function Frame:SetDominantAxis(axis)
	if axis ~= self._DominantAxis then
		self._DominantAxis = axis

		return true, axis
	end
end

function Frame:IsVisible()
	return self._Visible
end

function Frame:SetVisible(visible)
	if visible ~= self._Visible then
		self._Visible = visible

		return true, visible
	end
end

function Frame:Destroy()
	if not self._Destroyed then
		self._RelativePosition = nil
		self._PixelPosition = nil
		self._AbsolutePosition = nil

		self._RelativeSize = nil
		self._PixelSize = nil
		self._AbsoluteSize = nil

		self._ChildPixelOffset = nil
		self._ChildRelativeOffset = nil
		self._ChildAbsoluteOffset = nil

		self._BackgroundColour = nil
		self._BackgroundImage = nil

		self._BackgroundImageAbsolutePosition = nil
		self._BackgroundImageAbsoluteSize = nil

		self._ChildrenAbsolutePosition = nil
		self._ChildrenAbsoluteSize = nil

		self._BorderColour = nil

		Object.Destroy(self)
	end
end

return Class.CreateClass(Frame, "Frame", Object)