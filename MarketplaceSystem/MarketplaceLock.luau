local MemoryStoreService = game:GetService("MemoryStoreService")
local Constants = require(game:GetService("ReplicatedStorage"):WaitForChild("MarketplaceConstants"))

local MarketplaceLock = {}
local map = MemoryStoreService:GetSortedMap("MarketplaceLocks")

function MarketplaceLock.Acquire(listingId: string): boolean
	local success = pcall(function()
		map:SetAsync(listingId, 0, Constants.LOCK_EXPIRY)
	end)
	return success
end

function MarketplaceLock.Release(listingId: string)
	pcall(function()
		map:RemoveAsync(listingId)
	end)
end

function MarketplaceLock.IsLocked(listingId: string): boolean
	local success, val = pcall(function()
		return map:GetAsync(listingId)
	end)
	return success and val ~= nil
end

return MarketplaceLock