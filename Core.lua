local addon, Maps = ...
local events=CreateFrame("Frame")
for _,event in ipairs({"ADDON_LOADED","PLAYER_REGEN_ENABLED","PLAYER_REGEN_DISABLED","MAP_EXPLORATION_UPDATED","DISPLAY_SIZE_CHANGED"}) do
    events:RegisterEvent(event)
end
function Maps:Refresh(rebuildZoom)
    if rebuildZoom then self.zoomPending=true end
    if not self.map then self:Attach(); return end
    if self.customFrame and not (InCombatLockdown and InCombatLockdown()) then self:DiscoverFrameWidgets() end
    if self.resetPending then self:ResetWindow() else self:ApplyWindow() end
    if self.zoomPending and not (InCombatLockdown and InCombatLockdown()) and self.map:IsShown()
        and self.map.ScrollContainer and type(self.map.ScrollContainer.zoomLevels)=="table"
        and #self.map.ScrollContainer.zoomLevels>0 then
        self.zoomPending=nil
    end
    if self.resetViewPending and not self.zoomPending and self:CanChangeWindow() and self.map:IsShown()
        and self:GetReadyLayerIndex() then
        local scroll=self.map.ScrollContainer
        if scroll and type(scroll.ResetZoom)=="function" then
            if securecallfunction then securecallfunction(scroll.ResetZoom,scroll,true)
            else scroll:ResetZoom(true) end
            self.resetViewPending=nil
        end
    end
    if self.closeAfterReset and not (InCombatLockdown and InCombatLockdown()) then
        self.closeAfterReset=nil
        if self.map:IsShown() then
            if HideUIPanel then
                if securecallfunction then securecallfunction(HideUIPanel,self.map) else HideUIPanel(self.map) end
            else self.map:Hide() end
        end
    end
    self:RefreshReveal()
    self:UpdateOptions()
end
function Maps:Attach()
    if self.map or (InCombatLockdown and InCombatLockdown()) or not WorldMapFrame or not WorldMapFrame.GetCanvas then return end
    self.map=WorldMapFrame
    self:InstallCustomFrame(self.map)
    self:InstallWindow(self.map)
    local function Reveal() self.extraZoomScale=nil; self:RefreshReveal() end
    for _,method in ipairs({"OnMapChanged","OnCanvasSizeChanged"}) do
        if type(self.map[method])=="function" then hooksecurefunc(self.map,method,Reveal) end
    end
    if self.customFrame and type(self.map.OnMapChanged)=="function" then
        hooksecurefunc(self.map,"OnMapChanged",function()
            C_Timer.After(0,function()
                if self:UseCustomFrame() and self.map:IsShown() then self:Refresh() end
            end)
        end)
    end
    if type(self.map.RefreshMaskableTextures)=="function" then
        hooksecurefunc(self.map,"RefreshMaskableTextures",function() self:UpdateRevealMasks() end)
    end
    if type(self.map.OnCanvasScaleChanged)=="function" then
        local lastLayer
        hooksecurefunc(self.map,"OnCanvasScaleChanged",function()
            local layer=self:GetReadyLayerIndex()
            if layer and layer~=lastLayer then lastLayer=layer; Reveal() end
        end)
    end
    if self.map:IsShown() then self:Refresh(true) end
end
function Maps:Initialize()
    if self.initialized then return end
    local PT=_G.PatchTools
    if not PT or not PT.extensionAPI or PT.extensionAPI<1 then
        print("PatchToolsMaps: "..self:T("API")); return
    end
    if type(PatchToolsMapsDB)~="table" then PatchToolsMapsDB={} end
    self.db=PatchToolsMapsDB
    for key,value in pairs({movable=true,resizable=true,extendedZoom=true,scale=1,mode="mist"}) do
        if type(self.db[key])~=type(value) then self.db[key]=value end
    end
    if type(self.db.customFrame)~="boolean" then self.db.customFrame=PT.isClassicEra==true end
    if self.db.mode~="classic" and self.db.mode~="mist" and self.db.mode~="full" then self.db.mode="mist" end
    local scale=self.db.scale
    self.db.scale=scale==scale and scale<math.huge and math.max(.6,scale) or 1
    for _,key in ipairs({"x","y"}) do
        local value=self.db[key]
        if type(value)~="number" or value~=value or math.abs(value)==math.huge then self.db[key]=nil end
    end
    if not self.db.x or not self.db.y then self.db.x,self.db.y=nil,nil end
    if type(self.db.knownOverlays)~="table" then self.db.knownOverlays={} end
    for key,value in pairs(self.db.knownOverlays) do
        if type(value)~="table" then self.db.knownOverlays[key]=nil end
    end
    self.initialized=PT:RegisterOptionsPage("maps",self:T("TITLE"),function(parent) self:BuildOptions(parent) end)
    if self.initialized then
        SLASH_PATCHTOOLSMAPS1="/ptmaps"
        SLASH_PATCHTOOLSMAPS2="/patchtoolsmaps"
        SlashCmdList.PATCHTOOLSMAPS=function(message)
            if (message or ""):lower():match("^%s*status%s*$") then
                self:PrintZoomStatus()
            elseif (message or ""):lower():match("^%s*reset%s*$") then
                self:ResetMap()
                PT:Print(self:T(InCombatLockdown and InCombatLockdown() and "RESET_PENDING" or "RESET_DONE"))
            else PT:OpenOptions(); PT:SelectOptionsPage("maps") end
        end
        self:Attach()
    end
end
events:SetScript("OnEvent",function(_,event,name)
    if event=="ADDON_LOADED" and name==addon then Maps:Initialize()
    elseif Maps.initialized then
        if event=="PLAYER_REGEN_DISABLED" then
            if Maps.resizeGrip then
                Maps:FinishResize()
                Maps.moveDriver:SetScript("OnUpdate",nil); Maps.moving=nil; Maps.extraZoomScale=nil
            end
        elseif event=="ADDON_LOADED" then
            Maps:Attach()
            if Maps.customFrame and not (InCombatLockdown and InCombatLockdown()) then
                Maps:DiscoverFrameWidgets(); Maps:LayoutCustomFrame()
            end
        elseif event=="PLAYER_REGEN_ENABLED" or event=="DISPLAY_SIZE_CHANGED" then Maps:Refresh()
        elseif event=="MAP_EXPLORATION_UPDATED" then Maps:RefreshReveal() end
    end
end)
