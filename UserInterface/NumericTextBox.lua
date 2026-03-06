local TextBox = require("UserInterface.TextBox")

local NumericTextBox = {}

function NumericTextBox.Create()
	local self = Class.CreateInstance(TextBox.Create(), NumericTextBox)

	self._Minimum = 0
	self._Maximum = 1

	self._LastValidValue = nil

	self._Events:Listen("FocusLost", NumericTextBox.CorrectValue)

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
	if minimum ~= self._Minimum then
		self._Minimum = minimum

		self._LastValidValue = nil

		return true, minimum
	end
end

function NumericTextBox:GetMaximum()
	return self._Maximum
end

function NumericTextBox:SetMaximum(maximum)
	if maximum ~= self._Maximum then
		self._Maximum = maximum

		self._LastValidValue = nil

		return true, maximum
	end
end

return Class.CreateClass(NumericTextBox, "NumericTextBox", TextBox)