require("SetupEnvironment")

socket = require("socket")
utf8 = require("utf8")

UserInterface = require("UserInterface")
libav = require("libav")

VideoReader = require("VideoReader")
VideoWriter = require("VideoWriter")

NetworkClient = require("NetworkClient")

local AppNetworkClient = nil

function love.load(args)
	local width, height = love.window.getDesktopDimensions(1)
	love.window.setTitle("Client")
	love.window.setMode(width * 0.5, height * 0.5, {
		["fullscreen"] = false,
		["stencil"] = false,
		["resizable"] = true,
		["centered"] = true,
		["display"] = 1
	})

	libav.avdevice.avdevice_register_all()

	UserInterface.Initialise()

	AppNetworkClient = NetworkClient.Create()
	AppNetworkClient:Bind()

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

	local LivestreamVideoFrame = UserInterface.VideoFrame.Create()
	LivestreamVideoFrame.RelativeSize = Vector2.Create(1.0, 0.92)
	LivestreamVideoFrame.PixelSize = Vector2.Create(-20, -30)
	LivestreamVideoFrame.PixelPosition = Vector2.Create(10, 10)
	LivestreamVideoFrame.BackgroundColour = Vector4.Create(0.0, 0.0, 0.0, 0.1)

	local LivestreamStartButton = UserInterface.Button.Create()
	LivestreamStartButton.RelativeSize = Vector2.Create(1.0, 0.08)
	LivestreamStartButton.PixelSize = Vector2.Create(-20, 0)
	LivestreamStartButton.RelativePosition = Vector2.Create(0, 0.92)
	LivestreamStartButton.PixelPosition = Vector2.Create(10, -10)
	LivestreamStartButton.BackgroundColour = Vector4.Create(1.0, 1.0, 1.0, 0.6)
	LivestreamStartButton.TextHorizontalAlignment = Enum.HorizontalAlignment.Middle
	LivestreamStartButton.Text = "Start Livestream"
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
					"udp://"..AppNetworkClient:GetLocalDetails()..":"..freePort.."?timeout=3000000",
					"mpegts"
				)

				if livestreamVideoReader then
					LivestreamVideoFrame.Video = livestreamVideoReader
					LivestreamVideoFrame.Playing = true

					LivestreamStartButton.Text = "Stop Livestream"
				end
			end
		end
	end)

	local SettingsViewFrame = UserInterface.Frame.Create()
	SettingsViewFrame.RelativeSize = Vector2.One
	SettingsViewFrame.BackgroundColour = Vector4.Zero

	local SettingsHostnameTextBox = UserInterface.TextBox.Create()
	SettingsHostnameTextBox.RelativeSize = Vector2.Create(0.5, 0.08)
	SettingsHostnameTextBox.PixelSize = Vector2.Create(-15, 0)
	SettingsHostnameTextBox.PixelPosition = Vector2.Create(10, 10)
	SettingsHostnameTextBox.PlaceholderText = "Enter devices hostname..."
	SettingsHostnameTextBox.Text = "LAPTOP-UISV0CCS"

	local SettingsPortTextBox = UserInterface.TextBox.Create()
	SettingsPortTextBox.RelativeSize = Vector2.Create(0.5, 0.08)
	SettingsPortTextBox.PixelSize = Vector2.Create(-15, 0)
	SettingsPortTextBox.RelativePosition = Vector2.Create(0.5, 0)
	SettingsPortTextBox.PixelPosition = Vector2.Create(5, 10)
	SettingsPortTextBox.PlaceholderText = "Enter port..."
	SettingsPortTextBox.Text = "64641"

	local SettingsConnectButton = UserInterface.Button.Create()
	SettingsConnectButton.RelativeSize = Vector2.Create(1.0, 0.08)
	SettingsConnectButton.PixelSize = Vector2.Create(-20, 0)
	SettingsConnectButton.RelativePosition = Vector2.Create(0, 0.08)
	SettingsConnectButton.PixelPosition = Vector2.Create(10, 20)
	SettingsConnectButton.BackgroundColour = Vector4.Create(1.0, 1.0, 1.0, 0.6)
	SettingsConnectButton.TextHorizontalAlignment = Enum.HorizontalAlignment.Middle
	SettingsConnectButton.Text = "Connect"
	SettingsConnectButton.Events:Listen("Pressed", function(pressed)
		if pressed then
			if AppNetworkClient.Connected then
				AppNetworkClient:Disconnect()

				if LivestreamVideoFrame.Video then
					LivestreamVideoFrame.Video:Destroy()
					LivestreamVideoFrame.Video = nil
				end

				LivestreamStartButton.Text = "Start Livestream"
				SettingsConnectButton.Text = "Connect"
			else
				local success, errorMessage = false, "Port is not a number"
				local port = tonumber(SettingsPortTextBox.Text)

				if port then
					success, errorMessage = AppNetworkClient:ConnectUsingHostname(
						SettingsHostnameTextBox.Text,
						port,
						3
					)
				end

				if success then
					love.window.showMessageBox("Connection Established", "Connection established.", "info")

					SettingsConnectButton.Text = "Disconnect"
				else
					love.window.showMessageBox("Connection Failed", "Connection failed! "..errorMessage, "error")
				end
			end
		end
	end)

	local SettingsServoAngleTextBox = UserInterface.TextBox.Create()
	SettingsServoAngleTextBox.RelativeSize = Vector2.Create(1.0, 0.08)
	SettingsServoAngleTextBox.PixelSize = Vector2.Create(-20, 0)
	SettingsServoAngleTextBox.RelativePosition = Vector2.Create(0.0, 0.16)
	SettingsServoAngleTextBox.PixelPosition = Vector2.Create(10, 30)
	SettingsServoAngleTextBox.PlaceholderText = "Enter servo angle (-90 to 90)..."
	SettingsServoAngleTextBox.Events:Listen("Submit", function(servoAngle)
		AppNetworkClient:Send({{
			"SetServoAngle", servoAngle
		}})
	end)

	LivestreamViewFrame:AddChild(LivestreamVideoFrame)
	LivestreamViewFrame:AddChild(LivestreamStartButton)

	SettingsViewFrame:AddChild(SettingsHostnameTextBox)
	SettingsViewFrame:AddChild(SettingsPortTextBox)
	SettingsViewFrame:AddChild(SettingsConnectButton)
	SettingsViewFrame:AddChild(SettingsServoAngleTextBox)

	ContentFrame:AddChild(LivestreamViewFrame)
	ContentFrame:AddChild(SettingsViewFrame)

	Root:AddChild(LivestreamViewButton)
	Root:AddChild(SettingsViewButton)
	Root:AddChild(ContentFrame)

	AppNetworkClient.Events:Listen("StopLivestream", function()
		if LivestreamVideoFrame.Video then
			LivestreamVideoFrame.Video:Destroy()
			LivestreamVideoFrame.Video = nil
		end

		LivestreamStartButton.Text = "Start Livestream"
	end)

	AppNetworkClient.Events:Listen("Disconnect", function()
		if LivestreamVideoFrame.Video then
			LivestreamVideoFrame.Video:Destroy()
			LivestreamVideoFrame.Video = nil
		end

		LivestreamStartButton.Text = "Start Livestream"
		SettingsConnectButton.Text = "Connect"
	end)

	UserInterface.SetRoot(Root)
end

function love.quit(exitCode)
	UserInterface.Deinitialise()
	
	AppNetworkClient:Destroy()
	AppNetworkClient = nil
end

function love.update(deltaTime)
	AppNetworkClient:Update()

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