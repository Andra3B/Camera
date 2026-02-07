local Frame = require("UserInterface.Frame")

local Label = {}

function Label.Create()
	local self = Class.CreateInstance(Frame.Create(), Label)
	
	self._Font = UserInterface.Font.Default

	self._Text = ""
	self._TextColour = Vector4.Create(0, 0, 0, 1)
	
	self._TextRelativeSize = 0.5
	self._TextPixelSize = 0

	self._TextHorizontalAlignment = Enum.HorizontalAlignment.Middle
	self._TextVerticalAlignment = Enum.VerticalAlignment.Middle

	self._AbsoluteTextOffset = nil
	self._AbsoluteTextSize = nil

	return self
end

function Label:Draw()
	Frame.Draw(self)

	local absolutePosition = self.AbsolutePosition
	local absoluteTextOffset = self.AbsoluteTextOffset

	love.graphics.setFont(self:GetFont():GetFont(self.AbsoluteTextSize.Y))
	love.graphics.setColor(self:GetTextColour():Unpack())
	love.graphics.print(
		self:GetText(),
		absolutePosition.X + absoluteTextOffset.X,
		absolutePosition.Y + absoluteTextOffset.Y
	)
end

function Label:Refresh()
	Frame.Refresh(self)

	self._AbsoluteTextOffset = nil
	self._AbsoluteTextSize = nil
end

function Label:GetAbsoluteTextOffset()
	if not self._AbsoluteTextOffset then
		local absoluteSize = self.AbsoluteSize
		local absoluteTextSize = self.AbsoluteTextSize

		local horizontalAlignment = self._TextHorizontalAlignment
		local verticalAlignment = self._TextVerticalAlignment

		local dx, dy

		if horizontalAlignment == Enum.HorizontalAlignment.Left then
			dx = 0
		elseif horizontalAlignment == Enum.HorizontalAlignment.Middle then
			dx = (absoluteSize.X - absoluteTextSize.X)*0.5
		else
			dx = absoluteSize.X - absoluteTextSize.X
		end

		if verticalAlignment == Enum.VerticalAlignment.Top then
			dy = 0
		elseif verticalAlignment == Enum.VerticalAlignment.Middle then
			dy = (absoluteSize.Y - absoluteTextSize.Y*1.3)*0.5
		else
			dy = absoluteSize.Y - absoluteTextSize.Y
		end

		self._AbsoluteTextOffset = Vector2.Create(math.floor(dx + 0.5), math.floor(dy + 0.5))
	end

	return self._AbsoluteTextOffset
end

function Label:GetAbsoluteTextSize()
	if not self._AbsoluteTextSize then
		local textSize = self._TextPixelSize + self.AbsoluteSize.Y*self._TextRelativeSize
		local font = self:GetFont():GetFont(textSize)

		self._AbsoluteTextSize = Vector2.Create(
			font:getWidth(self._Text),
			font:getBaseline()
		)
	end

	return self._AbsoluteTextSize
end

function Label:GetFont()
	return self._Font
end

function Label:SetFont(font)
	self._Font = font
end

function Label:GetText()
	return self._Text
end

function Label:SetText(text)
	self._Text = tostring(text)
end

function Label:GetTextRelativeSize()
	return self._TextRelativeSize
end

function Label:SetTextRelativeSize(size)
	self._TextRelativeSize = size
end

function Label:GetTextPixelSize()
	return self._TextPixelSize
end

function Label:SetTextPixelSize(size)
	self._TextPixelSize = size
end

function Label:GetTextColour()
	return self._TextColour
end

function Label:SetTextColour(colour)
	self._TextColour = colour
end

function Label:GetTextVerticalAlignment()
	return self._TextVerticalAlignment
end

function Label:SetTextVerticalAlignment(alignment)
	self._TextVerticalAlignment = alignment
end

function Label:GetTextHorizontalAlignment()
	return self._TextHorizontalAlignment
end

function Label:SetTextHorizontalAlignment(alignment)
	self._TextHorizontalAlignment = alignment
end

function Label:Destroy()
	if not self._Destroyed then
		self._Font = nil

		self._TextColour = nil

		self._AbsoluteTextOffset = nil
		self._AbsoluteTextSize = nil

		Frame.Destroy(self)
	end
end

return Class.CreateClass(Label, "Label", Frame, {
	["AbsoluteTextOffset"] = {"AbsoluteSize", "AbsoluteTextSize", "Font", "Text", "TextHorizontalAlignment", "TextVerticalAlignment"},
	["AbsoluteTextSize"] = {"AbsoluteSize", "Font", "Text", "TextRelativeSize", "TextPixelSize"}
})