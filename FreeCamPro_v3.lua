-- FreeCamPro v3 · WackShop
local Players = game:GetService("Players")
local RS      = game:GetService("RunService")
local UIS     = game:GetService("UserInputService")
local TS      = game:GetService("TweenService")
local SG      = game:GetService("StarterGui")

local plr  = Players.LocalPlayer
local cam  = workspace.CurrentCamera
local pg   = plr:WaitForChild("PlayerGui")
if pg:FindFirstChild("FCP") then pg.FCP:Destroy() end

local SPEED=20; local SENS=0.18; local SMOOTH=8; local JR=55
local camOn=false; local ready=false; local panVis=true
local mv=Vector2.zero
local tRX,tRY,cRX,cRY=0,0,0,0
local tPos,cPos=Vector3.zero,Vector3.zero
local oSpd,oJmp,lCF,lConn
local jOn,jTid,jCen=false,nil,Vector2.zero
local rOn,rTid=false,nil
local jBase,jKnob

local BLUE=Color3.fromRGB(26,111,255)
local CYAN=Color3.fromRGB(0,195,255)
local PURP=Color3.fromRGB(168,85,247)
local BG=Color3.fromRGB(14,18,30)
local ROW=Color3.fromRGB(22,28,46)

local function lockChar(s)
    local ch=plr.Character; if not ch then return end
    local hum=ch:FindFirstChildOfClass("Humanoid")
    local hrp=ch:FindFirstChild("HumanoidRootPart")
    if s then
        if hum then oSpd=hum.WalkSpeed;oJmp=hum.JumpPower;hum.WalkSpeed=0;hum.JumpPower=0;hum.PlatformStand=true end
        if hrp then
            hrp.Anchored=true;lCF=hrp.CFrame
            lConn=RS.Heartbeat:Connect(function()
                if hrp and lCF then hrp.CFrame=lCF;hrp.AssemblyLinearVelocity=Vector3.zero;hrp.AssemblyAngularVelocity=Vector3.zero end
            end)
        end
    else
        if lConn then lConn:Disconnect() end
        if hrp then hrp.Anchored=false end
        if hum then hum.WalkSpeed=oSpd or 16;hum.JumpPower=oJmp or 50;hum.PlatformStand=false end
    end
end

RS.RenderStepped:Connect(function(dt)
    if not camOn or not ready then return end
    local a=1-math.exp(-SMOOTH*dt)
    if mv.Magnitude>0.05 then
        local d=cam.CFrame.LookVector*-mv.Y+cam.CFrame.RightVector*mv.X
        if d.Magnitude>0 then tPos=tPos+d.Unit*SPEED*dt end
    end
    cPos=cPos:Lerp(tPos,a);cRX=cRX+(tRX-cRX)*a;cRY=cRY+(tRY-cRY)*a
    cam.CFrame=CFrame.new(cPos)*CFrame.Angles(0,math.rad(cRY),0)*CFrame.Angles(math.rad(cRX),0,0)
end)

-- ScreenGui
local sg=Instance.new("ScreenGui")
sg.Name="FCP";sg.IgnoreGuiInset=true;sg.ResetOnSpawn=false;sg.Parent=pg

-- ===== MAIN PANEL =====
local panel=Instance.new("Frame",sg)
panel.Size=UDim2.fromOffset(230,310)
panel.Position=UDim2.new(1,-248,0.5,-155)
panel.BackgroundColor3=BG;panel.BorderSizePixel=0
Instance.new("UICorner",panel).CornerRadius=UDim.new(0,14)
Instance.new("UIStroke",panel).Color=Color3.fromRGB(40,55,90)

-- title bar
local title=Instance.new("Frame",panel)
title.Size=UDim2.new(1,0,0,48);title.BackgroundColor3=Color3.fromRGB(10,13,22);title.BorderSizePixel=0
Instance.new("UICorner",title).CornerRadius=UDim.new(0,14)

local iF=Instance.new("Frame",title)
iF.Size=UDim2.fromOffset(32,32);iF.Position=UDim2.new(0,10,0.5,-16)
iF.BackgroundColor3=BLUE;iF.BorderSizePixel=0;Instance.new("UICorner",iF).CornerRadius=UDim.new(0,8)
local iL=Instance.new("TextLabel",iF);iL.Size=UDim2.new(1,0,1,0);iL.BackgroundTransparency=1;iL.Text="🎥";iL.TextSize=16;iL.Font=Enum.Font.GothamBold

local function mkLbl(p,txt,tc,fs,fnt,xa,sz,pos)
    local l=Instance.new("TextLabel",p);l.BackgroundTransparency=1;l.Text=txt;l.TextColor3=tc
    l.Font=fnt;l.TextSize=fs;l.TextXAlignment=xa;l.Size=sz;l.Position=pos;return l
end
mkLbl(title,"FreeCam Pro",Color3.fromRGB(235,240,255),14,Enum.Font.GothamBold,Enum.TextXAlignment.Left,UDim2.new(1,-90,0,22),UDim2.new(0,50,0,6))
mkLbl(title,"v3.0 · WackShop",Color3.fromRGB(70,88,130),10,Enum.Font.Gotham,Enum.TextXAlignment.Left,UDim2.new(1,-90,0,14),UDim2.new(0,50,0,28))

local xBtn=Instance.new("TextButton",title)
xBtn.Size=UDim2.fromOffset(28,28);xBtn.Position=UDim2.new(1,-36,0.5,-14)
xBtn.BackgroundColor3=Color3.fromRGB(50,20,20);xBtn.Text="✕";xBtn.TextColor3=Color3.fromRGB(220,80,80)
xBtn.Font=Enum.Font.GothamBold;xBtn.TextSize=13;xBtn.BorderSizePixel=0;xBtn.AutoButtonColor=false
Instance.new("UICorner",xBtn).CornerRadius=UDim.new(0,7)
xBtn.InputEnded:Connect(function(i)
    if i.UserInputType~=Enum.UserInputType.MouseButton1 and i.UserInputType~=Enum.UserInputType.Touch then return end
    if camOn then
        camOn=false;ready=false;lockChar(false);cam.CameraType=Enum.CameraType.Custom
        local ch=plr.Character;if ch then cam.CameraSubject=ch:FindFirstChildOfClass("Humanoid") or ch end
        cam.FieldOfView=70;pcall(function()SG:SetCoreGuiEnabled(Enum.CoreGuiType.TouchGui,true)end)
    end
    sg:Destroy()
end)

-- drag
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

local function mkLine(y)
    local l=Instance.new("Frame",panel);l.Size=UDim2.new(1,-20,0,1);l.Position=UDim2.new(0,10,0,y)
    l.BackgroundColor3=Color3.fromRGB(35,48,75);l.BorderSizePixel=0
end

-- ===== TOGGLE — ใช้ TextButton เป็น row ตรงๆ ไม่มี hitbox ซ้อน =====
local function mkToggle(lb,desc,y,onFn,offFn)
    -- ใช้ TextButton แทน Frame เพื่อให้รับ input ได้โดยตรง
    local row=Instance.new("TextButton",panel)
    row.Size=UDim2.new(1,-16,0,52);row.Position=UDim2.new(0,8,0,y)
    row.BackgroundColor3=ROW;row.BorderSizePixel=0;row.Text="";row.AutoButtonColor=false
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,10)
    local rStroke=Instance.new("UIStroke",row);rStroke.Color=BLUE;rStroke.Thickness=1;rStroke.Transparency=0.7

    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(1,-70,0,22);lbl.Position=UDim2.new(0,12,0,7)
    lbl.BackgroundTransparency=1;lbl.Text=lb;lbl.TextColor3=Color3.fromRGB(215,220,235)
    lbl.Font=Enum.Font.GothamBold;lbl.TextSize=13;lbl.TextXAlignment=Enum.TextXAlignment.Left

    local dbl=Instance.new("TextLabel",row)
    dbl.Size=UDim2.new(1,-70,0,16);dbl.Position=UDim2.new(0,12,0,29)
    dbl.BackgroundTransparency=1;dbl.Text=desc;dbl.TextColor3=Color3.fromRGB(70,88,130)
    dbl.Font=Enum.Font.Gotham;dbl.TextSize=11;dbl.TextXAlignment=Enum.TextXAlignment.Left

    local swBG=Instance.new("Frame",row)
    swBG.Size=UDim2.fromOffset(46,24);swBG.Position=UDim2.new(1,-56,0.5,-12)
    swBG.BackgroundColor3=Color3.fromRGB(30,38,60);swBG.BorderSizePixel=0
    Instance.new("UICorner",swBG).CornerRadius=UDim.new(1,0)

    local knob=Instance.new("Frame",swBG)
    knob.Size=UDim2.fromOffset(18,18);knob.Position=UDim2.new(0,3,0.5,-9)
    knob.BackgroundColor3=Color3.fromRGB(80,95,130);knob.BorderSizePixel=0
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)

    local state=false
    local function set(s)
        state=s
        TS:Create(swBG,TweenInfo.new(0.2),{BackgroundColor3=s and BLUE or Color3.fromRGB(30,38,60)}):Play()
        TS:Create(knob,TweenInfo.new(0.2),{
            Position=s and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9),
            BackgroundColor3=s and Color3.new(1,1,1) or Color3.fromRGB(80,95,130)
        }):Play()
        rStroke.Transparency=s and 0.1 or 0.7
        lbl.TextColor3=s and BLUE or Color3.fromRGB(215,220,235)
        dbl.Text=s and "● กำลังทำงาน" or desc
        dbl.TextColor3=s and Color3.fromRGB(100,160,255) or Color3.fromRGB(70,88,130)
        if s then onFn() else offFn() end
    end

    -- TextButton รับ input ตรงๆ ไม่ต้องมี hitbox
    row.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            set(not state) end
    end)
end

-- ===== SLIDER — ใช้ TextButton เป็น track =====
local function mkSlider(lb,y,val,mn,mx,step,col,fn)
    local slb=Instance.new("TextLabel",panel)
    slb.Size=UDim2.new(1,-80,0,16);slb.Position=UDim2.new(0,14,0,y)
    slb.BackgroundTransparency=1;slb.Text=lb;slb.TextColor3=Color3.fromRGB(140,155,190)
    slb.Font=Enum.Font.Gotham;slb.TextSize=11;slb.TextXAlignment=Enum.TextXAlignment.Left

    local badge=Instance.new("TextLabel",panel)
    badge.Size=UDim2.fromOffset(52,16);badge.Position=UDim2.new(1,-64,0,y)
    badge.BackgroundColor3=Color3.fromRGB(20,26,44);badge.BackgroundTransparency=0
    badge.TextColor3=col;badge.Font=Enum.Font.GothamBold;badge.TextSize=11;badge.BorderSizePixel=0
    Instance.new("UICorner",badge).CornerRadius=UDim.new(0,5)

    -- ใช้ TextButton แทน Frame+hitbox
    local track=Instance.new("TextButton",panel)
    track.Size=UDim2.new(1,-28,0,20);track.Position=UDim2.new(0,14,0,y+18)
    track.BackgroundColor3=Color3.fromRGB(30,38,60);track.BorderSizePixel=0
    track.Text="";track.AutoButtonColor=false
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)

    local fill=Instance.new("Frame",track)
    fill.BackgroundColor3=col;fill.BorderSizePixel=0;fill.Size=UDim2.new(0,0,1,0)
    Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)

    local thumb=Instance.new("Frame",track)
    thumb.Size=UDim2.fromOffset(20,20);thumb.AnchorPoint=Vector2.new(0.5,0.5)
    thumb.Position=UDim2.new(0,0,0.5,0);thumb.BackgroundColor3=col;thumb.BorderSizePixel=0
    Instance.new("UICorner",thumb).CornerRadius=UDim.new(1,0)
    local tsk=Instance.new("UIStroke",thumb);tsk.Color=Color3.fromRGB(10,14,24);tsk.Thickness=2.5

    local cur=val
    local function ref()
        local p=math.clamp((cur-mn)/(mx-mn),0,1)
        fill.Size=UDim2.new(p,0,1,0);thumb.Position=UDim2.new(p,0,0.5,0)
        badge.Text=step<1 and string.format("%.2f",cur) or tostring(cur);fn(cur)
    end
    ref()

    local sld=false
    local function fromI(i)
        local p=math.clamp((i.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        local n=math.floor(((mn+(mx-mn)*p-mn)/step)+0.5)
        cur=math.clamp(math.floor((mn+n*step)*1e3+0.5)/1e3,mn,mx);ref()
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then sld=true;fromI(i) end
    end)
    UIS.InputChanged:Connect(function(i)
        if sld and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then fromI(i) end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then sld=false end
    end)
end

-- ===== วาง element =====
mkLine(52)
mkToggle("🎥  Free Camera","เปิดกล้องอิสระ",58,
    function()
        camOn=true;lockChar(true);ready=false
        pcall(function()SG:SetCoreGuiEnabled(Enum.CoreGuiType.TouchGui,false)end)
        local cf=cam.CFrame;tPos=cf.Position;cPos=cf.Position
        local rx,ry,_=cf:ToOrientation()
        tRX=math.deg(rx);cRX=math.deg(rx);tRY=math.deg(ry);cRY=math.deg(ry)
        cam.CameraType=Enum.CameraType.Scriptable;cam.CFrame=cf;ready=true
        if jBase then jBase.Visible=false end
    end,
    function()
        camOn=false;ready=false;lockChar(false)
        pcall(function()SG:SetCoreGuiEnabled(Enum.CoreGuiType.TouchGui,true)end)
        cam.CameraType=Enum.CameraType.Custom
        local ch=plr.Character;if ch then cam.CameraSubject=ch:FindFirstChildOfClass("Humanoid") or ch end
        cam.FieldOfView=70;mv=Vector2.zero;if jBase then jBase.Visible=false end
    end
)

mkLine(116)
local sep=Instance.new("TextLabel",panel)
sep.Size=UDim2.new(1,-16,0,14);sep.Position=UDim2.new(0,12,0,120);sep.BackgroundTransparency=1
sep.Text="⚙  SETTINGS";sep.TextColor3=Color3.fromRGB(60,80,120);sep.Font=Enum.Font.GothamBold
sep.TextSize=10;sep.TextXAlignment=Enum.TextXAlignment.Left

mkSlider("⚡ SPEED",       136,SPEED, 2,   60,  2,    Color3.fromRGB(0,210,255), function(v)SPEED=v  end)
mkSlider("🎯 SENSITIVITY", 172,SENS,  0.02,0.5, 0.02, Color3.fromRGB(255,165,0), function(v)SENS=v   end)
mkSlider("〰 SMOOTH",      208,SMOOTH,1,   20,  1,    Color3.fromRGB(40,210,100),function(v)SMOOTH=v end)

mkLine(244)

-- ===== FOV PANEL แนวตั้ง แยกอิสระ =====
local fovPanel=Instance.new("Frame",sg)
fovPanel.Size=UDim2.fromOffset(58,220);fovPanel.Position=UDim2.new(0,80,0.5,-110)
fovPanel.BackgroundColor3=BG;fovPanel.BorderSizePixel=0;fovPanel.Visible=false
Instance.new("UICorner",fovPanel).CornerRadius=UDim.new(0,14)
local fps=Instance.new("UIStroke",fovPanel);fps.Color=PURP;fps.Thickness=1.5

local fg={}
fovPanel.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        fg.on=true;fg.s=i.Position;fg.o=fovPanel.Position end
end)
UIS.InputChanged:Connect(function(i)
    if fg.on and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
        local d=i.Position-fg.s;fovPanel.Position=UDim2.new(fg.o.X.Scale,fg.o.X.Offset+d.X,fg.o.Y.Scale,fg.o.Y.Offset+d.Y) end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then fg.on=false end
end)

local fLbl=Instance.new("TextLabel",fovPanel)
fLbl.Size=UDim2.new(1,0,0,26);fLbl.Position=UDim2.new(0,0,0,4);fLbl.BackgroundTransparency=1
fLbl.Text="FOV";fLbl.TextColor3=PURP;fLbl.Font=Enum.Font.GothamBold;fLbl.TextSize=12

local fBadge=Instance.new("TextLabel",fovPanel)
fBadge.Size=UDim2.fromOffset(44,20);fBadge.Position=UDim2.new(0.5,-22,0,28)
fBadge.BackgroundColor3=ROW;fBadge.BackgroundTransparency=0;fBadge.TextColor3=PURP
fBadge.Font=Enum.Font.GothamBold;fBadge.TextSize=11;fBadge.BorderSizePixel=0
Instance.new("UICorner",fBadge).CornerRadius=UDim.new(0,5)

local fPlus=Instance.new("TextButton",fovPanel)
fPlus.Size=UDim2.new(1,-8,0,30);fPlus.Position=UDim2.new(0,4,0,52)
fPlus.BackgroundColor3=ROW;fPlus.Text="＋";fPlus.TextColor3=PURP
fPlus.Font=Enum.Font.GothamBold;fPlus.TextSize=18;fPlus.BorderSizePixel=0;fPlus.AutoButtonColor=false
Instance.new("UICorner",fPlus).CornerRadius=UDim.new(0,8)
Instance.new("UIStroke",fPlus).Color=PURP

local fTrack=Instance.new("Frame",fovPanel)
fTrack.Size=UDim2.new(0,8,0,68);fTrack.Position=UDim2.new(0.5,-4,0,88)
fTrack.BackgroundColor3=Color3.fromRGB(30,38,60);fTrack.BorderSizePixel=0
Instance.new("UICorner",fTrack).CornerRadius=UDim.new(1,0)

local fFill=Instance.new("Frame",fTrack)
fFill.AnchorPoint=Vector2.new(0,1);fFill.Position=UDim2.new(0,0,1,0)
fFill.BackgroundColor3=PURP;fFill.BorderSizePixel=0;fFill.Size=UDim2.new(1,0,0.5,0)
Instance.new("UICorner",fFill).CornerRadius=UDim.new(1,0)

local fThumb=Instance.new("Frame",fTrack)
fThumb.Size=UDim2.fromOffset(18,18);fThumb.AnchorPoint=Vector2.new(0.5,0.5)
fThumb.BackgroundColor3=PURP;fThumb.BorderSizePixel=0
Instance.new("UICorner",fThumb).CornerRadius=UDim.new(1,0)
Instance.new("UIStroke",fThumb).Color=Color3.fromRGB(10,14,24)

local fHit=Instance.new("TextButton",fovPanel)
fHit.Size=UDim2.new(1,0,0,88);fHit.Position=UDim2.new(0,0,0,80)
fHit.BackgroundTransparency=1;fHit.Text="";fHit.AutoButtonColor=false

local fMinus=Instance.new("TextButton",fovPanel)
fMinus.Size=UDim2.new(1,-8,0,30);fMinus.Position=UDim2.new(0,4,0,162)
fMinus.BackgroundColor3=ROW;fMinus.Text="－";fMinus.TextColor3=PURP
fMinus.Font=Enum.Font.GothamBold;fMinus.TextSize=18;fMinus.BorderSizePixel=0;fMinus.AutoButtonColor=false
Instance.new("UICorner",fMinus).CornerRadius=UDim.new(0,8)
Instance.new("UIStroke",fMinus).Color=PURP

local fovV=70
local function fRef()
    local p=math.clamp((fovV-10)/110,0,1)
    fFill.Size=UDim2.new(1,0,p,0);fThumb.Position=UDim2.new(0.5,0,1-p,0)
    fBadge.Text=tostring(math.floor(fovV+0.5)).."°";cam.FieldOfView=fovV
end
local function fFromI(i)
    local p=math.clamp((i.Position.Y-fTrack.AbsolutePosition.Y)/fTrack.AbsoluteSize.Y,0,1)
    fovV=math.clamp(10+110*(1-p),10,120);fRef()
end
local fSld=false
fHit.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then fSld=true;fFromI(i) end
end)
UIS.InputChanged:Connect(function(i)
    if fSld and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then fFromI(i) end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then fSld=false end
end)
fPlus.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then fovV=math.min(120,fovV+5);fRef() end
end)
fMinus.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then fovV=math.max(10,fovV-5);fRef() end
end)

mkToggle("🔭  FOV Override","ปรับ Field of View",248,
    function() fovPanel.Visible=true end,
    function() fovPanel.Visible=false;cam.FieldOfView=70 end
)

-- ===== ปุ่ม W =====
local wBtn=Instance.new("TextButton",sg)
wBtn.Size=UDim2.fromOffset(42,42);wBtn.Position=UDim2.new(0,24,0.5,-21)
wBtn.BackgroundColor3=Color3.fromRGB(0,0,0);wBtn.Text="";wBtn.BorderSizePixel=0;wBtn.AutoButtonColor=false
Instance.new("UICorner",wBtn).CornerRadius=UDim.new(1,0)
local wLbl=Instance.new("TextLabel",wBtn)
wLbl.Size=UDim2.new(1,0,1,0);wLbl.BackgroundTransparency=1;wLbl.Text="W";wLbl.TextColor3=CYAN
wLbl.Font=Enum.Font.GothamBlack;wLbl.TextSize=18
local wsk=Instance.new("UIStroke",wLbl);wsk.Color=CYAN;wsk.Thickness=1.5;wsk.ApplyStrokeMode=Enum.ApplyStrokeMode.Content

local wd={}
wBtn.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        wd.on=true;wd.s=i.Position;wd.o=wBtn.Position;wd.mv=false end
end)
UIS.InputChanged:Connect(function(i)
    if wd.on and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
        local d=i.Position-wd.s;if d.Magnitude>6 then wd.mv=true end
        wBtn.Position=UDim2.new(wd.o.X.Scale,wd.o.X.Offset+d.X,wd.o.Y.Scale,wd.o.Y.Offset+d.Y) end
end)
wBtn.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        if not wd.mv then panVis=not panVis;panel.Visible=panVis end
        wd.on=false;wd.mv=false end
end)

-- ===== JOYSTICK =====
local JD=JR*2
jBase=Instance.new("Frame",sg)
jBase.Size=UDim2.fromOffset(JD+20,JD+20);jBase.BackgroundColor3=Color3.fromRGB(255,255,255)
jBase.BackgroundTransparency=0.92;jBase.BorderSizePixel=0;jBase.Visible=false
Instance.new("UICorner",jBase).CornerRadius=UDim.new(0.5,0)
jKnob=Instance.new("Frame",jBase)
jKnob.Size=UDim2.fromOffset(JR,JR);jKnob.Position=UDim2.new(0.5,-JR/2,0.5,-JR/2)
jKnob.BackgroundColor3=BLUE;jKnob.BackgroundTransparency=0.82;jKnob.BorderSizePixel=0
Instance.new("UICorner",jKnob).CornerRadius=UDim.new(0.5,0)

local function jStart(pos) jOn=true;jBase.Position=UDim2.new(0,pos.X-(JD+20)/2,0,pos.Y-(JD+20)/2);jCen=Vector2.new(pos.X,pos.Y);jBase.Visible=true end
local function jMove(pos)
    if not jOn then return end
    local d=Vector2.new(pos.X-jCen.X,pos.Y-jCen.Y);local dist=math.min(d.Magnitude,JR)
    local dir=d.Magnitude>0 and d.Unit or Vector2.zero
    jKnob.Position=UDim2.new(0.5,(dir*dist).X-JR/2,0.5,(dir*dist).Y-JR/2);mv=dir*(dist/JR)
end
local function jEnd() jOn=false;jTid=nil;mv=Vector2.zero;jKnob.Position=UDim2.new(0.5,-JR/2,0.5,-JR/2);jBase.Visible=false end

UIS.TouchStarted:Connect(function(inp,_)
    if not camOn then return end
    if inp.Position.X<cam.ViewportSize.X/2 then
        if not jOn then jTid=inp;jStart(inp.Position) end
    else
        if not rOn then rOn=true;rTid=inp end
    end
end)
UIS.TouchMoved:Connect(function(inp)
    if not camOn then return end
    if inp==jTid then jMove(inp.Position)
    elseif inp==rTid and rOn then
        tRY=tRY-inp.Delta.X*SENS;tRX=math.clamp(tRX-inp.Delta.Y*SENS,-85,85) end
end)
UIS.TouchEnded:Connect(function(inp)
    if inp==jTid then jEnd() end;if inp==rTid then rOn=false;rTid=nil end
end)

print("✅ FreeCamPro v3 โหลดสำเร็จ")
