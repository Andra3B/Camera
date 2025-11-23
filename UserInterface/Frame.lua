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

	self._ChildOffset = Vector2.Zero

	self._BackgroundColour = Vector4.One
	self._BackgroundImage = nil

	self._CornerRadius = 0

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
		love.graphics.setScissor(
			math.max(newScissorTopLeft.X, scissorTopLeftX),
			math.max(newScissorTopLeft.Y, scissorTopLeftY),
			math.min(newScissorBottomRight.X - newScissorTopLeft.X, scissorWidth),
			math.min(newScissorBottomRight.Y - newScissorTopLeft.Y, scissorHeight)
		)

		self:Draw()

		for _, child in ipairs(self:GetChildren()) do
			if Class.IsA(child, "Frame") then
				love.graphics.push("all")

				child:RecursiveDraw()

				love.graphics.pop()
			end
		end

		love.graphics.setScissor()
		love.graphics.origin()
	end
end

function Frame:Refresh()
	Hierarchy.Refresh(self)

	local parentAbsolutePosition = nil
	local parentChildOffset = nil
	local parentAbsoluteSize = nil
	local parent = self._Parent

	if parent then
		parentAbsolutePosition = parent._AbsolutePosition
		parentChildOffset = parent:GetChildOffset()
		parentAbsoluteSize = parent._AbsoluteSize
	else
		parentAbsolutePosition = Vector2.Zero
		parentChildOffset = Vector2.Zero
		parentAbsoluteSize = Vector2.Create(love.graphics.getDimensions())
	end

	self._AbsolutePosition =
		parentAbsoluteSize * self._RelativePosition + parentAbsolutePosition + parentChildOffset + self._PixelPosition
		
	self._AbsoluteSize = parentAbsoluteSize * self._RelativeSize + self._PixelSize
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

function Frame:GetChildOffset()
	return self._ChildOffset
end

function Frame:SetChildOffset(offset)
	if self._ChildOffset ~= offset then
		self._ChildOffset = offset

		self:RecursiveRefresh()
	end
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

function Frame:Destroy()
	if not self._Destroyed then
		self._RelativePosition = nil
		self._PixelPosition = nil

		self._RelativeSize = nil
		self._PixelSize = nil

		self._AbsolutePosition = nil
		self._AbsoluteSize = nil

		self._ChildOffset = nil

		self._BackgroundColour = nil

		Hierarchy.Destroy(self)
	end
end

return Class.CreateClass(Frame, "Frame", Hierarchy)