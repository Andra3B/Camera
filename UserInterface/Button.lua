local Interactive = love.filesystem.load("UserInterface/Interactive.lua")(
	require("UserInterface.Label")
)

local Button = {}

function Button.Create()
	local self = Class.CreateInstance(Interactive.Create(), Button)
	
	self._CanFocus = false

	return self
end

return Class.CreateClass(Button, "Button", Interactive)