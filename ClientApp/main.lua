require("Setup")

socket = require("socket")
utf8 = require("utf8")

UserInterface = require("UserInterface")
libav = require("libav")

VideoReader = require("VideoReader")
VideoWriter = require("VideoWriter")

NetworkClient = require("NetworkClient")

MotionTracker = require("MotionTracker")

local AppNetworkClient = nil

function love.load()
	libav.avdevice.avdevice_register_all()

	AppNetworkClient = NetworkClient.Create()
	AppNetworkClient:Bind()

	local width, height = love.window.getDesktopDimensions(1)
	love.window.setTitle("Camera Client")
	love.window.setMode(width*0.5, height*0.5, {
		["fullscreen"] = false,
		["stencil"] = false,
		["resizable"] = true,
		["centered"] = true,
		["display"] = 1
	})

	UserInterface.Initialise()

	local Root = UserInterface.Frame.Create()
	Root.RelativeSize = Vector2.One

	local AppPages = UserInterface.Pages.Create()
	AppPages.RelativeSize = Vector2.One
	AppPages.Parent = Root
	
	local ConnectionPage = UserInterface.Frame.Create()
	ConnectionPage.RelativeSize = Vector2.One
	ConnectionPage.Parent = AppPages

	local ConnectionTitle = UserInterface.Label.Create()
	ConnectionTitle.RelativeOrigin = Vector2.Create(0.5, 1)
	ConnectionTitle.RelativeSize = Vector2.Create(1, 0.1)
	ConnectionTitle.RelativePosition = Vector2.Create(0.5, 0.45)
	ConnectionTitle.PixelPosition = Vector2.Create(0, -10)
	ConnectionTitle.Text = "Camera Connection Details:"
	ConnectionTitle.Font = UserInterface.Font.FreeSansBold
	ConnectionTitle.Parent = ConnectionPage

	local HostEntry = UserInterface.TextBox.Create()
	HostEntry.RelativeOrigin = Vector2.Create(1, 0.5)
	HostEntry.RelativeSize = Vector2.Create(0.4, 0.1)
	HostEntry.RelativePosition = Vector2.Create(0.5, 0.5)
	HostEntry.PixelPosition = Vector2.Create(-5, 0)
	HostEntry.PlaceholderText = "Enter Host..."
	HostEntry.RelativeCornerRadius = 1
	HostEntry.BorderThickness = 1
	HostEntry.Parent = ConnectionPage

	local PortEntry = UserInterface.TextBox.Create()
	PortEntry.RelativeOrigin = Vector2.Create(0, 0.5)
	PortEntry.RelativeSize = Vector2.Create(0.4, 0.1)
	PortEntry.RelativePosition = Vector2.Create(0.5, 0.5)
	PortEntry.PixelPosition = Vector2.Create(5, 0)
	PortEntry.PlaceholderText = "Enter Port..."
	PortEntry.RelativeCornerRadius = 1
	PortEntry.BorderThickness = 1
	PortEntry.Parent = ConnectionPage

	local ConnectButton = UserInterface.Button.Create()
	ConnectButton.RelativeOrigin = Vector2.Create(0.5, 0)
	ConnectButton.RelativeSize = Vector2.Create(0.8, 0.1)
	ConnectButton.PixelSize = Vector2.Create(10, 0)
	ConnectButton.RelativePosition = Vector2.Create(0.5, 0.55)
	ConnectButton.PixelPosition = Vector2.Create(0, 10)
	ConnectButton.RelativeCornerRadius = 1
	ConnectButton.BorderThickness = 1
	ConnectButton.Text = "Connect"
	ConnectButton.Parent = ConnectionPage

	local ErrorLabel = UserInterface.Label.Create()
	ErrorLabel.RelativeOrigin = Vector2.Create(0.5, 0)
	ErrorLabel.RelativeSize = Vector2.Create(0.8, 0.075)
	ErrorLabel.PixelSize = Vector2.Create(10, 0)
	ErrorLabel.RelativePosition = Vector2.Create(0.5, 0.65)
	ErrorLabel.PixelPosition = Vector2.Create(0, 20)
	ErrorLabel.BackgroundColour = Vector4.Create(0, 0, 0, 0.2)
	ErrorLabel.TextColour = Vector4.Create(1, 0, 0, 1)
	ErrorLabel.Font = UserInterface.Font.FreeSansBold
	ErrorLabel.RelativeCornerRadius = 1
	ErrorLabel.Visible = false
	ErrorLabel.Parent = ConnectionPage

	ConnectButton.Events:Listen("Released", function()
		local host = HostEntry.Text
		local success, errorMessage = false, "Invalid host"

		if #host > 0 then
			success, errorMessage = AppNetworkClient:Connect(host, PortEntry.Text, 3)
		end

		if success then
			print("Connected!")
			ErrorLabel.Visible = false
		else
			ErrorLabel.Text = errorMessage.."!"
			ErrorLabel.Visible = true
		end
	end)

	local NavigationBar = UserInterface.Frame.Create()
	NavigationBar.AspectRatio = 5
	NavigationBar.DominantAxis = Enum.Axis.Y
	NavigationBar.RelativeOrigin = Vector2.Create(0.5, 0)
	NavigationBar.RelativeSize = Vector2.Create(1, 0.1)
	NavigationBar.RelativePosition = Vector2.Create(0.5, 0)
	NavigationBar.PixelPosition = Vector2.Create(0, 10)
	NavigationBar.RelativeCornerRadius = 1
	NavigationBar.BorderThickness = 1
	NavigationBar.BackgroundColour = Vector4.Create(0, 0, 0, 0.2)
	NavigationBar.Parent = Root

	local LivestreamPage = UserInterface.Frame.Create()
	LivestreamPage.RelativeSize = Vector2.One
	LivestreamPage.Parent = AppPages

	local ControlBar = UserInterface.Frame.Create()
	ControlBar.AspectRatio = 5
	ControlBar.DominantAxis = Enum.Axis.Y
	ControlBar.RelativeOrigin = Vector2.Create(0.5, 1)
	ControlBar.RelativeSize = Vector2.Create(1, 0.1)
	ControlBar.RelativePosition = Vector2.Create(0.5, 1)
	ControlBar.PixelPosition = Vector2.Create(0, -10)
	ControlBar.RelativeCornerRadius = 1
	ControlBar.BorderThickness = 1
	ControlBar.BackgroundColour = Vector4.Create(0, 0, 0, 0.2)
	ControlBar.Parent = LivestreamPage

	local LeftControlButton = UserInterface.Button.Create()
	LeftControlButton.AspectRatio = 1
	LeftControlButton.DominantAxis = Enum.Axis.Y
	LeftControlButton.RelativeOrigin = Vector2.Create(0, 0.5)
	LeftControlButton.RelativeSize = Vector2.Create(1, 1)
	LeftControlButton.PixelSize = Vector2.Create(-10, -10)
	LeftControlButton.RelativePosition = Vector2.Create(0, 0.5)
	LeftControlButton.PixelPosition = Vector2.Create(5, 0)
	LeftControlButton.Text = "<"
	LeftControlButton.RelativeCornerRadius = 1
	LeftControlButton.BorderThickness = 1
	LeftControlButton.BackgroundColour = Vector4.Create(1, 1, 1, 1)
	LeftControlButton.Parent = ControlBar

	local StartControlButton = UserInterface.Button.Create()
	StartControlButton.RelativeOrigin = Vector2.Create(0.5, 0.5)
	StartControlButton.RelativeSize = Vector2.Create(0.55, 1)
	StartControlButton.PixelSize = Vector2.Create(0, -10)
	StartControlButton.RelativePosition = Vector2.Create(0.5, 0.5)
	StartControlButton.Text = "Start"
	StartControlButton.RelativeCornerRadius = 1
	StartControlButton.BorderThickness = 1
	StartControlButton.BackgroundColour = Vector4.Create(1, 1, 1, 1)
	StartControlButton.Parent = ControlBar

	local RightControlButton = UserInterface.Button.Create()
	RightControlButton.AspectRatio = 1
	RightControlButton.DominantAxis = Enum.Axis.Y
	RightControlButton.RelativeOrigin = Vector2.Create(1, 0.5)
	RightControlButton.RelativeSize = Vector2.Create(1, 1)
	RightControlButton.PixelSize = Vector2.Create(-10, -10)
	RightControlButton.RelativePosition = Vector2.Create(1, 0.5)
	RightControlButton.PixelPosition = Vector2.Create(-5, 0)
	RightControlButton.Text = ">"
	RightControlButton.RelativeCornerRadius = 1
	RightControlButton.BorderThickness = 1
	RightControlButton.BackgroundColour = Vector4.Create(1, 1, 1, 1)
	RightControlButton.Parent = ControlBar

	local LivestreamFrame = UserInterface.VideoFrame.Create()
	LivestreamFrame.RelativeSize = Vector2.Create(1, 0.8)
	LivestreamFrame.PixelSize = Vector2.Create(-20, -40)
	LivestreamFrame.RelativePosition = Vector2.Create(0, 0.1)
	LivestreamFrame.PixelPosition = Vector2.Create(10, 20)
	LivestreamFrame.PixelCornerRadius = 10
	LivestreamFrame.BorderThickness = 1
	LivestreamFrame.BackgroundColour = Vector4.Create(1, 1, 1, 1)
	LivestreamFrame.Parent = LivestreamPage

	local SettingsPage = UserInterface.Frame.Create()
	SettingsPage.RelativeSize = Vector2.One
	SettingsPage.Parent = AppPages

	AppPages:AddTransition(1, 2, Enum.PageTransitionDirection.Down)

	local timer = Timer.Create(1, true)
	timer.Events:Listen("TimerElapsed", function()
		AppPages.Page = 2
	end)

	timer.Running = true

	UserInterface.SetRoot(Root)
end

--[[
	LivestreamStartButton.Events:Listen("Pressed", function(pressed)
		if pressed then
			if LivestreamVideoFrame.Video then
				AppNetworkClient:Send({{
					"StopLivestream"
				}})

				LivestreamVideoFrame.Video:Destroy()
				LivestreamVideoFrame.Video = nil

				LivestreamStartButton.Text = "Start Livestream"
			else
				local freePort = NetworkClient.GetFreePort()

				AppNetworkClient:Send({{
					"StartLivestream",
					freePort
				}})

				local livestreamVideoReader = VideoReader.CreateFromURL(
					"udp://"..AppNetworkClient:GetLocalDetails()..":"..freePort.."?timeout=10000000",
					"h264"
				)

				if livestreamVideoReader then
					LivestreamVideoFrame.Video = livestreamVideoReader
					LivestreamVideoFrame.Playing = true

					LivestreamStartButton.Text = "Stop Livestream"
				end
			end
		end
	end)

	local SettingsHostnameTextBox = UserInterface.TextBox.Create()
	SettingsHostnameTextBox.RelativeSize = Vector2.Create(0.5, 0.08)
	SettingsHostnameTextBox.PixelSize = Vector2.Create(-15, 0)
	SettingsHostnameTextBox.PixelPosition = Vector2.Create(10, 10)
	SettingsHostnameTextBox.PlaceholderText = "Enter devices hostname..."
	SettingsHostnameTextBox.Text = "AndraeBanwosCamera"--"LAPTOP-UISV0CCS"

	local SettingsPortTextBox = UserInterface.TextBox.Create()
	SettingsPortTextBox.RelativeSize = Vector2.Create(0.5, 0.08)
	SettingsPortTextBox.PixelSize = Vector2.Create(-15, 0)
	SettingsPortTextBox.RelativePosition = Vector2.Create(0.5, 0)
	SettingsPortTextBox.PixelPosition = Vector2.Create(5, 10)
	SettingsPortTextBox.PlaceholderText = "Enter port..."
	SettingsPortTextBox.Text = "64641"
--]]

function love.update(deltaTime)
	AppNetworkClient:Update()
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
	AppNetworkClient:Destroy()
end

function love.resize(width, height) UserInterface.Refresh() end

function love.keypressed(key, scancode) UserInterface.Input(Enum.InputType.Keyboard, scancode, Vector4.Create(0, 0, -1, 0)) end
function love.keyreleased(key, scancode) UserInterface.Input(Enum.InputType.Keyboard, scancode, Vector4.Zero) end
function love.mousemoved(x, y, dx, dy) UserInterface.Input(Enum.InputType.Mouse, "mousemovement", Vector4.Create(x, y, dx, dy)) end
function love.wheelmoved(dx, dy) UserInterface.Input(Enum.InputType.Mouse, "mousewheelmovement", Vector4.Create(dx, dx, 0, 0)) end
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