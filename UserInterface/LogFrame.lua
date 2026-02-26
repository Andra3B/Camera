local ScrollFrame = require("UserInterface.ScrollFrame")

local LogFrame = {}

function LogFrame.Create()
	local self = Class.CreateInstance(ScrollFrame.Create(), LogFrame)

	self._Capacity = 50

	self._Logs = UserInterface.Label.Create()
	self._Logs.RelativeSize = Vector2.One
	self._Logs.BackgroundColour = Vector4.Zero
	self._Logs.TextPixelSize = 20
	self._Logs.TextRelativeOrigin = Vector2.Zero
	self._Logs.TextRelativePosition = Vector2.Zero
	self._Logs.TextPixelPosition = Vector2.Create(10, 10)
	self._Logs.ScaleToFit = true

	self._Container:AddChild(self._Logs)
	
	return self
end

function LogFrame:GetLogs()
	return self._Logs
end

function LogFrame:GetCapacity()
	return self._Capacity
end

function LogFrame:SetCapacity(capacity)
	for _ = 1, self._Capacity - capacity, 1 do
		self:Pop()
	end

	self._Capacity = capacity
end

function LogFrame:Push(text, ...)
	local logsText = self._Logs.Text
	text = logsText..string.format(text, ...).."\n"

	local lineCount = 0
	local newLine = string.byte("\n")

	local index = #text
	while index > 0 do
		if string.byte(text, index) == newLine then
			lineCount = lineCount + 1

			if lineCount > self.Capacity then
				break
			end
		end

		index = index - 1
	end

	self._Logs.Text = string.sub(text, index + 1)
end

function LogFrame:Pop()
	local logsText = self._Logs.Text

	if #logsText > 0 then
		local newLineIndex = string.find(logsText, "\n", 1, true) or #logsText

		self._Logs.Text = string.sub(logsText, newLineIndex + 1)

		return string.sub(logsText, 1, newLineIndex)
	end
end

function LogFrame:Clear()
	self._Logs.Text = ""
end

function LogFrame:Destroy()
	if not self._Destroyed then
		self._Logs = nil

		ScrollFrame.Destroy(self)
	end
end

return Class.CreateClass(LogFrame, "LogFrame", ScrollFrame)