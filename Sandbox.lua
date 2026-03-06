libav = require("libav.libav")
VideoReader = require("VideoReader")

function love.load()
	VideoReader.Initialize()

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
	
	FPSLabel = UserInterface.Label.Create()
	FPSLabel.RelativeOrigin = Vector2.Create(0.5, 0.5)
	FPSLabel.RelativeSize = Vector2.Create(0.5, 0.1)
	FPSLabel.RelativePosition = Vector2.Create(0.5, 0.5)

	FPSLabel.Parent = Root

	local MyLabel = UserInterface.Label.Create()
	MyLabel.RelativeSize = Vector2.Create(1, 0.1)
	MyLabel.BackgroundColour = Vector4.Create(1, 0, 0, 1)
	MyLabel.Text = "Hello, world!"

	MyLabel.Parent = Root

	UserInterface.SetRoot(Root)
end

function love.update(deltaTime)
	FPSLabel.Text = love.timer.getFPS()
end

function love.quit(exitCode)
	VideoReader.Deinitialize()
end