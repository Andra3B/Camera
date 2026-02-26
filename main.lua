if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
	require("lldebugger").start()
end

table.new = require("table.new")
table.empty = table.new(0, 0)

table.erase = function(tab, cleanupCallback)
	for key, value in pairs(tab) do
		if cleanupCallback then
			cleanupCallback(value)
		end

		tab[key] = nil
	end
end

string.replace = function(str, from, to, with)
	if to >= #str then
		return string.sub(str, 1, from - 1)..with
	else
		return string.sub(str, 1, from - 1)..with..string.sub(str, to + 1)
	end
end

math.clamp = function(value, min, max)
	if value < min then
		return min
	elseif value > max then
		return max
	else
		return value
	end
end

ffi = require("ffi")
buffer = require("string.buffer")

Class = require("Class")

Entity = require("Entity")
Object = require("Object")

Enum = require("Enum")
Log = require("Log")

Vector2 = require("Vector2")
Vector3 = require("Vector3")
Vector4 = require("Vector4")

EventDirector = require("EventDirector")

Animation = require("Animation")
Timer = require("Timer")

NetworkClient = require("NetworkClient")
NetworkServer = require("NetworkServer")

if love then
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

	function love.run()
		love.load()
	
		love.timer.step()
		return function()
			love.event.pump()
	
			for name, a, b, c, d, e, f in love.event.poll() do
				if name == "quit" then
					a = a or 0
	
					love.quit(a)
	
					Animation.DestroyAllAnimations()
					Timer.DestroyAllTimers()
	
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

	dofile(arg[2].."/main.lua")
end