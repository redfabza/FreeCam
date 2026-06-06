-- FreeCamPro v3 by WackShop
local Players      = game:GetService("Players")
local RS           = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local TS           = game:GetService("TweenService")
local SG           = game:GetService("StarterGui")

local player    = Players.LocalPlayer
local camera    = workspace.CurrentCamera
local gui       = player:WaitForChild("PlayerGui")

if gui:FindFirstChild("FreeCamPro") then gui.FreeCamPro:Destroy() end

-- ===== ค่าตั้งต้น =====
local camSpeed = 20
local sens     = 0.18
local smooth   = 8
local JR       = 55   -- joystick radius

-- ===== ตัวแปรระบบ =====
local enabled   = false
local camReady  = false
local panelOpen = true
local moveVec   = Vector2.zero

local tRotX, tRotY = 0, 0
local cRotX, cRotY = 0, 0
local tPos, cPos   = Vector3.zero, Vector3.zero

local origSpeed, origJump
local lockedCF, lockConn

local joyActive, joyTouchId, joyCenter = false, nil, Vector2.zero
local rotActive, rotTouchId            = false, nil
local jBase, jKnob

-- ===== ล็อกตัวละคร =====
local function lockChar(on)
    local ch  = player.Character; if not ch then return end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    if on then
        if hum then
            origSpeed = hum.WalkSpeed; origJump = hum.JumpPower
            hum.WalkSpeed = 0; hum.JumpPower = 0; hum.PlatformStand = true
        end
        if hrp then
            hrp.Anchored = true; lockedCF = hrp.CFrame
            lockConn = RS.Heartbeat:Connect(function()
                if hrp and lockedCF then
                    hrp.CFrame = lockedCF
                    hrp.AssemblyLinearVelocity  = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end
            end)
        end
    else
        if lockConn then lockConn:Disconnect() end
        if hrp then hrp.Anchored = false end
        if hum then
            hum.WalkSpeed = origSpeed or 16
            hum.JumpPower = origJump  or 50
            hum.PlatformStand = false
        end
    end
end

-- ===== Camera Loop =====
RS.RenderStepped:Connect(function(dt)
    if not enabled or not camReady then return end
    local a = 1 - math.exp(-smooth * dt)
    if moveVec.Magnitude > 0.05 then
        local d = (camera.CFrame.LookVector * -moveVec.Y + camera.CFrame.RightVector * moveVec.X)
        if d.Magnitude > 0 then tPos = tPos + d.Unit * camSpeed * dt end
    end
    cPos  = cPos:Lerp(tPos, a)
    cRotX = cRotX + (tRotX - cRotX) * a
    cRotY = cRotY + (tRotY - cRotY) * a
    camera.CFrame =
        CFrame.new(cPos)
        * CFrame.Angles(0, math.rad(cRotY), 0)
        * CFrame.Angles(math.rad(cRotX), 0, 0)
end)

-- =============================================
-- ===== GUI =====
-- =============================================
local sg = Instance.new("ScreenGui")
sg.Name           = "FreeCamPro"
sg.IgnoreGuiInset = true
sg.ResetOnSpawn   = false
sg.Parent         = gui

-- ===== Panel หลัก =====
local panel = Instance.new("Frame")
panel.Name              = "Panel"
panel.Size              = UDim2.fromOffset(230, 320)
panel.Position          = UDim2.new(1, -250, 0.5, -160)
panel.BackgroundColor3  = Color3.fromRGB(14, 18, 30)
panel.BorderSizePixel   = 0
panel.ClipsDescendants  = false
panel.Parent            = sg
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)
local ps = Instance.new("UIStroke", panel)
ps.Color = Color3.fromRGB(40, 55, 90); ps.Thickness = 1.5

-- ===== Title Bar =====
local title = Instance.new("Frame")
title.Name             = "Title"
title.Size             = UDim2.new(1, 0, 0, 48)
title.BackgroundColor3 = Color3.fromRGB(10, 13, 22)
title.BorderSizePixel  = 0
title.Parent           = panel
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 14)

-- icon
local iconF = Instance.new("Frame")
iconF.Size             = UDim2.fromOffset(32, 32)
iconF.Position         = UDim2.new(0, 10, 0.5, -16)
iconF.BackgroundColor3 = Color3.fromRGB(26, 111, 255)
iconF.BorderSizePixel  = 0
iconF.Parent           = title
Instance.new("UICorner", iconF).CornerRadius = UDim.new(0, 8)
local iconL = Instance.new("TextLabel")
iconL.Size                  = UDim2.new(1,0,1,0)
iconL.BackgroundTransparency = 1
iconL.Text                  = "🎥"
iconL.TextSize              = 16
iconL.Font                  = Enum.Font.GothamBold
iconL.Parent                = iconF

local tLbl = Instance.new("TextLabel")
tLbl.Size               = UDim2.new(1,-90,0,22)
tLbl.Position           = UDim2.new(0,50,0,6)
tLbl.BackgroundTransparency = 1
tLbl.Text               = "FreeCam Pro"
tLbl.TextColor3         = Color3.fromRGB(235,240,255)
tLbl.Font               = Enum.Font.GothamBold
tLbl.TextSize           = 14
tLbl.TextXAlignment     = Enum.TextXAlignment.Left
tLbl.Parent             = title

local sLbl = Instance.new("TextLabel")
sLbl.Size               = UDim2.new(1,-90,0,14)
sLbl.Position           = UDim2.new(0,50,0,28)
sLbl.BackgroundTransparency = 1
sLbl.Text               = "v3.0 · WackShop"
sLbl.TextColor3         = Color3.fromRGB(70, 88, 130)
sLbl.Font               = Enum.Font.Gotham
sLbl.TextSize           = 10
sLbl.TextXAlignment     = Enum.TextXAlignment.Left
sLbl.Parent             = title

-- ปุ่มปิด
local closeBtn = Instance.new("TextButton")
closeBtn.Size             = UDim2.fromOffset(28,28)
closeBtn.Position         = UDim2.new(1,-36,0.5,-14)
closeBtn.BackgroundColor3 = Color3.fromRGB(50,20,20)
closeBtn.Text             = "✕"
closeBtn.TextColor3       = Color3.fromRGB(220,80,80)
closeBtn.Font             = Enum.Font.GothamBold
closeBtn.TextSize         = 13
closeBtn.BorderSizePixel  = 0
closeBtn.Parent           = title
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,7)
local cs = Instance.new("UIStroke", closeBtn)
cs.Color = Color3.fromRGB(180,50,50); cs.Thickness = 1

closeBtn.InputEnded:Connect(function(i)
    if i.UserInputType ~= Enum.UserInputType.MouseButton1
    and i.UserInputType ~= Enum.UserInputType.Touch then return end
    if enabled then
        enabled = false; camReady = false; lockChar(false)
        camera.CameraType = Enum.CameraType.Custom
        local ch = player.Character
        if ch then camera.CameraSubject = ch:FindFirstChildOfClass("Humanoid") or ch end
        camera.FieldOfView = 70
        pcall(function() SG:SetCoreGuiEnabled(Enum.CoreGuiType.TouchGui, true) end)
    end
    sg:Destroy()
end)

-- drag panel
local drag = {}
title.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        drag.on = true; drag.s = i.Position; drag.o = panel.Position
    end
end)
UIS.InputChanged:Connect(function(i)
    if drag.on and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - drag.s
        panel.Position = UDim2.new(drag.o.X.Scale, drag.o.X.Offset+d.X, drag.o.Y.Scale, drag.o.Y.Offset+d.Y)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        drag.on = false
    end
end)

-- ===== เส้นแบ่ง =====
local function makeLine(y)
    local l = Instance.new("Frame")
    l.Size = UDim2.new(1,-20,0,1)
    l.Position = UDim2.new(0,10,0,y)
    l.BackgroundColor3 = Color3.fromRGB(35,48,75)
    l.BorderSizePixel = 0
    l.Parent = panel
end
makeLine(52)

-- ===== Toggle helper =====
local BLUE = Color3.fromRGB(26,111,255)

local function makeToggle(label, desc, y, onFn, offFn)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,-16,0,52)
    row.Position = UDim2.new(0,8,0,y)
    row.BackgroundColor3 = Color3.fromRGB(20,26,44)
    row.BorderSizePixel = 0
    row.Parent = panel
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,10)
    local rs = Instance.new("UIStroke", row)
    rs.Color = BLUE; rs.Thickness = 1; rs.Transparency = 0.7

    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(1,-70,0,22)
    lb.Position = UDim2.new(0,12,0,7)
    lb.BackgroundTransparency = 1
    lb.Text = label
    lb.TextColor3 = Color3.fromRGB(215,220,235)
    lb.Font = Enum.Font.GothamBold
    lb.TextSize = 13
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.Parent = row

    local db = Instance.new("TextLabel")
    db.Size = UDim2.new(1,-70,0,16)
    db.Position = UDim2.new(0,12,0,29)
    db.BackgroundTransparency = 1
    db.Text = desc
    db.TextColor3 = Color3.fromRGB(70,88,130)
    db.Font = Enum.Font.Gotham
    db.TextSize = 11
    db.TextXAlignment = Enum.TextXAlignment.Left
    db.Parent = row

    local swBG = Instance.new("Frame")
    swBG.Size = UDim2.fromOffset(46,24)
    swBG.Position = UDim2.new(1,-56,0.5,-12)
    swBG.BackgroundColor3 = Color3.fromRGB(30,38,60)
    swBG.BorderSizePixel = 0
    swBG.Parent = row
    Instance.new("UICorner", swBG).CornerRadius = UDim.new(1,0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(18,18)
    knob.Position = UDim2.new(0,3,0.5,-9)
    knob.BackgroundColor3 = Color3.fromRGB(80,95,130)
    knob.BorderSizePixel = 0
    knob.Parent = swBG
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1,0,1,0)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.Parent = row

    local state = false
    local function set(s)
        state = s
        TS:Create(swBG, TweenInfo.new(0.2), {BackgroundColor3 = s and BLUE or Color3.fromRGB(30,38,60)}):Play()
        TS:Create(knob, TweenInfo.new(0.2), {
            Position = s and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9),
            BackgroundColor3 = s and Color3.new(1,1,1) or Color3.fromRGB(80,95,130)
        }):Play()
        rs.Transparency = s and 0.2 or 0.7
        lb.TextColor3 = s and BLUE or Color3.fromRGB(215,220,235)
        db.Text = s and "● กำลังทำงาน" or desc
        db.TextColor3 = s and Color3.fromRGB(100,140,255) or Color3.fromRGB(70,88,130)
        if s then onFn() else offFn() end
    end

    hit.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            set(not state)
        end
    end)
end

-- ===== Slider helper =====
local function makeSlider(label, y, val, minV, maxV, step, color, onChange)
    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(0,120,0,16)
    lb.Position = UDim2.new(0,14,0,y)
    lb.BackgroundTransparency = 1
    lb.Text = label
    lb.TextColor3 = Color3.fromRGB(140,155,190)
    lb.Font = Enum.Font.Gotham
    lb.TextSize = 11
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.Parent = panel

    local badge = Instance.new("TextLabel")
    badge.Size = UDim2.fromOffset(50,16)
    badge.Position = UDim2.new(1,-62,0,y)
    badge.BackgroundColor3 = Color3.fromRGB(20,26,44)
    badge.TextColor3 = color
    badge.Font = Enum.Font.GothamBold
    badge.TextSize = 11
    badge.BorderSizePixel = 0
    badge.Parent = panel
    Instance.new("UICorner", badge).CornerRadius = UDim.new(0,5)

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1,-28,0,6)
    track.Position = UDim2.new(0,14,0,y+20)
    track.BackgroundColor3 = Color3.fromRGB(30,38,60)
    track.BorderSizePixel = 0
    track.Parent = panel
    Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = color
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)

    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.fromOffset(16,16)
    thumb.AnchorPoint = Vector2.new(0.5,0.5)
    thumb.BackgroundColor3 = color
    thumb.BorderSizePixel = 0
    thumb.Parent = track
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1,0)
    local ts2 = Instance.new("UIStroke", thumb)
    ts2.Color = Color3.fromRGB(10,14,24); ts2.Thickness = 2.5

    local hitbox = Instance.new("TextButton")
    hitbox.Size = UDim2.new(1,0,0,30)
    hitbox.Position = UDim2.new(0,0,0.5,-15)
    hitbox.BackgroundTransparency = 1
    hitbox.Text = ""
    hitbox.Parent = track

    local cur = val
    local function refresh()
        local p = math.clamp((cur-minV)/(maxV-minV),0,1)
        fill.Size = UDim2.new(p,0,1,0)
        thumb.Position = UDim2.new(p,0,0.5,0)
        badge.Text = step<1 and string.format("%.2f",cur) or tostring(cur)
        onChange(cur)
    end
    refresh()

    local sliding = false
    local function fromInput(i)
        local p = math.clamp((i.Position.X - track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        local raw = minV+(maxV-minV)*p
        local n = math.floor(((raw-minV)/step)+0.5)
        cur = math.clamp(math.floor((minV+n*step)*1000+0.5)/1000, minV, maxV)
        refresh()
    end

    hitbox.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            sliding = true; fromInput(i)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then fromInput(i) end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then sliding = false end
    end)
end

-- ===== วาง Toggle และ Slider =====
makeToggle("🎥  Free Camera", "เปิดกล้องอิสระ", 58,
    function()
        enabled = true; lockChar(true); camReady = false
        pcall(function() SG:SetCoreGuiEnabled(Enum.CoreGuiType.TouchGui, false) end)
        local cf = camera.CFrame
        tPos = cf.Position; cPos = cf.Position
        local rx,ry,_ = cf:ToOrientation()
        tRotX = math.deg(rx); cRotX = math.deg(rx)
        tRotY = math.deg(ry); cRotY = math.deg(ry)
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = cf
        camReady = true
        if jBase then jBase.Visible = false end
    end,
    function()
        enabled = false; camReady = false; lockChar(false)
        pcall(function() SG:SetCoreGuiEnabled(Enum.CoreGuiType.TouchGui, true) end)
        camera.CameraType = Enum.CameraType.Custom
        local ch = player.Character
        if ch then camera.CameraSubject = ch:FindFirstChildOfClass("Humanoid") or ch end
        camera.FieldOfView = 70
        moveVec = Vector2.zero
        if jBase then jBase.Visible = false end
    end
)

local sep1 = Instance.new("TextLabel")
sep1.Size = UDim2.new(1,-16,0,14)
sep1.Position = UDim2.new(0,12,0,118)
sep1.BackgroundTransparency = 1
sep1.Text = "⚙  SETTINGS"
sep1.TextColor3 = Color3.fromRGB(60,80,120)
sep1.Font = Enum.Font.GothamBold
sep1.TextSize = 10
sep1.TextXAlignment = Enum.TextXAlignment.Left
sep1.Parent = panel

makeLine(116)

makeSlider("⚡ SPEED",       134, camSpeed, 2,    60,  2,    Color3.fromRGB(0,210,255),  function(v) camSpeed = v end)
makeSlider("🎯 SENSITIVITY", 168, sens,     0.02, 0.5, 0.02, Color3.fromRGB(255,165,0),  function(v) sens     = v end)
makeSlider("〰 SMOOTH",      202, smooth,   1,    20,  1,    Color3.fromRGB(40,210,100), function(v) smooth   = v end)

makeLine(240)

makeToggle("🔭  FOV Override", "ปรับ Field of View", 246,
    function()
        -- เพิ่ม FOV slider แบบ inline
        local fovSlider = sg:FindFirstChild("FOVSlider")
        if not fovSlider then
            local fs = Instance.new("Frame")
            fs.Name = "FOVSlider"
            fs.Size = UDim2.new(1,-16,0,40)
            fs.Position = UDim2.new(0,8,0,302)
            fs.BackgroundColor3 = Color3.fromRGB(20,26,44)
            fs.BorderSizePixel = 0
            fs.Parent = panel
            Instance.new("UICorner", fs).CornerRadius = UDim.new(0,10)

            local fl = Instance.new("TextLabel")
            fl.Size = UDim2.new(0,80,0,16)
            fl.Position = UDim2.new(0,10,0,5)
            fl.BackgroundTransparency = 1
            fl.Text = "FOV"
            fl.TextColor3 = Color3.fromRGB(168,85,247)
            fl.Font = Enum.Font.GothamBold
            fl.TextSize = 11
            fl.TextXAlignment = Enum.TextXAlignment.Left
            fl.Parent = fs

            local fb = Instance.new("TextLabel")
            fb.Size = UDim2.fromOffset(50,16)
            fb.Position = UDim2.new(1,-58,0,5)
            fb.BackgroundColor3 = Color3.fromRGB(14,18,30)
            fb.TextColor3 = Color3.fromRGB(168,85,247)
            fb.Font = Enum.Font.GothamBold
            fb.TextSize = 11
            fb.BorderSizePixel = 0
            fb.Parent = fs
            Instance.new("UICorner", fb).CornerRadius = UDim.new(0,5)

            local ftrack = Instance.new("Frame")
            ftrack.Size = UDim2.new(1,-20,0,6)
            ftrack.Position = UDim2.new(0,10,0,28)
            ftrack.BackgroundColor3 = Color3.fromRGB(30,38,60)
            ftrack.BorderSizePixel = 0
            ftrack.Parent = fs
            Instance.new("UICorner", ftrack).CornerRadius = UDim.new(1,0)

            local ffill = Instance.new("Frame")
            ffill.BackgroundColor3 = Color3.fromRGB(168,85,247)
            ffill.BorderSizePixel = 0
            ffill.Parent = ftrack
            Instance.new("UICorner", ffill).CornerRadius = UDim.new(1,0)

            local fthumb = Instance.new("Frame")
            fthumb.Size = UDim2.fromOffset(16,16)
            fthumb.AnchorPoint = Vector2.new(0.5,0.5)
            fthumb.BackgroundColor3 = Color3.fromRGB(168,85,247)
            fthumb.BorderSizePixel = 0
            fthumb.Parent = ftrack
            Instance.new("UICorner", fthumb).CornerRadius = UDim.new(1,0)
            local fts = Instance.new("UIStroke", fthumb)
            fts.Color = Color3.fromRGB(10,14,24); fts.Thickness = 2.5

            local fhit = Instance.new("TextButton")
            fhit.Size = UDim2.new(1,0,0,30)
            fhit.Position = UDim2.new(0,0,0.5,-15)
            fhit.BackgroundTransparency = 1
            fhit.Text = ""
            fhit.Parent = ftrack

            local fovVal = camera.FieldOfView
            local function fRefresh()
                local p = math.clamp((fovVal-10)/(120-10),0,1)
                ffill.Size = UDim2.new(p,0,1,0)
                fthumb.Position = UDim2.new(p,0,0.5,0)
                fb.Text = tostring(math.floor(fovVal+0.5)).."°"
                if enabled then camera.FieldOfView = fovVal end
            end
            fRefresh()

            local fsliding = false
            local function fFromInput(i)
                local p = math.clamp((i.Position.X-ftrack.AbsolutePosition.X)/ftrack.AbsoluteSize.X,0,1)
                fovVal = math.clamp(10+(120-10)*p, 10, 120)
                fRefresh()
            end
            fhit.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then
                    fsliding = true; fFromInput(i)
                end
            end)
            UIS.InputChanged:Connect(function(i)
                if fsliding and (i.UserInputType == Enum.UserInputType.MouseMovement
                or i.UserInputType == Enum.UserInputType.Touch) then fFromInput(i) end
            end)
            UIS.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then fsliding = false end
            end)

            panel.Size = UDim2.fromOffset(230, 360)
        end
    end,
    function()
        local fs = sg:FindFirstChild("FOVSlider") or panel:FindFirstChild("FOVSlider")
        if fs then
            fs:Destroy()
            panel.Size = UDim2.fromOffset(230, 320)
        end
        if enabled then camera.FieldOfView = 70 end
    end
)

-- ===== ปุ่ม W =====
local wBtn = Instance.new("TextButton")
wBtn.Name = "WBtn"
wBtn.Size = UDim2.fromOffset(42,42)
wBtn.Position = UDim2.new(0,24,0.5,-21)
wBtn.BackgroundColor3 = Color3.fromRGB(0,0,0)
wBtn.BackgroundTransparency = 0
wBtn.Text = ""
wBtn.BorderSizePixel = 0
wBtn.AutoButtonColor = false
wBtn.Parent = sg
Instance.new("UICorner", wBtn).CornerRadius = UDim.new(1,0)

local wLbl = Instance.new("TextLabel")
wLbl.Size = UDim2.new(1,0,1,0)
wLbl.BackgroundTransparency = 1
wLbl.Text = "W"
wLbl.TextColor3 = Color3.fromRGB(0,195,255)
wLbl.Font = Enum.Font.GothamBlack
wLbl.TextSize = 18
wLbl.Parent = wBtn
local wsk = Instance.new("UIStroke", wLbl)
wsk.Color = Color3.fromRGB(0,195,255)
wsk.Thickness = 1.5
wsk.ApplyStrokeMode = Enum.ApplyStrokeMode.Content

local fdrag = {}
wBtn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then
        fdrag.on = true; fdrag.s = i.Position; fdrag.o = wBtn.Position; fdrag.moved = false
    end
end)
UIS.InputChanged:Connect(function(i)
    if fdrag.on and (i.UserInputType == Enum.UserInputType.MouseMovement
    or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - fdrag.s
        if d.Magnitude > 6 then fdrag.moved = true end
        wBtn.Position = UDim2.new(fdrag.o.X.Scale, fdrag.o.X.Offset+d.X,
                                   fdrag.o.Y.Scale, fdrag.o.Y.Offset+d.Y)
    end
end)
wBtn.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then
        if not fdrag.moved then
            panelOpen = not panelOpen
            panel.Visible = panelOpen
        end
        fdrag.on = false; fdrag.moved = false
    end
end)

-- ===== Joystick =====
local JD = JR*2
jBase = Instance.new("Frame")
jBase.Size = UDim2.fromOffset(JD+20,JD+20)
jBase.BackgroundColor3 = Color3.fromRGB(255,255,255)
jBase.BackgroundTransparency = 0.92
jBase.BorderSizePixel = 0
jBase.Visible = false
jBase.Parent = sg
Instance.new("UICorner",jBase).CornerRadius = UDim.new(0.5,0)

jKnob = Instance.new("Frame")
jKnob.Size = UDim2.fromOffset(JR,JR)
jKnob.Position = UDim2.new(0.5,-JR/2,0.5,-JR/2)
jKnob.BackgroundColor3 = Color3.fromRGB(26,111,255)
jKnob.BackgroundTransparency = 0.85
jKnob.BorderSizePixel = 0
jKnob.Parent = jBase
Instance.new("UICorner",jKnob).CornerRadius = UDim.new(0.5,0)

local function jStart(pos)
    joyActive = true
    jBase.Position = UDim2.new(0,pos.X-(JD+20)/2,0,pos.Y-(JD+20)/2)
    joyCenter = Vector2.new(pos.X,pos.Y)
    jBase.Visible = true
end
local function jMove(pos)
    if not joyActive then return end
    local d = Vector2.new(pos.X-joyCenter.X, pos.Y-joyCenter.Y)
    local dist = math.min(d.Magnitude, JR)
    local dir = d.Magnitude>0 and d.Unit or Vector2.zero
    jKnob.Position = UDim2.new(0.5,(dir*dist).X-JR/2,0.5,(dir*dist).Y-JR/2)
    moveVec = dir*(dist/JR)
end
local function jEnd()
    joyActive = false; joyTouchId = nil
    moveVec = Vector2.zero
    jKnob.Position = UDim2.new(0.5,-JR/2,0.5,-JR/2)
    jBase.Visible = false
end

UIS.TouchStarted:Connect(function(inp,gpe)
    if not enabled or gpe then return end
    if inp.Position.X < camera.ViewportSize.X/2 then
        if not joyActive then joyTouchId = inp; jStart(inp.Position) end
    else
        if not rotActive then rotActive = true; rotTouchId = inp end
    end
end)
UIS.TouchMoved:Connect(function(inp)
    if not enabled then return end
    if inp == joyTouchId then jMove(inp.Position)
    elseif inp == rotTouchId and rotActive then
        tRotY = tRotY - inp.Delta.X * sens
        tRotX = math.clamp(tRotX - inp.Delta.Y * sens, -85, 85)
    end
end)
UIS.TouchEnded:Connect(function(inp)
    if inp == joyTouchId then jEnd() end
    if inp == rotTouchId then rotActive = false; rotTouchId = nil end
end)

print("✅ FreeCamPro v3 โหลดสำเร็จ")
