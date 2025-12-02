require("SetupEnvironment")

socket = require("socket")
utf8 = require("utf8")

UserInterface = require("UserInterface")
libav = require("libav")

NetworkServer = require("NetworkServer")

local ApplicationNetworkServer = nil

local livestreaming = false
local LivestreamVideoFrame = nil

function love.load(args)
	local width, height = love.window.getDesktopDimensions(1)
	love.window.setTitle("Camera")
	love.window.setMode(width * 0.5, height * 0.5, {
		["fullscreen"] = false,
		["stencil"] = false,
		["resizable"] = true,
		["centered"] = true,
		["display"] = 1
	})

	UserInterface.Initialise()

	ApplicationNetworkServer = NetworkServer.Create()
	
	ApplicationNetworkServer:Bind()
	local IPAddress, port = ApplicationNetworkServer:GetLocalDetails()

	local Root = UserInterface.Frame.Create()
	Root.RelativeSize = Vector2.Create(1, 1)
	Root.BackgroundColour = Vector4.Create(1, 1, 1, 1)
	
	local ContentFrame = UserInterface.ViewSelectorFrame.Create()
	ContentFrame.RelativeSize = Vector2.Create(0.95, 0.87)
	ContentFrame.RelativePosition = Vector2.Create(0.025, 0.105)
	ContentFrame.BackgroundColour = Vector4.Create(0.0, 0.0, 0.0, 0.1)

	local NetworkTestingViewButton = UserInterface.Button.Create()
	NetworkTestingViewButton.RelativeSize = Vector2.Create(1/3, 0.08)
	NetworkTestingViewButton.TextHorizontalAlignment = Enum.HorizontalAlignment.Middle
	NetworkTestingViewButton.Text = "Network Testing"
	NetworkTestingViewButton.Events:Listen("Pressed", function(pressed)
		if pressed then
			ContentFrame.DrawnChildIndex = 1
		end
	end)

	local LivestreamTestingViewButton = UserInterface.Button.Create()
	LivestreamTestingViewButton.RelativeSize = Vector2.Create(1/3, 0.08)
	LivestreamTestingViewButton.RelativePosition = Vector2.Create(1/3, 0)
	LivestreamTestingViewButton.TextHorizontalAlignment = Enum.HorizontalAlignment.Middle
	LivestreamTestingViewButton.Text = "Livestream Testing"
	LivestreamTestingViewButton.Events:Listen("Pressed", function(pressed)
		if pressed then
			ContentFrame.DrawnChildIndex = 2
		end
	end)

	local SettingsViewButton = UserInterface.Button.Create()
	SettingsViewButton.RelativeSize = Vector2.Create(1/3, 0.08)
	SettingsViewButton.RelativePosition = Vector2.Create(2/3, 0)
	SettingsViewButton.TextHorizontalAlignment = Enum.HorizontalAlignment.Middle
	SettingsViewButton.Text = "Settings"
	SettingsViewButton.Events:Listen("Pressed", function(pressed)
		if pressed then
			ContentFrame.DrawnChildIndex = 3
		end
	end)

	local NetworkViewFrame = UserInterface.Frame.Create()
	NetworkViewFrame.RelativeSize = Vector2.One
	NetworkViewFrame.BackgroundColour = Vector4.Zero

	local NetworkCommandLabel = UserInterface.Label.Create()
	NetworkCommandLabel.RelativeSize = Vector2.Create(1.0, 0.08)
	NetworkCommandLabel.PixelSize = Vector2.Create(-20, 0)
	NetworkCommandLabel.PixelPosition = Vector2.Create(10, 10)

	local LivestreamViewFrame = UserInterface.Frame.Create()
	LivestreamViewFrame.RelativeSize = Vector2.One
	LivestreamViewFrame.BackgroundColour = Vector4.Zero

	LivestreamVideoFrame = UserInterface.VideoFrame.Create()
	LivestreamVideoFrame.RelativeSize = Vector2.Create(1, 1)
	LivestreamVideoFrame.PixelSize = Vector2.Create(-20, -20)
	LivestreamVideoFrame.PixelPosition = Vector2.Create(10, 10)
	LivestreamVideoFrame.BackgroundColour = Vector4.Create(0.0, 0.0, 0.0, 0.1)

	local SettingsViewFrame = UserInterface.Frame.Create()
	SettingsViewFrame.RelativeSize = Vector2.One
	SettingsViewFrame.BackgroundColour = Vector4.Zero

	local SettingsIPAddressLabel = UserInterface.Label.Create()
	SettingsIPAddressLabel.RelativeSize = Vector2.Create(0.5, 0.08)
	SettingsIPAddressLabel.PixelSize = Vector2.Create(-15, 0)
	SettingsIPAddressLabel.PixelPosition = Vector2.Create(10, 10)
	SettingsIPAddressLabel.Text = IPAddress

	local SettingsPortLabel = UserInterface.Label.Create()
	SettingsPortLabel.RelativeSize = Vector2.Create(0.5, 0.08)
	SettingsPortLabel.PixelSize = Vector2.Create(-15, 0)
	SettingsPortLabel.RelativePosition = Vector2.Create(0.5, 0)
	SettingsPortLabel.PixelPosition = Vector2.Create(5, 10)
	SettingsPortLabel.Text = port

	local SettingsVideoSourceTextBox = UserInterface.TextBox.Create()
	SettingsVideoSourceTextBox.RelativeSize = Vector2.Create(1, 0.08)
	SettingsVideoSourceTextBox.PixelSize = Vector2.Create(-20, 0)
	SettingsVideoSourceTextBox.RelativePosition = Vector2.Create(0, 0.08)
	SettingsVideoSourceTextBox.PixelPosition = Vector2.Create(10, 20)
	SettingsVideoSourceTextBox.PlaceholderText = "Enter video source..."
	SettingsVideoSourceTextBox.Text = "Assets/Videos/Ocean.mp4"

	NetworkViewFrame:AddChild(NetworkCommandLabel)

	LivestreamViewFrame:AddChild(LivestreamVideoFrame)

	SettingsViewFrame:AddChild(SettingsIPAddressLabel)
	SettingsViewFrame:AddChild(SettingsPortLabel)
	SettingsViewFrame:AddChild(SettingsVideoSourceTextBox)

	ContentFrame:AddChild(NetworkViewFrame)
	ContentFrame:AddChild(LivestreamViewFrame)
	ContentFrame:AddChild(SettingsViewFrame)

	Root:AddChild(NetworkTestingViewButton)
	Root:AddChild(LivestreamTestingViewButton)
	Root:AddChild(SettingsViewButton)
	Root:AddChild(ContentFrame)

	ApplicationNetworkServer.Events:Listen("StartLivestream", function(from, port)
		if livestreaming then return end
		
		local video = UserInterface.Video.CreateFromURL(SettingsVideoSourceTextBox.Text)

		if video then
			LivestreamVideoFrame.Video = video
			video:StartLivestream("udp://"..from:GetRemoteDetails()..":"..port)
		
			LivestreamVideoFrame.Playing = true
			livestreaming = true
		else
			love.window.showMessageBox("Couldn't Find Video Source", "Couldn't find video source!", "error")
		end
	end)

	ApplicationNetworkServer.Events:Listen("StopLivestream", function()
		LivestreamVideoFrame.Playing = false
	end)

	ApplicationNetworkServer.Events:Listen("SendMessage", function(from, message)
		local IPAddress, port = from:GetRemoteDetails()
		
		NetworkCommandLabel.Text = "Received message \""..message.."\" from ("..IPAddress..", "..port..")"
	end)

	libav.avdevice.avdevice_register_all()

	ApplicationNetworkServer:Listen()

	UserInterface.SetRoot(Root)
end

function love.quit(exitCode)
	if livestreaming then
		ApplicationNetworkServer:GetClient(1):Send({{
			"StopLivestream"
		}})
	end

	UserInterface.Deinitialise()
	ApplicationNetworkServer:Destroy()
end

function love.update(deltaTime)
	ApplicationNetworkServer:Update()

	UserInterface.Update(deltaTime)

	if livestreaming and not LivestreamVideoFrame.Playing then
		ApplicationNetworkServer:GetClient(1):Send({{
			"StopLivestream"
		}})

		LivestreamVideoFrame.Video:Destroy()
		LivestreamVideoFrame.Video = nil

		livestreaming = false
	end
end

function love.draw()
	love.graphics.clear(0, 0, 0, 0)

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

local function ApplicationStep()
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
	return ApplicationStep
end