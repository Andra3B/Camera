local Interactive = love.filesystem.load("UserInterface/Interactive.lua")(
	require("UserInterface.Label")
)

local TextBox = {}

local function Input(self, inputType, scancode, state)
	if self.Focused and state.Z < 0 and inputType == Enum.InputType.Keyboard then
		if scancode == "left" then
			self.Cursor = self.Cursor - 1
		elseif scancode == "right" then
			self.Cursor = self.Cursor + 1
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

local function TextInput(self, text)
	if self.AbsoluteActive and self:IsFocused() then
		self:InsertText(text)
	end
end

function TextBox.Create()
	local self = Class.CreateInstance(Interactive.Create(), TextBox)

	self._PlaceholderText = "Enter text here..."
	self._PlaceholderTextColour = Vector4.Create(0.0, 0.0, 0.0, 0.5)

	self._Cursor = 0
	self._CursorAbsolutePosition = nil

	self._ReleaseFocusOnSubmit = true

	self._Events:Listen("Input", Input, self)
	self._Events:Listen("TextInput", TextInput, self)

	return self
end

function TextBox:Draw()
	Interactive.Draw(self)

	local absolutePosition = self.AbsolutePosition
	
	if self.AbsoluteActive and self:IsFocused() then
		local cursorAbsolutePosition = self.CursorAbsolutePosition
		
		love.graphics.setColor(self.TextColour:Unpack())
		love.graphics.rectangle(
			"fill",
			absolutePosition.X + cursorAbsolutePosition.X,
			absolutePosition.Y + cursorAbsolutePosition.Y,
			2, self.TextObject:getHeight()*0.8
		)
	elseif #self.Text == 0 then
		local textAbsolutePosition = self.TextAbsolutePosition

		love.graphics.setColor(self.PlaceholderTextColour:Unpack())
		love.graphics.draw(
			self.TextObject,
			absolutePosition.X + textAbsolutePosition.X,
			absolutePosition.Y + textAbsolutePosition.Y
		)
	end
end

function TextBox:Refresh()
	Interactive.Refresh(self)

	self._CursorAbsolutePosition = nil
end

function TextBox:SetText(text)
	Interactive.SetText(self, text)

	self.Cursor = self._Cursor
end

function TextBox:GetTextObject()
	if not self._TextObject then
		self._TextObject = love.graphics.newText(
			self.Font:GetFont(self.TextAbsoluteSize),
			#self.Text > 0 and self.Text or self.PlaceholderText
		)
	end

	return self._TextObject
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
	self._PlaceholderText = tostring(text)
end

function TextBox:GetPlaceholderTextColour()
	return self._PlaceholderTextColour
end

function TextBox:SetPlaceholderTextColour(colour)
	self._PlaceholderTextColour = colour
end

function TextBox:GetCursor()
	return self._Cursor
end

function TextBox:SetCursor(position)
	self._Cursor = math.clamp(position, 0, utf8.len(self._Text))
end

function TextBox:GetCursorAbsolutePosition()
	if not self._CursorAbsolutePosition then
		local textAbsolutePosition = self.TextAbsolutePosition

		if self.Cursor == 0 then
			self._CursorAbsolutePosition = textAbsolutePosition
		else
			local textWidth = self.Font:GetFont(self.TextAbsoluteSize):getWidth(
				string.sub(self._Text, 1, utf8.offset(self._Text, self._Cursor))
			)

			self._CursorAbsolutePosition = Vector2.Create(textWidth + textAbsolutePosition.X, textAbsolutePosition.Y)
		end
	end

	return self._CursorAbsolutePosition
end

function TextBox:GetReleaseFocusOnSubmit()
	return self._ReleaseFocusOnSubmit
end

function TextBox:SetReleaseFocusOnSubmit(keep)
	self._ReleaseFocusOnSubmit = keep
end

function TextBox:Submit()
	if self.AbsoluteActive then
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

return Class.CreateClass(TextBox, "TextBox", Interactive, {
	["CursorAbsolutePosition"] = {"Cursor", "Text", "Font", "TextAbsoluteSize", "TextAbsolutePosition"},
	["TextObject"] = {"PlaceholderText"}
})