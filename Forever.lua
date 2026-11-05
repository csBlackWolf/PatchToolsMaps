local _, Maps = ...

local function Frame(value)
    return (type(value)=="table" or type(value)=="userdata") and type(value.GetNumPoints)=="function"
end
local function Capture(frame)
    if not Frame(frame) then return end
    local result={frame=frame,points={},width=frame:GetWidth(),height=frame:GetHeight()}
    for i=1,frame:GetNumPoints() do result.points[i]={frame:GetPoint(i)} end
    return result
end
local function Restore(entry)
    if not entry then return end
    entry.frame:SetSize(entry.width,entry.height)
    entry.frame:ClearAllPoints()
    for _,point in ipairs(entry.points) do entry.frame:SetPoint(unpack(point)) end
end

function Maps:InstallForeverFrame(map)
    local border=map.BorderFrame
    if not Frame(border) then return end
    self.foreverFrame={border=border,alpha=border:GetAlpha(),mouse=border:IsMouseEnabled(),
        scroll=Capture(map.ScrollContainer),nav=Capture(map.NavBar),quest=Capture(map.QuestLog)}
    self.foreverFrame.masked={}
    self.foreverFrame.panels={}
    self.foreverFrame.buttons={}
    -- These are native map controls, separate from the addon toolbar. Keep
    -- their original map parent: native callbacks use GetParent() as the map.
    self.foreverFrame.controls={}
    for _,key in ipairs({"WorldMapTrackingOptionsButton","WorldMapTrackingPinButton","SidePanelToggle"}) do
        local entry=Capture(map[key])
        if entry then self.foreverFrame.controls[key]=entry end
    end
    local quest=map.QuestLog
    local details=Frame(quest) and quest.DetailsFrame
    if Frame(details) then
        self.foreverFrame.details=Capture(details)
        self.foreverFrame.detailsScroll=Capture(details.ScrollFrame)
    end
    self.foreverFrame.textColors={}
    local maximize=border.MaximizeMinimizeFrame
    if Frame(maximize) then
        self.foreverFrame.maximize=Capture(maximize)
        self.foreverFrame.maximize.parent=maximize:GetParent()
    end
    -- Native display-state changes reset both the window position and canvas
    -- anchors, including when only the quest-log side panel is toggled.
    if type(map.UpdateSpacerFrameAnchoring)=="function" then
        hooksecurefunc(map,"UpdateSpacerFrameAnchoring",function()
            if not self.layingOutFrame then self:Refresh() end
        end)
    end
end

function Maps:LayoutForeverFrame(enabled)
    local native=self.foreverFrame
    local map=self.map
    local wasEnabled=native.enabled
    native.enabled=enabled
    native.border:SetAlpha(enabled and 0 or native.alpha)
    native.border:EnableMouse(not enabled and native.mouse)
    local maximize=native.maximize
    if maximize then
        if enabled then
            maximize.frame:SetParent(self.customFrame)
            maximize.frame:ClearAllPoints()
            maximize.frame:SetPoint("TOPRIGHT",map,"TOPRIGHT",-36,-3)
        elseif wasEnabled then
            maximize.frame:SetParent(maximize.parent); Restore(maximize)
        end
    end
    if enabled then
        -- Keep Blizzard's navigation and quest log functional. The navigation
        -- has its own narrow row; fixed addon controls use our title bar.
        local left,top,right,bottom=self:GetCustomFrameInsets()
        local quest=native.quest and native.quest.frame
        local questWidth=quest and quest:IsShown() and map.questLogWidth or 0
        local scroll=map.ScrollContainer
        scroll:ClearAllPoints()
        scroll:SetPoint("TOPLEFT",map,"TOPLEFT",left,top-28)
        scroll:SetPoint("BOTTOMRIGHT",map,"BOTTOMRIGHT",right-questWidth,bottom)
        if native.nav then
            native.nav.frame:ClearAllPoints()
            native.nav.frame:SetPoint("TOPLEFT",map,"TOPLEFT",8,top)
            native.nav.frame:SetPoint("TOPRIGHT",map,"TOPRIGHT",-76-questWidth,top)
            native.nav.frame:SetHeight(28)
            if type(NavBar_CheckLength)=="function" then NavBar_CheckLength(native.nav.frame) end
        end
        if quest then
            quest:ClearAllPoints()
            quest:SetPoint("TOPRIGHT",map,"TOPRIGHT",-4,top)
            quest:SetPoint("BOTTOMRIGHT",map,"BOTTOMRIGHT",-4,bottom)
        end
        -- Filter lives at the right end of the navigation row, immediately
        -- before the search field when the quest log is expanded.
        local filter=native.controls.WorldMapTrackingOptionsButton
        if filter then
            filter.frame:ClearAllPoints()
            filter.frame:SetPoint("TOPRIGHT",scroll,"TOPRIGHT",0,30)
        end
        local pin=native.controls.WorldMapTrackingPinButton
        if pin then
            pin.frame:ClearAllPoints()
            pin.frame:SetPoint("TOPRIGHT",scroll,"TOPRIGHT",-32,30)
        end
        local toggle=native.controls.SidePanelToggle
        if toggle then
            toggle.frame:ClearAllPoints()
            toggle.frame:SetPoint("BOTTOMRIGHT",scroll,"BOTTOMRIGHT",0,0)
        end
        self:LayoutForeverDetails()
    elseif wasEnabled then
        Restore(native.scroll); Restore(native.nav); Restore(native.quest)
        Restore(native.details); Restore(native.detailsScroll)
        for _,entry in pairs(native.controls) do Restore(entry) end
    end
    self:UpdateForeverPresentation()
end

-- Mask only identified presentation, never menu handlers, quest buttons or
-- scroll contents. Keep original alpha values for native/fullscreen mode.
function Maps:MaskForeverRegion(region)
    if (type(region)~="table" and type(region)~="userdata") or type(region.GetAlpha)~="function" then return end
    local masked=self.foreverFrame.masked
    if masked[region]==nil then masked[region]=region:GetAlpha() end
    region:SetAlpha(0)
end

local function TextureRegions(frame,callback)
    if not Frame(frame) or type(frame.GetRegions)~="function" then return end
    for _,region in ipairs({frame:GetRegions()}) do
        if region.IsObjectType and region:IsObjectType("Texture") then callback(region) end
    end
end

function Maps:ForeverPanel(owner)
    local native=self.foreverFrame
    if native.panels[owner] then return native.panels[owner] end
    local panel=CreateFrame("Frame",nil,owner,"BackdropTemplate")
    panel:SetFrameLevel(math.max(0,owner:GetFrameLevel()-1))
    panel:SetPoint("TOPLEFT",owner,"TOPLEFT",1,-1)
    panel:SetPoint("BOTTOMRIGHT",owner,"BOTTOMRIGHT",-1,1)
    panel:EnableMouse(false)
    panel:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=8,
        insets={left=2,right=2,top=2,bottom=2}})
    panel:SetBackdropColor(.055,.045,.035,1)
    panel:SetBackdropBorderColor(.48,.37,.23,1)
    native.panels[owner]=panel
    return panel
end

function Maps:UpdateForeverPresentation()
    local native=self.foreverFrame
    if not native or (InCombatLockdown and InCombatLockdown()) then return end
    if not native.enabled then
        for region,alpha in pairs(native.masked) do region:SetAlpha(alpha) end
        native.masked={}
        for region,color in pairs(native.textColors) do region:SetTextColor(unpack(color)) end
        native.textColors={}
        for _,panel in pairs(native.panels) do panel:Hide() end
        for _,button in pairs(native.buttons) do button:Hide() end
        return
    end
    local function Mask(region) self:MaskForeverRegion(region) end
    -- Blizzard reparents its background out of BorderFrame during OnLoad.
    Mask(native.border.Bg)
    for _,overlay in ipairs(type(self.map.overlayFrames)=="table" and self.map.overlayFrames or {}) do
        if overlay.PlayerCoords and overlay.CursorCoords then Mask(overlay) end
    end
    -- TomTom's frame contains only map coordinate strings. Its saved options,
    -- waypoint pins and tooltips remain owned by TomTom.
    if Frame(TomTomWorldFrame) and TomTomWorldFrame:GetParent()==self.map then Mask(TomTomWorldFrame) end
    local nav=native.nav and native.nav.frame
    if nav then
        TextureRegions(nav,Mask); TextureRegions(nav.overlay,Mask)
        self:ForeverPanel(nav):Show()
        local list=type(nav.navList)=="table" and nav.navList or {}
        for _,button in ipairs(list) do
            TextureRegions(button,Mask)
            local panel=self:ForeverPanel(button)
            panel:Show()
            if button:IsMouseOver() then panel:SetBackdropBorderColor(.85,.65,.25,1)
            else panel:SetBackdropBorderColor(.48,.37,.23,1) end
            if button==nav.homeButton then
                Mask(button.text)
                if not native.buttons[button] then
                    local text=button:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
                    text:SetPoint("CENTER"); text:SetText("‹")
                    native.buttons[button]=text
                end
                native.buttons[button]:Show()
            end
        end
    end
    local quest=native.quest and native.quest.frame
    if quest then
        local quests=quest.QuestsFrame
        local scroll=Frame(quests) and quests.ScrollFrame
        if Frame(scroll) then
            Mask(scroll.Background)
            if Frame(scroll.BorderFrame) then Mask(scroll.BorderFrame.Border) end
            self:ForeverPanel(scroll):Show()
        end
        local details=quest.DetailsFrame
        if Frame(details) then
            Mask(details.Bg)
            if Frame(details.BorderFrame) then Mask(details.BorderFrame.Border) end
            TextureRegions(details.BackFrame,Mask)
            self:LayoutForeverDetails()
            if Frame(details.ScrollFrame) then self:ForeverPanel(details.ScrollFrame):Show() end
            self:StyleForeverQuestText(Frame(details.ScrollFrame) and details.ScrollFrame.Contents)
            local rewards=details.RewardsFrameContainer
            self:StyleForeverQuestText(Frame(rewards) and rewards.RewardsFrame)
        end
    end
end

function Maps:LayoutForeverDetails()
    local native=self.foreverFrame
    if not native.details then return end
    local details=native.details.frame
    local quest=native.quest.frame
    details:ClearAllPoints()
    details:SetPoint("TOPRIGHT",quest,"TOPRIGHT",-18,-1)
    details:SetPoint("BOTTOMRIGHT",quest,"BOTTOMRIGHT",-18,3)
    local height=math.max(100,quest:GetHeight()-4-72)
    if native.detailsScroll and math.abs(native.detailsScroll.frame:GetHeight()-height)>.1 then
        native.detailsScroll.frame:SetHeight(height)
    end
end

function Maps:StyleForeverQuestText(frame,depth)
    depth=depth or 0
    if not Frame(frame) or depth>10 then return end
    if type(frame.GetRegions)=="function" then
        for _,region in ipairs({frame:GetRegions()}) do
            if region.IsObjectType and region:IsObjectType("FontString") and region.GetTextColor then
                local r,g,b,a=region:GetTextColor()
                if type(r)=="number" and math.max(r,g,b)<.6 then
                    if not self.foreverFrame.textColors[region] then
                        self.foreverFrame.textColors[region]={r,g,b,a}
                    end
                    local _,size=region:GetFont()
                    if type(size)=="number" and size>=16 then region:SetTextColor(1,.82,0,a)
                    else region:SetTextColor(.9,.88,.83,a) end
                end
            end
        end
    end
    if type(frame.GetChildren)=="function" then
        for _,child in ipairs({frame:GetChildren()}) do self:StyleForeverQuestText(child,depth+1) end
    end
end
