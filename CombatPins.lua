local _, Maps = ...

-- Only the world map we manage is guarded. Native marker input settings can
-- be refreshed after combat; tooltips and the markers themselves stay active.
function Maps:InstallCombatPinInput()
    if self.pinInputGuard or not (PatchTools and PatchTools.isForever) then return end
    if not MapCanvasPinMixin or type(MapCanvasPinMixin.CheckMouseButtonPassthrough)~="function" then return end
    local guard=self.DeferredPinInput.New(self.map,function() return InCombatLockdown() end)
    self.pinInputGuard=guard
    local native={CheckMouseButtonPassthrough=MapCanvasPinMixin.CheckMouseButtonPassthrough}
    if SuperTrackablePinMixin and type(SuperTrackablePinMixin.UpdateMousePropagation)=="function" then
        native.UpdateMousePropagation=SuperTrackablePinMixin.UpdateMousePropagation
    end
    local function Prepare(object)
        if type(object)~="table" then return end
        for name,method in pairs(native) do
            if rawget(object,name)==method then guard:Wrap(object,name) end
        end
    end
    local function PreparePools()
        for _,pool in pairs(self.map.pinPools or {}) do
            for _,enumerator in ipairs({"EnumerateActive","EnumerateInactive"}) do
                if type(pool[enumerator])=="function" then
                    for pin in pool[enumerator](pool) do Prepare(pin) end
                end
            end
        end
    end
    local function PrepareTemplates()
        -- Blizzard copies mixin functions into derived templates before our
        -- addon loads. Replace only exact copies of the original methods.
        for _,object in pairs(_G) do Prepare(object) end
        PreparePools()
    end
    PrepareTemplates()
    local scroll=self.map.ScrollContainer
    if type(scroll.MarkCanvasDirty)=="function" then
        -- AcquirePin marks the canvas dirty before configuring mouse input.
        hooksecurefunc(scroll,"MarkCanvasDirty",PreparePools)
    end
    local events=CreateFrame("Frame")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:RegisterEvent("ADDON_LOADED")
    events:SetScript("OnEvent",function(_,event)
        if event=="PLAYER_REGEN_ENABLED" then guard:Flush()
        else C_Timer.After(0,PrepareTemplates) end
    end)
    self.pinInputEvents=events
end
