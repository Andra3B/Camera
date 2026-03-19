local Interactive = love.filesystem.load("UserInterface/Interactive.lua")(require("UserInterface.Label"))

local Button = {}

function Button.Create(button)
	local self = Class.CreateInstance(Interactive.Create(button), Button)
	
	self._CanFocus = false

	if button then
	end

	return self
end

return Class.CreateClass(Button, "Button", Interactive)