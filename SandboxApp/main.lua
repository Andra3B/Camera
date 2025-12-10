require("SetupEnvironment")

socket = require("socket")
utf8 = require("utf8")

UserInterface = require("UserInterface")
libav = require("libav")

VideoReader = require("VideoReader")
VideoWriter = require("VideoWriter")

NetworkClient = require("NetworkClient")
NetworkServer = require("NetworkServer")

pigpio = require("pigpio")

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

	libav.avdevice.avdevice_register_all()

	print(pigpio.gpioInitialise())

	local Root = UserInterface.Frame.Create()
	Root.RelativeSize = Vector2.Create(1, 1)
	Root.BackgroundColour = Vector4.Create(1, 1, 1, 1)

	local ServoPWMNumberTextBox = UserInterface.TextBox.Create()
	ServoPWMNumberTextBox.RelativeSize = Vector2.Create(0.5, 0.08)
	ServoPWMNumberTextBox.RelativePosition = Vector2.Create(0.25, 0.46)
	ServoPWMNumberTextBox.PlaceholderText = "Enter Servo PWM Number (1000-2000)..."
	ServoPWMNumberTextBox.Text = "1500"
	ServoPWMNumberTextBox.Events:Listen("Submit", function(text)
		pigpio.gpioServo(18, tonumber(text))
	end)

	Root:AddChild(MyVideoFrame)

	UserInterface.SetRoot(Root)
	UserInterface.Initialise()
end

function love.quit(exitCode)
	UserInterface.Deinitialise()

	pigpio.gpioTerminate()
end

function love.update(deltaTime)
	UserInterface.Update(deltaTime)
end

function love.draw()
	--love.graphics.clear(0, 0, 0, 0)

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