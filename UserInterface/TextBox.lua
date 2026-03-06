local Interactive = love.filesystem.load("UserInterface/Interactive.lua")(require("UserInterface.Label"))

local TextBox = {}

local function Input(self, _, inputType, scancode, state)
	if self.Focused and state.Z < 0 and inputType == Enum.InputType.Keyboard then
		if scancode == "left" then
			self.Cursor = self._Cursor - 1
		elseif scancode == "right" then
			self.Cursor = self._Cursor + 1
		elseif scancode == "backspace" then
			local text = self._Text
			local cursor = self._Cursor

			if cursor > 0 and #text > 0 then
				self.Text = string.replace(text, utf8.offset(text, cursor), utf8.offset(text, cursor + 1) - 1, "")
				self.Cursor = cursor - 1
			end
		elseif scancode == "return" then
			self:Submit()

			if self._ReleaseFocusOnSubmit then
				UserInterface.SetFocus(nil)
			end
		end
	end
end

local function TextInput(self, _, text)
	if self._Active and self.Focused then
		self:InsertText(text)
	end
end

function TextBox.Create()
	local self = Class.CreateInstance(Interactive.Create(), TextBox)

	self._PlaceholderText = "Enter text here..."
	self._PlaceholderTextColour = Vector4.Create(0.0, 0.0, 0.0, 0.5)

	self._Cursor = 0
	self._CursorAbsolutePosition = Vector2.Zero

	self._ReleaseFocusOnSubmit = true

	self._Events:Listen("Input", Input)
	self._Events:Listen("TextInput", TextInput)

	self._Events:GetListener("FontChanged", 1).Callback = TextBox.RefreshTextObject
	self._Events:GetListener("TextChanged", 1).Callback = TextBox.RefreshTextObject
	self._Events:GetListener("TextAbsoluteSizeChanged", 1).Callback = TextBox.RefreshTextObject
	self._Events:Listen("PlaceholderTextChanged", TextBox.RefreshTextObject)

	self._Events:Listen("TextAbsolutePositionChanged", TextBox.RefreshCursorAbsolutePosition)
	self._Events:Listen("TextObjectChanged", TextBox.RefreshCursorAbsolutePosition)
	self._Events:Listen("CursorChanged", TextBox.RefreshCursorAbsolutePosition)

	return self
end

function TextBox:RefreshTextObject()
	self._TextObject:release()
	self.TextObject = love.graphics.newText(
		self.Font:GetFont(self._TextAbsoluteSize),
		#self._Text > 0 and self._Text or self._PlaceholderText
	)
end

function TextBox:RefreshCursorAbsolutePosition()
	local textAbsolutePosition = self._TextAbsolutePosition

	if self._Cursor == 0 then
		self.CursorAbsolutePosition = textAbsolutePosition
	else
		local textWidth = self.Font:GetFont(self._TextAbsoluteSize):getWidth(
			string.sub(self._Text, 1, utf8.offset(self._Text, self._Cursor))
		)

		self.CursorAbsolutePosition = Vector2.Create(textWidth + textAbsolutePosition.X, textAbsolutePosition.Y)
	end
end

function TextBox:Draw()
	Interactive.Draw(self)

	local absolutePosition = self._AbsolutePosition
	
	if self._Active and self.Focused then
		local cursorAbsolutePosition = self._CursorAbsolutePosition

		love.graphics.setColor(self.TextColour:Unpack())
		love.graphics.rectangle(
			"fill",
			absolutePosition.X + cursorAbsolutePosition.X,
			absolutePosition.Y + cursorAbsolutePosition.Y,
			2, self._TextObject:getHeight()*0.8
		)
	elseif #self._Text == 0 then
		local textAbsolutePosition = self._TextAbsolutePosition

		love.graphics.setColor(self.PlaceholderTextColour:Unpack())
		love.graphics.draw(
			self._TextObject,
			absolutePosition.X + textAbsolutePosition.X,
			absolutePosition.Y + textAbsolutePosition.Y
		)
	end
end

function TextBox:InsertText(text)
	if #text > 0 then
		local boxText = self._Text
		local cursorByteOffset = utf8.offset(boxText, self._Cursor + 1)

		self.Text = string.sub(boxText, 1, cursorByteOffset - 1)..text..string.sub(boxText, cursorByteOffset)
		self.Cursor = self._Cursor + utf8.len(text)
	end
end

function TextBox:GetPlaceholderText()
	return self._PlaceholderText
end

function TextBox:SetPlaceholderText(text)
	if text ~= self._PlaceholderText then
		self._PlaceholderText = tostring(text)

		return true, text
	end
end

function TextBox:GetPlaceholderTextColour()
	return self._PlaceholderTextColour
end

function TextBox:SetPlaceholderTextColour(colour)
	if colour ~= self._PlaceholderTextColour then
		self._PlaceholderTextColour = colour

		return true, colour
	end
end

function TextBox:GetCursor()
	return self._Cursor
end

function TextBox:SetCursor(position)
	position = math.clamp(position, 0, utf8.len(self._Text))

	if position ~= self._Cursor then
		self._Cursor = position

		return true, position
	end
end

function TextBox:GetCursorAbsolutePosition()
	return self._CursorAbsolutePosition
end

function TextBox:SetCursorAbsolutePosition(position)
	if position ~= self._CursorAbsolutePosition then
		self._CursorAbsolutePosition = position

		return true, position
	end
end

function TextBox:GetReleaseFocusOnSubmit()
	return self._ReleaseFocusOnSubmit
end

function TextBox:SetReleaseFocusOnSubmit(release)
	if release ~= self._ReleaseFocusOnSubmit then
		self._ReleaseFocusOnSubmit = release

		return true, release
	end
end

function TextBox:Submit()
	if self._Active then
		self._Events:Push("Submit", self._Text)
	end
end

function TextBox:Destroy()
	if not self._Destroyed then
		self._PlaceholderTextColour = nil

		self._CursorAbsolutePosition = nil

		Interactive.Destroy(self)
	end
end

return Class.CreateClass(TextBox, "TextBox", Interactive)