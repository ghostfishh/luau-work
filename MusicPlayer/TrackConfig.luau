local Config = {}

Config.GuiName = "MusicPlayerGUI"
Config.AutoCloneGui = false

Config.TracksLocation = game:GetService("SoundService")
Config.TracksFolderName = "Tracks"
Config.MoodValueName = "Mood"

Config.DefaultMood = "Crazy"
Config.AutoPlay = false
Config.FadeTime = 0.35
Config.DefaultVolume = 0.5
Config.ShuffleOnStart = false

Config.UIAnimations = {
	ShowDuration = 0.4,
	HideDuration = 0.3,
	ShowEasing = Enum.EasingStyle.Back,
	HideEasing = Enum.EasingStyle.Quad,
	ShowDirection = Enum.EasingDirection.Out,
	HideDirection = Enum.EasingDirection.In,
	CardSlideDistance = 100,
	ButtonHoverScale = 1.1,
	ButtonHoverDuration = 0.15,
	ProgressUpdateRate = 0.1,
	AlbumRotationSpeed = 0,
}

return Config