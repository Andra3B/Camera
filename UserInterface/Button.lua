local Interactive = love.filesystem.load("UserInterface/Interactive.lua")(
	require("UserInterface.Label")
)

local Button = {}

function Button.Create()
	local self = Class.CreateInstance(Interactive.Create(), Button)

	self._BackgroundColour = Vector4.Create(0.0, 0.0, 0.0, 0.1)

	return self
end

return Class.CreateClass(Button, "Button", Interactive)