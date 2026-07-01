local PlacementConfig = require(script.Parent.PlacementConfig)

local PlacementEngine = {}
PlacementEngine.__index = PlacementEngine

export type PlacementEngine = {
	GridSize: number,
	RotationStep: number,
	Plot: BasePart?,
	CurrentRotation: number,
}

function PlacementEngine.new(plot: BasePart?)
	local self = setmetatable({}, PlacementEngine)
	
	-- Setup
	self.GridSize = PlacementConfig.GRID_SIZE
	self.RotationStep = PlacementConfig.ROTATION_STEP
	self.Plot = plot
	self.CurrentRotation = 0
	
	return self
end

-- Snap
function PlacementEngine:SnapValue(value: number): number
	return math.round(value / self.GridSize) * self.GridSize
end

-- Math
function PlacementEngine:CalculateCFrame(model: Model, hitPosition: Vector3, normal: Vector3?): CFrame
	local normal = normal or Vector3.new(0, 1, 0)
	
	-- Orientation
	local vY = normal
	local vX, vZ
	
	if math.abs(vY:Dot(Vector3.new(0, 1, 0))) > 0.99 then
		-- Floor/Ceiling
		vZ = Vector3.new(0, 0, 1)
		vX = vY:Cross(vZ).Unit
		vZ = vX:Cross(vY).Unit
	else
		-- Walls
		local worldUp = Vector3.new(0, 1, 0)
		vX = vY:Cross(worldUp).Unit
		vZ = vX:Cross(vY).Unit
	end
	
	-- Position
	local snappedX = self:SnapValue(hitPosition.X)
	local snappedY = self:SnapValue(hitPosition.Y)
	local snappedZ = self:SnapValue(hitPosition.Z)
	local snappedPos = Vector3.new(snappedX, snappedY, snappedZ)
	
	-- Pivot Offset
	local modelCFrame, size = model:GetBoundingBox()
	local pivot = model:GetPivot()
	local relativeCenter = pivot:Inverse() * modelCFrame
	local distFromBottomToPivot = -(relativeCenter.Y - (size.Y / 2))
	local targetPivotPos = snappedPos + (normal * distFromBottomToPivot)
	
	-- Combine
	local baseCFrame = CFrame.fromMatrix(targetPivotPos, vX, vY, vZ)
	local rotationCFrame = CFrame.Angles(0, math.rad(self.CurrentRotation), 0)
	
	return baseCFrame * rotationCFrame
end

-- Rotation
function PlacementEngine:Rotate()
	self.CurrentRotation = (self.CurrentRotation + self.RotationStep) % 360
end

-- Collisions
function PlacementEngine:IsPositionValid(model: Model, targetPivotCFrame: CFrame, floorPart: BasePart?): boolean
	local modelCFrame, size = model:GetBoundingBox()
	local pivotToCenterOffset = modelCFrame.Position - model:GetPivot().Position
	local targetBoxCenterCFrame = targetPivotCFrame * CFrame.new(pivotToCenterOffset)
	local collisionSize = size - Vector3.new(0.01, 0.05, 0.01)
	
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {model}
	
	local collisions = workspace:GetPartBoundsInBox(targetBoxCenterCFrame, collisionSize, params)
	
	local isValid = true
	for _, part in collisions do
		-- Ignore floor
		if part ~= self.Plot and part ~= floorPart then
			isValid = false
			break
		end
	end
	
	return isValid
end

return PlacementEngine
