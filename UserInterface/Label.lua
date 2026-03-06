local Frame = require("UserInterface.Frame")

local Label = {}

function Label.Create()
	local self = Class.CreateInstance(Frame.Create(), Label)
	
	self._Font = UserInterface.Font.Default

	self._Text = ""
	self._TextObject = love.graphics.newText(self._Font:GetFont(12), "")

	self._TextColour = Vector4.Create(0, 0, 0, 1)

	self._TextRelativePosition = Vector2.Create(0.5, 0.5)
	self._TextPixelPosition = Vector2.Zero
	self._TextAbsolutePosition = Vector2.Zero

	self._TextRelativeSize = 0.5
	self._TextPixelSize = 0
	self._TextAbsoluteSize = 0

	self._TextRelativeOrigin = Vector2.Create(0.5, 0.5)
	self._TextPixelOrigin = Vector2.Zero

	self._Events:Listen("FontChanged", Label.RefreshTextObject)
	self._Events:Listen("TextChanged", Label.RefreshTextObject)
	self._Events:Listen("TextAbsoluteSizeChanged", Label.RefreshTextObject)

	self._Events:Listen("TextRelativePositionChanged", Label.RefreshTextAbsolutePosition)
	self._Events:Listen("TextPixelPositionChanged", Label.RefreshTextAbsolutePosition)
	self._Events:Listen("TextRelativeOriginChanged", Label.RefreshTextAbsolutePosition)
	self._Events:Listen("TextPixelOriginChanged", Label.RefreshTextAbsolutePosition)
	self._Events:Listen("TextObjectChanged", Label.RefreshTextAbsolutePosition)
	self._Events:Listen("AbsoluteSizeChanged", Label.RefreshTextAbsolutePosition)

	self._Events:Listen("TextRelativeSizeChanged", Label.RefreshTextAbsoluteSize)
	self._Events:Listen("TextPixelSizeChanged", Label.RefreshTextAbsoluteSize)
	self._Events:Listen("AbsoluteSizeChanged", Label.RefreshTextAbsoluteSize)

	return self
end

function Label:RefreshTextObject()
	self._TextObject:release()
	self.TextObject = love.graphics.newText(self.Font:GetFont(self._TextAbsoluteSize), self.Text)
end

function Label:RefreshTextAbsolutePosition()
	self.TextAbsolutePosition = 
		self._TextPixelPosition + self._AbsoluteSize*self._TextRelativePosition -
		self._TextPixelOrigin - self._TextRelativeOrigin*Vector2.Create(self._TextObject:getDimensions())
end

function Label:RefreshTextAbsoluteSize()
	self.TextAbsoluteSize = math.floor(self._TextPixelSize + self._AbsoluteSize.Y*self._TextRelativeSize + 0.5)
end

function Label:Draw()
	Frame.Draw(self)

	if #self.Text > 0 then
		local absolutePosition = self.AbsolutePosition
		local textAbsolutePosition = self.TextAbsolutePosition

		love.graphics.setColor(self.TextColour:Unpack())
		love.graphics.draw(
			self.TextObject,
			absolutePosition.X + textAbsolutePosition.X,
			absolutePosition.Y + textAbsolutePosition.Y
		)
	end
end

function Label:GetTextRelativePosition()
	return self._TextRelativePosition
end

function Label:SetTextRelativePosition(position)
	if position ~= self._TextRelativePosition then
		self._TextRelativePosition = position

		return true, position
	end
end

function Label:GetTextPixelPosition()
	return self._TextPixelPosition
end

function Label:SetTextPixelPosition(position)
	if position ~= self._TextPixelPosition then
		self._TextPixelPosition = position

		return true, position
	end
end

function Label:GetTextAbsolutePosition()
	return self._TextAbsolutePosition
end

function Label:SetTextAbsolutePosition(position)
	if position ~= self._TextAbsolutePosition then
		self._TextAbsolutePosition = position

		return true, position
	end
end

function Label:GetTextRelativeSize()
	return self._TextRelativeSize
end

function Label:SetTextRelativeSize(size)
	if size ~= self._TextRelativeSize then
		self._TextRelativeSize = size

		return true, size
	end
end

function Label:GetTextPixelSize()
	return self._TextPixelSize
end

function Label:SetTextPixelSize(size)
	if size ~= self._TextPixelSize then
		self._TextPixelSize = size

		return true, size
	end
end

function Label:GetTextAbsoluteSize()
	return self._TextAbsoluteSize
end

function Label:SetTextAbsoluteSize(size)
	if size ~= self._TextAbsoluteSize then
		self._TextAbsoluteSize = size

		return true, size
	end
end

function Label:GetTextRelativeOrigin()
	return self._TextRelativeOrigin
end

function Label:SetTextRelativeOrigin(origin)
	if origin ~= self._TextRelativeOrigin then
		self._TextRelativeOrigin = origin

		return true, origin
	end
end

function Label:GetTextPixelOrigin()
	return self._TextPixelOrigin
end

function Label:SetTextPixelOrigin(origin)
	if origin ~= self._TextPixelOrigin then
		self._TextPixelOrigin = origin

		return true, origin
	end
end

function Label:GetFont()
	return self._Font
end

function Label:SetFont(font)
	if font ~= self._Font then
		self._Font = font

		return true, font
	end
end

function Label:GetText()
	return self._Text
end

function Label:SetText(text)
	text = tostring(text)

	if text ~= self._Text then
		self._Text = text

		return true, text
	end
end

function Label:GetTextObject()
	return self._TextObject
end

function Label:SetTextObject(object)
	if object ~= self._TextObject then
		self._TextObject = object

		return true, object
	end
end

function Label:GetTextColour()
	return self._TextColour
end

function Label:SetTextColour(colour)
	if colour ~= self._TextColour then
		self._TextColour = colour

		return true, colour
	end
end

function Label:Destroy()
	if not self._Destroyed then
		self._Font = nil
		
		self._TextObject:release()
		self._TextObject = nil

		self._TextAbsolutePosition = nil
		self._TextAbsoluteSize = nil

		self._TextColour = nil

		Frame.Destroy(self)
	end
end

return Class.CreateClass(Label, "Label", Frame)