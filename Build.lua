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
			"powershell.exe Compress-Archive -Path ClientApplication/main.lua, ClientApplication/conf.lua -DestinationPath Client.zip",
			Enum.ExecutionMode.Execute
		)
	else
		System.Execute(
			"tar -c -f Client.tar ClientApplication/main.lua ClientApplication/conf.lua",
			Enum.ExecutionMode.Execute
		)
	end

	if System.Execute("mv Client.zip Client.love", Enum.ExecutionMode.Execute) == 0 then
		if System.Create("ClientBuild/") then
			if jit.os == "Windows" then
				if System.Execute(
					"cat \""..loveFolder.."love.exe\" Client.love > ClientBuild/Client.exe",
					Enum.ExecutionMode.Execute
				) == 0 then
					if not (
						System.Copy("Assets", "ClientBuild") and
						System.Copy("libav", "ClientBuild") and
						System.Copy("UserInterface", "ClientBuild") and
						System.Copy("Class.lua", "ClientBuild") and
						System.Copy("Enum.lua", "ClientBuild") and
						System.Copy("Enums.lua", "ClientBuild") and
						System.Copy("EventDirector.lua", "ClientBuild") and
						System.Copy("EventListener.lua", "ClientBuild") and
						System.Copy("FFILoader.lua", "ClientBuild") and
						System.Copy("Log.lua", "ClientBuild") and
						System.Copy("NetworkController.lua", "ClientBuild") and
						System.Copy("NetworkClient.lua", "ClientBuild") and
						System.Copy("SetupEnvironment.lua", "ClientBuild") and
						System.Copy("System.lua", "ClientBuild") and
						System.Copy("Vector2.lua", "ClientBuild") and
						System.Copy("Vector3.lua", "ClientBuild") and
						System.Copy("Vector4.lua", "ClientBuild") and

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
						Log.Critical(Enum.LogCategory.Build, "Failed to copy required files to the ClientBuild folder!")
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
	if jit.os == "Windows" then
		System.Execute(
			"powershell.exe Compress-Archive -Path CameraApplication/main.lua, CameraApplication/conf.lua -DestinationPath Camera.zip",
			Enum.ExecutionMode.Execute
		)
	else
		System.Execute(
			"tar -c -f Camera.tar CameraApplication/main.lua CameraApplication/conf.lua",
			Enum.ExecutionMode.Execute
		)
	end

	if System.Execute("mv Camera.zip Camera.love", Enum.ExecutionMode.Execute) == 0 then
		if System.Create("CameraBuild/") then
			if jit.os == "Windows" then
				if System.Execute(
					"cat \""..loveFolder.."love.exe\" Camera.love > CameraBuild/Camera.exe",
					Enum.ExecutionMode.Execute
				) == 0 then
					if not (
						System.Copy("Assets", "ClientBuild") and
						System.Copy("libav", "ClientBuild") and
						System.Copy("UserInterface", "ClientBuild") and
						System.Copy("Class.lua", "ClientBuild") and
						System.Copy("Enum.lua", "ClientBuild") and
						System.Copy("Enums.lua", "ClientBuild") and
						System.Copy("EventDirector.lua", "ClientBuild") and
						System.Copy("EventListener.lua", "ClientBuild") and
						System.Copy("FFILoader.lua", "ClientBuild") and
						System.Copy("Log.lua", "ClientBuild") and
						System.Copy("NetworkController.lua", "ClientBuild") and
						System.Copy("NetworkServer.lua", "ClientBuild") and
						System.Copy("NetworkClient.lua", "ClientBuild") and
						System.Copy("SetupEnvironment.lua", "ClientBuild") and
						System.Copy("System.lua", "ClientBuild") and
						System.Copy("Vector2.lua", "ClientBuild") and
						System.Copy("Vector3.lua", "ClientBuild") and
						System.Copy("Vector4.lua", "ClientBuild") and

						System.Copy(loveFolder.."/SDL2.dll", "CameraBuild") and
						System.Copy(loveFolder.."/OpenAL32.dll", "CameraBuild") and
						System.Copy(loveFolder.."/license.txt", "CameraBuild") and
						System.Copy(loveFolder.."/love.dll", "CameraBuild") and
						System.Copy(loveFolder.."/lua51.dll", "CameraBuild") and
						System.Copy(loveFolder.."/mpg123.dll", "CameraBuild") and
						System.Copy(loveFolder.."/msvcp120.dll", "CameraBuild") and
						System.Copy(loveFolder.."/msvcr120.dll", "CameraBuild") and

						System.Copy(libAVFolder.."/avutil-60.dll", "CameraBuild") and
						System.Copy(libAVFolder.."/avcodec-62.dll", "CameraBuild") and
						System.Copy(libAVFolder.."/avformat-62.dll", "CameraBuild") and
						System.Copy(libAVFolder.."/avdevice-62.dll", "CameraBuild") and
						System.Copy(libAVFolder.."/avfilter-11.dll", "CameraBuild") and
						System.Copy(libAVFolder.."/swscale-9.dll", "CameraBuild")
					) then
						Log.Critical(Enum.LogCategory.Build, "Failed to copy required files to the CameraBuild folder!")
					end
				else
					Log.Critical(Enum.LogCategory.Build, "Failed to create Camera.exe!")
				end
			else
				if System.Execute(
					"cat "..loveFolder.."/love Camera.love > Camera && chmod a+x Camera",
					Enum.ExecutionMode.Execute
				) == 0 then
				
				else
					Log.Critical(Enum.LogCategory.Build, "Failed to create Camera!")
				end
			end
		else
			Log.Critical(Enum.LogCategory.Build, "Failed to create CameraBuild folder!")
		end

		System.Destroy("Camera.love")
	else
		Log.Critical(Enum.LogCategory.Build, "Failed to create Camera.love!")
	end
end

if target ~= "Client" then
	BuildCamera()
end

if target ~= "Camera" then
	BuildClient()
end