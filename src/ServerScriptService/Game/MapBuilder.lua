--[[
	Pet Heist — MapBuilder (procedural world: ground, shop, spawn, decor)
	Location in Studio: ServerScriptService > Game > ModuleScript "MapBuilder"
	Everything is built in code — no manual building required.
]]

local MapBuilder = {}

local function part(props, parent)
	local p = Instance.new("Part")
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Anchored = true
	p.Parent = parent or workspace
	return p
end

function MapBuilder:Init(ctx)
	local world = Instance.new("Folder")
	world.Name = "PetHeistWorld"
	world.Parent = workspace

	-- Ground
	part({
		Name = "Ground",
		Size = Vector3.new(400, 2, 400),
		Position = Vector3.new(0, -1, 0),
		Color = Color3.fromRGB(95, 165, 95),
		Material = Enum.Material.Grass,
	}, world)

	-- Center plaza
	part({
		Name = "Plaza",
		Size = Vector3.new(40, 1.2, 40),
		Position = Vector3.new(0, 0.4, 0),
		Color = Color3.fromRGB(200, 190, 170),
		Material = Enum.Material.Concrete,
	}, world)

	-- Shop hut (simple)
	local hutColor = Color3.fromRGB(150, 110, 70)
	part({ Name = "ShopBase", Size = Vector3.new(16, 1, 12), Position = Vector3.new(0, 1, -10), Color = Color3.fromRGB(170, 160, 150), Material = Enum.Material.WoodPlanks }, world)
	part({ Name = "ShopWallL", Size = Vector3.new(1, 6, 12), Position = Vector3.new(-7.5, 4, -10), Color = hutColor, Material = Enum.Material.Wood }, world)
	part({ Name = "ShopWallR", Size = Vector3.new(1, 6, 12), Position = Vector3.new(7.5, 4, -10), Color = hutColor, Material = Enum.Material.Wood }, world)
	part({ Name = "ShopWallB", Size = Vector3.new(16, 6, 1), Position = Vector3.new(0, 4, -15.5), Color = hutColor, Material = Enum.Material.Wood }, world)
	part({ Name = "ShopRoof", Size = Vector3.new(18, 1, 14), Position = Vector3.new(0, 7.5, -10), Color = Color3.fromRGB(180, 70, 70), Material = Enum.Material.Slate }, world)

	-- Shop sign
	local signPart = part({ Name = "ShopSign", Size = Vector3.new(10, 3, 0.5), Position = Vector3.new(0, 9.5, -4), Color = Color3.fromRGB(60, 40, 20) }, world)
	local signGui = Instance.new("BillboardGui")
	signGui.Size = UDim2.new(0, 220, 0, 60)
	signGui.StudsOffset = Vector3.new(0, 1, 0)
	signGui.AlwaysOnTop = true
	signGui.Adornee = signPart
	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.new(1, 0, 1, 0)
	signText.BackgroundTransparency = 1
	signText.TextColor3 = Color3.fromRGB(255, 220, 100)
	signText.Font = Enum.Font.GothamBlack
	signText.TextSize = 28
	signText.Text = "PET SHOP"
	signText.Parent = signGui
	signGui.Parent = signPart

	-- Spawn
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Vector3.new(0, 1.5, 14)
	spawn.Anchored = true
	spawn.Color = Color3.fromRGB(120, 200, 255)
	spawn.Material = Enum.Material.Neon
	spawn.Parent = world

	-- Decorative trees (deterministic layout)
	local treeAngles = { 0.4, 1.1, 1.9, 2.6, 3.3, 4.1, 4.8, 5.5 }
	for _, a in ipairs(treeAngles) do
		local r = 95
		local tx, tz = math.cos(a) * r, math.sin(a) * r
		part({ Name = "Trunk", Size = Vector3.new(2, 8, 2), Position = Vector3.new(tx, 4, tz), Color = Color3.fromRGB(110, 75, 45), Material = Enum.Material.Wood }, world)
		local leaves = part({ Name = "Leaves", Shape = Enum.PartType.Ball, Size = Vector3.new(9, 9, 9), Position = Vector3.new(tx, 10, tz), Color = Color3.fromRGB(60, 140, 70), Material = Enum.Material.Grass }, world)
		leaves.CanCollide = false
	end

	-- Path from spawn to shop
	part({ Name = "Path", Size = Vector3.new(6, 1.1, 22), Position = Vector3.new(0, 0.45, 3), Color = Color3.fromRGB(210, 200, 180), Material = Enum.Material.Sand }, world)

	-- Lighting / atmosphere
	local L = game:GetService("Lighting")
	L.ClockTime = 14
	L.Brightness = 2
	L.Ambient = Color3.fromRGB(110, 110, 110)
	L.OutdoorAmbient = Color3.fromRGB(130, 130, 130)

	print("[Pet Heist] Map built")
end

return MapBuilder
