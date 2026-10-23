local _, Maps = ...

function Maps:InstallZoom(scroll)
    if not scroll or type(scroll.OnMouseWheel) ~= "function"
        or type(scroll.InstantPanAndZoom) ~= "function" then return end
    self.zoomDiagnostics={calls=0,reason="ready"}
    -- Registering a script alone does not guarantee the frame receives wheels.
    scroll:EnableMouseWheel(true)
    scroll:HookScript("OnMouseUp",function(_,button)
        if button=="RightButton" then self.extraZoomScale=nil end
    end)
    -- Use the native pan/zoom operation; never replace methods or extend the
    -- zoomLevels table shared with protected map pins.
    -- XML already holds the original method as its event handler. Hook the
    -- actual script so hardware wheel events reach us on every map type.
    scroll:HookScript("OnMouseWheel", function(_, delta)
        local diagnostic=self.zoomDiagnostics
        diagnostic.calls=diagnostic.calls+1
        diagnostic.delta=delta
        if not self.db.extendedZoom then diagnostic.reason="disabled"; return end
        if InCombatLockdown and InCombatLockdown() then diagnostic.reason="combat"; return end
        if type(delta)~="number" or delta==0 then diagnostic.reason="invalid-delta"; return end
        if type(scroll.zoomLevels)~="table" or #scroll.zoomLevels==0 then diagnostic.reason="no-levels"; return end
        local maximum = scroll:GetScaleForMaxZoom()
        local scale = self.extraZoomScale or scroll:GetCanvasScale()
        local minimum=scroll.zoomLevels[1].scale
        diagnostic.scale,diagnostic.maximum,diagnostic.minimum=scale,maximum,minimum
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
        if securecallfunction then securecallfunction(scroll.InstantPanAndZoom, scroll, target, x, y)
        else scroll:InstantPanAndZoom(target, x, y) end
        diagnostic.after=scroll:GetCanvasScale()
    end)
end

function Maps:ZoomSettingsChanged()
    self.extraZoomScale = nil
    if not self.db.extendedZoom then self.resetViewPending = true end
    self:Refresh()
end

function Maps:PrintZoomStatus()
    local PT=PatchTools
    local scroll=self.map and self.map.ScrollContainer
    local diagnostic=self.zoomDiagnostics or {}
    local ready=scroll and type(scroll.zoomLevels)=="table" and #scroll.zoomLevels>0
    local function Read(method)
        if not scroll or type(scroll[method])~="function" then return "?" end
        local ok,value=pcall(scroll[method],scroll)
        return ok and tostring(value) or "?"
    end
    PT:Print("Maps "..self.version.."; extra="..tostring(self.db.extendedZoom)
        .."; combat="..tostring(InCombatLockdown and InCombatLockdown() or false)
        .."; wheel="..Read("IsMouseWheelEnabled"))
    PT:Print("Map="..tostring(self.map and self.map:GetMapID()).."; levels="..tostring(ready and #scroll.zoomLevels or 0)
        .."; scale="..(ready and Read("GetCanvasScale") or "?")
        .."; max="..(ready and Read("GetScaleForMaxZoom") or "?")
        .."; nativeTarget="..tostring(scroll and scroll.targetScale)
        .."; mode="..tostring(scroll and scroll.mouseWheelZoomMode))
    PT:Print("Wheel events="..tostring(diagnostic.calls or 0).."; result="..tostring(diagnostic.reason)
        .."; delta="..tostring(diagnostic.delta).."; target="..tostring(diagnostic.target)
        .."; after="..tostring(diagnostic.after))
end
