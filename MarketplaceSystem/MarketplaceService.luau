local MessagingService = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Store = require(ServerScriptService:WaitForChild("MarketplaceStore"))
local Lock = require(ServerScriptService:WaitForChild("MarketplaceLock"))
local Constants = require(ReplicatedStorage:WaitForChild("MarketplaceConstants"))

local MarketplaceService = {}
local listings = {}

local Events = Instance.new("Folder")
Events.Name = "MarketplaceEvents"
Events.Parent = ReplicatedStorage

local BuyReq = Instance.new("RemoteFunction")
BuyReq.Name = "BuyRequest"
BuyReq.Parent = Events

local UpdateEv = Instance.new("RemoteEvent")
UpdateEv.Name = "MarketplaceUpdate"
UpdateEv.Parent = Events

function MarketplaceService.Sync()
	listings = Store.GetListings()
	UpdateEv:FireAllClients(listings)
end

function MarketplaceService.GetListings()
	return listings
end

function MarketplaceService.AddListing(id: string, sellerId: number, itemId: number, price: number)
	-- id is explicit so buybutton and seed agree on the same string
	local listing = {
		Id = id,
		SellerId = sellerId,
		ItemId = itemId,
		Price = price,
		CreatedTime = os.time(),
	}
	local current = Store.GetListings()
	-- avoid duplicates on re-seed
	for _, item in ipairs(current) do
		if item.Id == id then return end
	end
	table.insert(current, listing)
	Store.SaveListings(current)
	MarketplaceService.Sync()
end

BuyReq.OnServerInvoke = function(player, listingId: string)
	if Lock.IsLocked(listingId) then
		return Constants.BUY_RESULT_LOCKED
	end
	if not Lock.Acquire(listingId) then
		return Constants.BUY_RESULT_LOCKED
	end

	local current = Store.GetListings()
	local foundIndex = nil
	for i, item in ipairs(current) do
		if item.Id == listingId then
			foundIndex = i
			break
		end
	end

	if not foundIndex then
		Lock.Release(listingId)
		return Constants.BUY_RESULT_NOT_FOUND
	end

	table.remove(current, foundIndex)
	Store.SaveListings(current)

	pcall(function()
		MessagingService:PublishAsync(Constants.MESSAGING_TOPIC, "update")
	end)

	Lock.Release(listingId)
	MarketplaceService.Sync()
	return Constants.BUY_RESULT_SUCCESS
end

MessagingService:SubscribeAsync(Constants.MESSAGING_TOPIC, function()
	MarketplaceService.Sync()
end)


Players.PlayerAdded:Connect(function(player)
	task.wait(1) 
	UpdateEv:FireClient(player, listings)
end)

print("marketplace service active")
MarketplaceService.Sync()

return MarketplaceService