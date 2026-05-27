
local Players      = game:GetService("Players")
local RS           = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player    = Players.LocalPlayer
local camera    = workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("FreeCamPro_GUI") then
    playerGui.FreeCamPro_GUI:Destroy()
end

-- =============================================
-- ===== ตั้งค่าหลัก =====
-- =============================================
local themeColor = Color3.fromRGB(26, 111, 255)
local camSpeed   = 20
local sens       = 0.18
local SMOOTH     = 8
local JOY_RADIUS = 55
local camFOV     = 70

local USE_ZOOM_BUTTONS = true
local zoomStep  = 4
local minFOV    = 10
local maxFOV    = 120

-- ===== ตัวแปรระบบ =====
local enabled     = false
local moveVec     = Vector2.zero
local isCollapsed = false
local panelOpen   = true

local targetRotX, targetRotY   = 0, 0
local currentRotX, currentRotY = 0, 0
local targetPos  = Vector3.zero
local currentPos = Vector3.zero
local camReady   = false

local origSpeed, origJump
local lockedPosition      = nil
local characterConnection = nil

local joyBase    = nil
local joyKnob    = nil
local joyActive  = false
local joyTouchId = nil
local joyCenter  = Vector2.zero
local rotating   = false
local rotTouchId = nil

local zoomInHeld  = false
local zoomOutHeld = false

-- =============================================
-- ===== ล็อก/ปลดตัวละคร =====
-- =============================================
local function lockCharacter(state)
    local character = player.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root     = character:FindFirstChild("HumanoidRootPart")
    if state then
        if humanoid then
            origSpeed = humanoid.WalkSpeed > 0 and humanoid.WalkSpeed or 16
            origJump  = humanoid.JumpPower  > 0 and humanoid.JumpPower  or 50
            humanoid.WalkSpeed     = 0
            humanoid.JumpPower     = 0
            humanoid.PlatformStand = true
        end
        if root then
            root.Anchored  = true
            lockedPosition = root.CFrame
            characterConnection = RS.Heartbeat:Connect(function()
                if root and lockedPosition then
                    root.CFrame                     = lockedPosition
                    root.AssemblyLinearVelocity  = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                end
            end)
        end
    else
        if characterConnection then characterConnection:Disconnect() end
        if root     then root.Anchored = false end
        if humanoid then
            humanoid.WalkSpeed     = origSpeed or 16
            humanoid.JumpPower     = origJump  or 50
            humanoid.PlatformStand = false
        end
    end
end

-- =============================================
-- ===== Smooth Camera Loop =====
-- =============================================
RS.RenderStepped:Connect(function(dt)
    if not enabled or not camReady then return end
    local alpha = 1 - math.exp(-SMOOTH * dt)

    if moveVec.Magnitude > 0.05 then
        local fwd   = camera.CFrame.LookVector  * -moveVec.Y
        local right = camera.CFrame.RightVector *  moveVec.X
        local dir   = fwd + right
        if dir.Magnitude > 0 then
            targetPos = targetPos + dir.Unit * camSpeed * dt
        end
    end

    if USE_ZOOM_BUTTONS then
        if zoomInHeld then
            camFOV = math.clamp(camFOV - (zoomStep * 15 * dt), minFOV, maxFOV)
        elseif zoomOutHeld then
            camFOV = math.clamp(camFOV + (zoomStep * 15 * dt), minFOV, maxFOV)
        end
    end

    currentPos  = currentPos:Lerp(targetPos, alpha)
    currentRotX = currentRotX + (targetRotX - currentRotX) * alpha
    currentRotY = currentRotY + (targetRotY - currentRotY) * alpha

    camera.CFrame =
        CFrame.new(currentPos)
        * CFrame.Angles(0, math.rad(currentRotY), 0)
        * CFrame.Angles(math.rad(currentRotX), 0, 0)

    camera.FieldOfView = camera.FieldOfView + (camFOV - camera.FieldOfView) * alpha
end)

-- =============================================
-- ===== GUI =====
-- =============================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "FreeCamPro_GUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn   = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent         = playerGui

pcall(function()
    game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.TouchGui, false)
end)

local FULL_H      = 252   -- เพิ่มพื้นที่รองรับแถว Smooth
local COLLAPSED_H = 44

-- =============================================
-- ===== หน้าต่างหลัก =====
-- =============================================
local Main = Instance.new("Frame", screenGui)
Main.Name             = "MainPanel"
Main.Size             = UDim2.fromOffset(220, FULL_H)
Main.AnchorPoint      = Vector2.new(1, 0.5)
Main.Position         = UDim2.new(1, -20, 0.5, 0)
Main.BackgroundColor3 = Color3.fromRGB(13, 17, 32)
Main.BorderSizePixel  = 0
Main.ZIndex           = 10
Main.ClipsDescendants = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)

local mainStroke = Instance.new("UIStroke", Main)
mainStroke.Thickness = 1.5
mainStroke.Color     = Color3.fromRGB(30, 42, 64)

Instance.new("UIGradient", Main).Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 18, 30)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(9,  10, 18))
})

-- ── แถบสีบนสุด ──
local topAccent = Instance.new("Frame", Main)
topAccent.Size             = UDim2.new(1, 0, 0, 2)
topAccent.Position         = UDim2.new(0, 0, 0, 0)
topAccent.BackgroundColor3 = themeColor
topAccent.BorderSizePixel  = 0
topAccent.ZIndex           = 11
Instance.new("UIGradient", topAccent).Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,0,0)),
    ColorSequenceKeypoint.new(0.5, themeColor),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,0,0))
})

-- ── Title Bar ──
local TitleBar = Instance.new("Frame", Main)
TitleBar.Size             = UDim2.new(1, 0, 0, 44)
TitleBar.Position         = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundColor3 = Color3.fromRGB(12, 14, 24)
TitleBar.BorderSizePixel  = 0
TitleBar.ZIndex           = 10
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 14)

-- ไอคอน 🎥
local iconBox = Instance.new("Frame", TitleBar)
iconBox.Size             = UDim2.fromOffset(30, 30)
iconBox.Position         = UDim2.new(0, 10, 0.5, -15)
iconBox.BackgroundColor3 = Color3.fromRGB(15, 61, 153)
iconBox.BorderSizePixel  = 0
iconBox.ZIndex           = 11
Instance.new("UICorner", iconBox).CornerRadius = UDim.new(0, 8)
Instance.new("UIGradient", iconBox).Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(15,61,153)),
    ColorSequenceKeypoint.new(1, themeColor)
})
local iconLbl = Instance.new("TextLabel", iconBox)
iconLbl.Size                  = UDim2.new(1, 0, 1, 0)
iconLbl.BackgroundTransparency = 1
iconLbl.Text                  = "🎥"
iconLbl.TextSize              = 14
iconLbl.Font                  = Enum.Font.GothamBold
iconLbl.ZIndex                = 12

local TitleLabel = Instance.new("TextLabel", TitleBar)
TitleLabel.Size               = UDim2.new(1, -120, 0, 20)
TitleLabel.Position           = UDim2.new(0, 48, 0, 6)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text               = "FreeCam Pro"
TitleLabel.TextColor3         = Color3.fromRGB(232, 237, 245)
TitleLabel.Font               = Enum.Font.GothamBold
TitleLabel.TextSize           = 13
TitleLabel.TextXAlignment     = Enum.TextXAlignment.Left
TitleLabel.ZIndex             = 11

local SubLabel = Instance.new("TextLabel", TitleBar)
SubLabel.Size               = UDim2.new(1, -120, 0, 14)
SubLabel.Position           = UDim2.new(0, 48, 0, 26)
SubLabel.BackgroundTransparency = 1
SubLabel.Text               = "v2.0 · WackShop"
SubLabel.TextColor3         = Color3.fromRGB(74, 90, 122)
SubLabel.Font               = Enum.Font.Gotham
SubLabel.TextSize           = 10
SubLabel.TextXAlignment     = Enum.TextXAlignment.Left
SubLabel.ZIndex             = 11

-- ปุ่ม ▼ Collapse
local collapseBtn = Instance.new("TextButton", TitleBar)
collapseBtn.Size             = UDim2.fromOffset(28, 28)
collapseBtn.Position         = UDim2.new(1, -34, 0.5, -14)
collapseBtn.BackgroundColor3 = Color3.fromRGB(17, 24, 39)
collapseBtn.Text             = "▼"
collapseBtn.TextColor3       = Color3.fromRGB(136, 153, 187)
collapseBtn.Font             = Enum.Font.GothamBold
collapseBtn.TextSize         = 12
collapseBtn.BorderSizePixel  = 0
collapseBtn.ZIndex           = 12
Instance.new("UICorner", collapseBtn).CornerRadius = UDim.new(0, 7)
Instance.new("UIStroke", collapseBtn).Color = Color3.fromRGB(30, 42, 64)

-- ── Drag ──
local drag = {}
TitleBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        drag.on = true; drag.s = inp.Position; drag.o = Main.Position
    end
end)
UIS.InputChanged:Connect(function(inp)
    if drag.on and (inp.UserInputType == Enum.UserInputType.MouseMovement
    or inp.UserInputType == Enum.UserInputType.Touch) then
        local d = inp.Position - drag.s
        Main.Position = UDim2.new(drag.o.X.Scale, drag.o.X.Offset + d.X,
                                  drag.o.Y.Scale, drag.o.Y.Offset + d.Y)
    end
end)
UIS.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then drag.on = false end
end)

-- ── Collapse ──
collapseBtn.MouseButton1Click:Connect(function()
    isCollapsed = not isCollapsed
    collapseBtn.Text = isCollapsed and "▲" or "▼"
    TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
        Size = UDim2.fromOffset(220, isCollapsed and COLLAPSED_H or FULL_H)
    }):Play()
end)

-- =============================================
-- ===== ปุ่ม W (แสดงตลอดเวลา) =====
-- =============================================
local FloatW = Instance.new("TextButton", screenGui)
FloatW.Name             = "FloatBtn_W"
FloatW.Size             = UDim2.fromOffset(44, 44)
FloatW.Position         = UDim2.new(1, -70, 0.5, 0)
FloatW.BackgroundColor3 = Color3.fromRGB(13, 17, 32)
FloatW.Text             = "W"
FloatW.TextColor3       = themeColor
FloatW.Font             = Enum.Font.GothamBold
FloatW.TextSize         = 18
FloatW.AutoButtonColor  = false
FloatW.BorderSizePixel  = 0
FloatW.ZIndex           = 20
FloatW.Visible          = true
Instance.new("UICorner", FloatW).CornerRadius = UDim.new(1, 0)
local FloatWStroke = Instance.new("UIStroke", FloatW)
FloatWStroke.Thickness = 1.5
FloatWStroke.Color     = themeColor

-- ── Drag ปุ่ม W ──
local fDrag = {}
FloatW.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        fDrag.on = true; fDrag.s = inp.Position; fDrag.o = FloatW.Position
        fDrag.moved = false
    end
end)
UIS.InputChanged:Connect(function(inp)
    if fDrag.on and (inp.UserInputType == Enum.UserInputType.MouseMovement
    or inp.UserInputType == Enum.UserInputType.Touch) then
        local d = inp.Position - fDrag.s
        if d.Magnitude > 4 then fDrag.moved = true end
        FloatW.Position = UDim2.new(fDrag.o.X.Scale, fDrag.o.X.Offset + d.X,
                                    fDrag.o.Y.Scale, fDrag.o.Y.Offset + d.Y)
    end
end)
UIS.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        fDrag.on = false
    end
end)

-- กด W → toggle panel เปิด/ปิด
FloatW.MouseButton1Click:Connect(function()
    if fDrag.moved then fDrag.moved = false return end
    panelOpen = not panelOpen

    if panelOpen then
        -- เปิด panel
        Main.Visible = true
        Main.Size    = UDim2.fromOffset(220, 0)
        TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(220, isCollapsed and COLLAPSED_H or FULL_H)
        }):Play()
        -- W สว่าง
        TweenService:Create(FloatW,       TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(13,17,32)}):Play()
        TweenService:Create(FloatWStroke, TweenInfo.new(0.2), {Color = themeColor}):Play()
        TweenService:Create(FloatW,       TweenInfo.new(0.2), {TextColor3 = themeColor}):Play()
    else
        -- ปิด panel
        TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.fromOffset(220, 0)
        }):Play()
        task.delay(0.22, function()
            Main.Visible = false
            Main.Size    = UDim2.fromOffset(220, isCollapsed and COLLAPSED_H or FULL_H)
        end)
        -- W หรี่ลง
        TweenService:Create(FloatW,       TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(17,24,39)}):Play()
        TweenService:Create(FloatWStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(30,42,64)}):Play()
        TweenService:Create(FloatW,       TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(136,153,187)}):Play()
    end
end)

FloatW.MouseEnter:Connect(function()
    TweenService:Create(FloatW, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(20,28,50)}):Play()
end)
FloatW.MouseLeave:Connect(function()
    local c = panelOpen and Color3.fromRGB(13,17,32) or Color3.fromRGB(17,24,39)
    TweenService:Create(FloatW, TweenInfo.new(0.15), {BackgroundColor3 = c}):Play()
end)

-- =============================================
-- ===== Helper: Toggle Row =====
-- =============================================
local function createToggleRow(labelText, descText, yPos, onCB, offCB)
    local box = Instance.new("Frame", Main)
    box.Size             = UDim2.new(1, -16, 0, 50)
    box.Position         = UDim2.new(0, 8, 0, yPos)
    box.BackgroundColor3 = Color3.fromRGB(17, 24, 39)
    box.BorderSizePixel  = 0
    box.ZIndex           = 10
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 10)

    local bs = Instance.new("UIStroke", box)
    bs.Color = themeColor; bs.Thickness = 1; bs.Transparency = 0.6

    local lbl = Instance.new("TextLabel", box)
    lbl.Size                  = UDim2.new(1, -64, 0, 22)
    lbl.Position              = UDim2.new(0, 10, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.Text                  = labelText
    lbl.TextColor3            = Color3.fromRGB(220, 220, 220)
    lbl.Font                  = Enum.Font.GothamBold
    lbl.TextSize              = 13
    lbl.TextXAlignment        = Enum.TextXAlignment.Left
    lbl.ZIndex                = 10

    local dlbl = Instance.new("TextLabel", box)
    dlbl.Size                  = UDim2.new(1, -64, 0, 16)
    dlbl.Position              = UDim2.new(0, 10, 0, 28)
    dlbl.BackgroundTransparency = 1
    dlbl.Text                  = descText
    dlbl.TextColor3            = Color3.fromRGB(74, 90, 122)
    dlbl.Font                  = Enum.Font.Gotham
    dlbl.TextSize              = 11
    dlbl.TextXAlignment        = Enum.TextXAlignment.Left
    dlbl.ZIndex                = 10

    local swBG = Instance.new("Frame", box)
    swBG.Size             = UDim2.fromOffset(44, 24)
    swBG.Position         = UDim2.new(1, -54, 0.5, -12)
    swBG.BackgroundColor3 = Color3.fromRGB(26, 32, 53)
    swBG.BorderSizePixel  = 0
    swBG.ZIndex           = 10
    Instance.new("UICorner", swBG).CornerRadius = UDim.new(1, 0)

    local swKnob = Instance.new("Frame", swBG)
    swKnob.Size             = UDim2.fromOffset(18, 18)
    swKnob.Position         = UDim2.new(0, 3, 0.5, -9)
    swKnob.BackgroundColor3 = Color3.fromRGB(58, 74, 106)
    swKnob.BorderSizePixel  = 0
    swKnob.ZIndex           = 11
    Instance.new("UICorner", swKnob).CornerRadius = UDim.new(1, 0)

    local hit = Instance.new("TextButton", box)
    hit.Size                  = UDim2.new(1, 0, 1, 0)
    hit.BackgroundTransparency = 1
    hit.Text                  = ""
    hit.ZIndex                = 12

    local state = false
    local function set(s)
        state = s
        TweenService:Create(swBG,   TweenInfo.new(0.2), {BackgroundColor3 = s and themeColor or Color3.fromRGB(26,32,53)}):Play()
        TweenService:Create(swKnob, TweenInfo.new(0.2), {
            Position         = s and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9),
            BackgroundColor3 = s and Color3.new(1,1,1) or Color3.fromRGB(58,74,106)
        }):Play()
        bs.Transparency = s and 0 or 0.6
        lbl.TextColor3  = s and themeColor or Color3.fromRGB(220,220,220)
        dlbl.Text       = s and "● กำลังทำงาน" or descText
        dlbl.TextColor3 = s and Color3.fromRGB(15,61,153) or Color3.fromRGB(74,90,122)
        if s then onCB() else offCB() end
    end
    hit.MouseButton1Click:Connect(function() set(not state) end)
    return set
end

-- =============================================
-- ===== Helper: Slider Row =====
-- =============================================
local function createSliderRow(labelText, yPos, initVal, minV, maxV, step, fillColor, onChange)
    local lbl = Instance.new("TextLabel", Main)
    lbl.Size                  = UDim2.new(1, -16, 0, 16)
    lbl.Position              = UDim2.new(0, 12, 0, yPos)
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment        = Enum.TextXAlignment.Left
    lbl.TextColor3            = Color3.fromRGB(136, 153, 187)
    lbl.TextSize              = 11
    lbl.Font                  = Enum.Font.Gotham
    lbl.ZIndex                = 10

    -- Value badge
    local valBadge = Instance.new("TextLabel", Main)
    valBadge.Size                  = UDim2.fromOffset(52, 16)
    valBadge.Position              = UDim2.new(1, -60, 0, yPos)
    valBadge.BackgroundColor3      = Color3.fromRGB(17, 24, 39)
    valBadge.TextColor3            = fillColor
    valBadge.Font                  = Enum.Font.GothamBold
    valBadge.TextSize              = 11
    valBadge.ZIndex                = 11
    Instance.new("UICorner", valBadge).CornerRadius = UDim.new(0, 5)
    local vbStroke = Instance.new("UIStroke", valBadge)
    vbStroke.Color = fillColor; vbStroke.Thickness = 1; vbStroke.Transparency = 0.7

    local row = Instance.new("Frame", Main)
    row.Size                  = UDim2.new(1, -16, 0, 22)
    row.Position              = UDim2.new(0, 8, 0, yPos + 18)
    row.BackgroundTransparency = 1
    row.ZIndex                = 10

    -- ปุ่ม −
    local btnD = Instance.new("TextButton", row)
    btnD.Size             = UDim2.new(0, 28, 1, 0)
    btnD.Position         = UDim2.new(0, 0, 0, 0)
    btnD.BackgroundColor3 = Color3.fromRGB(17, 24, 39)
    btnD.Text             = "−"
    btnD.TextColor3       = Color3.fromRGB(136, 153, 187)
    btnD.TextSize         = 14
    btnD.Font             = Enum.Font.GothamBold
    btnD.BorderSizePixel  = 0
    btnD.ZIndex           = 11
    Instance.new("UICorner", btnD).CornerRadius = UDim.new(0, 7)
    Instance.new("UIStroke", btnD).Color = Color3.fromRGB(30,42,64)

    -- ปุ่ม ＋
    local btnU = Instance.new("TextButton", row)
    btnU.Size             = UDim2.new(0, 28, 1, 0)
    btnU.Position         = UDim2.new(1, -28, 0, 0)
    btnU.BackgroundColor3 = Color3.fromRGB(17, 24, 39)
    btnU.Text             = "＋"
    btnU.TextColor3       = Color3.fromRGB(136, 153, 187)
    btnU.TextSize         = 14
    btnU.Font             = Enum.Font.GothamBold
    btnU.BorderSizePixel  = 0
    btnU.ZIndex           = 11
    Instance.new("UICorner", btnU).CornerRadius = UDim.new(0, 7)
    Instance.new("UIStroke", btnU).Color = Color3.fromRGB(30,42,64)

    -- แถบ track
    local bar = Instance.new("Frame", row)
    bar.Size             = UDim2.new(1, -68, 0, 6)
    bar.Position         = UDim2.new(0, 34, 0.5, -3)
    bar.BackgroundColor3 = Color3.fromRGB(26, 32, 53)
    bar.BorderSizePixel  = 0
    bar.ZIndex           = 10
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame", bar)
    fill.BackgroundColor3 = fillColor
    fill.BorderSizePixel  = 0
    fill.ZIndex           = 11
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    -- thumb
    local thumb = Instance.new("Frame", bar)
    thumb.Size             = UDim2.fromOffset(14, 14)
    thumb.AnchorPoint      = Vector2.new(0.5, 0.5)
    thumb.BackgroundColor3 = fillColor
    thumb.BorderSizePixel  = 0
    thumb.ZIndex           = 13
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)
    local thumbStroke = Instance.new("UIStroke", thumb)
    thumbStroke.Color = Color3.fromRGB(13,17,32); thumbStroke.Thickness = 2.5

    -- Hitbox ล่องหนครอบแถบทั้งหมด (hit area ใหญ่กว่า track จริง)
    local hitbox = Instance.new("TextButton", row)
    hitbox.Size                  = UDim2.new(1, -68, 1, 8)
    hitbox.Position              = UDim2.new(0, 34, 0.5, -4)
    hitbox.BackgroundTransparency = 1
    hitbox.Text                  = ""
    hitbox.ZIndex                = 12

    local val = initVal
    local function refresh()
        local pct = math.clamp((val - minV) / (maxV - minV), 0, 1)
        fill.Size          = UDim2.new(pct, 0, 1, 0)
        thumb.Position     = UDim2.new(pct, 0, 0.5, 0)
        local disp = step < 1 and string.format("%.2f", val) or tostring(val)
        lbl.Text       = labelText
        valBadge.Text  = disp
        onChange(val)
    end
    refresh()

    local function updateFromInput(input)
        local pos       = input.Position.X
        local absPos    = bar.AbsolutePosition.X
        local absSize   = bar.AbsoluteSize.X
        local pct       = math.clamp((pos - absPos) / absSize, 0, 1)
        local rawVal    = minV + (maxV - minV) * pct
        local stepCount = math.floor(((rawVal - minV) / step) + 0.5)
        val = math.clamp(math.floor((minV + stepCount * step) * 1000 + 0.5) / 1000, minV, maxV)
        refresh()
    end

    local sliding = false
    hitbox.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            updateFromInput(inp)
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if sliding and (inp.UserInputType == Enum.UserInputType.MouseMovement
        or inp.UserInputType == Enum.UserInputType.Touch) then
            updateFromInput(inp)
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then sliding = false end
    end)

    -- กดปุ่ม +/−
    btnD.MouseButton1Click:Connect(function()
        val = math.max(minV, math.floor((val - step)*1000+0.5)/1000); refresh()
    end)
    btnU.MouseButton1Click:Connect(function()
        val = math.min(maxV, math.floor((val + step)*1000+0.5)/1000); refresh()
    end)

    -- hover ปุ่ม
    for _, btn in ipairs({btnD, btnU}) do
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.12), {TextColor3 = fillColor}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.12), {TextColor3 = Color3.fromRGB(136,153,187)}):Play()
        end)
    end
end

-- =============================================
-- ===== สร้างเมนูหลัก =====
-- =============================================

-- แถบขั้น (divider) ก่อน settings
local divider = Instance.new("Frame", Main)
divider.Size             = UDim2.new(1, -16, 0, 1)
divider.Position         = UDim2.new(0, 8, 0, 48)
divider.BackgroundColor3 = Color3.fromRGB(30, 42, 64)
divider.BorderSizePixel  = 0
divider.ZIndex           = 10

-- Toggle Free Cam
createToggleRow("🎥  Free Camera", "เปิดกล้องอิสระ", 52,
    function()
        enabled = true; lockCharacter(true); camReady = false
        local cf   = camera.CFrame
        targetPos  = cf.Position; currentPos = cf.Position
        local rx, ry, _ = cf:ToOrientation()
        targetRotX  = math.deg(rx); currentRotX = math.deg(rx)
        targetRotY  = math.deg(ry); currentRotY = math.deg(ry)
        camera.CameraType  = Enum.CameraType.Scriptable
        camera.CFrame      = cf
        camFOV = camera.FieldOfView
        camReady = true
        if joyBase then joyBase.Visible = false end
        local zp = screenGui:FindFirstChild("VerticalZoomPanel")
        if zp then zp.Visible = true end
    end,
    function()
        enabled = false; camReady = false; lockCharacter(false)
        camera.CameraType  = Enum.CameraType.Custom
        local ch = player.Character
        if ch then camera.CameraSubject = ch:FindFirstChildOfClass("Humanoid") or ch end
        camera.FieldOfView = 70; camFOV = 70
        moveVec = Vector2.zero
        if joyBase then joyBase.Visible = false end
        local zp = screenGui:FindFirstChild("VerticalZoomPanel")
        if zp then zp.Visible = false end
    end
)

-- Sliders
local SECTION_LABEL_Y = 110
local sectionLbl = Instance.new("TextLabel", Main)
sectionLbl.Size                  = UDim2.new(1, -16, 0, 14)
sectionLbl.Position              = UDim2.new(0, 12, 0, SECTION_LABEL_Y)
sectionLbl.BackgroundTransparency = 1
sectionLbl.Text                  = "⚙  SETTINGS"
sectionLbl.TextColor3            = Color3.fromRGB(74, 90, 122)
sectionLbl.Font                  = Enum.Font.GothamBold
sectionLbl.TextSize              = 10
sectionLbl.TextXAlignment        = Enum.TextXAlignment.Left
sectionLbl.ZIndex                = 10

createSliderRow("⚡ SPEED",       126, camSpeed, 2,    60,  2,    Color3.fromRGB(0, 212, 255),  function(v) camSpeed = v end)
createSliderRow("🎯 SENSITIVITY", 164, sens,     0.02, 0.5, 0.02, Color3.fromRGB(255, 165, 0),  function(v) sens     = v end)
createSliderRow("〰 SMOOTH",      202, SMOOTH,   1,    20,  1,    Color3.fromRGB(34, 197, 94),  function(v) SMOOTH   = v end)

-- Credit
local Credit = Instance.new("TextLabel", Main)
Credit.Size                  = UDim2.new(1, 0, 0, 16)
Credit.Position              = UDim2.new(0, 0, 1, -18)
Credit.BackgroundTransparency = 1
Credit.Text                  = "FreeCamPro — WackShop Style"
Credit.TextColor3            = Color3.fromRGB(40, 50, 70)
Credit.Font                  = Enum.Font.Gotham
Credit.TextSize              = 10
Credit.ZIndex                = 10

-- =============================================
-- ===== FOV Panel แนวตั้ง (แยก) =====
-- =============================================
if USE_ZOOM_BUTTONS then
    local zoomContainer = Instance.new("Frame", screenGui)
    zoomContainer.Name           = "VerticalZoomPanel"
    zoomContainer.Size           = UDim2.fromOffset(52, 210)
    zoomContainer.AnchorPoint    = Vector2.new(1, 0.5)
    zoomContainer.Position       = UDim2.new(1, -78, 0.5, 0)
    zoomContainer.BackgroundColor3 = Color3.fromRGB(13, 17, 32)
    zoomContainer.BorderSizePixel  = 0
    zoomContainer.Visible        = false
    zoomContainer.ZIndex         = 15
    Instance.new("UICorner", zoomContainer).CornerRadius = UDim.new(0, 14)
    local zcStroke = Instance.new("UIStroke", zoomContainer)
    zcStroke.Color = Color3.fromRGB(30,42,64); zcStroke.Thickness = 1.5

    -- Label "FOV" แนวตั้ง
    local fovLabel = Instance.new("TextLabel", zoomContainer)
    fovLabel.Size                  = UDim2.new(1, 0, 0, 44)
    fovLabel.Position              = UDim2.new(0, 0, 0, 0)
    fovLabel.BackgroundTransparency = 1
    fovLabel.Text                  = "FOV"
    fovLabel.TextColor3            = Color3.fromRGB(168, 85, 247)
    fovLabel.Font                  = Enum.Font.GothamBold
    fovLabel.TextSize              = 10
    fovLabel.ZIndex                = 16

    -- Value badge
    local fovVal = Instance.new("TextLabel", zoomContainer)
    fovVal.Size                  = UDim2.new(1, -8, 0, 20)
    fovVal.Position              = UDim2.new(0, 4, 0, 44)
    fovVal.BackgroundColor3      = Color3.fromRGB(17, 24, 39)
    fovVal.BackgroundTransparency = 0
    fovVal.Text                  = tostring(camFOV) .. "°"
    fovVal.TextColor3            = Color3.fromRGB(168, 85, 247)
    fovVal.Font                  = Enum.Font.GothamBold
    fovVal.TextSize              = 11
    fovVal.ZIndex                = 17
    Instance.new("UICorner", fovVal).CornerRadius = UDim.new(0, 5)
    local fvStroke = Instance.new("UIStroke", fovVal)
    fvStroke.Color = Color3.fromRGB(168,85,247); fvStroke.Thickness = 1; fvStroke.Transparency = 0.65

    -- ปุ่ม ＋ (zoom in = FOV ลด)
    local btnPlus = Instance.new("TextButton", zoomContainer)
    btnPlus.Size             = UDim2.new(1, -8, 0, 32)
    btnPlus.Position         = UDim2.new(0, 4, 0, 68)
    btnPlus.BackgroundColor3 = Color3.fromRGB(17, 24, 39)
    btnPlus.Text             = "＋"
    btnPlus.TextColor3       = Color3.fromRGB(136, 153, 187)
    btnPlus.Font             = Enum.Font.GothamBold
    btnPlus.TextSize         = 20
    btnPlus.BorderSizePixel  = 0
    btnPlus.ZIndex           = 16
    Instance.new("UICorner", btnPlus).CornerRadius = UDim.new(0, 9)
    Instance.new("UIStroke", btnPlus).Color = Color3.fromRGB(30,42,64)

    -- แถบ FOV แนวตั้ง
    local trackBG = Instance.new("Frame", zoomContainer)
    trackBG.Size             = UDim2.new(0, 8, 0, 62)
    trackBG.Position         = UDim2.new(0.5, -4, 0, 104)
    trackBG.BackgroundColor3 = Color3.fromRGB(26, 32, 53)
    trackBG.BorderSizePixel  = 0
    trackBG.ZIndex           = 16
    Instance.new("UICorner", trackBG).CornerRadius = UDim.new(1, 0)

    local trackFill = Instance.new("Frame", trackBG)
    trackFill.AnchorPoint      = Vector2.new(0, 1)
    trackFill.Position         = UDim2.new(0, 0, 1, 0)
    trackFill.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
    trackFill.BorderSizePixel  = 0
    trackFill.ZIndex           = 17
    Instance.new("UICorner", trackFill).CornerRadius = UDim.new(1, 0)

    local trackThumb = Instance.new("Frame", trackBG)
    trackThumb.Size             = UDim2.fromOffset(14, 14)
    trackThumb.AnchorPoint      = Vector2.new(0.5, 0.5)
    trackThumb.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
    trackThumb.BorderSizePixel  = 0
    trackThumb.ZIndex           = 18
    Instance.new("UICorner", trackThumb).CornerRadius = UDim.new(1, 0)
    local ttStroke = Instance.new("UIStroke", trackThumb)
    ttStroke.Color = Color3.fromRGB(13,17,32); ttStroke.Thickness = 2.5

    -- Hitbox แนวตั้ง
    local trackHitbox = Instance.new("TextButton", zoomContainer)
    trackHitbox.Size                  = UDim2.new(1, 0, 0, 70)
    trackHitbox.Position              = UDim2.new(0, 0, 0, 100)
    trackHitbox.BackgroundTransparency = 1
    trackHitbox.Text                  = ""
    trackHitbox.ZIndex                = 19

    -- อัปเดต visual FOV
    local function refreshFov()
        local pct = math.clamp((camFOV - minFOV) / (maxFOV - minFOV), 0, 1)
        trackFill.Size      = UDim2.new(1, 0, pct, 0)
        trackThumb.Position = UDim2.new(0.5, 0, 1 - pct, 0)
        fovVal.Text         = tostring(math.floor(camFOV + 0.5)) .. "°"
    end
    refreshFov()

    -- ลาก track
    local fovSliding = false
    trackHitbox.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            fovSliding = true
            local absTop  = trackBG.AbsolutePosition.Y
            local absH    = trackBG.AbsoluteSize.Y
            local pct     = math.clamp((inp.Position.Y - absTop) / absH, 0, 1)
            camFOV = math.clamp(minFOV + (maxFOV - minFOV) * (1 - pct), minFOV, maxFOV)
            refreshFov()
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if fovSliding and (inp.UserInputType == Enum.UserInputType.MouseMovement
        or inp.UserInputType == Enum.UserInputType.Touch) then
            local absTop = trackBG.AbsolutePosition.Y
            local absH   = trackBG.AbsoluteSize.Y
            local pct    = math.clamp((inp.Position.Y - absTop) / absH, 0, 1)
            camFOV = math.clamp(minFOV + (maxFOV - minFOV) * (1 - pct), minFOV, maxFOV)
            refreshFov()
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then fovSliding = false end
    end)

    -- ปุ่ม ＋/－
    btnPlus.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            zoomInHeld = true
            TweenService:Create(btnPlus, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(168,85,247), TextColor3 = Color3.new(1,1,1)}):Play()
        end
    end)
    btnPlus.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            zoomInHeld = false
            TweenService:Create(btnPlus, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(17,24,39), TextColor3 = Color3.fromRGB(136,153,187)}):Play()
        end
    end)

    -- ปุ่ม ＋ (ล่าง) = zoom out (FOV เพิ่ม)
    local btnMinus = Instance.new("TextButton", zoomContainer)
    btnMinus.Size             = UDim2.new(1, -8, 0, 32)
    btnMinus.Position         = UDim2.new(0, 4, 0, 170)
    btnMinus.BackgroundColor3 = Color3.fromRGB(17, 24, 39)
    btnMinus.Text             = "－"
    btnMinus.TextColor3       = Color3.fromRGB(136, 153, 187)
    btnMinus.Font             = Enum.Font.GothamBold
    btnMinus.TextSize         = 20
    btnMinus.BorderSizePixel  = 0
    btnMinus.ZIndex           = 16
    Instance.new("UICorner", btnMinus).CornerRadius = UDim.new(0, 9)
    Instance.new("UIStroke", btnMinus).Color = Color3.fromRGB(30,42,64)

    btnMinus.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            zoomOutHeld = true
            TweenService:Create(btnMinus, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(168,85,247), TextColor3 = Color3.new(1,1,1)}):Play()
        end
    end)
    btnMinus.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            zoomOutHeld = false
            TweenService:Create(btnMinus, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(17,24,39), TextColor3 = Color3.fromRGB(136,153,187)}):Play()
        end
    end)

    -- อัปเดต fovVal ทุก frame เมื่อกดค้าง
    RS.Heartbeat:Connect(function()
        if zoomInHeld or zoomOutHeld then refreshFov() end
    end)
end

-- =============================================
-- ===== JOYSTICK =====
-- =============================================
local JOY_D = JOY_RADIUS * 2

joyBase = Instance.new("Frame", screenGui)
joyBase.Size                  = UDim2.new(0, JOY_D + 20, 0, JOY_D + 20)
joyBase.BackgroundColor3      = Color3.fromRGB(255, 255, 255)
joyBase.BackgroundTransparency = 0.98
joyBase.BorderSizePixel       = 0
joyBase.Visible               = false
Instance.new("UICorner", joyBase).CornerRadius = UDim.new(0.5, 0)

joyKnob = Instance.new("Frame", joyBase)
joyKnob.Size                  = UDim2.new(0, JOY_RADIUS, 0, JOY_RADIUS)
joyKnob.Position              = UDim2.new(0.5, -JOY_RADIUS/2, 0.5, -JOY_RADIUS/2)
joyKnob.BackgroundColor3      = themeColor
joyKnob.BackgroundTransparency = 0.95
joyKnob.BorderSizePixel       = 0
Instance.new("UICorner", joyKnob).CornerRadius = UDim.new(0.5, 0)

local function joyStart(pos)
    joyActive = true
    joyBase.Position = UDim2.new(0, pos.X - (JOY_D+20)/2, 0, pos.Y - (JOY_D+20)/2)
    joyCenter        = Vector2.new(pos.X, pos.Y)
    joyBase.Visible  = true
end
local function joyMove(pos)
    if not joyActive then return end
    local delta = Vector2.new(pos.X - joyCenter.X, pos.Y - joyCenter.Y)
    local dist  = math.min(delta.Magnitude, JOY_RADIUS)
    local dir   = delta.Magnitude > 0 and delta.Unit or Vector2.zero
    joyKnob.Position = UDim2.new(0.5, (dir*dist).X - JOY_RADIUS/2, 0.5, (dir*dist).Y - JOY_RADIUS/2)
    moveVec = dir * (dist / JOY_RADIUS)
end
local function joyEnd()
    joyActive        = false; joyTouchId = nil
    moveVec          = Vector2.zero
    joyKnob.Position = UDim2.new(0.5, -JOY_RADIUS/2, 0.5, -JOY_RADIUS/2)
    joyBase.Visible  = false
end

UIS.TouchStarted:Connect(function(inp, gpe)
    if not enabled or gpe then return end
    if inp.Position.X < camera.ViewportSize.X / 2 then
        if not joyActive and not joyTouchId then joyTouchId = inp; joyStart(inp.Position) end
    else
        if not rotating and not rotTouchId then rotating = true; rotTouchId = inp end
    end
end)
UIS.TouchMoved:Connect(function(inp)
    if not enabled then return end
    if inp == joyTouchId then joyMove(inp.Position)
    elseif inp == rotTouchId and rotating then
        targetRotY = targetRotY - (inp.Delta.X * sens)
        targetRotX = math.clamp(targetRotX - (inp.Delta.Y * sens), -85, 85)
    end
end)
UIS.TouchEnded:Connect(function(inp)
    if inp == joyTouchId then joyEnd() end
    if inp == rotTouchId then rotating = false; rotTouchId = nil end
end)

UIS.InputChanged:Connect(function(input, gpe)
    if not enabled or gpe then return end
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        camFOV = math.clamp(camFOV - (input.Position.Z * 4), minFOV, maxFOV)
    end
end)

print("✅ FreeCamPro v2.0 — WackShop Style โหลดสำเร็จ!")
