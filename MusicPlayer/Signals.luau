local Signals = {}


Signals.TrackChanged = Instance.new("BindableEvent")
Signals.PlayStateChanged = Instance.new("BindableEvent")
Signals.VolumeChanged = Instance.new("BindableEvent")
Signals.MoodChanged = Instance.new("BindableEvent")

return Signals