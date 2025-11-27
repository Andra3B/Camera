require("SetupEnvironment")

System.Options = {
	["Target"] = {
		DataType = Enum.OptionDataType.String,
		Default = "All"
	},

	["LoveFolder"] = {
		DataType = Enum.OptionDataType.Path,
		Required = true
	},

	["LibAVFolder"] = {
		DataType = Enum.OptionDataType.Path,
		Required = true
	}
}

System.UpdateOptions(arg)

local target = System.Options.Target.Value
local loveFolder = System.Options.LoveFolder.Value
local libAVFolder = System.Options.LibAVFolder.Value

local function BuildClient()
	if jit.os == "Windows" then
		System.Execute(
			"powershell.exe Compress-Archive -Path ClientApplication/main.lua, ClientApplication/conf.lua, libav, UserInterface, Class.lua, Enum.lua, Enums.lua, EventDirector.lua, EventListener.lua, FFILoader.lua, Log.lua, NetworkController.lua, NetworkClient.lua, SetupEnvironment.lua, System.lua, Vector2.lua, Vector3.lua, Vector4.lua -DestinationPath Client.zip",
			Enum.ExecutionMode.Execute
		)
	else
		System.Execute(
			"tar -c -f Client.zip ClientApplication/main.lua ClientApplication/conf.lua Class.lua Enum.lua Enums.lua EventDirector.lua EventListener.lua FFILoader.lua Log.lua NetworkController.lua NetworkClient.lua SetupEnvironment.lua System.lua Vector2.lua Vector3.lua Vector4.lua",
			Enum.ExecutionMode.Execute
		)
	end

	if System.Execute("mv Client.zip Client.love", Enum.ExecutionMode.Execute) == 0 then
		if System.Create("ClientBuild/") then
			if jit.os == "Windows" then
				if System.Execute(
					"cat "..loveFolder.."/love.exe Client.love > ClientBuild/Client.exe",
					Enum.ExecutionMode.Execute
				) == 0 then
					if not (
						System.Copy(loveFolder.."/SDL2.dll", "ClientBuild") and
						System.Copy(loveFolder.."/OpenAL32.dll", "ClientBuild") and
						System.Copy(loveFolder.."/license.txt", "ClientBuild") and
						System.Copy(loveFolder.."/love.dll", "ClientBuild") and
						System.Copy(loveFolder.."/lua51.dll", "ClientBuild") and
						System.Copy(loveFolder.."/mpg123.dll", "ClientBuild") and
						System.Copy(loveFolder.."/msvcp120.dll", "ClientBuild") and
						System.Copy(loveFolder.."/msvcr120.dll", "ClientBuild") and

						System.Copy(libAVFolder.."/avutil-60.dll", "ClientBuild") and
						System.Copy(libAVFolder.."/avcodec-62.dll", "ClientBuild") and
						System.Copy(libAVFolder.."/avformat-62.dll", "ClientBuild") and
						System.Copy(libAVFolder.."/avdevice-62.dll", "ClientBuild") and
						System.Copy(libAVFolder.."/avfilter-11.dll", "ClientBuild") and
						System.Copy(libAVFolder.."/swscale-9.dll", "ClientBuild")
					) then
						Log.Critical(Enum.LogCategory.Build, "Failed to copy required DLLs to the ClientBuild folder!")
					end
				else
					Log.Critical(Enum.LogCategory.Build, "Failed to create Client.exe!")
				end
			else
				if System.Execute(
					"cat "..loveFolder.."/love Client.love > Client && chmod a+x Client",
					Enum.ExecutionMode.Execute
				) == 0 then
				
				else
					Log.Critical(Enum.LogCategory.Build, "Failed to create Client!")
				end
			end
		else
			Log.Critical(Enum.LogCategory.Build, "Failed to create ClientBuild folder!")
		end

		System.Destroy("Client.love")
	else
		Log.Critical(Enum.LogCategory.Build, "Failed to create Client.love!")
	end
end

local function BuildCamera()

end

if target ~= "Client" then
	BuildCamera()
end

if target ~= "Camera" then
	BuildClient()
end