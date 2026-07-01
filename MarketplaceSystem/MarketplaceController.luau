local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Events = ReplicatedStorage:WaitForChild("MarketplaceEvents")
local BuyReq = Events:WaitForChild("BuyRequest")
local UpdateEv = Events:WaitForChild("MarketplaceUpdate")
local Constants = require(ReplicatedStorage:WaitForChild("MarketplaceConstants"))

local MarketplaceController = {}

local function getButton(listingId: string)
	-- search all guis for a button whose ListingId attribute matches
	local gui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MarketplaceUI")
	for _, btn in ipairs(gui:GetDescendants()) do
		if btn:IsA("TextButton") and btn:GetAttribute("ListingId") == listingId then
			return btn
		end
	end
	return nil
end

local function setButtonState(button, active: boolean, text: string)
	if not button then return end
	button.Text = text
	button.Active = active
end

UpdateEv.OnClientEvent:Connect(function(listings)
	local gui = Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("MarketplaceUI")
	if not gui then return end

	-- build a lookup for fast id checking
	local available = {}
	for _, item in ipairs(listings) do
		available[item.Id] = true
	end

	-- update every button in the gui based on whether its listing still exists
	for _, btn in ipairs(gui:GetDescendants()) do
		if btn:IsA("TextButton") and btn:GetAttribute("ListingId") then
			local id = btn:GetAttribute("ListingId")
			if btn.Text == "Processing..." then continue end
			if available[id] then
				setButtonState(btn, true, "Buy")
			elseif #listings > 0 then
				-- only mark sold out if we have real data, not an empty first sync
				setButtonState(btn, false, "Sold Out")
			end
		end
	end
end)

function MarketplaceController.RequestBuy(listingId: string): boolean
	local button = getButton(listingId)
	setButtonState(button, false, "Processing...")

	local success, result = pcall(function()
		return BuyReq:InvokeServer(listingId)
	end)

	if not success then
		setButtonState(button, true, "Error – Try Again")
		return false
	end

	if result == Constants.BUY_RESULT_SUCCESS then
		setButtonState(button, false, "Purchased!")
		return true
	elseif result == Constants.BUY_RESULT_LOCKED then
		setButtonState(button, true, "Busy – Try Again")
		return false
	elseif result == Constants.BUY_RESULT_NOT_FOUND then
		setButtonState(button, false, "Sold Out")
		return false
	end

	setButtonState(button, true, "Error – Try Again")
	return false
end

return MarketplaceController