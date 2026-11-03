--[[
	Pet Heist — ShopSystem (buy pets & nest slots, server-validated)
	Location in Studio: ServerScriptService > Game > ModuleScript "ShopSystem"
	Client calls: ReplicatedStorage.PetHeistNet.Shop:InvokeServer("BuyPet", tierIndex)
	                                                           :InvokeServer("BuySlot")
]]

local ShopSystem = {}
local ctx

function ShopSystem:Init(c)
	ctx = c
	ctx.Remotes.Shop.OnServerInvoke = function(player, action, arg)
		if action == "BuyPet" then
			return self:BuyPet(player, arg)
		elseif action == "BuySlot" then
			return self:BuySlot(player)
		end
		return false, "Unknown shop action."
	end
end

function ShopSystem:BuyPet(player, tierIndex)
	tierIndex = tonumber(tierIndex)
	local tier = tierIndex and ctx.Config.PET_TIERS[tierIndex]
	if not tier then
		return false, "Invalid pet."
	end
	if not ctx.Pets:HasFreeSlot(player) then
		return false, "Your yard is full! Buy more slots."
	end
	if not ctx.Economy:Spend(player, tier.Price) then
		return false, "Not enough coins!"
	end
	local pet = ctx.Pets:Spawn(player, tierIndex)
	if not pet then
		-- refund on unexpected failure
		ctx.Economy:Add(player, tier.Price)
		return false, "Could not place pet."
	end
	ctx.Remotes.Notify:FireClient(player, "Bought " .. tier.Name .. "!")
	return true, "OK"
end

function ShopSystem:BuySlot(player)
	local plot = ctx.Plots:GetPlot(player)
	if not plot then
		return false, "You have no plot."
	end
	if plot.MaxSlots >= ctx.Config.MAX_SLOTS then
		return false, "Max nest slots reached!"
	end
	local price = ctx.Config.SLOT_PRICE_BASE * plot.MaxSlots
	if not ctx.Economy:Spend(player, price) then
		return false, "Not enough coins!"
	end
	plot.MaxSlots += 1
	ctx.Remotes.Notify:FireClient(player, "Pet slot unlocked! (" .. plot.MaxSlots .. "/" .. ctx.Config.MAX_SLOTS .. ")")
	return true, "OK"
end

function ShopSystem:SlotPrice(player)
	local plot = ctx.Plots:GetPlot(player)
	if not plot or plot.MaxSlots >= ctx.Config.MAX_SLOTS then
		return nil
	end
	return ctx.Config.SLOT_PRICE_BASE * plot.MaxSlots
end

return ShopSystem
