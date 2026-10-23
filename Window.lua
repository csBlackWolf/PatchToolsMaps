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
    map:SetClampedToScreen(true)
    self.dragBar:SetShown(self.db.movable)
    self.resizeGrip:SetShown(self.db.resizable)
end
function Maps:ResetWindow()
    self.db.scale,self.db.x,self.db.y=1,nil,nil
    if not self:CanChangeWindow() then self.resetPending=true; return end
    self.resetPending=nil
    local map=self.map
    map:SetScale(self.originalScale)
    map:ClearAllPoints()
    for _,point in ipairs(self.originalPoints) do map:SetPoint(unpack(point)) end
    self:ApplyWindow()
end
function Maps:ResetMap()
    self.closeAfterReset=self.map and self.map:IsShown() or nil
    self.db.extendedZoom=false
    self.zoomPending=true
    self.resetViewPending=true
    self.moving=nil
    if self.dragBar then self.dragBar:SetScript("OnUpdate",nil) end
    if self.resizeGrip then self.resizeGrip:SetScript("OnUpdate",nil) end
    self:ResetWindow()
    self:Refresh()
end
function Maps:ExtendZoom(scroll)
    local levels=scroll.zoomLevels
    if not self.db.extendedZoom or not levels or #levels==0 then return end
    local last=levels[#levels]
    if last.patchToolsMaps then return end
    levels[#levels+1]={scale=last.scale*2,layerIndex=last.layerIndex,patchToolsMaps=true}
end
function Maps:InstallWindow(map)
    self.originalScale=map:GetScale()
    self.originalPoints={}
    for i=1,map:GetNumPoints() do self.originalPoints[i]={map:GetPoint(i)} end
    local bar=CreateFrame("Button",nil,map)
    self.dragBar=bar
    bar:Hide()
    bar:SetPoint("TOPLEFT",map,"TOPLEFT",100,-2)
    bar:SetPoint("TOPRIGHT",map,"TOPRIGHT",-100,-2)
    bar:SetHeight(19)
    bar:SetFrameLevel(map:GetFrameLevel()+10)
    bar:RegisterForDrag("LeftButton")
    local background=bar:CreateTexture(nil,"BACKGROUND")
    background:SetAllPoints(); background:SetColorTexture(.04,.07,.09,.95)
    local title=bar:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    title:SetAllPoints(); title:SetText(self:T("DRAG"))
    bar:SetScript("OnDragStart",function()
        if not self:CanChangeWindow() or not self.db.movable then return end
        self:SavePosition()
        local x,y=GetCursorPosition()
        local startX,startY=self.db.x,self.db.y
        if not startX or not startY then return end
        self.moving=true
        bar:SetScript("OnUpdate",function()
            if not self:CanChangeWindow() then bar:SetScript("OnUpdate",nil); self.moving=nil; return end
            local cx,cy=GetCursorPosition()
            local scale=UIParent:GetEffectiveScale()
            self.db.x=math.max(0,math.min(1,startX+(cx-x)/scale/UIParent:GetWidth()))
            self.db.y=math.max(0,math.min(1,startY+(cy-y)/scale/UIParent:GetHeight()))
            self:ApplyWindow()
        end)
    end)
    local function Stop()
        if not self.moving then return end
        self.moving=nil
        bar:SetScript("OnUpdate",nil)
    end
    bar:SetScript("OnDragStop",Stop)
    local grip=CreateFrame("Button",nil,map)
    self.resizeGrip=grip
    grip:Hide()
    grip:SetPoint("BOTTOMRIGHT",map,"BOTTOMRIGHT",12,-12)
    grip:SetSize(24,24); grip:SetFrameLevel(map:GetFrameLevel()+10)
    local border=grip:CreateTexture(nil,"BACKGROUND")
    border:SetAllPoints(); border:SetColorTexture(.58,.43,.21,1)
    local face=grip:CreateTexture(nil,"ARTWORK")
    face:SetPoint("TOPLEFT",1,-1); face:SetPoint("BOTTOMRIGHT",-1,1)
    face:SetColorTexture(.09,.075,.05,1)
    local icon=grip:CreateTexture(nil,"OVERLAY")
    icon:SetPoint("CENTER"); icon:SetSize(20,20)
    icon:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    icon:SetVertexColor(.9,.8,.6)
    grip:SetScript("OnEnter",function()
        border:SetColorTexture(.85,.68,.33,1)
        face:SetColorTexture(.18,.14,.08,1)
        if GameTooltip then GameTooltip:SetOwner(grip,"ANCHOR_RIGHT"); GameTooltip:SetText(self:T("SIZE_DRAG")); GameTooltip:Show() end
    end)
    grip:SetScript("OnLeave",function()
        border:SetColorTexture(.58,.43,.21,1)
        face:SetColorTexture(.09,.075,.05,1)
        if GameTooltip then GameTooltip:Hide() end
    end)
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
            self.db.scale=math.max(.6,math.min(1.5,start*(1+delta)))
            self:ApplyWindow()
        end)
    end)
    grip:SetScript("OnMouseUp",function() grip:SetScript("OnUpdate",nil) end)
    map:HookScript("OnHide",function() Stop(); grip:SetScript("OnUpdate",nil) end)
    map:HookScript("OnShow",function()
        C_Timer.After(0,function() if map:IsShown() then self:Refresh() end end)
    end)
    for _,method in ipairs({"Maximize","Minimize"}) do
        if type(map[method])=="function" then hooksecurefunc(map,method,function()
            local maximized=map.IsMaximized and map:IsMaximized()
            bar:SetShown(not maximized and self.db.movable)
            grip:SetShown(not maximized and self.db.resizable)
            if maximized then
                if not (InCombatLockdown and InCombatLockdown()) then map:SetScale(self.originalScale) end
            else self:Refresh() end
        end) end
    end
    local scroll=map.ScrollContainer
    if scroll and type(scroll.CreateZoomLevels)=="function" then
        hooksecurefunc(scroll,"CreateZoomLevels",function()
            self:ExtendZoom(scroll)
            self:RefreshReveal()
        end)
    end
end
