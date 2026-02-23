require("Setup")

socket = require("socket")
utf8 = require("utf8")

UserInterface = require("UserInterface")

GStreamer = require("GStreamer.GStreamer")
GObject = GStreamer.GObject
GLib = GStreamer.GLib
GStreamer = GStreamer.GStreamer

VideoReader = require("VideoReader")

NetworkClient = require("NetworkClient")

MotionTracker = require("MotionTracker")

function love.load()
	local width, height = love.window.getDesktopDimensions(1)
	love.window.setTitle("Sandbox")
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

	local Root = UserInterface.Frame.Create()
	Root.RelativeSize = Vector2.One

	GStreamer.gst_init(ffi.new("int[1]", 0), nil)

  	pipeline = GStreamer.gst_parse_launch(
    	"playbin uri=https://gstreamer.freedesktop.org/data/media/sintel_trailer-480p.webm",
    	nil
	)

  	GStreamer.gst_element_set_state(pipeline, GStreamer.GST_STATE_PLAYING)

	local loop = GLib.g_main_loop_new(NULL, GLib.FALSE)
	GLib.g_main_loop_run(loop)

  	bus = GStreamer.gst_element_get_bus(pipeline)
  	msg = GStreamer.gst_bus_timed_pop_filtered(
		bus, GStreamer.GST_CLOCK_TIME_NONE,
    	bit.bor(GStreamer.GST_MESSAGE_ERROR, GStreamer.GST_MESSAGE_EOS)
	)

  	if (GStreamer.GST_MESSAGE_TYPE(msg) == GStreamer.GST_MESSAGE_ERROR) then
    	print("ERROR!")
		return 0
	end

	UserInterface.SetRoot(Root)
end

function love.update(deltaTime)
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