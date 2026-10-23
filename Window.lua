local _, Maps = ...
function Maps:CanChangeWindow()
    return self.map and not (InCombatLockdown and InCombatLockdown())
        and not (self.map.IsMaximized and self.map:IsMaximized())
end
function Maps:SavePosition()
    local map=self.map
    local left,top=map:GetLeft(),map:GetTop()
    if not left or not top then return end
    local ratio=map:GetEffectiveScale()/UIParent:GetEffectiveScale()
    self.db.x=left*ratio/UIParent:GetWidth()
    self.db.y=top*ratio/UIParent:GetHeight()
end
function Maps:ApplyWindow()
    if not self:CanChangeWindow() then return end
    local map=self.map
    map:SetScale(self.originalScale*self.db.scale)
    if self.db.x and self.db.y then
        local ratio=UIParent:GetEffectiveScale()/map:GetEffectiveScale()
        map:ClearAllPoints()
        map:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",self.db.x*UIParent:GetWidth()*ratio,self.db.y*UIParent:GetHeight()*ratio)
    end
    map:SetClampedToScreen(false)
    if self.ownsDragBar then self.dragBar:SetShown(self.db.movable) end
    self.resizeGrip:SetShown(self.db.resizable)
end
function Maps:ResetWindow()
    self.db.scale,self.db.x,self.db.y=1,nil,nil
    if not self:CanChangeWindow() then self.resetPending=true; return end
    self.resetPending=nil
    local map=self.map
    map:SetScale(self.originalScale)
    map:ClearAllPoints()
    if PatchTools and PatchTools.isClassicEra then
        -- Era's native title drag can also move its persistent screen anchor.
        -- Restore the native default even if that anchor was left off-screen.
        if WorldMapScreenAnchor then
            WorldMapScreenAnchor:ClearAllPoints()
            WorldMapScreenAnchor:SetPoint("TOPLEFT",UIParent,"TOPLEFT",16,-104)
        end
        map:SetPoint("TOPLEFT",UIParent,"TOPLEFT",16,-104)
    else
        for _,point in ipairs(self.originalPoints) do map:SetPoint(unpack(point)) end
    end
    self:ApplyWindow()
end
function Maps:ResetMap()
    self.closeAfterReset=self.map and self.map:IsShown() or nil
    self.extraZoomScale=nil
    self.zoomPending=true
    self.resetViewPending=true
    self.moving=nil
    if self.moveDriver then self.moveDriver:SetScript("OnUpdate",nil) end
    if self.resizeGrip then self.resizeGrip:SetScript("OnUpdate",nil) end
    self:ResetWindow()
    self:Refresh()
end
function Maps:InstallWindow(map)
    self.originalScale=map:GetScale()
    self.originalPoints={}
    for i=1,map:GetNumPoints() do self.originalPoints[i]={map:GetPoint(i)} end
    local bar=WorldMapTitleButton
    self.ownsDragBar=bar==nil
    if not bar then
        -- Invisible hit area on the existing header; no label or painted bar.
        bar=CreateFrame("Button",nil,map)
        bar:SetPoint("TOPLEFT",map,"TOPLEFT",80,-2)
        bar:SetPoint("TOPRIGHT",map,"TOPRIGHT",-100,-2)
        bar:SetHeight(19)
        bar:RegisterForDrag("LeftButton")
    end
    self.dragBar=bar
    self.moveDriver=CreateFrame("Frame",nil,map)
    local driver=self.moveDriver
    local function Start()
        if not self:CanChangeWindow() or not self.db.movable then return end
        if map.StopMovingOrSizing then map:StopMovingOrSizing() end
        self:SavePosition()
        local x,y=GetCursorPosition()
        local startX,startY=self.db.x,self.db.y
        if not startX or not startY then return end
        self.moving=true
        driver:SetScript("OnUpdate",function()
            if not self:CanChangeWindow() then driver:SetScript("OnUpdate",nil); self.moving=nil; return end
            local cx,cy=GetCursorPosition()
            local scale=UIParent:GetEffectiveScale()
            self.db.x=startX+(cx-x)/scale/UIParent:GetWidth()
            self.db.y=startY+(cy-y)/scale/UIParent:GetHeight()
            self:ApplyWindow()
        end)
    end
    bar:HookScript("OnDragStart",Start)
    local function Stop()
        if not self.moving then return end
        self.moving=nil
        driver:SetScript("OnUpdate",nil)
        self:ApplyWindow()
    end
    bar:HookScript("OnDragStop",Stop)
    local grip=CreateFrame("Button",nil,map)
    self.resizeGrip=grip
    grip:Hide()
    grip:SetPoint("BOTTOMRIGHT",map,"BOTTOMRIGHT",2,-2)
    grip:SetSize(20,20); grip:SetFrameLevel(map:GetFrameLevel()+10)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetScript("OnEnter",function()
        if GameTooltip then GameTooltip:SetOwner(grip,"ANCHOR_RIGHT"); GameTooltip:SetText(self:T("SIZE_DRAG")); GameTooltip:Show() end
    end)
    grip:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    grip:SetScript("OnMouseDown",function(_,button)
        if button~="LeftButton" or not self:CanChangeWindow() or not self.db.resizable then return end
        self:SavePosition()
        local x,y=GetCursorPosition()
        local start=self.db.scale
        local width=map:GetWidth()*map:GetEffectiveScale()
        local height=map:GetHeight()*map:GetEffectiveScale()
        grip:SetScript("OnUpdate",function()
            if not self:CanChangeWindow() then grip:SetScript("OnUpdate",nil); return end
            local cx,cy=GetCursorPosition()
            local delta=((cx-x)*width+(y-cy)*height)/(width*width+height*height)
            self.db.scale=math.max(.6,start*(1+delta))
            self:ApplyWindow()
        end)
    end)
    grip:SetScript("OnMouseUp",function() grip:SetScript("OnUpdate",nil) end)
    map:HookScript("OnHide",function() Stop(); self.extraZoomScale=nil; grip:SetScript("OnUpdate",nil) end)
    map:HookScript("OnShow",function()
        C_Timer.After(0,function() if map:IsShown() then self:Refresh() end end)
    end)
    for _,method in ipairs({"Maximize","Minimize"}) do
        if type(map[method])=="function" then hooksecurefunc(map,method,function()
            local maximized=map.IsMaximized and map:IsMaximized()
            if self.ownsDragBar then bar:SetShown(not maximized and self.db.movable) end
            grip:SetShown(not maximized and self.db.resizable)
            if maximized then
                if not (InCombatLockdown and InCombatLockdown()) then map:SetScale(self.originalScale) end
            else self:Refresh() end
        end) end
    end
    local scroll=map.ScrollContainer
    self:InstallZoom(scroll)
    if scroll and type(scroll.CreateZoomLevels)=="function" then
        hooksecurefunc(scroll,"CreateZoomLevels",function()
            self:RefreshReveal()
        end)
    end
end
