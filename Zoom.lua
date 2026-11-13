local _, Maps = ...

-- Forever's native zoom fields are also consumed by protected quest pins.
-- Even out-of-combat addon pan calls can contaminate later combat updates.
-- Experimental Forever zoom requires the deferred marker input guard.
function Maps:ClearExtraZoom()
    self.extraZoomScale=nil
end

function Maps:CaptureViewportInputs(stage)
    if type(issecurevariable)~="function" then return end
    local scroll=self.map and self.map.ScrollContainer
    if not scroll then return end
    local rows=self.viewportInputRows or {}
    self.viewportInputRows=rows
    if #rows>=2 then return end
    local fields={}
    for _,key in ipairs({"mapID","baseScale","GetWidth","GetHeight","CreateZoomLevels",
        "OnCanvasSizeChanged","ResetZoom","InstantPanAndZoom"}) do
        local secure,owner=issecurevariable(scroll,key)
        fields[#fields+1]=key.."="..(secure and "secure" or tostring(owner or "unsafe"))
    end
    rows[#rows+1]=stage.." inputs: "..table.concat(fields,", ")
end

function Maps:CanUseMapInCombat()
    if not (InCombatLockdown and InCombatLockdown()) then return true end
    if not self.map or not (PatchTools and (PatchTools.isClassicEra or (PatchTools.isForever and self.pinInputGuard))) then return false end
    -- Switching the whole frame style still waits until combat ends.
    if self.customFrame and (self.customControlsPlaced==true)~=(self:UseCustomFrame()==true) then return false end
    for _,frame in ipairs({self.map,self.map.ScrollContainer,self.map:GetCanvas()}) do
        if frame.IsProtected and frame:IsProtected() then return false end
    end
    return true
end

-- Inspect ownership only; never repair or overwrite Blizzard state here.
function Maps:CaptureScrollSecurity(stage)
    if not (self.scrollSecurityEnabled or self.scrollSecurityStartup) or type(issecurevariable)~="function" then return end
    local scroll=self.map and self.map.ScrollContainer
    if not scroll then return end
    local unsafe={}
    for _,key in ipairs({"currentScale","targetScale","currentScrollX","currentScrollY","targetScrollX","targetScrollY","zoomLevels"}) do
        local secure,owner=issecurevariable(scroll,key)
        if not secure then unsafe[#unsafe+1]=key.." ("..tostring(owner or "?")..")" end
    end
    local state=#unsafe>0 and table.concat(unsafe,", ") or "secure"
    local rows=self.scrollSecurityRows or {}
    self.scrollSecurityRows=rows
    if state~=self.scrollSecurityLast then
        self.scrollSecurityLast=state
        if #rows<24 then rows[#rows+1]=stage..": "..state end
        if #unsafe>0 and not self.scrollSecurityOrigin and type(debugstack)=="function" then
            -- Record the first observed transition's caller chain, not a claim
            -- that this post-hook is the original taint write.
            self.scrollSecurityOrigin={stage=stage,stack=debugstack(3,12,0)}
        end
    end
end

function Maps:StartScrollSecurity()
    -- Capture from attachment, before our first layout. This is a bounded,
    -- read-only history; it does not print or write native canvas fields.
    if self.scrollSecurityStarted then return end
    self.scrollSecurityStarted=true
    self.scrollSecurityStartup=true
    self:InstallScrollSecurityHooks(self.map and self.map.ScrollContainer)
    self:CaptureScrollSecurity("before addon setup")
    self:CaptureViewportInputs("before addon setup")
end

function Maps:ToggleScrollSecurity()
    self.scrollSecurityEnabled=not self.scrollSecurityEnabled
    -- Keep the startup evidence when the user first enables diagnosis.
    if not self.scrollSecurityStartup and self.scrollSecurityEnabled then
        self.scrollSecurityRows={}; self.scrollSecurityLast=nil
        self.scrollSecurityOrigin=nil
    end
    self.scrollSecurityStartup=nil
    self:CaptureScrollSecurity("enabled")
    PatchTools:Print("Maps scroll diagnosis: "..(self.scrollSecurityEnabled and "on" or "off"))
end

function Maps:BuildScrollSecurityOrigin()
    local origin=self.scrollSecurityOrigin
    if not origin then return "Maps: no unsafe transition captured yet." end
    return "First observed transition: "..origin.stage.."\n"..origin.stack
end

function Maps:ShowDiagnosticText(text)
    local PT=PatchTools
    if PT.copyReportAPI and PT.OpenDebugReport then PT:OpenDebugReport(text)
    else for line in text:gmatch("[^\r\n]+") do PT:Print(line) end end
end

function Maps:PrintScrollSecurityOrigin()
    self:ShowDiagnosticText(self:BuildScrollSecurityOrigin())
end

function Maps:CallMapFunction(fn,...)
    -- securecallfunction does not grant combat permission. Call ordinary map
    -- operations directly only after checking the actual frame protection.
    if InCombatLockdown and InCombatLockdown() then return fn(...) end
    if securecallfunction then
        self:CaptureScrollSecurity("before native operation")
        local function After(...)
            self:CaptureScrollSecurity("after native operation")
            return ...
        end
        return After(securecallfunction(fn,...))
    end
    return fn(...)
end

-- These post-hooks observe transitions only. They neither repair native
-- state nor prove which earlier statement first wrote a tainted value.
function Maps:InstallScrollSecurityHooks(scroll)
    if not scroll or type(hooksecurefunc)~="function" then return end
    self.scrollSecurityHooks=self.scrollSecurityHooks or {}
    local installed=self.scrollSecurityHooks[scroll]
    if not installed then installed={}; self.scrollSecurityHooks[scroll]=installed end
    for _,method in ipairs({"CreateZoomLevels","ResetZoom","InstantPanAndZoom","OnCanvasSizeChanged"}) do
        if not installed[method] and type(scroll[method])=="function" then
            local stage="after native "..method
            hooksecurefunc(scroll,method,function()
                self:CaptureScrollSecurity(stage)
            end)
            installed[method]=true
        end
    end
end

function Maps:InstallZoom(scroll)
    if not scroll or type(scroll.OnMouseWheel) ~= "function"
        or type(scroll.InstantPanAndZoom) ~= "function" then return end
    self:InstallScrollSecurityHooks(scroll)
    self.zoomDiagnostics={calls=0,reason="ready"}
    -- Registering a script alone does not guarantee the frame receives wheels.
    scroll:EnableMouseWheel(true)
    scroll:HookScript("OnMouseUp",function(_,button)
        if button=="RightButton" then self:ClearExtraZoom() end
    end)
    -- Use the native pan/zoom operation; never replace methods or extend the
    -- zoomLevels table shared with protected map pins.
    -- XML already holds the original method as its event handler. Hook the
    -- actual script so hardware wheel events reach us on every map type.
    scroll:HookScript("OnMouseWheel", function(_, delta)
        self:CaptureScrollSecurity("wheel entry")
        local diagnostic=self.zoomDiagnostics
        diagnostic.calls=diagnostic.calls+1
        diagnostic.delta=delta
        if PatchTools and PatchTools.isForever and not self.pinInputGuard then
            diagnostic.reason="native-only"
            diagnostic.target,diagnostic.after=nil,nil
            return
        end
        if not self.db.extendedZoom then diagnostic.reason="disabled"; return end
        local foreverZoom=PatchTools and PatchTools.isForever and self.pinInputGuard
            and not self.map:IsProtected() and not scroll:IsProtected()
        if not self:CanUseMapInCombat() and not foreverZoom then diagnostic.reason="combat-protected"; return end
        if type(delta)~="number" or delta==0 then diagnostic.reason="invalid-delta"; return end
        if type(scroll.zoomLevels)~="table" or #scroll.zoomLevels==0 then diagnostic.reason="no-levels"; return end
        local maximum = scroll:GetScaleForMaxZoom()
        local scale = self.extraZoomScale or scroll:GetCanvasScale()
        local minimum=scroll.zoomLevels[1].scale
        diagnostic.scale,diagnostic.maximum,diagnostic.minimum=scale,maximum,minimum
        -- At the lower limit no zoom remains to apply. Repeating Era's native
        -- pan/clamp at the same scale can alternate its letterboxed edges.
        -- Check the native scale too: an extra zoom may still need restoring
        -- after the original wheel handler has changed the canvas scale.
        if delta<0 and scale<=minimum+.000001 and scroll:GetCanvasScale()<=minimum+.000001 then
            self.extraZoomScale=nil
            diagnostic.reason,diagnostic.target,diagnostic.after="minimum",minimum,scroll:GetCanvasScale()
            return
        end
        -- Own the full enabled zoom range. Waiting for native maximum leaves
        -- maps with inactive native wheel zoom permanently stuck at minimum.
        local target = math.max(minimum, math.min(maximum * 4, scale * 1.25 ^ delta))
        local x, y = .5, .5
        if scroll.GetNormalizedHorizontalScroll then
            x, y = scroll:GetNormalizedHorizontalScroll(), scroll:GetNormalizedVerticalScroll()
        end
        if scroll.GetCursorPosition and scroll.Child then
            local cx, cy = scroll:GetCursorPosition()
            local left, top = scroll.Child:GetLeft(), scroll.Child:GetTop()
            local current = scroll:GetCanvasScale()
            if cx and cy and left and top and current > 0 then
                x = scroll:NormalizeHorizontalSize(cx / current - left)
                y = scroll:NormalizeVerticalSize(top - cy / current)
            end
        end
        diagnostic.reason,diagnostic.target="applied",target
        self.extraZoomScale = target > minimum + .000001 and target or nil
        self:CallMapFunction(scroll.InstantPanAndZoom, scroll, target, x, y)
        diagnostic.after=scroll:GetCanvasScale()
    end)
end

function Maps:ZoomSettingsChanged()
    self:ClearExtraZoom()
    if not self.db.extendedZoom then self.resetViewPending = true end
    self:Refresh()
end

function Maps:BuildZoomStatus()
    local lines={}
    local function Add(text) lines[#lines+1]=text end
    local scroll=self.map and self.map.ScrollContainer
    local diagnostic=self.zoomDiagnostics or {}
    local ready=scroll and type(scroll.zoomLevels)=="table" and #scroll.zoomLevels>0
    local function Read(method)
        if not scroll or type(scroll[method])~="function" then return "?" end
        local ok,value=pcall(scroll[method],scroll)
        return ok and tostring(value) or "?"
    end
    for _,row in ipairs(self.scrollSecurityRows or {}) do Add(row) end
    for _,row in ipairs(self.viewportInputRows or {}) do Add(row) end
    Add("Maps "..self.version.."; extra="..tostring(self.db.extendedZoom)
        .."; combat="..tostring(InCombatLockdown and InCombatLockdown() or false)
        .."; wheel="..Read("IsMouseWheelEnabled"))
    Add("Native method barrier="..tostring(type(securecallmethod)=="function"))
    Add("Deferred pin input="..tostring(self.pinInputGuard~=nil).."; pending="..tostring(self.pinInputGuard and self.pinInputGuard:PendingCount() or 0))
    Add(self:BuildRevealStatus())
    Add("Map="..tostring(self.map and self.map:GetMapID()).."; levels="..tostring(ready and #scroll.zoomLevels or 0)
        .."; scale="..(ready and Read("GetCanvasScale") or "?")
        .."; max="..(ready and Read("GetScaleForMaxZoom") or "?")
        .."; nativeTarget="..tostring(scroll and scroll.targetScale)
        .."; mode="..tostring(scroll and scroll.mouseWheelZoomMode))
    if scroll then
        Add("Window="..tostring(self.map:GetWidth()).."x"..tostring(self.map:GetHeight())
            .."; viewport="..tostring(scroll:GetWidth()).."x"..tostring(scroll:GetHeight())
            .."; protected="..tostring(self.map:IsProtected()).."/"..tostring(scroll:IsProtected()))
    end
    Add("Wheel events="..tostring(diagnostic.calls or 0).."; result="..tostring(diagnostic.reason)
        .."; delta="..tostring(diagnostic.delta).."; target="..tostring(diagnostic.target)
        .."; after="..tostring(diagnostic.after))
    lines[#lines+1]=self:BuildScrollSecurityOrigin()
    return table.concat(lines,"\n")
end

function Maps:PrintZoomStatus()
    self:ShowDiagnosticText(self:BuildZoomStatus())
end
