local Players = game:GetService("Players")
local player = Players.LocalPlayer

player.CharacterAdded:Wait()
task.wait(1)

local scriptParent = script.Parent

local function safeRequire(moduleName)
	local module = scriptParent:WaitForChild(moduleName)
	if not module then return nil end

	local success, result = pcall(function()
		return require(module)
	end)

	if success then
		return result
	else
		return nil
	end
end

local Config = safeRequire("TrackConfig")
local Signals = safeRequire("Signals")
local Manager = safeRequire("MusicManager")
local Controller = safeRequire("MusicController")
local MusicPlayerAPI = safeRequire("MusicPlayerAPI")

if not (Config and Signals and Manager and Controller and MusicPlayerAPI) then
	return
end

local success, musicController = pcall(function()
	return Controller.new()
end)

if not success then return end

local startSuccess, startError = pcall(function()
	musicController:Start()
end)

if not startSuccess then return end

MusicPlayerAPI:Initialize(musicController)
_G.MusicPlayer = MusicPlayerAPI

warn("Ghost's Music Player loaded!")