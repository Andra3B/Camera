local UserInterface = {}

Enum.HorizontalAlignment = Enum.Create({
	Left = 1,
	Middle = 2,
	Right = 3
})

Enum.VerticalAlignment = Enum.Create({
	Top = 1,
	Middle = 2,
	Bottom = 3
})

Enum.InputType = Enum.Create({
	Keyboard = 1,
	Mouse = 2
})

UserInterface.Initialised = false

UserInterface.Frame = require("UserInterface.Frame")
UserInterface.Label = require("UserInterface.Label")
UserInterface.Button = require("UserInterface.Button")
UserInterface.TextBox = require("UserInterface.TextBox")
UserInterface.NumericTextBox = require("UserInterface.NumericTextBox")
UserInterface.VideoFrame = require("UserInterface.VideoFrame")
UserInterface.Pages = require("UserInterface.Pages")
UserInterface.ScrollFrame = require("UserInterface.ScrollFrame")

UserInterface.Font = require("UserInterface.Font")

UserInterface.Events = nil

UserInterface.Root = nil

UserInterface.Hovering = nil
UserInterface.Pressed = nil
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

function UserInterface.SetFocus(focus)
	local oldFocus = UserInterface.Focus

	if focus ~= oldFocus then
		if focus and focus.CanFocus then
			UserInterface.Focus = focus
			UserInterface.Focus.Events:Push("FocusGained")
		else
			UserInterface.Focus = nil
		end

		if oldFocus then
			oldFocus.Events:Push("FocusLost")
		end
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

		UserInterface.Hovering = interactiveFrame

		if scancode == "leftmousebutton" then
			if state.Z < 0 then
				if interactiveFrame and interactiveFrame.AbsoluteActive then
					UserInterface.Pressed = interactiveFrame
					UserInterface.SetFocus(interactiveFrame)

					interactiveFrame.Events:Trigger("Pressed")
				else
					UserInterface.Pressed = nil
					UserInterface.SetFocus(nil)
				end
			elseif UserInterface.Pressed then
				UserInterface.Pressed.Events:Trigger("Released")

				UserInterface.Pressed = nil
			end
		end
	end

	if UserInterface.Focus and UserInterface.Focus.AbsoluteActive then
		UserInterface.Focus.Events:Trigger("Input", inputType, scancode, state)
	end

	if UserInterface.Hovering and UserInterface.Hovering ~= UserInterface.Focus and UserInterface.Hovering.AbsoluteActive then
		UserInterface.Hovering.Events:Trigger("Input", inputType, scancode, state)
	end

	if scancode == "mousewheelmovement" then
		local x, y = love.mouse.getPosition()
		local scrollFrame = UserInterface.GetFrameContainingPoint(x, y, UserInterface.Root, "ScrollFrame")

		if
			scrollFrame and
			scrollFrame.AbsoluteActive and
			UserInterface.Focus ~= scrollFrame and
			UserInterface.Hovering ~= scrollFrame
		then
			scrollFrame.Events:Trigger("Input", inputType, scancode, state)
		end
	end
end

function UserInterface.TextInput(text)
	if UserInterface.Focus then
		UserInterface.Focus.Events:Trigger("TextInput", text)
	end
end

function UserInterface.GetFrameContainingPoint(x, y, frame, frameType)
	local containingFrame = nil

	if frame and frame.Visible then
		local absoluteX, absoluteY = frame.AbsolutePosition:Unpack()
		local absoluteWidth, absoluteHeight = frame.AbsoluteSize:Unpack()

		if x >= absoluteX and y >= absoluteY and x <= (absoluteX + absoluteWidth) and y <= (absoluteY + absoluteHeight) then
			if not frameType or Class.IsA(frame, frameType) then
				containingFrame = frame
			end
			
			local children = frame.Children

			for childIndex = #children, 1, -1 do
				local childContainingFrame = UserInterface.GetFrameContainingPoint(x, y, children[childIndex], frameType)

				if childContainingFrame then
					containingFrame = childContainingFrame
					break
				end
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

		UserInterface.Hovering = nil
		UserInterface.Pressed = nil
		UserInterface.SetFocus(nil)

		UserInterface.Events:Destroy()
		UserInterface.Events = nil

		UserInterface.Initialised = false
	end
end

return UserInterface