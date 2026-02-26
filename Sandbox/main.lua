function love.load()
	local width, height = love.window.getDesktopDimensions(1)
	love.window.setTitle("Sandbox")
	love.window.setMode(width*0.5, height*0.5, {
		["fullscreen"] = false,
		["stencil"] = false,
		["resizable"] = true,
		["centered"] = true,
		["minwidth"] = 400,
		["minheight"] = 400,
		["display"] = 1
	})

	local Root = UserInterface.Frame.Create()
	Root.RelativeSize = Vector2.Create(1, 1)

	ConsoleLogs = UserInterface.LogFrame.Create()
	ConsoleLogs.RelativeSize = Vector2.Create(1, 0.9)
	ConsoleLogs.PixelSize = Vector2.Create(-20, -20)
	ConsoleLogs.PixelPosition = Vector2.Create(10, 10)
	ConsoleLogs.Logs.Text = string.rep("Hello, world!\n", 50)
	ConsoleLogs.BorderThickness = 2
	ConsoleLogs.Parent = Root

	local ConsoleInput = UserInterface.TextBox.Create()
	ConsoleInput.RelativeSize = Vector2.Create(1, 0.1)
	ConsoleInput.RelativePosition = Vector2.Create(0, 0.9)
	ConsoleInput.BorderThickness = 2
	ConsoleInput.PlaceholderText = "Enter command..."
	ConsoleInput.ReleaseFocusOnSubmit = false
	ConsoleInput.Parent = Root

	ConsoleInput.Events:Listen("Submit", function(text)
		ConsoleLogs:Push(text)

		ConsoleInput.Text = ""
	end)

	UserInterface.SetRoot(Root)
end