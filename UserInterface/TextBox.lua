local Interactive = love.filesystem.load("UserInterface/Interactive.lua")(
	require("UserInterface.Label")
)

local TextBox = {}

function TextBox.Create()
	local self = Class.CreateInstance(Interactive.Create(), TextBox)

	self._PlaceholderText = "Enter text here..."
	self._PlaceholderTextColour = Vector4.Create(0.0, 0.0, 0.0, 0.5)

	self._CursorPosition = 0

	self._AbsoluteCursorOffset = nil
	self._AbsoluteCursorSize = nil

	return self
end

function TextBox:Refresh()
	Interactive.Refresh(self)
end

function TextBox:Draw()
	Interactive.Draw(self)

	local absolutePosition = self.AbsolutePosition
	
	if self.AbsoluteActive and self:IsFocused() then
		local absoluteCursorOffset = self.AbsoluteCursorOffset
		local absoluteCursorSize = self.AbsoluteCursorSize
		
		love.graphics.rectangle(
			"fill",
			absolutePosition.X + absoluteCursorOffset.X,
			absolutePosition.Y + absoluteCursorOffset.Y,
			absoluteCursorSize.X,
			absoluteCursorSize.Y
		)
	elseif #self._Text == 0 then
		local absoluteTextOffset = self.AbsoluteTextOffset
		
		love.graphics.setColor(self._PlaceholderTextColour:Unpack())
		love.graphics.print(
			self._PlaceholderText,
			absolutePosition.X + absoluteTextOffset.X,
			absolutePosition.Y + absoluteTextOffset.Y
		)
	end
end

function TextBox:Refresh()
	Interactive.Refresh(self)

	self._AbsoluteCursorOffset = nil
	self._AbsoluteCursorSize = nil
end

function TextBox:GetAbsoluteTextSize()
	if not self._AbsoluteTextSize then
		local textSize = self._TextPixelSize + self.AbsoluteSize.Y*self._TextRelativeSize
		local font = self:GetFont():GetFont(textSize)

		self._AbsoluteTextSize = Vector2.Create(
			font:getWidth(#self._Text > 0 and self._Text or self._PlaceholderText),
			font:getBaseline()
		)
	end

	return self._AbsoluteTextSize
end

function TextBox:SetText(text)
	Interactive.SetText(self, text)

	self.CursorPosition = self._CursorPosition
end

function TextBox:InsertText(text)
	if #text > 0 then
		local cursorPosition = self._CursorPosition

		local boxText = self._Text
		local cursorByteOffset = utf8.offset(boxText, cursorPosition + 1)

		self.Text = string.sub(boxText, 1, cursorByteOffset - 1)..text..string.sub(boxText, cursorByteOffset)

		self.CursorPosition = cursorPosition + utf8.len(text)
	end
end

function TextBox:GetPlaceholderText()
	return self._PlaceholderText
end

function TextBox:SetPlaceholderText(text)
	self._PlaceholderText = tostring(text)
end

function TextBox:GetPlaceholderTextColour()
	return self._PlaceholderTextColour
end

function TextBox:SetPlaceholderTextColour(colour)
	self._PlaceholderTextColour = colour
end

function TextBox:GetCursorPosition()
	return self._CursorPosition
end

function TextBox:SetCursorPosition(position)
	self._CursorPosition = math.clamp(position, 0, utf8.len(self._Text))
end

function TextBox:GetAbsoluteCursorOffset()
	if not self._AbsoluteCursorOffset then
		local cursorPosition = self._CursorPosition
		local absoluteTextOffset = self.AbsoluteTextOffset

		if cursorPosition == 0 then
			self._AbsoluteCursorOffset = absoluteTextOffset
		else
			local text = self._Text
			local textWidth = self:GetFont():GetFont(self.AbsoluteTextSize.Y):getWidth(
				string.sub(text, 1, utf8.offset(text, cursorPosition))
			)

			self._AbsoluteCursorOffset = Vector2.Create(
				textWidth + absoluteTextOffset.X, absoluteTextOffset.Y
			)
		end
	end

	return self._AbsoluteCursorOffset
end

function TextBox:GetAbsoluteCursorSize()
	if not self._AbsoluteCursorSize then
		self._AbsoluteCursorSize = Vector2.Create(
			2, self:GetFont():GetFont(self.AbsoluteTextSize.Y):getHeight()
		)
	end

	return self._AbsoluteCursorSize
end

function TextBox:SetFont(font)
	Interactive.SetFont(self, font)

	self._AbsoluteCursorOffset = nil
end

function TextBox:Submit()
	if self.AbsoluteActive then
		self._Events:Push("Submit", self._Text)
	end
end

function TextBox:Input(inputType, scancode, state)
	if self.AbsoluteActive and self:IsFocused() and state.Z < 0 and inputType == Enum.InputType.Keyboard then
		if scancode == "left" then
			self.CursorPosition = self.CursorPosition - 1
		elseif scancode == "right" then
			self.CursorPosition = self.CursorPosition + 1
		elseif scancode == "backspace" then
			local text = self._Text
			local cursorPosition = self.CursorPosition

			if cursorPosition > 0 and #text > 0 then
				self.Text = string.replace(
					text,
					utf8.offset(text, cursorPosition),
					utf8.offset(text, cursorPosition + 1) - 1,
					""
				)

				self.CursorPosition = cursorPosition - 1
			end
		elseif scancode == "return" then
			self:Submit()
		end
	end
end

function TextBox:TextInput(text)
	if self.AbsoluteActive and self:IsFocused() then
		self:InsertText(text)
	end
end

return Class.CreateClass(TextBox, "TextBox", Interactive, {
	["AbsoluteTextSize"] = {"PlaceholderText"},
	["AbsoluteCursorOffset"] = {"CursorPosition", "AbsoluteTextSize", "AbsoluteTextOffset"},
	["AbsoluteCursorSize"] = {"Font", "AbsoluteTextSize"}
})