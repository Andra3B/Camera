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

function Frame.Create()
	local self = Class.CreateInstance(Object.Create(), Frame)

	self._RelativePosition = Vector2.Zero
	self._PixelPosition = Vector2.Zero
	self._AbsolutePosition = nil
	
	self._RelativeSize = Vector2.Zero
	self._PixelSize = Vector2.Zero
	self._AbsoluteSize = nil

	self._RelativeOrigin = Vector2.Zero
	self._PixelOrigin = Vector2.Zero

	self._ChildPixelOffset = Vector2.Zero
	self._ChildRelativeOffset = Vector2.Zero
	self._ChildAbsoluteOffset = nil

	self._BackgroundColour = Vector4.One
	self._BackgroundImage = nil
	self._BackgroundImageScaleMode = Enum.ScaleMode.Stretch

	self._BackgroundImageAbsolutePosition = nil
	self._BackgroundImageAbsoluteSize = nil

	self._ChildAbsolutePosition = nil
	self._ChildAbsoluteSize = nil

	self._BorderColour = Vector4.Create(0, 0, 0, 1)
	self._BorderThickness = 0

	self._CornerRelativeRadius = 0
	self._CornerPixelRadius = 0
	self._CornerAbsoluteRadius = nil

	self._AspectRatio = 1
	self._DominantAxis = Enum.Axis.None

	self._Visible = true

	return self
end

function Frame:Refresh()
	Object.Refresh(self)

	self._AbsolutePosition = nil
	self._AbsoluteSize = nil
	self._ChildAbsoluteOffset = nil
	self._CornerAbsoluteRadius = nil
	self._BackgroundImageAbsolutePosition = nil
	self._BackgroundImageAbsoluteSize = nil
	self._ChildAbsolutePosition = nil
	self._ChildAbsoluteSize = nil
end

function Frame:Draw()
	local absolutePosition = self.AbsolutePosition
	local absoluteSize = self.AbsoluteSize
	local backgroundImage = self.BackgroundImage
	local cornerAbsoluteRadius = self.CornerAbsoluteRadius

	love.graphics.setColor(self.BackgroundColour:Unpack())
	love.graphics.rectangle(
		"fill",
		absolutePosition.X, absolutePosition.Y,
		absoluteSize.X, absoluteSize.Y,
		cornerAbsoluteRadius, cornerAbsoluteRadius
	)
	
	if backgroundImage then
		local width, height = backgroundImage:getDimensions()
		
		local backgroundImageAbsolutePosition = self.BackgroundImageAbsolutePosition
		local backgroundImageAbsoluteSize = self.BackgroundImageAbsoluteSize
		local scaleFactorX, scaleFactorY = self.BackgroundImageAbsoluteSize.X/width, self.BackgroundImageAbsoluteSize.Y/height
		
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.draw(
			backgroundImage,
			backgroundImageAbsolutePosition.X, backgroundImageAbsolutePosition.Y,
			0,
			scaleFactorX, scaleFactorY
		)
	end
end

function Frame:PostDraw()
end

function Frame:PostDescendantDraw()
	local absolutePosition = self.AbsolutePosition
	local absoluteSize = self.AbsoluteSize
	local cornerAbsoluteRadius = self.CornerAbsoluteRadius
	
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

function Frame:AddChild(child, where)
	if Object.AddChild(self, child, where) then
		self._ChildAbsolutePosition = nil
		self._ChildAbsoluteSize = nil

		return true
	end

	return false
end

function Frame:GetRelativePosition()
	return self._RelativePosition
end

function Frame:SetRelativePosition(position)
	if self._RelativePosition ~= position then
		self._RelativePosition = position

		self:RecursiveRefresh(true)
	end
end

function Frame:GetPixelPosition()
	return self._PixelPosition
end

function Frame:SetPixelPosition(position)
	if self._PixelPosition ~= position then
		self._PixelPosition = position

		self:RecursiveRefresh(true)
	end
end

function Frame:GetAbsolutePosition()
	if not self._AbsolutePosition then
		local parentAbsolutePosition = nil
		local parentAbsoluteSize = nil
		local parentChildAbsoluteOffset = nil
		local parent = self._Parent

		if parent then
			parentAbsolutePosition = parent.AbsolutePosition
			parentAbsoluteSize = parent.AbsoluteSize
			parentChildAbsoluteOffset = parent.ChildAbsoluteOffset
		else
			parentAbsolutePosition = Vector2.Zero
			parentAbsoluteSize = Vector2.Create(love.graphics.getDimensions())
			parentChildAbsoluteOffset = Vector2.Zero
		end

		self._AbsolutePosition =
			parentAbsolutePosition +
			parentChildAbsoluteOffset +
			self._PixelPosition +
			parentAbsoluteSize*self._RelativePosition -
			self.AbsoluteSize*self._RelativeOrigin -
			self._PixelOrigin
	end

	return self._AbsolutePosition
end

function Frame:GetRelativeSize()
	return self._RelativeSize
end

function Frame:SetRelativeSize(size)
	if self._RelativeSize ~= size then
		self._RelativeSize = size

		self:RecursiveRefresh(true)
	end
end

function Frame:GetPixelSize()
	return self._PixelSize
end

function Frame:SetPixelSize(size)
	if self._PixelSize ~= size then
		self._PixelSize = size

		self:RecursiveRefresh(true)
	end
end

function Frame:GetAbsoluteSize()
	if not self._AbsoluteSize then
		local parent = self._Parent

		self._AbsoluteSize = self._PixelSize +
			(parent and parent.AbsoluteSize or Vector2.Create(love.graphics.getDimensions()))*self._RelativeSize

		if self._DominantAxis == Enum.Axis.X then
			self._AbsoluteSize.Y = self._AbsoluteSize.X/self._AspectRatio
		elseif self._DominantAxis == Enum.Axis.Y then
			self._AbsoluteSize.X = self._AbsoluteSize.Y*self._AspectRatio
		end
	end

	return self._AbsoluteSize
end

function Frame:GetRelativeOrigin()
	return self._RelativeOrigin
end

function Frame:SetRelativeOrigin(origin)
	self._RelativeOrigin = origin
end

function Frame:GetPixelOrigin()
	return self._PixelOrigin
end

function Frame:SetPixelOrigin(origin)
	self._PixelOrigin = origin
end

function Frame:GetChildPixelOffset()
	return self._ChildPixelOffset
end

function Frame:SetChildPixelOffset(offset)
	if self._ChildPixelOffset ~= offset then
		self._ChildPixelOffset = offset

		self:RecursiveRefresh(false)
	end
end

function Frame:GetChildRelativeOffset()
	return self._ChildRelativeOffset
end

function Frame:SetChildRelativeOffset(offset)
	if self._ChildRelativeOffset ~= offset then
		self._ChildRelativeOffset = offset

		self:RecursiveRefresh(false)
	end
end

function Frame:GetChildAbsoluteOffset()
	if not self._ChildAbsoluteOffset then
		self._ChildAbsoluteOffset = self._ChildPixelOffset + self.AbsoluteSize*self._ChildRelativeOffset
	end

	return self._ChildAbsoluteOffset
end

function Frame:GetBackgroundColour()
	return self._BackgroundColour
end

function Frame:SetBackgroundColour(colour)
	self._BackgroundColour = colour
end

function Frame:GetBackgroundImage()
	return self._BackgroundImage
end

function Frame:SetBackgroundImage(image)
	self._BackgroundImage = image
end

function Frame:GetBackgroundImageScaleMode()
	return self._BackgroundImageScaleMode
end

function Frame:SetBackgroundImageScaleMode(mode)
	self._BackgroundImageScaleMode = mode
end

function Frame:GetBackgroundImageAbsolutePosition()
	local backgroundImage = self.BackgroundImage

	if not self._BackgroundImageAbsolutePosition and backgroundImage then
		local absolutePosition = self.AbsolutePosition
		local absoluteSize = self.AbsoluteSize

		if self._BackgroundImageScaleMode == Enum.ScaleMode.Stretch then
			self._BackgroundImageAbsolutePosition = absolutePosition
			self._BackgroundImageAbsoluteSize = absoluteSize
		else
			local width, height = backgroundImage:getDimensions()
			local scaleFactor = math.min(absoluteSize.X / width, absoluteSize.Y / height)

			self._BackgroundImageAbsoluteSize = Vector2.Create(scaleFactor*width, scaleFactor*height)
			self._BackgroundImageAbsolutePosition = absolutePosition + (absoluteSize - self._BackgroundImageAbsoluteSize)*0.5
		end
	end

	return self._BackgroundImageAbsolutePosition
end

function Frame:GetBackgroundImageAbsoluteSize()
	self:GetBackgroundImageAbsolutePosition()

	return self._BackgroundImageAbsoluteSize
end

function Frame:GetChildAbsolutePosition()
	if not self._ChildAbsolutePosition then
		if #self._Children > 0 then
			local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge

			for _, child in pairs(self._Children) do
				local absolutePosition = child.AbsolutePosition - self.ChildAbsoluteOffset - self.AbsolutePosition
				local x1, y1 = absolutePosition:Unpack()
				local x2, y2 = (absolutePosition + child.AbsoluteSize):Unpack()

				minX = math.min(minX, x1)
				minY = math.min(minY, y1)
				maxX = math.max(maxX, x2)
				maxY = math.max(maxY, y2)
			end

			self._ChildAbsolutePosition = Vector2.Create(minX, minY)
			self._ChildAbsoluteSize = Vector2.Create(maxX - minX, maxY - minY)
		else
			self._ChildAbsolutePosition = Vector2.Zero
			self._ChildAbsoluteSize = Vector2.Zero
		end
	end

	return self._ChildAbsolutePosition
end

function Frame:GetChildAbsoluteSize()
	self:GetChildAbsolutePosition()

	return self._ChildAbsoluteSize
end

function Frame:GetBorderColour()
	return self._BorderColour
end

function Frame:SetBorderColour(colour)
	self._BorderColour = colour
end

function Frame:GetBorderThickness()
	return self._BorderThickness
end

function Frame:SetBorderThickness(thickness)
	self._BorderThickness = thickness
end

function Frame:GetCornerRelativeRadius()
	return self._CornerRelativeRadius
end

function Frame:SetCornerRelativeRadius(radius)
	self._CornerRelativeRadius = radius
end

function Frame:GetCornerPixelRadius()
	return self._CornerPixelRadius
end

function Frame:SetCornerPixelRadius(radius)
	self._CornerPixelRadius = radius
end

function Frame:GetCornerAbsoluteRadius()
	if not self._CornerAbsoluteRadius then
		self._CornerAbsoluteRadius =
			self._CornerPixelRadius + math.min(self.AbsoluteSize:Unpack())*0.5*self._CornerRelativeRadius
	end

	return self._CornerAbsoluteRadius
end

function Frame:GetAspectRatio()
	return self._AspectRatio
end

function Frame:SetAspectRatio(ratio)
	self._AspectRatio = ratio
end

function Frame:GetDominantAxis()
	return self._DominantAxis
end

function Frame:SetDominantAxis(axis)
	self._DominantAxis = axis
end

function Frame:IsVisible()
	return self._Visible
end

function Frame:SetVisible(visible)
	self._Visible = visible
end

function Frame:Destroy()
	if not self._Destroyed then
		self._RelativePosition = nil
		self._PixelPosition = nil

		self._RelativeSize = nil
		self._PixelSize = nil

		self._AbsolutePosition = nil
		self._AbsoluteSize = nil

		self._ChildPixelOffset = nil
		self._ChildRelativeOffset = nil

		self._ChildAbsoluteOffset = nil

		self._BackgroundColour = nil
		self._BackgroundImage = nil

		self._BackgroundImageAbsolutePosition = nil
		self._BackgroundImageAbsoluteSize = nil

		self._ChildAbsolutePosition = nil
		self._ChildAbsoluteSize = nil

		self._BorderColour = nil

		Object.Destroy(self)
	end
end

return Class.CreateClass(Frame, "Frame", Object, {
	["ChildAbsoluteOffset"] = {"ChildRelativeOffset", "ChildPixelOffset"},
	["CornerAbsoluteRadius"] = {"CornerRelativeRadius", "CornerPixelRadius"},
	["BackgroundImageAbsolutePosition"] = {"BackgroundImage"},
	["BackgroundImageAbsoluteSize"] = {"BackgroundImageAbsolutePosition"}
})