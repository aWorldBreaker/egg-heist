--[[
	Pet Heist — PlotManager (player plots / nests)
	Location in Studio: ServerScriptService > Game > ModuleScript "PlotManager"
]]

local PlotManager = {}
local ctx
local plots = {} -- [index] = plot

function PlotManager:Init(c)
	ctx = c
	self:Build()
end

function PlotManager:Build()
	local folder = Instance.new("Folder")
	folder.Name = "Plots"
	folder.Parent = workspace

	local n = ctx.Config.MAX_PLOTS
	local ringR = ctx.Config.PLOT_RING_RADIUS
	local size = ctx.Config.PLOT_SIZE

	for i = 1, n do
		local ang = (i - 1) / n * math.pi * 2
		local cx = math.cos(ang) * ringR
		local cz = math.sin(ang) * ringR

		local pad = Instance.new("Part")
		pad.Name = "Plot" .. i
		pad.Size = Vector3.new(size, 1, size)
		pad.Position = Vector3.new(cx, 0.5, cz)
		pad.Anchored = true
		pad.Color = Color3.fromRGB(126, 184, 126)
		pad.Material = Enum.Material.Grass
		pad.Parent = folder

		-- Owner sign (billboard above plot)
		local sign = Instance.new("BillboardGui")
		sign.Name = "PlotSign"
		sign.Size = UDim2.new(0, 200, 0, 50)
		sign.StudsOffset = Vector3.new(0, 7, 0)
		sign.AlwaysOnTop = true
		sign.Adornee = pad
		local label = Instance.new("TextLabel")
		label.Name = "Text"
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 0.4
		label.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.Font = Enum.Font.GothamBold
		label.TextSize = 20
		label.Text = "Empty Plot"
		label.Parent = sign
		sign.Parent = pad

		-- Pet slots (4 per row)
		local nests = {}
		local perRow = 4
		for s = 1, ctx.Config.MAX_SLOTS do
			local row = math.floor((s - 1) / perRow)
			local col = (s - 1) % perRow
			local nest = Instance.new("Part")
			nest.Name = "Bed" .. s
			nest.Shape = Enum.PartType.Cylinder
			nest.Size = Vector3.new(1, 5, 5)
			nest.Orientation = Vector3.new(0, 0, 90) -- lay flat
			nest.Position = Vector3.new(
				cx + (col - 1.5) * 5.5,
				1.2,
				cz + (row - 0.5) * 5.5
			)
			nest.Anchored = true
			nest.CanCollide = false
			nest.Color = Color3.fromRGB(160, 120, 80)
			nest.Material = Enum.Material.Wood
			nest.Parent = folder
			nests[s] = nest
		end

		plots[i] = {
			Index = i,
			Owner = nil, -- userId
			Pad = pad,
			SignLabel = label,
			Beds = nests,
			MaxSlots = ctx.Config.START_SLOTS,
		}
	end
end

function PlotManager:Assign(player, slots)
	for _, plot in ipairs(plots) do
		if plot.Owner == nil then
			plot.Owner = player.UserId
			plot.MaxSlots = math.clamp(slots or ctx.Config.START_SLOTS, 1, ctx.Config.MAX_SLOTS)
			plot.SignLabel.Text = player.DisplayName .. "'s Yard"
			plot.Pad.Color = Color3.fromRGB(140, 200, 140)
			return plot
		end
	end
	return nil -- server full
end

function PlotManager:Release(player)
	local plot = self:GetPlot(player)
	if plot then
		plot.Owner = nil
		plot.MaxSlots = ctx.Config.START_SLOTS
		plot.SignLabel.Text = "Empty Plot"
		plot.Pad.Color = Color3.fromRGB(126, 184, 126)
	end
end

function PlotManager:GetPlot(player)
	for _, plot in ipairs(plots) do
		if plot.Owner == player.UserId then
			return plot
		end
	end
	return nil
end

function PlotManager:GetSlots(player)
	local plot = self:GetPlot(player)
	return plot and plot.MaxSlots or ctx.Config.START_SLOTS
end

return PlotManager
