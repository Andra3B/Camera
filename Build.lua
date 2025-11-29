require("SetupEnvironment")

System.Options = {
	["Target"] = {
		DataType = Enum.OptionDataType.String,
		Default = "All"
	},

	["LoveFolder"] = {
		DataType = Enum.OptionDataType.Path,
		Required = false
	},

	["LibAVFolder"] = {
		DataType = Enum.OptionDataType.Path,
		Required = false
	}
}

System.UpdateOptions(arg)

local target = System.Options.Target.Value
local loveFolder = System.Options.LoveFolder.Value
local libAVFolder = System.Options.LibAVFolder.Value

local function BuildClient()
	if jit.os == "Windows" then
		System.Execute(
			"powershell.exe Compress-Archive -Path ClientApplication/main.lua, ClientApplication/conf.lua, Assets, libav, UserInterface, Class.lua, Enum.lua, Enums.lua, EventDirector.lua, EventListener.lua, FFILoader.lua, Log.lua, NetworkClient.lua, NetworkController.lua, SetupEnvironment.lua, System.lua, Vector2.lua, Vector3.lua, Vector4.lua -DestinationPath Client.zip",
			Enum.ExecutionMode.Execute
		)

		if System.Create("ClientBuild/") then
			if System.Execute("mv Client.zip Client.love", Enum.ExecutionMode.Execute) == 0 then
				if System.Execute(
					"cat \""..loveFolder.."love.exe\" Client.love > ClientBuild/Client.exe ",
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
						Log.Critical(Enum.LogCategory.Build, "Failed to copy required files to the ClientBuild folder!")
					end
				else
					Log.Critical(Enum.LogCategory.Build, "Failed to create Client.exe!")
				end

				System.Destroy("Client.love")
			else
				Log.Critical(Enum.LogCategory.Build, "Failed to create Client.love!")
			end
		else
			Log.Critical(Enum.LogCategory.Build, "Failed to create ClientBuild folder!")
		end
	else
		System.Execute(
			"zip -9 -r Client.zip ClientApplication/main.lua ClientApplication/conf.lua Assets libav UserInterface Class.lua Enum.lua Enums.lua EventDirector.lua EventListener.lua FFILoader.lua Log.lua NetworkClient.lua NetworkController.lua SetupEnvironment.lua System.lua Vector2.lua Vector3.lua Vector4.lua",
			Enum.ExecutionMode.Execute
		)
		
		if System.Create("ClientBuild/") then
			if System.Execute("mv Client.zip ClientBuild/Client.love", Enum.ExecutionMode.Execute) == 0 then
				local executableFile = io.open("ClientBuild/Client", "w+")

				if executableFile then
					executableFile:write([[
						#!/bin/sh
						exec love "$(dirname "$0")/Client.love"
					]])

					executableFile:close()

					if System.Execute(
						"chmod a+x ClientBuild/Client",
						Enum.ExecutionMode.Execute
					) ~= 0 then
						Log.Critical(Enum.LogCategory.Build, "Failed to make Client executable!")
					end
				else
					Log.Critical(Enum.LogCategory.Build, "Failed to create Client!")
				end
			else
				Log.Critical(Enum.LogCategory.Build, "Failed to create Client.love!")
			end	
		else
			Log.Critical(Enum.LogCategory.Build, "Failed to create ClientBuild folder!")
		end
	end
end

local function BuildCamera()
	if jit.os == "Windows" then
		System.Execute(
			"powershell.exe Compress-Archive -Path CameraApplication/main.lua, CameraApplication/conf.lua, Assets, libav, UserInterface, Class.lua, Enum.lua, Enums.lua, EventDirector.lua, EventListener.lua, FFILoader.lua, Log.lua, NetworkClient.lua, NetworkServer.lua, NetworkController.lua, SetupEnvironment.lua, System.lua, Vector2.lua, Vector3.lua, Vector4.lua -DestinationPath Camera.zip",
			Enum.ExecutionMode.Execute
		)

		if System.Create("CameraBuild/") then
			if System.Execute("mv Camera.zip Camera.love", Enum.ExecutionMode.Execute) == 0 then
				if System.Execute(
					"cat \""..loveFolder.."love.exe\" Camera.love > CameraBuild/Camera.exe ",
					Enum.ExecutionMode.Execute
				) == 0 then
					if not (
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

				System.Destroy("Camera.love")
			else
				Log.Critical(Enum.LogCategory.Build, "Failed to create Camera.love!")
			end
		else
			Log.Critical(Enum.LogCategory.Build, "Failed to create ClientBuild folder!")
		end
	else
		System.Execute(
			"zip -9 -r Camera.zip CameraApplication/main.lua CameraApplication/conf.lua Assets libav UserInterface Class.lua Enum.lua Enums.lua EventDirector.lua EventListener.lua FFILoader.lua Log.lua NetworkClient.lua NetworkServer.lua NetworkController.lua SetupEnvironment.lua System.lua Vector2.lua Vector3.lua Vector4.lua",
			Enum.ExecutionMode.Execute
		)
		
		if System.Create("CameraBuild/") then
			if System.Execute("mv Camera.zip CameraBuild/Camera.love", Enum.ExecutionMode.Execute) == 0 then
				local executableFile = io.open("CameraBuild/Camera", "w+")

				if executableFile then
					executableFile:write([[
						#!/bin/sh
						exec love "$(dirname "$0")/Camera.love"
					]])

					executableFile:close()

					if System.Execute(
						"chmod a+x CameraBuild/Camera",
						Enum.ExecutionMode.Execute
					) ~= 0 then
						Log.Critical(Enum.LogCategory.Build, "Failed to make Camera executable!")
					end
				else
					Log.Critical(Enum.LogCategory.Build, "Failed to create Camera!")
				end
			else
				Log.Critical(Enum.LogCategory.Build, "Failed to create Camera.love!")
			end	
		else
			Log.Critical(Enum.LogCategory.Build, "Failed to create CameraBuild folder!")
		end
	end
end

if target ~= "Client" then
	BuildCamera()
end

if target ~= "Camera" then
	BuildClient()
end