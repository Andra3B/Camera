local Frame = require("UserInterface.Frame")

local Label = {}

function Label.Create()
	local self = Class.CreateInstance(Frame.Create(), Label)
	
	self._Font = UserInterface.Font.Default

	self._Text = ""
	self._TextObject = nil

	self._TextColour = Vector4.Create(0, 0, 0, 1)

	self._TextRelativePosition = Vector2.Create(0.5, 0.5)
	self._TextPixelPosition = Vector2.Zero
	self._TextAbsolutePosition = nil

	self._TextRelativeSize = 0.5
	self._TextPixelSize = 0
	self._TextAbsoluteSize = nil

	self._TextRelativeOrigin = Vector2.Create(0.5, 0.5)
	self._TextPixelOrigin = Vector2.Zero

	self._ScaleToFit = false

	return self
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

function Label:GetAbsoluteSize()
	if not self._AbsoluteSize then
		local absoluteSize = Frame.GetAbsoluteSize(self)

		if self.ScaleToFit then
			local width, height = self.TextObject:getDimensions()

			self._AbsoluteSize.X = math.max(absoluteSize.X, width)
			self._AbsoluteSize.Y = math.max(absoluteSize.Y, height)
		end
	end

	return self._AbsoluteSize
end

function Label:Refresh()
	Frame.Refresh(self)

	self._TextObject = nil

	self._TextAbsolutePosition = nil
	self._TextAbsoluteSize = nil
end

function Label:GetTextRelativePosition()
	return self._TextRelativePosition
end

function Label:SetTextRelativePosition(position)
	self._TextRelativePosition = position

	if self.ScaleToFit then
		self:RecursiveRefresh(true)
	end
end

function Label:GetTextPixelPosition()
	return self._TextPixelPosition
end

function Label:SetTextPixelPosition(position)
	self._TextPixelPosition = position

	if self.ScaleToFit then
		self:RecursiveRefresh(true)
	end
end

function Label:GetTextAbsolutePosition()
	if not self._TextAbsolutePosition then
		self._TextAbsolutePosition = 
			self._TextPixelPosition + self.AbsoluteSize*self._TextRelativePosition -
			self._TextPixelOrigin - self._TextRelativeOrigin*Vector2.Create(self.TextObject:getDimensions())
	end

	return self._TextAbsolutePosition
end

function Label:GetTextRelativeSize()
	return self._TextRelativeSize
end

function Label:SetTextRelativeSize(size)
	self._TextRelativeSize = size

	if self.ScaleToFit then
		self:RecursiveRefresh(true)
	end
end

function Label:GetTextPixelSize()
	return self._TextPixelSize
end

function Label:SetTextPixelSize(size)
	self._TextPixelSize = size

	if self.ScaleToFit then
		self:RecursiveRefresh(true)
	end
end

function Label:GetTextAbsoluteSize()
	if not self._TextAbsoluteSize then
		if self.ScaleToFit then
			self._TextAbsoluteSize = math.floor(self._TextPixelSize + 0.5)
		else
			self._TextAbsoluteSize = math.floor(self._TextPixelSize + self.AbsoluteSize.Y*self._TextRelativeSize + 0.5)
		end
	end

	return self._TextAbsoluteSize
end

function Label:GetTextRelativeOrigin()
	return self._TextRelativeOrigin
end

function Label:SetTextRelativeOrigin(origin)
	self._TextRelativeOrigin = origin

	if self.ScaleToFit then
		self:RecursiveRefresh(true)
	end
end

function Label:GetTextPixelOrigin()
	return self._TextPixelOrigin
end

function Label:SetTextPixelOrigin(origin)
	self._TextPixelOrigin = origin

	if self.ScaleToFit then
		self:RecursiveRefresh(true)
	end
end

function Label:GetFont()
	return self._Font
end

function Label:SetFont(font)
	self._Font = font

	if self.ScaleToFit then
		self:RecursiveRefresh(true)
	end
end

function Label:GetText()
	return self._Text
end

function Label:SetText(text)
	text = tostring(text)

	if text ~= self._Text then
		self._Text = text

		if self.ScaleToFit then
			self:RecursiveRefresh(true)
		end

		self.Events:Push("TextChanged", text)
	end
end

function Label:GetTextObject()
	if not self._TextObject then
		self._TextObject = love.graphics.newText(self.Font:GetFont(self.TextAbsoluteSize), self.Text)
	end

	return self._TextObject
end

function Label:GetTextColour()
	return self._TextColour
end

function Label:SetTextColour(colour)
	self._TextColour = colour
end

function Label:GetScaleToFit()
	return self._ScaleToFit
end

function Label:SetScaleToFit(scaleToFit)
	self._ScaleToFit = scaleToFit
end

function Label:Destroy()
	if not self._Destroyed then
		self._Font = nil

		self._TextObject = nil

		self._TextAbsolutePosition = nil
		self._TextAbsoluteSize = nil

		self._TextColour = nil

		Frame.Destroy(self)
	end
end

return Class.CreateClass(Label, "Label", Frame, {
	["TextObject"] = {"TextAbsoluteSize", "Font", "Text"},
	["TextAbsolutePosition"] = {"TextObject", "TextPixelPosition", "TextRelativePosition", "TextPixelOrigin", "TestRelativeOrigin"},
	["TextAbsoluteSize"] = {"AbsoluteSize", "TextPixelSize", "TextRelativeSize"}
})