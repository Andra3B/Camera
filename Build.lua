require("SetupEnvironment")

System.Options = {
	["Target"] = {
		DataType = Enum.OptionDataType.String,
		Default = "All"
	}
}

print(System.GetScriptFolder())

local function BuildClient()

end

local function BuildCamera()

end

System.UpdateOptions(arg)

local target = System.Options.Target.Value

if target ~= "Client" then
	BuildCamera()
end

if target ~= "Camera" then
	BuildClient()
end