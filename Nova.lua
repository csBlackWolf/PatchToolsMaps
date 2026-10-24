local _, Maps = ...

local function Editable(frame)
    return frame and type(frame.GetAlpha)=="function"
        and not (type(frame.IsProtected)=="function" and frame:IsProtected())
end

function Maps:DiscoverNovaTimers()
    if not LibStub then return end
    local ace=LibStub("AceAddon-3.0",true)
    local nova=ace and ace:GetAddon("NovaWorldBuffs",true)
    if not nova or type(nova.worldBuffMapMarkerTypes)~="table" then return end
    self.novaTimers=self.novaTimers or {}
    local function Add(name,definition,layer)
        local source=_G[name]
        if not Editable(source) or not source.timerFrame
            or not source.timerFrame.fs or not source.texture then return end
        local previous=self.novaTimers[name]
        if previous then
            if previous.source==source then return end
            previous.button:Hide()
            if previous.original and Editable(previous.source) then
                previous.source:SetAlpha(previous.original.alpha)
                previous.source:EnableMouse(previous.original.mouse)
            end
        end
        -- Keep HereBeDragons' actual pin, parent, anchors and visibility intact.
        -- Only its presentation is masked while a read-only footer mirror is active.
        local entry={source=source,name=definition.name or name,layer=layer}
        local button=CreateFrame("Button",nil,self.customFrame.footer)
        entry.button=button
        button:SetSize(84,18); button:Hide(); button:EnableMouse(true)
        entry.icon=button:CreateTexture(nil,"ARTWORK")
        entry.icon:SetSize(16,16); entry.icon:SetPoint("LEFT",0,0)
        entry.text=button:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        entry.text:SetPoint("LEFT",entry.icon,"RIGHT",5,0)
        entry.text:SetPoint("RIGHT",-2,0); entry.text:SetJustifyH("LEFT")
        button:SetScript("OnEnter",function()
            if not GameTooltip then return end
            GameTooltip:SetOwner(button,"ANCHOR_TOP")
            GameTooltip:SetText(entry.name)
            GameTooltip:AddLine(source.timerFrame.fs:GetText() or "—",1,1,1)
            if layer then GameTooltip:AddLine(self:T("NOVA_LAYER",tostring(layer)),.7,.7,.7) end
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(self.novaBuffHint or self:T("NOVA_OPEN"),1,.82,0,true)
            GameTooltip:AddLine(self:T("NOVA_CLICK"),.7,.7,.7,true)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
        button:SetScript("OnMouseDown",function(_,mouseButton)
            if InCombatLockdown and InCombatLockdown() then return end
            local handler=source:GetScript("OnMouseDown")
            if handler then handler(source,mouseButton) end
        end)
        self.novaTimers[name]=entry
    end
    for kind,definition in pairs(nova.worldBuffMapMarkerTypes) do
        Add(kind.."NWBWorldMap",definition)
        if nova.data and type(nova.data.layers)=="table" then
            for layer in pairs(nova.data.layers) do Add(kind..tostring(layer).."NWBWorldMap",definition,layer) end
        end
    end
end

function Maps:UpdateNovaTimers()
    if not self.customFrame then return false end
    local combat=InCombatLockdown and InCombatLockdown()
    if not combat then self:DiscoverNovaTimers() end
    local enabled=combat and self.novaActive or self:UseCustomFrame()
    local entries={}
    for name,entry in pairs(self.novaTimers or {}) do
        local source=entry.source
        if (type(source.fs)=="table" or type(source.fs)=="userdata") and type(source.fs.GetText)=="function" then
            local hint=source.fs:GetText()
            if type(hint)=="string" and hint~="" then self.novaBuffHint=hint end
        end
        if enabled then
            if not combat and Editable(source) then
                if not entry.original then
                    entry.original={alpha=source:GetAlpha(),mouse=source:IsMouseEnabled()}
                end
                source:SetAlpha(0); source:EnableMouse(false)
            end
            -- Nova owns Show/Hide, including faction, realm/layer, map and
            -- addon settings. Unknown timers ("--") remain unknown, not estimated.
            local shown=entry.original and source:IsShown() and source.timerFrame:IsShown()
            entry.button:SetShown(shown and true or false)
            if shown then
                entry.icon:SetTexture(source.texture:GetTexture())
                entry.text:SetText(source.timerFrame.fs:GetText() or "—")
                entries[#entries+1]={key=name,entry=entry}
            end
        elseif not combat then
            entry.button:Hide()
            if entry.original and Editable(source) then
                source:SetAlpha(entry.original.alpha); source:EnableMouse(entry.original.mouse)
                entry.original=nil
            end
        end
    end
    if combat then return false end
    self.novaActive=enabled and true or nil
    table.sort(entries,function(a,b) return a.key<b.key end)
    local available=math.max(84,self.originalWidth*self.db.scale-32)
    local columns=math.max(1,math.floor(available/88))
    local rows=math.ceil(#entries/columns)
    local height=rows>0 and rows*22+2 or 0
    for i,value in ipairs(entries) do
        local column=(i-1)%columns
        local row=math.floor((i-1)/columns)
        local button=value.entry.button
        button:ClearAllPoints()
        button:SetPoint("BOTTOMRIGHT",self.customFrame.footer,"BOTTOMRIGHT",-column*88,row*22)
    end
    local changed=(self.novaRowHeight or 0)~=height
    self.novaRowHeight=height
    return changed
end
