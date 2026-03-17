if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then require("lldebugger").start() end

require("Setup")

Animation = require("Animation")
Timer = require("Timer")

NetworkClient = require("NetworkClient")
NetworkServer = require("NetworkServer")

socket = require("socket")
utf8 = require("utf8")
	
UserInterface = require("UserInterface.UserInterface")

function love.resize(width, height) UserInterface.Refresh() end
	
function love.keypressed(key, scancode) UserInterface.Input(Enum.InputType.Keyboard, scancode, Vector4.Create(0, 0, -1, 0)) end
function love.keyreleased(key, scancode) UserInterface.Input(Enum.InputType.Keyboard, scancode, Vector4.Zero) end
function love.mousemoved(x, y, dx, dy) UserInterface.Input(Enum.InputType.Mouse, "mousemovement", Vector4.Create(x, y, dx, dy)) end
function love.wheelmoved(dx, dy) UserInterface.Input(Enum.InputType.Mouse, "mousewheelmovement", Vector4.Create(dx, dy, 0, 0)) end
function love.mousepressed(x, y, button, isTouch, presses) UserInterface.Input(Enum.InputType.Mouse, button, Vector4.Create(x, y, -presses, 0)) end
function love.mousereleased(x, y, button, isTouch, presses) UserInterface.Input(Enum.InputType.Mouse, button, Vector4.Create(x, y, 0, 0)) end
	
function love.textinput(text) UserInterface.TextInput(text) end
	
function love.update(deltaTime) end
function love.draw() end
function love.quit(exitCode) end

function love.errorhandler(message)
	Log.Error(arg[2], debug.traceback(tostring(message), 2):gsub("\n[^\n]+$", ""))

	love.quit(1)

	Animation.DestroyAnimations()
	Timer.DestroyTimers()
	UserInterface.DestroyRoot()
end

function love.threaderror(thread, message) love.errorhandler(message) end

function love.run()
	love.load()
	
	LOAD_TIME = love.timer.getTime()

	love.timer.step()
	return function()
		love.event.pump()

		for name, a, b, c, d, e, f in love.event.poll() do
			if name == "quit" then
				a = a or 0
	
				love.quit(a)
	
				Animation.DestroyAnimations()
				Timer.DestroyTimers()
				UserInterface.DestroyRoot()
	
				return a
			end
	
			local handler = love.handlers[name]
	
			if handler then
				handler(a, b, c, d, e, f)
			end
		end
	
		local deltaTime = love.timer.step()
	
		Timer.Update(deltaTime)
		Animation.Update(deltaTime)
	
		love.update(deltaTime)
	
		UserInterface.Update(deltaTime)
	
		if love.graphics.isActive() then
			UserInterface.Draw()
				
			love.draw()
				
			love.graphics.present()
		end
	
		love.timer.sleep(0.001)
	end
end

dofile(arg[2]..".lua")