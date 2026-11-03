--[[
	Pet Heist — PetManager (spawn, grow, income, steal transfer, save/restore)
	Location in Studio: ServerScriptService > Game > ModuleScript "PetManager"

	Pets are cute blocky creatures assembled from Parts in code
	(body, head, ears, eyes, tail, paws) — no meshes or assets needed.
]]

local PetManager = {}
local ctx
local pets = {} -- array of pet objects
local petUid = 0

function PetManager:Init(c)
	ctx = c
	task.spawn(function()
		while true do
			task.wait(1)
			self:Tick()
		end
	end)
end

local function fmt(n)
	n = math.floor(n)
	if n >= 1e6 then
		return string.format("%.1fM", n / 1e6)
	elseif n >= 1e3 then
		return string.format("%.1fK", n / 1e3)
	end
	return tostring(n)
end

function PetManager:Tick()
	local now = os.clock()
	for _, p in ipairs(pets) do
		if p.Matured then
			local owner = ctx.Players:GetPlayerByUserId(p.OwnerId)
			if owner then
				local mult = 1 + ctx.Rebirth:Get(owner) * ctx.Config.REBIRTH_BONUS
				ctx.Economy:Add(owner, p.Income * mult)
			end
		elseif now >= p.MatureAt then
			p.Matured = true
			self:SetScale(p, 1)
			self:RefreshBillboard(p)
		else
			local t = 1 - (p.MatureAt - now) / p.GrowthTime
			self:SetScale(p, 0.45 + 0.55 * math.clamp(t, 0, 1))
		end
	end
	-- lazy cleanup of destroyed pets
	for i = #pets, 1, -1 do
		if not self:Exists(pets[i]) then
			table.remove(pets, i)
		end
	end
end

-- Build a blocky pet. Returns { Model, Parts = {{Part, BaseSize, BaseOffset}}, Origin, Body }
function PetManager:BuildPet(tier, origin)
	local model = Instance.new("Model")
	model.Name = "Pet"

	local parts = {}
	local function addPart(name, size, offset, color, material)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.Color = color or tier.Color
		part.Material = material or Enum.Material.SmoothPlastic
		part.Anchored = true
		part.CanCollide = false
		part.Parent = model
		table.insert(parts, { Part = part, BaseSize = size, BaseOffset = offset })
		return part
	end

	local c = tier.Color
	local dark = Color3.fromRGB(30, 30, 30)
	addPart("Body", Vector3.new(2, 2, 3), Vector3.new(0, 1.6, 0), c)
	addPart("Head", Vector3.new(1.8, 1.8, 1.8), Vector3.new(0, 3.3, 1.7), c)
	addPart("EarL", Vector3.new(0.6, 1, 0.4), Vector3.new(-0.6, 4.5, 1.7), c)
	addPart("EarR", Vector3.new(0.6, 1, 0.4), Vector3.new(0.6, 4.5, 1.7), c)
	addPart("EyeL", Vector3.new(0.35, 0.45, 0.2), Vector3.new(-0.45, 3.5, 2.65), dark, Enum.Material.Neon)
	addPart("EyeR", Vector3.new(0.35, 0.45, 0.2), Vector3.new(0.45, 3.5, 2.65), dark, Enum.Material.Neon)
	addPart("Tail", Vector3.new(0.5, 0.5, 1.6), Vector3.new(0, 2.1, -2.1), c)
	addPart("PawL", Vector3.new(0.7, 0.7, 1.2), Vector3.new(-0.6, 0.5, 1.1), c)
	addPart("PawR", Vector3.new(0.7, 0.7, 1.2), Vector3.new(0.6, 0.5, 1.1), c)

	local body = parts[1].Part
	model.PrimaryPart = body
	model.Parent = workspace
	return { Model = model, Parts = parts, Origin = origin, Body = body }
end

function PetManager:SetScale(pet, s)
	for _, rec in ipairs(pet.Parts) do
		rec.Part.Size = rec.BaseSize * s
		rec.Part.Position = pet.Origin + rec.BaseOffset * s
	end
end

function PetManager:MakeBillboard(pet, tier)
	local gui = Instance.new("BillboardGui")
	gui.Name = "PetInfo"
	gui.Size = UDim2.new(0, 150, 0, 54)
	gui.StudsOffset = Vector3.new(0, 6.5, 0)
	gui.AlwaysOnTop = true
	gui.Adornee = pet.Body
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 0.35
	label.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 15
	label.Parent = gui
	gui.Parent = pet.Body
	pet.Billboard = label
	self:RefreshBillboard(pet)
end

function PetManager:RefreshBillboard(pet)
	if not pet.Billboard then
		return
	end
	local tier = ctx.Config.PET_TIERS[pet.Tier]
	if pet.Matured then
		pet.Billboard.Text = tier.Name .. "\n$" .. fmt(pet.Income) .. "/s"
	else
		pet.Billboard.Text = tier.Name .. "\nGrowing..."
	end
end

function PetManager:MakeStealPrompt(pet)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Steal Pet"
	prompt.ObjectText = ctx.Config.PET_TIERS[pet.Tier].Name
	prompt.HoldDuration = ctx.Config.STEAL_HOLD_TIME
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = pet.Body
	ctx.Steal:WatchPrompt(prompt, pet)
end

-- Find a free bed slot index on the player's plot (also returns plot)
function PetManager:FindFreeSlot(player)
	local plot = ctx.Plots:GetPlot(player)
	if not plot then
		return nil
	end
	local used = {}
	for _, p in ipairs(pets) do
		if p.OwnerId == player.UserId then
			used[p.Slot] = true
		end
	end
	for s = 1, plot.MaxSlots do
		if not used[s] then
			return s, plot
		end
	end
	return nil
end

function PetManager:HasFreeSlot(player)
	return self:FindFreeSlot(player) ~= nil
end

-- Spawn a pet for a player. opts = { Slot = n, Matured = bool, Progress = 0..1 }
-- pet.Model is the body Part (used for position/distance checks);
-- pet.PetModel is the full Model (destroyed on remove).
function PetManager:Spawn(player, tierIndex, opts)
	opts = opts or {}
	local tier = ctx.Config.PET_TIERS[tierIndex]
	if not tier then
		return nil
	end
	local slot, plot
	if opts.Slot then
		slot = opts.Slot
		plot = ctx.Plots:GetPlot(player)
	else
		slot, plot = self:FindFreeSlot(player)
	end
	if not slot or not plot then
		return nil
	end
	local bed = plot.Beds[slot]
	if not bed then
		return nil
	end

	petUid += 1
	local origin = bed.Position + Vector3.new(0, 1.2, 0)
	local built = self:BuildPet(tier, origin)
	local now = os.clock()
	local progress = opts.Progress or 0
	local pet = {
		Uid = petUid,
		Tier = tierIndex,
		Income = tier.Income,
		OwnerId = player.UserId,
		PlotIndex = plot.Index,
		Slot = slot,
		Model = built.Body, -- body part: position/distance checks use this
		PetModel = built.Model,
		Parts = built.Parts,
		Origin = origin,
		GrowthTime = tier.Growth,
		MatureAt = now + tier.Growth * (1 - progress),
		Matured = opts.Matured or false,
	}
	if pet.Matured then
		pet.MatureAt = now
		self:SetScale(pet, 1)
	else
		self:SetScale(pet, 0.45 + 0.55 * progress)
	end
	self:MakeBillboard(pet, tier)
	self:MakeStealPrompt(pet)
	table.insert(pets, pet)
	return pet
end

function PetManager:Exists(pet)
	return pet.PetModel ~= nil and pet.PetModel.Parent ~= nil
end

function PetManager:Remove(pet)
	for i, p in ipairs(pets) do
		if p == pet then
			table.remove(pets, i)
			break
		end
	end
	if pet.PetModel then
		pet.PetModel:Destroy()
	end
end

-- Move a pet to a new owner (steal). Keeps tier + maturity.
function PetManager:Transfer(pet, newOwner)
	local tierIndex = pet.Tier
	local matured = pet.Matured
	local progress = 1
	if not matured then
		progress = math.clamp(1 - (pet.MatureAt - os.clock()) / pet.GrowthTime, 0, 1)
	end
	self:Remove(pet)
	return self:Spawn(newOwner, tierIndex, { Matured = matured, Progress = progress })
end

function PetManager:ClearPlayer(player)
	for i = #pets, 1, -1 do
		if pets[i].OwnerId == player.UserId then
			local p = pets[i]
			table.remove(pets, i)
			if p.PetModel then
				p.PetModel:Destroy()
			end
		end
	end
end

-- Serialize for DataStore
function PetManager:Serialize(player)
	local out = {}
	for _, p in ipairs(pets) do
		if p.OwnerId == player.UserId and self:Exists(p) then
			local progress = 1
			if not p.Matured then
				progress = math.clamp(1 - (p.MatureAt - os.clock()) / p.GrowthTime, 0, 1)
			end
			table.insert(out, { T = p.Tier, S = p.Slot, M = p.Matured and 1 or 0, P = progress })
		end
	end
	return out
end

function PetManager:Restore(player, saved)
	if type(saved) ~= "table" then
		return
	end
	table.sort(saved, function(a, b)
		return (a.S or 0) < (b.S or 0)
	end)
	for _, s in ipairs(saved) do
		if type(s.T) == "number" and ctx.Config.PET_TIERS[s.T] then
			self:Spawn(player, s.T, {
				Slot = s.S,
				Matured = s.M == 1,
				Progress = tonumber(s.P) or 0,
			})
		end
	end
end

return PetManager
