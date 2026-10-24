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
    self:UpdateOpacityPopup()
end

function Maps:UpdateOpacityPopup()
    local popup=self.opacityPopup
    if not popup or not popup:IsShown() then return end
    self.updatingQuickOpacity=true
    local value=math.floor(self:GetMapTransparency()*100+.5)
    popup.slider:SetValue(value); popup.title:SetText(self:T("TRANSPARENCY",value))
    self.updatingQuickOpacity=nil
end

function Maps:ToggleOpacityPopup(anchor)
    if self.opacityPopup and self.opacityPopup:IsShown() then self.opacityPopup:Hide(); return end
    if not self.opacityPopup then
        local popup=CreateFrame("Frame","PatchToolsMapsOpacityPopup",UIParent,"BackdropTemplate")
        self.opacityPopup=popup
        popup:SetSize(330,92); popup:SetFrameStrata("FULLSCREEN_DIALOG")
        popup:SetClampedToScreen(true); popup:EnableMouse(true)
        popup:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize=10,insets={left=2,right=2,top=2,bottom=2}})
        popup:SetBackdropColor(.055,.045,.035,1); popup:SetBackdropBorderColor(.48,.37,.23,1)
        popup.title=popup:CreateFontString(nil,"OVERLAY","GameFontNormal")
        popup.title:SetPoint("TOPLEFT",12,-12); popup.title:SetWidth(290); popup.title:SetJustifyH("LEFT")
        local close=CreateFrame("Button",nil,popup,"UIPanelCloseButton")
        close:SetPoint("TOPRIGHT",0,0); close:SetSize(22,22)
        close:SetScript("OnClick",function() popup:Hide() end)
        local slider=CreateFrame("Slider","PatchToolsMapsQuickOpacitySlider",popup,"OptionsSliderTemplate")
        popup.slider=slider
        slider:SetPoint("TOPLEFT",16,-46); slider:SetWidth(290)
        slider:SetMinMaxValues(0,100); slider:SetValueStep(1); slider:SetObeyStepOnDrag(true)
        PatchToolsMapsQuickOpacitySliderLow:SetText("0%"); PatchToolsMapsQuickOpacitySliderHigh:SetText("100%")
        slider:SetScript("OnValueChanged",function(_,value)
            if not self.updatingQuickOpacity then self:SetMapTransparency(math.floor(value+.5)/100) end
        end)
        popup:SetScript("OnShow",function() self:UpdateOpacityPopup() end)
        table.insert(UISpecialFrames,"PatchToolsMapsOpacityPopup")
        self.map:HookScript("OnHide",function() popup:Hide() end)
        popup:Hide()
    end
    GameTooltip:Hide()
    if CloseDropDownMenus then CloseDropDownMenus() end
    self.opacityPopup:ClearAllPoints()
    self.opacityPopup:SetPoint("TOPLEFT",anchor,"BOTTOMLEFT",0,-4)
    self.opacityPopup:Show()
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
