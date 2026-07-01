local TweenService = game:GetService("TweenService")
local Config = require(script.Parent.TrackConfig)

local Manager = {}
Manager.__index = Manager

function Manager.new()
	local self = setmetatable({}, Manager)
	self.CurrentMood = Config.DefaultMood
	self.CurrentTrackIndex = 1
	self.Playlist = {}
	self.IsPlaying = false
	self.Volume = Config.DefaultVolume
	self._endedConn = nil
	self._fadingOut = false
	return self
end

function Manager:_getFolder()
	return Config.TracksLocation:FindFirstChild(Config.TracksFolderName)
end

function Manager:ScanTracks()
	local folder = self:_getFolder()
	if not folder then return {} end

	local list = {}
	for _, sound in ipairs(folder:GetChildren()) do
		if sound:IsA("Sound") then
			local mood = sound:FindFirstChild(Config.MoodValueName)
			if not mood or mood.Value == self.CurrentMood then
				sound.Volume = 0
				table.insert(list, sound)
			end
		end
	end

	if Config.ShuffleOnStart then
		for i = #list, 2, -1 do
			local j = math.random(i)
			list[i], list[j] = list[j], list[i]
		end
	end

	self.Playlist = list
	self.CurrentTrackIndex = 1
	return list
end

function Manager:GetCurrentTrack()
	return self.Playlist[self.CurrentTrackIndex]
end

function Manager:_fade(sound, target, duration)
	duration = duration or Config.FadeTime
	local tween = TweenService:Create(
		sound,
		TweenInfo.new(duration),
		{Volume = target}
	)
	tween:Play()
	return tween
end

function Manager:_connectEnded(sound)
	if self._endedConn then
		self._endedConn:Disconnect()
	end
	self._endedConn = sound.Ended:Connect(function()
		self:Next()
	end)
end

function Manager:Play()
	local track = self:GetCurrentTrack()
	if not track then return false end

	if track.IsPlaying then
		return true
	end

	track.Volume = 0
	track:Play()
	self:_fade(track, self.Volume)
	self:_connectEnded(track)
	self.IsPlaying = true

	local Signals = require(script.Parent.Signals)
	Signals.TrackChanged:Fire(track)
	Signals.PlayStateChanged:Fire(true)

	return true
end

function Manager:Stop()
	local current = self:GetCurrentTrack()
	if current then
		self._fadingOut = true
		local tween = self:_fade(current, 0)
		tween.Completed:Connect(function()
			current:Stop()
			self._fadingOut = false
		end)
	end
	self.IsPlaying = false

	local Signals = require(script.Parent.Signals)
	Signals.PlayStateChanged:Fire(false)
end

function Manager:Pause()
	local current = self:GetCurrentTrack()
	if current then
		self._fadingOut = true
		local tween = self:_fade(current, 0, 0.2)
		tween.Completed:Connect(function()
			current:Pause()
			self._fadingOut = false
		end)
	end
	self.IsPlaying = false

	local Signals = require(script.Parent.Signals)
	Signals.PlayStateChanged:Fire(false)
end

function Manager:Resume()
	local track = self:GetCurrentTrack()
	if not track then return false end

	track:Resume()
	self:_fade(track, self.Volume, 0.2)
	self.IsPlaying = true

	local Signals = require(script.Parent.Signals)
	Signals.PlayStateChanged:Fire(true)

	return true
end

function Manager:Next()
	local current = self:GetCurrentTrack()
	if current then current:Stop() end

	self.CurrentTrackIndex += 1
	if self.CurrentTrackIndex > #self.Playlist then
		self.CurrentTrackIndex = 1
	end

	return self:Play()
end

function Manager:Previous()
	local current = self:GetCurrentTrack()
	if current then current:Stop() end

	self.CurrentTrackIndex -= 1
	if self.CurrentTrackIndex < 1 then
		self.CurrentTrackIndex = #self.Playlist
	end

	return self:Play()
end

function Manager:SetMood(mood)
	local current = self:GetCurrentTrack()
	if current then
		self._fadingOut = true
		local tween = self:_fade(current, 0)
		tween.Completed:Connect(function()
			current:Stop()
			self._fadingOut = false
		end)
		task.wait(Config.FadeTime)
	end

	self.CurrentMood = mood
	self:ScanTracks()

	if self.IsPlaying then
		self:Play()
	end
end

function Manager:SetVolume(value)
	self.Volume = math.clamp(value, 0, 1)
	local track = self:GetCurrentTrack()
	if track and not self._fadingOut then 
		track.Volume = self.Volume 
	end
end

function Manager:GetMood()
	return self.CurrentMood
end

function Manager:GetPlaylist()
	return self.Playlist
end

function Manager:Shuffle()
	local current = self:GetCurrentTrack()
	for i = #self.Playlist, 2, -1 do
		local j = math.random(i)
		self.Playlist[i], self.Playlist[j] = self.Playlist[j], self.Playlist[i]
	end

	for i, sound in ipairs(self.Playlist) do
		if sound == current then
			self.CurrentTrackIndex = i
			break
		end
	end
end

function Manager:GoToTrack(index)
	if index < 1 or index > #self.Playlist then return false end

	local current = self:GetCurrentTrack()
	if current then current:Stop() end

	self.CurrentTrackIndex = index
	return self:Play()
end

return Manager