local Hierarchy = require("UserInterface.Hierarchy")

local Frame = {}

function Frame.Create()
	local self = Class.CreateInstance(Hierarchy.Create(), Frame)

	self._RelativePosition = Vector2.Zero
	self._PixelPosition = Vector2.Zero
	self._AbsolutePosition = Vector2.Zero
	
	self._RelativeSize = Vector2.Zero
	self._PixelSize = Vector2.Zero
	self._AbsoluteSize = Vector2.Zero

	self._ChildTopLeftBoundingCorner = Vector2.Zero
	self._ChildBottomRightBoundingCorner = Vector2.Zero

	self._BackgroundColour = Vector4.One
	self._BackgroundImage = nil

	self._CornerRadius = 0

	self._Visible = true

	return self
end

function Frame:Draw()
	local absolutePosition = self._AbsolutePosition
	local absoluteSize = self._AbsoluteSize
	local backgroundImage = self:GetBackgroundImage()
	local cornerRadius = self:GetCornerRadius()

	love.graphics.setColor(self:GetBackgroundColour():Unpack())
	love.graphics.rectangle(
		"fill",
		absolutePosition.X, absolutePosition.Y,
		absoluteSize.X, absoluteSize.Y,
		cornerRadius, cornerRadius
	)

	if backgroundImage then
		local width, height = backgroundImage:getDimensions()
		
		local scissorTopLeftX, scissorTopLeftY, scissorWidth, scissorHeight = love.graphics.getScissor()
		love.graphics.setScissor() -- TODO: Find fix to still have scissor enabled but images dont glitch at edges

		love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
		love.graphics.draw(
			backgroundImage,
			absolutePosition.X, absolutePosition.Y,
			0,
			absoluteSize.X / width, absoluteSize.Y / height,
			0, 0,
			0, 0
		)

		love.graphics.setScissor(scissorTopLeftX, scissorTopLeftY, scissorWidth, scissorHeight)
	end
end

function Frame:RecursiveDraw()
	if self:IsVisible() then
		local scissorTopLeftX, scissorTopLeftY, scissorWidth, scissorHeight = love.graphics.getScissor()
		
		if not scissorTopLeftX then
			scissorTopLeftX, scissorTopLeftY, scissorWidth, scissorHeight = 0, 0, love.graphics.getDimensions()
		end

		local scissorBottomRightX, scissorBottomRightY = scissorTopLeftX + scissorWidth, scissorTopLeftY + scissorHeight

		local newScissorTopLeft = self._AbsolutePosition
		local newScissorBottomRight = self._AbsolutePosition + self._AbsoluteSize

		if not (
			newScissorBottomRight.X < scissorTopLeftX or
			newScissorTopLeft.X > scissorBottomRightX or
			newScissorBottomRight.Y < scissorTopLeftY or
			newScissorTopLeft.Y > scissorBottomRightY
		) then
			love.graphics.push("all")

			love.graphics.setScissor(
				math.max(newScissorTopLeft.X, scissorTopLeftX),
				math.max(newScissorTopLeft.Y, scissorTopLeftY),
				math.min(newScissorBottomRight.X - newScissorTopLeft.X, scissorWidth),
				math.min(newScissorBottomRight.Y - newScissorTopLeft.Y, scissorHeight)
			)

			love.graphics.push("all")

			self:Draw()

			local children = self:GetChildren()
			for _, child in ipairs(children) do
				if Class.IsA(child, "Frame") then
					love.graphics.push("all")

					child:RecursiveDraw()

					love.graphics.pop()
				end
			end

			love.graphics.pop()

			if children[0] then
				children[0]:RecursiveDraw()
			end

			love.graphics.pop()
		end
	end
end

function Frame:Refresh()
	Hierarchy.Refresh(self)

	local parentAbsolutePosition = nil
	local parentAbsoluteSize = nil
	local parent = self._Parent

	if parent then
		parentAbsolutePosition = parent._AbsolutePosition
		parentAbsoluteSize = parent._AbsoluteSize
	else
		parentAbsolutePosition = Vector2.Zero
		parentAbsoluteSize = Vector2.Create(love.graphics.getDimensions())
	end

	self._AbsolutePosition = parentAbsoluteSize * self._RelativePosition + parentAbsolutePosition + self._PixelPosition
	self._AbsoluteSize = parentAbsoluteSize * self._RelativeSize + self._PixelSize
end

function Frame:RecursiveRefresh()
	Hierarchy.RecursiveRefresh(self)
	
	local childTopLeftBoundingCorner
	local childBottomRightBoundingCorner

	local children = self:GetChildren()
	if #children > 0 then
		childTopLeftBoundingCorner = Vector2.Create(math.huge, math.huge)
		childBottomRightBoundingCorner = Vector2.Create(-math.huge, -math.huge)

		for _, child in pairs(children) do
			childTopLeftBoundingCorner = Vector2.Create(
				math.min(child._AbsolutePosition.X, childTopLeftBoundingCorner.X),
				math.min(child._AbsolutePosition.Y, childTopLeftBoundingCorner.Y)
			)

			childBottomRightBoundingCorner = Vector2.Create(
				math.max(child._AbsolutePosition.X + child._AbsoluteSize.X, childBottomRightBoundingCorner.X),
				math.max(child._AbsolutePosition.Y + child._AbsoluteSize.Y, childBottomRightBoundingCorner.Y)
			)
		end
	else
		childTopLeftBoundingCorner = Vector2.Zero
		childBottomRightBoundingCorner = Vector2.Zero
	end

	self._ChildTopLeftBoundingCorner = childTopLeftBoundingCorner
	self._ChildBottomRightBoundingCorner = childBottomRightBoundingCorner
end

function Frame:RecursiveUpdate()
	Hierarchy.RecursiveUpdate(self)
end

function Frame:GetRelativePosition()
	return self._RelativePosition
end

function Frame:SetRelativePosition(position)
	if self._RelativePosition ~= position then
		self._RelativePosition = position

		self:RecursiveRefresh()
	end
end

function Frame:GetPixelPosition()
	return self._PixelPosition
end

function Frame:SetPixelPosition(position)
	if self._PixelPosition ~= position then
		self._PixelPosition = position

		self:RecursiveRefresh()
	end
end

function Frame:GetAbsolutePosition()
	return self._AbsolutePosition
end

function Frame:GetRelativeSize()
	return self._RelativeSize
end

function Frame:SetRelativeSize(size)
	if self._RelativeSize ~= size then
		self._RelativeSize = size

		self:RecursiveRefresh()
	end
end

function Frame:GetPixelSize()
	return self._PixelSize
end

function Frame:SetPixelSize(size)
	if self._PixelSize ~= size then
		self._PixelSize = size

		self:RecursiveRefresh()
	end
end

function Frame:GetAbsoluteSize()
	return self._AbsoluteSize
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

function Frame:GetCornerRadius()
	return self._CornerRadius
end

function Frame:SetCornerRadius(radius)
	self._CornerRadius = radius
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
		
		self._ChildTopLeftBoundingCorner = nil
		self._ChildBottomRightBoundingCorner = nil

		self._BackgroundColour = nil

		Hierarchy.Destroy(self)
	end
end

return Class.CreateClass(Frame, "Frame", Hierarchy)