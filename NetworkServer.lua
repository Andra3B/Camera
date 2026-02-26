local NetworkController = require("NetworkController")
local NetworkClient = require("NetworkClient")

local NetworkServer = {}

function NetworkServer.Create(serverSocket)
	local self = Class.CreateInstance(NetworkController.Create(serverSocket), NetworkServer)

	self._Clients = {}
	
	return self
end

function NetworkServer:GetClient(index)
	return self._Clients[index]
end

function NetworkServer:IterateClients()
	return ipairs(self._Clients)
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

			table.insert(self._Clients, networkClient)
		else
			break
		end
	end

	local index = 1
	while index <= #self._Clients do
		local networkClient = self._Clients[index]

		if networkClient:Update() then
			index = index + 1
		else
			table.remove(self._Clients, index)
			networkClient:Destroy()
		end
	end
end

function NetworkServer:Destroy()
	if not self._Destroyed then
		table.erase(self._Clients, NetworkClient.Destroy)

		self._Clients = nil

		NetworkController.Destroy(self)
	end
end

return Class.CreateClass(NetworkServer, "NetworkServer", NetworkController)