require("SetupEnvironment")

socket = require("socket")
utf8 = require("utf8")

UserInterface = require("UserInterface")
libav = require("libav")

VideoReader = require("VideoReader")
VideoWriter = require("VideoWriter")

NetworkClient = require("NetworkClient")
NetworkServer = require("NetworkServer")

MotionTracker = require("MotionTracker")

local sourceVideoFrame = nil

local motionTracker = nil

function love.load(args)
	local width, height = love.window.getDesktopDimensions(1)
	love.window.setTitle("Sandbox")
	love.window.setMode(width * 0.5, height * 0.5, {
		["fullscreen"] = false,
		["stencil"] = false,
		["resizable"] = true,
		["centered"] = true,
		["display"] = 1
	})

	Shaders = {
		["MotionTrackingOne"] = love.graphics.newShader(
			"Assets/Shaders/MotionTrackingOne.frag",
			"Assets/Shaders/Default.vert"
		),

		["MotionTrackingTwo"] = love.graphics.newShader(
			"Assets/Shaders/MotionTrackingTwo.frag",
			"Assets/Shaders/Default.vert"
		),

		["MotionTrackingThree"] = love.graphics.newShader(
			"Assets/Shaders/MotionTrackingThree.frag",
			"Assets/Shaders/Default.vert"
		),

		["MotionTrackingFour"] = love.graphics.newShader(
			"Assets/Shaders/MotionTrackingFour.frag",
			"Assets/Shaders/Default.vert"
		),

		["MotionTrackingFive"] = love.graphics.newShader(
			"Assets/Shaders/MotionTrackingFive.frag",
			"Assets/Shaders/Default.vert"
		)
	}

	libav.avdevice.avdevice_register_all()

	UserInterface.Initialise()

	local Root = UserInterface.Frame.Create()
	Root.RelativeSize = Vector2.Create(1, 1)
	Root.BackgroundColour = Vector4.Create(1, 1, 1, 1)

	sourceVideoFrame = UserInterface.VideoFrame.Create()
	sourceVideoFrame.RelativeSize = Vector2.Create(0.5, 1)
	sourceVideoFrame.PixelSize = Vector2.Create(-20, -20)
	sourceVideoFrame.PixelPosition = Vector2.Create(10, 10)
	sourceVideoFrame.BackgroundColour = Vector4.Create(0, 0, 0, 0.1)
	sourceVideoFrame.Video = VideoReader.CreateFromURL("file:Assets/Videos/ManWalking.mp4", "mp4")
	sourceVideoFrame.Playing = true

	motionTracker = MotionTracker.Create(sourceVideoFrame.Video.Width, sourceVideoFrame.Video.Height)

	local MotionOutputFrame = UserInterface.Frame.Create()
	MotionOutputFrame.Name = "MotionOutputFrame"
	MotionOutputFrame.RelativeSize = Vector2.Create(0.5, 1)
	MotionOutputFrame.PixelSize = Vector2.Create(-20, -20)
	MotionOutputFrame.RelativePosition = Vector2.Create(0.5, 0)
	MotionOutputFrame.PixelPosition = Vector2.Create(10, 10)
	MotionOutputFrame.BackgroundImage = motionTracker._MotionCanvas

	Root:AddChild(sourceVideoFrame)
	Root:AddChild(MotionOutputFrame)

	UserInterface.SetRoot(Root)
end

function love.quit(exitCode)
	UserInterface.Deinitialise()

	motionTracker:Destroy()
end

function love.update(deltaTime)
	UserInterface.Update(deltaTime)
end

function love.draw()
	if sourceVideoFrame.FrameChanged then
		motionTracker:Update(sourceVideoFrame.BackgroundImage)
	end

	UserInterface.Draw()

	love.graphics.present()
end

function love.focus(focused)
end

function love.resize(width, height)
	UserInterface.Refresh()
end

function love.visible(visible)
end

function love.keypressed(key, scancode)
	UserInterface.Input(Enum.InputType.Keyboard, scancode, Vector4.Create(0, 0, -1, 0))
end

function love.keyreleased(key, scancode)
	UserInterface.Input(Enum.InputType.Keyboard, scancode, Vector4.Zero)
end

function love.textinput(text)
	UserInterface.TextInput(text)
end

function love.mousemoved(x, y, dx, dy)
	UserInterface.Input(Enum.InputType.Mouse, "mousemovement", Vector4.Create(x, y, dx, dy))
end

function love.wheelmoved(dx, dy)
	UserInterface.Input(Enum.InputType.Mouse, "mousewheelmovement", Vector4.Create(dx, dx, 0, 0))
end

function love.mousepressed(x, y, button, isTouch, presses)
	UserInterface.Input(Enum.InputType.Mouse, button, Vector4.Create(x, y, -presses, 0))
end

function love.mousereleased(x, y, button, isTouch, presses)
	UserInterface.Input(Enum.InputType.Mouse, button, Vector4.Create(x, y, 0, 0))
end

local function AppStep()
	love.event.pump()

	for name, a, b, c, d, e, f in love.event.poll() do
		if name == "quit" then
			a = a or 0

			love.quit(a)
			return a
		end

		local handler = love.handlers[name]

		if handler then
			handler(a, b, c, d, e, f)
		end
	end

	love.update(love.timer.step())

	if love.graphics.isActive() then
		love.draw()
	end

	love.timer.sleep(0.001)
end

function love.run()
	love.load(arg)

	love.timer.step()
	return AppStep
end