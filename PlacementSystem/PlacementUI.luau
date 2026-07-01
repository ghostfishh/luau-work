--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local PlacementSystem = ReplicatedStorage:WaitForChild("PlacementSystem")
local Models = PlacementSystem:WaitForChild("Models")

local PlacementUI = {}
local mainGui: ScreenGui? = nil
local contentFrame: Frame? = nil
local openBtn: TextButton? = nil
local removeToggleBtn: TextButton? = nil

-- Toggle
function PlacementUI.ToggleVisibility(visible: boolean?)
	if not contentFrame or not openBtn then return end
	local isNowVisible = if visible ~= nil then visible else not contentFrame.Visible
	
	contentFrame.Visible = isNowVisible
	openBtn.Visible = not isNowVisible
end

function PlacementUI.SetRemovalState(isActive: boolean)
	if not removeToggleBtn then return end
	if isActive then
		removeToggleBtn.Text = "Removal: ON"
		removeToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
	else
		removeToggleBtn.Text = "Removal: OFF"
		removeToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	end
end

function PlacementUI.Create(onSelect: (string) -> (), onToggle: (boolean) -> (), onRotate: () -> (), onPlace: () -> ())
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	-- Clean up existing UI
	local oldUI = playerGui:FindFirstChild("PlacementUI")
	if oldUI then oldUI:Destroy() end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Parent = playerGui
	mainGui = screenGui

	-- Open Button (Hidden by default)
	local open = Instance.new("TextButton")
	open.Name = "OpenPlacementUI"
	open.Size = UDim2.new(0, 120, 0, 40)
	open.Position = UDim2.new(0.5, 0, 1, -60)
	open.AnchorPoint = Vector2.new(0.5, 0)
	open.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	open.BackgroundTransparency = 0.2
	open.Text = "OPEN PLACEMENT"
	open.TextColor3 = Color3.fromRGB(255, 255, 255)
	open.Font = Enum.Font.GothamBold
	open.Visible = false
	open.Parent = screenGui
	openBtn = open
	
	local openCorner = Instance.new("UICorner")
	openCorner.CornerRadius = UDim.new(0, 8)
	openCorner.Parent = open
	
	open.MouseButton1Click:Connect(function()
		PlacementUI.ToggleVisibility(true)
	end)

	-- Content Frame
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, 0, 1, 0)
	content.BackgroundTransparency = 1
	content.Parent = screenGui
	contentFrame = content

	-- Close Button (Inside Content)
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.new(0, 30, 0, 30)
	closeBtn.Position = UDim2.new(0.8, 10, 1, -125)
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = content
	
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(1, 0)
	closeCorner.Parent = closeBtn
	
	closeBtn.MouseButton1Click:Connect(function()
		PlacementUI.ToggleVisibility(false)
	end)

	-- Selection
	local frame = Instance.new("ScrollingFrame")
	frame.Name = "SelectionBar"
	frame.Size = UDim2.new(0.6, 0, 0, 110)
	frame.Position = UDim2.new(0.5, 0, 1, -130)
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	frame.BackgroundTransparency = 0.3
	frame.BorderSizePixel = 0
	frame.ScrollBarThickness = 4
	frame.CanvasSize = UDim2.new(0, 0, 0, 0)
	frame.AutomaticCanvasSize = Enum.AutomaticSize.X
	frame.Parent = content

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 10)
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = frame

	-- Add item buttons
	for _, modelTemplate in Models:GetChildren() do
		if not modelTemplate:IsA("Model") then continue end
		
		local button = Instance.new("TextButton")
		button.Name = modelTemplate.Name
		button.Size = UDim2.new(0, 90, 0, 90)
		button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		button.Text = ""
		button.Parent = frame
		
		local uiScale = Instance.new("UIScale")
		uiScale.Parent = button
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = button
		
		-- 3D Viewport Preview
		local viewport = Instance.new("ViewportFrame")
		viewport.Size = UDim2.new(1, 0, 1, 0)
		viewport.BackgroundTransparency = 1
		viewport.Parent = button
		
		local previewModel = modelTemplate:Clone()
		previewModel:PivotTo(CFrame.new(0, 0, 0))
		previewModel.Parent = viewport
		
		local cam = Instance.new("Camera")
		cam.FieldOfView = 50
		viewport.CurrentCamera = cam
		cam.Parent = viewport
		
		local _, size = previewModel:GetBoundingBox()
		local dist = size.Magnitude * 1.5
		
		local angle = 0
		local isHovering = false
		
		local function UpdateCamera()
			local rotation = CFrame.Angles(0, math.rad(angle), 0)
			local cameraPos = (rotation * Vector3.new(dist, dist*0.6, dist))
			cam.CFrame = CFrame.new(cameraPos, Vector3.new(0, 0, 0))
		end
		
		UpdateCamera()
		
		local connection = RunService.RenderStepped:Connect(function(dt)
			if isHovering then
				angle += 90 * dt
				UpdateCamera()
			end
		end)
		
		button.MouseEnter:Connect(function() 
			isHovering = true 
			TweenService:Create(uiScale, TweenInfo.new(0.2), {Scale = 1.1}):Play()
		end)
		button.MouseLeave:Connect(function() 
			isHovering = false 
			TweenService:Create(uiScale, TweenInfo.new(0.2), {Scale = 1.0}):Play()
		end)
		
		button.Destroying:Connect(function()
			connection:Disconnect()
		end)
		
		-- Title Label
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, 20)
		label.Position = UDim2.new(0, 0, 1, -20)
		label.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		label.BackgroundTransparency = 0.5
		label.Text = modelTemplate.Name
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.Font = Enum.Font.GothamBold
		label.TextSize = 10
		label.Parent = button
		
		local labelCorner = Instance.new("UICorner")
		labelCorner.CornerRadius = UDim.new(0, 8)
		labelCorner.Parent = label
		
		button.MouseButton1Click:Connect(function()
			onSelect(modelTemplate.Name)
		end)
	end

	-- Removal Mode Toggle
	local removeToggle = Instance.new("TextButton")
	removeToggle.Name = "RemovalToggle"
	removeToggle.Size = UDim2.new(0, 120, 0, 40)
	removeToggle.Position = UDim2.new(0.5, 0, 1, -180)
	removeToggle.AnchorPoint = Vector2.new(0.5, 0)
	removeToggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	removeToggle.Text = "Removal: OFF"
	removeToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
	removeToggle.Font = Enum.Font.GothamBold
	removeToggle.Parent = content
	
	removeToggleBtn = removeToggle
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = removeToggle
	
	removeToggle.MouseButton1Click:Connect(function()
		local newState = removeToggle.Text:find("OFF") ~= nil
		onToggle(newState)
		PlacementUI.SetRemovalState(newState)
	end)

	-- Mobile Controls (Only if TouchEnabled)
	local UserInputService = game:GetService("UserInputService")
	if UserInputService.TouchEnabled then
		local mobileContainer = Instance.new("Frame")
		mobileContainer.Name = "MobileControls"
		mobileContainer.Size = UDim2.new(0, 220, 0, 100)
		mobileContainer.Position = UDim2.new(1, -230, 0.5, -50)
		mobileContainer.BackgroundTransparency = 1
		mobileContainer.Parent = content
		
		local function CreateMobileBtn(name: string, pos: UDim2, text: string, color: Color3)
			local btn = Instance.new("TextButton")
			btn.Name = name
			btn.Size = UDim2.new(0, 100, 0, 100)
			btn.Position = pos
			btn.BackgroundColor3 = color
			btn.BackgroundTransparency = 0.3
			btn.Text = text
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			btn.Font = Enum.Font.GothamBlack
			btn.TextSize = 20
			btn.Parent = mobileContainer
			
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 50) -- Circle
			corner.Parent = btn
			
			return btn
		end
		
		local rotateBtn = CreateMobileBtn("MobileRotate", UDim2.new(0, 0, 0, 0), "R", Color3.fromRGB(80, 80, 200))
		local placeBtn = CreateMobileBtn("MobilePlace", UDim2.new(0, 110, 0, 0), "PLACE", Color3.fromRGB(80, 200, 80))
		
		rotateBtn.MouseButton1Click:Connect(onRotate)
		placeBtn.MouseButton1Click:Connect(onPlace)
	end
end

return PlacementUI
