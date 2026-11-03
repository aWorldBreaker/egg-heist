--[[
	Pet Heist — RebirthSystem (prestige: reset for permanent income bonus)
	Location in Studio: ServerScriptService > Game > ModuleScript "RebirthSystem"
	Client calls: ReplicatedStorage.PetHeistNet.Rebirth:InvokeServer()
]]

local RebirthSystem = {}
local ctx
local rebirths = {} -- [userId] = count

function RebirthSystem:Init(c)
	ctx = c
	ctx.Remotes.Rebirth.OnServerInvoke = function(player)
		return self:DoRebirth(player)
	end
end

function RebirthSystem:Get(player)
	return rebirths[player.UserId] or 0
end

function RebirthSystem:Set(player, n)
	rebirths[player.UserId] = n or 0
end

function RebirthSystem:Clear(player)
	rebirths[player.UserId] = nil
end

function RebirthSystem:DoRebirth(player)
	local lifetime = ctx.Economy:GetLifetime(player)
	local cost = ctx.Config.REBIRTH_COST
	if lifetime < cost then
		return false, "Need " .. cost .. " lifetime coins to rebirth!"
	end
	ctx.Pets:ClearPlayer(player)
	ctx.Economy:Reset(player)
	ctx.Economy:SetLifetime(player, 0)
	rebirths[player.UserId] = self:Get(player) + 1
	local bonusPct = math.floor(ctx.Config.REBIRTH_BONUS * 100)
	ctx.Remotes.Notify:FireClient(player,
		"REBIRTH! Permanent +" .. bonusPct .. "% income (x" .. rebirths[player.UserId] .. ")")
	return true, "OK"
end

return RebirthSystem
