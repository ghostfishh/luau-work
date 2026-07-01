local PlacementConfig = {
	-- Config
	GRID_SIZE = 2,
	ROTATION_STEP = 90,
	MAX_PLACEMENT_DISTANCE = 50,
	
	-- Visuals
	PREVIEW_TRANSPARENCY = 0.5,
	VALID_COLOR = Color3.fromRGB(0, 255, 100),
	INVALID_COLOR = Color3.fromRGB(255, 50, 50),
	INTERPOLATION_SPEED = 15,
	
	-- Binds
	KEYBINDS = {
		ROTATE = Enum.KeyCode.R,
		CANCEL = Enum.KeyCode.Q,
		TOGGLE_REMOVAL = Enum.KeyCode.X,
		TOGGLE_UI = Enum.KeyCode.B,
	},
	
	-- Pro
	SURFACE_TAG = "Placeable",
	ITEM_ATTRIBUTE = "PlacementItem",
	OWNER_ATTRIBUTE = "Owner",
	
	-- Mobile
	MOBILE_BTN_SIZE = 100,
	MOBILE_BTN_COLOR_ROTATE = Color3.fromRGB(80, 80, 200),
	MOBILE_BTN_COLOR_PLACE = Color3.fromRGB(80, 200, 80),
}

return PlacementConfig
