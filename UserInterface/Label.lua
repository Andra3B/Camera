local Frame = require("UserInterface.Frame")

local Label = {}

function Label.Create()
	local self = Class.CreateInstance(Frame.Create(), Label)
	
	self._Font = UserInterface.Font.Default

	self._Text = ""
	self._TextSize = 16
	self._TextColour = Vector4.Create(0.0, 0.0, 0.0, 1.0)

	self._TextHorizontalAlignment = Enum.HorizontalAlignment.Left
	self._TextVerticalAlignment = Enum.VerticalAlignment.Middle

	self._AbsoluteTextOffset = Vector2.Zero
	self._AbsoluteTextSize = Vector2.Zero

	return self
end

function Label:Refresh()
	Frame.Refresh(self)

	self:SetText(self._Text)
end

function Label:Draw()
	Frame.Draw(self)

	local absolutePosition = self.AbsolutePosition
	local absoluteTextOffset = self._AbsoluteTextOffset

	love.graphics.setFont(self:GetFont():GetFont(self:GetTextSize()))
	love.graphics.setColor(self:GetTextColour():Unpack())
	love.graphics.print(
		self:GetText(),
		absolutePosition.X + absoluteTextOffset.X,
		absolutePosition.Y + absoluteTextOffset.Y
	)
end

function Label:GetAbsoluteTextOffset()
	return self._AbsoluteTextOffset
end

function Label:GetAbsoluteTextSize()
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
	text = tostring(text)

	local absolutePosition = self.AbsolutePosition
	local absoluteSize = self.AbsoluteSize

	local horizontalAlignment = self._TextHorizontalAlignment
	local verticalAlignment = self._TextVerticalAlignment

	local font = self:GetFont():GetFont(self._TextSize)
	
	local absoluteTextSize = Vector2.Create(font:getWidth(text), font:getHeight())

	local dx = 0
	local dy = 0

	if horizontalAlignment == Enum.HorizontalAlignment.Left then
		dx = 0
	elseif horizontalAlignment == Enum.HorizontalAlignment.Middle then
		dx = (absoluteSize.X - absoluteTextSize.X) * 0.5
	else
		dx = absoluteSize.X - absoluteTextSize.X
	end

	if verticalAlignment == Enum.VerticalAlignment.Top then
		dy = 0
	elseif verticalAlignment == Enum.VerticalAlignment.Middle then
		dy = (absoluteSize.Y - absoluteTextSize.Y) * 0.5
	else
		dy = absoluteSize.Y - absoluteTextSize.Y
	end

	self._Text = text

	self._AbsoluteTextOffset = Vector2.Create(math.floor(dx + 0.5), math.floor(dy + 0.5))
	self._AbsoluteTextSize = absoluteTextSize
end

function Label:GetTextSize()
	return self._TextSize
end

function Label:SetTextSize(size)
	self._TextSize = size
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

return Class.CreateClass(Label, "Label", Frame)