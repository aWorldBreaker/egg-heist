--[[
	Pet Heist — Shared configuration
	Location in Studio: ReplicatedStorage > Folder "Shared" > ModuleScript "Config"
]]

local Config = {}

Config.GAME_NAME = "Pet Heist"
Config.VERSION = "1.0.0"

-- Plots (yards)
Config.MAX_PLOTS = 12
Config.PLOT_SIZE = 26
Config.PLOT_RING_RADIUS = 70

-- Economy
Config.START_COINS = 100
Config.START_SLOTS = 3
Config.MAX_SLOTS = 8
Config.SLOT_PRICE_BASE = 500 -- price = base * currentSlots
Config.AUTOSAVE_INTERVAL = 120 -- seconds

-- Pet tiers: Price, Income (coins/sec), Growth (sec to mature), Color
Config.PET_TIERS = {
	{ Name = "Tabby Cat",     Price = 50,     Income = 2,    Growth = 20,  Color = Color3.fromRGB(255, 170, 80) },
	{ Name = "Puppy",         Price = 350,    Income = 9,    Growth = 30,  Color = Color3.fromRGB(160, 120, 85) },
	{ Name = "Fox",           Price = 1800,   Income = 30,   Growth = 45,  Color = Color3.fromRGB(255, 120, 50) },
	{ Name = "Dragon",        Price = 9000,   Income = 110,  Growth = 60,  Color = Color3.fromRGB(80, 200, 120) },
	{ Name = "Phoenix",       Price = 45000,  Income = 420,  Growth = 90,  Color = Color3.fromRGB(255, 80, 80) },
	{ Name = "Golden Unicorn", Price = 250000, Income = 1800, Growth = 120, Color = Color3.fromRGB(255, 210, 90) },
}

-- Rebirth
Config.REBIRTH_COST = 1000000 -- lifetime coins required
Config.REBIRTH_BONUS = 0.25   -- +25% income per rebirth (multiplicative stacks)

-- Steal
Config.STEAL_HOLD_TIME = 3  -- seconds holding E
Config.STEAL_COOLDOWN = 30  -- seconds between steals
Config.SLAP_DAMAGE = 10
Config.SLAP_COOLDOWN = 1.5

return Config
