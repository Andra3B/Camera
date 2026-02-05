local Frame = {}

function Frame.Create()
	local self = Class.CreateInstance(Object.Create(), Frame)

	self._RelativePosition = Vector2.Zero
	self._PixelPosition = Vector2.Zero
	self._AbsolutePosition = nil
	
	self._RelativeSize = Vector2.Zero
	self._PixelSize = Vector2.Zero
	self._AbsoluteSize = nil

	self._ChildPixelOffset = Vector2.Zero
	self._ChildRelativeOffset = Vector2.Zero
	self._AbsoluteChildOffset = nil

	self._BackgroundColour = Vector4.One
	self._BackgroundImage = nil

	self._CornerRadius = 0

	self._Visible = true

	return self
end

function Frame:Refresh()
	Object.Refresh(self)

	self._AbsolutePosition = nil
	self._AbsoluteSize = nil
	self._AbsoluteChildOffset = nil
end

function Frame:Draw()
	local absolutePosition = self.AbsolutePosition
	local absoluteSize = self.AbsoluteSize
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

			love.graphics.setScissor(
				math.max(newScissorTopLeft.X, scissorTopLeftX),
				math.max(newScissorTopLeft.Y, scissorTopLeftY),
				math.min(newScissorBottomRight.X - newScissorTopLeft.X, scissorWidth),
				math.min(newScissorBottomRight.Y - newScissorTopLeft.Y, scissorHeight)
			)

			love.graphics.push("all")

			self:Draw()

			for _, child in ipairs(self:GetChildren()) do
				if Class.IsA(child, "Frame") then
					love.graphics.push("all")

					child:RecursiveDraw()

					love.graphics.pop()
				end
			end

			love.graphics.pop()
			love.graphics.pop()
		end
	end
end

function Frame:GetRelativePosition()
	return self._RelativePosition
end

function Frame:SetRelativePosition(position)
	if self._RelativePosition ~= position then
		self._RelativePosition = position
		self._AbsolutePosition = nil

		self:RecursiveRefresh()
	end
end

function Frame:GetPixelPosition()
	return self._PixelPosition
end

function Frame:SetPixelPosition(position)
	if self._PixelPosition ~= position then
		self._PixelPosition = position
		self._AbsolutePosition = nil

		self:RecursiveRefresh()
	end
end

function Frame:GetAbsolutePosition()
	if not self._AbsolutePosition then
		local parentAbsolutePosition = nil
		local parentAbsoluteSize = nil
		local parentAbsoluteChildOffset = nil
		local parent = self._Parent

		if parent then
			parentAbsolutePosition = parent.AbsolutePosition
			parentAbsoluteSize = parent.AbsoluteSize
			parentAbsoluteChildOffset = parent.AbsoluteChildOffset
		else
			parentAbsolutePosition = Vector2.Zero
			parentAbsoluteSize = Vector2.Create(love.graphics.getDimensions())
			parentAbsoluteChildOffset = Vector2.Zero
		end

		self._AbsolutePosition =
			parentAbsolutePosition + parentAbsoluteChildOffset + self._PixelPosition + parentAbsoluteSize*self._RelativePosition
	end

	return self._AbsolutePosition
end

function Frame:GetRelativeSize()
	return self._RelativeSize
end

function Frame:SetRelativeSize(size)
	if self._RelativeSize ~= size then
		self._RelativeSize = size
		self._AbsoluteSize = nil
		self._AbsoluteChildOffset = nil

		self:RecursiveRefresh()
	end
end

function Frame:GetPixelSize()
	return self._PixelSize
end

function Frame:SetPixelSize(size)
	if self._PixelSize ~= size then
		self._PixelSize = size
		self._AbsoluteSize = nil
		self._AbsoluteChildOffset = nil

		self:RecursiveRefresh()
	end
end

function Frame:GetAbsoluteSize()
	if not self._AbsoluteSize then
		local parent = self._Parent

		self._AbsoluteSize = 
			self._PixelSize + (parent and parent.AbsoluteSize or Vector2.Create(love.graphics.getDimensions()))*self._RelativeSize
	end

	return self._AbsoluteSize
end

function Frame:GetChildPixelOffset()
	return self._ChildPixelOffset
end

function Frame:SetChildPixelOffset(offset)
	self._ChildPixelOffset = offset
end

function Frame:GetChildRelativeOffset()
	return self._ChildRelativeOffset
end

function Frame:SetChildRelativeOffset(offset)
	self._ChildRelativeOffset = offset
end

function Frame:GetAbsoluteChildOffset()
	if not self._AbsoluteChildOffset then
		self._AbsoluteChildOffset = self._ChildPixelOffset + self.AbsoluteSize*self._ChildRelativeOffset
	end

	return self._AbsoluteChildOffset
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

		self._ChildPixelOffset = nil
		self._ChildRelativeOffset = nil

		self._AbsoluteChildOffset = nil

		self._BackgroundColour = nil
		self._BackgroundImage = nil

		Object.Destroy(self)
	end
end

return Class.CreateClass(Frame, "Frame", Object)