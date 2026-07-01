local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local updating = false

local Config = require(script.Parent.TrackConfig)
local Manager = require(script.Parent.MusicManager)
local Signals = require(script.Parent.Signals)

local Controller = {}
Controller.__index = Controller

function Controller.new()
	local self = setmetatable({}, Controller)
	self.Manager = Manager.new()
	self.Gui = nil
	self.IsVisible = false
	self.AlbumRotation = 0
	self._albumRotationLoop = nil
	self._progressLoop = nil
	return self
end

function Controller:_setupGui()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local gui = playerGui:WaitForChild(Config.GuiName, 10)

	if not gui then return end

	self.Gui = gui

	local card = self:_getCard()
	if card then
		if not card:GetAttribute("OriginalPosYScale") then
			card:SetAttribute("OriginalPosYScale", card.Position.Y.Scale)
			card:SetAttribute("OriginalPosYOffset", card.Position.Y.Offset)
		end

		card.Visible = false
		card.Position = UDim2.new(
			card.Position.X.Scale,
			card.Position.X.Offset,
			card.Position.Y.Scale,
			card.Position.Y.Offset + Config.UIAnimations.CardSlideDistance
		)

		self:_setTransparency(card, 1)
	end
end

function Controller:_getCard()
	if not self.Gui then return nil end
	return self.Gui:FindFirstChild("PlayerCard")
end

function Controller:_setTransparency(element, transparency)
	for _, child in ipairs(element:GetDescendants()) do
		if child:IsA("GuiObject") then
			if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
				child.TextTransparency = transparency
			end
			if child:IsA("ImageLabel") or child:IsA("ImageButton") then
				child.ImageTransparency = transparency
			end
			if child.BackgroundTransparency < 1 then
				if not child:GetAttribute("OriginalBGTransparency") then
					child:SetAttribute("OriginalBGTransparency", child.BackgroundTransparency)
				end
				local originalBG = child:GetAttribute("OriginalBGTransparency")
				child.BackgroundTransparency = transparency + (originalBG * (1 - transparency))
			end
		end
	end
end

function Controller:_animateShow()
	if self.IsVisible then return end
	self.IsVisible = true

	local card = self:_getCard()
	if not card then return end

	card.Visible = true

	local originalPosYScale = card:GetAttribute("OriginalPosYScale") or card.Position.Y.Scale
	local originalPosYOffset = card:GetAttribute("OriginalPosYOffset") or card.Position.Y.Offset

	local originalPos = UDim2.new(
		card.Position.X.Scale,
		card.Position.X.Offset,
		originalPosYScale,
		originalPosYOffset
	)

	local slideInfo = TweenInfo.new(
		Config.UIAnimations.ShowDuration,
		Config.UIAnimations.ShowEasing,
		Config.UIAnimations.ShowDirection
	)

	local slideTween = TweenService:Create(card, slideInfo, {
		Position = originalPos
	})

	slideTween:Play()

	task.spawn(function()
		local steps = 10
		for i = 1, steps do
			local alpha = i / steps
			self:_setTransparency(card, 1 - alpha)
			task.wait(Config.UIAnimations.ShowDuration / steps)
		end
		self:_setTransparency(card, 0)
	end)

	if self.Manager.IsPlaying then
		self:_startAlbumRotation()
	end
end

function Controller:_animateHide()
	if not self.IsVisible then return end
	self.IsVisible = false

	local card = self:_getCard()
	if not card then return end

	self:_stopAlbumRotation()

	local hideInfo = TweenInfo.new(
		Config.UIAnimations.HideDuration,
		Config.UIAnimations.HideEasing,
		Config.UIAnimations.HideDirection
	)

	local originalPosYScale = card:GetAttribute("OriginalPosYScale") or card.Position.Y.Scale
	local originalPosYOffset = card:GetAttribute("OriginalPosYOffset") or card.Position.Y.Offset

	local targetPos = UDim2.new(
		card.Position.X.Scale,
		card.Position.X.Offset,
		originalPosYScale,
		originalPosYOffset + Config.UIAnimations.CardSlideDistance
	)

	local hideTween = TweenService:Create(card, hideInfo, {
		Position = targetPos
	})

	hideTween:Play()

	task.spawn(function()
		local steps = 10
		for i = 1, steps do
			local alpha = i / steps
			self:_setTransparency(card, alpha)
			task.wait(Config.UIAnimations.HideDuration / steps)
		end
		self:_setTransparency(card, 1)
	end)

	hideTween.Completed:Connect(function()
		card.Visible = false
	end)
end

function Controller:_startAlbumRotation()
	self:_stopAlbumRotation()

	self._albumRotationLoop = task.spawn(function()
		local card = self:_getCard()
		if not card then return end

		local albumArt = card:FindFirstChild("AlbumArt")
		local albumImage = albumArt and albumArt:FindFirstChild("AlbumImage")

		if albumImage then
			while self.Manager.IsPlaying and self.IsVisible do
				self.AlbumRotation = (self.AlbumRotation + Config.UIAnimations.AlbumRotationSpeed * 0.05) % 360
				albumImage.Rotation = self.AlbumRotation
				task.wait(0.05)
			end
		end
	end)
end

function Controller:_stopAlbumRotation()
	if self._albumRotationLoop then
		task.cancel(self._albumRotationLoop)
		self._albumRotationLoop = nil
	end

	local card = self:_getCard()
	if card then
		local albumArt = card:FindFirstChild("AlbumArt")
		local albumImage = albumArt and albumArt:FindFirstChild("AlbumImage")

		if albumImage then
			local resetInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local resetTween = TweenService:Create(albumImage, resetInfo, {Rotation = 0})
			resetTween:Play()
			self.AlbumRotation = 0
		end
	end
end

function Controller:_updateInfo()
	if updating then return end
	updating = true

	local card = self:_getCard()
	local track = self.Manager:GetCurrentTrack()

	if card and track then
		local title = card:FindFirstChild("TrackTitle")
		local artist = card:FindFirstChild("ArtistName")
		local albumArt = card:FindFirstChild("AlbumArt")
		local albumImage = albumArt and albumArt:FindFirstChild("AlbumImage")

		if title then
			local fadeOut = TweenService:Create(title, TweenInfo.new(0.15), {TextTransparency = 1})
			fadeOut:Play()
			fadeOut.Completed:Connect(function()
				title.Text = track.Name
				local fadeIn = TweenService:Create(title, TweenInfo.new(0.15), {TextTransparency = 0})
				fadeIn:Play()
			end)
		end

		local artistVal = track:FindFirstChild("Artist")
		if artist then
			local fadeOut = TweenService:Create(artist, TweenInfo.new(0.15), {TextTransparency = 1})
			fadeOut:Play()
			fadeOut.Completed:Connect(function()
				artist.Text = artistVal and artistVal.Value or "Unknown Artist"
				local fadeIn = TweenService:Create(artist, TweenInfo.new(0.15), {TextTransparency = 0})
				fadeIn:Play()
			end)
		end

		local coverVal = track:FindFirstChild("AlbumCover")
		if albumImage and coverVal then
			local fadeOut = TweenService:Create(albumImage, TweenInfo.new(0.15), {ImageTransparency = 1})
			fadeOut:Play()
			fadeOut.Completed:Connect(function()
				albumImage.Image = coverVal.Value
				local fadeIn = TweenService:Create(albumImage, TweenInfo.new(0.15), {ImageTransparency = 0})
				fadeIn:Play()
			end)
		end
	end

	updating = false
end

function Controller:_updatePlayButtonImage()
	local card = self:_getCard()
	if not card then return end

	local playButton = card:FindFirstChild("PlayButton")
	if playButton and playButton:IsA("ImageButton") then
		local targetImage = self.Manager.IsPlaying 
			and "rbxassetid://91241285290661" 
			or "rbxassetid://108121732295170"

		local fadeOut = TweenService:Create(playButton, TweenInfo.new(0.1), {ImageTransparency = 1})
		fadeOut:Play()
		fadeOut.Completed:Connect(function()
			playButton.Image = targetImage
			local fadeIn = TweenService:Create(playButton, TweenInfo.new(0.1), {ImageTransparency = 0})
			fadeIn:Play()
		end)
	end
end

function Controller:_addButtonHoverEffects()
	local card = self:_getCard()
	if not card then return end

	local function addHover(button)
		if not button or not button:IsA("GuiButton") then return end

		local originalSize = button.Size

		button.MouseEnter:Connect(function()
			local tween = TweenService:Create(
				button,
				TweenInfo.new(Config.UIAnimations.ButtonHoverDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Size = UDim2.new(
					originalSize.X.Scale * Config.UIAnimations.ButtonHoverScale,
					originalSize.X.Offset * Config.UIAnimations.ButtonHoverScale,
					originalSize.Y.Scale * Config.UIAnimations.ButtonHoverScale,
					originalSize.Y.Offset * Config.UIAnimations.ButtonHoverScale
					)}
			)
			tween:Play()
		end)

		button.MouseLeave:Connect(function()
			local tween = TweenService:Create(
				button,
				TweenInfo.new(Config.UIAnimations.ButtonHoverDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Size = originalSize}
			)
			tween:Play()
		end)
	end

	addHover(card:FindFirstChild("PlayButton"))
	addHover(card:FindFirstChild("NextButton"))
	addHover(card:FindFirstChild("PreviousButton"))
end

function Controller:_bindButtons()
	local card = self:_getCard()
	if not card then return end

	local function bind(name, fn)
		local b = card:FindFirstChild(name)
		if b and b:IsA("GuiButton") then
			b.Activated:Connect(fn)
		end
	end

	bind("PlayButton", function()
		if self.Manager.IsPlaying then
			self.Manager:Pause()
		else
			local track = self.Manager:GetCurrentTrack()
			if track and track.TimePosition > 0 then
				self.Manager:Resume()
			else
				self.Manager:Play()
			end
		end
		self:_updatePlayButtonImage()
	end)

	bind("NextButton", function()
		self.Manager:Next()
		self:_updateInfo()
		self:_updatePlayButtonImage()
	end)

	bind("PreviousButton", function()
		self.Manager:Previous()
		self:_updateInfo()
		self:_updatePlayButtonImage()
	end)
end

function Controller:_updateProgress()
	local card = self:_getCard()
	local track = self.Manager:GetCurrentTrack()

	if not card or not track or track.TimeLength == 0 then return end

	local progressBg = card:FindFirstChild("ProgressBarBackground")
	if not progressBg then return end

	local fill = progressBg:FindFirstChild("ProgressBarFill")
	if fill then
		local progress = track.TimePosition / track.TimeLength

		local tween = TweenService:Create(
			fill,
			TweenInfo.new(Config.UIAnimations.ProgressUpdateRate, Enum.EasingStyle.Linear),
			{Size = UDim2.new(progress, 0, 1, 0)}
		)
		tween:Play()
	end
end

function Controller:_startProgressLoop()
	if self._progressLoop then
		task.cancel(self._progressLoop)
	end

	self._progressLoop = task.spawn(function()
		while self.IsVisible do
			self:_updateProgress()
			task.wait(Config.UIAnimations.ProgressUpdateRate)
		end
	end)
end

function Controller:_stopProgressLoop()
	if self._progressLoop then
		task.cancel(self._progressLoop)
		self._progressLoop = nil
	end
end

function Controller:Start()
	self:_setupGui()
	self.Manager:ScanTracks()
	self:_bindButtons()
	self:_addButtonHoverEffects()

	Signals.TrackChanged.Event:Connect(function()
		self:_updateInfo()
		self:_updatePlayButtonImage()
	end)

	Signals.PlayStateChanged.Event:Connect(function(isPlaying)
		if isPlaying then
			self:_animateShow()
			self:_startProgressLoop()
			self:_startAlbumRotation()
		else
			local track = self.Manager:GetCurrentTrack()
			if not track or track.TimePosition == 0 then
				self:_animateHide()
				self:_stopProgressLoop()
				self:_stopAlbumRotation()
			else
				self:_stopAlbumRotation()
			end
		end
		self:_updatePlayButtonImage()
	end)
end

function Controller:Destroy()
	self:_stopProgressLoop()
	self:_stopAlbumRotation()
	if self.Manager._endedConn then
		self.Manager._endedConn:Disconnect()
	end
end

return Controller