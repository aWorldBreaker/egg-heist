--[[
	Pet Heist v1.0.0 — Server bootstrap
	Location in Studio: ServerScriptService > Script named "Main" (paste this file).

	Required siblings in Studio:
	  ReplicatedStorage/Shared/Config                 (ModuleScript)
	  ServerScriptService/Game/                        (Folder)
	    Economy, SaveSystem, PlotManager, MapBuilder,
	    PetManager, ShopSystem, StealSystem, RebirthSystem (ModuleScripts)
	  StarterPlayer/StarterPlayerScripts/Client        (LocalScript)

	All network remotes are created here in code — no manual setup needed.
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local GameFolder = ServerScriptService:WaitForChild("Game")

local function req(name)
	return require(GameFolder:WaitForChild(name))
end

-- Shared context passed to every system (avoids circular requires)
local ctx = {
	Config = Config,
	Players = Players,
	Remotes = {},
	Economy = req("Economy"),
	Save = req("SaveSystem"),
	Plots = req("PlotManager"),
	Map = req("MapBuilder"),
	Steal = req("StealSystem"),
	Pets = req("PetManager"),
	Shop = req("ShopSystem"),
	Rebirth = req("RebirthSystem"),
}

-- Create network remotes in code
local net = Instance.new("Folder")
net.Name = "PetHeistNet"
net.Parent = ReplicatedStorage
local function makeRemote(className, name)
	local r = Instance.new(className)
	r.Name = name
	r.Parent = net
	return r
end
ctx.Remotes.Notify = makeRemote("RemoteEvent", "Notify")
ctx.Remotes.StealProgress = makeRemote("RemoteEvent", "StealProgress")
ctx.Remotes.Shop = makeRemote("RemoteFunction", "Shop")
ctx.Remotes.Rebirth = makeRemote("RemoteFunction", "Rebirth")

-- Boot order matters
ctx.Map:Init(ctx)
ctx.Economy:Init(ctx)
ctx.Save:Init(ctx)
ctx.Plots:Init(ctx)
ctx.Steal:Init(ctx)
ctx.Pets:Init(ctx)
ctx.Shop:Init(ctx)
ctx.Rebirth:Init(ctx)

local function setupLeaderstats(player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = 0
	coins.Parent = ls
	ls.Parent = player
	return coins
end

Players.PlayerAdded:Connect(function(player)
	local coinsValue = setupLeaderstats(player)
	local data = ctx.Save:Load(player)
	ctx.Economy:SetBalance(player, data.Coins, data.Lifetime, coinsValue)
	ctx.Rebirth:Set(player, data.Rebirths or 0)
	local plot = ctx.Plots:Assign(player, data.Slots)
	if not plot then
		player:Kick("Server is full, please try again later!")
		return
	end
	ctx.Pets:Restore(player, data.Pets)
	ctx.Steal:GiveSlap(player)
end)

Players.PlayerRemoving:Connect(function(player)
	ctx.Save:Save(player)
	ctx.Pets:ClearPlayer(player)
	ctx.Plots:Release(player)
	ctx.Economy:Clear(player)
	ctx.Rebirth:Clear(player)
end)

game:BindToClose(function()
	for _, p in ipairs(Players:GetPlayers()) do
		ctx.Save:Save(p)
	end
end)

print("[Pet Heist] Server ready v" .. Config.VERSION)
