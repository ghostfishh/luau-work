local DataStoreService = game:GetService("DataStoreService")
local Constants = require(game:GetService("ReplicatedStorage"):WaitForChild("MarketplaceConstants"))

local MarketplaceStore = {}
local store = DataStoreService:GetDataStore(Constants.DATASTORE_KEY)

function MarketplaceStore.GetListings(): {any}
	local success, result = pcall(function()
		return store:GetAsync("AllListings")
	end)
	return if success then result or {} else {}
end

function MarketplaceStore.SaveListings(listings: {any})
	pcall(function()
		store:SetAsync("AllListings", listings)
	end)
end

return MarketplaceStore