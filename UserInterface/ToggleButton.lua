local Button = require("UserInterface.Button")

local ToggleButton = {}

local function ButtonReleased(self)
	self.Value = not self._Value
end

function ToggleButton.Create(toggleButton)
	local self = Class.CreateInstance(Button.Create(toggleButton), ToggleButton)

	self._Value = false

	self._ToggledBackgroundImage = nil
	self._ClearedBackgroundImage = nil

	self._Events:Listen("Released", ButtonReleased)

	self._Events:Listen("ToggledBackgroundImageChanged", ToggleButton.RefreshBackgroundImageAbsoluteValues)
	self._Events:Listen("ClearedBackgroundImageChanged", ToggleButton.RefreshBackgroundImageAbsoluteValues)
	self._Events:Listen("ValueChanged", ToggleButton.RefreshBackgroundImageAbsoluteValues)

	if toggleButton then
		self.Value = toggleButton.Value

		self.ToggledBackgroundImage = toggleButton.ToggledBackgroundImage
		self.ClearedBackgroundImageChanged = toggleButton.ClearedBackgroundImage
	end

	return self
end

function ToggleButton:GetBackgroundImage()
	if self.ToggledBackgroundImage or self.ClearedBackgroundImage then
		if self._Value then
			return self.ToggledBackgroundImage
		else
			return self.ClearedBackgroundImage
		end
	else
		return Button.GetBackgroundImage(self)
	end
end

function ToggleButton:GetToggledBackgroundImage()
	return self._ToggledBackgroundImage
end

function ToggleButton:SetToggledBackgroundImage(image)
	if image ~= self._ToggledBackgroundImage then
		self._ToggledBackgroundImage = image

		return true, image
	end
end

function ToggleButton:GetClearedBackgroundImage()
	return self._ClearedBackgroundImage
end

function ToggleButton:SetClearedBackgroundImage(image)
	if image ~= self._ClearedBackgroundImage then
		self._ClearedBackgroundImage = image

		return true, image
	end
end

function ToggleButton:GetValue()
	return self._Value
end

function ToggleButton:SetValue(value)
	if value ~= self._Value then
		self._Value = value

		return true, value
	end
end

function ToggleButton:Destroy()
	if not self._Destroyed then
		self._ToggledBackgroundImage = nil
		self._ClearedBackgroundImage = nil

		Button.Destroy(self)
	end
end

return Class.CreateClass(ToggleButton, "ToggleButton", Button)