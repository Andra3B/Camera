local NetworkController = require("NetworkController")
local NetworkClient = require("NetworkClient")

local NetworkServer = {}

function NetworkServer.Create(serverSocket)
	local self = Class.CreateInstance(NetworkController.Create(serverSocket), NetworkServer)

	self._Connections = {}
	
	return self
end

function NetworkServer:GetClient(index)
	return self._Connections[index]
end

function NetworkServer:GetLocalDetails()
	return self._Socket:getsockname()
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
			local networkClient = NetworkClient.Create(clientSocket, self)

			table.insert(self._Connections, networkClient)
		else
			break
		end
	end

	local index = 1
	while index <= #self._Connections do
		local networkClient = self._Connections[index]

		if networkClient:IsConnected() then
			networkClient:Update()

			index = index + 1
		else
			table.remove(self._Connections, index)
			networkClient:Destroy()
		end
	end
end

function NetworkServer:Destroy()
	if not self._Destroyed then
		for index, networkClient in pairs(self._Connections) do
			networkClient:Destroy()
			self._Connections[index] = nil
		end

		self._Connections = nil

		NetworkController.Destroy(self)
	end
end

return Class.CreateClass(NetworkServer, "NetworkServer", NetworkController)