
local ServerScriptService = game:GetService("ServerScriptService")
local MarketplaceService = require(ServerScriptService:WaitForChild("MarketplaceService"))

MarketplaceService.AddListing("Item_123", 1, 101, 500)
MarketplaceService.AddListing("Item_456", 1, 102, 250)

print("test listings seeded")


local ServerScriptService = game:GetService("ServerScriptService")

require(ServerScriptService:WaitForChild("MarketplaceService"))