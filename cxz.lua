-- CXZ Script (BETA) - UI nativa + funções + botão CXZ para abrir/fechar
-- Feito para Delta Executor | by cxz

-- ======= UTIL =======
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

local function getHumanoid()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char:FindFirstChildOfClass("Humanoid"), char
end

local Humanoid, Character = getHumanoid()
LocalPlayer.CharacterAdded:Connect(function(c)
    Character = c
    Humanoid = c:WaitForChild("Humanoid")
end)

-- Estados
local State = {
    Fly = false,
    NoClip = false,
    InfiniteJump = false,
    ESP = false,
    ESPColor = Color3.fromRGB(255,0,255), -- Roxo
    KillAura = false,
    KillAuraRange = 15,
    AutoFarm = false,
    AntiAFK = false,
    Connections = {},
    FlyBodyVel = nil,
}

local function bind(name, conn)
    if State.Connections[name] then
        pcall(function() State.Connections[name]:Disconnect() end)
    end
    State.Connections[name] = conn
end

local function unbind(name)
    if State.Connections[name] then
        pcall(function() State.Connections[name]:Disconnect() end)
        State.Connections[name] = nil
    end
end

-- ======= FUNÇÕES =======

-- Anti-AFK
local function setAntiAFK(on)
    if on then
        bind("AntiAFK", LocalPlayer.Idled:Connect(function()
            local vu = game:GetService("VirtualUser")
            vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end))
    else
        unbind("AntiAFK")
    end
end

-- Fly
local function setFly(on)
    State.Fly = on
    if on then
        local hrp = Character and Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if State.FlyBodyVel then pcall(function() State.FlyBodyVel:Destroy() end) end

        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(1e5,1e5,1e5)
        bv.Velocity = Vector3.zero
        bv.Parent = hrp
        State.FlyBodyVel = bv

        bind("Fly", RunService.RenderStepped:Connect(function()
            if not State.Fly or not Humanoid or not Character or not hrp then return end
            bv.Velocity = Humanoid.MoveDirection * 100
        end))
    else
        unbind("Fly")
        if State.FlyBodyVel then pcall(function() State.FlyBodyVel:Destroy() end) State.FlyBodyVel = nil end
    end
end

-- NoClip
local function setNoClip(on)
    State.NoClip = on
    if on then
        bind("NoClip", RunService.Stepped:Connect(function()
            if not Character then return end
            for _,part in ipairs(Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end))
    else
        unbind("NoClip")
    end
end

-- Infinite Jump
local function setInfiniteJump(on)
    State.InfiniteJump = on
    if on then
        bind("InfJump", UserInputService.JumpRequest:Connect(function()
            if Humanoid then Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
        end))
    else
        unbind("InfJump")
    end
end

-- ESP
local function ensureHighlight(model, color)
    if not model or not model:IsA("Model") then return end
    local h = model:FindFirstChildOfClass("Highlight")
    if not h then
        h = Instance.new("Highlight")
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = model
    end
    h.FillColor = color
    h.OutlineColor = Color3.new(1,1,1)
    h.OutlineTransparency = 0
end

local function setESP(on)
    State.ESP = on
    if on then
        bind("ESP", RunService.RenderStepped:Connect(function()
            if not State.ESP then return end
            -- Players
            for _,plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    ensureHighlight(plr.Character, State.ESPColor)
                end
            end
            -- NPCs / Bosses
            for _,m in ipairs(workspace:GetDescendants()) do
                if m:IsA("Model") and m:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(m) then
                    ensureHighlight(m, State.ESPColor)
                end
            end
        end))
    else
        unbind("ESP")
        for _,m in ipairs(workspace:GetDescendants()) do
            if m:IsA("Model") then
                local h = m:FindFirstChildOfClass("Highlight")
                if h then pcall(function() h:Destroy() end) end
            end
        end
    end
end

-- Kill Aura
local function setKillAura(on)
    State.KillAura = on
    if on then
        bind("KillAura", RunService.Heartbeat:Connect(function()
            if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
            local hrp = Character.HumanoidRootPart
            for _,m in ipairs(workspace:GetDescendants()) do
                if m:IsA("Model") and m ~= Character then
                    local hum = m:FindFirstChildOfClass("Humanoid")
                    local root = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
                    if hum and root and (root.Position - hrp.Position).Magnitude <= State.KillAuraRange then
                        pcall(function() hum.Health = 0 end)
                    end
                end
            end
        end))
    else
        unbind("KillAura")
    end
end

-- AutoFarm (genérico)
local function setAutoFarm(on)
    State.AutoFarm = on
    if on then
        bind("AutoFarm", RunService.Heartbeat:Connect(function()
            if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
            local hrp = Character.HumanoidRootPart
            for _,m in ipairs(workspace:GetDescendants()) do
                if m:IsA("Model") and m:FindFirstChildOfClass("Humanoid") and m:FindFirstChild("HumanoidRootPart") and m ~= Character then
                    hrp.CFrame = m.HumanoidRootPart.CFrame * CFrame.new(0,3,0)
                    break
                end
            end
        end))
    else
        unbind("AutoFarm")
    end
end

-- ======= UI (Instance.new) =======

-- Paleta
local COLOR_BG = Color3.fromRGB(30,30,30)
local COLOR_PANEL = Color3.fromRGB(42,42,42)
local COLOR_TEXT = Color3.fromRGB(255,255,255)
local COLOR_ACC = Color3.fromRGB(0,255,255)

-- ScreenGui principal
local gui = Instance.new("ScreenGui")
gui.Name = "CXZ_SCRIPT_BETA"
gui.ResetOnSpawn = false
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- Main Frame (COMPACTO)
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 420, 0, 300)                 -- <= menor
main.Position = UDim2.new(0.5, -210, 0.5, -150)       -- centralizado
main.BackgroundColor3 = COLOR_BG
main.BorderSizePixel = 0
main.Parent = gui
main.Visible = false                                  -- começa escondido

-- UICorner
local corner = Instance.new("UICorner", main)
corner.CornerRadius = UDim.new(0, 12)

-- Top Bar (draggable)
local top = Instance.new("Frame")
top.Size = UDim2.new(1, 0, 0, 40)
top.BackgroundColor3 = COLOR_PANEL
top.BorderSizePixel = 0
top.Parent = main
Instance.new("UICorner", top).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -20, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.Text = "CXZ Script (BETA)"
title.TextColor3 = COLOR_TEXT
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Parent = top

-- Drag do painel
do
    local dragging, dragStart, startPos
    top.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)
    top.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Conteúdo
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 160, 1, -50)             -- reduzido pra caber
sidebar.Position = UDim2.new(0, 10, 0, 50)
sidebar.BackgroundColor3 = COLOR_PANEL
sidebar.BorderSizePixel = 0
sidebar.Parent = main
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 10)

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -190, 1, -50)            -- acompanha sidebar menor
content.Position = UDim2.new(0, 180, 0, 50)
content.BackgroundColor3 = COLOR_PANEL
content.BorderSizePixel = 0
content.Parent = main
Instance.new("UICorner", content).CornerRadius = UDim.new(0, 10)

-- Helpers UI
local function mkBtn(parent, text)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -20, 0, 32)                 -- altura menor
    b.Position = UDim2.new(0, 10, 0, 0)
    b.BackgroundColor3 = COLOR_BG
    b.Text = text
    b.TextColor3 = COLOR_TEXT
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 14
    b.AutoButtonColor = false
    b.Parent = parent
    local c = Instance.new("UICorner", b); c.CornerRadius = UDim.new(0,10)
    b.MouseEnter:Connect(function() b.BackgroundColor3 = COLOR_ACC end)
    b.MouseLeave:Connect(function() b.BackgroundColor3 = COLOR_BG end)
    return b
end

local function mkLabel(parent, text)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = COLOR_TEXT
    l.Font = Enum.Font.Gotham
    l.TextSize = 14
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Size = UDim2.new(1, -20, 0, 20)
    l.Position = UDim2.new(0, 10, 0, 0)
    l.Parent = parent
    return l
end

local function mkToggle(parent, text, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, 34)
    container.Position = UDim2.new(0, 10, 0, 0)
    container.BackgroundTransparency = 1
    container.Parent = parent

    local lbl = mkLabel(container, text)
    lbl.Size = UDim2.new(1, -60, 1, 0)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 50, 0, 22)
    btn.Position = UDim2.new(1, -60, 0.5, -11)
    btn.BackgroundColor3 = default and COLOR_ACC or COLOR_BG
    btn.Text = default and "ON" or "OFF"
    btn.TextColor3 = COLOR_TEXT
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 12
    btn.Parent = container
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and COLOR_ACC or COLOR_BG
        btn.Text = state and "ON" or "OFF"
        callback(state)
    end)

    task.defer(function() callback(default) end)
    return container
end

local function mkInput(parent, label, placeholder, onApply)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, 60)
    container.Position = UDim2.new(0, 10, 0, 0)
    container.BackgroundTransparency = 1
    container.Parent = parent

    local lbl = mkLabel(container, label)
    lbl.Position = UDim2.new(0,0,0,0)

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -110, 0, 26)
    box.Position = UDim2.new(0, 0, 0, 26)
    box.BackgroundColor3 = COLOR_BG
    box.Text = ""
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = Color3.fromRGB(180,180,180)
    box.TextColor3 = COLOR_TEXT
    box.Font = Enum.Font.Gotham
    box.TextSize = 14
    box.ClearTextOnFocus = false
    box.Parent = container
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,8)

    local apply = Instance.new("TextButton")
    apply.Size = UDim2.new(0, 100, 0, 26)
    apply.Position = UDim2.new(1, -105, 0, 26)
    apply.BackgroundColor3 = COLOR_ACC
    apply.Text = "Aplicar"
    apply.TextColor3 = COLOR_TEXT
    apply.Font = Enum.Font.GothamSemibold
    apply.TextSize = 14
    apply.Parent = container
    Instance.new("UICorner", apply).CornerRadius = UDim.new(0,8)

    apply.MouseButton1Click:Connect(function()
        onApply(box.Text)
    end)

    return container
end

local function mkDropdown(parent, label, options, defaultLabel, onSelect)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, 60)
    container.Position = UDim2.new(0, 10, 0, 0)
    container.BackgroundTransparency = 1
    container.Parent = parent

    mkLabel(container, label)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 26)
    btn.Position = UDim2.new(0, 0, 0, 26)
    btn.BackgroundColor3 = COLOR_BG
    btn.Text = defaultLabel
    btn.TextColor3 = COLOR_TEXT
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.Parent = container
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)

    local listFrame = Instance.new("Frame")
    listFrame.Visible = false
    listFrame.BackgroundColor3 = COLOR_BG
    listFrame.BorderSizePixel = 0
    listFrame.Size = UDim2.new(1, 0, 0, (#options)*26+8)
    listFrame.Position = UDim2.new(0, 0, 0, 58)
    listFrame.Parent = container
    Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0,8)

    local layout = Instance.new("UIListLayout", listFrame)
    layout.Padding = UDim.new(0,4)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    listFrame.ClipsDescendants = true
    local pad = Instance.new("UIPadding", listFrame)
    pad.PaddingTop = UDim.new(0,4)
    pad.PaddingBottom = UDim.new(0,4)

    for _,opt in ipairs(options) do
        local o = Instance.new("TextButton")
        o.Size = UDim2.new(1, -8, 0, 22)
        o.BackgroundColor3 = COLOR_PANEL
        o.Text = opt
        o.TextColor3 = COLOR_TEXT
        o.Font = Enum.Font.Gotham
        o.TextSize = 14
        o.Parent = listFrame
        Instance.new("UICorner", o).CornerRadius = UDim.new(0,6)
        o.MouseButton1Click:Connect(function()
            btn.Text = opt
            listFrame.Visible = false
            onSelect(opt)
        end)
    end

    btn.MouseButton1Click:Connect(function()
        listFrame.Visible = not listFrame.Visible
    end)

    return container
end

-- Páginas
local pages = {}
local function newPage(name)
    local f = Instance.new("ScrollingFrame")
    f.Size = UDim2.new(1, -20, 1, -20)
    f.Position = UDim2.new(0, 10, 0, 10)
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.ScrollBarThickness = 4
    f.Visible = false
    f.Parent = content
    local list = Instance.new("UIListLayout", f)
    list.Padding = UDim.new(0,10)
    list.FillDirection = Enum.FillDirection.Vertical
    list.HorizontalAlignment = Enum.HorizontalAlignment.Left
    list.VerticalAlignment = Enum.VerticalAlignment.Top
    list.SortOrder = Enum.SortOrder.LayoutOrder
    pages[name] = f
    return f
end

local function showPage(name)
    for n,frame in pairs(pages) do
        frame.Visible = (n == name)
    end
end

-- Sidebar Buttons
local categories = {"Player","Visual","Farm","Extra","Config"}
local yOff = 10
local sideButtons = {}
for _,cat in ipairs(categories) do
    local b = mkBtn(sidebar, cat)
    b.Position = UDim2.new(0, 10, 0, yOff)
    yOff = yOff + 38
    sideButtons[cat] = b
end

-- ======= Construir páginas =======

-- PLAYER
local pgPlayer = newPage("Player")

mkInput(pgPlayer, "WalkSpeed (16-200)", "ex: 80", function(txt)
    local v = tonumber(txt)
    if v and Humanoid then Humanoid.WalkSpeed = math.clamp(v, 16, 200) end
end)

mkInput(pgPlayer, "JumpPower (50-500)", "ex: 120", function(txt)
    local v = tonumber(txt)
    if v and Humanoid then Humanoid.JumpPower = math.clamp(v, 50, 500) end
end)

mkToggle(pgPlayer, "Fly [F]", false, function(on) setFly(on) end)
mkToggle(pgPlayer, "NoClip [N]", false, function(on) setNoClip(on) end)
mkToggle(pgPlayer, "Infinite Jump [J]", false, function(on) setInfiniteJump(on) end)

-- VISUAL
local pgVisual = newPage("Visual")

mkDropdown(pgVisual, "Cor do ESP", {"Roxo","Azul","Verde"}, "Roxo", function(opt)
    local map = {
        ["Roxo"]=Color3.fromRGB(255,0,255),
        ["Azul"]=Color3.fromRGB(0,0,255),
        ["Verde"]=Color3.fromRGB(0,255,0),
    }
    State.ESPColor = map[opt] or Color3.fromRGB(255,0,255)
end)

mkToggle(pgVisual, "ESP Players/NPCs [E]", false, function(on) setESP(on) end)

local btnFog = mkBtn(pgVisual, "Remover Neblina / Aumentar Brilho")
btnFog.MouseButton1Click:Connect(function()
    Lighting.FogEnd = 1e10
    Lighting.Brightness = 2
end)

-- FARM
local pgFarm = newPage("Farm")

mkInput(pgFarm, "Kill Aura Alcance", "ex: 15", function(txt)
    local v = tonumber(txt)
    if v then State.KillAuraRange = math.clamp(v, 5, 100) end
end)
mkToggle(pgFarm, "Kill Aura [K]", false, function(on) setKillAura(on) end)
mkToggle(pgFarm, "Auto Farm (genérico)", false, function(on) setAutoFarm(on) end)

-- EXTRA
local pgExtra = newPage("Extra")

mkToggle(pgExtra, "Anti-AFK", false, function(on) setAntiAFK(on) end)

local btnDia = mkBtn(pgExtra, "Forçar Dia")
btnDia.MouseButton1Click:Connect(function() Lighting.TimeOfDay = "14:00:00" end)

local btnNoite = mkBtn(pgExtra, "Forçar Noite")
btnNoite.MouseButton1Click:Connect(function() Lighting.TimeOfDay = "00:00:00" end)

-- CONFIG
local pgConfig = newPage("Config")

local btnReset = mkBtn(pgConfig, "Fechar Hub (Reset UI)")
btnReset.MouseButton1Click:Connect(function()
    for k,_ in pairs(State.Connections) do unbind(k) end
    if State.FlyBodyVel then pcall(function() State.FlyBodyVel:Destroy() end) end
    if gui then pcall(function() gui:Destroy() end) end
    local tg = game:GetService("CoreGui"):FindFirstChild("CXZ_TOGGLE_GUI") or (LocalPlayer.PlayerGui and LocalPlayer.PlayerGui:FindFirstChild("CXZ_TOGGLE_GUI"))
    if tg then pcall(function() tg:Destroy() end) end
end)

-- Mostrar Player por padrão
showPage("Player")

-- Sidebar clicks
for cat,btn in pairs(sideButtons) do
    btn.MouseButton1Click:Connect(function() showPage(cat) end)
end

-- ======= KEYBINDS =======
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.F then
        State.Fly = not State.Fly
        setFly(State.Fly)
    elseif input.KeyCode == Enum.KeyCode.N then
        State.NoClip = not State.NoClip
        setNoClip(State.NoClip)
    elseif input.KeyCode == Enum.KeyCode.J then
        State.InfiniteJump = not State.InfiniteJump
        setInfiniteJump(State.InfiniteJump)
    elseif input.KeyCode == Enum.KeyCode.K then
        State.KillAura = not State.KillAura
        setKillAura(State.KillAura)
    elseif input.KeyCode == Enum.KeyCode.E then
        State.ESP = not State.ESP
        setESP(State.ESP)
    end
end)

-- ======= BOTÃO BOLINHA "CXZ" PARA ABRIR/FECHAR =======
local toggleGui = Instance.new("ScreenGui")
toggleGui.Name = "CXZ_TOGGLE_GUI"
toggleGui.ResetOnSpawn = false
pcall(function() toggleGui.Parent = game:GetService("CoreGui") end)
if not toggleGui.Parent then toggleGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local ball = Instance.new("TextButton")
ball.Name = "CXZ_Button"
ball.Size = UDim2.new(0, 56, 0, 56)
ball.Position = UDim2.new(1, -70, 0, 12) -- canto sup. direito
ball.BackgroundColor3 = Color3.fromRGB(35,35,35)
ball.Text = "CXZ"
ball.TextColor3 = Color3.fromRGB(255,255,255)
ball.Font = Enum.Font.GothamBold
ball.TextSize = 16
ball.AutoButtonColor = false
ball.Parent = toggleGui
local ballCorner = Instance.new("UICorner", ball); ballCorner.CornerRadius = UDim.new(1,0)
ball.ZIndex = 9999

-- hover
ball.MouseEnter:Connect(function() ball.BackgroundColor3 = Color3.fromRGB(0,255,255) end)
ball.MouseLeave:Connect(function() ball.BackgroundColor3 = Color3.fromRGB(35,35,35) end)

-- toggle visibilidade
ball.MouseButton1Click:Connect(function()
    main.Visible = not main.Visible
end)

-- (Opcional) arrastar bolinha
do
    local dragging, dragStart, startPos
    ball.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = ball.Position
        end
    end)
    ball.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            ball.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- ======= FIM =======
