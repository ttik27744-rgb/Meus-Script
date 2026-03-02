-- ==========================================
-- ⚡ TSB BODY LOCK-ON (ZERO DELAY)
-- ==========================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Configurações
local Settings = {
    Prediction = 0.135,
    TargetParts = {"HumanoidRootPart", "UpperTorso", "Torso"}
}

local Locked = false
local LockedPlayer = nil
local LockConnection = nil

-- ==========================================
-- BYPASS ANTI-CHEAT (TSB FOCUS)
-- ==========================================
local OldNamecall
OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    
    -- Ignora chamadas do nosso próprio executor
    if not checkcaller() then
        -- Bloqueia tentativas do Anti-Cheat local de te dar Kick
        if method == "Kick" or method == "kick" then
            return task.wait(9e9) 
        end
    end
    
    return OldNamecall(self, ...)
end)

-- ==========================================
-- FUNÇÕES DE BUSCA
-- ==========================================
local function GetRoot()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
end

local function IsAlive(plr)
    if not plr or not plr.Character then return false end
    local hum = plr.Character:FindFirstChild("Humanoid")
    return hum and hum.Health > 0
end

local function GetClosestPlayer()
    local root = GetRoot()
    if not root then return nil end
    
    local closest, shortDist = nil, math.huge
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and IsAlive(plr) then
            local targetRoot = plr.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local dist = (root.Position - targetRoot.Position).Magnitude
                if dist < shortDist then
                    shortDist = dist
                    closest = plr
                end
            end
        end
    end
    return closest
end

local function GetTargetPart(char)
    for _, partName in ipairs(Settings.TargetParts) do
        local part = char:FindFirstChild(partName)
        if part then return part end
    end
    return nil
end

-- ==========================================
-- LÓGICA DO LOCK-ON (ZERO DELAY)
-- ==========================================
local function UpdateLock()
    local hum = GetHumanoid()
    local root = GetRoot()
    
    if not Locked or not LockedPlayer or not IsAlive(LockedPlayer) or not root or not hum then
        if Locked then DisableLock() end
        return
    end
    
    local targetPart = GetTargetPart(LockedPlayer.Character)
    if not targetPart then return end
    
    -- Predição de Movimento
    local predictedPos = targetPart.Position + (targetPart.Velocity * Settings.Prediction)
    
    -- Desativa a rotação padrão do Roblox para não "brigar" com o script
    hum.AutoRotate = false 
    
    -- Rotação Instantânea (Apenas eixo Y para o personagem não olhar pro chão/céu)
    local lookPos = Vector3.new(predictedPos.X, root.Position.Y, predictedPos.Z)
    root.CFrame = CFrame.lookAt(root.Position, lookPos)
end

function DisableLock()
    Locked = false
    LockedPlayer = nil
    
    local hum = GetHumanoid()
    if hum then hum.AutoRotate = true end -- Devolve a rotação normal
    
    if LockConnection then
        LockConnection:Disconnect()
        LockConnection = nil
    end
end

function EnableLock()
    LockedPlayer = GetClosestPlayer()
    if not LockedPlayer then return false end
    
    Locked = true
    if LockConnection then LockConnection:Disconnect() end
    
    -- Usa Heartbeat para ocorrer APÓS a física, garantindo zero delay no TSB
    LockConnection = RunService.Heartbeat:Connect(UpdateLock)
    return true
end

-- ==========================================
-- MENU MINIMALISTA
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TSBMiniLock"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui") or LocalPlayer.PlayerGui

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Parent = ScreenGui
ToggleBtn.Size = UDim2.new(0, 120, 0, 40)
ToggleBtn.Position = UDim2.new(0.5, -60, 0.1, 0) -- Topo centro
ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
ToggleBtn.Text = "LOCK: OFF"
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 14
ToggleBtn.Active = true
ToggleBtn.Draggable = true -- Arraste para onde quiser
ToggleBtn.BorderSizePixel = 2
ToggleBtn.BorderColor3 = Color3.fromRGB(0, 0, 0)

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = ToggleBtn

ToggleBtn.MouseButton1Click:Connect(function()
    if not Locked then
        if EnableLock() then
            ToggleBtn.Text = "LOCK: ON ("..LockedPlayer.Name..")"
            ToggleBtn.TextColor3 = Color3.fromRGB(50, 255, 50)
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 50, 20)
        else
            ToggleBtn.Text = "SEM ALVO"
            task.wait(0.5)
            ToggleBtn.Text = "LOCK: OFF"
        end
    else
        DisableLock()
        ToggleBtn.Text = "LOCK: OFF"
        ToggleBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    end
end)

-- Atalho Teclado (Opcional, tecla Q)
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Q then
        ToggleBtn.Active = false -- Simula o click
        -- Aciona a mesma lógica do botão
        for _, connection in pairs(getconnections(ToggleBtn.MouseButton1Click)) do
            connection:Fire()
        end
    end
end)
