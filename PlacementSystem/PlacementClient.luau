local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

-- Assets
local PlacementSystem = ReplicatedStorage:WaitForChild("PlacementSystem")
local Models = PlacementSystem:WaitForChild("Models")
local Modules = PlacementSystem:WaitForChild("Modules")
local PlacementEngine = require(Modules.PlacementEngine)
local PlacementConfig = require(Modules.PlacementConfig)
local PlacementUI = require(Modules.PlacementUI)
local Signal = require(Modules.Signal)

-- Networking
local PlaceEvent = PlacementSystem.Remotes:WaitForChild("PlaceEvent")
local RemoveEvent = PlacementSystem.Remotes:WaitForChild("RemoveEvent")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- State
local engine = PlacementEngine.new()
local currentPreview: Model? = nil
local activeModelName: string = ""
local isRemovalMode: boolean = false
local visualRotation = 0
local lastValidCFrame: CFrame? = nil
local lastValidTarget: BasePart? = nil
local lastValidNormal: Vector3 = Vector3.new(0, 1, 0)

-- API
local OnPlaced = Signal.new()
local OnRemoved = Signal.new()
local PlacementAPI = {
	OnPlaced = OnPlaced,
	OnRemoved = OnRemoved,
}
_G.PlacementAPI = PlacementAPI

-- Loaded!
warn("Loaded Ghost's Placement!")

-- UI
local selectionHighlight = Instance.new("SelectionBox")
selectionHighlight.Color3 = Color3.fromRGB(255, 50, 50)
selectionHighlight.Parent = player.PlayerGui

-- Logic
local function FindAncestorWithAttribute(instance: Instance, attribute: string)
	local current = instance
	while current and current ~= workspace do
		if current:GetAttribute(attribute) then
			return current
		end
		current = current.Parent
	end
	return nil
end

local function StartPlacement(modelName: string)
	isRemovalMode = false
	selectionHighlight.Adornee = nil
	PlacementUI.SetRemovalState(false)
	
	if currentPreview then currentPreview:Destroy() end
	
	local template = Models:FindFirstChild(modelName)
	if not template then return end
	
	activeModelName = modelName
	currentPreview = template:Clone()
	
	-- Ghost
	for _, part in currentPreview:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.Transparency = 1 
			task.spawn(function()
				for i = 1, 10 do
					task.wait(0.02)
					if part and part.Parent then
						part.Transparency = 1 - (i * (1 - PlacementConfig.PREVIEW_TRANSPARENCY) / 10)
					end
				end
			end)
		end
	end
	
	currentPreview.Parent = workspace
	mouse.TargetFilter = currentPreview
	visualRotation = engine.CurrentRotation
end

local function RequestPlacement(isFromButton: boolean?)
	if not currentPreview then return end
	
	local targetCFrame = currentPreview:GetPivot()
	local targetPart = mouse.Target
	
	if isFromButton and lastValidCFrame then
		targetCFrame = lastValidCFrame
		targetPart = lastValidTarget
	end
	
	if engine:IsPositionValid(currentPreview, targetCFrame, targetPart) then
		local normal = lastValidNormal
		PlaceEvent:FireServer(activeModelName, targetCFrame, normal)
		OnPlaced:Fire(activeModelName, targetCFrame)
	end
end

-- Init
PlacementUI.Create(
	function(name) StartPlacement(name) end, 
	function(state)
		isRemovalMode = state
		if isRemovalMode then
			selectionHighlight.Adornee = nil
			if currentPreview then
				currentPreview:Destroy()
				currentPreview = nil
				mouse.TargetFilter = nil
			end
		end
	end,
	function() if currentPreview then engine:Rotate() end end,
	function() RequestPlacement(true) end
)

-- Loop
RunService.RenderStepped:Connect(function(dt)
	if isRemovalMode then
		local target = mouse.Target
		local model = target and FindAncestorWithAttribute(target, "PlacementItem")
		selectionHighlight.Adornee = (model and model:IsA("Model")) and model or nil
		return
	end
	
	if not currentPreview then return end
	
	-- UI Check
	local mousePos = UserInputService:GetMouseLocation()
	local guisAtPos = player.PlayerGui:GetGuiObjectsAtPosition(mousePos.X, mousePos.Y)
	local overUI = false
	for _, gui in guisAtPos do
		if (gui:IsA("TextButton") or gui:IsA("ImageButton")) and gui:IsDescendantOf(player.PlayerGui:FindFirstChild("PlacementUI")) then
			overUI = true
			break
		end
	end
	
	if not overUI then
		local targetRotation = engine.CurrentRotation
		local diff = (targetRotation - visualRotation + 180) % 360 - 180
		visualRotation = visualRotation + diff * math.min(dt * PlacementConfig.INTERPOLATION_SPEED, 1)
		
		local targetPart = mouse.Target
		local normal = targetPart and Vector3.fromNormalId(mouse.TargetSurface) or Vector3.new(0, 1, 0)
		local hitPos = mouse.Hit.Position
		
		local originalRot = engine.CurrentRotation
		engine.CurrentRotation = visualRotation
		local finalCFrame = engine:CalculateCFrame(currentPreview, hitPos, normal)
		engine.CurrentRotation = originalRot
		
		currentPreview:PivotTo(finalCFrame)
		
		-- Validation
		local isValid = engine:IsPositionValid(currentPreview, finalCFrame, mouse.Target)
		local taggedParts = CollectionService:GetTagged(PlacementConfig.SURFACE_TAG) or {}
		if #taggedParts > 0 and mouse.Target and not CollectionService:HasTag(mouse.Target, PlacementConfig.SURFACE_TAG) then
			isValid = false
		end
		
		if isValid then
			lastValidCFrame = finalCFrame
			lastValidTarget = mouse.Target
			lastValidNormal = normal
		end
		
		-- Visuals
		local color = isValid and PlacementConfig.VALID_COLOR or PlacementConfig.INVALID_COLOR
		for _, part in currentPreview:GetDescendants() do
			if part:IsA("BasePart") then part.Color = color end
		end
	else
		-- UI Freeze
		if lastValidCFrame then
			currentPreview:PivotTo(lastValidCFrame)
			for _, part in currentPreview:GetDescendants() do
				if part:IsA("BasePart") then part.Color = PlacementConfig.VALID_COLOR end
			end
		end
	end
end)

-- Toggle Shortcut
_G.TogglePlacementUI = function()
	PlacementUI.ToggleVisibility()
end

-- Inputs
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	
	if input.KeyCode == PlacementConfig.KEYBINDS.ROTATE and currentPreview then
		engine:Rotate()
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
		if isRemovalMode then
			local target = mouse.Target
			local model = target and FindAncestorWithAttribute(target, "PlacementItem")
			if model and model:IsA("Model") then
				RemoveEvent:FireServer(model)
				OnRemoved:Fire(model)
			end
		else
			RequestPlacement()
		end
	elseif input.KeyCode == PlacementConfig.KEYBINDS.CANCEL then
		if currentPreview then
			currentPreview:Destroy()
			currentPreview = nil
			mouse.TargetFilter = nil
		end
		isRemovalMode = false
		selectionHighlight.Adornee = nil
		PlacementUI.SetRemovalState(false)
	elseif input.KeyCode == PlacementConfig.KEYBINDS.TOGGLE_REMOVAL then
		isRemovalMode = not isRemovalMode
		PlacementUI.SetRemovalState(isRemovalMode)
		if isRemovalMode then
			selectionHighlight.Adornee = nil
			if currentPreview then
				currentPreview:Destroy()
				currentPreview = nil
				mouse.TargetFilter = nil
			end
		end
	elseif input.KeyCode == PlacementConfig.KEYBINDS.TOGGLE_UI then
		PlacementUI.ToggleVisibility()
	end
end)
