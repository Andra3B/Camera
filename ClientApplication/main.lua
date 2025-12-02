require("SetupEnvironment")

socket = require("socket")
utf8 = require("utf8")

UserInterface = require("UserInterface")
libav = require("libav")

NetworkClient = require("NetworkClient")

local ApplicationNetworkClient = nil

local livestreaming = false

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

	UserInterface.Initialise()

	ApplicationNetworkClient = NetworkClient.Create()
	ApplicationNetworkClient:Bind()

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
	NetworkCommandLabel.RelativePosition = Vector2.Create(0.0, 0.08)
	NetworkCommandLabel.PixelPosition = Vector2.Create(10, 20)

	local NetworkMessageTextBox = UserInterface.TextBox.Create()
	NetworkMessageTextBox.RelativeSize = Vector2.Create(1.0, 0.08)
	NetworkMessageTextBox.PixelSize = Vector2.Create(-20, 0)
	NetworkMessageTextBox.PixelPosition = Vector2.Create(10, 10)
	NetworkMessageTextBox.PlaceholderText = "Enter Message..."
	NetworkMessageTextBox.Events:Listen("Submit", function(text)
		local command = {{
			"SendMessage",
			text
		}}

		local commandString = NetworkClient.GetStringFromCommands(command)
		NetworkCommandLabel.Text = "Command: "..(commandString and commandString or "Invalid command")

		ApplicationNetworkClient:Send(command)
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
			if livestreaming then
				ApplicationNetworkClient:Send({{
					"StopLivestream"
				}})

				LivestreamVideoFrame.Video:Destroy()
				LivestreamVideoFrame.Video = nil

				livestreaming = false

				LivestreamStartButton.Text = "Start Livestream"
			else
				local freePort = NetworkClient.GetFreePort()

				ApplicationNetworkClient:Send({{
					"StartLivestream",
					freePort
				}})

				LivestreamVideoFrame.Video = UserInterface.Video.CreateFromURL(
					"udp://"..ApplicationNetworkClient:GetLocalDetails()..":"..freePort.."?timeout=1000000"
				)
				LivestreamVideoFrame.Playing = true
				livestreaming = true

				LivestreamStartButton.Text = "Stop Livestream"
			end
		end
	end)

	local SettingsViewFrame = UserInterface.Frame.Create()
	SettingsViewFrame.RelativeSize = Vector2.One
	SettingsViewFrame.BackgroundColour = Vector4.Zero

	local SettingsIPAddressTextBox = UserInterface.TextBox.Create()
	SettingsIPAddressTextBox.RelativeSize = Vector2.Create(0.5, 0.08)
	SettingsIPAddressTextBox.PixelSize = Vector2.Create(-15, 0)
	SettingsIPAddressTextBox.PixelPosition = Vector2.Create(10, 10)
	SettingsIPAddressTextBox.PlaceholderText = "Enter IP address..."

	local SettingsPortTextBox = UserInterface.TextBox.Create()
	SettingsPortTextBox.RelativeSize = Vector2.Create(0.5, 0.08)
	SettingsPortTextBox.PixelSize = Vector2.Create(-15, 0)
	SettingsPortTextBox.RelativePosition = Vector2.Create(0.5, 0)
	SettingsPortTextBox.PixelPosition = Vector2.Create(5, 10)
	SettingsPortTextBox.PlaceholderText = "Enter port..."

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
			if ApplicationNetworkClient.Connected then
				ApplicationNetworkClient:Disconnect()

				SettingsConnectButton.Text = "Connect"
			else
				local success, errorMessage = false, "Port is not a number"
				local port = tonumber(SettingsPortTextBox.Text)

				if port then
					success, errorMessage = ApplicationNetworkClient:ConnectUsingIPAddress(
						SettingsIPAddressTextBox.Text,
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

	NetworkViewFrame:AddChild(NetworkCommandLabel)
	NetworkViewFrame:AddChild(NetworkMessageTextBox)

	LivestreamViewFrame:AddChild(LivestreamVideoFrame)
	LivestreamViewFrame:AddChild(LivestreamStartButton)

	SettingsViewFrame:AddChild(SettingsIPAddressTextBox)
	SettingsViewFrame:AddChild(SettingsPortTextBox)
	SettingsViewFrame:AddChild(SettingsConnectButton)

	ContentFrame:AddChild(NetworkViewFrame)
	ContentFrame:AddChild(LivestreamViewFrame)
	ContentFrame:AddChild(SettingsViewFrame)

	Root:AddChild(NetworkTestingViewButton)
	Root:AddChild(LivestreamTestingViewButton)
	Root:AddChild(SettingsViewButton)
	Root:AddChild(ContentFrame)

	ApplicationNetworkClient.Events:Listen("StopLivestream", function()
		if LivestreamVideoFrame.Video then
			LivestreamVideoFrame.Video:Destroy()
			LivestreamVideoFrame.Video = nil
		end
		
		livestreaming = false

		LivestreamStartButton.Text = "Start Livestream"
	end)

	UserInterface.SetRoot(Root)
end

function love.quit(exitCode)
	UserInterface.Deinitialise()
	
	ApplicationNetworkClient:Destroy()
	ApplicationNetworkClient = nil
end

function love.update(deltaTime)
	ApplicationNetworkClient:Update()

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