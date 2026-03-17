local Button = require("UserInterface.Button")

local ToggleButton = {}

local function ButtonReleased(self)
	self.Value = not self._Value
end

function ToggleButton.Create()
	local self = Class.CreateInstance(Button.Create(), ToggleButton)

	self._Value = false

	self._Events:Listen("Released", ButtonReleased)

	return self
end

function ToggleButton:GetValue()
	return self._Value
end

function ToggleButton:SetValue(value)
	value = value and true

	if value ~= self._Value then
		self._Value = value

		return true, value
	end
end

return Class.CreateClass(ToggleButton, "ToggleButton", Button)