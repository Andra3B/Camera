require("Setup")

socket = require("socket")
utf8 = require("utf8")

UserInterface = require("UserInterface")
libav = require("libav.libav")

VideoReader = require("VideoReader")

NetworkClient = require("NetworkClient")

MotionTracker = require("MotionTracker")

local AppNetworkClient

local livestreaming

local motionTracker

local calibratingMotionTracking = false

local function StartLivestream()
	if not livestreaming then
		local freePort = NetworkClient.GetFreePort()

		AppNetworkClient:Send({{"StartLivestream", freePort}})

		local livestream = VideoReader.CreateFromURL(
			"udp://"..AppNetworkClient:GetLocalDetails()..":"..freePort.."?timeout=5000000&fifo_size=1000000&overrun_nonfatal=1",
			"mpegts"
		)

		if livestream then
			motionTracker = MotionTracker.Create(livestream.Width, livestream.Height)

			LivestreamFrame.Video = livestream
			LivestreamFrame.Playing = true

			LivestreamFrame.VideoVisible = true
			LivestreamFrame.BackgroundImage = motionTracker.MotionMask

			CalibrationControlButton.Active = true

			LivestreamControlButton.Text = "Stop"

			livestreaming = true
		end
	end
end

local function StopLivestream()
	if livestreaming then
		AppNetworkClient:Send({{"StopLivestream"}})

		if motionTracker then
			motionTracker:Destroy()
			motionTracker = nil
		end
		
		calibratingMotionTracking = false
		trackerRelativePosition = nil

		LivestreamFrame.Video:Destroy()
		LivestreamFrame.Video = nil
		LivestreamFrame.BackgroundImage = nil

		CalibrationControlButton.Active = false

		LivestreamControlButton.Text = "Start"

		livestreaming = false
	end
end

function love.load()
	libav.avdevice.avdevice_register_all()

	AppNetworkClient = NetworkClient.Create()
	AppNetworkClient.Events:Listen("Disconnected", StopLivestream)
	AppNetworkClient:Bind()

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

	Root = UserInterface.Frame.Create()
	Root.RelativeSize = Vector2.One

	AppPages = UserInterface.Pages.Create()
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

	HostEntry = UserInterface.TextBox.Create()
	HostEntry.RelativeOrigin = Vector2.Create(1, 0.5)
	HostEntry.RelativeSize = Vector2.Create(0.4, 0.1)
	HostEntry.RelativePosition = Vector2.Create(0.5, 0.5)
	HostEntry.PixelPosition = Vector2.Create(-5, 0)
	HostEntry.PlaceholderText = "Enter Host..."
	HostEntry.CornerRelativeRadius = 1
	HostEntry.BorderThickness = 1
	HostEntry.Parent = ConnectionPage

	PortEntry = UserInterface.TextBox.Create()
	PortEntry.RelativeOrigin = Vector2.Create(0, 0.5)
	PortEntry.RelativeSize = Vector2.Create(0.4, 0.1)
	PortEntry.RelativePosition = Vector2.Create(0.5, 0.5)
	PortEntry.PixelPosition = Vector2.Create(5, 0)
	PortEntry.PlaceholderText = "Enter Port..."
	PortEntry.CornerRelativeRadius = 1
	PortEntry.BorderThickness = 1
	PortEntry.Parent = ConnectionPage

	ConnectButton = UserInterface.Button.Create()
	ConnectButton.RelativeOrigin = Vector2.Create(0.5, 0)
	ConnectButton.RelativeSize = Vector2.Create(0.8, 0.1)
	ConnectButton.PixelSize = Vector2.Create(10, 0)
	ConnectButton.RelativePosition = Vector2.Create(0.5, 0.55)
	ConnectButton.PixelPosition = Vector2.Create(0, 10)
	ConnectButton.CornerRelativeRadius = 1
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
	ErrorLabel.CornerRelativeRadius = 1
	ErrorLabel.Visible = false
	ErrorLabel.Parent = ConnectionPage

	ConnectButton.Events:Listen("Pressed", function()
		local host = HostEntry.Text
		local success, errorMessage = false, "Invalid host"

		if #host > 0 then
			success, errorMessage = AppNetworkClient:Connect(host, PortEntry.Text, 3)
		end

		if success then
			ErrorLabel.Visible = false
			AppPages.Page = 2
		else
			ErrorLabel.Text = errorMessage.."!"
			ErrorLabel.Visible = true
		end
	end)

	local SubPagesFrame = UserInterface.Frame.Create()
	SubPagesFrame.RelativeSize = Vector2.One
	SubPagesFrame.BackgroundColour = Vector4.Zero
	SubPagesFrame.Parent = AppPages

	local SubPages = UserInterface.Pages.Create()
	SubPages.RelativeSize = Vector2.Create(1, 1)
	SubPages.BackgroundColour = Vector4.Zero
	SubPages.Parent = SubPagesFrame
	
	local LivestreamPage = UserInterface.Frame.Create()
	LivestreamPage.RelativeSize = Vector2.One
	LivestreamPage.Parent = SubPages

	LivestreamFrame = UserInterface.VideoFrame.Create()
	LivestreamFrame.RelativeSize = Vector2.Create(1, 1)
	LivestreamFrame.PixelSize = Vector2.Create(-20, -140)
	LivestreamFrame.PixelPosition = Vector2.Create(10, 70)
	LivestreamFrame.CornerRelativeRadius = 0.1
	LivestreamFrame.BorderThickness = 1
	LivestreamFrame.BackgroundColour = Vector4.Create(1, 1, 1, 1)
	LivestreamFrame.BackgroundImageScaleMode = Enum.ScaleMode.MaintainAspectRatio
	LivestreamFrame.Parent = LivestreamPage

	local BottomBarPages = UserInterface.Pages.Create()
	BottomBarPages.RelativeOrigin = Vector2.Create(0, 1)
	BottomBarPages.RelativeSize = Vector2.Create(1, 0)
	BottomBarPages.PixelSize = Vector2.Create(0, 100)
	BottomBarPages.RelativePosition = Vector2.Create(0, 1)
	BottomBarPages.PixelPosition = Vector2.Create(0, -10)
	BottomBarPages.BackgroundColour = Vector4.Zero
	BottomBarPages.Parent = LivestreamPage

	local ControlFrame = UserInterface.Frame.Create()
	ControlFrame.RelativeSize = Vector2.One
	ControlFrame.BackgroundColour = Vector4.Zero
	ControlFrame.Parent = BottomBarPages
	
	local ControlBar = UserInterface.Frame.Create()
	ControlBar.AspectRatio = 6
	ControlBar.DominantAxis = Enum.Axis.Y
	ControlBar.RelativeOrigin = Vector2.Create(0.5, 0)
	ControlBar.RelativeSize = Vector2.Create(1, 0.5)
	ControlBar.RelativePosition = Vector2.Create(0.5, 0.5)
	ControlBar.CornerRelativeRadius = 1
	ControlBar.BorderThickness = 1
	ControlBar.BackgroundColour = Vector4.Create(0, 0, 0, 0.2)
	ControlBar.Parent = ControlFrame

	LeftControlButton = UserInterface.Button.Create()
	LeftControlButton.AspectRatio = 1
	LeftControlButton.DominantAxis = Enum.Axis.Y
	LeftControlButton.RelativeOrigin = Vector2.Create(0.5, 0.5)
	LeftControlButton.RelativeSize = Vector2.Create(0.8, 0.8)
	LeftControlButton.RelativePosition = Vector2.Create(1/12, 0.5)
	LeftControlButton.Text = "<"
	LeftControlButton.CornerRelativeRadius = 1
	LeftControlButton.BorderThickness = 1
	LeftControlButton.BackgroundColour = Vector4.Create(1, 1, 1, 1)
	LeftControlButton.Parent = ControlBar

	TrackingControlButton = UserInterface.Button.Create()
	TrackingControlButton.AspectRatio = 1
	TrackingControlButton.DominantAxis = Enum.Axis.Y
	TrackingControlButton.RelativeOrigin = Vector2.Create(0.5, 0.5)
	TrackingControlButton.RelativeSize = Vector2.Create(0.8, 0.8)
	TrackingControlButton.RelativePosition = Vector2.Create(3/12, 0.5)
	TrackingControlButton.Text = "MT"
	TrackingControlButton.CornerRelativeRadius = 1
	TrackingControlButton.BorderThickness = 1
	TrackingControlButton.BackgroundColour = Vector4.Create(1, 1, 1, 1)
	TrackingControlButton.Parent = ControlBar

	LivestreamControlButton = UserInterface.Button.Create()
	LivestreamControlButton.AspectRatio = 2.1
	LivestreamControlButton.DominantAxis = Enum.Axis.Y
	LivestreamControlButton.RelativeOrigin = Vector2.Create(0.5, 0.5)
	LivestreamControlButton.RelativeSize = Vector2.Create(1, 0.8)
	LivestreamControlButton.RelativePosition = Vector2.Create(0.5, 0.5)
	LivestreamControlButton.Text = "Start"
	LivestreamControlButton.CornerRelativeRadius = 1
	LivestreamControlButton.BorderThickness = 1
	LivestreamControlButton.BackgroundColour = Vector4.Create(1, 1, 1, 1)
	LivestreamControlButton.Parent = ControlBar

	LivestreamControlButton.Events:Listen("Pressed", function()
		if livestreaming then
			StopLivestream()
		else
			StartLivestream()
		end
	end)

	CalibrationControlButton = UserInterface.Button.Create()
	CalibrationControlButton.AspectRatio = 1
	CalibrationControlButton.DominantAxis = Enum.Axis.Y
	CalibrationControlButton.RelativeOrigin = Vector2.Create(0.5, 0.5)
	CalibrationControlButton.RelativeSize = Vector2.Create(0.8, 0.8)
	CalibrationControlButton.RelativePosition = Vector2.Create(9/12, 0.5)
	CalibrationControlButton.Text = "C"
	CalibrationControlButton.CornerRelativeRadius = 1
	CalibrationControlButton.BorderThickness = 1
	CalibrationControlButton.BackgroundColour = Vector4.Create(1, 1, 1, 1)
	CalibrationControlButton.Active = false
	CalibrationControlButton.Parent = ControlBar

	local calibrationModeAnimation = Animation.Create(
		LivestreamFrame, "PixelSize",
		LivestreamFrame.PixelSize, LivestreamFrame.PixelSize - Vector2.Create(0, 50),
		1, Enum.AnimationType.SharpSmoothStep, false
	)

	CalibrationControlButton.Events:Listen("Pressed", function()
		BottomBarPages.Page = 2

		calibrationModeAnimation:Reset()
		calibrationModeAnimation.Reversed = false
		calibrationModeAnimation.Playing = true
	end)

	local RightControlButton = UserInterface.Button.Create()
	RightControlButton.AspectRatio = 1
	RightControlButton.DominantAxis = Enum.Axis.Y
	RightControlButton.RelativeOrigin = Vector2.Create(0.5, 0.5)
	RightControlButton.RelativeSize = Vector2.Create(0.8, 0.8)
	RightControlButton.RelativePosition = Vector2.Create(11/12, 0.5)
	RightControlButton.Text = ">"
	RightControlButton.CornerRelativeRadius = 1
	RightControlButton.BorderThickness = 1
	RightControlButton.BackgroundColour = Vector4.Create(1, 1, 1, 1)
	RightControlButton.Parent = ControlBar

	local _CalibrationFrame = UserInterface.Frame.Create()
	_CalibrationFrame.RelativeSize = Vector2.One
	_CalibrationFrame.BackgroundColour = Vector4.Zero
	_CalibrationFrame.Parent = BottomBarPages

	local CalibrationFrame = UserInterface.Frame.Create()
	CalibrationFrame.RelativeSize = Vector2.Create(1, 0.5)
	CalibrationFrame.BackgroundColour = Vector4.Zero
	CalibrationFrame.Parent = _CalibrationFrame

	local CalibrationButtonFrame = UserInterface.Frame.Create()
	CalibrationButtonFrame.RelativeSize = Vector2.Create(1, 0.5)
	CalibrationButtonFrame.RelativePosition = Vector2.Create(0, 0.5)
	CalibrationButtonFrame.BackgroundColour = Vector4.Zero
	CalibrationButtonFrame.Parent = _CalibrationFrame

	local MotionThresholdTitle = UserInterface.Label.Create()
	MotionThresholdTitle.RelativeSize = Vector2.Create(0.2, 0.5)
	MotionThresholdTitle.BackgroundColour = Vector4.Zero
	MotionThresholdTitle.Text = "Motion Threshold:"
	MotionThresholdTitle.Parent = CalibrationFrame

	MotionThresholdEntry = UserInterface.NumericTextBox.Create()
	MotionThresholdEntry.RelativeOrigin = Vector2.Create(0.5, 1)
	MotionThresholdEntry.RelativeSize = Vector2.Create(0.175, 0.5)
	MotionThresholdEntry.RelativePosition = Vector2.Create(0.1, 1)
	MotionThresholdEntry.PlaceholderText = "Enter threshold..."
	MotionThresholdEntry.Value = 0.12
	MotionThresholdEntry.Cursor = math.huge
	MotionThresholdEntry.BorderThickness = 1
	MotionThresholdEntry.CornerRelativeRadius = 1
	MotionThresholdEntry.Parent = CalibrationFrame

	local ShapeMinimumAreaTitle = UserInterface.Label.Create()
	ShapeMinimumAreaTitle.RelativeSize = Vector2.Create(0.2, 0.5)
	ShapeMinimumAreaTitle.RelativePosition = Vector2.Create(0.2, 0)
	ShapeMinimumAreaTitle.BackgroundColour = Vector4.Zero
	ShapeMinimumAreaTitle.Text = "Shape Minimum Area:"
	ShapeMinimumAreaTitle.Parent = CalibrationFrame

	ShapeMinimumAreaEntry = UserInterface.NumericTextBox.Create()
	ShapeMinimumAreaEntry.RelativeOrigin = Vector2.Create(0.5, 1)
	ShapeMinimumAreaEntry.RelativeSize = Vector2.Create(0.175, 0.5)
	ShapeMinimumAreaEntry.RelativePosition = Vector2.Create(0.3, 1)
	ShapeMinimumAreaEntry.PlaceholderText = "Enter area..."
	ShapeMinimumAreaEntry.Value = 0.03
	ShapeMinimumAreaEntry.Cursor = math.huge
	ShapeMinimumAreaEntry.BorderThickness = 1
	ShapeMinimumAreaEntry.CornerRelativeRadius = 1
	ShapeMinimumAreaEntry.Parent = CalibrationFrame

	local ShapeSearchRadiusTitle = UserInterface.Label.Create()
	ShapeSearchRadiusTitle.RelativeSize = Vector2.Create(0.2, 0.5)
	ShapeSearchRadiusTitle.RelativePosition = Vector2.Create(0.4, 0)
	ShapeSearchRadiusTitle.BackgroundColour = Vector4.Zero
	ShapeSearchRadiusTitle.Text = "Shape Search Radius:"
	ShapeSearchRadiusTitle.Parent = CalibrationFrame

	ShapeSearchRadiusEntry = UserInterface.NumericTextBox.Create()
	ShapeSearchRadiusEntry.RelativeOrigin = Vector2.Create(0.5, 1)
	ShapeSearchRadiusEntry.RelativeSize = Vector2.Create(0.175, 0.5)
	ShapeSearchRadiusEntry.RelativePosition = Vector2.Create(0.5, 1)
	ShapeSearchRadiusEntry.PlaceholderText = "Enter radius..."
	ShapeSearchRadiusEntry.Value = 7
	ShapeSearchRadiusEntry.Minimum = 1
	ShapeSearchRadiusEntry.Maximum = math.huge
	ShapeSearchRadiusEntry.Cursor = math.huge
	ShapeSearchRadiusEntry.BorderThickness = 1
	ShapeSearchRadiusEntry.CornerRelativeRadius = 1
	ShapeSearchRadiusEntry.Parent = CalibrationFrame

	local AdaptionRateTitle = UserInterface.Label.Create()
	AdaptionRateTitle.RelativeSize = Vector2.Create(0.2, 0.5)
	AdaptionRateTitle.RelativePosition = Vector2.Create(0.6, 0)
	AdaptionRateTitle.BackgroundColour = Vector4.Zero
	AdaptionRateTitle.Text = "Adaption Rate:"
	AdaptionRateTitle.Parent = CalibrationFrame

	AdaptionRateEntry = UserInterface.NumericTextBox.Create()
	AdaptionRateEntry.RelativeOrigin = Vector2.Create(0.5, 1)
	AdaptionRateEntry.RelativeSize = Vector2.Create(0.175, 0.5)
	AdaptionRateEntry.RelativePosition = Vector2.Create(0.7, 1)
	AdaptionRateEntry.PlaceholderText = "Enter rate..."
	AdaptionRateEntry.Value = 0.1
	AdaptionRateEntry.Cursor = math.huge
	AdaptionRateEntry.BorderThickness = 1
	AdaptionRateEntry.CornerRelativeRadius = 1
	AdaptionRateEntry.Parent = CalibrationFrame

	local SubdivisionsTitle = UserInterface.Label.Create()
	SubdivisionsTitle.RelativeSize = Vector2.Create(0.2, 0.5)
	SubdivisionsTitle.RelativePosition = Vector2.Create(0.8, 0)
	SubdivisionsTitle.BackgroundColour = Vector4.Zero
	SubdivisionsTitle.Text = "Subdivisions:"
	SubdivisionsTitle.Parent = CalibrationFrame

	SubdivisionsEntry = UserInterface.NumericTextBox.Create()
	SubdivisionsEntry.RelativeOrigin = Vector2.Create(0.5, 1)
	SubdivisionsEntry.RelativeSize = Vector2.Create(0.175, 0.5)
	SubdivisionsEntry.RelativePosition = Vector2.Create(0.9, 1)
	SubdivisionsEntry.PlaceholderText = "Enter subdivisions..."
	SubdivisionsEntry.Value = 6
	SubdivisionsEntry.Minimum = 0
	SubdivisionsEntry.Maximum = math.huge
	SubdivisionsEntry.Cursor = math.huge
	SubdivisionsEntry.BorderThickness = 1
	SubdivisionsEntry.CornerRelativeRadius = 1
	SubdivisionsEntry.Parent = CalibrationFrame

	local SaveCalibrationButton = UserInterface.Button.Create()
	SaveCalibrationButton.RelativeOrigin = Vector2.Create(0.5, 0.5)
	SaveCalibrationButton.RelativeSize = Vector2.Create(0.175, 0.5)
	SaveCalibrationButton.RelativePosition = Vector2.Create(0.3, 0.5)
	SaveCalibrationButton.Text = "Save"
	SaveCalibrationButton.BorderThickness = 1
	SaveCalibrationButton.CornerRelativeRadius = 1
	SaveCalibrationButton.Parent = CalibrationButtonFrame

	SaveCalibrationButton.Events:Listen("Pressed", function()
		if calibratingMotionTracking then
			LivestreamFrame.VideoVisible = true

			motionTracker.MotionThreshold = MotionThresholdEntry.Value
			motionTracker.ShapeMinimumArea = ShapeMinimumAreaEntry.Value
			motionTracker.ShapeSearchRadius = ShapeSearchRadiusEntry.Value
			motionTracker.AdaptionRate = AdaptionRateEntry.Value
			motionTracker.Subdivisions = SubdivisionsEntry.Value
		end
	end)

	local ResetCalibrationButton = UserInterface.Button.Create()
	ResetCalibrationButton.RelativeOrigin = Vector2.Create(0.5, 0.5)
	ResetCalibrationButton.RelativeSize = Vector2.Create(0.175, 0.5)
	ResetCalibrationButton.RelativePosition = Vector2.Create(0.5, 0.5)
	ResetCalibrationButton.Text = "Reset"
	ResetCalibrationButton.BorderThickness = 1
	ResetCalibrationButton.CornerRelativeRadius = 1
	ResetCalibrationButton.Parent = CalibrationButtonFrame

	ResetCalibrationButton.Events:Listen("Pressed", function()
		MotionThresholdEntry.Value = 0.12
		MotionThresholdEntry.Cursor = math.huge

		ShapeMinimumAreaEntry.Value = 0.03
		ShapeMinimumAreaEntry.Cursor = math.huge

		ShapeSearchRadiusEntry.Value = 7
		ShapeSearchRadiusEntry.Cursor = math.huge

		AdaptionRateEntry.Value = 0.1
		AdaptionRateEntry.Cursor = math.huge

		SubdivisionsEntry.Value = 6
		SubdivisionsEntry.Cursor = math.huge
	end)

	local BackCalibrationButton = UserInterface.Button.Create()
	BackCalibrationButton.RelativeOrigin = Vector2.Create(0.5, 0.5)
	BackCalibrationButton.RelativeSize = Vector2.Create(0.175, 0.5)
	BackCalibrationButton.RelativePosition = Vector2.Create(0.7, 0.5)
	BackCalibrationButton.Text = "Back"
	BackCalibrationButton.BorderThickness = 1
	BackCalibrationButton.CornerRelativeRadius = 1
	BackCalibrationButton.Parent = CalibrationButtonFrame

	BackCalibrationButton.Events:Listen("Pressed", function()
		BottomBarPages.Page = 1

		calibrationModeAnimation:Reset()
		calibrationModeAnimation.Reversed = true
		calibrationModeAnimation.Playing = true
	end)

	NoMotionLabel = UserInterface.Label.Create()
	NoMotionLabel.AspectRatio = 5
	NoMotionLabel.DominantAxis = Enum.Axis.Y
	NoMotionLabel.RelativeOrigin = Vector2.Create(0.5, 0.5)
	NoMotionLabel.RelativeSize = Vector2.Create(1, 0.1)
	NoMotionLabel.RelativePosition = Vector2.Create(0.5, 0.5)
	NoMotionLabel.Text = "No Motion"
	NoMotionLabel.TextColour = Vector4.Create(1, 0, 0, 1)
	NoMotionLabel.Font = UserInterface.Font.FreeSansBold
	NoMotionLabel.CornerRelativeRadius = 1
	NoMotionLabel.BackgroundColour = Vector4.Create(0.6, 0.6, 0.6, 0.5)
	NoMotionLabel.BorderThickness = 1
	NoMotionLabel.Visible = false
	NoMotionLabel.Parent = LivestreamFrame

	MotionMaskButton = UserInterface.Button.Create()
	MotionMaskButton.AspectRatio = 1
	MotionMaskButton.DominantAxis = Enum.Axis.Y
	MotionMaskButton.RelativeOrigin = Vector2.Create(1, 0)
	MotionMaskButton.RelativeSize = Vector2.Create(1, 0.08)
	MotionMaskButton.RelativePosition = Vector2.Create(1, 0)
	MotionMaskButton.PixelPosition = Vector2.Create(-10, 10)
	MotionMaskButton.Text = "MM"
	MotionMaskButton.CornerRelativeRadius = 1
	MotionMaskButton.BorderThickness = 1
	MotionMaskButton.BackgroundColour = Vector4.Create(1, 1, 1, 1)
	MotionMaskButton.Visible = false
	MotionMaskButton.Parent = LivestreamFrame

	MotionMaskButton.Events:Listen("Pressed", function()
		LivestreamFrame.BackgroundImage = motionTracker.MotionMask
		LivestreamFrame.VideoVisible = not LivestreamFrame.VideoVisible
	end)

	BackgroundButton = UserInterface.Button.Create()
	BackgroundButton.AspectRatio = 1
	BackgroundButton.DominantAxis = Enum.Axis.Y
	BackgroundButton.RelativeOrigin = Vector2.Create(1, 1)
	BackgroundButton.RelativeSize = Vector2.Create(1, 0.08)
	BackgroundButton.RelativePosition = Vector2.Create(1, 1)
	BackgroundButton.PixelPosition = Vector2.Create(-10, -10)
	BackgroundButton.Text = "B"
	BackgroundButton.CornerRelativeRadius = 1
	BackgroundButton.BorderThickness = 1
	BackgroundButton.BackgroundColour = Vector4.Create(1, 1, 1, 1)
	BackgroundButton.Visible = false
	BackgroundButton.Parent = LivestreamFrame

	BackgroundButton.Events:Listen("Pressed", function()
		LivestreamFrame.BackgroundImage = motionTracker.Background
		LivestreamFrame.VideoVisible = not LivestreamFrame.VideoVisible
	end)

	BottomBarPages.Events:Listen("PageSwitching", function(from, to, switched)
		if livestreaming then
			if to == 2 then
				if switched then
					calibratingMotionTracking = true
					MotionMaskButton.Visible = true
					BackgroundButton.Visible = true
				end
			elseif from == 2 then
				if not switched then
					calibratingMotionTracking = false
					MotionMaskButton.Visible = false
					BackgroundButton.Visible = false
				end
			end
		end
	end)

	BottomBarPages:AddTransition(1, 2, Enum.PageTransitionDirection.Left)
	BottomBarPages:AddTransition(2, 1, Enum.PageTransitionDirection.Right)

	local SettingsPage = UserInterface.Frame.Create()
	SettingsPage.RelativeSize = Vector2.One
	SettingsPage.Parent = SubPages

	local TopBar = UserInterface.Button.Create()
	TopBar.RelativeOrigin = Vector2.Create(0.5, 0)
	TopBar.PixelSize = Vector2.Create(320, 50)
	TopBar.RelativePosition = Vector2.Create(0.5, 0)
	TopBar.PixelPosition = Vector2.Create(0, 10)
	TopBar.CornerRelativeRadius = 1
	TopBar.BorderThickness = 1
	TopBar.BackgroundColour = Vector4.Create(0, 0, 0, 0.2)
	TopBar.FocusedBackgroundColour = TopBar.BackgroundColour
	TopBar.HoveringBackgroundColour = TopBar.BackgroundColour
	TopBar.PressedBackgroundColour = TopBar.BackgroundColour
	TopBar.InactiveOverlayColour = TopBar.BackgroundColour
	TopBar.Parent = SubPagesFrame

	local LivestreamPageButton = UserInterface.Button.Create()
	LivestreamPageButton.RelativeOrigin = Vector2.Create(0, 0.5)
	LivestreamPageButton.RelativeSize = Vector2.Create(0.4, 0.8)
	LivestreamPageButton.RelativePosition = Vector2.Create(0.02, 0.5)
	LivestreamPageButton.Text = "Livestream"
	LivestreamPageButton.CornerRelativeRadius = 1
	LivestreamPageButton.BorderThickness = 1
	LivestreamPageButton.BackgroundColour = Vector4.Create(1, 1, 1, 1)
	LivestreamPageButton.Parent = TopBar

	LivestreamPageButton.Events:Listen("Pressed", function()
		SubPages.Page = 1
	end)
	
	local SettingsPageButton = UserInterface.Button.Create()
	SettingsPageButton.RelativeOrigin = Vector2.Create(0.5, 0.5)
	SettingsPageButton.RelativeSize = Vector2.Create(0.4, 0.8)
	SettingsPageButton.RelativePosition = Vector2.Create(0.64, 0.5)
	SettingsPageButton.Text = "Settings"
	SettingsPageButton.CornerRelativeRadius = 1
	SettingsPageButton.BorderThickness = 1
	SettingsPageButton.BackgroundColour = Vector4.Create(1, 1, 1, 1)
	SettingsPageButton.Parent = TopBar

	SettingsPageButton.Events:Listen("Pressed", function()
		SubPages.Page = 2
	end)

	local DisconnectButton = UserInterface.Button.Create()
	DisconnectButton.AspectRatio = 1
	DisconnectButton.DominantAxis = Enum.Axis.Y
	DisconnectButton.RelativeOrigin = Vector2.Create(1, 0.5)
	DisconnectButton.RelativeSize = Vector2.Create(0.8, 0.8)
	DisconnectButton.RelativePosition = Vector2.Create(0.98, 0.5)
	DisconnectButton.Text = "X"
	DisconnectButton.CornerRelativeRadius = 1
	DisconnectButton.BorderThickness = 1
	DisconnectButton.BackgroundColour = Vector4.Create(1, 1, 1, 1)
	DisconnectButton.Parent = TopBar

	DisconnectButton.Events:Listen("Pressed", function()
		StopLivestream()

		AppNetworkClient:Disconnect()

		AppPages.Page = 1
	end)

	local SettingsScrollFrame = UserInterface.ScrollFrame.Create()
	SettingsScrollFrame.RelativeSize = Vector2.Create(1, 1)
	SettingsScrollFrame.PixelSize = Vector2.Create(-20, -80)
	SettingsScrollFrame.PixelPosition = Vector2.Create(10, 70)
	SettingsScrollFrame.BorderThickness = 1
	SettingsScrollFrame.CornerRelativeRadius = 0.1
	SettingsScrollFrame.BackgroundColour = Vector4.One
	SettingsScrollFrame.Parent = SettingsPage

	SubPages:AddTransition(1, 2, Enum.PageTransitionDirection.Left)
	SubPages:AddTransition(2, 1, Enum.PageTransitionDirection.Right)

	AppPages:AddTransition(1, 2, Enum.PageTransitionDirection.Down)
	AppPages:AddTransition(2, 1, Enum.PageTransitionDirection.Up)

	FPSLabel = UserInterface.Label.Create()
	FPSLabel.RelativeSize = Vector2.Create(0.2, 0.1)
	FPSLabel.BackgroundColour = Vector4.Zero
	FPSLabel.Parent = Root

	UserInterface.SetRoot(Root)
end

function love.update(deltaTime)
	AppNetworkClient:Update()
	Timer.Update(deltaTime)
	Animation.Update(deltaTime)

	FPSLabel.Text = string.format("FPS: %d", love.timer.getFPS())
	
	NoMotionLabel.Visible = calibratingMotionTracking and #motionTracker.MotionShapes == 0

	UserInterface.Update(deltaTime)
end

function love.draw()
	UserInterface.Draw()

	if livestreaming then
		if LivestreamFrame.FrameChanged then
			motionTracker:Update(LivestreamFrame.VideoImage)
		end
		
		if calibratingMotionTracking then
			local absolutePosition = LivestreamFrame.BackgroundImageAbsolutePosition
			local absoluteSize = LivestreamFrame.BackgroundImageAbsoluteSize

			love.graphics.setLineWidth(3)

			for index, shape in pairs(motionTracker.MotionShapes) do
				local topLeft, bottomRight = unpack(shape)
				
				if index == motionTracker.LargestMotionShape then
					love.graphics.setColor(0, 0, 1, 1)
				else
					love.graphics.setColor(0, 1, 0, 1)
				end

				love.graphics.rectangle(
					"line",
					absolutePosition.X + absoluteSize.X*topLeft.X,
					absolutePosition.Y + absoluteSize.Y*topLeft.Y,
					absoluteSize.X*(bottomRight.X - topLeft.X),
					absoluteSize.Y*(bottomRight.Y - topLeft.Y)
				)
			end
		end
	end
		
	love.graphics.present()
end

function love.quit(exitCode)
	StopLivestream()

	UserInterface.Deinitialise()
	Animation.DestroyAllAnimations()
	Timer.DestroyAllTimers()
	AppNetworkClient:Destroy()
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