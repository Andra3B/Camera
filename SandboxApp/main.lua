require("Setup")

socket = require("socket")
utf8 = require("utf8")

UserInterface = require("UserInterface")
libav = require("libav")

VideoReader = require("VideoReader")

NetworkClient = require("NetworkClient")

MotionTracker = require("MotionTracker")

function love.load()
	libav.avdevice.avdevice_register_all()

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

	Shaders = {
		["MotionMask"] = love.graphics.newShader(
			"Assets/Shaders/MotionMask.frag",
			"Assets/Shaders/Default.vert"
		),

		["Reduction"] = love.graphics.newShader(
			"Assets/Shaders/Reduction.frag",
			"Assets/Shaders/Default.vert"
		),

		["BackgroundAdaption"] = love.graphics.newShader(
			"Assets/Shaders/BackgroundAdaption.frag",
			"Assets/Shaders/Default.vert"
		)
	}

	UserInterface.Initialise()

	local Root = UserInterface.Frame.Create()
	Root.RelativeSize = Vector2.One

	VideoPlayer = UserInterface.VideoFrame.Create()
	VideoPlayer.RelativeOrigin = Vector2.Create(0.5, 0.5)
	VideoPlayer.RelativeSize = Vector2.Create(0.9, 0.9)
	VideoPlayer.RelativePosition = Vector2.Create(0.5, 0.5)
	VideoPlayer.BackgroundImageScaleMode = Enum.ScaleMode.MaintainAspectRatio
	VideoPlayer.Video = VideoReader.CreateFromURL(nil, "dshow")
	VideoPlayer.Parent = Root
	
	motionTracker = MotionTracker.Create(VideoPlayer.Video.Width, VideoPlayer.Video.Height)
	VideoPlayer.Playing = true

	UserInterface.SetRoot(Root)
end

function love.update(deltaTime)
	Timer.Update(deltaTime)
	Animation.Update(deltaTime)
	UserInterface.Update(deltaTime)
end

function love.draw()
	if VideoPlayer.FrameChanged then
		motionTracker:Update(VideoPlayer.VideoImage, not justRan)
		justRan = true
	end

	UserInterface.Draw()

	love.graphics.setLineWidth(3)

	for index, shape in pairs(motionTracker.MotionShapes) do
		local x1, y1, x2, y2 = unpack(shape)
		
		x1 = VideoPlayer.BackgroundImageAbsolutePosition.X + VideoPlayer.BackgroundImageAbsoluteSize.X*x1
		y1 = VideoPlayer.BackgroundImageAbsolutePosition.Y + VideoPlayer.BackgroundImageAbsoluteSize.Y*y1
		x2 = VideoPlayer.BackgroundImageAbsolutePosition.X + VideoPlayer.BackgroundImageAbsoluteSize.X*x2
		y2 = VideoPlayer.BackgroundImageAbsolutePosition.Y + VideoPlayer.BackgroundImageAbsoluteSize.Y*y2
		
		if index == motionTracker.LargestMotionShape then
			love.graphics.setColor(0, 0, 1, 1)
		else
			love.graphics.setColor(0, 1, 0, 1)
		end

		love.graphics.rectangle("line", x1, y1, x2 - x1, y2 - y1)
	end
		
	love.graphics.present()
end

function love.quit(exitCode)
	UserInterface.Deinitialise()
	Animation.DestroyAllAnimations()
	Timer.DestroyAllTimers()
end

function love.resize(width, height) UserInterface.Refresh() end

function love.keypressed(key, scancode) UserInterface.Input(Enum.InputType.Keyboard, scancode, Vector4.Create(0, 0, -1, 0)) end
function love.keyreleased(key, scancode) UserInterface.Input(Enum.InputType.Keyboard, scancode, Vector4.Zero) end
function love.mousemoved(x, y, dx, dy) UserInterface.Input(Enum.InputType.Mouse, "mousemovement", Vector4.Create(x, y, dx, dy)) end
function love.wheelmoved(dx, dy) UserInterface.Input(Enum.InputType.Mouse, "mousewheelmovement", Vector4.Create(dx, dy, 0, 0)) end
function love.mousepressed(x, y, button, isTouch, presses) UserInterface.Input(Enum.InputType.Mouse, button, Vector4.Create(x, y, -presses, 0)) end
function love.mousereleased(x, y, button, isTouch, presses) UserInterface.Input(Enum.InputType.Mouse, button, Vector4.Create(x, y, 0, 0)) end

function love.textinput(text) UserInterface.TextInput(text) end

function love.run()
	love.load()

	love.timer.step()
	return function()
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
end