--[[
	Pet Heist — SaveSystem (DataStore persistence)
	Location in Studio: ServerScriptService > Game > ModuleScript "SaveSystem"
	NOTE: enable "Studio Access to API Services" in Game Settings > Security
	to test saving inside Roblox Studio.
]]

local SaveSystem = {}
local ctx
local store = nil

function SaveSystem:Init(c)
	ctx = c
	local ok, ds = pcall(function()
		return game:GetService("DataStoreService"):GetDataStore("PetHeist_Save_v1")
	end)
	if ok and ds then
		store = ds
	else
		warn("[Pet Heist] DataStore unavailable — progress will NOT save. " ..
			"Enable Studio Access to API Services to test saving.")
	end
	task.spawn(function()
		while true do
			task.wait(ctx.Config.AUTOSAVE_INTERVAL)
			for _, p in ipairs(ctx.Players:GetPlayers()) do
				self:Save(p)
			end
		end
	end)
end

function SaveSystem:DefaultData()
	return {
		Coins = ctx.Config.START_COINS,
		Lifetime = 0,
		Pets = {},
		Rebirths = 0,
		Slots = ctx.Config.START_SLOTS,
	}
end

function SaveSystem:Load(player)
	local data = self:DefaultData()
	if store then
		local ok, saved = pcall(function()
			return store:GetAsync("u_" .. player.UserId)
		end)
		if ok and type(saved) == "table" then
			for k, v in pairs(saved) do
				data[k] = v
			end
		end
	end
	return data
end

function SaveSystem:Collect(player)
	return {
		Coins = ctx.Economy:Get(player),
		Lifetime = ctx.Economy:GetLifetime(player),
		Pets = ctx.Pets:Serialize(player),
		Rebirths = ctx.Rebirth:Get(player),
		Slots = ctx.Plots:GetSlots(player),
	}
end

function SaveSystem:Save(player)
	if not store then
		return
	end
	local ok, err = pcall(function()
		store:SetAsync("u_" .. player.UserId, self:Collect(player))
	end)
	if not ok then
		warn("[Pet Heist] Save failed for " .. player.Name .. ": " .. tostring(err))
	end
end

return SaveSystem
