local NetworkController = require("NetworkController")
local NetworkClient = require("NetworkClient")

local NetworkServer = {}

local function OnChildDisconnected(self, _, networkClient)
	networkClient:Destroy()
end

function NetworkServer.Create(serverSocket)
	local self = Class.CreateInstance(NetworkController.Create(serverSocket), NetworkServer)

	self._Events:Listen("ChildDisconnected", OnChildDisconnected)

	return self
end

function NetworkServer:Listen()
	local success, errorMessage = self._Socket:listen(10)

	return success == 1, errorMessage
end

function NetworkServer:Update()
	NetworkController.Update(self)

	while true do
		local clientSocket = self._Socket:accept()

		if clientSocket then
			local networkClient = NetworkClient.Create(clientSocket, true)
			networkClient.Parent = self
		else
			break
		end
	end
end

return Class.CreateClass(NetworkServer, "NetworkServer", NetworkController)