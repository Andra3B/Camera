libav = require("libav.libav")
VideoReader = require("VideoReader")

MotionTracker = require("MotionTracker")

local appClient = nil

local tracker = nil
local tracking = false

local trackingCooldownTimer = nil
local trackingCooldown = false

local settingsString = nil
local settings = {}

local function StartLivestream()
	if not LivestreamFrame.Video then
		local freePort = NetworkClient.GetFreePort()

		appClient:Send("&StartLivestream:%d!", freePort)

		LivestreamFrame.Video = VideoReader.Create(
			"udp://"..appClient:GetLocalDetails()..":"..freePort.."?fifo_size=1000000&overrun_nonfatal=1",
			"mpegts",
			1280, 720,
			"-fflags nobuffer -flags low_delay -probesize 32 -analyzeduration 0 -timeout "..(settings.Client.NetworkTimeout * 1000000),
			""
		)
		
		tracker = MotionTracker.Create(1280, 720)

		if settings.Client.ViewMode == "MotionMask" then
			LivestreamFrame.BackgroundImage = tracker.MotionMask
			LivestreamFrame.VideoVisible = false
		elseif settings.Client.ViewMode == "Background" then
			LivestreamFrame.BackgroundImage = tracker.Background
			LivestreamFrame.VideoVisible = false
		else
			LivestreamFrame.VideoVisible = true
		end

		tracker.MotionThreshold = settings.Camera.MotionThreshold
		tracker.ShapeMinimumArea = settings.Camera.ShapeMinimumArea
		tracker.ShapeSearchRadius = settings.Camera.ShapeSearchRadius
		tracker.AdaptionRate = settings.Camera.AdaptionRate
		tracker.Subdivisions = settings.Camera.Subdivisions

		LivestreamButton.Text = "STOP"

		LivestreamFrame.Playing = true
	end
end

local function StopLivestream()
	if LivestreamFrame.Video then
		appClient:Send("&StopLivestream!")

		tracker:Destroy()
		tracker = nil
		
		LivestreamFrame.Video:Destroy()
		LivestreamFrame.Video = nil

		LivestreamButton.Text = "START"
	end
end

local function SetSetting(name, value, clientSetting)
	local _settings = settings[clientSetting and "Client" or "Camera"]
	_settings[name] = value

	local valueType = type(value)

	if clientSetting then
		if name == "IdleTime" then
			appClient.IdleTime = value
		elseif name == "PingPeriod" then
			appClient.PingPeriod = value
		elseif LivestreamFrame.Video then
			if name == "ViewMode" then
				if value == "MotionMask" then
					LivestreamFrame.BackgroundImage = tracker.MotionMask
					LivestreamFrame.VideoVisible = false
				elseif value == "Background" then
					LivestreamFrame.BackgroundImage = tracker.Background
					LivestreamFrame.VideoVisible = false
				else
					LivestreamFrame.BackgroundImage = nil
					LivestreamFrame.VideoVisible = true
				end
			end
		end

		if valueType == "number" then
			_settings[name] = tonumber(value)

			settingsString = string.gsub(
				settingsString,
				"&"..name..":Number,(.-),(.-),(.-),.-!",
				"&"..name..":Number,%1,%2,%3,"..value.."!"
			)
		elseif valueType == "boolean" then
			_settings[name] = value == "true"

			settingsString = string.gsub(
				settingsString,
				"&"..name..":Boolean,.-!",
				"&"..name..":Boolean,"..tostring(value).."!"
			)
		elseif valueType == "string" then
			_settings[name] = value

			settingsString = string.gsub(
				settingsString,
				"&"..name..":String,(.-),.-!",
				"&"..name..":String,%1,"..value.."!"
			)
		end
	else
		if LivestreamFrame.Video then
			if name == "MotionThreshold" then
				tracker.MotionThreshold = tonumber(value)
			elseif name == "ShapeMinimumArea" then
				tracker.ShapeMinimumArea = tonumber(value)
			elseif name == "ShapeSearchRadius" then
				tracker.ShapeSearchRadius = tonumber(value)
			elseif name == "AdaptionRate" then
				tracker.AdaptionRate = tonumber(value)
			elseif name == "Subdivisions" then
				tracker.Subdivisions = tonumber(value)
			end
		end
		
		appClient:Send("&SetSetting:"..name..","..tostring(value)..","..valueType.."!")
	end
end

local function RefreshSettings(_settingsString)
	settings.Client = {}
	settings.Camera = {}

	SettingsPage.Container:DestroyChildren()

	local clientSetting = nil
	local nextPosition = Vector2.Create(0, 0)

	for line in string.gmatch(_settingsString, "[^\n]*") do
		if string.sub(line, -1) ~= "!" then
			line = string.sub(line, 1, -2)
		end

		local firstCharacter = string.sub(line, 1, 1)

		if firstCharacter == "[" then
			local text = string.match(line, "[^%[%]]+")
			
			if text then
				local titleLabel = nil

				if string.sub(line, 2, 2) == "[" then
					if string.sub(line, 3, 3) == "[" then
						titleLabel = UserInterface.Label.Create(SettingsLabelTemplateFour)
					else
						titleLabel = UserInterface.Label.Create(SettingsLabelTemplateTwo)
						text = text..":"
					end
				else
					clientSetting = text == "Client"

					titleLabel = UserInterface.Label.Create(SettingsLabelTemplateOne)
					text = text..":"
				end

				titleLabel.Text = text
				titleLabel.PixelPosition = nextPosition
				titleLabel.Visible = true
				titleLabel.Parent = SettingsPage.Container

				nextPosition = nextPosition + Vector2.Create(0, titleLabel.AbsoluteSize.Y)
			end
		elseif clientSetting ~= nil and firstCharacter == "&" then
			local settingDetails = NetworkClient.GetCommandsFromString(line)

			if settingDetails then
				settingDetails = settingDetails[1]

				local settingName = settingDetails[1]
				local settingEntry = nil

				if settingDetails[2] == "Number" then
					local min, max, value = tonumber(settingDetails[4]), tonumber(settingDetails[5]), tonumber(settingDetails[6])
					
					if min and max and value then
						settingEntry = UserInterface.NumericTextBox.Create(SettingsNumberTemplate)
						settingEntry.Name = settingName
						settingEntry.PlaceholderText = settingDetails[3]
						settingEntry.Minimum = min
						settingEntry.Maximum = max
						settingEntry.Value = value
						settingEntry.Cursor = math.huge
						
						settingEntry.Events:Listen("Submit", function(self, clientSetting, value)
							SetSetting(self.Name, value, clientSetting)
						end, clientSetting)
						
						SetSetting(settingName, tonumber(value), clientSetting)
					else
						goto End
					end
				elseif settingDetails[2] == "Boolean" then
					settingEntry = UserInterface.ToggleButton.Create(SettingsBooleanTemplate)
					settingEntry.Name = settingName
					settingEntry.Value = settingDetails[3] == "true"

					settingEntry.Events:Listen("ValueChanged", function(self, clientSetting, value)
						SetSetting(self.Name, value, clientSetting)
					end, clientSetting)
					
					SetSetting(settingName, settingEntry.Value, clientSetting)
				elseif settingDetails[2] == "String" then
					settingEntry = UserInterface.TextBox.Create(SettingsStringTemplate)
					settingEntry.Name = settingName
					settingEntry.PlaceholderText = settingDetails[3]
					settingEntry.Text = settingDetails[4]
					settingEntry.Cursor = math.huge

					settingEntry.Events:Listen("Submit", function(self, clientSetting, value)
						SetSetting(self.Name, value, clientSetting)
					end, clientSetting)
					
					SetSetting(settingName, settingDetails[4], clientSetting)
				else
					goto End
				end
				
				local settingLabel = UserInterface.Label.Create(SettingsLabelTemplateThree)
				settingLabel.Text = settingName
				settingLabel.PixelPosition = nextPosition
				settingLabel.Visible = true
				settingLabel.Parent = SettingsPage.Container

				settingEntry.PixelPosition = nextPosition + Vector2.Create(settingLabel.AbsoluteSize.X + 10, 0)
				settingEntry.Visible = true
				settingEntry.Parent = SettingsPage.Container

				nextPosition = nextPosition + Vector2.Create(0, settingLabel.AbsoluteSize.Y)
				::End::
			end
		end
	end
end

local function SaveSettings()
	local success, errorMessage = nil, nil
	local retry = 0

	repeat
		success, errorMessage = love.filesystem.write("Settings.txt", settingsString)
		retry = retry + 1
	until success or retry > 3

	if not success then
		Log.Error("Camera", "Failed to save settings to file! %s", errorMessage)
	end
end

function love.load()
	if not love.filesystem.getInfo("Settings.txt", "file") then
		local settingsString = love.filesystem.read("Assets/Other/DefaultClientSettings.txt")

		if settingsString then
			love.filesystem.write("Settings.txt", settingsString)
		end
	end

	local clientSettingsString, errorMessage = love.filesystem.read("Settings.txt")

	if not clientSettingsString then
		error("Failed to read settings file! "..errorMessage)
	end

	settingsString = clientSettingsString

	trackingCooldownTimer = Timer.Create(1.5, false)
	trackingCooldownTimer.Events:Listen("TimerElapsed", function()
		trackingCooldown = false
	end)

	appClient = NetworkClient.Create()
	appClient:Bind()

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
		["Box"] = love.graphics.newImage("Assets/Images/Icons/Box.png"),
		["Sliders"] = love.graphics.newImage("Assets/Images/Icons/Sliders.png"),
		["Check"] = love.graphics.newImage("Assets/Images/Icons/Check.png")
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
	CameraAddressEntry.PlaceholderText = "Enter camera address (hostname:port)"
	CameraAddressEntry.PlaceholderTextColour = Vector4.Create(1, 1, 1, 0.5)
	CameraAddressEntry.BackgroundColour = Vector4.Create(1, 1, 1, 0.1)
	CameraAddressEntry.TextColour = Vector4.One
	CameraAddressEntry.CornerPixelRadius = 10
	CameraAddressEntry.Parent = ConnectionPage

	local ConnectionErrorLabel = UserInterface.Label.Create()
	ConnectionErrorLabel.RelativeOrigin = Vector2.Create(0.5, 0)
	ConnectionErrorLabel.RelativeSize = Vector2.Create(0.7, 0)
	ConnectionErrorLabel.PixelSize = Vector2.Create(0, 50)
	ConnectionErrorLabel.RelativePosition = Vector2.Create(0.5, 0.5)
	ConnectionErrorLabel.PixelPosition = Vector2.Create(0, CameraAddressEntry.AbsoluteSize.Y + 15)
	ConnectionErrorLabel.BackgroundColour = Vector4.Create(1, 1, 1, 0.3)
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
	ConnectButton.BackgroundColour = Vector4.Create(1, 1, 1, 0.1)
	ConnectButton.TextColour = Vector4.One
	ConnectButton.CornerPixelRadius = 10
	ConnectButton.Parent = ConnectionPage	

	ConnectButton.Events:Listen("Pressed", function()
		local host, port = string.match(CameraAddressEntry.Text, "([%w_%-%.]+):(%d+)")
		
		local success, errorMessage = false, "Invalid address"

		if host then
			success, errorMessage = appClient:Connect(host, port, settings.Client.NetworkTimeout)
		end

		if success then
			appClient:Send("&GetSettings!")

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
	LivestreamButton.PixelPosition = Vector2.Create(0, -30)
	LivestreamButton.BackgroundColour = Vector4.Create(1, 1, 1, 0.1)
	LivestreamButton.TextColour = Vector4.One
	LivestreamButton.BorderThickness = 3
	LivestreamButton.BorderColour = Vector4.One
	LivestreamButton.CornerRelativeRadius = 1
	LivestreamButton.Text = "START"
	LivestreamButton.Parent = LivestreamPage

	LivestreamButton.Events:Listen("Released", function()
		if LivestreamFrame.Video then
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
	RotateLeftButton.PixelPosition = Vector2.Create(-LivestreamButton.AbsoluteSize.X*0.5 - 10, -30)
	RotateLeftButton.BackgroundColour = Vector4.Create(1, 1, 1, 0.1)
	RotateLeftButton.TextColour = Vector4.One
	RotateLeftButton.BorderThickness = 3
	RotateLeftButton.BorderColour = Vector4.One
	RotateLeftButton.CornerRelativeRadius = 1
	RotateLeftButton.BackgroundImage = Icons.LeftArrow
	RotateLeftButton.Parent = LivestreamPage

	RotateLeftButton.Events:Listen("Released", function()
		trackingCooldown = true
		
		appClient:Send("&IncrementAngle:%d!", settings.Client.RotationIncrement)

		trackingCooldownTimer:Reset()
		trackingCooldownTimer.Running = true
	end)

	local RotateRightButton = UserInterface.Button.Create()
	RotateRightButton.AspectRatio = 1
	RotateRightButton.DominantAxis = Enum.Axis.Y
	RotateRightButton.RelativeOrigin = Vector2.Create(0, 1)
	RotateRightButton.RelativeSize = Vector2.Create(1, 0)
	RotateRightButton.PixelSize = Vector2.Create(0, 60)
	RotateRightButton.RelativePosition = Vector2.Create(0.5, 1)
	RotateRightButton.PixelPosition = Vector2.Create(LivestreamButton.AbsoluteSize.X*0.5 + 10, -30)
	RotateRightButton.BackgroundColour = Vector4.Create(1, 1, 1, 0.1)
	RotateRightButton.TextColour = Vector4.One
	RotateRightButton.BorderThickness = 3
	RotateRightButton.BorderColour = Vector4.One
	RotateRightButton.CornerRelativeRadius = 1
	RotateRightButton.BackgroundImage = Icons.RightArrow
	RotateRightButton.Parent = LivestreamPage

	RotateRightButton.Events:Listen("Released", function()
		trackingCooldown = true

		appClient:Send("&IncrementAngle:%d!", -settings.Client.RotationIncrement)

		trackingCooldownTimer:Reset()
		trackingCooldownTimer.Running = true
	end)

	local TrackingToggleButton = UserInterface.ToggleButton.Create()
	TrackingToggleButton.AspectRatio = 1
	TrackingToggleButton.DominantAxis = Enum.Axis.Y
	TrackingToggleButton.RelativeOrigin = Vector2.Create(0, 1)
	TrackingToggleButton.RelativeSize = Vector2.Create(1, 0)
	TrackingToggleButton.PixelSize = Vector2.Create(0, 60)
	TrackingToggleButton.RelativePosition = Vector2.Create(0, 1)
	TrackingToggleButton.PixelPosition = Vector2.Create(20, -30)
	TrackingToggleButton.BackgroundColour = Vector4.Create(1, 1, 1, 0.1)
	TrackingToggleButton.TextColour = Vector4.One
	TrackingToggleButton.BorderThickness = 3
	TrackingToggleButton.BorderColour = Vector4.Create(1, 0, 0, 1)
	TrackingToggleButton.CornerRelativeRadius = 1
	TrackingToggleButton.BackgroundImage = Icons.Box
	TrackingToggleButton.BackgroundImageScale = 0.8
	TrackingToggleButton.Value = false
	TrackingToggleButton.Parent = LivestreamPage

	TrackingToggleButton.Events:Listen("Released", function()
		tracking = TrackingToggleButton.Value
		TrackingToggleButton.BorderColour = tracking and Vector4.Create(0, 1, 0, 1) or Vector4.Create(1, 0, 0, 1)
	end)

	LivestreamFrame = UserInterface.VideoFrame.Create()
	LivestreamFrame.RelativeSize = Vector2.Create(1, 1)
	LivestreamFrame.PixelSize = Vector2.Create(0, -TrackingToggleButton.AbsoluteSize.Y - 40)
	LivestreamFrame.BackgroundImageScaleMode = Enum.ScaleMode.MaintainAspectRatio
	LivestreamFrame.BackgroundColour = Vector4.Create(1, 1, 1, 0.1)
	LivestreamFrame.Parent = LivestreamPage

	SettingsPage = UserInterface.ScrollFrame.Create()
	SettingsPage.RelativeSize = Vector2.One
	SettingsPage.BackgroundColour = Vector4.Zero
	SettingsPage.Parent = AppPages

	SettingsLabelTemplateOne = UserInterface.Label.Create()
	SettingsLabelTemplateOne.TextPixelPosition = Vector2.Create(10, 0)
	SettingsLabelTemplateOne.TextRelativeSize = 0
	SettingsLabelTemplateOne.TextPixelSize = 40
	SettingsLabelTemplateOne.ScaleToFitText = true
	SettingsLabelTemplateOne.TextColour = Vector4.One
	SettingsLabelTemplateOne.Font = UserInterface.Font.FreeSansBold
	SettingsLabelTemplateOne.BackgroundColour = Vector4.Zero
	SettingsLabelTemplateOne.Visible = false
	SettingsLabelTemplateOne.Parent = SettingsPage

	SettingsLabelTemplateTwo = UserInterface.Label.Create()
	SettingsLabelTemplateTwo.TextPixelPosition = Vector2.Create(10, 0)
	SettingsLabelTemplateTwo.TextRelativeSize = 0
	SettingsLabelTemplateTwo.TextPixelSize = 25
	SettingsLabelTemplateTwo.ScaleToFitText = true
	SettingsLabelTemplateTwo.TextColour = Vector4.One
	SettingsLabelTemplateTwo.Font = UserInterface.Font.FreeSansBold
	SettingsLabelTemplateTwo.BackgroundColour = Vector4.Zero
	SettingsLabelTemplateTwo.Visible = false
	SettingsLabelTemplateTwo.Parent = SettingsPage

	SettingsLabelTemplateThree = UserInterface.Label.Create()
	SettingsLabelTemplateThree.TextPixelPosition = Vector2.Create(10, 0)
	SettingsLabelTemplateThree.TextRelativeSize = 0
	SettingsLabelTemplateThree.TextPixelSize = 20
	SettingsLabelTemplateThree.ScaleToFitText = true
	SettingsLabelTemplateThree.TextColour = Vector4.One
	SettingsLabelTemplateThree.BackgroundColour = Vector4.Zero
	SettingsLabelTemplateThree.Visible = false
	SettingsLabelTemplateThree.Parent = SettingsPage

	SettingsLabelTemplateFour = UserInterface.Label.Create()
	SettingsLabelTemplateFour.TextPixelPosition = Vector2.Create(10, 0)
	SettingsLabelTemplateFour.TextRelativeSize = 0
	SettingsLabelTemplateFour.TextPixelSize = 20
	SettingsLabelTemplateFour.ScaleToFitText = true
	SettingsLabelTemplateFour.TextColour = Vector4.Create(0.6, 0.6, 0.6, 1)
	SettingsLabelTemplateFour.BackgroundColour = Vector4.Zero
	SettingsLabelTemplateFour.Visible = false
	SettingsLabelTemplateFour.Parent = SettingsPage

	SettingsNumberTemplate = UserInterface.NumericTextBox.Create()
	SettingsNumberTemplate.RelativeOrigin = Vector2.Create(0, 0.08)
	SettingsNumberTemplate.PixelSize = Vector2.Create(300, 30)
	SettingsNumberTemplate.TextRelativeOrigin = Vector2.Create(0, 0.5)
	SettingsNumberTemplate.TextRelativePosition = Vector2.Create(0, 0.5)
	SettingsNumberTemplate.TextPixelPosition = Vector2.Create(10, 0)
	SettingsNumberTemplate.PlaceholderTextColour = Vector4.Create(1, 1, 1, 0.5)
	SettingsNumberTemplate.BackgroundColour = Vector4.Create(1, 1, 1, 0.1)
	SettingsNumberTemplate.TextRelativeSize = 0.6
	SettingsNumberTemplate.TextColour = Vector4.One
	SettingsNumberTemplate.CornerPixelRadius = 10
	SettingsNumberTemplate.Visible = false
	SettingsNumberTemplate.Parent = SettingsPage

	SettingsBooleanTemplate = UserInterface.ToggleButton.Create()
	SettingsBooleanTemplate.AspectRatio = 1
	SettingsBooleanTemplate.DominantAxis = Enum.Axis.Y
	SettingsBooleanTemplate.RelativeOrigin = Vector2.Create(0, 0.08)
	SettingsBooleanTemplate.PixelSize = Vector2.Create(0, 30)
	SettingsBooleanTemplate.BackgroundColour = Vector4.Create(1, 1, 1, 0.1)
	SettingsBooleanTemplate.CornerPixelRadius = 10
	SettingsBooleanTemplate.ToggledBackgroundImage = Icons.Check
	SettingsBooleanTemplate.Visible = false
	SettingsBooleanTemplate.Parent = SettingsPage

	SettingsStringTemplate = UserInterface.TextBox.Create()
	SettingsStringTemplate.RelativeOrigin = Vector2.Create(0, 0.08)
	SettingsStringTemplate.PixelSize = Vector2.Create(300, 30)
	SettingsStringTemplate.TextRelativeOrigin = Vector2.Create(0, 0.5)
	SettingsStringTemplate.TextRelativePosition = Vector2.Create(0, 0.5)
	SettingsStringTemplate.TextPixelPosition = Vector2.Create(10, 0)
	SettingsStringTemplate.PlaceholderTextColour = Vector4.Create(1, 1, 1, 0.5)
	SettingsStringTemplate.BackgroundColour = Vector4.Create(1, 1, 1, 0.1)
	SettingsStringTemplate.TextRelativeSize = 0.6
	SettingsStringTemplate.TextColour = Vector4.One
	SettingsStringTemplate.CornerPixelRadius = 10
	SettingsStringTemplate.Visible = false
	SettingsStringTemplate.Parent = SettingsPage

	AppInfoLabel = UserInterface.Label.Create()
	AppInfoLabel.RelativeOrigin = Vector2.Create(0, 1)
	AppInfoLabel.PixelSize = Vector2.Create(0, 20)
	AppInfoLabel.RelativeSize = Vector2.Create(1, 0)
	AppInfoLabel.RelativePosition = Vector2.Create(0, 1)
	AppInfoLabel.TextRelativeOrigin = Vector2.Create(0.5, 1)
	AppInfoLabel.TextRelativePosition = Vector2.Create(0.5, 1)
	AppInfoLabel.TextRelativeSize = 0.8
	AppInfoLabel.Text = Vector2.Create(0.5, 1)
	AppInfoLabel.TextColour = Vector4.One
	AppInfoLabel.BackgroundColour = Vector4.Zero
	AppInfoLabel.Parent = Root

	AppPages:AddTransition(1, 2, Enum.PageTransitionDirection.Down)
	AppPages:AddTransition(1, 3, Enum.PageTransitionDirection.Left)

	AppPages:AddTransition(2, 1, Enum.PageTransitionDirection.Up)
	AppPages:AddTransition(2, 3, Enum.PageTransitionDirection.Left)

	AppPages:AddTransition(3, 1, Enum.PageTransitionDirection.Right)
	AppPages:AddTransition(3, 2, Enum.PageTransitionDirection.Right)

	AppPages.Events:Listen("PageSwitching", function(_, _, from, to, switched)
		ConnectionErrorLabel.Visible = false

		if switched then
			if to == 1 then
				TitleLabel.Text = "Connection Details:"
				AppInfoLabel.Visible = true
			elseif to == 2 then
				TitleLabel.Text = "Livestream:"
				AppInfoLabel.Visible = true
			else
				TitleLabel.Text = "Settings:"
			end
		else
			if to == 3 then
				AppInfoLabel.Visible = false
			end
		end
	end)

	appClient.Events:Listen("GetSettings", function(_, _, cameraSettingsString)
		RefreshSettings(settingsString.."\n"..cameraSettingsString)

		print(settings.Camera.MotionThreshold)
	end)

	appClient.Events:Listen("Disconnected", function()
		StopLivestream()
		appClient:Send("&SetAngle:0!")

		AppPages.Page = 1
	end)
	
	appClient.Events:Listen("StopLivestream", StopLivestream)

	UserInterface.SetRoot(Root)
	
	RefreshSettings(settingsString)

	Log.Info("Client", "Client ready")
end

function love.update(deltaTime)
	appClient:Update()

	AppInfoLabel.Text = string.format(
		"FPS: %d | RT: %.3f s",
		love.timer.getFPS(),
		love.timer.getTime() - LOAD_TIME
	)

	if LivestreamFrame.Video and tracker.LargestMotionShape then
		AppInfoLabel.Text = AppInfoLabel.Text..string.format(
			" | MC: %.2f%% | CE: %.2f%%",
			tracker.MotionCoverage * 100,
			math.abs(tracker.LargestMotionShape[1].X + tracker.LargestMotionShape[2].X - 1) * 100
		)
	else
		AppInfoLabel.Text = AppInfoLabel.Text.." | MC: 0.00% | CE: 0.00%"
	end
end

function love.draw()
	if LivestreamFrame.Video then
		if LivestreamFrame.FrameUpdated then
			tracker:Update(LivestreamFrame.Video.Frame)
		end

		if tracker.LargestMotionShape then
			if settings.Client.ShowMotionShapes then
				local absolutePosition = LivestreamFrame.BackgroundImageAbsolutePosition
				local absoluteSize = LivestreamFrame.BackgroundImageAbsoluteSize

				love.graphics.setLineWidth(3)

				for index, shape in pairs(tracker.MotionShapes) do
					local topLeft, bottomRight = unpack(shape)
					
					if shape == tracker.LargestMotionShape then
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

			if tracking then
				local trackingShape = tracker.LargestMotionShape
				local trackingArea = (trackingShape[2].X - trackingShape[1].X)*(trackingShape[2].Y - trackingShape[1].Y)

				if trackingArea < 0.9 then
					if not trackingCooldown then
						trackingCooldown = true

						appClient:Send("&IncrementAngle:"..(-settings.Camera.AngleControlCoefficient*(trackingShape[1].X + trackingShape[2].X - 1)).."!")
						
						trackingCooldownTimer:Reset()
						trackingCooldownTimer.Running = true
					end
				elseif trackingCooldown then
					trackingCooldownTimer:Reset()
					trackingCooldownTimer.Running = true
				end
			end
		end
	end
end

function love.quit(exitCode)
	StopLivestream()

	for index, shader in pairs(Shaders) do
		Shaders[index] = nil
		shader:release()
	end

	for index, icon in pairs(Icons) do
		Icons[index] = nil
		icon:release()
	end

	appClient:Destroy()

	trackingCooldownTimer:Destroy()

	SaveSettings()

	Log.Info("Client", "Client stopping")
end