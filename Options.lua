local _, Maps = ...
local function Label(parent,text,y,font)
    local label=parent:CreateFontString(nil,"OVERLAY",font or "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT",0,y); label:SetWidth(570); label:SetJustifyH("LEFT"); label:SetText(text)
    return label
end
function Maps:BuildOptions(parent)
    Label(parent,self:T("INTRO"),0)
    local checks={}
    local function Check(key,text,y)
        local box=CreateFrame("CheckButton",nil,parent,"UICheckButtonTemplate")
        box:SetPoint("TOPLEFT",0,y)
        local label=parent:CreateFontString(nil,"OVERLAY","GameFontNormal")
        label:SetPoint("LEFT",box,"RIGHT",4,0); label:SetWidth(530); label:SetJustifyH("LEFT"); label:SetText(self:T(text))
        box:SetScript("OnClick",function(b) self.db[key]=b:GetChecked()==true; self:Refresh(true) end)
        checks[key]=box
    end
    Check("movable","MOVABLE",-45)
    Check("resizable","RESIZE",-82)
    Label(parent,self:T("WINDOW_HINT"),-126)
    Check("extendedZoom","ZOOM",-174)
    Label(parent,self:T("ZOOM_HINT"),-215)
    Label(parent,self:T("MODE"),-257,"GameFontNormal")
    local modes={}
    for i,entry in ipairs({{"classic","CLASSIC"},{"mist","MIST"},{"full","FULL"}}) do
        local key=entry[1]
        local button=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
        button:SetPoint("TOPLEFT",0,-286-(i-1)*32); button:SetSize(350,27); button:SetText(self:T(entry[2]))
        button:SetScript("OnClick",function() self.db.mode=key; self:Refresh(); self:UpdateOptions() end)
        modes[key]=button
    end
    Label(parent,self:T("VISUAL"),-393)
    Label(parent,self:T("STATUS"),-425)
    local reset=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    reset:SetPoint("TOPLEFT",0,-487); reset:SetSize(350,27); reset:SetText(self:T("RESET"))
    local scale=Label(parent,"",-535)
    reset:SetScript("OnClick",function() self:ResetMap(); self:UpdateOptions() end)
    self.optionsUI={checks=checks,modes=modes,scale=scale,reset=reset}
    parent:SetScript("OnShow",function() self:UpdateOptions() end)
    self:UpdateOptions()
end
function Maps:UpdateOptions()
    local ui=self.optionsUI
    if not ui then return end
    for key,box in pairs(ui.checks) do box:SetChecked(self.db[key]) end
    for mode,button in pairs(ui.modes) do if self.db.mode==mode then button:Disable() else button:Enable() end end
    ui.scale:SetText(self:T("SCALE",math.floor(self.db.scale*100+.5)))
end
