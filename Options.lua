local _, Maps = ...
local function Label(parent,text,y,font)
    local label=parent:CreateFontString(nil,"OVERLAY",font or "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT",0,y); label:SetWidth(570); label:SetJustifyH("LEFT"); label:SetText(text)
    return label
end
function Maps:BuildOptions(parent)
    Label(parent,self:T("INTRO"),0)
    local checks={}
    local function Check(key,text,y,inverted)
        local box=CreateFrame("CheckButton",nil,parent,"UICheckButtonTemplate")
        box:SetPoint("TOPLEFT",0,y)
        local label=parent:CreateFontString(nil,"OVERLAY","GameFontNormal")
        label:SetPoint("LEFT",box,"RIGHT",4,0); label:SetWidth(530); label:SetJustifyH("LEFT"); label:SetText(self:T(text))
        box:SetScript("OnClick",function(b)
            local value=b:GetChecked()==true
            if inverted then value=not value end
            self.db[key]=value
            if key=="extendedZoom" then self:ZoomSettingsChanged() else self:Refresh() end
            self:UpdateOptions()
        end)
        checks[key]=box
    end
    Check("movable","MOVABLE",-35)
    Check("resizable","RESIZE",-70)
    Label(parent,self:T("WINDOW_HINT"),-111)
    Check("extendedZoom","ZOOM",-158)
    Label(parent,self:T("ZOOM_HINT"),-199)
    Label(parent,self:T("MODE"),-240,"GameFontNormal")
    local mode=CreateFrame("Frame","PatchToolsMapsRevealDropdown",parent,"UIDropDownMenuTemplate")
    mode:SetPoint("TOPLEFT",-16,-264)
    UIDropDownMenu_SetWidth(mode,350)
    local modes={{"classic","CLASSIC"},{"mist","MIST"},{"full","FULL"}}
    UIDropDownMenu_Initialize(mode,function(_,level)
        for _,entry in ipairs(modes) do
            local value=entry[1]
            local info=UIDropDownMenu_CreateInfo()
            info.text,info.value=self:T(entry[2]),value
            info.checked=self.db.mode==value
            info.func=function() self.db.mode=value; self:Refresh(); self:UpdateOptions() end
            UIDropDownMenu_AddButton(info,level)
        end
    end)
    Label(parent,self:T("VISUAL"),-310)
    if PatchTools.isClassicEra then
        Check("customFrame","FRAME_CLASSIC_OPTION",-339,true)
        Label(parent,self:T("FRAME_CLASSIC_HINT"),-380)
    end
    local opacityText=Label(parent,"",-411,"GameFontNormal")
    local opacity=CreateFrame("Slider","PatchToolsMapsOpacitySlider",parent,"OptionsSliderTemplate")
    opacity:SetPoint("TOPLEFT",4,-438); opacity:SetWidth(350)
    opacity:SetMinMaxValues(0,100); opacity:SetValueStep(1); opacity:SetObeyStepOnDrag(true)
    PatchToolsMapsOpacitySliderLow:SetText("0%"); PatchToolsMapsOpacitySliderHigh:SetText("100%")
    opacity:SetScript("OnValueChanged",function(_,value)
        if not self.updatingOpacity then self:SetMapTransparency(math.floor(value+.5)/100) end
    end)
    Label(parent,self:T("STATUS",tostring(select(2,GetBuildInfo()))),-470)
    local reset=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    reset:SetPoint("TOPLEFT",0,-505); reset:SetSize(350,27); reset:SetText(self:T("RESET"))
    local scale=Label(parent,"",-548)
    reset:SetScript("OnClick",function() self:ResetMap(); self:UpdateOptions() end)
    self.optionsUI={checks=checks,mode=mode,scale=scale,reset=reset,opacity=opacity,opacityText=opacityText}
    parent:SetScript("OnShow",function() self:UpdateOptions() end)
    self:UpdateOptions()
end
function Maps:UpdateOptions()
    local ui=self.optionsUI
    if not ui then return end
    for key,box in pairs(ui.checks) do
        local value=self.db[key]
        if key=="customFrame" then value=not value end
        box:SetChecked(value)
    end
    local labels={classic="CLASSIC",mist="MIST",full="FULL"}
    UIDropDownMenu_SetText(ui.mode,self:T(labels[self.db.mode] or "MIST"))
    self.updatingOpacity=true
    local transparency=math.floor(self:GetMapTransparency()*100+.5)
    ui.opacity:SetValue(transparency)
    ui.opacityText:SetText(self:T("TRANSPARENCY",transparency))
    self.updatingOpacity=nil
    ui.scale:SetText(self:T("SCALE",math.floor(self.windowDB.scale*100+.5)))
end
