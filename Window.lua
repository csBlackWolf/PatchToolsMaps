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
function Maps:ApplyEraChrome(factor,maximized)
    if not self.eraChrome then return false end
    -- Era's small border is two fixed-size textures, not a stretchable frame.
    -- Scale only the decorative header/border and its controls. The map canvas
    -- remains in the native coordinate space used by continent hit testing.
    local custom=self.customFrame and self:UseCustomFrame()
    for _,entry in ipairs(self.eraChrome) do
        local scale=entry.scale*(custom and 1 or factor)
        if math.abs(entry.frame:GetScale()-scale)>.00001 then entry.frame:SetScale(scale) end
    end
    local scroll=self.map.ScrollContainer
    if not scroll then return false end
    local inset=self.eraInsets
    local left,top=inset[1]*factor,inset[2]*factor
    local right,bottom=inset[3]*factor,inset[4]*factor
    if custom then left,top,right,bottom=self:GetCustomFrameInsets() end
    if maximized then left,top,right,bottom=11,-70,inset[3],inset[4] end
    local matched=0
    for i=1,scroll:GetNumPoints() do
        local point,relative,relativePoint,x,y=scroll:GetPoint(i)
        if relative==self.map and point==relativePoint then
            if point=="TOPLEFT" and math.abs(x-left)<.00001 and math.abs(y-top)<.00001 then matched=matched+1 end
            if point=="BOTTOMRIGHT" and math.abs(x-right)<.00001 and math.abs(y-bottom)<.00001 then matched=matched+1 end
        end
    end
    if matched==2 and scroll:GetNumPoints()==2 then return false end
    scroll:ClearAllPoints()
    scroll:SetPoint("TOPLEFT",self.map,"TOPLEFT",left,top)
    scroll:SetPoint("BOTTOMRIGHT",self.map,"BOTTOMRIGHT",right,bottom)
    return true
end
function Maps:CaptureEraView()
    if not self.eraChrome then return nil end
    local scroll=self.map.ScrollContainer
    local levels=scroll and scroll.zoomLevels
    local minimum=type(levels)=="table" and levels[1] and levels[1].scale
    if not minimum or minimum<=0 then return nil end
    return {
        ratio=scroll:GetCanvasScale()/minimum,
        x=scroll:GetNormalizedHorizontalScroll(),
        y=scroll:GetNormalizedVerticalScroll(),
    }
end
function Maps:RefreshEraViewport(view)
    local map,scroll=self.map,self.map.ScrollContainer
    local levels=scroll and scroll.zoomLevels
    if (self.resizing or self.viewportRebuildPending) and type(levels)=="table" and levels[1]
        and scroll and type(scroll.CreateZoomLevels)=="function" then
        -- Only recompute the viewport's fit scales during the gesture. A full
        -- frame rebuild resets the canvas and refreshes providers on every tick.
        if securecallfunction then securecallfunction(scroll.CreateZoomLevels,scroll)
        else scroll:CreateZoomLevels() end
        -- Finishing the drag runs the normal reveal hook once, without the
        -- native ResetZoom that would blend the saved pan back toward center.
        self.viewportRebuildPending=self.resizing and true or nil
    elseif type(map.OnFrameSizeChanged)=="function" then
        if securecallfunction then securecallfunction(map.OnFrameSizeChanged,map)
        else map:OnFrameSizeChanged() end
        self.viewportRebuildPending=nil
    end
    self.extraZoomScale=nil
    levels=scroll and scroll.zoomLevels
    if view and type(levels)=="table" and levels[1] and type(scroll.InstantPanAndZoom)=="function" then
        local maximum=scroll:GetScaleForMaxZoom()*(self.db.extendedZoom and 4 or 1)
        local target=math.max(levels[1].scale,math.min(maximum,levels[1].scale*view.ratio))
        local x,y=view.x,view.y
        if type(scroll.CalculateScrollExtentsAtScale)=="function"
            and type(scroll.SetPanTarget)=="function" and type(scroll.MarkCanvasDirty)=="function"
            and type(scroll.GetCurrentScrollX)=="function" and type(scroll.GetCurrentScrollY)=="function" then
            local xmin,xmax,ymin,ymax=scroll:CalculateScrollExtentsAtScale(target)
            if type(xmin)=="number" and type(xmax)=="number"
                and type(ymin)=="number" and type(ymax)=="number"
                and (xmin>xmax+.0000001 or ymin>ymax+.0000001) then
                -- At fit zoom a letterboxed axis has reversed native bounds.
                -- Reusing the previous edge in native Lerp/Clamp can alternate
                -- between both edges on each shrinking tick. Seed the native
                -- pan through its public methods so each tick clamps from the
                -- same center, without replacing methods or changing bounds.
                if xmin>xmax then x=.5 end
                if ymin>ymax then y=.5 end
                local currentX,currentY=scroll:GetCurrentScrollX(),scroll:GetCurrentScrollY()
                if securecallfunction then
                    securecallfunction(scroll.SetPanTarget,scroll,currentX,currentY)
                    securecallfunction(scroll.MarkCanvasDirty,scroll)
                    securecallfunction(scroll.SetPanTarget,scroll,x,y)
                else
                    scroll:SetPanTarget(currentX,currentY)
                    scroll:MarkCanvasDirty()
                    scroll:SetPanTarget(x,y)
                end
            end
        end
        if securecallfunction then securecallfunction(scroll.InstantPanAndZoom,scroll,target,x,y)
        else scroll:InstantPanAndZoom(target,x,y) end
        if self.db.extendedZoom and target>levels[1].scale+.000001 then self.extraZoomScale=target end
    end
end
function Maps:FinishResize()
    if self.resizeGrip then self.resizeGrip:SetScript("OnUpdate",nil) end
    if not self.resizing then return end
    self.resizing=nil
    if self.map and self.map:IsShown() then self:ApplyWindow() end
    self.resizeView=nil
end
function Maps:ApplyWindow()
    if not self:CanChangeWindow() then return end
    if self.customFrame then self:UpdateNovaTimers() end
    local map=self.map
    -- Capture before changing the viewport: native normalized scroll getters
    -- depend on its dimensions. Keep one stable snapshot for the entire drag.
    local view=self.resizeView or self:CaptureEraView()
    local resized=false
    if PatchTools and PatchTools.isClassicEra then
        -- Era's native cursor conversion assumes the window's original scale.
        -- Change the viewport dimensions instead of scaling its coordinate space.
        map:SetScale(self.originalScale)
        local width,height=self.originalWidth*self.db.scale,self.originalHeight*self.db.scale
        if self.customFrame and self:UseCustomFrame() then height=self:GetCustomFrameHeight(width) end
        resized=math.abs(map:GetWidth()-width)>.01 or math.abs(map:GetHeight()-height)>.01
        if resized then map:SetSize(width,height) end
        resized=self:ApplyEraChrome(self.db.scale,false) or resized
    else
        map:SetScale(self.originalScale*self.db.scale)
    end
    if self.db.x and self.db.y then
        local ratio=UIParent:GetEffectiveScale()/map:GetEffectiveScale()
        map:ClearAllPoints()
        map:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",self.db.x*UIParent:GetWidth()*ratio,self.db.y*UIParent:GetHeight()*ratio)
    end
    map:SetClampedToScreen(false)
    if self.ownsDragBar then self.dragBar:SetShown(self.db.movable) end
    self.resizeGrip:SetShown(self.db.resizable)
    if self.customFrame then self:LayoutCustomFrame() end
    if self.eraChrome and (resized or (self.viewportRebuildPending and not self.resizing)) then
        self:RefreshEraViewport(view)
    end
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
    self.resizing,self.resizeView=nil,nil
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
    self.originalWidth=type(map.minimizedWidth)=="number" and map.minimizedWidth or map:GetWidth()
    self.originalHeight=type(map.minimizedHeight)=="number" and map.minimizedHeight or map:GetHeight()
    if PatchTools and PatchTools.isClassicEra then
        self.eraChrome={}
        for _,frame in pairs({map.MiniBorderFrame,WorldMapTitleButton,WorldMapFrameCloseButton,map.MaximizeMinimizeFrame}) do
            if (type(frame)=="table" or type(frame)=="userdata") and type(frame.GetScale)=="function" then
                self.eraChrome[#self.eraChrome+1]={frame=frame,scale=frame:GetScale()}
            end
        end
        -- Native minimized Era insets. Keep existing custom offsets when the
        -- module attaches to a minimized map, including another addon's layout.
        self.eraInsets={20,-22,-10,28}
        local scroll=map.ScrollContainer
        if scroll and not (map.IsMaximized and map:IsMaximized()) then
            for i=1,scroll:GetNumPoints() do
                local point,relative,relativePoint,x,y=scroll:GetPoint(i)
                if relative==map and point==relativePoint then
                    if point=="TOPLEFT" then self.eraInsets[1],self.eraInsets[2]=x,y
                    elseif point=="BOTTOMRIGHT" then self.eraInsets[3],self.eraInsets[4]=x,y end
                end
            end
        end
    end
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
    if self.customHeader then
        self.customHeader:HookScript("OnDragStart",Start)
        self.customHeader:HookScript("OnDragStop",Stop)
    end
    local grip=CreateFrame("Button",nil,map)
    self.resizeGrip=grip
    grip:Hide()
    grip:SetPoint("BOTTOMRIGHT",map,"BOTTOMRIGHT",2,-2)
    grip:SetSize(20,20); grip:SetFrameLevel(map:GetFrameLevel()+10)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetScript("OnEnter",function()
        if not self.resizing and GameTooltip then GameTooltip:SetOwner(grip,"ANCHOR_RIGHT"); GameTooltip:SetText(self:T("SIZE_DRAG")); GameTooltip:Show() end
    end)
    grip:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    grip:SetScript("OnMouseDown",function(_,button)
        if button~="LeftButton" or not self:CanChangeWindow() or not self.db.resizable then return end
        self:SavePosition()
        self.resizeView=self:CaptureEraView()
        self.resizing=true
        if GameTooltip then GameTooltip:Hide() end
        local x,y=GetCursorPosition()
        local start=self.db.scale
        local width=map:GetWidth()*map:GetEffectiveScale()
        local height=map:GetHeight()*map:GetEffectiveScale()
        grip:SetScript("OnUpdate",function()
            if type(IsMouseButtonDown)=="function" and not IsMouseButtonDown("LeftButton") then
                self:FinishResize(); return
            end
            if not self:CanChangeWindow() then self:FinishResize(); return end
            local cx,cy=GetCursorPosition()
            local delta=((cx-x)*width+(y-cy)*height)/(width*width+height*height)
            self.db.scale=math.max(.6,start*(1+delta))
            self:ApplyWindow()
        end)
    end)
    grip:SetScript("OnMouseUp",function() self:FinishResize() end)
    map:HookScript("OnHide",function() Stop(); self:FinishResize(); self.extraZoomScale=nil end)
    map:HookScript("OnShow",function()
        C_Timer.After(0,function() if map:IsShown() then self:Refresh() end end)
    end)
    for _,method in ipairs({"Maximize","Minimize"}) do
        if type(map[method])=="function" then hooksecurefunc(map,method,function()
            local maximized=map.IsMaximized and map:IsMaximized()
            if maximized then self.resizing,self.resizeView=nil,nil; grip:SetScript("OnUpdate",nil) end
            if self.ownsDragBar then bar:SetShown(not maximized and self.db.movable) end
            grip:SetShown(not maximized and self.db.resizable)
            if maximized then
                if not (InCombatLockdown and InCombatLockdown()) then
                    map:SetScale(self.originalScale)
                    if self:ApplyEraChrome(1,true) and type(map.OnFrameSizeChanged)=="function" then
                        if securecallfunction then securecallfunction(map.OnFrameSizeChanged,map)
                        else map:OnFrameSizeChanged() end
                        self.viewportRebuildPending=nil
                    end
                    if self.customFrame then self:LayoutCustomFrame() end
                end
            else self:Refresh() end
        end) end
    end
    local scroll=map.ScrollContainer
    self:InstallZoom(scroll)
    if scroll and type(scroll.CreateZoomLevels)=="function" then
        hooksecurefunc(scroll,"CreateZoomLevels",function()
            if not self.resizing then self:RefreshReveal() end
        end)
    end
end
