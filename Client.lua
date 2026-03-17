libav = require("libav.libav")
VideoReader = require("VideoReader")

MotionTracker = require("MotionTracker")

local appClient

local tracker = nil

local livestreaming = false
local tracking = false

local function StartLivestream()
	if not livestreaming then
		local freePort = NetworkClient.GetFreePort()

		appClient:Send("&StartLivestream:%d!", freePort)

		local livestream = VideoReader.Create(
			"tcp://"..appClient:GetLocalDetails()..":"..freePort.."?listen=1&timeout=5000000&recv_buffer_size=65536",
			"mpegts",
			5,
			"fflags=nobuffer,avioflags=direct"
		)

		if livestream then
			tracker = MotionTracker.Create(livestream.Width, livestream.Height)

			LivestreamFrame.Video = livestream
			LivestreamFrame.VideoVisible = true
			LivestreamFrame.Playing = true

			LivestreamButton.Text = "STOP"

			livestreaming = true
		end
	end
end

local function StopLivestream()
	if livestreaming then
		appClient:Send("&StopLivestream!")

		tracker:Destroy()
		tracker = nil
		
		LivestreamFrame.BackgroundImage = nil
		
		LivestreamFrame.Video:Destroy()
		LivestreamFrame.Video = nil

		LivestreamButton.Text = "START"

		livestreaming = false
	end
end

function love.load()
	appClient = NetworkClient.Create()
	appClient:Bind()
	
	VideoReader.Initialize()

	local width, height = love.window.getDesktopDimensions(1)
	love.window.setTitle("Camera Client")
	love.window.setMode(width*0.5, height*0.5, {
		["fullscreen"] = false,
		["stencil"] = false,
		["resizable"] = true,
		["centered"] = true,
		["minwidth"] = 600,
		["minheight"] = 600,
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

	Icons = {
		["Close"] = love.graphics.newImage("Assets/Images/Icons/Close.png"),
		["Settings"] = love.graphics.newImage("Assets/Images/Icons/Settings.png"),
		["LeftArrow"] = love.graphics.newImage("Assets/Images/Icons/LeftArrow.png"),
		["RightArrow"] = love.graphics.newImage("Assets/Images/Icons/RightArrow.png"),
		["Anchor"] = love.graphics.newImage("Assets/Images/Icons/Anchor.png"),
		["Sliders"] = love.graphics.newImage("Assets/Images/Icons/Sliders.png")
	}

	local Root = UserInterface.Frame.Create()
	Root.BackgroundColour = Vector4.Create(0.12, 0.12, 0.12, 1)
	Root.RelativeSize = Vector2.One

	local Topbar = UserInterface.Frame.Create()
	Topbar.RelativeSize = Vector2.Create(1, 0)
	Topbar.PixelSize = Vector2.Create(0, 50)
	Topbar.BackgroundColour = Vector4.Create(1, 1, 1, 0.05)
	Topbar.Parent = Root
	
	local AppPages = UserInterface.Pages.Create()
	AppPages.RelativeSize = Vector2.Create(1, 1)
	AppPages.PixelSize = Vector2.Create(0, -Topbar.AbsoluteSize.Y)
	AppPages.PixelPosition = Vector2.Create(0, Topbar.AbsoluteSize.Y)
	AppPages.BackgroundColour = Vector4.Zero
	AppPages.Parent = Root

	local DisconnectButton = UserInterface.Button.Create()
	DisconnectButton.AspectRatio = 1
	DisconnectButton.DominantAxis = Enum.Axis.Y
	DisconnectButton.RelativeSize = Vector2.Create(1, 1)
	DisconnectButton.BackgroundImage = Icons.Close
	DisconnectButton.BackgroundColour = Vector4.Zero
	DisconnectButton.Parent = Topbar

	DisconnectButton.Events:Listen("Pressed", function()
		appClient:Disconnect()
	end)

	local TitleLabel = UserInterface.Label.Create()
	TitleLabel.RelativeOrigin = Vector2.Create(0.5, 0)
	TitleLabel.RelativeSize = Vector2.Create(1, 1)
	TitleLabel.RelativePosition = Vector2.Create(0.5, 0)
	TitleLabel.Text = "Connection Details:"
	TitleLabel.TextColour = Vector4.One
	TitleLabel.BackgroundColour = Vector4.Zero
	TitleLabel.Parent = Topbar

	local SettingsButton = UserInterface.Button.Create()
	SettingsButton.AspectRatio = 1
	SettingsButton.DominantAxis = Enum.Axis.Y
	SettingsButton.RelativeOrigin = Vector2.Create(1, 0)
	SettingsButton.RelativeSize = Vector2.Create(1, 1)
	SettingsButton.RelativePosition = Vector2.Create(1, 0)
	SettingsButton.BackgroundImage = Icons.Settings
	SettingsButton.BackgroundImageScale = 0.8
	SettingsButton.BackgroundColour = Vector4.Zero
	SettingsButton.Parent = Topbar

	SettingsButton.Events:Listen("Pressed", function()
		if AppPages.Page == 3 then
			if appClient.Connected then
				AppPages.Page = 2
			else
				AppPages.Page = 1
			end
		else
			AppPages.Page = 3
		end
	end)
	
	local ConnectionPage = UserInterface.Frame.Create()
	ConnectionPage.RelativeSize = Vector2.One
	ConnectionPage.BackgroundColour = Vector4.Zero
	ConnectionPage.Parent = AppPages

	local CameraAddressEntry = UserInterface.TextBox.Create()
	CameraAddressEntry.RelativeOrigin = Vector2.Create(0.5, 1)
	CameraAddressEntry.RelativeSize = Vector2.Create(0.7, 0)
	CameraAddressEntry.PixelSize = Vector2.Create(0, 50)
	CameraAddressEntry.RelativePosition = Vector2.Create(0.5, 0.5)
	CameraAddressEntry.PixelPosition = Vector2.Create(0, -5)
	CameraAddressEntry.PlaceholderText = "Enter camera address (hostname:port)..."
	CameraAddressEntry.PlaceholderTextColour = Vector4.Create(1, 1, 1, 0.5)
	CameraAddressEntry.BackgroundColour = Vector4.Create(0.2, 0.2, 0.2, 1)
	CameraAddressEntry.TextColour = Vector4.One
	CameraAddressEntry.CornerPixelRadius = 10
	CameraAddressEntry.Parent = ConnectionPage

	local ConnectionErrorLabel = UserInterface.Label.Create()
	ConnectionErrorLabel.RelativeOrigin = Vector2.Create(0.5, 0)
	ConnectionErrorLabel.RelativeSize = Vector2.Create(0.7, 0)
	ConnectionErrorLabel.PixelSize = Vector2.Create(0, 50)
	ConnectionErrorLabel.RelativePosition = Vector2.Create(0.5, 0.5)
	ConnectionErrorLabel.PixelPosition = Vector2.Create(0, CameraAddressEntry.AbsoluteSize.Y + 15)
	ConnectionErrorLabel.BackgroundColour = Vector4.Create(0.3, 0.3, 0.3, 1)
	ConnectionErrorLabel.TextColour = Vector4.Create(1, 0, 0, 1)
	ConnectionErrorLabel.CornerPixelRadius = 10
	ConnectionErrorLabel.Visible = false
	ConnectionErrorLabel.Parent = ConnectionPage

	local ConnectButton = UserInterface.Button.Create()
	ConnectButton.RelativeOrigin = Vector2.Create(0.5, 0)
	ConnectButton.RelativeSize = Vector2.Create(0.6, 0)
	ConnectButton.PixelSize = Vector2.Create(0, 50)
	ConnectButton.RelativePosition = Vector2.Create(0.5, 0.5)
	ConnectButton.PixelPosition = Vector2.Create(0, 5)
	ConnectButton.Text = "Connect"
	ConnectButton.BackgroundColour = Vector4.Create(0.2, 0.2, 0.2, 1)
	ConnectButton.TextColour = Vector4.One
	ConnectButton.CornerPixelRadius = 10
	ConnectButton.Parent = ConnectionPage	

	ConnectButton.Events:Listen("Pressed", function()
		local host, port = string.match(CameraAddressEntry.Text, "([%w_%.]+):(%d+)")
		
		local success, errorMessage = false, "Invalid address"

		if host then
			success, errorMessage = appClient:Connect(host, port, 3)
		end

		if success then
			ConnectionErrorLabel.Visible = false
			AppPages.Page = 2
		else
			ConnectionErrorLabel.Text = errorMessage.."!"
			ConnectionErrorLabel.Visible = true
		end
	end)

	local LivestreamPage = UserInterface.Frame.Create()
	LivestreamPage.RelativeSize = Vector2.One
	LivestreamPage.BackgroundColour = Vector4.Zero
	LivestreamPage.Parent = AppPages

	LivestreamButton = UserInterface.Button.Create()
	LivestreamButton.AspectRatio = 3
	LivestreamButton.DominantAxis = Enum.Axis.Y
	LivestreamButton.RelativeOrigin = Vector2.Create(0.5, 1)
	LivestreamButton.RelativeSize = Vector2.Create(1, 0)
	LivestreamButton.PixelSize = Vector2.Create(0, 60)
	LivestreamButton.RelativePosition = Vector2.Create(0.5, 1)
	LivestreamButton.PixelPosition = Vector2.Create(0, -20)
	LivestreamButton.BackgroundColour = Vector4.Create(0.2, 0.2, 0.2, 1)
	LivestreamButton.TextColour = Vector4.One
	LivestreamButton.BorderThickness = 3
	LivestreamButton.BorderColour = Vector4.One
	LivestreamButton.CornerRelativeRadius = 1
	LivestreamButton.Text = "START"
	LivestreamButton.Parent = LivestreamPage

	LivestreamButton.Events:Listen("Released", function()
		if livestreaming then
			StopLivestream()
		else
			StartLivestream()
		end
	end)

	local RotateLeftButton = UserInterface.Button.Create()
	RotateLeftButton.AspectRatio = 1
	RotateLeftButton.DominantAxis = Enum.Axis.Y
	RotateLeftButton.RelativeOrigin = Vector2.Create(1, 1)
	RotateLeftButton.RelativeSize = Vector2.Create(1, 0)
	RotateLeftButton.PixelSize = Vector2.Create(0, 60)
	RotateLeftButton.RelativePosition = Vector2.Create(0.5, 1)
	RotateLeftButton.PixelPosition = Vector2.Create(-LivestreamButton.AbsoluteSize.X*0.5 - 10, -20)
	RotateLeftButton.BackgroundColour = Vector4.Create(0.2, 0.2, 0.2, 1)
	RotateLeftButton.TextColour = Vector4.One
	RotateLeftButton.BorderThickness = 3
	RotateLeftButton.BorderColour = Vector4.One
	RotateLeftButton.CornerRelativeRadius = 1
	RotateLeftButton.BackgroundImage = Icons.LeftArrow
	RotateLeftButton.Parent = LivestreamPage

	RotateLeftButton.Events:Listen("Released", function()
		appClient:Send("&IncrementServoAngle:%d!", 10)
	end)

	local RotateRightButton = UserInterface.Button.Create()
	RotateRightButton.AspectRatio = 1
	RotateRightButton.DominantAxis = Enum.Axis.Y
	RotateRightButton.RelativeOrigin = Vector2.Create(0, 1)
	RotateRightButton.RelativeSize = Vector2.Create(1, 0)
	RotateRightButton.PixelSize = Vector2.Create(0, 60)
	RotateRightButton.RelativePosition = Vector2.Create(0.5, 1)
	RotateRightButton.PixelPosition = Vector2.Create(LivestreamButton.AbsoluteSize.X*0.5 + 10, -20)
	RotateRightButton.BackgroundColour = Vector4.Create(0.2, 0.2, 0.2, 1)
	RotateRightButton.TextColour = Vector4.One
	RotateRightButton.BorderThickness = 3
	RotateRightButton.BorderColour = Vector4.One
	RotateRightButton.CornerRelativeRadius = 1
	RotateRightButton.BackgroundImage = Icons.RightArrow
	RotateRightButton.Parent = LivestreamPage

	RotateRightButton.Events:Listen("Released", function()
		appClient:Send("&IncrementServoAngle:%d!", 10)
	end)

	local TrackingToggleButton = UserInterface.ToggleButton.Create()
	TrackingToggleButton.AspectRatio = 1
	TrackingToggleButton.DominantAxis = Enum.Axis.Y
	TrackingToggleButton.RelativeOrigin = Vector2.Create(0, 1)
	TrackingToggleButton.RelativeSize = Vector2.Create(1, 0)
	TrackingToggleButton.PixelSize = Vector2.Create(0, 60)
	TrackingToggleButton.RelativePosition = Vector2.Create(0, 1)
	TrackingToggleButton.PixelPosition = Vector2.Create(20, -20)
	TrackingToggleButton.BackgroundColour = Vector4.Create(0.2, 0.2, 0.2, 1)
	TrackingToggleButton.TextColour = Vector4.One
	TrackingToggleButton.BorderThickness = 3
	TrackingToggleButton.BorderColour = Vector4.One
	TrackingToggleButton.CornerRelativeRadius = 1
	TrackingToggleButton.BackgroundImage = Icons.Anchor
	TrackingToggleButton.BackgroundImageScale = 0.8
	TrackingToggleButton.Value = true
	TrackingToggleButton.Parent = LivestreamPage

	LivestreamFrame = UserInterface.VideoFrame.Create()
	LivestreamFrame.RelativeSize = Vector2.Create(1, 1)
	LivestreamFrame.PixelSize = Vector2.Create(0, -TrackingToggleButton.AbsoluteSize.Y - 40)
	LivestreamFrame.BackgroundImageScaleMode = Enum.ScaleMode.MaintainAspectRatio
	LivestreamFrame.BackgroundColour = Vector4.Create(0.2, 0.2, 0.2, 1)
	LivestreamFrame.Parent = LivestreamPage

	local SettingsPage = UserInterface.ScrollFrame.Create()
	SettingsPage.RelativeSize = Vector2.One
	SettingsPage.BackgroundColour = Vector4.Zero
	SettingsPage.Parent = AppPages

	AppPages:AddTransition(1, 2, Enum.PageTransitionDirection.Down)
	AppPages:AddTransition(1, 3, Enum.PageTransitionDirection.Left)

	AppPages:AddTransition(2, 1, Enum.PageTransitionDirection.Up)
	AppPages:AddTransition(2, 3, Enum.PageTransitionDirection.Left)

	AppPages:AddTransition(3, 1, Enum.PageTransitionDirection.Right)
	AppPages:AddTransition(3, 2, Enum.PageTransitionDirection.Right)

	AppPages.Events:Listen("PageSwitching", function(_, _, from, to, switched)
		if switched then
			if to == 1 then
				TitleLabel.Text = "Connection Details:"
			elseif to == 2 then
				TitleLabel.Text = "Livestream:"
			else
				TitleLabel.Text = "Settings:"
			end
		end
	end)

	appClient.Events:Listen("Disconnected", function()
		StopLivestream()

		AppPages.Page = 1
	end)
	
	appClient.Events:Listen("StopLivestream", StopLivestream)

	UserInterface.SetRoot(Root)

	Log.Info("Client", "Client ready")
end

function love.update(deltaTime)
	appClient:Update()
end

function love.draw()
	if livestreaming then
		if LivestreamFrame.FrameChanged then
			tracker:Update(LivestreamFrame.Video.Frame)
		end

		if tracker then
			local trackingShape = tracker.LargestMotionShape

			if trackingShape then
				appClient:Send("&IncrementServoAngle:%d!", 30*(trackingShape[1].X + trackingShape[2].X - 1))
			end
		end
	end
end

function love.quit(exitCode)
	StopLivestream()
	
	appClient:Destroy()

	for index, shader in pairs(Shaders) do
		Shaders[index] = nil
		shader:release()
	end

	Shaders = nil

	for index, image in pairs(Icons) do
		Icons[index] = nil
		image:release()
	end

	Icons = nil

	VideoReader.Deinitialize()

	Log.Info("Client", "Client stopping")
end