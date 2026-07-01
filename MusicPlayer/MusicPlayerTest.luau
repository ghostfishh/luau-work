local Players = game:GetService("Players")
local player = Players.LocalPlayer

local ShopHitbox = workspace:WaitForChild("ShopHitbox")

local isInShop = false
local debounce = false

local function enterShop()
	if debounce then return end
	debounce = true

	isInShop = true
	_G.MusicPlayer:SetMood("Shop")
	_G.MusicPlayer:Play()

	task.wait(0.5)
	debounce = false
end

local function exitShop()
	if debounce then return end
	debounce = true

	isInShop = false
	_G.MusicPlayer:SetMood("Outside")
	_G.MusicPlayer:Play()

	task.wait(0.5)
	debounce = false
end

ShopHitbox.Touched:Connect(function(hit)
	if hit.Parent and hit.Parent:FindFirstChild("Humanoid") then
		local character = hit.Parent
		if character == player.Character then
			if not isInShop then
				enterShop()
			end
		end
	end
end)

ShopHitbox.TouchEnded:Connect(function(hit)
	if hit.Parent and hit.Parent:FindFirstChild("Humanoid") then
		local character = hit.Parent
		if character == player.Character then
			if isInShop then
				exitShop()
			end
		end
	end
end)