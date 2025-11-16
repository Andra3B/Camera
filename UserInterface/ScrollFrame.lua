local Interactive = loadfile("UserInterface/Interactive.lua")(
	require("UserInterface.Frame")
)

local ScrollFrame = {}

function ScrollFrame.Create()
	local self = Class.CreateInstance(Interactive.Create(), ScrollFrame)

	return self
end

return Class.CreateClass(ScrollFrame, "ScrollFrame", Interactive)