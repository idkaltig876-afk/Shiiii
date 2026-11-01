--[[
    Nully Hub - Full Build
    Dark Galaxy + Explicit Hentai Easter Egg
    Keyless
]]

if getgenv().NullyLoaded then return end
getgenv().NullyLoaded = true

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- World detection
getgenv().CheckPlaceId  = game.PlaceId == 100117331123089 and 100117331123089 or 7449423635
getgenv().CheckPlaceId2 = game.PlaceId == 4442272183 and 4442272183 or 79091703265657
getgenv().CheckPlaceId3 = game.PlaceId == 2753915549 and 2753915549 or 85211729168715

local OldWorld   = game.PlaceId == getgenv().CheckPlaceId3
local NewWorld   = game.PlaceId == getgenv().CheckPlaceId2
local ThreeWorld = game.PlaceId == getgenv().CheckPlaceId

getgenv().Nully = {
    AutoFarm = false,
    AutoQuest = true,
    Magnet = true,
    MagnetRadius = 115,
    FlySpeed = 82,
    FastAttack = true,
    NoClip = true,
    IgnoreUnkillable = true,
    AutoSpinFruit = false,
    AutoBoss = false,
    AutoRaid = false,
    FruitNotifier = false,
    ESP = {Player = false, Fruit = false, Mob = false},
    SelectWeapon = "Melee",
}

-- AntiCheat
local function AntiCheat()
    pcall(function()
        for _, c in pairs(getconnections(game:GetService("ScriptContext").Error)) do
            c:Disable()
        end
    end)
    local old
    old = hookmetamethod(game, "__index", newcclosure(function(self, key)
        if not checkcaller() and key == "Velocity" and typeof(self) == "Instance" and self:IsA("BasePart") then
            return Vector3.zero
        end
        return old(self, key)
    end))
end
AntiCheat()

-- Utils
local function GetHRP()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end
local function GetHum()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
end
local function Click()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton1(Vector2.new())
end
local function toTarget(cf)
    local hrp = GetHRP()
    if not hrp then return end
    local dist = (hrp.Position - cf.Position).Magnitude
    local t = math.clamp(dist / getgenv().Nully.FlySpeed, 0.18, 2.5)
    TweenService:Create(hrp, TweenInfo.new(t, Enum.EasingStyle.Linear), {CFrame = cf}):Play()
end
local function Magnet(center)
    if not getgenv().Nully.Magnet then return end
    for _, m in pairs(workspace.Enemies:GetChildren()) do
        if m:FindFirstChild("Humanoid") and m:FindFirstChild("HumanoidRootPart") and m.Humanoid.Health > 0 then
            if (m.HumanoidRootPart.Position - center).Magnitude <= getgenv().Nully.MagnetRadius then
                pcall(function()
                    if isnetworkowner and isnetworkowner(m.HumanoidRootPart) then
                        m.HumanoidRootPart.CFrame = CFrame.new(center + Vector3.new(math.random(-2,2), 0, math.random(-2,2)))
                    end
                end)
            end
        end
    end
end

-- Unkillable filter
local Unkillable = {
    "Sick Man", "Rich Son", "Detective", "Citizen", "Horned Man",
    "Bartilo", "Trevor", "Swan", "Indra", "Don Swan",
    "Prisoner", "Escaping Prisoner", "Prison Escapee", "Escapee", "Escaping"
}
local function IsUnkillable(mob)
    if not getgenv().Nully.IgnoreUnkillable then return false end
    if not mob or not mob:FindFirstChild("Humanoid") then return false end
    for _, n in pairs(Unkillable) do
        if string.find(string.lower(mob.Name), string.lower(n)) then return true end
    end
    if mob:FindFirstChild("Talk") or mob:FindFirstChild("Dialogue") then return true end
    return false
end

-- Quest
local CFrameMon
local function CheckQuest()
    local lvl = LocalPlayer.Data.Level.Value
    if OldWorld then
        if lvl <= 9 then CFrameMon = CFrame.new(1353.45, 3.41, 1376.92)
        elseif lvl <= 14 then CFrameMon = CFrame.new(-1402.75, 98.56, 90.64)
        elseif lvl <= 29 then CFrameMon = CFrame.new(-1267.89, 66.20, -531.82)
        else CFrameMon = CFrame.new(1353.45, 3.41, 1376.92) end
    else
        CFrameMon = CFrame.new(1057.93, 137.61, 1242.08)
    end
end

-- Auto Farm
local function AutoFarm()
    while getgenv().Nully.AutoFarm and task.wait(0.11) do
        pcall(function()
            local hrp = GetHRP()
            if not hrp or not GetHum() or GetHum().Health <= 0 then return end
            if getgenv().Nully.AutoQuest then CheckQuest() end

            local closest, dist = nil, math.huge
            for _, m in pairs(workspace.Enemies:GetChildren()) do
                if m:FindFirstChild("Humanoid") and m:FindFirstChild("HumanoidRootPart") and m.Humanoid.Health > 0 and not IsUnkillable(m) then
                    local d = (m.HumanoidRootPart.Position - hrp.Position).Magnitude
                    if d < dist then closest = m; dist = d end
                end
            end
            if closest then
                toTarget(closest.HumanoidRootPart.CFrame * CFrame.new(0, 21, 4))
                Magnet(closest.HumanoidRootPart.Position)
                if getgenv().Nully.FastAttack then Click() end
                hrp.CFrame = closest.HumanoidRootPart.CFrame * CFrame.new(0, 19, 3)
            elseif CFrameMon then
                toTarget(CFrameMon * CFrame.new(0, 12, 0))
            end
        end)
    end
end

-- Auto Boss
local function AutoBoss()
    while getgenv().Nully.AutoBoss and task.wait(0.35) do
        pcall(function()
            for _, m in pairs(workspace.Enemies:GetChildren()) do
                if m:FindFirstChild("Humanoid") and m:FindFirstChild("HumanoidRootPart") and m.Humanoid.Health > 0 and string.find(m.Name, "Boss") then
                    toTarget(m.HumanoidRootPart.CFrame * CFrame.new(0, 25, 0))
                    Magnet(m.HumanoidRootPart.Position)
                    if getgenv().Nully.FastAttack then Click() end
                end
            end
        end)
    end
end

-- Auto Raid
local function AutoRaid()
    while getgenv().Nully.AutoRaid and task.wait(1.1) do
        pcall(function()
            RS.Remotes.CommF_:InvokeServer("RaidsNpc", "Check")
            RS.Remotes.CommF_:InvokeServer("RaidsNpc", "Select", "Flame")
        end)
    end
end

-- Fruit Notifier
local function FruitNotifier()
    while getgenv().Nully.FruitNotifier and task.wait(2) do
        pcall(function()
            for _, v in pairs(workspace:GetChildren()) do
                if v:IsA("Tool") and string.find(v.Name:lower(), "fruit") then
                    print("[Nully] Fruit found: " .. v.Name)
                end
            end
        end)
    end
end

-- Auto Spin
local function AutoSpin()
    while getgenv().Nully.AutoSpinFruit and task.wait(1.4) do
        pcall(function()
            RS.Remotes.CommF_:InvokeServer("Cousin", "Buy")
        end)
    end
end

-- ESP
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "NullyESP"
ESPFolder.Parent = CoreGui

local function ClearESP()
    ESPFolder:ClearAllChildren()
end

local function CreateESP(obj, text, color)
    local part = obj:FindFirstChild("HumanoidRootPart") or obj
    if not part then return end
    local bill = Instance.new("BillboardGui")
    bill.Adornee = part
    bill.Size = UDim2.new(0, 130, 0, 28)
    bill.AlwaysOnTop = true
    bill.Parent = ESPFolder
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color
    label.TextStrokeTransparency = 0.3
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
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
            if m:FindFirstChild("HumanoidRootPart") and m.Humanoid.Health > 0 and not IsUnkillable(m) then
                CreateESP(m, m.Name, Color3.fromRGB(100, 200, 255))
            end
        end
    end
    if getgenv().Nully.ESP.Fruit then
        for _, v in pairs(workspace:GetChildren()) do
            if v:IsA("Tool") and string.find(v.Name:lower(), "fruit") then
                CreateESP(v, v.Name, Color3.fromRGB(255, 190, 60))
            end
        end
    end
end

-- ===================== UI =====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NullyHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 330, 0, 520)
Main.Position = UDim2.new(0.015, 0, 0.15, 0)
Main.BackgroundColor3 = Color3.fromRGB(8, 5, 16)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(95, 40, 170)
stroke.Thickness = 1.5
stroke.Transparency = 0.3
stroke.Parent = Main

-- Title with Explicit Easter Egg
local Title = Instance.new("TextButton")
Title.Size = UDim2.new(1, 0, 0, 42)
Title.BackgroundTransparency = 1
Title.Text = "  Nully  |  Galaxy Full"
Title.TextColor3 = Color3.fromRGB(210, 180, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 17
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main

local isNSFW = false
local originalTexts = {}

local function MakeToggle(name, default, y, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 30)
    btn.Position = UDim2.new(0.05, 0, 0, y)
    btn.BackgroundColor3 = default and Color3.fromRGB(75, 30, 140) or Color3.fromRGB(20, 14, 35)
    btn.Text = "  " .. name .. (default and "  [ON]" or "  [OFF]")
    btn.TextColor3 = Color3.fromRGB(235, 225, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = Main
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    originalTexts[btn] = btn.Text

    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and (isNSFW and Color3.fromRGB(180, 20, 80) or Color3.fromRGB(75, 30, 140)) or (isNSFW and Color3.fromRGB(45, 8, 25) or Color3.fromRGB(20, 14, 35))
        btn.Text = "  " .. name .. (state and "  [ON]" or "  [OFF]")
        if isNSFW then
            local explicit = btn.Text
            if string.find(name, "Auto Farm") then explicit = "  Breed Farm" .. (state and "  [ON]" or "  [OFF]")
            elseif string.find(name, "Auto Quest") then explicit = "  Rape Quest" .. (state and "  [ON]" or "  [OFF]")
            elseif string.find(name, "Magnet") then explicit = "  Suck Mobs In" .. (state and "  [ON]" or "  [OFF]")
            elseif string.find(name, "Ignore Unkillable") then explicit = "  Ignore Used Toys" .. (state and "  [ON]" or "  [OFF]")
            elseif string.find(name, "Auto Spin Fruit") then explicit = "  Spin for Cum Fruit" .. (state and "  [ON]" or "  [OFF]")
            elseif string.find(name, "Auto Boss") then explicit = "  Fuck Bosses" .. (state and "  [ON]" or "  [OFF]")
            elseif string.find(name, "Auto Raid") then explicit = "  Gangbang Raid" .. (state and "  [ON]" or "  [OFF]")
            elseif string.find(name, "Fruit Notifier") then explicit = "  Nude Fruit Alert" .. (state and "  [ON]" or "  [OFF]")
            elseif string.find(name, "Fast Attack") then explicit = "  Fast Pound" .. (state and "  [ON]" or "  [OFF]")
            elseif string.find(name, "NoClip") then explicit = "  Ghost Fuck" .. (state and "  [ON]" or "  [OFF]")
            elseif string.find(name, "Player ESP") then explicit = "  See Naked Players" .. (state and "  [ON]" or "  [OFF]")
            elseif string.find(name, "Mob ESP") then explicit = "  See Prey" .. (state and "  [ON]" or "  [OFF]")
            elseif string.find(name, "Fruit ESP") then explicit = "  See Juicy Fruits" .. (state and "  [ON]" or "  [OFF]")
            end
            btn.Text = explicit
        end
        callback(state)
    end)
end

MakeToggle("Auto Farm", false, 50, function(v) getgenv().Nully.AutoFarm = v if v then task.spawn(AutoFarm) end end)
MakeToggle("Auto Quest", true, 85, function(v) getgenv().Nully.AutoQuest = v end)
MakeToggle("Magnet", true, 120, function(v) getgenv().Nully.Magnet = v end)
MakeToggle("Ignore Unkillable", true, 155, function(v) getgenv().Nully.IgnoreUnkillable = v end)
MakeToggle("Auto Spin Fruit", false, 190, function(v) getgenv().Nully.AutoSpinFruit = v if v then task.spawn(AutoSpin) end end)
MakeToggle("Auto Boss", false, 225, function(v) getgenv().Nully.AutoBoss = v if v then task.spawn(AutoBoss) end end)
MakeToggle("Auto Raid", false, 260, function(v) getgenv().Nully.AutoRaid = v if v then task.spawn(AutoRaid) end end)
MakeToggle("Fruit Notifier", false, 295, function(v) getgenv().Nully.FruitNotifier = v if v then task.spawn(FruitNotifier) end end)
MakeToggle("Fast Attack", true, 330, function(v) getgenv().Nully.FastAttack = v end)
MakeToggle("NoClip", true, 365, function(v) getgenv().Nully.NoClip = v end)
MakeToggle("Player ESP", false, 400, function(v) getgenv().Nully.ESP.Player = v end)
MakeToggle("Mob ESP", false, 435, function(v) getgenv().Nully.ESP.Mob = v end)
MakeToggle("Fruit ESP", false, 470, function(v) getgenv().Nully.ESP.Fruit = v end)

-- Explicit Theme Switch
Title.MouseButton1Click:Connect(function()
    isNSFW = not isNSFW
    if isNSFW then
        Main.BackgroundColor3 = Color3.fromRGB(22, 3, 12)
        stroke.Color = Color3.fromRGB(255, 50, 120)
        stroke.Thickness = 2
        Title.Text = "  Nully  |  Nude Hentai"
        Title.TextColor3 = Color3.fromRGB(255, 160, 210)

        for _, btn in pairs(Main:GetChildren()) do
            if btn:IsA("TextButton") and btn ~= Title then
                local state = string.find(btn.Text, "%[ON%]")
                if string.find(btn.Text, "Auto Farm") or string.find(btn.Text, "Breed") then
                    btn.Text = "  Breed Farm" .. (state and "  [ON]" or "  [OFF]")
                elseif string.find(btn.Text, "Auto Quest") or string.find(btn.Text, "Rape") then
                    btn.Text = "  Rape Quest" .. (state and "  [ON]" or "  [OFF]")
                elseif string.find(btn.Text, "Magnet") or string.find(btn.Text, "Suck") then
                    btn.Text = "  Suck Mobs In" .. (state and "  [ON]" or "  [OFF]")
                elseif string.find(btn.Text, "Ignore") then
                    btn.Text = "  Ignore Used Toys" .. (state and "  [ON]" or "  [OFF]")
                elseif string.find(btn.Text, "Spin") then
                    btn.Text = "  Spin for Cum Fruit" .. (state and "  [ON]" or "  [OFF]")
                elseif string.find(btn.Text, "Boss") then
                    btn.Text = "  Fuck Bosses" .. (state and "  [ON]" or "  [OFF]")
                elseif string.find(btn.Text, "Raid") then
                    btn.Text = "  Gangbang Raid" .. (state and "  [ON]" or "  [OFF]")
                elseif string.find(btn.Text, "Notifier") or string.find(btn.Text, "Nude Fruit") then
                    btn.Text = "  Nude Fruit Alert" .. (state and "  [ON]" or "  [OFF]")
                elseif string.find(btn.Text, "Fast") or string.find(btn.Text, "Pound") then
                    btn.Text = "  Fast Pound" .. (state and "  [ON]" or "  [OFF]")
                elseif string.find(btn.Text, "NoClip") or string.find(btn.Text, "Ghost") then
                    btn.Text = "  Ghost Fuck" .. (state and "  [ON]" or "  [OFF]")
                elseif string.find(btn.Text, "Player") then
                    btn.Text = "  See Naked Players" .. (state and "  [ON]" or "  [OFF]")
                elseif string.find(btn.Text, "Mob") or string.find(btn.Text, "Prey") then
                    btn.Text = "  See Prey" .. (state and "  [ON]" or "  [OFF]")
                elseif string.find(btn.Text, "Fruit ESP") or string.find(btn.Text, "Juicy") then
                    btn.Text = "  See Juicy Fruits" .. (state and "  [ON]" or "  [OFF]")
                end
                btn.BackgroundColor3 = state and Color3.fromRGB(180, 20, 80) or Color3.fromRGB(45, 8, 25)
                btn.TextColor3 = Color3.fromRGB(255, 210, 230)
            end
        end
    else
        Main.BackgroundColor3 = Color3.fromRGB(8, 5, 16)
        stroke.Color = Color3.fromRGB(95, 40, 170)
        stroke.Thickness = 1.5
        Title.Text = "  Nully  |  Galaxy Full"
        Title.TextColor3 = Color3.fromRGB(210, 180, 255)

        for btn, original in pairs(originalTexts) do
            if btn and btn.Parent then
                btn.Text = original
                if string.find(original, "%[ON%]") then
                    btn.BackgroundColor3 = Color3.fromRGB(75, 30, 140)
                else
                    btn.BackgroundColor3 = Color3.fromRGB(20, 14, 35)
                end
                btn.TextColor3 = Color3.fromRGB(235, 225, 255)
            end
        end
    end
end)

-- Loops
RunService.Stepped:Connect(function()
    if getgenv().Nully.NoClip and LocalPlayer.Character then
        for _, p in pairs(LocalPlayer.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)

task.spawn(function()
    while task.wait(1.2) do
        if getgenv().Nully.ESP.Player or getgenv().Nully.ESP.Mob or getgenv().Nully.ESP.Fruit then
            UpdateESP()
        else
            ClearESP()
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    AntiCheat()
end)

print("[Nully] Full script loaded | Click the title for NSFW mode")
