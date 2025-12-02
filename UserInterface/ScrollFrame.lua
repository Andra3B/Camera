local Frame = require("UserInterface.Frame")
local Button = require("UserInterface.Button")

local ScrollFrame = {}

function ScrollFrame.Create()
	local self = Class.CreateInstance(Frame.Create(), ScrollFrame)

	self._ViewPosition = Vector2.Zero

	local scrollOverlayFrame = Frame.Create()
	scrollOverlayFrame.RelativeSize = Vector2.One
	scrollOverlayFrame.BackgroundColour = Vector4.Zero

	local verticalScrollBarButton = Button.Create()
	verticalScrollBarButton.Name = "VerticalScrollBarButton"
	verticalScrollBarButton.RelativeSize = Vector2.Create(0.01, 0.2)
	verticalScrollBarButton.BackgroundColour = Vector4.Create(1, 0, 0, 1)

	scrollOverlayFrame:AddChild(verticalScrollBarButton)

	self:AddChild(scrollOverlayFrame, 0)

	return self
end

function ScrollFrame:Draw()
	Frame.Draw(self)

	local dx, dy = self:GetViewPosition():Unpack()
	love.graphics.translate(-dx, -dy)
end

function ScrollFrame:GetViewPosition()
	return self._ViewPosition
end

function ScrollFrame:SetViewPosition(position)
	self._ViewPosition = position
end

function ScrollFrame:Destroy()
	if not self._Destroyed then
		self._ViewPosition = nil

		Frame.Destroy(self)
	end
end

return Class.CreateClass(ScrollFrame, "ScrollFrame", Frame)