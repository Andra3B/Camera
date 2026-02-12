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
	love.window.setTitle("Camera Client")
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

		["COMEncode"] = love.graphics.newShader(
			"Assets/Shaders/COMEncode.frag",
			"Assets/Shaders/Default.vert"
		),

		["Reduction"] = love.graphics.newShader(
			"Assets/Shaders/Reduction.frag",
			"Assets/Shaders/Default.vert"
		)
	}

	UserInterface.Initialise()

	Root = UserInterface.Frame.Create()
	Root.RelativeSize = Vector2.One

	local redFrame = UserInterface.Frame.Create()
	redFrame.RelativeSize = Vector2.Create(0.6, 0.6)
	redFrame.BackgroundColour = Vector4.Create(1, 0, 0, 1)
	redFrame.Parent = Root

	local blueFrame = UserInterface.Frame.Create()
	blueFrame.RelativeSize = Vector2.Create(0.5, 0.5)
	blueFrame.RelativePosition = Vector2.Create(0.8, 0.8)
	blueFrame.BackgroundColour = Vector4.Create(0, 0, 1, 1)
	blueFrame.Parent = redFrame

	UserInterface.SetRoot(Root)
end

function love.update(deltaTime)
	Timer.Update(deltaTime)
	Animation.Update(deltaTime)
	UserInterface.Update(deltaTime)
end

function love.draw()
	UserInterface.Draw()
		
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