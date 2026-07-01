local MusicPlayerAPI = {}

local Controller = nil
local Manager = nil

function MusicPlayerAPI:Initialize(controllerInstance)
	Controller = controllerInstance
	Manager = controllerInstance.Manager
end

function MusicPlayerAPI:Play()
	if not Manager then return false end
	return Manager:Play()
end

function MusicPlayerAPI:Stop()
	if not Manager then return end
	Manager:Stop()
end

function MusicPlayerAPI:Pause()
	if not Manager then return end
	Manager:Pause()
end

function MusicPlayerAPI:Resume()
	if not Manager then return false end
	return Manager:Resume()
end

function MusicPlayerAPI:Next()
	if not Manager then return false end
	return Manager:Next()
end

function MusicPlayerAPI:Previous()
	if not Manager then return false end
	return Manager:Previous()
end

function MusicPlayerAPI:TogglePlayPause()
	if not Manager then return end

	if Manager.IsPlaying then
		self:Pause()
	else
		local track = Manager:GetCurrentTrack()
		if track and track.TimePosition > 0 then
			self:Resume()
		else
			self:Play()
		end
	end
end

function MusicPlayerAPI:GoToTrack(index)
	if not Manager then return false end
	return Manager:GoToTrack(index)
end

function MusicPlayerAPI:Shuffle()
	if not Manager then return end
	Manager:Shuffle()
end

function MusicPlayerAPI:RescanTracks()
	if not Manager then return {} end
	return Manager:ScanTracks()
end

function MusicPlayerAPI:SetMood(moodName)
	if not Manager then return end
	Manager:SetMood(moodName)
end

function MusicPlayerAPI:GetMood()
	if not Manager then return nil end
	return Manager:GetMood()
end

function MusicPlayerAPI:SetVolume(volume)
	if not Manager then return end
	Manager:SetVolume(volume)
end

function MusicPlayerAPI:GetVolume()
	if not Manager then return 0 end
	return Manager.Volume
end

function MusicPlayerAPI:VolumeUp()
	if not Manager then return end
	local newVolume = math.min(Manager.Volume + 0.1, 1)
	Manager:SetVolume(newVolume)
	return newVolume
end

function MusicPlayerAPI:VolumeDown()
	if not Manager then return end
	local newVolume = math.max(Manager.Volume - 0.1, 0)
	Manager:SetVolume(newVolume)
	return newVolume
end

function MusicPlayerAPI:GetCurrentTrack()
	if not Manager then return nil end
	return Manager:GetCurrentTrack()
end

function MusicPlayerAPI:GetPlaylist()
	if not Manager then return {} end
	return Manager:GetPlaylist()
end

function MusicPlayerAPI:GetCurrentTrackIndex()
	if not Manager then return 0 end
	return Manager.CurrentTrackIndex
end

function MusicPlayerAPI:IsPlaying()
	if not Manager then return false end
	return Manager.IsPlaying
end

function MusicPlayerAPI:GetTrackInfo()
	if not Manager then return nil end

	local track = Manager:GetCurrentTrack()
	if not track then return nil end

	local artistVal = track:FindFirstChild("Artist")
	local coverVal = track:FindFirstChild("AlbumCover")

	return {
		Name = track.Name,
		Artist = artistVal and artistVal.Value or "Unknown Artist",
		AlbumCover = coverVal and coverVal.Value or "",
		TimeLength = track.TimeLength,
		TimePosition = track.TimePosition,
		IsPlaying = track.IsPlaying,
		IsPaused = track.IsPaused,
	}
end

function MusicPlayerAPI:ShowUI()
	if not Controller then return end
	Controller:_animateShow()
end

function MusicPlayerAPI:HideUI()
	if not Controller then return end
	Controller:_animateHide()
end

function MusicPlayerAPI:IsUIVisible()
	if not Controller then return false end
	return Controller.IsVisible
end

return MusicPlayerAPI