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

	UserInterface.Initialise()

	local Root = UserInterface.Frame.Create()
	Root.RelativeSize = Vector2.Create(1, 1)
	Root.BackgroundColour = Vector4.Create(1, 1, 1, 1)

	MyPages = UserInterface.Pages.Create()
	MyPages.RelativeSize = Vector2.Create(1, 1)

	local Frame1 = UserInterface.Frame.Create()
	Frame1.RelativeSize = Vector2.Create(1, 1)
	Frame1.BackgroundColour = Vector4.Create(1, 0, 0, 1)

	local Frame2 = UserInterface.Frame.Create()
	Frame2.RelativeSize = Vector2.Create(1, 1)
	Frame2.BackgroundColour = Vector4.Create(0, 1, 0, 1)

	MyPages:AddChild(Frame1)
	MyPages:AddChild(Frame2)

	Root:AddChild(MyPages)

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

	UserInterface.SetRoot(Root)

	MyPages:AddTransition(1, 2, Enum.PageTransitionDirection.Up).AnimationType = Enum.AnimationType.SharpSmoothStep
	MyPages:AddTransition(2, 1, Enum.PageTransitionDirection.Down).AnimationType = Enum.AnimationType.SharpSmoothStep

	MyPages.Page = 2

	local width, height = love.window.getDesktopDimensions(1)
	love.window.setTitle("Camera Client")
	love.window.setMode(width*0.5, height*0.5, {
		["fullscreen"] = false,
		["stencil"] = false,
		["resizable"] = true,
		["centered"] = true,
		["display"] = 1
	})
end

local counter = 200

function love.update(deltaTime)
	counter = counter - 1

	if counter <= 0 then
		MyPages.Page = 1
	end

	AppNetworkClient:Update()
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