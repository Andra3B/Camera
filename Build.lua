require("SetupEnvironment")

local libav = require("libav.init")

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
			"powershell.exe Compress-Archive -Path ClientApp/main.lua, ClientApp/conf.lua, Assets, libav, UserInterface, Class.lua, Enum.lua, Enums.lua, EventDirector.lua, EventListener.lua, FFILoader.lua, Log.lua, NetworkClient.lua, NetworkController.lua, SetupEnvironment.lua, System.lua, Vector2.lua, Vector3.lua, Vector4.lua, VideoReader.lua, VideoWriter.lua -DestinationPath Client.zip",
			Enum.ExecutionMode.Execute
		)

		if System.Create("ClientBuild/") then
			if System.Execute("mv Client.zip Client.love", Enum.ExecutionMode.Execute) == 0 then
				if System.Execute(
					"cat \""..loveFolder.."love.exe\" Client.love > ClientBuild/Client.exe ",
					Enum.ExecutionMode.Execute
				) == 0 then
					if not (
						System.Copy("Assets", "ClientBuild") and

						System.Copy(loveFolder.."SDL2.dll", "ClientBuild") and
						System.Copy(loveFolder.."OpenAL32.dll", "ClientBuild") and
						System.Copy(loveFolder.."license.txt", "ClientBuild") and
						System.Copy(loveFolder.."love.dll", "ClientBuild") and
						System.Copy(loveFolder.."lua51.dll", "ClientBuild") and
						System.Copy(loveFolder.."mpg123.dll", "ClientBuild") and
						System.Copy(loveFolder.."msvcp120.dll", "ClientBuild") and
						System.Copy(loveFolder.."msvcr120.dll", "ClientBuild") and

						System.Copy(libAVFolder.."avutil-"..tostring(libav.avutil.LIBAVUTIL_VERSION_MAJOR)..".dll", "ClientBuild") and
						System.Copy(libAVFolder.."avcodec-"..tostring(libav.avcodec.LIBAVCODEC_VERSION_MAJOR)..".dll", "ClientBuild") and
						System.Copy(libAVFolder.."avformat-"..tostring(libav.avformat.LIBAVFORMAT_VERSION_MAJOR)..".dll", "ClientBuild") and
						System.Copy(libAVFolder.."avdevice-"..tostring(libav.avdevice.LIBAVDEVICE_VERSION_MAJOR)..".dll", "ClientBuild") and
						System.Copy(libAVFolder.."avfilter-"..tostring(libav.avfilter.LIBAVFILTER_VERSION_MAJOR)..".dll", "ClientBuild") and
						System.Copy(libAVFolder.."swscale-"..tostring(libav.swscale.LIBSWSCALE_VERSION_MAJOR)..".dll", "ClientBuild")
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
			"zip -9 -r -j Client.zip ClientApp/main.lua ClientApp/conf.lua && "..
			"zip -9 -r Client.zip Assets libav UserInterface Class.lua Enum.lua Enums.lua EventDirector.lua EventListener.lua FFILoader.lua Log.lua NetworkClient.lua NetworkController.lua SetupEnvironment.lua System.lua Vector2.lua Vector3.lua Vector4.lua VideoReader.lua VideoWriter.lua",
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
					System.Execute("chmod a+x ClientBuild/Client", Enum.ExecutionMode.Execute)

					if not System.Copy("Assets", "ClientBuild") then
						Log.Critical(Enum.LogCategory.Build, "Failed to make Client executable!")
					end
				else
					Log.Critical(Enum.LogCategory.Build, "Failed to create Client executable!")
				end
			else
				Log.Critical(Enum.LogCategory.Build, "Failed to create Client.love!")
			end	
		else
			Log.Critical(Enum.LogCategory.Build, "Failed to create ClientBuild folder!")
		end
	end
end

local function BuildLinuxCamera()
	System.Execute(
		"zip -9 -r -j LinuxCamera.zip LinuxCameraApp/main.lua LinuxCameraApp/conf.lua && "..
		"zip -9 -r LinuxCamera.zip Assets libav pigpio UserInterface Class.lua Enum.lua Enums.lua EventDirector.lua EventListener.lua FFILoader.lua Log.lua NetworkClient.lua NetworkServer.lua NetworkController.lua SetupEnvironment.lua System.lua Vector2.lua Vector3.lua Vector4.lua VideoReader.lua VideoWriter.lua",
		Enum.ExecutionMode.Execute
	)
		
	if System.Create("LinuxCameraBuild/") then
		if System.Execute("mv LinuxCamera.zip LinuxCameraBuild/LinuxCamera.love", Enum.ExecutionMode.Execute) == 0 then
			local executableFile = io.open("LinuxCameraBuild/LinuxCamera", "w+")
				
			if executableFile then
				executableFile:write(
					"#!/bin/sh\nexec love \"$(dirname \"$0\")/LinuxCamera.love\"\n"
				)
					
				executableFile:close()
				System.Execute("chmod a+x LinuxCameraBuild/LinuxCamera", Enum.ExecutionMode.Execute)

				if not System.Copy("Assets", "LinuxCameraBuild") then
					Log.Critical(Enum.LogCategory.Build, "Failed to copy required files to the CameraBuild folder!")
				end
			else
				Log.Critical(Enum.LogCategory.Build, "Failed to create Camera executable!")
			end
		else
			Log.Critical(Enum.LogCategory.Build, "Failed to create Camera.love!")
		end	
	else
		Log.Critical(Enum.LogCategory.Build, "Failed to create CameraBuild folder!")
	end
end

local function BuildWindowsCamera()
	System.Execute(
		"powershell.exe Compress-Archive -Path WindowsCameraApp/main.lua, WindowsCameraApp/conf.lua, Assets, libav, UserInterface, Class.lua, Enum.lua, Enums.lua, EventDirector.lua, EventListener.lua, FFILoader.lua, Log.lua, NetworkClient.lua, NetworkServer.lua, NetworkController.lua, SetupEnvironment.lua, System.lua, Vector2.lua, Vector3.lua, Vector4.lua, VideoReader.lua, VideoWriter.lua -DestinationPath WindowsCamera.zip",
		Enum.ExecutionMode.Execute
	)

	if System.Create("WindowsCameraBuild/") then
		if System.Execute("mv WindowsCamera.zip WindowsCamera.love", Enum.ExecutionMode.Execute) == 0 then
			if System.Execute(
				"cat \""..loveFolder.."love.exe\" WindowsCamera.love > WindowsCameraBuild/WindowsCamera.exe ",
				Enum.ExecutionMode.Execute
			) == 0 then
				if not (
					System.Copy("Assets", "WindowsCameraBuild") and

					System.Copy(loveFolder.."/SDL2.dll", "WindowsCameraBuild") and
					System.Copy(loveFolder.."/OpenAL32.dll", "WindowsCameraBuild") and
					System.Copy(loveFolder.."/license.txt", "WindowsCameraBuild") and
					System.Copy(loveFolder.."/love.dll", "WindowsCameraBuild") and
					System.Copy(loveFolder.."/lua51.dll", "WindowsCameraBuild") and
					System.Copy(loveFolder.."/mpg123.dll", "WindowsCameraBuild") and
					System.Copy(loveFolder.."/msvcp120.dll", "WindowsCameraBuild") and
					System.Copy(loveFolder.."/msvcr120.dll", "WindowsCameraBuild") and

					System.Copy(libAVFolder.."avutil-"..tostring(libav.avutil.LIBAVUTIL_VERSION_MAJOR)..".dll", "WindowsCameraBuild") and
					System.Copy(libAVFolder.."avcodec-"..tostring(libav.avcodec.LIBAVCODEC_VERSION_MAJOR)..".dll", "WindowsCameraBuild") and
					System.Copy(libAVFolder.."avformat-"..tostring(libav.avformat.LIBAVFORMAT_VERSION_MAJOR)..".dll", "WindowsCameraBuild") and
					System.Copy(libAVFolder.."avdevice-"..tostring(libav.avdevice.LIBAVDEVICE_VERSION_MAJOR)..".dll", "WindowsCameraBuild") and
					System.Copy(libAVFolder.."avfilter-"..tostring(libav.avfilter.LIBAVFILTER_VERSION_MAJOR)..".dll", "WindowsCameraBuild") and
					System.Copy(libAVFolder.."swscale-"..tostring(libav.swscale.LIBSWSCALE_VERSION_MAJOR)..".dll", "WindowsCameraBuild")
				) then
					Log.Critical(Enum.LogCategory.Build, "Failed to copy required files to the WindowsCameraBuild folder!")
				end
			else
				Log.Critical(Enum.LogCategory.Build, "Failed to create WindowsCamera.exe!")
			end

			System.Destroy("WindowsCamera.love")
		else
			Log.Critical(Enum.LogCategory.Build, "Failed to create WindowsCamera.love!")
		end
	else
		Log.Critical(Enum.LogCategory.Build, "Failed to create WindowsCameraBuild folder!")
	end
end

local function BuildSandbox()
	if jit.os == "Windows" then
		System.Execute(
			"powershell.exe Compress-Archive -Path SandboxApp/main.lua, SandboxApp/conf.lua, Assets, libav, UserInterface, Class.lua, Enum.lua, Enums.lua, EventDirector.lua, EventListener.lua, FFILoader.lua, Log.lua, NetworkClient.lua, NetworkController.lua, SetupEnvironment.lua, System.lua, Vector2.lua, Vector3.lua, Vector4.lua, VideoReader.lua, VideoWriter.lua -DestinationPath Sandbox.zip",
			Enum.ExecutionMode.Execute
		)

		if System.Create("SandboxBuild/") then
			if System.Execute("mv Sandbox.zip Sandbox.love", Enum.ExecutionMode.Execute) == 0 then
				if System.Execute(
					"cat \""..loveFolder.."love.exe\" Sandbox.love > SandboxBuild/Sandbox.exe ",
					Enum.ExecutionMode.Execute
				) == 0 then
					if not (
						System.Copy("Assets", "SandboxBuild") and

						System.Copy(loveFolder.."SDL2.dll", "SandboxBuild") and
						System.Copy(loveFolder.."OpenAL32.dll", "SandboxBuild") and
						System.Copy(loveFolder.."license.txt", "SandboxBuild") and
						System.Copy(loveFolder.."love.dll", "SandboxBuild") and
						System.Copy(loveFolder.."lua51.dll", "SandboxBuild") and
						System.Copy(loveFolder.."mpg123.dll", "SandboxBuild") and
						System.Copy(loveFolder.."msvcp120.dll", "SandboxBuild") and
						System.Copy(loveFolder.."msvcr120.dll", "SandboxBuild") and

						System.Copy(libAVFolder.."avutil-"..tostring(libav.avutil.LIBAVUTIL_VERSION_MAJOR)..".dll", "SandboxBuild") and
						System.Copy(libAVFolder.."avcodec-"..tostring(libav.avcodec.LIBAVCODEC_VERSION_MAJOR)..".dll", "SandboxBuild") and
						System.Copy(libAVFolder.."avformat-"..tostring(libav.avformat.LIBAVFORMAT_VERSION_MAJOR)..".dll", "SandboxBuild") and
						System.Copy(libAVFolder.."avdevice-"..tostring(libav.avdevice.LIBAVDEVICE_VERSION_MAJOR)..".dll", "SandboxBuild") and
						System.Copy(libAVFolder.."avfilter-"..tostring(libav.avfilter.LIBAVFILTER_VERSION_MAJOR)..".dll", "SandboxBuild") and
						System.Copy(libAVFolder.."swscale-"..tostring(libav.swscale.LIBSWSCALE_VERSION_MAJOR)..".dll", "SandboxBuild")
					) then
						Log.Critical(Enum.LogCategory.Build, "Failed to copy required files to the SandboxBuild folder!")
					end
				else
					Log.Critical(Enum.LogCategory.Build, "Failed to create Sandbox.exe!")
				end

				System.Destroy("Sandbox.love")
			else
				Log.Critical(Enum.LogCategory.Build, "Failed to create Sandbox.love!")
			end
		else
			Log.Critical(Enum.LogCategory.Build, "Failed to create SandboxBuild folder!")
		end
	else
		System.Execute(
			"zip -9 -r -j Sandbox.zip SandboxApp/main.lua SandboxApp/conf.lua && "..
			"zip -9 -r Sandbox.zip Assets libav pigpio UserInterface Class.lua Enum.lua Enums.lua EventDirector.lua EventListener.lua FFILoader.lua Log.lua NetworkClient.lua NetworkController.lua SetupEnvironment.lua System.lua Vector2.lua Vector3.lua Vector4.lua VideoReader.lua VideoWriter.lua",
			Enum.ExecutionMode.Execute
		)
		
		if System.Create("SandboxBuild/") then
			if System.Execute("mv Sandbox.zip SandboxBuild/Sandbox.love", Enum.ExecutionMode.Execute) == 0 then
				local executableFile = io.open("SandboxBuild/Sandbox", "w+")

				if executableFile then
					executableFile:write([[
						#!/bin/sh
						exec love "$(dirname "$0")/Sandbox.love"
					]])

					executableFile:close()
					System.Execute("chmod a+x SandboxBuild/Sandbox", Enum.ExecutionMode.Execute)

					if not System.Copy("Assets", "SandboxBuild") then
						Log.Critical(Enum.LogCategory.Build, "Failed to make Sandbox executable!")
					end
				else
					Log.Critical(Enum.LogCategory.Build, "Failed to create Sandbox executable!")
				end
			else
				Log.Critical(Enum.LogCategory.Build, "Failed to create Sandbox.love!")
			end	
		else
			Log.Critical(Enum.LogCategory.Build, "Failed to create SandboxBuild folder!")
		end
	end
end

if target == "Client" then
	BuildClient()
elseif target == "Camera" then
	if jit.os == "Windows" then
		BuildWindowsCamera()
	else
		BuildLinuxCamera()
	end
elseif target == "Sandbox" then
	BuildSandbox()
else
	BuildClient()

	if jit.os == "Windows" then
		BuildWindowsCamera()
	else
		BuildLinuxCamera()
	end

	BuildSandbox()
end