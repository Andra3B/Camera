require("SetupEnvironment")

socket = require("socket")
utf8 = require("utf8")

UserInterface = require("UserInterface")
libav = require("libav")

VideoReader = require("VideoReader")
VideoWriter = require("VideoWriter")

NetworkServer = require("NetworkServer")

pigpio = require("pigpio")

local AppNetworkServer = nil

local livestreamPID = -1

local function StartLivestream(from, port)
	if livestreamPID < 0 then
		os.execute(
			"rpicam-vid -t 0 --codec h264 --nopreview --inline --width 1280 --height 720 -o udp://"..from:GetRemoteDetails()..":"..port.." > /dev/null 2>&1 & echo $! > LivestreamPID.txt"
		)

		local livestreamFile = io.open("LivestreamPID.txt", "r")
		livestreamPID = tonumber(livestreamFile:read("*a"):match("^%s*(%d+)%s*$"))
		livestreamFile:close()
		os.remove("LivestreamPID.txt")
	end
end

local function StopLivestream()
	if livestreamPID > 0 then
		livestreamPID = os.execute("kill "..livestreamPID)
		livestreamPID = -1
	end
end

function love.load(args)
	local width, height = love.window.getDesktopDimensions(1)
	love.window.setTitle("Linux Camera")
	love.window.setMode(width * 0.5, height * 0.5, {
		["fullscreen"] = false,
		["stencil"] = false,
		["resizable"] = true,
		["centered"] = true,
		["display"] = 1
	})
	
	libav.avdevice.avdevice_register_all()
	pigpio.gpioInitialise()
	UserInterface.Initialise()

	AppNetworkServer = NetworkServer.Create()
	AppNetworkServer:Bind(nil, 64641)

	local Root = UserInterface.Frame.Create()
	Root.RelativeSize = Vector2.Create(1, 1)
	Root.BackgroundColour = Vector4.Create(1, 1, 1, 1)
	
	local ContentFrame = UserInterface.ViewSelectorFrame.Create()
	ContentFrame.RelativeSize = Vector2.Create(0.95, 0.87)
	ContentFrame.RelativePosition = Vector2.Create(0.025, 0.105)
	ContentFrame.BackgroundColour = Vector4.Create(0.0, 0.0, 0.0, 0.1)

	local LivestreamViewButton = UserInterface.Button.Create()
	LivestreamViewButton.RelativeSize = Vector2.Create(0.5, 0.08)
	LivestreamViewButton.TextHorizontalAlignment = Enum.HorizontalAlignment.Middle
	LivestreamViewButton.Text = "Livestream"
	LivestreamViewButton.Events:Listen("Pressed", function(pressed)
		if pressed then
			ContentFrame.DrawnChildIndex = 1
		end
	end)

	local SettingsViewButton = UserInterface.Button.Create()
	SettingsViewButton.RelativeSize = Vector2.Create(0.5, 0.08)
	SettingsViewButton.RelativePosition = Vector2.Create(0.5, 0)
	SettingsViewButton.TextHorizontalAlignment = Enum.HorizontalAlignment.Middle
	SettingsViewButton.Text = "Settings"
	SettingsViewButton.Events:Listen("Pressed", function(pressed)
		if pressed then
			ContentFrame.DrawnChildIndex = 2
		end
	end)

	local LivestreamViewFrame = UserInterface.Frame.Create()
	LivestreamViewFrame.RelativeSize = Vector2.One
	LivestreamViewFrame.BackgroundColour = Vector4.Zero

	LivestreamVideoFrame = UserInterface.VideoFrame.Create()
	LivestreamVideoFrame.RelativeSize = Vector2.One
	LivestreamVideoFrame.PixelSize = Vector2.Create(-20, -20)
	LivestreamVideoFrame.PixelPosition = Vector2.Create(10, 10)
	LivestreamVideoFrame.BackgroundColour = Vector4.Create(0.0, 0.0, 0.0, 0.1)

	local SettingsViewFrame = UserInterface.Frame.Create()
	SettingsViewFrame.RelativeSize = Vector2.One
	SettingsViewFrame.BackgroundColour = Vector4.Zero

	LivestreamViewFrame:AddChild(LivestreamVideoFrame)

	ContentFrame:AddChild(LivestreamViewFrame)
	ContentFrame:AddChild(SettingsViewFrame)

	Root:AddChild(LivestreamViewButton)
	Root:AddChild(SettingsViewButton)
	Root:AddChild(ContentFrame)

	AppNetworkServer.Events:Listen("StartLivestream", StartLivestream)
	AppNetworkServer.Events:Listen("StopLivestream", StopLivestream)
	AppNetworkServer.Events:Listen("SetServoAngle", function(from, angle)
		angle = tonumber(angle)

		if angle then
			pigpio.gpioServo(18, 1500 + (math.clamp(angle, -90, 90) / 90) * 800)
		end
	end)

	AppNetworkServer:Listen()
	UserInterface.SetRoot(Root)
end

function love.quit(exitCode)
	local client = AppNetworkServer:GetClient(1)

	StopLivestream()

	if client then
		client:Send({{
			"StopLivestream"
		}})
	end

	UserInterface.Deinitialise()
	pigpio.gpioTerminate()
	AppNetworkServer:Destroy()
end

function love.update(deltaTime)
	AppNetworkServer:Update()

	UserInterface.Update(deltaTime)
end

function love.draw()
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