local _, Maps = ...
Maps.frameWidgetAPI=1

-- Alpha chrome surrounds the existing map. Its canvas and data providers stay
-- owned by Blizzard and the addons which created them.
function Maps:UseCustomFrame()
    return PatchTools and PatchTools.isClassicEra and self.db.customFrame
        and not (self.map.IsMaximized and self.map:IsMaximized())
end

function Maps:GetCustomFrameInsets(width)
    local bottom=24
    -- Reserve another row only when an addon actually registered fixed info.
    for _,entry in ipairs(self.frameWidgets or {}) do
        if entry.slot~="buttons" and entry.frame:IsShown() then
            bottom=math.max(bottom,28+math.min(32,entry.frame:GetHeight()))
        end
    end
    return 4,-36-self:GetToolbarLayout(width).extraHeight,-4,bottom+(self.novaRowHeight or 0)
end

function Maps:GetCustomFrameHeight(width)
    local left,top,right,bottom=self:GetCustomFrameInsets(width)
    local layers=C_Map.GetMapArtLayers(self.map:GetMapID())
    local art=layers and layers[1]
    local ratio=(self.originalHeight-50)/(self.originalWidth-30)
    if art and type(art.layerWidth)=="number" and art.layerWidth>0
        and type(art.layerHeight)=="number" and art.layerHeight>0 then
        ratio=art.layerHeight/art.layerWidth
    end
    -- Keep the viewport in the map art's aspect ratio. A fixed outer-window
    -- ratio plus fixed toolbar heights creates a growing letterbox at fit zoom.
    return (width-left+right)*ratio-top+bottom
end

local function Allowed(frame)
    return (type(frame)=="table" or type(frame)=="userdata") and type(frame.GetNumPoints)=="function"
        and not (type(frame.IsProtected)=="function" and frame:IsProtected())
end
function Maps:GetToolbarLayout(width)
    width=width or self.map:GetWidth()
    local available=math.max(24,width-18)
    local layout={items={},total=0,extraHeight=0,rows=1}
    for _,entry in ipairs(self.frameWidgets or {}) do
        local widget=entry.frame
        if entry.slot=="buttons" and Allowed(widget) and widget:IsShown() then
            local scale=math.min(1,24/math.max(1,widget:GetHeight()),available/math.max(1,widget:GetWidth()))
            local item={scale=scale,width=widget:GetWidth()*scale}
            layout.items[entry]=item
            layout.total=layout.total+item.width+3
        end
    end
    layout.total=math.max(0,layout.total-3)
    layout.stacked=layout.total>math.max(0,width-247)
    local x,row=0,0
    for _,entry in ipairs(self.frameWidgets or {}) do
        local item=layout.items[entry]
        if item then
            if layout.stacked and x>0 and x+item.width>available then x=0; row=row+1 end
            item.x,item.y=x,row*27
            x=x+item.width+3
        end
    end
    layout.rows=row+1
    layout.width=math.max(1,math.min(layout.total,available))
    if layout.stacked then layout.extraHeight=layout.rows*27 end
    return layout
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
function Maps:PositionHeaderTooltip(widget)
    if not self.map or not self:UseCustomFrame() or not GameTooltip
        or not GameTooltip:IsOwned(widget) then return end
    GameTooltip:ClearAllPoints()
    GameTooltip:SetPoint("BOTTOM",widget,"TOP",0,6)
    GameTooltip:SetClampedToScreen(true)
end

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
    self:DiscoverDeathlogControl()
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

function Maps:DiscoverDeathlogControl()
    if not self.map or (InCombatLockdown and InCombatLockdown()) then return end
    local checkbox=_G.DeathlogHeatmapCheckbox
    local container=checkbox and type(checkbox.GetParent)=="function" and checkbox:GetParent()
    -- Deathlog uses the same global name in its own statistics window. Adopt
    -- only the world-map container, never that other checkbox or any heatmap pin.
    if not self.deathlogControl and Allowed(container) and Allowed(checkbox)
        and container:GetParent()==self.map:GetCanvas() and container.heatmap_checkbox==checkbox then
        local control={container=container,checkbox=checkbox}
        local broker=LibStub and LibStub("LibDataBroker-1.1",true)
        local data=broker and broker:GetDataObjectByName("Deathlog")
        local registered,button=self:RegisterMapAction("Deathlog.heatmap",{
            style="minimap",
            icon=data and data.icon or "Interface\\TARGETINGFRAME\\UI-TargetingFrame-Skull",
            tooltip=function()
                return self:T("DEATHLOG_HEATMAP",self:T(checkbox:GetChecked() and "STATE_ON" or "STATE_OFF"))
            end,
            isShown=function() return container:IsShown() and checkbox:IsShown() end,
            isActive=function() return checkbox:GetChecked()==true end,
            onClick=function(_,mouseButton)
                if mouseButton~="LeftButton" or (InCombatLockdown and InCombatLockdown()) then return end
                -- Run Deathlog's current handler; it owns the setting and refresh.
                local click=checkbox:GetScript("OnClick")
                if click then click(checkbox,"LeftButton") end
            end,
        })
        if registered then control.button=button; self.deathlogControl=control end
    end
    self:LayoutDeathlogControl(self:UseCustomFrame())
    self:UpdateMapActions()
end

function Maps:LayoutDeathlogControl(enabled)
    local control=self.deathlogControl
    if not control then return end
    local container,checkbox=control.container,control.checkbox
    if enabled then
        if not control.original then
            control.original={alpha=container:GetAlpha(),mouse=checkbox:IsMouseEnabled()}
        end
        -- Keep Deathlog's native anchors, parent and Show/Hide state untouched.
        container:SetAlpha(0); checkbox:EnableMouse(false)
    elseif control.original then
        container:SetAlpha(control.original.alpha); checkbox:EnableMouse(control.original.mouse)
        control.original=nil
    end
end

function Maps:InstallCustomFrame(map)
    if not (PatchTools and PatchTools.isClassicEra) then return end
    local frame=CreateFrame("Frame",nil,map,"BackdropTemplate")
    self.customFrame=frame
    frame:Hide()
    frame:SetAllPoints(map)
    frame:SetFrameLevel(map:GetFrameLevel()+1)
    frame:EnableMouse(false)
    -- The legacy close control can retain an overlapping mouse region when
    -- the small-map chrome is resized. Use an explicitly sized foreground
    -- control for Modern, forwarding the original close action unchanged.
    local close=CreateFrame("Button",nil,frame)
    self.customCloseButton=close
    close:SetSize(32,32); close:SetScale(1)
    close:SetPoint("TOPRIGHT",map,"TOPRIGHT",-4,-3)
    close:SetFrameLevel(map:GetFrameLevel()+30)
    close:SetFrameStrata("TOOLTIP") -- Above adopted toolbar buttons, including Krowi's Era buttons.
    close:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    close:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    close:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    close:RegisterForClicks("LeftButtonUp")
    close:SetScript("OnClick",function()
        local native=WorldMapFrameCloseButton
        local click=native and native:GetScript("OnClick")
        if click then click(native,"LeftButton")
        elseif HideUIPanel then HideUIPanel(map)
        else map:Hide() end
    end)
    if WorldMapFrameCloseButton then
        self.nativeCloseAppearance={alpha=WorldMapFrameCloseButton:GetAlpha(),mouse=WorldMapFrameCloseButton:IsMouseEnabled()}
    end
    frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=10,
        insets={left=2,right=2,top=2,bottom=2}})
    frame:SetBackdropColor(.055,.045,.035,1)
    frame:SetBackdropBorderColor(.48,.37,.23,1)
    local header=CreateFrame("Button",nil,frame)
    header:SetPoint("TOPLEFT",9,-4)
    header:SetHeight(26); header:RegisterForDrag("LeftButton")
    self.customHeader=header
    header:RegisterForClicks("RightButtonUp")
    header:SetScript("OnClick",function(_,button)
        if button=="RightButton" then self:ToggleOpacityPopup(header) end
    end)
    header:SetScript("OnEnter",function()
        GameTooltip:SetOwner(header,"ANCHOR_TOP"); GameTooltip:SetText(self:T("OPACITY_SHORTCUT")); GameTooltip:Show()
        self:PositionHeaderTooltip(header)
    end)
    header:SetScript("OnLeave",function() GameTooltip:Hide() end)
    header:HookScript("OnDragStart",function() if self.opacityPopup then self.opacityPopup:Hide() end end)
    frame.title=header:CreateFontString(nil,"OVERLAY","GameFontNormal")
    frame.title:SetPoint("LEFT",0,0); frame.title:SetPoint("RIGHT",-4,0)
    frame.title:SetJustifyH("LEFT"); frame.title:SetText("PatchToolsMaps")
    local dock=CreateFrame("Frame",nil,frame)
    dock:SetPoint("TOPRIGHT",map,"TOPRIGHT",-70,-4); dock:SetSize(1,26)
    dock:SetFrameLevel(map:GetFrameLevel()+20)
    frame.buttons=dock
    header:SetPoint("TOPRIGHT",dock,"TOPLEFT",-8,0)
    local footer=CreateFrame("Frame",nil,frame)
    footer:SetPoint("BOTTOMLEFT",9,5); footer:SetPoint("BOTTOMRIGHT",-24,5); footer:SetHeight(14)
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
        local actionsChanged=self:UpdateMapActions()
        if self:UpdateNovaTimers() or actionsChanged then self:Refresh() end
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
    if not enabled and self.opacityPopup then self.opacityPopup:Hide() end
    self:LayoutDeathlogControl(enabled)
    self:UpdateMapActions()
    self:UpdateNovaTimers()
    self.customFrame:SetShown(enabled)
    self.customCloseButton:SetShown(enabled)
    if WorldMapFrameCloseButton and self.nativeCloseAppearance then
        WorldMapFrameCloseButton:SetAlpha(enabled and 0 or self.nativeCloseAppearance.alpha)
        WorldMapFrameCloseButton:EnableMouse(not enabled and self.nativeCloseAppearance.mouse)
    end
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
            entry.frame:SetScale(entry.scale*(maximized and 1 or self.windowDB.scale))
        end
        self.customControlsPlaced=nil
    end
    local toolbar=self:GetToolbarLayout()
    if enabled then
        local _,_,_,bottom=self:GetCustomFrameInsets()
        self.customFrame.footer:SetHeight(bottom-10)
        local dock=self.customFrame.buttons
        dock:ClearAllPoints()
        dock:SetPoint("TOPRIGHT",self.map,"TOPRIGHT",toolbar.stacked and -9 or -70,toolbar.stacked and -30 or -4)
        dock:SetSize(toolbar.width,toolbar.rows*27)
        self.customHeader:ClearAllPoints()
        self.customHeader:SetPoint("TOPLEFT",self.customFrame,"TOPLEFT",9,-4)
        if toolbar.stacked then self.customHeader:SetPoint("TOPRIGHT",self.map,"TOPRIGHT",-70,-4)
        else self.customHeader:SetPoint("TOPRIGHT",dock,"TOPLEFT",-8,0) end
    end
    local left,right=0,0
    for _,entry in ipairs(self.frameWidgets or {}) do
        if Allowed(entry.frame) then
            if enabled then
                entry.original=entry.original or Snapshot(entry.frame)
                local widget=entry.frame
                local item=toolbar.items[entry]
                local scale=item and item.scale or 1
                widget:SetScale(scale)
                widget:SetParent(entry.slot=="buttons" and self.customFrame.buttons or self.customFrame.footer)
                widget:ClearAllPoints()
                if entry.slot=="buttons" then
                    widget:SetPoint("TOPLEFT",self.customFrame.buttons,"TOPLEFT",item and item.x/scale or 0,item and -item.y/scale or 0)
                elseif entry.slot=="info-left" then
                    widget:SetPoint("BOTTOMLEFT",self.customFrame.footer,"BOTTOMLEFT",left,self.novaRowHeight or 0)
                    if widget:IsShown() then left=left+widget:GetWidth()+8 end
                else
                    widget:SetPoint("BOTTOMRIGHT",self.customFrame.footer,"BOTTOMRIGHT",-right,self.novaRowHeight or 0)
                    if widget:IsShown() then right=right+widget:GetWidth()+8 end
                end
            elseif entry.original then Restore(entry.original); entry.original=nil end
        end
    end
    if enabled then self:UpdateFrameCoordinates() end
    self.layingOutFrame=nil
end
