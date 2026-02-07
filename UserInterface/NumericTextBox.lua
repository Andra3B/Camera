local TextBox = require("UserInterface.TextBox")

local NumericTextBox = {}

function NumericTextBox.Create()
	local self = Class.CreateInstance(TextBox.Create(), NumericTextBox)

	self._Minimum = 0
	self._Maximum = 1

	self._LastValidValue = nil

	return self
end

function NumericTextBox:CorrectValue()
	local text = string.gsub(tostring(self._Text), "%s*", "")

	if string.find(text, "^%-?%d+.?%d*$") then
		local value = tonumber(text)

		if value then
			value = math.clamp(value, self._Minimum, self._Maximum)

			self.Text = value
			self._LastValidValue = value
			return
		end
	end

	self.Text = self._LastValidValue or self._Minimum
end

NumericTextBox.FocusLost = NumericTextBox.CorrectValue

function NumericTextBox:GetValue()
	return tonumber(self._Text)
end

function NumericTextBox:SetValue(value)
	self.Text = value
end

function NumericTextBox:GetMinimum()
	return self._Minimum
end

function NumericTextBox:SetMinimum(minimum)
	self._Minimum = minimum

	self._LastValidValue = nil
end

function NumericTextBox:GetMaximum()
	return self._Maximum
end

function NumericTextBox:SetMaximum(maximum)
	self._Maximum = maximum

	self._LastValidValue = nil
end

return Class.CreateClass(NumericTextBox, "NumericTextBox", TextBox)