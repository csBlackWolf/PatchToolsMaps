local _, Maps = ...
Maps.mapActionAPI=1

local function Value(options,key,fallback)
    local value=options[key]
    if type(value)~="function" then
        if value==nil then return fallback end
        return value
    end
    local ok,result=pcall(value)
    if ok then return result end
    return fallback
end

-- Preferred integration for a fixed map function: no frame or layout code is
-- required from the other addon. Map pins still belong on Blizzard's canvas.
function Maps:RegisterMapAction(id,options)
    if type(id)~="string" or id=="" or type(options)~="table"
        or (type(options.icon)~="string" and type(options.icon)~="number")
        or type(options.onClick)~="function" then return false end
    for _,key in ipairs({"isShown","isActive"}) do
        if options[key]~=nil and type(options[key])~="function" then return false end
    end
    self.mapActions=self.mapActions or {}
    if self.mapActions[id] then return false end
    local button=CreateFrame("Button",nil,self.map or UIParent,"BackdropTemplate")
    button:SetSize(24,24); button:Hide()
    button:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=8,
        insets={left=2,right=2,top=2,bottom=2}})
    button.icon=button:CreateTexture(nil,"ARTWORK")
    button.icon:SetPoint("CENTER"); button.icon:SetSize(18,18); button.icon:SetTexture(options.icon)
    local hover=button:CreateTexture(nil,"HIGHLIGHT")
    hover:SetAllPoints(); hover:SetColorTexture(1,.8,.35,.18)
    if not self:RegisterFrameWidget(id,button,"buttons") then return false end
    self.mapActions[id]={button=button,options=options}
    button:SetScript("OnClick",function(_,mouseButton)
        if not self.map or not self:UseCustomFrame() then return end
        options.onClick(button,mouseButton)
        self:UpdateMapActions(); self:Refresh()
        if button:IsMouseOver() then button:GetScript("OnEnter")() end
    end)
    button:SetScript("OnEnter",function()
        GameTooltip:SetOwner(button,"ANCHOR_BOTTOM")
        GameTooltip:SetText(tostring(Value(options,"tooltip",id)),1,1,1,1,true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave",function() GameTooltip:Hide() end)
    return true,button
end

function Maps:UpdateMapActions()
    local changed=false
    local modern=self.map and self:UseCustomFrame()
    for _,entry in pairs(self.mapActions or {}) do
        local button,options=entry.button,entry.options
        local wanted=options.isShown==nil or Value(options,"isShown",false)
        local shown=modern and wanted and true or false
        if button:IsShown()~=shown then changed=true; button:SetShown(shown) end
        local active=options.isActive==nil or (Value(options,"isActive",false) and true or false)
        button.icon:SetDesaturated(not active)
        button.icon:SetVertexColor(active and 1 or .55,active and 1 or .55,active and 1 or .55)
        button:SetBackdropColor(.055,.045,.035,1)
        button:SetBackdropBorderColor(active and .85 or .35,active and .65 or .3,active and .25 or .25,1)
    end
    return changed
end
