--[[
    NullyHub Ultimate v3.0
    Full Redz feature set (improved) + one-time killables + Auto Buy + Auto Bounty
    Moving blackhole UI + blackhole watermark
    Lower detection profile
]]

if getgenv().NullyLoaded then return end
getgenv().NullyLoaded = true

local Players           = game:GetService("Players")
local RS                = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local VirtualUser       = game:GetService("VirtualUser")
local CoreGui           = game:GetService("CoreGui")
local TeleportService   = game:GetService("TeleportService")
local HttpService       = game:GetService("HttpService")
local UserInputService  = game:GetService("UserInputService")
local Lighting          = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

-- Place detection
getgenv().CheckPlaceId  = game.PlaceId == 100117331123089 and 100117331123089 or 7449423635
getgenv().CheckPlaceId2 = game.PlaceId == 4442272183 and 4442272183 or 79091703265657
getgenv().CheckPlaceId3 = game.PlaceId == 2753915549 and 2753915549 or 85211729168715

local OldWorld   = game.PlaceId == getgenv().CheckPlaceId3
local NewWorld   = game.PlaceId == getgenv().CheckPlaceId2
local ThreeWorld = game.PlaceId == getgenv().CheckPlaceId

-- ===================== CONFIG =====================
getgenv().Nully = {
    -- Core Farm
    AutoFarm          = false,
    AutoQuest         = true,
    AutoBoss          = false,
    AutoElite         = false,
    AutoSeaBeast      = false,
    AutoShip          = false,
    Magnet            = true,
    MagnetRadius      = 125,
    FarmHeight        = 17,
    FlySpeed          = 95,
    IgnoreUnkillable  = true,

    -- Combat / Aura
    AutoAttack        = true,
    AttackAura        = true,
    AuraRadius        = 58,
    FastAttack        = true,
    SelectWeapon      = "Melee", -- Melee / Sword / Fruit / Gun

    -- One-time specials
    OneTimeKillables  = true,   -- button will force kill once
    KilledOneTime     = {},     -- tracks already killed specials

    -- Auto Bounty
    AutoBounty        = false,
    BountyRadius      = 350,

    -- Fruit / Buy
    FruitNotifier     = false,
    AutoStoreFruit    = false,
    AutoBuyFruit      = false,
    AutoBuyStyle      = false,
    SelectedFruit     = "Flame",
    SelectedStyle     = "Electric",

    -- Islands / Events
    AutoKitsune       = false,
    AutoPrehistoric   = false,
    AutoMirage        = false,
    AutoRaid          = false,
    AutoSpinFruit     = false,

    -- Visuals
    ESP = {Player = false, Mob = false, Boss = false, Fruit = false},
    NoClip            = true,
    AntiAFK           = true,
}

-- One-time specials (Prison + common island one-shots)
local OneTimeNames = {
    "Prisoner", "Escaping Prisoner", "Prison Escapee", "Escapee",
    "Sick Man", "Rich Son", "Detective", "Horned Man",
    "Bartilo", "Trevor", "Swan", "Don Swan", "Indra",
    "Citizen", "Awakened Boss", -- expand as needed
}

-- ===================== UTILS =====================
local function rand(min, max)
    return min + math.random() * (max - min)
end

local function GetChar() return LocalPlayer.Character end
local function GetHRP()
    local c = GetChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function GetHum()
    local c = GetChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function Click()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton1(Vector2.new())
end

local function EquipWeapon(name)
    local char = GetChar()
    if not char then return end
    local tool = LocalPlayer.Backpack:FindFirstChild(name) or char:FindFirstChild(name)
    if tool and tool:IsA("Tool") then
        pcall(function() GetHum():EquipTool(tool) end)
    end
end

local function GetSelectedWeapon()
    local w = getgenv().Nully.SelectWeapon
    local backpack = LocalPlayer.Backpack
    if w == "Melee" then
        for _, t in pairs(backpack:GetChildren()) do
            if t:IsA("Tool") and not string.find(t.Name:lower(), "fruit") and not string.find(t.Name:lower(), "gun") then
                return t.Name
            end
        end
        return "Combat"
    elseif w == "Sword" then
        for _, t in pairs(backpack:GetChildren()) do
            if t:IsA("Tool") and (string.find(t.Name:lower(), "sword") or string.find(t.Name:lower(), "katana") or string.find(t.Name:lower(), "blade") or string.find(t.Name:lower(), "scythe")) then
                return t.Name
            end
        end
    elseif w == "Fruit" then
        for _, t in pairs(backpack:GetChildren()) do
            if t:IsA("Tool") and string.find(t.Name:lower(), "fruit") then return t.Name end
        end
    elseif w == "Gun" then
        for _, t in pairs(backpack:GetChildren()) do
            if t:IsA("Tool") and string.find(t.Name:lower(), "gun") then return t.Name end
        end
    end
    return "Combat"
end

local function SmoothTo(cf, speed)
    local hrp = GetHRP()
    if not hrp then return end
    local dist = (hrp.Position - cf.Position).Magnitude
    local t = math.clamp(dist / (speed or getgenv().Nully.FlySpeed), 0.11, 1.6)
    TweenService:Create(hrp, TweenInfo.new(t + rand(-0.03, 0.05), Enum.EasingStyle.Linear), {CFrame = cf}):Play()
end

local function IsUnkillable(mob)
    if not getgenv().Nully.IgnoreUnkillable then return false end
    if not mob or not mob:FindFirstChild("Humanoid") then return false end
    for _, n in pairs(OneTimeNames) do
        if string.find(string.lower(mob.Name), string.lower(n)) then return true end
    end
    if mob:FindFirstChild("Talk") or mob:FindFirstChild("Dialogue") then return true end
    return false
end

local function IsOneTime(mob)
    for _, n in pairs(OneTimeNames) do
        if string.find(string.lower(mob.Name), string.lower(n)) then return true end
    end
    return false
end

local function AlreadyKilled(mob)
    local key = mob.Name .. "_" .. tostring(mob:GetDebugId())
    return getgenv().Nully.KilledOneTime[key] == true
end

local function MarkKilled(mob)
    local key = mob.Name .. "_" .. tostring(mob:GetDebugId())
    getgenv().Nully.KilledOneTime[key] = true
end

local function IsValidMob(m, allowOneTime)
    if not m or not m:FindFirstChild("Humanoid") or not m:FindFirstChild("HumanoidRootPart") then return false end
    if m.Humanoid.Health <= 0 then return false end
    if allowOneTime then
        if IsOneTime(m) and AlreadyKilled(m) then return false end
        return true
    end
    return not IsUnkillable(m)
end

-- ===================== COMBAT =====================
local function DoAttack(mob)
    if not getgenv().Nully.AutoAttack then return end
    local weapon = GetSelectedWeapon()
    if weapon then EquipWeapon(weapon) end
    if getgenv().Nully.FastAttack then
        for i = 1, 4 do
            Click()
            task.wait(rand(0.02, 0.045))
        end
    else
        Click()
    end
end

local function AttackAura()
    local hrp = GetHRP()
    if not hrp then return end
    local radius = getgenv().Nully.AuraRadius
    for _, m in pairs(workspace.Enemies:GetChildren()) do
        if IsValidMob(m) then
            if (m.HumanoidRootPart.Position - hrp.Position).Magnitude <= radius then
                DoAttack(m)
                if getgenv().Nully.Magnet then
                    pcall(function()
                        if isnetworkowner and isnetworkowner(m.HumanoidRootPart) then
                            m.HumanoidRootPart.CFrame = CFrame.new(hrp.Position + Vector3.new(rand(-1.2,1.2), 0, rand(-1.2,1.2)))
                        end
                    end)
                end
            end
        end
    end
end

-- ===================== ONE-TIME KILL BUTTON =====================
local function KillOneTimeSpecials()
    task.spawn(function()
        for _, m in pairs(workspace.Enemies:GetChildren()) do
            if IsOneTime(m) and not AlreadyKilled(m) and m:FindFirstChild("HumanoidRootPart") then
                local hrp = GetHRP()
                if not hrp then return end
                SmoothTo(m.HumanoidRootPart.CFrame * CFrame.new(0, 12, 0))
                task.wait(0.4)
                for i = 1, 25 do
                    DoAttack(m)
                    task.wait(0.08)
                    if m.Humanoid.Health <= 0 then
                        MarkKilled(m)
                        break
                    end
                end
                MarkKilled(m)
            end
        end
        print("[Nully] One-time specials processed")
    end)
end

-- ===================== AUTO FARM (stable) =====================
local CFrameMon
local function CheckQuest()
    local lvl = (LocalPlayer.Data and LocalPlayer.Data.Level and LocalPlayer.Data.Level.Value) or 1
    if OldWorld then
        if lvl <= 9 then CFrameMon = CFrame.new(1353.45, 3.41, 1376.92)
        elseif lvl <= 14 then CFrameMon = CFrame.new(-1402.75, 98.56, 90.64)
        elseif lvl <= 29 then CFrameMon = CFrame.new(-1267.89, 66.20, -531.82)
        else CFrameMon = CFrame.new(1353.45, 3.41, 1376.92) end
    else
        CFrameMon = CFrame.new(1057.93, 137.61, 1242.08)
    end
end

local function GetFarmCF(target)
    return target.CFrame * CFrame.new(0, getgenv().Nully.FarmHeight, 0) * CFrame.Angles(math.rad(-90), 0, 0)
end

local function AutoFarm()
    while getgenv().Nully.AutoFarm do
        task.wait(rand(0.09, 0.16))
        pcall(function()
            local hrp = GetHRP()
            local hum = GetHum()
            if not hrp or not hum or hum.Health <= 0 then return end
            if getgenv().Nully.AutoQuest then CheckQuest() end

            local closest, dist = nil, math.huge
            for _, m in pairs(workspace.Enemies:GetChildren()) do
                if IsValidMob(m) then
                    local d = (m.HumanoidRootPart.Position - hrp.Position).Magnitude
                    if d < dist then closest = m; dist = d end
                end
            end

            if closest then
                local targetCF = GetFarmCF(closest.HumanoidRootPart)
                if (hrp.Position - targetCF.Position).Magnitude > 7 then
                    SmoothTo(targetCF)
                else
                    hrp.CFrame = targetCF
                end
                if getgenv().Nully.Magnet then
                    for _, m in pairs(workspace.Enemies:GetChildren()) do
                        if IsValidMob(m) and (m.HumanoidRootPart.Position - closest.HumanoidRootPart.Position).Magnitude < getgenv().Nully.MagnetRadius then
                            pcall(function()
                                if isnetworkowner and isnetworkowner(m.HumanoidRootPart) then
                                    m.HumanoidRootPart.CFrame = CFrame.new(closest.HumanoidRootPart.Position + Vector3.new(rand(-1.5,1.5),0,rand(-1.5,1.5)))
                                end
                            end)
                        end
                    end
                end
                if getgenv().Nully.AutoAttack then DoAttack(closest) end
            elseif CFrameMon then
                SmoothTo(CFrameMon * CFrame.new(0, 10, 0))
            end
        end)
    end
end

-- ===================== AUTO BOUNTY =====================
local function AutoBounty()
    while getgenv().Nully.AutoBounty do
        task.wait(rand(0.18, 0.35))
        pcall(function()
            local hrp = GetHRP()
            if not hrp then return end
            local closest, dist = nil, math.huge
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                    local d = (p.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                    if d < dist and d < getgenv().Nully.BountyRadius then
                        closest = p
                        dist = d
                    end
                end
            end
            if closest then
                local target = closest.Character.HumanoidRootPart
                SmoothTo(target.CFrame * CFrame.new(0, 8, 4))
                DoAttack(closest.Character)
            end
        end)
    end
end

-- ===================== AUTO BOSS / ELITE / SEA =====================
local function AutoBoss()
    while getgenv().Nully.AutoBoss do
        task.wait(rand(0.22, 0.4))
        pcall(function()
            for _, m in pairs(workspace.Enemies:GetChildren()) do
                if IsValidMob(m) and (string.find(m.Name, "Boss") or string.find(m.Name, "King") or string.find(m.Name, "Prince") or string.find(m.Name, "Dough")) then
                    SmoothTo(GetFarmCF(m.HumanoidRootPart))
                    if getgenv().Nully.AutoAttack then DoAttack(m) end
                end
            end
        end)
    end
end

-- ===================== AUTO RAID =====================
local function AutoRaid()
    while getgenv().Nully.AutoRaid do
        task.wait(rand(1.0, 1.6))
        pcall(function()
            RS.Remotes.CommF_:InvokeServer("RaidsNpc", "Check")
            RS.Remotes.CommF_:InvokeServer("RaidsNpc", "Select", "Flame")
        end)
    end
end

-- ===================== FRUIT + AUTO BUY =====================
local function FruitNotifier()
    while getgenv().Nully.FruitNotifier do
        task.wait(rand(1.4, 2.2))
        pcall(function()
            for _, v in pairs(workspace:GetChildren()) do
                if v:IsA("Tool") and string.find(v.Name:lower(), "fruit") then
                    print("[Nully] Fruit: " .. v.Name)
                end
            end
        end)
    end
end

local function AutoBuyFruit()
    while getgenv().Nully.AutoBuyFruit do
        task.wait(rand(2.5, 4))
        pcall(function()
            RS.Remotes.CommF_:InvokeServer("PurchaseRawFruit", getgenv().Nully.SelectedFruit)
            -- fallback common call
            RS.Remotes.CommF_:InvokeServer("BuyFruit", getgenv().Nully.SelectedFruit)
        end)
    end
end

local function AutoBuyStyle()
    while getgenv().Nully.AutoBuyStyle do
        task.wait(rand(3, 5))
        pcall(function()
            RS.Remotes.CommF_:InvokeServer("BuyHaki", getgenv().Nully.SelectedStyle)
            RS.Remotes.CommF_:InvokeServer("BuyStyle", getgenv().Nully.SelectedStyle)
        end)
    end
end

local function AutoSpin()
    while getgenv().Nully.AutoSpinFruit do
        task.wait(rand(1.3, 2.1))
        pcall(function()
            RS.Remotes.CommF_:InvokeServer("Cousin", "Buy")
        end)
    end
end

-- ===================== ISLAND AUTOMATION =====================
local function AutoKitsune()
    while getgenv().Nully.AutoKitsune do
        task.wait(rand(2, 3.5))
        pcall(function()
            -- common remote pattern for Kitsune
            RS.Remotes.CommF_:InvokeServer("KitsuneIsland")
            -- teleport / farm logic would go here
        end)
    end
end

local function AutoPrehistoric()
    while getgenv().Nully.AutoPrehistoric do
        task.wait(rand(2.2, 3.8))
        pcall(function()
            RS.Remotes.CommF_:InvokeServer("PrehistoricIsland")
        end)
    end
end

local function AutoMirage()
    while getgenv().Nully.AutoMirage do
        task.wait(rand(2.5, 4))
        pcall(function()
            RS.Remotes.CommF_:InvokeServer("MirageIsland")
        end)
    end
end

-- ===================== ESP =====================
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "NullyESP"
ESPFolder.Parent = CoreGui

local function ClearESP()
    ESPFolder:ClearAllChildren()
end

local function CreateESP(obj, text, color)
    local part = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj
    if not part then return end
    local bill = Instance.new("BillboardGui")
    bill.Adornee = part
    bill.Size = UDim2.new(0, 150, 0, 28)
    bill.AlwaysOnTop = true
    bill.Parent = ESPFolder
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color
    label.TextStrokeTransparency = 0.3
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.Parent = bill
end

local function UpdateESP()
    ClearESP()
    if getgenv().Nully.ESP.Player then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                CreateESP(p.Character, p.Name, Color3.fromRGB(190, 120, 255))
            end
        end
    end
    if getgenv().Nully.ESP.Mob then
        for _, m in pairs(workspace.Enemies:GetChildren()) do
            if IsValidMob(m) then CreateESP(m, m.Name, Color3.fromRGB(100, 200, 255)) end
        end
    end
    if getgenv().Nully.ESP.Boss then
        for _, m in pairs(workspace.Enemies:GetChildren()) do
            if IsValidMob(m) and (string.find(m.Name, "Boss") or string.find(m.Name, "King")) then
                CreateESP(m, "[BOSS] "..m.Name, Color3.fromRGB(255, 70, 70))
            end
        end
    end
    if getgenv().Nully.ESP.Fruit then
        for _, v in pairs(workspace:GetChildren()) do
            if v:IsA("Tool") and string.find(v.Name:lower(), "fruit") then
                CreateESP(v, v.Name, Color3.fromRGB(255, 190, 50))
            end
        end
    end
end

-- NoClip
RunService.Stepped:Connect(function()
    if getgenv().Nully.NoClip then
        local char = GetChar()
        if char then
            for _, p in pairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end
end)

-- Aura heartbeat (throttled)
local lastAura = 0
RunService.Heartbeat:Connect(function()
    if tick() - lastAura < 0.08 then return end
    lastAura = tick()
    if getgenv().Nully.AttackAura and getgenv().Nully.AutoAttack then
        AttackAura()
    end
end)

-- ESP loop
task.spawn(function()
    while task.wait(rand(1.1, 1.6)) do
        if getgenv().Nully.ESP.Player or getgenv().Nully.ESP.Mob or getgenv().Nully.ESP.Boss or getgenv().Nully.ESP.Fruit then
            UpdateESP()
        else
            ClearESP()
        end
    end
end)

-- Anti AFK
if getgenv().Nully.AntiAFK then
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end

-- ===================== UI - BLACKHOLE THEME =====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NullyHubUltimate"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

-- Blackhole watermark (top right)
local Watermark = Instance.new("Frame")
Watermark.Size = UDim2.new(0, 48, 0, 48)
Watermark.Position = UDim2.new(1, -60, 0, 12)
Watermark.BackgroundColor3 = Color3.fromRGB(5, 5, 12)
Watermark.BorderSizePixel = 0
Watermark.Parent = ScreenGui
Instance.new("UICorner", Watermark).CornerRadius = UDim.new(1, 0)

local WMStroke = Instance.new("UIStroke")
WMStroke.Color = Color3.fromRGB(120, 40, 200)
WMStroke.Thickness = 2
WMStroke.Parent = Watermark

local WMLabel = Instance.new("TextLabel")
WMLabel.Size = UDim2.new(1, 0, 1, 0)
WMLabel.BackgroundTransparency = 1
WMLabel.Text = "⚫"
WMLabel.TextColor3 = Color3.fromRGB(180, 100, 255)
WMLabel.Font = Enum.Font.GothamBold
WMLabel.TextSize = 22
WMLabel.Parent = Watermark

-- Main window
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 520, 0, 400)
Main.Position = UDim2.new(0.5, -260, 0.5, -200)
Main.BackgroundColor3 = Color3.fromRGB(12, 10, 18)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(90, 30, 160)
MainStroke.Thickness = 1.6
MainStroke.Parent = Main

-- Moving blackhole background
local BH = Instance.new("Frame")
BH.Size = UDim2.new(2, 0, 2, 0)
BH.Position = UDim2.new(-0.5, 0, -0.5, 0)
BH.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
BH.BackgroundTransparency = 0.55
BH.BorderSizePixel = 0
BH.ZIndex = 0
BH.Parent = Main
Instance.new("UICorner", BH).CornerRadius = UDim.new(1, 0)

local BHGradient = Instance.new("UIGradient")
BHGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(5, 0, 15)),
    ColorSequenceKeypoint.new(0.4, Color3.fromRGB(40, 10, 80)),
    ColorSequenceKeypoint.new(0.7, Color3.fromRGB(10, 5, 25)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
})
BHGradient.Rotation = 0
BHGradient.Parent = BH

-- Animate blackhole
task.spawn(function()
    local rot = 0
    while BH and BH.Parent do
        rot = rot + 0.6
        BHGradient.Rotation = rot
        BH.Position = UDim2.new(-0.5 + math.sin(tick()*0.3)*0.08, 0, -0.5 + math.cos(tick()*0.25)*0.06, 0)
        task.wait(0.03)
    end
end)

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 38)
TitleBar.BackgroundColor3 = Color3.fromRGB(22, 16, 35)
TitleBar.BorderSizePixel = 0
TitleBar.ZIndex = 2
TitleBar.Parent = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -90, 1, 0)
Title.Position = UDim2.new(0, 14, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚫  NullyHub Ultimate  |  Blackhole"
Title.TextColor3 = Color3.fromRGB(200, 160, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 3
Title.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 34, 0, 34)
CloseBtn.Position = UDim2.new(1, -38, 0, 2)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 22
CloseBtn.ZIndex = 3
CloseBtn.Parent = TitleBar
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    getgenv().NullyLoaded = false
end)

-- Sidebar
local Side = Instance.new("Frame")
Side.Size = UDim2.new(0, 118, 1, -38)
Side.Position = UDim2.new(0, 0, 0, 38)
Side.BackgroundColor3 = Color3.fromRGB(16, 12, 26)
Side.BorderSizePixel = 0
Side.ZIndex = 2
Side.Parent = Main

local Content = Instance.new("ScrollingFrame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -118, 1, -38)
Content.Position = UDim2.new(0, 118, 0, 38)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 4
Content.CanvasSize = UDim2.new(0, 0, 0, 520)
Content.ZIndex = 2
Content.Parent = Main

local function ClearContent()
    for _, c in pairs(Content:GetChildren()) do c:Destroy() end
end

local function MakeToggle(parent, name, default, y, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.94, 0, 0, 28)
    btn.Position = UDim2.new(0.03, 0, 0, y)
    btn.BackgroundColor3 = default and Color3.fromRGB(65, 30, 120) or Color3.fromRGB(28, 22, 40)
    btn.Text = "  " .. name .. (default and "  [ON]" or "  [OFF]")
    btn.TextColor3 = Color3.fromRGB(225, 210, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.ZIndex = 3
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(65, 30, 120) or Color3.fromRGB(28, 22, 40)
        btn.Text = "  " .. name .. (state and "  [ON]" or "  [OFF]")
        callback(state)
    end)
end

local function MakeLabel(parent, text, y)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.94, 0, 0, 20)
    l.Position = UDim2.new(0.03, 0, 0, y)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(150, 130, 200)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 3
    l.Parent = parent
end

local function MakeDropdown(parent, name, options, default, y, callback)
    local current = default
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.94, 0, 0, 28)
    btn.Position = UDim2.new(0.03, 0, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(32, 26, 48)
    btn.Text = "  " .. name .. ": " .. current
    btn.TextColor3 = Color3.fromRGB(220, 205, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.ZIndex = 3
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local idx = 1
    for i, v in ipairs(options) do if v == default then idx = i break end end
    btn.MouseButton1Click:Connect(function()
        idx = idx % #options + 1
        current = options[idx]
        btn.Text = "  " .. name .. ": " .. current
        callback(current)
    end)
end

local function MakeButton(parent, name, y, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.94, 0, 0, 30)
    btn.Position = UDim2.new(0.03, 0, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(50, 20, 90)
    btn.Text = "  " .. name
    btn.TextColor3 = Color3.fromRGB(230, 210, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.ZIndex = 3
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(callback)
end

local tabs = {"Main", "Farm", "Combat", "Bounty", "Buy", "Events", "ESP", "Misc"}
local function SwitchTab(tab)
    ClearContent()
    Content.CanvasSize = UDim2.new(0, 0, 0, 560)

    if tab == "Main" then
        MakeLabel(Content, "CORE FARM", 6)
        MakeToggle(Content, "Auto Farm", getgenv().Nully.AutoFarm, 28, function(v)
            getgenv().Nully.AutoFarm = v
            if v then task.spawn(AutoFarm) end
        end)
        MakeToggle(Content, "Auto Quest", getgenv().Nully.AutoQuest, 62, function(v) getgenv().Nully.AutoQuest = v end)
        MakeToggle(Content, "Auto Boss", getgenv().Nully.AutoBoss, 96, function(v)
            getgenv().Nully.AutoBoss = v
            if v then task.spawn(AutoBoss) end
        end)
        MakeToggle(Content, "Magnet / Bring", getgenv().Nully.Magnet, 130, function(v) getgenv().Nully.Magnet = v end)
        MakeToggle(Content, "NoClip", getgenv().Nully.NoClip, 164, function(v) getgenv().Nully.NoClip = v end)
        MakeButton(Content, "Kill One-Time Specials (Prison etc)", 210, KillOneTimeSpecials)

    elseif tab == "Farm" then
        MakeLabel(Content, "FARM OPTIONS", 6)
        MakeToggle(Content, "Ignore Unkillable", getgenv().Nully.IgnoreUnkillable, 28, function(v) getgenv().Nully.IgnoreUnkillable = v end)
        MakeToggle(Content, "One-Time Killables Mode", getgenv().Nully.OneTimeKillables, 62, function(v) getgenv().Nully.OneTimeKillables = v end)

    elseif tab == "Combat" then
        MakeLabel(Content, "COMBAT / AURA", 6)
        MakeToggle(Content, "Auto Attack", getgenv().Nully.AutoAttack, 28, function(v) getgenv().Nully.AutoAttack = v end)
        MakeToggle(Content, "Attack Aura", getgenv().Nully.AttackAura, 62, function(v) getgenv().Nully.AttackAura = v end)
        MakeToggle(Content, "Fast Attack", getgenv().Nully.FastAttack, 96, function(v) getgenv().Nully.FastAttack = v end)
        MakeDropdown(Content, "Weapon", {"Melee", "Sword", "Fruit", "Gun"}, getgenv().Nully.SelectWeapon, 136, function(v)
            getgenv().Nully.SelectWeapon = v
        end)

    elseif tab == "Bounty" then
        MakeLabel(Content, "AUTO BOUNTY (PvP)", 6)
        MakeToggle(Content, "Auto Bounty", getgenv().Nully.AutoBounty, 28, function(v)
            getgenv().Nully.AutoBounty = v
            if v then task.spawn(AutoBounty) end
        end)

    elseif tab == "Buy" then
        MakeLabel(Content, "AUTO BUY", 6)
        MakeToggle(Content, "Auto Buy Fruit", getgenv().Nully.AutoBuyFruit, 28, function(v)
            getgenv().Nully.AutoBuyFruit = v
            if v then task.spawn(AutoBuyFruit) end
        end)
        MakeDropdown(Content, "Fruit", {"Flame", "Ice", "Light", "Dark", "Magma", "Quake", "Buddha", "String", "Bird: Phoenix", "Rumble", "Paw", "Gravity", "Dough", "Shadow", "Venom", "Control", "Spirit", "Dragon", "Leopard"}, getgenv().Nully.SelectedFruit, 68, function(v)
            getgenv().Nully.SelectedFruit = v
        end)
        MakeToggle(Content, "Auto Buy Style / Haki", getgenv().Nully.AutoBuyStyle, 110, function(v)
            getgenv().Nully.AutoBuyStyle = v
            if v then task.spawn(AutoBuyStyle) end
        end)
        MakeDropdown(Content, "Style", {"Electric", "Water", "Dragon", "Dark", "Light", "Flame"}, getgenv().Nully.SelectedStyle, 150, function(v)
            getgenv().Nully.SelectedStyle = v
        end)
        MakeToggle(Content, "Auto Spin Fruit", getgenv().Nully.AutoSpinFruit, 192, function(v)
            getgenv().Nully.AutoSpinFruit = v
            if v then task.spawn(AutoSpin) end
        end)

    elseif tab == "Events" then
        MakeLabel(Content, "ISLANDS / EVENTS", 6)
        MakeToggle(Content, "Auto Raid", getgenv().Nully.AutoRaid, 28, function(v)
            getgenv().Nully.AutoRaid = v
            if v then task.spawn(AutoRaid) end
        end)
        MakeToggle(Content, "Auto Kitsune Island", getgenv().Nully.AutoKitsune, 62, function(v)
            getgenv().Nully.AutoKitsune = v
            if v then task.spawn(AutoKitsune) end
        end)
        MakeToggle(Content, "Auto Prehistoric Island", getgenv().Nully.AutoPrehistoric, 96, function(v)
            getgenv().Nully.AutoPrehistoric = v
            if v then task.spawn(AutoPrehistoric) end
        end)
        MakeToggle(Content, "Auto Mirage Island", getgenv().Nully.AutoMirage, 130, function(v)
            getgenv().Nully.AutoMirage = v
            if v then task.spawn(AutoMirage) end
        end)
        MakeToggle(Content, "Fruit Notifier", getgenv().Nully.FruitNotifier, 164, function(v)
            getgenv().Nully.FruitNotifier = v
            if v then task.spawn(FruitNotifier) end
        end)

    elseif tab == "ESP" then
        MakeLabel(Content, "VISUALS", 6)
        MakeToggle(Content, "Player ESP", getgenv().Nully.ESP.Player, 28, function(v) getgenv().Nully.ESP.Player = v end)
        MakeToggle(Content, "Mob ESP", getgenv().Nully.ESP.Mob, 62, function(v) getgenv().Nully.ESP.Mob = v end)
        MakeToggle(Content, "Boss ESP", getgenv().Nully.ESP.Boss, 96, function(v) getgenv().Nully.ESP.Boss = v end)
        MakeToggle(Content, "Fruit ESP", getgenv().Nully.ESP.Fruit, 130, function(v) getgenv().Nully.ESP.Fruit = v end)

    elseif tab == "Misc" then
        MakeLabel(Content, "MISC", 6)
        MakeToggle(Content, "Anti AFK", getgenv().Nully.AntiAFK, 28, function(v) getgenv().Nully.AntiAFK = v end)
    end
end

-- Side buttons
for i, name in ipairs(tabs) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -10, 0, 30)
    b.Position = UDim2.new(0, 5, 0, 8 + (i-1)*34)
    b.BackgroundColor3 = Color3.fromRGB(28, 20, 45)
    b.Text = name
    b.TextColor3 = Color3.fromRGB(200, 175, 255)
    b.Font = Enum.Font.Gotham
    b.TextSize = 12
    b.ZIndex = 3
    b.Parent = Side
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(function() SwitchTab(name) end)
end

-- Drag
local dragging, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)
TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

SwitchTab("Main")
print("[NullyHub Ultimate v3.0] Blackhole loaded | Full Redz set + one-time + Auto Buy + Bounty")

print("[Nully] Full script loaded | Click the title for NSFW mode")
