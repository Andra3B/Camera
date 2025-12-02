local UserInterface = {}

UserInterface.Initialised = false

UserInterface.Frame = require("UserInterface.Frame")
UserInterface.Label = require("UserInterface.Label")
UserInterface.Button = require("UserInterface.Button")
UserInterface.TextBox = require("UserInterface.TextBox")
UserInterface.VideoFrame = require("UserInterface.VideoFrame")
UserInterface.ScrollFrame = require("UserInterface.ScrollFrame")
UserInterface.ViewSelectorFrame = require("UserInterface.ViewSelectorFrame")

UserInterface.Font = require("UserInterface.Font")
UserInterface.Video = require("UserInterface.Video")

UserInterface.Shaders = {}

UserInterface.Events = nil

UserInterface.Root = nil

UserInterface.Hovering = nil
UserInterface.LastPressed = nil
UserInterface.CurrentlyPressed = nil
UserInterface.Focus = nil

local MOUSE_INPUT_STRINGS = {
	[1] = "leftmousebutton",
	[2] = "rightmousebutton",
	[3] = "middlemousebutton",
	[4] = "firstmousebutton",
	[5] = "secondmousebutton"
}

function UserInterface.Initialise()
	if not UserInterface.Initialised then
		UserInterface.Shaders.YUV2RGBA = love.graphics.newShader(
			"Assets/Shaders/YUV2RGBA.frag",
			"Assets/Shaders/Default.vert"
		)

		UserInterface.Events = EventDirector.Create()

		UserInterface.Initialised = true
	end
end

function UserInterface.Update(deltaTime)
	UserInterface.Events:Update()

	if UserInterface.Root then
		UserInterface.Root:RecursiveUpdate(deltaTime)
	end
end

function UserInterface.Refresh()
	if UserInterface.Root then
		UserInterface.Root:RecursiveRefresh()
	end
end

function UserInterface.Input(inputType, scancode, state)
	if inputType == Enum.InputType.Mouse then
		if type(scancode) == "number" then
			scancode = MOUSE_INPUT_STRINGS[scancode]

			if not scancode then
				return
			end
		end

		local interactiveFrame = UserInterface.GetFrameContainingPoint(state.X, state.Y, UserInterface.Root, "Interactive")

		if scancode == "mousemovement" then
			UserInterface.Hovering = interactiveFrame
		elseif scancode == "leftmousebutton" then
			if state.Z < 0 then
				if interactiveFrame and interactiveFrame.AbsoluteActive then
					UserInterface.CurrentlyPressed = interactiveFrame
					UserInterface.LastPressed = interactiveFrame
					UserInterface.Focus = interactiveFrame.CanFocus and interactiveFrame or nil
					
					interactiveFrame.Events:Push("Pressed", true)
				else
					UserInterface.CurrentlyPressed = nil
					UserInterface.Focus = nil
				end
			else
				if UserInterface.CurrentlyPressed then
					UserInterface.CurrentlyPressed.Events:Push("Pressed", false)

					UserInterface.CurrentlyPressed = nil
				end
			end
		end
	end

	if UserInterface.Focus then
		UserInterface.Focus:Input(inputType, scancode, state)
	end
end

function UserInterface.TextInput(text)
	if UserInterface.Focus and UserInterface.Focus.TextInput then
		UserInterface.Focus:TextInput(text)
	end
end

function UserInterface.GetFrameContainingPoint(x, y, frame, frameType)
	local containingFrame = nil

	if frame then
		local absoluteX, absoluteY = frame._AbsolutePosition:Unpack()
		local absoluteWidth, absoluteHeight = frame._AbsoluteSize:Unpack()

		if x >= absoluteX and y >= absoluteY and x <= (absoluteX + absoluteWidth) and y <= (absoluteY + absoluteHeight) then
			if not frameType or Class.IsA(frame, frameType) then
				containingFrame = frame
			end

			local childContainingFrame = nil
			local children = frame:GetDrawnChildren()

			if children[0] then
				childContainingFrame = UserInterface.GetFrameContainingPoint(
					x, y,
					children[0],
					frameType
				)
			end

			if not childContainingFrame then
				for childIndex = #children, 1, -1 do
					childContainingFrame = UserInterface.GetFrameContainingPoint(
						x, y,
						children[childIndex],
						frameType
					)

					if childContainingFrame then
						break
					end
				end
			end

			if childContainingFrame then
				containingFrame = childContainingFrame
			end
		end
	end

	return containingFrame
end

function UserInterface.SetRoot(root)
	if Class.IsA(root, "Frame") then
		UserInterface.Root = root

		return true
	end

	return false
end

function UserInterface.Draw()
	if UserInterface.Root then
		UserInterface.Root:RecursiveDraw()
	end
end

function UserInterface.Deinitialise()
	if UserInterface.Initialised then
		if UserInterface.Root then
			UserInterface.Root:Destroy()
		end

		UserInterface.Root = nil
		UserInterface.PreFocus = nil
		UserInterface.Focus = nil

		UserInterface.Shaders.YUV2RGBA:release()
		UserInterface.Shaders.YUV2RGBA = nil

		UserInterface.Events:Destroy()
		UserInterface.Events = nil

		UserInterface.Initialised = false
	end
end

return UserInterface