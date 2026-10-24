local _, Maps = ...
local function Bounded(value)
    value=tonumber(value)
    if not value or value~=value or math.abs(value)==math.huge then return 0 end
    return math.max(0,math.min(1,value))
end

function Maps:GetMapTransparency()
    local get=C_CVar and C_CVar.GetCVar or GetCVar
    if get then
        local ok,value=pcall(get,"worldMapOpacity")
        if ok and tonumber(value) then return Bounded(value) end
    end
    return Bounded(self.db and self.db.transparency)
end

function Maps:SetMapTransparency(value)
    value=Bounded(value)
    local get=C_CVar and C_CVar.GetCVar or GetCVar
    local set=C_CVar and C_CVar.SetCVar or SetCVar
    local ok,current
    if get then ok,current=pcall(get,"worldMapOpacity") end
    if ok and tonumber(current) and set then
        pcall(set,"worldMapOpacity",tostring(value))
    else
        self.db.transparency=value
    end
    self:ApplyMapOpacity()
    self:UpdateOptions()
end

function Maps:ApplyMapOpacity()
    if not self.map then return end
    if InCombatLockdown and InCombatLockdown() then return end
    local value=self:GetMapTransparency()
    -- Match Blizzard: fullscreen stays opaque; minimized maps use the CVar.
    if self.map.IsMaximized and self.map:IsMaximized() then value=0 end
    if type(WorldMapFrame_SetOpacity)=="function" then
        WorldMapFrame_SetOpacity(value)
    else
        -- Clients without the legacy helper use the same alpha curve.
        self.map:SetAlpha(1-.5*value)
        if self.map.ScrollContainer then self.map.ScrollContainer:SetAlpha(1-.65*value) end
    end
end
