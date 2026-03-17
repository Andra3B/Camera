--if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then require("lldebugger").start() end

local commandChannel, dataChannel, ffmpegCommand, frameByteSize = ...

local ffmpegPipe, errorState = io.popen("ffmpeg -hide_banner -loglevel quiet "..ffmpegCommand, "rb")

if ffmpegPipe then
	while true do
		local command = commandChannel:pop()

		if command == "Stop" then
			repeat
				command = commandChannel:demand()
			until command ~= "Stop"
		elseif command == "Exit" then
			break
		end

		local frame = ffmpegPipe:read(frameByteSize)

		if frame and #frame == frameByteSize then
			dataChannel:push(love.data.newByteData(frame))
		end
	end

	ffmpegPipe:close()
else
	error("Failed to launch ffmpeg: "..tostring(errorState))
end