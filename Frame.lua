local _, Maps = ...

-- Alpha chrome surrounds the existing map. Its canvas and data providers stay
-- owned by Blizzard and the addons which created them.
function Maps:UseCustomFrame()
    return PatchTools and PatchTools.isClassicEra and self.db.customFrame
        and not (self.map.IsMaximized and self.map:IsMaximized())
end

local function Allowed(frame)
    return (type(frame)=="table" or type(frame)=="userdata") and type(frame.GetNumPoints)=="function"
        and not (type(frame.IsProtected)=="function" and frame:IsProtected())
end
local function Snapshot(frame)
    local entry={frame=frame,parent=frame:GetParent(),points={},scale=frame:GetScale()}
    for i=1,frame:GetNumPoints() do entry.points[i]={frame:GetPoint(i)} end
    return entry
end
local function Restore(entry)
    local frame=entry.frame
    frame:SetParent(entry.parent)
    frame:SetScale(entry.scale)
    frame:ClearAllPoints()
    for _,point in ipairs(entry.points) do frame:SetPoint(unpack(point)) end
end

-- Addons may register an existing unprotected widget. Never clone its click
-- handlers, change its visibility preference, or move map pins into the dock.
-- Slots: buttons, info-left, info-right.
function Maps:RegisterFrameWidget(id,frame,slot)
    if type(id)~="string" or id=="" or not Allowed(frame) then return false end
    if slot~="buttons" and slot~="info-left" and slot~="info-right" then return false end
    self.frameWidgets=self.frameWidgets or {}
    for _,entry in ipairs(self.frameWidgets) do
        if entry.frame==frame then return entry.id==id end
        if entry.id==id then return false end
    end
    self.frameWidgets[#self.frameWidgets+1]={id=id,frame=frame,slot=slot}
    return true
end

function Maps:DiscoverFrameWidgets()
    if not LibStub then return end
    local buttons=LibStub("Krowi_WorldMapButtons-1.4",true)
    if buttons and type(buttons.Buttons)=="table" then
        for _,button in ipairs(buttons.Buttons) do
            -- The library sometimes includes Blizzard's overlay buttons.
            -- Adopt only its own named buttons and ATT's standalone fallback.
            local name=button:GetName()
            if type(name)=="string" and name:match("^Krowi_WorldMapButtons%d+$") then
                self:RegisterFrameWidget(name,button,"buttons")
            end
        end
        if self.buttonLibrary~=buttons and type(buttons.SetPoints)=="function" then
            self.buttonLibrary=buttons
            hooksecurefunc(buttons,"SetPoints",function() self:LayoutCustomFrame() end)
        end
    end
    if _G["AllTheThings-WorldMap"] then
        self:RegisterFrameWidget("ATT",_G["AllTheThings-WorldMap"],"buttons")
    end
    local ace=LibStub("AceAddon-3.0",true)
    local silver=ace and ace:GetAddon("SilverDragon",true)
    local ldb=silver and silver:GetModule("LDB",true)
    if ldb and ldb.worldmap then self:RegisterFrameWidget("SilverDragon",ldb.worldmap,"buttons") end
end

function Maps:InstallCustomFrame(map)
    if not (PatchTools and PatchTools.isClassicEra) then return end
    local frame=CreateFrame("Frame",nil,map,"BackdropTemplate")
    self.customFrame=frame
    frame:Hide()
    frame:SetAllPoints(map)
    frame:SetFrameLevel(map:GetFrameLevel()+1)
    frame:EnableMouse(false)
    frame:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=16,
        insets={left=4,right=4,top=4,bottom=4}})
    frame:SetBackdropColor(.055,.045,.035,1)
    frame:SetBackdropBorderColor(.65,.49,.27,1)
    local header=CreateFrame("Button",nil,frame)
    header:SetPoint("TOPLEFT",8,-5); header:SetPoint("TOPRIGHT",-70,-5)
    header:SetHeight(25); header:RegisterForDrag("LeftButton")
    self.customHeader=header
    frame.title=header:CreateFontString(nil,"OVERLAY","GameFontNormal")
    frame.title:SetPoint("CENTER"); frame.title:SetText("PatchToolsMaps")
    local dock=CreateFrame("Frame",nil,frame)
    dock:SetPoint("TOPLEFT",10,-31); dock:SetPoint("TOPRIGHT",-10,-31); dock:SetHeight(36)
    dock:SetFrameLevel(map:GetFrameLevel()+20)
    frame.buttons=dock
    local footer=CreateFrame("Frame",nil,frame)
    footer:SetPoint("BOTTOMLEFT",12,9); footer:SetPoint("BOTTOMRIGHT",-24,9); footer:SetHeight(42)
    footer:SetFrameLevel(map:GetFrameLevel()+20)
    frame.footer=footer
    frame.coordinates=footer:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    frame.coordinates:SetPoint("TOPLEFT",0,0); frame.coordinates:SetPoint("TOPRIGHT",0,0)
    frame.coordinates:SetJustifyH("LEFT")
    self.frameControls={}
    for _,control in ipairs({WorldMapFrameCloseButton,map.MaximizeMinimizeFrame}) do
        if Allowed(control) then self.frameControls[#self.frameControls+1]=Snapshot(control) end
    end
    self.frameArt={}
    for _,region in pairs({MiniBorderLeft,MiniBorderRight,MiniWorldMapTitle}) do
        if region and type(region.GetAlpha)=="function" then
            self.frameArt[#self.frameArt+1]={region=region,alpha=region:GetAlpha()}
        end
    end
    -- Read-only coordinate updates; never change another addon's options.
    local elapsedTotal=0
    frame:SetScript("OnUpdate",function(_,elapsed)
        elapsedTotal=elapsedTotal+elapsed
        if elapsedTotal<.15 then return end
        elapsedTotal=0
        self:UpdateFrameCoordinates()
    end)
end

function Maps:UpdateFrameCoordinates()
    local frame=self.customFrame
    if not frame or not self:UseCustomFrame() then return end
    local info=C_Map.GetMapInfo and C_Map.GetMapInfo(self.map:GetMapID())
    frame.title:SetText(info and info.name or WORLD_MAP or "PatchToolsMaps")
    local player,cursor="—","—"
    local playerMap=C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local position=playerMap and C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(playerMap,"player")
    if position then
        local x,y=position:GetXY()
        if x and y then
            local zone=C_Map.GetMapInfo(playerMap)
            player=string.format("%.1f, %.1f",x*100,y*100)
            if playerMap~=self.map:GetMapID() and zone then player=player.." ("..zone.name..")" end
        end
    end
    local scroll=self.map.ScrollContainer
    if scroll and scroll:IsMouseOver() and type(scroll.GetNormalizedCursorPosition)=="function" then
        local x,y=scroll:GetNormalizedCursorPosition()
        if x and y and x>=0 and x<=1 and y>=0 and y<=1 then cursor=string.format("%.1f, %.1f",x*100,y*100) end
    end
    frame.coordinates:SetText(self:T("FRAME_COORDS",player,cursor))
end

function Maps:LayoutCustomFrame()
    if not self.customFrame or self.layingOutFrame or (InCombatLockdown and InCombatLockdown()) then return end
    self.layingOutFrame=true
    local enabled=self:UseCustomFrame()
    self.customFrame:SetShown(enabled)
    for _,entry in ipairs(self.frameArt) do entry.region:SetAlpha(enabled and 0 or entry.alpha) end
    if enabled then
        for _,entry in ipairs(self.frameControls) do
            entry.frame:SetScale(1); entry.frame:ClearAllPoints()
            entry.frame:SetPoint("TOPRIGHT",self.map,"TOPRIGHT",entry.frame==WorldMapFrameCloseButton and -4 or -35,-3)
        end
        self.customControlsPlaced=true
    elseif self.customControlsPlaced then
        for _,entry in ipairs(self.frameControls) do
            Restore(entry)
            local maximized=self.map.IsMaximized and self.map:IsMaximized()
            entry.frame:SetScale(entry.scale*(maximized and 1 or self.db.scale))
        end
        self.customControlsPlaced=nil
    end
    local index,left,right=0,0,0
    for _,entry in ipairs(self.frameWidgets or {}) do
        if Allowed(entry.frame) then
            if enabled then
                entry.original=entry.original or Snapshot(entry.frame)
                local widget=entry.frame
                widget:SetScale(1)
                widget:SetParent(entry.slot=="buttons" and self.customFrame.buttons or self.customFrame.footer)
                widget:ClearAllPoints()
                if entry.slot=="buttons" then
                    local width=math.max(20,widget:GetWidth())
                    widget:SetPoint("LEFT",self.customFrame.buttons,"LEFT",index,0)
                    if widget:IsShown() then index=index+width+6 end
                elseif entry.slot=="info-left" then
                    widget:SetPoint("BOTTOMLEFT",self.customFrame.footer,"BOTTOMLEFT",left,0)
                    if widget:IsShown() then left=left+widget:GetWidth()+8 end
                else
                    widget:SetPoint("BOTTOMRIGHT",self.customFrame.footer,"BOTTOMRIGHT",-right,0)
                    if widget:IsShown() then right=right+widget:GetWidth()+8 end
                end
            elseif entry.original then Restore(entry.original); entry.original=nil end
        end
    end
    if enabled then self:UpdateFrameCoordinates() end
    self.layingOutFrame=nil
end
