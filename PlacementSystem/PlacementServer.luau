-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Assets
local PlacementSystem = ReplicatedStorage:WaitForChild("PlacementSystem")
local Models = PlacementSystem:WaitForChild("Models")
local Modules = PlacementSystem:WaitForChild("Modules")
local PlacementEngine = require(Modules.PlacementEngine)
local Signal = require(Modules.Signal)
local VFXHandler = require(Modules.VFXHandler)

-- Networking
local PlaceEvent = PlacementSystem.Remotes:FindFirstChild("PlaceEvent") or Instance.new("RemoteEvent")
PlaceEvent.Name = "PlaceEvent"
PlaceEvent.Parent = PlacementSystem.Remotes

local RemoveEvent = PlacementSystem.Remotes:FindFirstChild("RemoveEvent") or Instance.new("RemoteEvent")
RemoveEvent.Name = "RemoveEvent"
RemoveEvent.Parent = PlacementSystem.Remotes

-- API
local OnPlaced = Signal.new()
local OnRemoved = Signal.new()
local PlacementAPI = {
	OnPlaced = OnPlaced,
	OnRemoved = OnRemoved,
}
_G.PlacementAPI = PlacementAPI

local engine = PlacementEngine.new()

-- Logic
local function TagModel(model: Model, player: Player)
	model:SetAttribute("Owner", player.UserId)
	model:SetAttribute("PlacementItem", true)
end

-- Placement
PlaceEvent.OnServerEvent:Connect(function(player, modelName, targetCFrame, normal)
	local template = Models:FindFirstChild(modelName)
	if not template then return end
	
	if engine:IsPositionValid(template, targetCFrame) then
		local newModel = template:Clone()
		newModel:PivotTo(targetCFrame)
		newModel.Parent = workspace
		
		TagModel(newModel, player)
		VFXHandler.PlayPlacementVFX(targetCFrame.Position)
		
		-- API
		OnPlaced:Fire(player, modelName, targetCFrame)
	else
		warn(player.Name .. " invalid placement")
	end
end)

-- Removal
RemoveEvent.OnServerEvent:Connect(function(player, target: Instance)
	if not target:IsA("Model") or not target:GetAttribute("PlacementItem") then return end
	
	-- Security
	if target:GetAttribute("Owner") ~= player.UserId then 
		warn(player.Name .. " unauthorized delete")
		return 
	end
	
	VFXHandler.PlayRemovalVFX(target:GetPivot().Position)
	
	-- API
	OnRemoved:Fire(player, target)
	
	target:Destroy()
end)
