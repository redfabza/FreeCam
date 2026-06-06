-- FreeCamPro v3 · WackShop
local Players = game:GetService("Players")
local RS      = game:GetService("RunService")
local UIS     = game:GetService("UserInputService")
local TS      = game:GetService("TweenService")
local SG      = game:GetService("StarterGui")

local plr    = Players.LocalPlayer
local cam    = workspace.CurrentCamera
local pgui   = plr:WaitForChild("PlayerGui")

if pgui:FindFirstChild("FCP") then pgui.FCP:Destroy() end

-- ค่าตั้งต้น
local SPEED  = 20
local SENS   = 0.18
local SMOOTH = 8
local JR     = 55

-- state
local on       = false
local ready    = false
local panelVis = true
local mv       = Vector2.zero
local tRX,tRY,cRX,cRY = 0,0,0,0
local tP,cP    = Vector3.zero,Vector3.zero
local oSpeed,oJump,locCF,locConn
local jOn,jTid,jCen = false,nil,Vector2.zero
local rOn,rTid      = false,nil
local jBase,jKnob

local BLUE   = Color3.fromRGB(26,111,255)
local CYAN   = Color3.fromRGB(0,195,255)
local BG     = Color3.fromRGB(14,18,30)
local ROW    = Color3.fromRGB(22,28,46)

-- lock char
local function lockChar(state)
    local ch  = plr.Character; if not ch then return end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    if state then
        if hum then oSpeed=hum.WalkSpeed;oJump=hum.JumpPower;hum.WalkSpeed=0;hum.JumpPower=0;hum.PlatformStand=true end
        if hrp  then hrp.Anchored=true;locCF=hrp.CFrame
            locConn=RS.Heartbeat:Connect(function()
                if hrp and locCF then hrp.CFrame=locCF;hrp.AssemblyLinearVelocity=Vector3.zero;hrp.AssemblyAngularVelocity=Vector3.zero end
            end)
        end
    else
        if locConn then locConn:Disconnect() end
        if hrp  then hrp.Anchored=false end
        if hum  then hum.WalkSpeed=oSpeed or 16;hum.JumpPower=oJump or 50;hum.PlatformStand=false end
    end
end

-- camera loop
RS.RenderStepped:Connect(function(dt)
    if not on or not ready then return end
    local a=1-math.exp(-SMOOTH*dt)
    if mv.Magnitude>0.05 then
        local d=cam.CFrame.LookVector*-mv.Y+cam.CFrame.RightVector*mv.X
        if d.Magnitude>0 then tP=tP+d.Unit*SPEED*dt end
    end
    cP=cP:Lerp(tP,a);cRX=cRX+(tRX-cRX)*a;cRY=cRY+(tRY-cRY)*a
    cam.CFrame=CFrame.new(cP)*CFrame.Angles(0,math.rad(cRY),0)*CFrame.Angles(math.rad(cRX),0,0)
end)

-- ===================== GUI =====================
local sg=Instance.new("ScreenGui")
sg.Name="FCP";sg.IgnoreGuiInset=true;sg.ResetOnSpawn=false;sg.Parent=pgui

-- helper สร้าง Frame
local function F(parent,props)
    local f=Instance.new("Frame");f.BorderSizePixel=0
    for k,v in pairs(props) do f[k]=v end
    f.Parent=parent;return f
end
local function R(parent,props) -- UICorner radius
    local c=Instance.new("UICorner");c.CornerRadius=props;c.Parent=parent
end
local function L(parent,props) -- TextLabel
    local l=Instance.new("TextLabel");l.BorderSizePixel=0;l.BackgroundTransparency=1
    for k,v in pairs(props) do l[k]=v end
    l.Parent=parent;return l
end
local function B(parent,props) -- TextButton
    local b=Instance.new("TextButton");b.BorderSizePixel=0;b.AutoButtonColor=false
    for k,v in pairs(props) do b[k]=v end
    b.Parent=parent;return b
end

-- ======== MAIN PANEL ========
local panel=F(sg,{Name="Panel",Size=UDim2.fromOffset(230,320),Position=UDim2.new(1,-250,0.5,-160),BackgroundColor3=BG})
R(panel,UDim.new(0,14))
local ps=Instance.new("UIStroke",panel);ps.Color=Color3.fromRGB(40,55,90);ps.Thickness=1.5

-- title bar
local title=F(panel,{Size=UDim2.new(1,0,0,48),BackgroundColor3=Color3.fromRGB(10,13,22),ZIndex=2})
R(title,UDim.new(0,14))
local iconF=F(title,{Size=UDim2.fromOffset(32,32),Position=UDim2.new(0,10,0.5,-16),BackgroundColor3=BLUE,ZIndex=2})
R(iconF,UDim.new(0,8))
L(iconF,{Size=UDim2.new(1,0,1,0),Text="🎥",TextSize=16,Font=Enum.Font.GothamBold,ZIndex=3})
L(title,{Size=UDim2.new(1,-90,0,22),Position=UDim2.new(0,50,0,6),Text="FreeCam Pro",TextColor3=Color3.fromRGB(235,240,255),Font=Enum.Font.GothamBold,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=3})
L(title,{Size=UDim2.new(1,-90,0,14),Position=UDim2.new(0,50,0,28),Text="v3.0 · WackShop",TextColor3=Color3.fromRGB(70,88,130),Font=Enum.Font.Gotham,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=3})

local closeBtn=B(title,{Size=UDim2.fromOffset(28,28),Position=UDim2.new(1,-36,0.5,-14),BackgroundColor3=Color3.fromRGB(50,20,20),Text="✕",TextColor3=Color3.fromRGB(220,80,80),Font=Enum.Font.GothamBold,TextSize=13,ZIndex=4})
R(closeBtn,UDim.new(0,7))
Instance.new("UIStroke",closeBtn).Color=Color3.fromRGB(180,50,50)

closeBtn.InputEnded:Connect(function(i)
    if i.UserInputType~=Enum.UserInputType.MouseButton1 and i.UserInputType~=Enum.UserInputType.Touch then return end
    if on then on=false;ready=false;lockChar(false);cam.CameraType=Enum.CameraType.Custom
        local ch=plr.Character;if ch then cam.CameraSubject=ch:FindFirstChildOfClass("Humanoid") or ch end
        cam.FieldOfView=70;pcall(function()SG:SetCoreGuiEnabled(Enum.CoreGuiType.TouchGui,true)end)
    end
    sg:Destroy()
end)

-- drag panel
local dg={}
title.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        dg.on=true;dg.s=i.Position;dg.o=panel.Position end
end)
UIS.InputChanged:Connect(function(i)
    if dg.on and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
        local d=i.Position-dg.s;panel.Position=UDim2.new(dg.o.X.Scale,dg.o.X.Offset+d.X,dg.o.Y.Scale,dg.o.Y.Offset+d.Y) end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dg.on=false end
end)

-- divider
local function divider(y)
    local d=F(panel,{Size=UDim2.new(1,-20,0,1),Position=UDim2.new(0,10,0,y),BackgroundColor3=Color3.fromRGB(35,48,75),ZIndex=2})
end

-- ======== TOGGLE ========
local function makeToggle(label,desc,y,onFn,offFn)
    local row=F(panel,{Size=UDim2.new(1,-16,0,52),Position=UDim2.new(0,8,0,y),BackgroundColor3=ROW,ZIndex=2})
    R(row,UDim.new(0,10))
    local st=Instance.new("UIStroke",row);st.Color=BLUE;st.Thickness=1;st.Transparency=0.7

    L(row,{Size=UDim2.new(1,-70,0,22),Position=UDim2.new(0,12,0,7),Text=label,TextColor3=Color3.fromRGB(215,220,235),Font=Enum.Font.GothamBold,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=3})
    local db=L(row,{Size=UDim2.new(1,-70,0,16),Position=UDim2.new(0,12,0,29),Text=desc,TextColor3=Color3.fromRGB(70,88,130),Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=3})

    local swBG=F(row,{Size=UDim2.fromOffset(46,24),Position=UDim2.new(1,-56,0.5,-12),BackgroundColor3=Color3.fromRGB(30,38,60),ZIndex=3})
    R(swBG,UDim.new(1,0))
    local knob=F(swBG,{Size=UDim2.fromOffset(18,18),Position=UDim2.new(0,3,0.5,-9),BackgroundColor3=Color3.fromRGB(80,95,130),ZIndex=4})
    R(knob,UDim.new(1,0))

    -- hitbox ใหญ่ทั้ง row และ ZIndex สูงกว่าทุกอย่าง
    local hit=B(row,{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=10})

    local state=false
    local function set(s)
        state=s
        TS:Create(swBG,TweenInfo.new(0.2),{BackgroundColor3=s and BLUE or Color3.fromRGB(30,38,60)}):Play()
        TS:Create(knob,TweenInfo.new(0.2),{Position=s and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9),BackgroundColor3=s and Color3.new(1,1,1) or Color3.fromRGB(80,95,130)}):Play()
        st.Transparency=s and 0.2 or 0.7
        db.Text=s and "● กำลังทำงาน" or desc
        db.TextColor3=s and Color3.fromRGB(100,140,255) or Color3.fromRGB(70,88,130)
        if s then onFn() else offFn() end
    end
    hit.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then set(not state) end
    end)
end

-- ======== SLIDER ========
local function makeSlider(label,y,val,mn,mx,step,col,onChange)
    L(panel,{Size=UDim2.new(1,-80,0,16),Position=UDim2.new(0,14,0,y),Text=label,TextColor3=Color3.fromRGB(140,155,190),Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=2})
    local badge=L(panel,{Size=UDim2.fromOffset(52,16),Position=UDim2.new(1,-64,0,y),Text="",TextColor3=col,Font=Enum.Font.GothamBold,TextSize=11,BackgroundColor3=Color3.fromRGB(20,26,44),BackgroundTransparency=0,ZIndex=2})
    R(badge,UDim.new(0,5))

    local track=F(panel,{Size=UDim2.new(1,-28,0,6),Position=UDim2.new(0,14,0,y+20),BackgroundColor3=Color3.fromRGB(30,38,60),ZIndex=2})
    R(track,UDim.new(1,0))
    local fill=F(track,{BackgroundColor3=col,ZIndex=3});R(fill,UDim.new(1,0))
    local thumb=F(track,{Size=UDim2.fromOffset(16,16),AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=col,ZIndex=4})
    R(thumb,UDim.new(1,0))
    local tsk=Instance.new("UIStroke",thumb);tsk.Color=Color3.fromRGB(10,14,24);tsk.Thickness=2.5

    local hit=B(track,{Size=UDim2.new(1,0,0,30),Position=UDim2.new(0,0,0.5,-15),BackgroundTransparency=1,Text="",ZIndex=10})

    local cur=val
    local function refresh()
        local p=math.clamp((cur-mn)/(mx-mn),0,1)
        fill.Size=UDim2.new(p,0,1,0);thumb.Position=UDim2.new(p,0,0.5,0)
        badge.Text=step<1 and string.format("%.2f",cur) or tostring(cur)
        onChange(cur)
    end
    refresh()
    local function fromInp(i)
        local p=math.clamp((i.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        local n=math.floor(((mn+(mx-mn)*p-mn)/step)+0.5)
        cur=math.clamp(math.floor((mn+n*step)*1000+0.5)/1000,mn,mx);refresh()
    end
    local sld=false
    hit.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then sld=true;fromInp(i) end
    end)
    UIS.InputChanged:Connect(function(i)
        if sld and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then fromInp(i) end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then sld=false end
    end)
end

-- forward declare fovPanel
local fovPanel

-- ======== วาง UI ========
divider(52)

makeToggle("🎥  Free Camera","เปิดกล้องอิสระ",58,
    function()
        on=true;lockChar(true);ready=false
        pcall(function()SG:SetCoreGuiEnabled(Enum.CoreGuiType.TouchGui,false)end)
        local cf=cam.CFrame;tP=cf.Position;cP=cf.Position
        local rx,ry,_=cf:ToOrientation()
        tRX=math.deg(rx);cRX=math.deg(rx);tRY=math.deg(ry);cRY=math.deg(ry)
        cam.CameraType=Enum.CameraType.Scriptable;cam.CFrame=cf;ready=true
        if jBase then jBase.Visible=false end
    end,
    function()
        on=false;ready=false;lockChar(false)
        pcall(function()SG:SetCoreGuiEnabled(Enum.CoreGuiType.TouchGui,true)end)
        cam.CameraType=Enum.CameraType.Custom
        local ch=plr.Character;if ch then cam.CameraSubject=ch:FindFirstChildOfClass("Humanoid") or ch end
        cam.FieldOfView=70;mv=Vector2.zero
        if jBase then jBase.Visible=false end
    end
)

divider(116)
L(panel,{Size=UDim2.new(1,-16,0,14),Position=UDim2.new(0,12,0,120),Text="⚙  SETTINGS",TextColor3=Color3.fromRGB(60,80,120),Font=Enum.Font.GothamBold,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=2})

makeSlider("⚡ SPEED",      136,SPEED,2,60,2,   Color3.fromRGB(0,210,255), function(v)SPEED=v end)
makeSlider("🎯 SENSITIVITY",170,SENS,0.02,0.5,0.02,Color3.fromRGB(255,165,0),function(v)SENS=v end)
makeSlider("〰 SMOOTH",     204,SMOOTH,1,20,1,  Color3.fromRGB(40,210,100),function(v)SMOOTH=v end)

divider(242)

makeToggle("🔭  FOV Override","ปรับ Field of View",248,
    function() fovPanel.Visible=true end,
    function() fovPanel.Visible=false;cam.FieldOfView=70 end
)

-- ======== FOV PANEL แยก ========
fovPanel=F(sg,{Name="FOVPanel",Size=UDim2.fromOffset(220,80),Position=UDim2.new(1,-250,0.5,175),BackgroundColor3=BG,Visible=false})
R(fovPanel,UDim.new(0,14))
local fps2=Instance.new("UIStroke",fovPanel);fps2.Color=Color3.fromRGB(168,85,247);fps2.Thickness=1.5

-- drag fovPanel
local fdg2={}
fovPanel.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        fdg2.on=true;fdg2.s=i.Position;fdg2.o=fovPanel.Position end
end)
UIS.InputChanged:Connect(function(i)
    if fdg2.on and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
        local d=i.Position-fdg2.s;fovPanel.Position=UDim2.new(fdg2.o.X.Scale,fdg2.o.X.Offset+d.X,fdg2.o.Y.Scale,fdg2.o.Y.Offset+d.Y) end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then fdg2.on=false end
end)

L(fovPanel,{Size=UDim2.new(0,60,0,20),Position=UDim2.new(0,12,0,8),Text="🔭 FOV",TextColor3=Color3.fromRGB(168,85,247),Font=Enum.Font.GothamBold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=2})
local fovBadge=L(fovPanel,{Size=UDim2.fromOffset(52,20),Position=UDim2.new(1,-62,0,8),Text="70°",TextColor3=Color3.fromRGB(168,85,247),Font=Enum.Font.GothamBold,TextSize=12,BackgroundColor3=Color3.fromRGB(20,26,44),BackgroundTransparency=0,ZIndex=2})
R(fovBadge,UDim.new(0,5))

local ftrack=F(fovPanel,{Size=UDim2.new(1,-24,0,8),Position=UDim2.new(0,12,0,44),BackgroundColor3=Color3.fromRGB(30,38,60),ZIndex=2})
R(ftrack,UDim.new(1,0))
local ffill=F(ftrack,{BackgroundColor3=Color3.fromRGB(168,85,247),ZIndex=3});R(ffill,UDim.new(1,0))
local fthumb=F(ftrack,{Size=UDim2.fromOffset(18,18),AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=Color3.fromRGB(168,85,247),ZIndex=4})
R(fthumb,UDim.new(1,0))
local ftsk=Instance.new("UIStroke",fthumb);ftsk.Color=Color3.fromRGB(10,14,24);ftsk.Thickness=2.5
local fhit=B(ftrack,{Size=UDim2.new(1,0,0,36),Position=UDim2.new(0,0,0.5,-18),BackgroundTransparency=1,Text="",ZIndex=10})

local fovVal=70
local function fRefresh()
    local p=math.clamp((fovVal-10)/110,0,1)
    ffill.Size=UDim2.new(p,0,1,0);fthumb.Position=UDim2.new(p,0,0.5,0)
    fovBadge.Text=tostring(math.floor(fovVal+0.5)).."°"
    cam.FieldOfView=fovVal
end
local fSld=false
local function fFromInp(i)
    local p=math.clamp((i.Position.X-ftrack.AbsolutePosition.X)/ftrack.AbsoluteSize.X,0,1)
    fovVal=math.clamp(10+110*p,10,120);fRefresh()
end
fhit.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then fSld=true;fFromInp(i) end
end)
UIS.InputChanged:Connect(function(i)
    if fSld and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then fFromInp(i) end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then fSld=false end
end)

-- ======== ปุ่ม W ========
local wBtn=B(sg,{Size=UDim2.fromOffset(42,42),Position=UDim2.new(0,24,0.5,-21),BackgroundColor3=Color3.fromRGB(0,0,0),Text=""})
R(wBtn,UDim.new(1,0))
local wLbl=L(wBtn,{Size=UDim2.new(1,0,1,0),Text="W",TextColor3=CYAN,Font=Enum.Font.GothamBlack,TextSize=18})
local wsk=Instance.new("UIStroke",wLbl);wsk.Color=CYAN;wsk.Thickness=1.5;wsk.ApplyStrokeMode=Enum.ApplyStrokeMode.Content

local wdg={}
wBtn.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        wdg.on=true;wdg.s=i.Position;wdg.o=wBtn.Position;wdg.mv=false end
end)
UIS.InputChanged:Connect(function(i)
    if wdg.on and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
        local d=i.Position-wdg.s;if d.Magnitude>6 then wdg.mv=true end
        wBtn.Position=UDim2.new(wdg.o.X.Scale,wdg.o.X.Offset+d.X,wdg.o.Y.Scale,wdg.o.Y.Offset+d.Y) end
end)
wBtn.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        if not wdg.mv then panelVis=not panelVis;panel.Visible=panelVis end
        wdg.on=false;wdg.mv=false end
end)

-- ======== Joystick ========
local JD=JR*2
jBase=F(sg,{Size=UDim2.fromOffset(JD+20,JD+20),BackgroundColor3=Color3.fromRGB(255,255,255),BackgroundTransparency=0.92,Visible=false})
R(jBase,UDim.new(0.5,0))
jKnob=F(jBase,{Size=UDim2.fromOffset(JR,JR),Position=UDim2.new(0.5,-JR/2,0.5,-JR/2),BackgroundColor3=BLUE,BackgroundTransparency=0.82})
R(jKnob,UDim.new(0.5,0))

local function jStart(pos) jOn=true;jBase.Position=UDim2.new(0,pos.X-(JD+20)/2,0,pos.Y-(JD+20)/2);jCen=Vector2.new(pos.X,pos.Y);jBase.Visible=true end
local function jMove(pos)
    if not jOn then return end
    local d=Vector2.new(pos.X-jCen.X,pos.Y-jCen.Y);local dist=math.min(d.Magnitude,JR)
    local dir=d.Magnitude>0 and d.Unit or Vector2.zero
    jKnob.Position=UDim2.new(0.5,(dir*dist).X-JR/2,0.5,(dir*dist).Y-JR/2);mv=dir*(dist/JR)
end
local function jEnd() jOn=false;jTid=nil;mv=Vector2.zero;jKnob.Position=UDim2.new(0.5,-JR/2,0.5,-JR/2);jBase.Visible=false end

UIS.TouchStarted:Connect(function(inp,gpe)
    if not on or gpe then return end
    if inp.Position.X<cam.ViewportSize.X/2 then
        if not jOn then jTid=inp;jStart(inp.Position) end
    else
        if not rOn then rOn=true;rTid=inp end
    end
end)
UIS.TouchMoved:Connect(function(inp)
    if not on then return end
    if inp==jTid then jMove(inp.Position)
    elseif inp==rTid and rOn then
        tRY=tRY-inp.Delta.X*SENS;tRX=math.clamp(tRX-inp.Delta.Y*SENS,-85,85) end
end)
UIS.TouchEnded:Connect(function(inp)
    if inp==jTid then jEnd() end
    if inp==rTid then rOn=false;rTid=nil end
end)

print("✅ FreeCamPro v3 โหลดสำเร็จ")
