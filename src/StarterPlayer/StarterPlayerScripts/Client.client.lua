--[[
	Pet Heist — Client (all UI built in code: HUD, shop, rebirth, toasts, steal bar)
	Location in Studio: StarterPlayer > StarterPlayerScripts > LocalScript "Client"
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local net = ReplicatedStorage:WaitForChild("PetHeistNet")
local NotifyRE = net:WaitForChild("Notify")
local StealProgressRE = net:WaitForChild("StealProgress")
local ShopRF = net:WaitForChild("Shop")
local RebirthRF = net:WaitForChild("Rebirth")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local function fmt(n)
	n = math.floor(n)
	if n >= 1e6 then
		return string.format("%.1fM", n / 1e6)
	elseif n >= 1e3 then
		return string.format("%.1fK", n / 1e3)
	end
	return tostring(n)
end

-- Root UI
local gui = Instance.new("ScreenGui")
gui.Name = "PetHeistUI"
gui.ResetOnSpawn = false
gui.Parent = playerGui

-- Coin HUD (top-left)
local coinFrame = Instance.new("Frame")
coinFrame.Size = UDim2.new(0, 220, 0, 54)
coinFrame.Position = UDim2.new(0, 16, 0, 16)
coinFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
coinFrame.BackgroundTransparency = 0.25
coinFrame.BorderSizePixel = 0
Instance.new("UICorner", coinFrame).CornerRadius = UDim.new(0, 12)
coinFrame.Parent = gui

local coinLabel = Instance.new("TextLabel")
coinLabel.Size = UDim2.new(1, -16, 1, 0)
coinLabel.Position = UDim2.new(0, 16, 0, 0)
coinLabel.BackgroundTransparency = 1
coinLabel.Font = Enum.Font.GothamBlack
coinLabel.TextSize = 26
coinLabel.TextXAlignment = Enum.TextXAlignment.Left
coinLabel.TextColor3 = Color3.fromRGB(255, 215, 90)
coinLabel.Text = "Coins: 0"
coinLabel.Parent = coinFrame

local leaderstats = player:WaitForChild("leaderstats")
local coinsValue = leaderstats:WaitForChild("Coins")
local function refreshCoins()
	coinLabel.Text = "Coins: " .. fmt(coinsValue.Value)
end
coinsValue.Changed:Connect(refreshCoins)
refreshCoins()

-- Top-right buttons
local function makeButton(text, order)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, 130, 0, 44)
	b.Position = UDim2.new(1, -146, 0, 16 + (order - 1) * 52)
	b.BackgroundColor3 = Color3.fromRGB(40, 120, 220)
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 18
	b.Text = text
	b.BorderSizePixel = 0
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
	b.Parent = gui
	return b
end

local shopBtn = makeButton("SHOP", 1)
local rebirthBtn = makeButton("REBIRTH", 2)
rebirthBtn.BackgroundColor3 = Color3.fromRGB(160, 70, 200)

-- Shop panel
local shopFrame = Instance.new("Frame")
shopFrame.Size = UDim2.new(0, 340, 0, 430)
shopFrame.Position = UDim2.new(0.5, -170, 0.5, -215)
shopFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
shopFrame.BorderSizePixel = 0
shopFrame.Visible = false
Instance.new("UICorner", shopFrame).CornerRadius = UDim.new(0, 14)
shopFrame.Parent = gui

local shopTitle = Instance.new("TextLabel")
shopTitle.Size = UDim2.new(1, 0, 0, 44)
shopTitle.BackgroundTransparency = 1
shopTitle.Font = Enum.Font.GothamBlack
shopTitle.TextSize = 22
shopTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
shopTitle.Text = "PET SHOP"
shopTitle.Parent = shopFrame

local shopClose = Instance.new("TextButton")
shopClose.Size = UDim2.new(0, 36, 0, 36)
shopClose.Position = UDim2.new(1, -44, 0, 4)
shopClose.BackgroundTransparency = 1
shopClose.Font = Enum.Font.GothamBold
shopClose.TextSize = 22
shopClose.TextColor3 = Color3.fromRGB(255, 120, 120)
shopClose.Text = "X"
shopClose.Parent = shopFrame
shopClose.MouseButton1Click:Connect(function()
	shopFrame.Visible = false
end)

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 8)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = shopFrame

local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 50)
pad.PaddingLeft = UDim.new(0, 12)
pad.PaddingRight = UDim.new(0, 12)
pad.PaddingBottom = UDim.new(0, 12)
pad.Parent = shopFrame

for i, tier in ipairs(Config.PET_TIERS) do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 52)
	row.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	row.BorderSizePixel = 0
	row.LayoutOrder = i
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
	row.Parent = shopFrame

	local info = Instance.new("TextLabel")
	info.Size = UDim2.new(1, -110, 1, 0)
	info.Position = UDim2.new(0, 10, 0, 0)
	info.BackgroundTransparency = 1
	info.Font = Enum.Font.Gotham
	info.TextSize = 14
	info.TextXAlignment = Enum.TextXAlignment.Left
	info.TextColor3 = Color3.fromRGB(230, 230, 230)
	info.Text = tier.Name .. "\n$" .. fmt(tier.Price) .. "  •  $" .. fmt(tier.Income) .. "/s"
	info.Parent = row

	local buy = Instance.new("TextButton")
	buy.Size = UDim2.new(0, 90, 0, 36)
	buy.Position = UDim2.new(1, -100, 0.5, -18)
	buy.BackgroundColor3 = Color3.fromRGB(60, 180, 80)
	buy.Font = Enum.Font.GothamBold
	buy.TextSize = 16
buy.TextColor3 = Color3.fromRGB(255, 255, 255)
	buy.Text = "BUY"
	buy.BorderSizePixel = 0
	Instance.new("UICorner", buy).CornerRadius = UDim.new(0, 8)
	buy.Parent = row
	buy.MouseButton1Click:Connect(function()
		local _ok, msg = ShopRF:InvokeServer("BuyPet", i)
		if not _ok then
			toast(msg)
		end
	end)
end

-- Pet slot row
local slotRow = Instance.new("Frame")
slotRow.Size = UDim2.new(1, 0, 0, 52)
slotRow.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
slotRow.BorderSizePixel = 0
slotRow.LayoutOrder = 100
Instance.new("UICorner", slotRow).CornerRadius = UDim.new(0, 8)
slotRow.Parent = shopFrame

local slotInfo = Instance.new("TextLabel")
slotInfo.Size = UDim2.new(1, -110, 1, 0)
slotInfo.Position = UDim2.new(0, 10, 0, 0)
slotInfo.BackgroundTransparency = 1
slotInfo.Font = Enum.Font.Gotham
slotInfo.TextSize = 14
slotInfo.TextXAlignment = Enum.TextXAlignment.Left
slotInfo.TextColor3 = Color3.fromRGB(230, 230, 230)
slotInfo.Text = "Extra Bed Slot"
slotInfo.Parent = slotRow

local slotBuy = Instance.new("TextButton")
slotBuy.Size = UDim2.new(0, 90, 0, 36)
slotBuy.Position = UDim2.new(1, -100, 0.5, -18)
slotBuy.BackgroundColor3 = Color3.fromRGB(60, 140, 220)
slotBuy.Font = Enum.Font.GothamBold
slotBuy.TextSize = 16
slotBuy.TextColor3 = Color3.fromRGB(255, 255, 255)
slotBuy.Text = "BUY"
slotBuy.BorderSizePixel = 0
Instance.new("UICorner", slotBuy).CornerRadius = UDim.new(0, 8)
slotBuy.Parent = slotRow
slotBuy.MouseButton1Click:Connect(function()
	local _ok, msg = ShopRF:InvokeServer("BuySlot")
	if not _ok then
		toast(msg)
	end
end)

shopBtn.MouseButton1Click:Connect(function()
	shopFrame.Visible = not shopFrame.Visible
end)

-- Rebirth
rebirthBtn.MouseButton1Click:Connect(function()
	local _ok, msg = RebirthRF:InvokeServer()
	toast(msg)
end)

-- Toast notifications
local toastLabel = Instance.new("TextLabel")
toastLabel.Size = UDim2.new(0, 420, 0, 44)
toastLabel.Position = UDim2.new(0.5, -210, 0, 80)
toastLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
toastLabel.BackgroundTransparency = 0.2
toastLabel.Font = Enum.Font.GothamBold
toastLabel.TextSize = 17
toastLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
toastLabel.Text = ""
toastLabel.Visible = false
toastLabel.BorderSizePixel = 0
Instance.new("UICorner", toastLabel).CornerRadius = UDim.new(0, 10)
toastLabel.Parent = gui

local toastToken = 0
function toast(msg)
	toastToken += 1
	local my = toastToken
	toastLabel.Text = msg
	toastLabel.Visible = true
	task.delay(3, function()
		if toastToken == my then
			toastLabel.Visible = false
		end
	end)
end

NotifyRE.OnClientEvent:Connect(toast)

-- Steal progress bar
local stealFrame = Instance.new("Frame")
stealFrame.Size = UDim2.new(0, 300, 0, 26)
stealFrame.Position = UDim2.new(0.5, -150, 0.5, 60)
stealFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
stealFrame.BackgroundTransparency = 0.3
stealFrame.BorderSizePixel = 0
stealFrame.Visible = false
Instance.new("UICorner", stealFrame).CornerRadius = UDim.new(0, 8)
stealFrame.Parent = gui

local stealFill = Instance.new("Frame")
stealFill.Size = UDim2.new(0, 0, 1, 0)
stealFill.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
stealFill.BorderSizePixel = 0
Instance.new("UICorner", stealFill).CornerRadius = UDim.new(0, 8)
stealFill.Parent = stealFrame

local stealText = Instance.new("TextLabel")
stealText.Size = UDim2.new(1, 0, 1, 0)
stealText.BackgroundTransparency = 1
stealText.Font = Enum.Font.GothamBold
stealText.TextSize = 14
stealText.TextColor3 = Color3.fromRGB(255, 255, 255)
stealText.Text = "STEALING..."
stealText.Parent = stealFrame

StealProgressRE.OnClientEvent:Connect(function(p)
	if p < 0 then
		stealFrame.Visible = false
	else
		stealFrame.Visible = true
		stealFill.Size = UDim2.new(math.clamp(p, 0, 1), 0, 1, 0)
	end
end)

-- Help hint (bottom)
local help = Instance.new("TextLabel")
help.Size = UDim2.new(0, 520, 0, 30)
help.Position = UDim2.new(0.5, -260, 1, -40)
help.BackgroundTransparency = 1
help.Font = Enum.Font.Gotham
help.TextSize = 14
help.TextColor3 = Color3.fromRGB(255, 255, 255)
help.TextStrokeTransparency = 0.5
help.Text = "Buy pets in the SHOP • Hold E near others' pets to steal • Slap thieves!"
help.Parent = gui

print("[Pet Heist] Client ready")
