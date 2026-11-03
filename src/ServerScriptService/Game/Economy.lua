--[[
	Pet Heist — Economy (server-authoritative coin balances)
	Location in Studio: ServerScriptService > Game > ModuleScript "Economy"
]]

local Economy = {}
local ctx
local balances = {} -- [userId] = { Coins = n, Lifetime = n, Value = IntValue }

function Economy:Init(c)
	ctx = c
end

function Economy:SetBalance(player, coins, lifetime, intValue)
	balances[player.UserId] = {
		Coins = coins or 0,
		Lifetime = lifetime or 0,
		Value = intValue,
	}
	if intValue then
		intValue.Value = coins or 0
	end
end

function Economy:Get(player)
	local b = balances[player.UserId]
	return b and b.Coins or 0
end

function Economy:GetLifetime(player)
	local b = balances[player.UserId]
	return b and b.Lifetime or 0
end

function Economy:SetLifetime(player, v)
	local b = balances[player.UserId]
	if b then
		b.Lifetime = v
	end
end

function Economy:Add(player, amount)
	local b = balances[player.UserId]
	if not b then
		return
	end
	amount = math.floor(amount)
	b.Coins += amount
	b.Lifetime += amount
	if b.Value then
		b.Value.Value = b.Coins
	end
end

-- Returns true if the player could afford it (and deducts)
function Economy:Spend(player, amount)
	local b = balances[player.UserId]
	amount = math.floor(amount)
	if not b or b.Coins < amount then
		return false
	end
	b.Coins -= amount
	if b.Value then
		b.Value.Value = b.Coins
	end
	return true
end

function Economy:Reset(player)
	local b = balances[player.UserId]
	if not b then
		return
	end
	b.Coins = 0
	if b.Value then
		b.Value.Value = 0
	end
end

function Economy:Clear(player)
	balances[player.UserId] = nil
end

return Economy
