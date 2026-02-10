require("Setup")

socket = require("socket")
utf8 = require("utf8")

UserInterface = require("UserInterface")
libav = require("libav")

VideoReader = require("VideoReader")

NetworkClient = require("NetworkClient")

MotionTracker = require("MotionTracker")

local AppNetworkClient

local livestreaming

local motionTracker
local motionThreshold = 0.02

local function StartLivestream()
	if not livestreaming then
		local freePort = NetworkClient.GetFreePort()

		AppNetworkClient:Send({{"StartLivestream", freePort}})

		local livestream = VideoReader.CreateFromURL(
			"udp://"..AppNetworkClient:GetLocalDetails()..":"..freePort.."?timeout=10000000",
			"h264"
		)

		if livestream then
			motionTracker = MotionTracker.Create(
				livestream.Width, livestream.Height
			)

			LivestreamFrame.Video = livestream
			LivestreamFrame.Playing = true

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

		LivestreamFrame.Video:Destroy()
		LivestreamFrame.Video = nil

		CalibrationControlButton.Active = false

		LivestreamControlButton.Text = "Start"

		livestreaming = false
	end
end

function love.load()
	libav.avdevice.avdevice_register_all()

	AppNetworkClient = NetworkClient.Create()
	AppNetworkClient.Events:Listen("Disconnect", StopLivestream)
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
	HostEntry.RelativeCornerRadius = 1
	HostEntry.BorderThickness = 1
	HostEntry.Parent = ConnectionPage

	PortEntry = UserInterface.TextBox.Create()
	PortEntry.RelativeOrigin = Vector2.Create(0, 0.5)
	PortEntry.RelativeSize = Vector2.Create(0.4, 0.1)
	PortEntry.RelativePosition = Vector2.Create(0.5, 0.5)
	PortEntry.PixelPosition = Vector2.Create(5, 0)
	PortEntry.PlaceholderText = "Enter Port..."
	PortEntry.RelativeCornerRadius = 1
	PortEntry.BorderThickness = 1
	PortEntry.Parent = ConnectionPage

	ConnectButton = UserInterface.Button.Create()
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

	local LivestreamPage = UserInterface.Frame.Create()
	LivestreamPage.RelativeSize = Vector2.One
	LivestreamPage.Parent = AppPages

	LivestreamFrame = UserInterface.VideoFrame.Create()
	LivestreamFrame.RelativeSize = Vector2.Create(1, 1)
	LivestreamFrame.PixelSize = Vector2.Create(-20, -80)
	LivestreamFrame.PixelPosition = Vector2.Create(10, 10)
	LivestreamFrame.RelativeCornerRadius = 0.1
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
	ControlBar.RelativeCornerRadius = 1
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
	LeftControlButton.RelativeCornerRadius = 1
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
	TrackingControlButton.RelativeCornerRadius = 1
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
	LivestreamControlButton.RelativeCornerRadius = 1
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
	CalibrationControlButton.RelativeCornerRadius = 1
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
	RightControlButton.RelativeCornerRadius = 1
	RightControlButton.BorderThickness = 1
	RightControlButton.BackgroundColour = Vector4.Create(1, 1, 1, 1)
	RightControlButton.Parent = ControlBar

	local _CalibrationFrame = UserInterface.Frame.Create()
	_CalibrationFrame.RelativeSize = Vector2.One
	_CalibrationFrame.BackgroundColour = Vector4.Zero
	_CalibrationFrame.Parent = BottomBarPages

	local CalibrationFrame = UserInterface.Frame.Create()
	CalibrationFrame.AspectRatio = 6
	CalibrationFrame.DominantAxis = Enum.Axis.Y
	CalibrationFrame.RelativeOrigin = Vector2.Create(0.5, 0)
	CalibrationFrame.RelativeSize = Vector2.One
	CalibrationFrame.RelativePosition = Vector2.Create(0.5, 0)
	CalibrationFrame.BackgroundColour = Vector4.Zero
	CalibrationFrame.BorderThickness = 1
	CalibrationFrame.RelativeCornerRadius = 0.3
	CalibrationFrame.BackgroundColour = Vector4.One
	CalibrationFrame.Parent = _CalibrationFrame

	local HigherThresholdTitle = UserInterface.Label.Create()
	HigherThresholdTitle.RelativeOrigin = Vector2.Create(0.5, 0.5)
	HigherThresholdTitle.RelativeSize = Vector2.Create(1/3, 1/3)
	HigherThresholdTitle.RelativePosition = Vector2.Create(1/6, 1/6)
	HigherThresholdTitle.BackgroundColour = Vector4.Zero
	HigherThresholdTitle.Text = "Higher Threshold:"
	HigherThresholdTitle.Parent = CalibrationFrame

	HigherThresholdEntry = UserInterface.NumericTextBox.Create()
	HigherThresholdEntry.RelativeOrigin = Vector2.Create(0.5, 0.5)
	HigherThresholdEntry.RelativeSize = Vector2.Create(1/3 - 0.02, 1/3 - 0.02)
	HigherThresholdEntry.RelativePosition = Vector2.Create(1/6, 3/6 - 0.05)
	HigherThresholdEntry.PlaceholderText = "Enter threshold..."
	HigherThresholdEntry.Value = 0.3
	HigherThresholdEntry.Cursor = math.huge
	HigherThresholdEntry.BorderThickness = 1
	HigherThresholdEntry.RelativeCornerRadius = 1
	HigherThresholdEntry.Parent = CalibrationFrame

	local LowerThresholdTitle = UserInterface.Label.Create()
	LowerThresholdTitle.RelativeOrigin = Vector2.Create(0.5, 0.5)
	LowerThresholdTitle.RelativeSize = Vector2.Create(1/3, 1/3)
	LowerThresholdTitle.RelativePosition = Vector2.Create(3/6, 1/6)
	LowerThresholdTitle.BackgroundColour = Vector4.Zero
	LowerThresholdTitle.Text = "Lower Threshold:"
	LowerThresholdTitle.Parent = CalibrationFrame

	LowerThresholdEntry = UserInterface.NumericTextBox.Create()
	LowerThresholdEntry.RelativeOrigin = Vector2.Create(0.5, 0.5)
	LowerThresholdEntry.RelativeSize = Vector2.Create(1/3 - 0.02, 1/3 - 0.02)
	LowerThresholdEntry.RelativePosition = Vector2.Create(3/6, 3/6 - 0.05)
	LowerThresholdEntry.PlaceholderText = "Enter threshold..."
	LowerThresholdEntry.Value = 0.01
	LowerThresholdEntry.Cursor = math.huge
	LowerThresholdEntry.BorderThickness = 1
	LowerThresholdEntry.RelativeCornerRadius = 1
	LowerThresholdEntry.Parent = CalibrationFrame

	local MotionThresholdTitle = UserInterface.Label.Create()
	MotionThresholdTitle.RelativeOrigin = Vector2.Create(0.5, 0.5)
	MotionThresholdTitle.RelativeSize = Vector2.Create(1/3, 1/3)
	MotionThresholdTitle.RelativePosition = Vector2.Create(5/6, 1/6)
	MotionThresholdTitle.BackgroundColour = Vector4.Zero
	MotionThresholdTitle.Text = "Motion Threshold:"
	MotionThresholdTitle.Parent = CalibrationFrame

	MotionThresholdEntry = UserInterface.NumericTextBox.Create()
	MotionThresholdEntry.RelativeOrigin = Vector2.Create(0.5, 0.5)
	MotionThresholdEntry.RelativeSize = Vector2.Create(1/3 - 0.02, 1/3 - 0.02)
	MotionThresholdEntry.RelativePosition = Vector2.Create(5/6, 3/6 - 0.05)
	MotionThresholdEntry.PlaceholderText = "Enter threshold..."
	MotionThresholdEntry.Value = 0.02
	MotionThresholdEntry.Cursor = math.huge
	MotionThresholdEntry.BorderThickness = 1
	MotionThresholdEntry.RelativeCornerRadius = 1
	MotionThresholdEntry.Parent = CalibrationFrame

	local SaveCalibrationButton = UserInterface.Button.Create()
	SaveCalibrationButton.RelativeOrigin = Vector2.Create(0.5, 0)
	SaveCalibrationButton.RelativeSize = Vector2.Create(1/6, 1/3 - 0.06)
	SaveCalibrationButton.RelativePosition = Vector2.Create(3/12 + 0.06, 2/3)
	SaveCalibrationButton.Text = "Save"
	SaveCalibrationButton.BorderThickness = 1
	SaveCalibrationButton.RelativeCornerRadius = 1
	SaveCalibrationButton.Parent = CalibrationFrame

	SaveCalibrationButton.Events:Listen("Pressed", function()
		if motionTracker then
			motionTracker.HigherThreshold = HigherThresholdEntry.Value
			motionTracker.LowerThreshold = LowerThresholdEntry.Value
			motionThreshold = MotionThresholdEntry.Value
		end

		print(motionThreshold)
	end)

	local ResetCalibrationButton = UserInterface.Button.Create()
	ResetCalibrationButton.RelativeOrigin = Vector2.Create(0.5, 0)
	ResetCalibrationButton.RelativeSize = Vector2.Create(1/6, 1/3 - 0.06)
	ResetCalibrationButton.RelativePosition = Vector2.Create(6/12, 2/3)
	ResetCalibrationButton.Text = "Reset"
	ResetCalibrationButton.BorderThickness = 1
	ResetCalibrationButton.RelativeCornerRadius = 1
	ResetCalibrationButton.Parent = CalibrationFrame

	ResetCalibrationButton.Events:Listen("Pressed", function()
		HigherThresholdEntry.Value = 0.3
		HigherThresholdEntry.Cursor = math.huge

		LowerThresholdEntry.Value = 0.01
		LowerThresholdTitle.Cursor = math.huge

		MotionThresholdEntry.Value = 0.02
		MotionThresholdEntry.Cursor = math.huge
	end)

	local BackCalibrationButton = UserInterface.Button.Create()
	BackCalibrationButton.RelativeOrigin = Vector2.Create(0.5, 0)
	BackCalibrationButton.RelativeSize = Vector2.Create(1/6, 1/3 - 0.06)
	BackCalibrationButton.RelativePosition = Vector2.Create(9/12 - 0.06, 2/3)
	BackCalibrationButton.Text = "Back"
	BackCalibrationButton.BorderThickness = 1
	BackCalibrationButton.RelativeCornerRadius = 1
	BackCalibrationButton.Parent = CalibrationFrame

	BackCalibrationButton.Events:Listen("Pressed", function()
		BottomBarPages.Page = 1

		calibrationModeAnimation:Reset()
		calibrationModeAnimation.Reversed = true
		calibrationModeAnimation.Playing = true
	end)

	BottomBarPages:AddTransition(1, 2, Enum.PageTransitionDirection.Left)
	BottomBarPages:AddTransition(2, 1, Enum.PageTransitionDirection.Right)

	AppPages:AddTransition(1, 2, Enum.PageTransitionDirection.Down)

	UserInterface.SetRoot(Root)
end

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