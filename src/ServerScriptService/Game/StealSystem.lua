--[[
	Pet Heist — StealSystem (steal pets + slap tool that interrupts steals)
	Location in Studio: ServerScriptService > Game > ModuleScript "StealSystem"

	Steal flow: hold E (ProximityPrompt) near another player's pet for
	Config.STEAL_HOLD_TIME seconds. The server validates distance every 0.1s,
	so walking away, dying, or getting slapped cancels the steal.
]]

local StealSystem = {}
local ctx
local cooldowns = {} -- [userId] = os.clock() of last completed steal
local active = {}    -- [userId] = { Pet = pet }

function StealSystem:Init(c)
	ctx = c

	ctx.Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			self:GiveSlap(player)
		end)
		-- in case character already exists
		if player.Character then
			self:GiveSlap(player)
		end
	end)
end

function StealSystem:WatchPrompt(prompt, pet)
	prompt.PromptButtonHoldBegan:Connect(function(player)
		self:BeginSteal(player, pet)
	end)
	prompt.PromptButtonHoldEnded:Connect(function(player)
		self:CancelSteal(player, true)
	end)
	-- Safety: if the prompt fires Triggered without our timer (edge case),
	-- our active-table guard makes this a harmless no-op.
	prompt.Triggered:Connect(function(_)
	end)
end

function StealSystem:BeginSteal(stealer, pet)
	if active[stealer.UserId] then
		return
	end
	if not ctx.Pets:Exists(pet) then
		return
	end
	if pet.OwnerId == stealer.UserId then
		return -- own pet: nothing to steal
	end
	if os.clock() - (cooldowns[stealer.UserId] or -999) < ctx.Config.STEAL_COOLDOWN then
		ctx.Remotes.Notify:FireClient(stealer, "Steal is on cooldown!")
		return
	end
	if not ctx.Pets:HasFreeSlot(stealer) then
		ctx.Remotes.Notify:FireClient(stealer, "Your yard is full!")
		return
	end

	active[stealer.UserId] = { Pet = pet }

	local victim = ctx.Players:GetPlayerByUserId(pet.OwnerId)
	if victim then
		ctx.Remotes.Notify:FireClient(victim, "Someone is stealing your pet!")
	end

	task.spawn(function()
		local need = ctx.Config.STEAL_HOLD_TIME
		local start = os.clock()
		while active[stealer.UserId] do
			task.wait(0.1)
			local st = active[stealer.UserId]
			if not st then
				break
			end
			local char = stealer.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if not hrp or not hum or hum.Health <= 0 or not ctx.Pets:Exists(pet) then
				self:CancelSteal(stealer, true)
				break
			end
			if (hrp.Position - pet.Model.Position).Magnitude > 15 then
				self:CancelSteal(stealer, true)
				break
			end
			local p = (os.clock() - start) / need
			ctx.Remotes.StealProgress:FireClient(stealer, math.clamp(p, 0, 1))
			if p >= 1 then
				self:CompleteSteal(stealer)
				break
			end
		end
	end)
end

-- silent = true when the player simply let go of E (no message)
function StealSystem:CancelSteal(player, silent)
	if not active[player.UserId] then
		return
	end
	active[player.UserId] = nil
	ctx.Remotes.StealProgress:FireClient(player, -1) -- hide bar
	if not silent then
		ctx.Remotes.Notify:FireClient(player, "Steal interrupted!")
	end
end

function StealSystem:CompleteSteal(stealer)
	local st = active[stealer.UserId]
	if not st then
		return
	end
	local pet = st.Pet
	active[stealer.UserId] = nil
	ctx.Remotes.StealProgress:FireClient(stealer, -1)
	if not ctx.Pets:Exists(pet) then
		return
	end
	if not ctx.Pets:HasFreeSlot(stealer) then
		ctx.Remotes.Notify:FireClient(stealer, "Your yard is full!")
		return
	end
	local tierName = ctx.Config.PET_TIERS[pet.Tier].Name
	local victim = ctx.Players:GetPlayerByUserId(pet.OwnerId)
	ctx.Pets:Transfer(pet, stealer)
	cooldowns[stealer.UserId] = os.clock()
	ctx.Remotes.Notify:FireClient(stealer, "You stole a " .. tierName .. "!")
	if victim then
		ctx.Remotes.Notify:FireClient(victim, stealer.DisplayName .. " stole your " .. tierName .. "!")
	end
end

-- Gives the player a Slap tool. Slapping a stealer cancels their steal.
function StealSystem:GiveSlap(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return
	end
	if backpack:FindFirstChild("Slap") or (player.Character and player.Character:FindFirstChild("Slap")) then
		return
	end

	local tool = Instance.new("Tool")
	tool.Name = "Slap"
	tool.RequiresHandle = true
	tool.CanBeDropped = false

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 2, 3)
	handle.Color = Color3.fromRGB(255, 180, 150)
	handle.Material = Enum.Material.SmoothPlastic
	handle.Parent = tool

	-- Slap logic is wired here on the server. Tool.Activated replicates to the
	-- server, so no Script inside the Tool is needed (Script.Source cannot be
	-- set at runtime anyway).
	local debounce = false
	tool.Activated:Connect(function()
		if debounce then
			return
		end
		debounce = true
		local owner = ctx.Players:GetPlayerFromCharacter(tool.Parent)
		local conn = nil
		conn = handle.Touched:Connect(function(hit)
			if conn then
				conn:Disconnect()
				conn = nil
			end
			local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
			local victimPlayer = hum and ctx.Players:GetPlayerFromCharacter(hit.Parent)
			if hum and victimPlayer and victimPlayer ~= owner and hum.Health > 0 then
				hum:TakeDamage(ctx.Config.SLAP_DAMAGE)
				local hrp = hit.Parent:FindFirstChild("HumanoidRootPart")
				if hrp then
					local dir = hrp.Position - handle.Position
					dir = Vector3.new(dir.X, 0, dir.Z)
					if dir.Magnitude < 0.01 then
						dir = Vector3.new(0, 0, 1)
					end
					hrp.AssemblyLinearVelocity = dir.Unit * 45 + Vector3.new(0, 30, 0)
				end
				-- interrupt an in-progress steal
				self:CancelSteal(victimPlayer, false)
			end
		end)
		task.delay(0.45, function()
			if conn then
				conn:Disconnect()
			end
		end)
		task.delay(ctx.Config.SLAP_COOLDOWN, function()
			debounce = false
		end)
	end)
	tool.Parent = backpack
end

return StealSystem
