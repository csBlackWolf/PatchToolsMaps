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
    popup.slider:SetValue(value); popup.title:SetText(self:T("QUICK_TRANSPARENCY",value))
    self.updatingQuickOpacity=nil
end

function Maps:PlaceOpacityPopup(anchor)
    local popup=self.opacityPopup
    local parentScale=UIParent:GetEffectiveScale()
    local above=UIParent:GetHeight()-anchor:GetTop()*anchor:GetEffectiveScale()/parentScale
    popup:ClearAllPoints()
    if above>=popup:GetHeight()+6 then
        popup:SetPoint("BOTTOMLEFT",anchor,"TOPLEFT",0,6)
    else
        local scale=self.map:GetEffectiveScale()/parentScale
        local left=self.map:GetLeft()*scale
        local right=left+self.map:GetWidth()*scale
        if UIParent:GetWidth()-right>=popup:GetWidth()+6 then
            popup:SetPoint("TOPLEFT",self.map,"TOPRIGHT",6,0)
        elseif left>=popup:GetWidth()+6 then
            popup:SetPoint("TOPRIGHT",self.map,"TOPLEFT",-6,0)
        else
            popup:SetPoint("TOPLEFT",anchor,"BOTTOMLEFT",0,-4)
        end
    end
end

function Maps:ToggleOpacityPopup(anchor)
    if self.opacityPopup and self.opacityPopup:IsShown() then self.opacityPopup:Hide(); return end
    if not self.opacityPopup then
        local popup=CreateFrame("Frame","PatchToolsMapsOpacityPopup",UIParent,"BackdropTemplate")
        self.opacityPopup=popup
        popup:SetSize(260,70); popup:SetFrameStrata("FULLSCREEN_DIALOG")
        popup:SetClampedToScreen(true); popup:EnableMouse(true)
        popup:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize=10,insets={left=2,right=2,top=2,bottom=2}})
        popup:SetBackdropColor(.055,.045,.035,1); popup:SetBackdropBorderColor(.48,.37,.23,1)
        popup.title=popup:CreateFontString(nil,"OVERLAY","GameFontNormal")
        popup.title:SetPoint("TOPLEFT",10,-9); popup.title:SetWidth(220); popup.title:SetJustifyH("LEFT")
        local close=CreateFrame("Button",nil,popup,"UIPanelCloseButton")
        close:SetPoint("TOPRIGHT",0,0); close:SetSize(18,18)
        close:SetScript("OnClick",function() popup:Hide() end)
        local slider=CreateFrame("Slider","PatchToolsMapsQuickOpacitySlider",popup,"OptionsSliderTemplate")
        popup.slider=slider
        slider:SetPoint("TOPLEFT",14,-32); slider:SetWidth(230)
        slider:SetMinMaxValues(0,100); slider:SetValueStep(1); slider:SetObeyStepOnDrag(true)
        PatchToolsMapsQuickOpacitySliderLow:SetText("0%"); PatchToolsMapsQuickOpacitySliderHigh:SetText("100%")
        slider:SetScript("OnValueChanged",function(_,value)
            if not self.updatingQuickOpacity then self:SetMapTransparency(math.floor(value+.5)/100) end
        end)
        popup:SetScript("OnShow",function() self:UpdateOpacityPopup() end)
        local function OutsideClick(button)
            if not popup:IsShown() or popup:IsMouseOver() then return end
            -- Let a second right-click on the title toggle it off on mouse-up.
            if button=="RightButton" and popup.anchor and popup.anchor:IsMouseOver() then return end
            popup:Hide()
        end
        local success,result=pcall(popup.RegisterEvent,popup,"GLOBAL_MOUSE_DOWN")
        local registered=success and result~=false
        if registered then
            popup:SetScript("OnEvent",function(_,event,button)
                if event=="GLOBAL_MOUSE_DOWN" then OutsideClick(button) end
            end)
        else
            -- Older clients without the event: detect new presses, never close
            -- merely because a slider drag that started inside moves outside.
            local down={}
            popup:SetScript("OnUpdate",function()
                if not IsMouseButtonDown then return end
                for _,button in ipairs({"LeftButton","RightButton"}) do
                    local held=IsMouseButtonDown(button)
                    if held and not down[button] then OutsideClick(button) end
                    down[button]=held
                end
            end)
            popup:HookScript("OnShow",function() down={} end)
        end
        table.insert(UISpecialFrames,"PatchToolsMapsOpacityPopup")
        self.map:HookScript("OnHide",function() popup:Hide() end)
        popup:Hide()
    end
    GameTooltip:Hide()
    if CloseDropDownMenus then CloseDropDownMenus() end
    self.opacityPopup.anchor=anchor
    self:PlaceOpacityPopup(anchor)
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
