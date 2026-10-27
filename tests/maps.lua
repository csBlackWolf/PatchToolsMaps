
local dropdownItems={}
function UIDropDownMenu_SetWidth(frame,width) frame.dropdownWidth=width end
function UIDropDownMenu_Initialize(frame,fn) frame.dropdownInitialize=fn end
function UIDropDownMenu_CreateInfo() return {} end
function UIDropDownMenu_AddButton(info) dropdownItems[#dropdownItems+1]=info end
function UIDropDownMenu_SetText(frame,text) frame.dropdownText=text end
local function OpenDropdown(frame)
    dropdownItems={}; frame.dropdownInitialize(frame,1); return dropdownItems
end
local frames={}
unpack=table.unpack or unpack
local combat=false
local secureHardwareClick=false
local escapeTarget
local UpdateSecureBindings=function() end
local function HasTemplate(widget,name)
    local template=rawget(widget,'template')
    return type(template)=='string' and template:find(name,1,true)~=nil
end
local cursorX,cursorY=100,100
local function Widget(parent)
    local w={parent=parent,scripts={},events={},shown=true,width=1000,height=700,scale=1,points={},frameLevel=1}
    local methods={}
    function methods:SetScript(k,v)
        assert(not (HasTemplate(self,'SecureActionButtonTemplate') and k=='OnClick'),
            'do not replace the secure click handler with addon Lua')
        self.scripts[k]=v
    end
    function methods:HookScript(k,v)
        local old=self.scripts[k]
        self.scripts[k]=function(...) if old then old(...) end; v(...) end
    end
    function methods:RegisterEvent(k) self.events[k]=true end
    function methods:SetSize(x,y)
        assert(not (combat and self:IsProtected()),'do not resize protected frames in combat')
        self.width,self.height=x,y
    end
    function methods:SetWidth(x) self.width=x end
    function methods:SetHeight(y) self.height=y end
    function methods:GetWidth() return self.width end
    function methods:GetHeight() return self.height end
    function methods:GetSize() return self.width,self.height end
    function methods:SetPoint(...)
        assert(not (combat and self:IsProtected()),'do not reanchor protected frames in combat')
        self.points[#self.points+1]={...}
    end
    function methods:ClearAllPoints() self.points={} end
    function methods:GetNumPoints() return #self.points end
    function methods:GetPoint(i) return unpack(self.points[i]) end
    function methods:GetParent() return self.parent end
    function methods:SetOwner(owner,anchor) self.owner,self.anchor=owner,anchor end
    function methods:IsOwned(owner) return self.owner==owner end
    function methods:SetParent(parent) self.parent=parent end
    function methods:GetName() return rawget(self,"name") end
    function methods:IsProtected()
        if rawget(self,"protected")==true then return true end
        for _,child in ipairs(frames) do
            if HasTemplate(child,'SecureActionButtonTemplate') then
                local parent=rawget(child,'parent')
                while parent do
                    if parent==self then return true end
                    parent=rawget(parent,'parent')
                end
            end
        end
        return false
    end
    function methods:GetAlpha() return rawget(self,"alpha") or 1 end
    function methods:IsMouseOver() return false end
    function methods:IsMouseEnabled() return rawget(self,"mouse")==true end
    function methods:EnableMouse(value) self.mouse=value end
    function methods:GetScript(key) return self.scripts[key] end
    function methods:SetAttribute(key,value)
        assert(not combat,'secure button setup must happen outside combat')
        self.attributes=rawget(self,'attributes') or {}; self.attributes[key]=value
    end
    function methods:GetAttribute(key) local attributes=rawget(self,'attributes'); return attributes and attributes[key] end
    function methods:Click(button,down)
        if HasTemplate(self,'SecureActionButtonTemplate') then
            if down then return end
            assert(self:GetAttribute('useOnKeyDown')==false)
            assert(self:GetAttribute('type')=='click')
            local previous=secureHardwareClick; secureHardwareClick=true
            self:GetAttribute('clickbutton'):Click(button or 'LeftButton')
            secureHardwareClick=previous
        elseif HasTemplate(self,'UIPanelCloseButton') then
            if down then return end
            local previous=secureHardwareClick; secureHardwareClick=true
            HideUIPanel(self:GetParent())
            secureHardwareClick=previous
        elseif self.scripts.OnClick then self.scripts.OnClick(self,button or 'LeftButton',down) end
    end
    function methods:GetTexture() return rawget(self,"texture") end
    function methods:GetScale() return self.scale end
    function methods:SetScale(s) self.scale=s end
    function methods:SetClampedToScreen(v) self.clamped=v end
    function methods:EnableMouseWheel(v) self.wheelEnabled=v end
    function methods:IsMouseWheelEnabled() return self.wheelEnabled==true end
    function methods:GetEffectiveScale() return self.scale end
    function methods:GetFrameLevel() return self.frameLevel end
    function methods:GetLeft() return 100 end
    function methods:GetTop() return 700 end
    function methods:SetText(s) self.text=s end
    function methods:SetValue(value)
        self.value=value
        if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,value) end
    end
    function methods:GetText() return self.text end
    function methods:SetChecked(s) self.checked=s end
    function methods:GetChecked() return self.checked end
    function methods:Show() self.shown=true; if self.scripts.OnShow then self.scripts.OnShow(self) end; UpdateSecureBindings() end
    function methods:Hide() self.shown=false; if self.scripts.OnHide then self.scripts.OnHide(self) end; UpdateSecureBindings() end
    function methods:SetShown(v) if v then self:Show() else self:Hide() end end
    function methods:IsShown() return self.shown end
    function methods:CreateFontString() return Widget(self) end
    function methods:CreateTexture() return Widget(self) end
    function methods:CreateLine() return Widget(self) end
    function methods:SetStartPoint(point,relativeTo,x,y) assert(type(relativeTo)=='table'); self.start={point,relativeTo,x,y} end
    function methods:SetEndPoint(point,relativeTo,x,y) assert(type(relativeTo)=='table'); self.finish={point,relativeTo,x,y} end
    function methods:SetDesaturated(v) self.desaturated=v end
    function methods:SetVertexColor(r,g,b) self.vertexColor={r,g,b} end
    function methods:SetAlpha(v) self.alpha=v end
    function methods:SetTexture(v) self.texture=v end
    function methods:AddMaskTexture(v) self.mask=v end
    function methods:RemoveMaskTexture(v) assert(self.mask==v); self.mask=nil end
    function methods:SetTexCoord(...) self.texCoord={...} end
    function methods:StartMoving() self.isMoving=true end
    function methods:StopMovingOrSizing() self.isMoving=false end
    setmetatable(w,{__index=function(_,key) return methods[key] or function() end end})
    return w
end
UpdateSecureBindings=function()
    for _,widget in ipairs(frames) do
        if HasTemplate(widget,'SecureHandlerShowHideTemplate') then
            local visible,current=true,widget
            while current do
                if not rawget(current,'shown') then visible=false; break end
                current=rawget(current,'parent')
            end
            if visible~=(rawget(widget,'secureVisible')==true) then
                widget.secureVisible=visible
                local code=widget:GetAttribute(visible and '_onshow' or '_onhide')
                if code then
                    local handle={}
                    function handle:GetName() return widget:GetName() end
                    function handle:SetBindingClick(priority,key,name,button)
                        assert(priority==true and key=='ESCAPE' and name==widget:GetName())
                        escapeTarget={frame=widget,button=button}
                    end
                    function handle:ClearBindings()
                        if escapeTarget and escapeTarget.frame==widget then escapeTarget=nil end
                    end
                    assert(load(code,'secure visibility snippet','t',{self=handle}))()
                end
            end
        end
    end
end
local function PressEscape()
    if not escapeTarget then
        for _,name in ipairs(UISpecialFrames) do
            local frame=_G[name]
            if frame and frame:IsShown() then
                local previous=secureHardwareClick; secureHardwareClick=true
                HideUIPanel(frame); secureHardwareClick=previous
                return true
            end
        end
        return false
    end
    escapeTarget.frame:Click(escapeTarget.button)
    return true
end
function CreateFrame(_,name,parent,template)
    local w=Widget(parent); w.TitleText=Widget(w); frames[#frames+1]=w
    w.template=template
    if name then _G[name]=w end
    if template=='OptionsSliderTemplate' then
        for _,suffix in ipairs({'Low','High','Text'}) do _G[name..suffix]=Widget(w) end
    end
    return w
end
UIParent=Widget(); UIParent:SetSize(1920,1080)
UISpecialFrames={}; SlashCmdList={}; tinsert=table.insert
function GetLocale() return os.getenv('PATCHTOOLS_TEST_LOCALE') or 'enUS' end
local era = os.getenv('PATCHTOOLS_TEST_CLIENT') == 'era'
local build = era and 70003 or 70532
local fixtureArt = era and 1194 or 2031
function GetBuildInfo()
    if era then return '1.15.9','70003','',11509 end
    return '1.60.1','70532','',16001
end
function InCombatLockdown() return combat end
function GetCursorPosition() return cursorX,cursorY end
local panelCloses=0
function HideUIPanel(frame)
    assert(not combat or secureHardwareClick,'insecure HideUIPanel is blocked during combat')
    panelCloses=panelCloses+1; frame:Hide()
end
local secureCalls=0
function securecallfunction(fn,...)
    assert(not combat,'native UI calls must wait for combat to end')
    secureCalls=secureCalls+1
    return fn(...)
end
function hooksecurefunc(object,key,fn)
    local original=object[key]
    object[key]=function(...)
        local result={original(...)}
        fn(...)
        return unpack(result)
    end
end
C_Timer={After=function(_,fn) fn() end}
local function Event(event,name)
    local copy={unpack(frames)}
    for _,frame in ipairs(copy) do
        if frame.events[event] and frame.scripts.OnEvent then frame.scripts.OnEvent(frame,event,name) end
    end
end
local PT={db={sellBlocklist={},sellAllowlist={},phaseLead=60,phaseDuration=10},modules={},version='0.7.0-local.1'}
_G.PatchTools=PT
function PT:Print(s) self.lastMessage=s end
function PT:SetOption(k,v) self.db[k]=v end
function PT:OpenOptions() self.options:Show() end
local base=BASE_PATH or 'PatchTools-next/PatchTools/'
assert(loadfile(base..'Client.lua'))('PatchTools',PT)
assert(loadfile(base..'Locales.lua'))('PatchTools',PT)
assert(loadfile(base..'Extensions.lua'))('PatchTools',PT)
assert(loadfile(base..'Options.lua'))('PatchTools',PT)
-- Without the module there are no map controls or navigation entry.
PT:CreateOptions()
local legacyPlaceholder=PT.mapsPlaceholder
if legacyPlaceholder then
    assert(PT.optionPages.maps==legacyPlaceholder)
    PT:SelectOptionsPage('maps'); assert(legacyPlaceholder:IsShown())
else
    assert(not PT.optionPages.maps and not PT.optionNavigation.maps)
    assert(PT:SelectOptionsPage('maps')==false)
end
PT:SelectOptionsPage('general')
assert(PT:SelectOptionsPage('missing')==false and PT.optionPages.general:IsShown())
PatchToolsMapsDB={customFrame=false,scale=1,x=.2,y=.8}
local Maps={}
for _,name in ipairs({'Locales.lua','OverlayData.lua','GeneratedCatalog.lua','GeneratedCatalogEra.lua','GeneratedCatalogEra70576.lua','Reveal.lua','Zoom.lua','Nova.lua','Opacity.lua','Frame.lua','Actions.lua','Window.lua','Options.lua','Core.lua'}) do
    assert(loadfile(MAPS_PATH..name))('PatchToolsMaps',Maps)
end
Event('ADDON_LOADED','PatchToolsMaps')
assert(Maps.initialized and Maps.db.mode=='mist' and PT.optionPages.maps)
assert(Maps.db.extendedZoom==true,'new installations enable map zoom by default')
assert(Maps.windowDB==PatchToolsMapsCharacterDB and Maps.windowDB.x==.2 and Maps.windowDB.y==.8)
assert(PT.optionPages.maps and not PT.mapsPlaceholder)
if legacyPlaceholder then assert(not legacyPlaceholder:IsShown()) end
assert(PT.optionNavigation.maps.points[1][3]>PT.optionNavigation.about.points[1][3])
assert(not PT:RegisterOptionsPage('maps','Duplicate',function() error('duplicate builder ran') end))
assert(not PT:RegisterOptionsPage('about','Reserved',function() end))
assert(not Maps.map)
PT:SelectOptionsPage('maps'); assert(PT.optionPages.maps:IsShown())
assert(Maps.optionsUI.checks.movable.checked==true)
if era then
    local classic=Maps.optionsUI.checks.customFrame
    assert(classic:GetChecked()==true)
    classic:SetChecked(false); classic.scripts.OnClick(classic); assert(Maps.db.customFrame==true)
    assert(classic:GetChecked()==false)
    classic:SetChecked(true); classic.scripts.OnClick(classic); assert(Maps.db.customFrame==false)
else
    assert(not Maps.optionsUI.checks.customFrame,'Forever keeps its native layout')
end
local revealChoices=OpenDropdown(Maps.optionsUI.mode)
assert(#revealChoices==3 and revealChoices[2].checked)
for i,value in ipairs({'classic','mist','full'}) do
    revealChoices[i].func(); assert(Maps.db.mode==value)
end
revealChoices[2].func()
assert(Maps.db.mode=='mist' and Maps.optionsUI.mode.dropdownText==Maps:T('MIST'))
-- Early registration, before options exist, uses the same interface.
local early={}
assert(loadfile(base..'Extensions.lua'))('PatchTools',early)
local mounted=0
assert(early:RegisterOptionsPage('early','Early',function() mounted=mounted+1 end))
assert(#early.extraOptionsPages==1 and mounted==0)
-- Blizzard's world map may load after the optional addon.
local explored={}
local artID=55
local layer={layerWidth=512,layerHeight=256,tileWidth=256,tileHeight=256}
C_Map={GetMapArtID=function() return artID end,GetMapArtLayers=function() return {layer} end}
C_MapExplorationInfo={GetExploredMapTextures=function() return explored end}
local map=Widget(UIParent)
WorldMapFrame=map
local nativeDragCalls=0
if era then
    -- Native Era XML: fixed border textures in MiniBorderFrame, with the title
    -- drag area and window controls parented directly to WorldMapFrame.
    map.MiniBorderFrame=Widget(map)
    MiniBorderLeft=Widget(map.MiniBorderFrame); MiniBorderLeft:SetSize(512,512)
    MiniBorderLeft:SetPoint('TOPLEFT',map.MiniBorderFrame,'TOPLEFT',12,0)
    MiniBorderRight=Widget(map.MiniBorderFrame); MiniBorderRight:SetSize(128,512)
    MiniBorderRight:SetPoint('LEFT',MiniBorderLeft,'RIGHT',0,0)
    WorldMapFrameCloseButton=Widget(map)
    map.MaximizeMinimizeFrame=Widget(map)
    WorldMapTitleButton=Widget(map)
    WorldMapTitleButton:SetSize(544,22)
    WorldMapTitleButton:SetPoint('TOPLEFT',MiniBorderLeft,'TOPLEFT',0,0)
    WorldMapScreenAnchor=Widget(UIParent)
    WorldMapScreenAnchor:SetPoint('TOPLEFT',UIParent,'TOPLEFT',-9999,9999)
    WorldMapTitleButton:SetScript('OnDragStart',function() nativeDragCalls=nativeDragCalls+1 end)
    WorldMapTitleButton:SetScript('OnUpdate',function() end)
end
map.maximized=false
map:SetPoint('CENTER',UIParent,'CENTER',0,0)
function map:IsMaximized() return self.maximized end
function map:Maximize() self.maximized=true; if WorldMapTitleButton then WorldMapTitleButton:Hide() end end
function map:Minimize() self.maximized=false; if WorldMapTitleButton then WorldMapTitleButton:Show() end end
function map:GetMapID() return 100 end
local nativeMasks={}
map.maskableTextures=nativeMasks
local mask={}
map.useMask=true
function map:GetUseMaskTexture() return self.useMask end
function map:GetMaskTexture() return mask end
function map:RefreshMaskableTextures() end
function map:AddMaskableTexture() error('addon texture must not enter Blizzard maskableTextures') end
local canvas=Widget(map)
local scroll=Widget(map)
map.ScrollContainer=scroll
function map:GetCanvas() return canvas end
function map:GetCanvasContainer() return scroll end
function scroll:GetCurrentLayerIndex()
    -- Mirror Blizzard's dependency so an early call fails as in the report.
    local index=1
    for i,level in ipairs(self.zoomLevels) do
        if (rawget(self,'currentScale') or 1)>=level.scale then index=i end
    end
    return self.zoomLevels[index].layerIndex
end
local nativeZoomBuilds=0
function scroll:GetScaleForMaxZoom() return self.zoomLevels[#self.zoomLevels].scale end
function scroll:GetCanvasScale() return rawget(self,'currentScale') or 1 end
function scroll:GetNormalizedHorizontalScroll() return .5 end
function scroll:GetNormalizedVerticalScroll() return .5 end
function scroll:InstantPanAndZoom(scale,x,y)
    assert(not combat)
    self.currentScale,self.panX,self.panY=scale,x,y
end
function scroll:OnMouseWheel(delta)
    if rawget(self,'overview') then return end
    self.currentScale=delta>0 and self:GetScaleForMaxZoom() or self.zoomLevels[1].scale
end

function scroll:CreateZoomLevels()
    nativeZoomBuilds=nativeZoomBuilds+1
    self.zoomLevels=setmetatable({{scale=1,layerIndex=1},{scale=2,layerIndex=1}},
        {__newindex=function() error('addon must not mutate Blizzard zoomLevels') end})
end
function scroll:ResetZoom(ignoreScaleRatio)
    assert(ignoreScaleRatio==true)
    self.currentScale=self.zoomLevels[1].scale
    self.panX,self.panY=.5,.5
    self.resets=(rawget(self,'resets') or 0)+1
end
-- XML binds the original handler before the addon is loaded. Real wheel
-- input calls the registered script, not a later replacement of the method.
scroll:SetScript('OnMouseWheel',scroll.OnMouseWheel)
local function Wheel(delta)
    if scroll:IsMouseWheelEnabled() then scroll.scripts.OnMouseWheel(scroll,delta) end
end
scroll.GetCursorPosition=false
scroll:CreateZoomLevels()
combat=true
Event('ADDON_LOADED','Blizzard_WorldMap')
assert(not Maps.map,'late map attachment must wait until combat ends')
combat=false
Event('PLAYER_REGEN_ENABLED')
assert(Maps.map==map and Maps.dragBar:IsShown() and Maps.resizeGrip:IsShown())
Maps.db.extendedZoom=true; Maps:Refresh(true)
assert(#scroll.zoomLevels==2 and nativeZoomBuilds==1)
scroll:CreateZoomLevels(); assert(#scroll.zoomLevels==2)
Maps.db.extendedZoom=false; Maps:Refresh(true); assert(#scroll.zoomLevels==2)
-- The extra overlay renderer never changes the explored list.
local overlay={textureWidth=300,textureHeight=200,offsetX=0,offsetY=0,fileDataIDs={111,222}}
explored={overlay}; Maps:RefreshReveal()
explored={}; Maps:RefreshReveal()
assert(#explored==0 and #Maps.textures==2)
assert(Maps.textures[1].alpha==.5 and Maps.textures[2].width==44)
assert(not Maps.textures[1].desaturated and Maps.textures[1].vertexColor[1]==1)
assert(Maps.textures[2].texCoord[2]==44/64)
assert(Maps.textures[1].mask==mask and map.maskableTextures==nativeMasks and next(nativeMasks)==nil)
map.useMask=false; map:RefreshMaskableTextures(); assert(rawget(Maps.textures[1],'mask')==nil)
map.useMask=true; map:RefreshMaskableTextures(); assert(Maps.textures[1].mask==mask)
Maps.db.mode='full'; Maps:RefreshReveal(); assert(Maps.textures[1].alpha==1)
assert(not Maps.textures[1].desaturated and Maps.textures[1].vertexColor[1]==1)
Maps.db.mode='classic'; Maps:RefreshReveal(); assert(not Maps.textures[1]:IsShown())
Maps.db.mode='full'; explored={overlay}; Maps:RefreshReveal(); assert(not Maps.textures[1]:IsShown())
explored={}; artID=56; Maps:RefreshReveal(); assert(not Maps.textures[1]:IsShown())
local invalid={textureWidth=300,textureHeight=200,offsetX=0,offsetY=0,fileDataIDs={111}}
assert(not Maps:ValidateOverlay(invalid,layer))
invalid.fileDataIDs={111,222}; invalid.isShownByMouseOver=true
assert(not Maps:ValidateOverlay(invalid,layer))
invalid.isShownByMouseOver=false; invalid.offsetX=0/0
assert(not Maps:ValidateOverlay(invalid,layer))
local special={textureWidth=300,textureHeight=200,offsetX=0,offsetY=0,fileDataIDs={111,222},isShownByMouseOver=true}
assert(#Maps:PlanOverlays({overlay},{special},layer,'full')==0)
-- Independently generated client data works without a learned exploration cache.
local catalogCount,artCount=0,0
for art,layers in pairs(Maps.catalog[build]) do
    artCount=artCount+1
    for key,overlays in pairs(layers) do
        local index,lw,lh,tw,th=key:match('^(%d+):(%d+):(%d+):(%d+):(%d+)$')
        for _,entry in ipairs(overlays) do
            assert(Maps:ValidateOverlay(entry,{tileWidth=tonumber(tw),tileHeight=tonumber(th)}))
            catalogCount=catalogCount+1
        end
    end
end
assert(artCount==(era and 41 or 45) and catalogCount==(era and 525 or 572))
local oldLayer=layer
layer={layerWidth=1002,layerHeight=668,tileWidth=256,tileHeight=256}
artID=fixtureArt; Maps.db.knownOverlays={}; explored={}; Maps.db.mode='mist'
Maps:RefreshReveal()
assert(Maps.textures[1]:IsShown() and Maps.textures[1].alpha==.5 and #explored==0)
assert(#Maps:GetCatalog(fixtureArt,1,layer)>0)
if not era then assert(#Maps:GetCatalog(fixtureArt,1,layer)==15) end
explored=Maps:GetCatalog(fixtureArt,1,layer); Maps:RefreshReveal()
assert(not Maps.textures[1]:IsShown())
assert(#Maps:GetCatalog(fixtureArt,2,layer)==0)
local savedBuild=GetBuildInfo
if era then
    GetBuildInfo=function() return '1.15.9','70576','',11509 end
    explored={}; Maps.db.knownOverlays={}
    assert(#Maps:GetCatalog(fixtureArt,1,layer)>0,'current Era patch must have its verified catalog')
    for _,mode in ipairs({'classic','mist','full'}) do
        Maps.db.mode=mode; Maps:RefreshReveal()
        if mode=='classic' then assert(not Maps.textures[1]:IsShown())
        else assert(Maps.textures[1]:IsShown() and Maps.textures[1].alpha==(mode=='mist' and .5 or 1)) end
    end
    local id,size=next(Maps.catalogTextureSizes[70576])
    local fw,fh=Maps:TextureSize(id,1,1)
    assert(fw==size[1] and fh==size[2],'current client texture edge dimensions must be preserved')
    Maps.db.mode='mist'
end
function GetBuildInfo() return '1.60.1','99999','',16001 end
assert(#Maps:GetCatalog(fixtureArt,1,layer)==0)
GetBuildInfo=savedBuild
if era then
    local id,size=next(Maps.catalogTextureSizes[70003])
    local fw,fh=Maps:TextureSize(id,1,1)
    assert(fw==size[1] and fh==size[2])
else
    local fw,fh=Maps:TextureSize(8124659,237,9)
    assert(fw==256 and fh==32)
end
if era then assert(not PT.optionPages.phase and not PT.optionNavigation.phase) end
layer=oldLayer; artID=56; explored={}; Maps.db.knownOverlays={}
-- Window scale, reset, fullscreen and combat deferral.
local function WindowFactor() return era and map:GetWidth()/Maps.originalWidth or map:GetScale()/Maps.originalScale end
Maps.windowDB.scale=1.3; Maps:Refresh(); assert(math.abs(WindowFactor()-1.3)<.00001)
map:Maximize(); assert(map.scale==1 and not Maps.dragBar:IsShown())
map:Minimize(); assert(math.abs(WindowFactor()-1.3)<.00001 and Maps.dragBar:IsShown())
map.protected=true; combat=true; Maps.windowDB.scale=.8; Maps:Refresh(); assert(math.abs(WindowFactor()-1.3)<.00001)
Maps.db.extendedZoom=true; Maps:Refresh(true); assert(#scroll.zoomLevels==2)
map.protected=nil; combat=false; Event('PLAYER_REGEN_ENABLED'); assert(math.abs(WindowFactor()-.8)<.00001 and #scroll.zoomLevels==2)
Maps.dragBar.scripts.OnDragStart(); assert(Maps.moving)
Maps.dragBar.scripts.OnDragStop(); assert(not Maps.moving and Maps.windowDB.x and Maps.windowDB.y)
Maps.dragBar.scripts.OnDragStart()
map.protected=true; combat=true; Event('PLAYER_REGEN_DISABLED')
assert(not Maps.moving and not Maps.moveDriver.scripts.OnUpdate)
assert(Maps.dragBar:IsShown() and Maps.resizeGrip:IsShown())
Maps.resizeGrip.scripts.OnMouseDown(Maps.resizeGrip,'LeftButton')
assert(Maps.resizeGrip:IsShown() and not Maps.resizeGrip.scripts.OnUpdate)
map.protected=nil; combat=false; Event('PLAYER_REGEN_ENABLED')
Maps.resizeGrip.scripts.OnMouseDown(Maps.resizeGrip,'LeftButton')
cursorX,cursorY=100000,-100000
Maps.resizeGrip.scripts.OnUpdate(); assert(Maps.windowDB.scale>1.5)
Maps.resizeGrip.scripts.OnMouseUp(); assert(not Maps.resizeGrip.scripts.OnUpdate)
Maps:ResetWindow(); assert(map.scale==1 and Maps.windowDB.x==nil and Maps.windowDB.y==nil)
-- Full reset is wired to the options button, including native view/zoom.
local anchor=Maps.resizeGrip.points[1]
assert(anchor[1]=='BOTTOMRIGHT' and anchor[2]==map and anchor[3]=='BOTTOMRIGHT')
assert(anchor[4]==2 and anchor[5]==-2)
assert(Maps.resizeGrip.width==20 and Maps.resizeGrip.height==20)
if era then assert(Maps.dragBar==WorldMapTitleButton and not Maps.ownsDragBar and nativeDragCalls>0 and Maps.dragBar.scripts.OnUpdate)
else assert(Maps.dragBar.height==19 and #Maps.dragBar.points==2) end
Maps.db.extendedZoom=true; Maps.windowDB.scale=1.4; Maps.windowDB.x=.4; Maps.windowDB.y=.6
Maps:Refresh(true); scroll.currentScale=4; scroll.panX,scroll.panY=.9,.1
Maps.optionsUI.reset.scripts.OnClick()
assert(not map:IsShown() and panelCloses==1)
assert(secureCalls>=2)
assert(map.scale==1 and Maps.windowDB.x==nil and Maps.windowDB.y==nil and Maps.db.extendedZoom)
assert(#scroll.zoomLevels==2 and scroll.currentScale==1 and scroll.panX==.5 and scroll.panY==.5)
assert(Maps.optionsUI.checks.extendedZoom.checked==true)
map:Show()
local resets=scroll.resets
map.protected=true; combat=true; Maps.db.extendedZoom=true; Maps.windowDB.scale=1.2
Maps:ResetMap(); assert(scroll.resets==resets and Maps.resetViewPending and Maps.resetPending)
assert(map:IsShown() and panelCloses==1) -- protected UI close waits for combat to end
map.protected=nil; combat=false; Event('PLAYER_REGEN_ENABLED')
assert(scroll.resets==resets+1 and not Maps.resetViewPending and not Maps.resetPending)
assert(not map:IsShown() and panelCloses==2)
map:Show()
map:Maximize(); Maps:ResetMap(); assert(Maps.resetViewPending and Maps.resetPending)
assert(not map:IsShown())
map:Minimize(); map:Show(); assert(not Maps.resetViewPending and not Maps.resetPending)
map:Hide(); local closes=panelCloses
Maps:ResetMap(); assert(Maps.resetViewPending and Maps.zoomPending)
assert(not map:IsShown() and panelCloses==closes)
map:Show(); assert(not Maps.resetViewPending and not Maps.zoomPending)
-- First-open/minimize/scale notifications can precede CreateZoomLevels.
-- Both nil and empty tables must defer native layer queries and view reset.
artID=fixtureArt; layer={layerWidth=1002,layerHeight=668,tileWidth=256,tileHeight=256}
Maps.db.mode='mist'; Maps:RefreshReveal()
assert(Maps.textures[1]:IsShown())
scroll.zoomLevels=nil
Maps:RefreshReveal(); assert(not Maps.textures[1]:IsShown())
map:Minimize(); map:OnCanvasScaleChanged()
Maps:ResetMap(); assert(Maps.resetViewPending and Maps.zoomPending)
assert(not map:IsShown())
scroll.zoomLevels={}
map:Minimize(); map:OnCanvasScaleChanged(); Maps:RefreshReveal()
assert(Maps.resetViewPending and Maps.zoomPending)
scroll:CreateZoomLevels()
map:Show()
assert(Maps.textures[1]:IsShown()) -- reopening rebuilds the native view and overlays
Maps:Refresh()
assert(not Maps.resetViewPending and not Maps.zoomPending and scroll.currentScale==1)
print('PASS: addon absent/late load, API registration, mist default, mode selection, overlay learning/rendering, texture tiling, art isolation, zoom limits, window controls, combat deferral and reset.')

assert(map.clamped==false)
map:Show(); Maps.db.movable=true; Maps.db.resizable=true
Maps.dragBar.scripts.OnDragStart()
cursorX,cursorY=-100000,100000
Maps.moveDriver.scripts.OnUpdate()
assert(Maps.windowDB.x<0 and Maps.windowDB.y>1)
Maps.dragBar.scripts.OnDragStop()
Maps.db.extendedZoom=true; Maps.extraZoomScale=nil; scroll.currentScale=2
local levels=scroll.zoomLevels
Wheel(1)
assert(scroll.currentScale==2.5 and Maps.extraZoomScale==2.5)
Wheel(1); assert(scroll.currentScale==3.125)
Wheel(-1); assert(scroll.currentScale==2.5)
Wheel(-1); assert(scroll.currentScale==2 and Maps.extraZoomScale==2)
for i=1,20 do Wheel(1) end
assert(scroll.currentScale==8 and scroll.zoomLevels==levels and #levels==2)
map.protected=true; combat=true; local secureBefore=secureCalls
Wheel(1); assert(secureCalls==secureBefore and scroll.currentScale==2)
SlashCmdList.PATCHTOOLSMAPS('reset')
assert(Maps.resetPending and map:IsShown())
map.protected=nil; combat=false; Event('PLAYER_REGEN_ENABLED')
assert(not map:IsShown() and Maps.windowDB.scale==1 and not Maps.windowDB.x and not Maps.windowDB.y)
map:Show(); Maps.windowDB.scale=5; Maps.windowDB.x=-2; Maps.windowDB.y=3; Maps:ApplyWindow()
SlashCmdList.PATCHTOOLSMAPS('reset')
assert(not map:IsShown() and Maps.windowDB.scale==1 and not Maps.windowDB.x and not Maps.windowDB.y)
-- World/continent overviews may have exactly one native scale and no
-- native wheel zoom. The addon must receive the actual registered event.
for _,overview in ipairs({'world','continent'}) do
    scroll.overview=overview
    scroll.zoomLevels=setmetatable({{scale=.75,layerIndex=1}},
        {__newindex=function() error('native overview zoom levels must remain untouched') end})
    scroll.currentScale=.75; Maps.extraZoomScale=nil; Maps.db.extendedZoom=true
    Wheel(1); assert(scroll.currentScale==.9375)
    Wheel(1); assert(scroll.currentScale==1.171875)
    Wheel(-1); Wheel(-1); assert(scroll.currentScale==.75 and not Maps.extraZoomScale)
    local original=scroll.zoomLevels
    for i=1,20 do Wheel(1) end
    assert(scroll.currentScale==3 and scroll.zoomLevels==original and #original==1)
    scroll.scripts.OnMouseUp(scroll,'RightButton'); assert(not Maps.extraZoomScale)
    Maps.db.extendedZoom=false; scroll.currentScale=.75
    Wheel(1); assert(scroll.currentScale==.75)
    Maps.db.extendedZoom=true; map.protected=true; combat=true
    Wheel(1); assert(scroll.currentScale==.75)
    map.protected=nil; combat=false
end
scroll.overview=nil; scroll.zoomLevels=levels
assert(scroll:IsMouseWheelEnabled() and Maps.zoomDiagnostics.calls>0)
SlashCmdList.PATCHTOOLSMAPS('status')
assert(PT.lastMessage:find('Wheel events=',1,true))
print('PASS: XML-bound hardware wheel events drive zone, world and continent zoom; one-level native tables stay untouched.')
print('PASS: extra wheel zoom without native zoom table mutation, native Era title reuse, unlimited resizing/off-screen dragging and slash reset with combat deferral.')
if era then
    local point=WorldMapScreenAnchor.points[1]
    assert(point[1]=='TOPLEFT' and point[4]==16 and point[5]==-104)
end
-- Reproduce the live report: four native levels exist, wheel events arrive,
-- but the displayed scale remains below their maximum. Extra zoom must not
-- wait for the native handler to reach that maximum before doing anything.
scroll.overview='reported-stalled-native'
scroll.zoomLevels={
    {scale=.57842313536926,layerIndex=1}, {scale=.8,layerIndex=1},
    {scale=1,layerIndex=1}, {scale=1.2387226156132,layerIndex=1},
}
scroll.currentScale=.57842313536926
Maps.extraZoomScale=nil; Maps.db.extendedZoom=true
Wheel(1)
assert(scroll.currentScale>.57842313536926,'enabled zoom must advance below the native maximum')
local first=scroll.currentScale
Wheel(1); assert(scroll.currentScale>first)
Wheel(-1); assert(math.abs(scroll.currentScale-first)<.00001)
for i=1,20 do Wheel(-1) end
assert(math.abs(scroll.currentScale-.57842313536926)<.00001)
scroll.overview=nil
print('PASS: live-reported four-level map zoom advances from minimum even when native wheel zoom is stalled.')
-- Reopening with an off-screen saved position must not sanitize it back on-screen.
Maps.initialized=false
Maps.windowDB.scale=5; Maps.windowDB.x=-2; Maps.windowDB.y=3
Maps:Initialize()
assert(Maps.windowDB.scale==5 and Maps.windowDB.x==-2 and Maps.windowDB.y==3)

Maps.initialized=false; Maps.db.extendedZoom=false; Maps:Initialize()
assert(Maps.db.extendedZoom==false,"preserve explicit saved zoom preference")
-- Reinitialization above deliberately reused a registered page; resume the live event fixture.
Maps.initialized=true

-- Regression: Era's native hit test reads physical cursor coordinates. Scaling
-- the entire frame shifts continent selection; growing its dimensions must not.
if era then
    map.protected=nil; combat=false; map.maximized=false; map:Show()
    local cursorMethod=scroll.GetCursorPosition
    local function NativeEraHitTest(px,py,canvasScale,left,top,width,height)
        return (px/canvasScale-left)/width,(top-py/canvasScale)/height
    end
    for _,factor in ipairs({.6,1,1.3,2,5}) do
        Maps.windowDB.scale=factor; Maps:ApplyWindow()
        assert(map:GetEffectiveScale()==Maps.originalScale)
        assert(math.abs(map:GetWidth()-Maps.originalWidth*factor)<.00001)
        for _,canvasScale in ipairs({.75,1,2,4}) do
            for _,point in ipairs({{.22,.4},{.75,.52}}) do
                local left,top,width,height=90,850,1000,668
                local px=(left+point[1]*width)*canvasScale*map:GetEffectiveScale()
                local py=(top-point[2]*height)*canvasScale*map:GetEffectiveScale()
                local hx,hy=NativeEraHitTest(px,py,canvasScale,left,top,width,height)
                assert(math.abs(hx-point[1])<.00001 and math.abs(hy-point[2])<.00001,
                    'visible continent and native click position must agree after resize')
            end
        end
        assert(scroll.GetCursorPosition==cursorMethod,'never replace protected native cursor methods')
    end
    Maps:ResetMap()
    assert(map:GetWidth()==Maps.originalWidth and map:GetHeight()==Maps.originalHeight)
end

if era then
    -- Native viewport rebuilds recreate the fit zoom. Keep relative zoom while
    -- resizing, and avoid resetting it again on ordinary settings refreshes.
    map.protected=nil; combat=false; map.maximized=false; map:Show()
    local rebuilds=0
    function map:OnFrameSizeChanged()
        rebuilds=rebuilds+1
        local fit=self:GetWidth()/Maps.originalWidth
        scroll.zoomLevels={{scale=fit,layerIndex=1},{scale=2*fit,layerIndex=1}}
        scroll.currentScale=fit
    end
    Maps.windowDB.scale=1; Maps:ApplyWindow()
    scroll.zoomLevels={{scale=1,layerIndex=1},{scale=2,layerIndex=1}}
    scroll.currentScale=3
    Maps.db.extendedZoom=true; Maps.windowDB.scale=2; Maps:ApplyWindow()
    assert(rebuilds==1 and scroll.currentScale==6 and Maps.extraZoomScale==6)
    Maps:ApplyWindow(); assert(rebuilds==1,'unchanged dimensions must not rebuild/reset zoom')
    map.protected=true; combat=true; Maps.windowDB.scale=3; Maps:ApplyWindow()
    assert(rebuilds==1 and map:GetWidth()==2*Maps.originalWidth)
    map.protected=nil; combat=false; Maps:Refresh()
    assert(rebuilds==2 and scroll.currentScale==9)
    Maps:ResetMap(); assert(map:GetWidth()==Maps.originalWidth)
end

if era then
    map.protected=nil; combat=false; map.maximized=false; map:Show()
    for _,factor in ipairs({.6,1,1.3,2,5}) do
        Maps.windowDB.scale=factor; Maps:ApplyWindow()
        assert(map:GetScale()==Maps.originalScale,'canvas coordinate scale must stay native')
        assert(map.MiniBorderFrame:GetScale()==factor,'fixed native border artwork must grow with the viewport')
        assert(WorldMapTitleButton:GetScale()==factor and WorldMapFrameCloseButton:GetScale()==factor)
        assert(map.MaximizeMinimizeFrame:GetScale()==factor)
        local topLeft,bottomRight=scroll.points[1],scroll.points[2]
        assert(topLeft[1]=='TOPLEFT' and topLeft[2]==map and topLeft[4]==20*factor and topLeft[5]==-22*factor)
        assert(bottomRight[1]=='BOTTOMRIGHT' and bottomRight[2]==map and bottomRight[4]==-10*factor and bottomRight[5]==28*factor)
        -- XML-fixed border and title sizes now retain their original proportions.
        assert(MiniBorderLeft:GetWidth()*map.MiniBorderFrame:GetScale()==512*factor)
        assert(MiniBorderRight:GetWidth()*map.MiniBorderFrame:GetScale()==128*factor)
        assert(WorldMapTitleButton:GetWidth()*WorldMapTitleButton:GetScale()==544*factor)
    end
    map:Maximize()
    assert(map.MiniBorderFrame:GetScale()==1 and WorldMapFrameCloseButton:GetScale()==1)
    assert(scroll.points[1][4]==11 and scroll.points[1][5]==-70 and scroll.points[2][5]==28)
    map:Minimize(); assert(map.MiniBorderFrame:GetScale()==Maps.windowDB.scale)
    map.protected=true; combat=true; local before=map.MiniBorderFrame:GetScale()
    Maps.windowDB.scale=1.7; Maps:ApplyWindow(); assert(map.MiniBorderFrame:GetScale()==before)
    map.protected=nil; combat=false; Maps:Refresh(); assert(map.MiniBorderFrame:GetScale()==1.7)
    Maps:ResetMap(); assert(map.MiniBorderFrame:GetScale()==1 and WorldMapFrameCloseButton:GetScale()==1)
    assert(scroll.points[1][4]==20 and scroll.points[2][5]==28)
end

if era then
    -- Resize a zoomed/panned canvas using Era's native pan interpolation and
    -- viewport-dependent scroll getters. Neither repeated resets nor focus
    -- drift may be hidden by the simpler InstantPanAndZoom fixture above.
    map.protected=nil; combat=false; map.maximized=false; Maps.windowDB.scale=1; map:Show(); Maps:ApplyWindow()
    local fullRebuilds,fitUpdates=0,0
    local offsetX,offsetY=0,0
    local canvasWidth,canvasHeight=1000,700
    local function ViewportWidth()
        return map:GetWidth()+scroll.points[2][4]-scroll.points[1][4]
    end
    local function ViewportHeight()
        return map:GetHeight()+scroll.points[1][5]-scroll.points[2][5]
    end
    function scroll:GetNormalizedHorizontalScroll()
        return (2*offsetX*self.currentScale+ViewportWidth())/(2*canvasWidth*self.currentScale)
    end
    function scroll:GetNormalizedVerticalScroll()
        return (2*offsetY*self.currentScale+ViewportHeight())/(2*canvasHeight*self.currentScale)
    end
    function scroll:CreateZoomLevels()
        fitUpdates=fitUpdates+1
        local fit=math.min(ViewportWidth()/canvasWidth,ViewportHeight()/canvasHeight)
        self.zoomLevels={{scale=fit,layerIndex=1},{scale=fit*2,layerIndex=1}}
    end
    function scroll:CalculateScrollExtentsAtScale(scale)
        local x,y=ViewportWidth()/(2*canvasWidth*scale),ViewportHeight()/(2*canvasHeight*scale)
        return x,1-x,y,1-y
    end
    function scroll:GetCurrentScrollX() return rawget(self,"panX") or rawget(self,"targetX") end
    function scroll:GetCurrentScrollY() return rawget(self,"panY") or rawget(self,"targetY") end
    function scroll:SetPanTarget(x,y) self.targetX,self.targetY=x,y end
    function scroll:MarkCanvasDirty()
        if self.panX==self.targetX then self.panX=nil end
        if self.panY==self.targetY then self.panY=nil end
    end
    function scroll:InstantPanAndZoom(scale,x,y)
        assert(not combat or not map:IsProtected())
        local ratio=self:GetCanvasScale()/scale
        x=x+((self:GetCurrentScrollX() or .5)-x)*ratio
        y=y+((self:GetCurrentScrollY() or .5)-y)*ratio
        local xmin,xmax,ymin,ymax=self:CalculateScrollExtentsAtScale(scale)
        local function NativeClamp(value,low,high)
            if value>high then return high elseif value<low then return low end
            return value
        end
        x,y=NativeClamp(x,xmin,xmax),NativeClamp(y,ymin,ymax)
        self.targetX,self.targetY=x,y
        self.currentScale,self.panX,self.panY=scale,x,y
        offsetX=x*canvasWidth-ViewportWidth()/(2*scale)
        offsetY=y*canvasHeight-ViewportHeight()/(2*scale)
    end
    function map:OnFrameSizeChanged()
        fullRebuilds=fullRebuilds+1
        scroll:CreateZoomLevels()
        scroll.currentScale=scroll.zoomLevels[1].scale
        scroll.panX,scroll.panY=.5,.5
    end
    scroll:CreateZoomLevels()
    scroll.currentScale=scroll.zoomLevels[1].scale*3
    scroll.panX,scroll.panY=.73,.32
    offsetX=.73*1000-ViewportWidth()/(2*scroll.currentScale)
    offsetY=.32*700-ViewportHeight()/(2*scroll.currentScale)
    local held=true
    function IsMouseButtonDown(button) assert(button=='LeftButton'); return held end
    cursorX,cursorY=200,200
    Maps.resizeGrip.scripts.OnMouseDown(Maps.resizeGrip,'LeftButton')
    assert(Maps.resizing and Maps.resizeView)
    for i=1,12 do
        cursorX,cursorY=200+i*30,200-i*20
        Maps.resizeGrip.scripts.OnUpdate()
        assert(fullRebuilds==0,'resize must not reset canvas/providers on each mouse move')
        assert(math.abs(scroll.currentScale/scroll.zoomLevels[1].scale-3)<.000001)
        assert(math.abs(scroll:GetNormalizedHorizontalScroll()-.73)<.000001)
        assert(math.abs(scroll:GetNormalizedVerticalScroll()-.32)<.000001)
    end
    assert(Maps.viewportRebuildPending and fitUpdates==13)
    held=false; Maps.resizeGrip.scripts.OnUpdate() -- release outside the grip

    assert(not Maps.resizing and not Maps.resizeView and not Maps.viewportRebuildPending)
    assert(fitUpdates==14 and fullRebuilds==0)
    assert(math.abs(scroll.panX-.73)<.000001 and math.abs(scroll.panY-.32)<.000001,
        'releasing the corner must not recenter the zoomed view')
    Maps.resizeGrip.scripts.OnMouseUp(); assert(fitUpdates==14)
    held=true
    Maps.resizeGrip.scripts.OnMouseDown(Maps.resizeGrip,'LeftButton')
    cursorX,cursorY=cursorX+50,cursorY-30; Maps.resizeGrip.scripts.OnUpdate()
    map.protected=true; combat=true; local before=fitUpdates; Maps:FinishResize()
    assert(not Maps.resizing and fitUpdates==before and Maps.viewportRebuildPending)
    map.protected=nil; combat=false; Maps:Refresh(); assert(not Maps.viewportRebuildPending and fitUpdates==before+1)

    -- At fit zoom the letterboxed axis has inverted native scroll bounds.
    -- Native Clamp branches (rather than sorting these bounds): repeated calls
    -- used to alternate between the opposite edges when shrinking the window.
    for _,dimensions in ipairs({{1000,700},{1000,600},{1000,668}}) do
        canvasWidth,canvasHeight=dimensions[1],dimensions[2]
        scroll:CreateZoomLevels()
        scroll.currentScale=scroll.zoomLevels[1].scale
        scroll.panX,scroll.panY=.5,.5
        scroll:InstantPanAndZoom(scroll.currentScale,.5,.5)
        cursorX,cursorY=500,500; held=true
        Maps.resizeGrip.scripts.OnMouseDown(Maps.resizeGrip,'LeftButton')
        for _,delta in ipairs({-20,-40,-60,-80,-100,-80,-60,-40,0,30,60}) do
            cursorX,cursorY=500+delta,500-delta
            Maps.resizeGrip.scripts.OnUpdate()
            local xmin,xmax,ymin,ymax=scroll:CalculateScrollExtentsAtScale(scroll.currentScale)
            assert(xmin>xmax or ymin>ymax,'fixture must exercise a letterboxed fit axis')
            local expectedX=xmin>xmax+.0000001 and xmax or .5
            local expectedY=ymin>ymax+.0000001 and ymax or .5
            assert(math.abs(scroll.panX-expectedX)<.000001 and math.abs(scroll.panY-expectedY)<.000001,
                'fully zoomed out resize must keep the same native edge, without alternating')
        end
        held=false; Maps.resizeGrip.scripts.OnUpdate()
        -- Native full-step wheel handling does nothing when already at fit.
        -- Our post-hook must likewise leave both scale and pan untouched.
        scroll.overview='native-minimum-noop'
        Maps.extraZoomScale=nil; Maps.db.extendedZoom=true
        local beforeX,beforeY=scroll.panX,scroll.panY
        local beforeScale=scroll.currentScale
        for i=1,20 do
            Wheel(-1)
            assert(scroll.currentScale==beforeScale and scroll.panX==beforeX and scroll.panY==beforeY,
                'scrolling outward at minimum must not reapply native pan/clamp')
        end
        Wheel(1); assert(scroll.currentScale>beforeScale,'zoom in must still work after hitting minimum')
        scroll.overview=nil
    end
    print('PASS: outward wheel events at fit zoom do not move the canvas; zoom in remains available.')
    print('PASS: fully zoomed out resize remains stable with native inverted extents and Clamp branches.')
end

-- Alpha chrome: original button handlers/visibility survive docking, library
-- relayouts and disabling; protected frames and combat mutations are rejected.
if era then
    combat=false; map.maximized=false; Maps.windowDB.scale=1; map:Show()
    C_Map.GetMapInfo=function(id) return {name='Test zone',mapID=id} end
    C_Map.GetBestMapForUnit=function() return 1453 end
    C_Map.GetPlayerMapPosition=function() return {GetXY=function() return .42,.61 end} end
    local questie=Widget(scroll); questie.name='Krowi_WorldMapButtons1'; questie:SetSize(36,36)
    questie:SetPoint('TOPRIGHT',map,'TOPRIGHT',-4,-2)
    local hidden=Widget(scroll); hidden.name='Krowi_WorldMapButtons2'; hidden:SetSize(36,36); hidden:Hide()
    local silver=Widget(map); silver:SetSize(20,20)
    local native=Widget(map); native.name='BlizzardTrackingButton'
    local clicks=0
    questie:SetScript('OnClick',function() clicks=clicks+1 end)
    local handler=questie.scripts.OnClick
    local library={Buttons={questie,hidden,native},SetPoints=function() questie:ClearAllPoints(); questie:SetPoint('TOPRIGHT',map,'TOPRIGHT',-4,-2) end}
    LibStub=function(name)
        if name=='Krowi_WorldMapButtons-1.4' then return library end
        if name=='AceAddon-3.0' then return {GetAddon=function(_,addon)
            if addon~='SilverDragon' then return nil end
            return {GetModule=function(_,module) assert(module=='LDB'); return {worldmap=silver} end}
        end} end
    end
    Maps.db.customFrame=true; Maps:Refresh()
    assert(Maps.customFrame:IsShown() and map:GetScale()==Maps.originalScale)
    assert(scroll.points[1][4]==4 and scroll.points[1][5]==-36 and scroll.points[2][5]==24)
    assert(questie:GetParent()==Maps.customFrame.buttons and silver:GetParent()==Maps.customFrame.buttons)
    assert(hidden:GetParent()==Maps.customFrame.buttons and not hidden:IsShown(),'respect addon visibility preferences')
    assert(native:GetParent()==map,'do not adopt native overlay buttons')
    assert(questie:GetHeight()*questie:GetScale()==24,'toolbar icons should fit a single compact header')
    assert(Maps.customFrame.footer:GetHeight()==14,'empty info slots must not reserve a second footer row')
    for _,factor in ipairs({.6,1,1.6,3}) do
        Maps.windowDB.scale=factor; Maps:ApplyWindow()
        local width=map:GetWidth()+scroll.points[2][4]-scroll.points[1][4]
        local height=map:GetHeight()+scroll.points[1][5]-scroll.points[2][5]
        assert(math.abs(width/height-layer.layerWidth/layer.layerHeight)<.000001,
            'viewport must fit the map art without a blank side panel at any window size')
        assert(math.abs(map:GetHeight()-height-60)<.000001,'chrome overhead stays at 60 pixels')
    end
    Maps.windowDB.scale=1; Maps:ApplyWindow()
    local originalArtWidth,originalArtHeight=layer.layerWidth,layer.layerHeight
    for _,dimensions in ipairs({{512,512},{1002,668},{512,256}}) do
        layer.layerWidth,layer.layerHeight=dimensions[1],dimensions[2]
        map:OnMapChanged()
        local width=map:GetWidth()-8
        local height=map:GetHeight()-60
        assert(math.abs(width/height-dimensions[1]/dimensions[2])<.000001,
            'changing maps must refit the compact window to the new map art')
    end
    layer.layerWidth,layer.layerHeight=originalArtWidth,originalArtHeight
    Maps:Refresh()
    assert(questie.scripts.OnClick==handler); questie.scripts.OnClick(); assert(clicks==1)
    library.SetPoints(); assert(questie.points[1][2]==Maps.customFrame.buttons,'library relayout must return to dock')
    -- Deferred addon initialization must be handled even if the map stays
    -- closed until combat. LibStub upgrades replace functions on the same table.
    map:Hide()
    local late
    library.Buttons=nil
    library.Add=function(self)
        late=Widget(scroll); late.name='Krowi_WorldMapButtons4'; late:SetSize(36,36)
        late:SetPoint('TOPRIGHT',scroll,'TOPRIGHT',-100,-2)
        self.Buttons={questie,hidden,native,late}
        return late
    end
    library.SetPoints=function()
        for _,button in ipairs(library.Buttons or {}) do
            button:ClearAllPoints(); button:SetPoint('TOPRIGHT',scroll,'TOPRIGHT',-100,-2)
        end
    end
    Event('PLAYER_LOGIN')
    assert(library:Add()==late,'observing button creation must preserve its return value')
    assert(late:GetParent()==Maps.customFrame.buttons,'late buttons must dock before the map is opened')
    local hooked=library.SetPoints
    Maps:DiscoverFrameWidgets(); assert(library.SetPoints==hooked,'do not install the same hook repeatedly')
    combat=true; map:Show(); library.SetPoints()
    assert(late.points[1][2]==Maps.customFrame.buttons and questie.points[1][2]==Maps.customFrame.buttons,
        'replacement library relayout must preserve all docked buttons on first combat opening')
    combat=false
    Maps:UpdateFrameCoordinates(); assert(Maps.customFrame.coordinates:GetText():find('42.0, 61.0',1,true))
    local protected=Widget(map); protected.protected=true
    assert(not Maps:RegisterFrameWidget('protected',protected,'buttons'))
    assert(not Maps:RegisterFrameWidget('invalid',questie,'invalid'))
    assert(not Maps:RegisterFrameWidget('duplicate',questie,'buttons'))
    local info=Widget(map); info:SetPoint('CENTER',map,'CENTER',0,0)
    assert(Maps:RegisterFrameWidget('Timer test',info,'info-right'))
    Maps:LayoutCustomFrame(); assert(info:GetParent()==Maps.customFrame.footer)
    local mapWidth,mapHeight=map:GetSize()
    local mapProtected=rawget(map,'protected')
    map.protected=true; combat=true
    library.SetPoints()
    assert(questie:GetParent()==Maps.customFrame.buttons and questie.points[1][1]=='TOPLEFT'
        and questie.points[1][2]==Maps.customFrame.buttons,'combat library relayout returns to the existing dock')
    scroll:ClearAllPoints()
    scroll:SetPoint('TOPLEFT',map,'TOPLEFT',20,-22)
    scroll:SetPoint('BOTTOMRIGHT',map,'BOTTOMRIGHT',-10,28)
    Maps:Refresh()
    assert(scroll.points[1][4]==4 and scroll.points[1][5]==-36 and scroll.points[2][5]==24,
        'combat refresh restores the cached viewport inset without resizing the protected map')
    assert(map:GetWidth()==mapWidth and map:GetHeight()==mapHeight)
    questie.protected=true
    questie.points={{'TOPRIGHT',map,'TOPRIGHT',-4,-2}}
    Maps:RestoreCombatFrame()
    assert(questie.points[1][1]=='TOPRIGHT','a widget that becomes protected must be left alone')
    questie.protected=false
    questie.parent=scroll
    Maps:RestoreCombatFrame()
    assert(questie:GetParent()==scroll,'combat repair must not reparent addon widgets')
    combat=false; map.protected=mapProtected; Maps:LayoutCustomFrame()
    local before=questie.points[1]
    map.protected=true; combat=true; Maps.db.customFrame=false; Maps:Refresh()
    assert(Maps.customFrame:IsShown() and questie.points[1]==before,'combat defers all frame/anchor changes')
    combat=false; map.protected=nil; Maps:Refresh()
    assert(not Maps.customFrame:IsShown() and questie:GetParent()==scroll and info:GetParent()==map)
    assert(questie.scripts.OnClick==handler and not hidden:IsShown() and questie:GetScale()==1)
    Maps.db.customFrame=true; Maps:Refresh(); map:Maximize()
    assert(not Maps.customFrame:IsShown() and questie:GetParent()==scroll,'fullscreen restores native widget layout')
    map:Minimize(); assert(Maps.customFrame:IsShown() and questie:GetParent()==Maps.customFrame.buttons)
    Maps.db.customFrame=false; Maps:Refresh()
    LibStub=nil
    print('PASS: alpha frame docking, original addon callbacks, coordinates, restoration, fullscreen and combat guards.')
else
    assert(not Maps.customFrame,'Forever retains its tested native layout during the Era frame alpha')
end

if era then
    combat=false; map.maximized=false; map:Show()
    local nova={worldBuffMapMarkerTypes={ony={name='Onyxia'},nef={name='Nefarian'}},data={layers={}}}
    LibStub=function(name)
        if name=='AceAddon-3.0' then return {GetAddon=function(_,addon)
            if addon=='NovaWorldBuffs' then return nova end
        end} end
    end
    local novaClicks=0
    local function Marker(text)
        local source=Widget(map); source:SetSize(23,23)
        source:SetAlpha(.8); source:EnableMouse(true)
        source:SetPoint('CENTER',map,'CENTER',200,-150)
        source.timerFrame=Widget(source); source.timerFrame.fs=Widget(source.timerFrame)
        source.timerFrame.fs:SetText(text)
        source.texture=Widget(source); source.texture:SetTexture(12345)
        source:SetScript('OnHide',function() source.timerFrame:Hide() end)
        source:SetScript('OnShow',function() source.timerFrame:Show() end)
        source:SetScript('OnMouseDown',function(owner,button)
            assert(owner==source and button=='LeftButton'); novaClicks=novaClicks+1
        end)
        return source
    end
    onyNWBWorldMap=Marker('3h48m'); nefNWBWorldMap=Marker('--')
    nefNWBWorldMap.fs=Widget(nefNWBWorldMap)
    nefNWBWorldMap.fs:SetText('Type /buffs to view all your characters world buffs.')
    -- Fresh reload: Nova creates all marker Frames shown, before HBD has
    -- acquired a pin for any of them on the currently opened unrelated zone.
    Maps.db.customFrame=true; Maps:Refresh()
    local ony=Maps.novaTimers.onyNWBWorldMap
    local nef=Maps.novaTimers.nefNWBWorldMap
    assert(not ony.button:IsShown() and not nef.button:IsShown() and Maps.novaRowHeight==0,
        'first map open must not treat unassigned, default-shown Nova frames as eligible timers')
    local function AcquireNovaPin(source)
        local pin=Widget(map); pin.icon=source
        source:SetParent(pin); source:ClearAllPoints(); source:SetPoint('CENTER',pin,'CENTER',0,0)
        return pin
    end
    local onyPin=AcquireNovaPin(onyNWBWorldMap)
    Maps:UpdateNovaTimers()
    assert(ony.button:IsShown() and not nef.button:IsShown(),'only markers assigned to actual map pins are eligible')
    onyPin:Hide(); Maps:UpdateNovaTimers()
    assert(not ony.button:IsShown(),'a hidden provider pin must not leave a timer visible')
    onyPin:Show(); Maps:UpdateNovaTimers()
    assert(ony.button:IsShown())
    AcquireNovaPin(nefNWBWorldMap)
    local originalAnchor=onyNWBWorldMap.points[1]
    Maps:Refresh()
    assert(ony.button:IsShown() and nef.button:IsShown() and Maps.novaRowHeight==24)
    assert(ony.text:GetText()=='3h48m' and nef.text:GetText()=='--','copy Nova timer text, including unknown values')
    assert(onyNWBWorldMap:GetAlpha()==0 and not onyNWBWorldMap:IsMouseEnabled())
    assert(onyNWBWorldMap:IsShown() and onyNWBWorldMap.timerFrame:IsShown(),
        'keep Nova Show/Hide state and original OnUpdate alive')
    assert(onyNWBWorldMap:GetParent()==onyPin and onyNWBWorldMap.points[1]==originalAnchor,
        'never move or reparent HereBeDragons pins')
    ony.button.scripts.OnMouseDown(ony.button,'LeftButton'); assert(novaClicks==1)
    local oldTooltip=GameTooltip
    local tooltipLines={}
    GameTooltip={SetOwner=function() end,SetText=function() end,Show=function() end,
        AddLine=function(_,text,r,g,b,wrap) tooltipLines[#tooltipLines+1]={text=text,wrap=wrap} end}
    ony.button.scripts.OnEnter()
    local foundHint=false
    for _,line in ipairs(tooltipLines) do
        if line.text==nefNWBWorldMap.fs:GetText() then foundHint=line.wrap==true end
    end
    assert(foundHint,'every mirrored buff icon shows the complete wrapped Nova /buffs hint')
    GameTooltip=oldTooltip
    onyNWBWorldMap:Hide(); Maps:UpdateNovaTimers()
    assert(not ony.button:IsShown() and nef.button:IsShown(),'native zone/faction/settings visibility is authoritative')
    nefNWBWorldMap:Hide(); Maps.customFrame.scripts.OnUpdate(Maps.customFrame,.2)
    assert(Maps.novaRowHeight==0,'zones without Nova markers reserve no timer row')
    onyNWBWorldMap:Show(); Maps.customFrame.scripts.OnUpdate(Maps.customFrame,.2)
    assert(Maps.novaRowHeight==24 and ony.button:IsShown())
    combat=true; Maps.db.customFrame=false
    onyNWBWorldMap.timerFrame.fs:SetText('3h47m'); Maps:UpdateNovaTimers()
    assert(ony.text:GetText()=='3h47m' and onyNWBWorldMap:GetAlpha()==0,
        'timer text can keep updating while original restoration waits for combat')
    combat=false; Maps:Refresh()
    assert(not ony.button:IsShown() and Maps.novaRowHeight==0)
    assert(onyNWBWorldMap:GetAlpha()==.8 and onyNWBWorldMap:IsMouseEnabled())
    assert(onyNWBWorldMap.points[1]==originalAnchor)
    Maps.db.customFrame=true; Maps:Refresh(); map:Maximize()
    assert(onyNWBWorldMap:GetAlpha()==.8 and not ony.button:IsShown(),'fullscreen restores the original Nova display')
    map:Minimize(); assert(onyNWBWorldMap:GetAlpha()==0 and ony.button:IsShown())
    nova.data.layers[99]={}; ony99NWBWorldMap=Marker('2h10m')
    Maps:Refresh(); assert(Maps.novaTimers.ony99NWBWorldMap.layer==99,'discover late-created layer timers')
    nova.data.layers[77]={}; nef77NWBWorldMap=Marker('protected'); nef77NWBWorldMap.protected=true
    Maps:Refresh(); assert(not Maps.novaTimers.nef77NWBWorldMap,'skip protected source frames')
    local oldSource=onyNWBWorldMap
    onyNWBWorldMap=Marker('replacement')
    Maps:Refresh()
    assert(not Maps.novaTimers.onyNWBWorldMap.button:IsShown(),'a recreated unassigned marker must stay hidden too')
    assert(Maps.novaTimers.onyNWBWorldMap.source==onyNWBWorldMap and oldSource:GetAlpha()==.8,
        'handle Nova recreating a marker without leaving the old source masked')
    Maps.db.customFrame=false; Maps:Refresh()
    LibStub=nil; onyNWBWorldMap=nil; nefNWBWorldMap=nil; ony99NWBWorldMap=nil; nef77NWBWorldMap=nil
    print('PASS: Nova source-driven zone/layer visibility, live/unknown timers, click forwarding, no pin movement, restoration and combat deferral.')
end

-- The native CVar is the source of truth, including edits outside our menu.
do
    local opacity=.35
    local previousCVar,previousNative=C_CVar,WorldMapFrame_SetOpacity
    C_CVar={GetCVar=function(key) assert(key=='worldMapOpacity'); return tostring(opacity) end,
        SetCVar=function(key,value) assert(key=='worldMapOpacity'); opacity=tonumber(value); Event('CVAR_UPDATE',key) end}
    local nativeCalls=0
    WorldMapFrame_SetOpacity=function(value)
        nativeCalls=nativeCalls+1
        map:SetAlpha(1-.5*value); scroll:SetAlpha(1-.65*value)
    end
    Maps:ApplyMapOpacity(); assert(Maps:GetMapTransparency()==.35 and nativeCalls==1)
    Maps.optionsUI.opacity.scripts.OnValueChanged(Maps.optionsUI.opacity,60)
    assert(opacity==.6 and math.abs(map:GetAlpha()-.7)<.000001 and math.abs(scroll:GetAlpha()-.61)<.000001)
    if era then
        Maps.db.customFrame=true; Maps:Refresh(); local modern=map:GetAlpha()
        Maps.db.customFrame=false; Maps:Refresh(); assert(map:GetAlpha()==modern and opacity==.6)
    end
    map:Maximize(); assert(map:GetAlpha()==1 and scroll:GetAlpha()==1 and opacity==.6)
    map:Minimize(); assert(math.abs(map:GetAlpha()-.7)<.000001)
    opacity=.3; Event('CVAR_UPDATE','WORLD_MAP_OPACITY')
    assert(Maps.optionsUI.opacity.value==30 and math.abs(map:GetAlpha()-.85)<.000001, tostring(Maps.optionsUI.opacity.value)..' / '..tostring(map:GetAlpha())..' / '..tostring(opacity))
    if era then
        GameTooltip=Widget(UIParent)
        Maps.db.customFrame=true; Maps:Refresh()
        local header=Maps.customHeader
        header.scripts.OnClick(header,'RightButton')
        local popup=Maps.opacityPopup
        assert(popup:IsShown() and popup.slider.value==30)
        assert(popup:GetWidth()==260 and popup:GetHeight()==70 and popup.points[1][1]=='BOTTOMLEFT'
            and popup.points[1][3]=='TOPLEFT','prefer compact popup above the title')
        local hover=false
        popup.IsMouseOver=function() return hover end
        hover=true; Event('GLOBAL_MOUSE_DOWN','LeftButton'); assert(popup:IsShown(),'inside click must retain the slider')
        hover=false; Event('GLOBAL_MOUSE_DOWN','LeftButton'); assert(not popup:IsShown(),'outside click dismisses without intercepting the click')
        header.scripts.OnClick(header,'RightButton')
        local oldHover=header.IsMouseOver
        header.IsMouseOver=function() return true end
        Event('GLOBAL_MOUSE_DOWN','RightButton'); assert(popup:IsShown())
        header.scripts.OnClick(header,'RightButton'); assert(not popup:IsShown(),'second title right-click must not reopen the popup')
        header.IsMouseOver=oldHover; header.scripts.OnClick(header,'RightButton')
        local oldTop,oldLeft,oldWidth=header.GetTop,map.GetLeft,map.GetWidth
        header.GetTop=function() return UIParent:GetHeight()-1 end
        map.GetLeft=function() return 10 end; map.GetWidth=function() return 500 end
        Maps:PlaceOpacityPopup(header); assert(popup.points[1][1]=='TOPLEFT' and popup.points[1][3]=='TOPRIGHT')
        map.GetLeft=function() return 1200 end
        Maps:PlaceOpacityPopup(header); assert(popup.points[1][1]=='TOPRIGHT' and popup.points[1][3]=='TOPLEFT')
        map.GetLeft=function() return 10 end; map.GetWidth=function() return 1900 end
        Maps:PlaceOpacityPopup(header); assert(popup.points[1][3]=='BOTTOMLEFT')
        header.GetTop,map.GetLeft,map.GetWidth=oldTop,oldLeft,oldWidth
        Maps:PlaceOpacityPopup(header)
        popup.slider:SetValue(42)
        assert(opacity==.42 and Maps.optionsUI.opacity.value==42 and popup.slider.value==42)
        opacity=.25; Event('CVAR_UPDATE','worldMapOpacity'); assert(popup.slider.value==25)
        header.scripts.OnClick(header,'RightButton'); assert(not popup:IsShown())
        header.scripts.OnClick(header,'RightButton'); map:Hide(); assert(not popup:IsShown())
        map:Show(); header.scripts.OnClick(header,'RightButton'); map:Maximize()
        assert(not popup:IsShown()); map:Minimize()
        local escaped=false
        for _,name in ipairs(UISpecialFrames) do if name=='PatchToolsMapsOpacityPopup' then escaped=true end end
        assert(escaped,'quick opacity popup must support Escape dismissal')
        Maps.db.customFrame=false; Maps:Refresh()
    end
    combat=true; local before=map:GetAlpha(); Maps:SetMapTransparency(.8)
    assert(opacity==.8 and map:GetAlpha()==before,'combat must defer map alpha calls')
    combat=false; Event('PLAYER_REGEN_ENABLED'); assert(math.abs(map:GetAlpha()-.6)<.000001)
    C_CVar=nil; WorldMapFrame_SetOpacity=nil
    Maps:SetMapTransparency(2); assert(Maps.db.transparency==1 and map:GetAlpha()==.5 and scroll:GetAlpha()==.35)
    Maps:SetMapTransparency(0/0); assert(Maps.db.transparency==0)
    C_CVar,WorldMapFrame_SetOpacity=previousCVar,previousNative
    Maps.db.transparency=nil
end
print('PASS: shared native map opacity, external CVar edits, fullscreen policy, combat deferral and clients without native opacity helpers.')

if era then
    local container=Widget(canvas); container:SetSize(40,40); container:SetAlpha(.8)
    local checkbox=Widget(container); checkbox:SetSize(24,24); checkbox:SetPoint('TOPLEFT',100,-50)
    checkbox:EnableMouse(true); checkbox:SetChecked(true)
    checkbox.label=Widget(container); checkbox.label:SetPoint('LEFT',checkbox,'RIGHT',0,0)
    container.heatmap_checkbox=checkbox; DeathlogHeatmapCheckbox=checkbox
    local clicked=0
    checkbox:SetScript('OnClick',function()
        clicked=clicked+1; checkbox:SetChecked(not checkbox:GetChecked())
        container:SetParent(canvas) -- As Deathlog's own applySettings does.
    end)
    local handler=checkbox.scripts.OnClick
    Maps.db.customFrame=true; Maps:Refresh()
    local action=Maps.deathlogControl.button
    assert(action:GetParent()==Maps.customFrame.buttons and action:IsShown())
    assert(action.border.texture==136430 and action.icon.vertexColor[1]==1 and rawget(action,"state")==nil)
    assert(container:GetParent()==canvas and container:GetWidth()==40 and container:GetAlpha()==0)
    assert(checkbox:GetParent()==container and checkbox.label:GetParent()==container)
    assert(checkbox.points[1][1]=='TOPLEFT' and checkbox.scripts.OnClick==handler and not checkbox:IsMouseEnabled())
    action.scripts.OnClick(action,'LeftButton')
    assert(clicked==1 and not checkbox:GetChecked() and not action.icon.desaturated and rawget(action,"state")==nil)
    action.scripts.OnClick(action,'RightButton'); assert(clicked==1)
    GameTooltip=Widget(UIParent)
    action.scripts.OnEnter(); assert(GameTooltip.text:find(Maps:T('STATE_OFF'),1,true))
    assert(GameTooltip.anchor=='ANCHOR_TOP' and GameTooltip.points[1][1]=='BOTTOM'
        and GameTooltip.points[1][2]==action and GameTooltip.points[1][3]=='TOP')
    container:Hide(); Maps:Refresh(); assert(not action:IsShown(),'respect Deathlog checkbox visibility preference')
    container:Show(); Maps:Refresh(); assert(action:IsShown())
    local stats=Widget(UIParent); DeathlogHeatmapCheckbox=Widget(stats)
    Maps:Refresh(); assert(Maps.deathlogControl.checkbox==checkbox,'ignore statistics-window checkbox')
    combat=true; action.scripts.OnClick(action,'LeftButton'); assert(clicked==1,'defer native toggle in combat')
    Maps.db.customFrame=false; Maps:Refresh(); assert(container:GetAlpha()==0)
    combat=false; Event('PLAYER_REGEN_ENABLED')
    assert(container:GetParent()==canvas and container:GetAlpha()==.8 and checkbox:IsMouseEnabled())
    assert(not action:IsShown() and checkbox.scripts.OnClick==handler)
    Maps.db.customFrame=true; Maps:Refresh(); map:Maximize()
    assert(container:GetAlpha()==.8 and not action:IsShown())
    map:Minimize(); assert(container:GetAlpha()==0 and action:IsShown())
    Maps.db.customFrame=false; Maps:Refresh(); DeathlogHeatmapCheckbox=nil
    print('PASS: Deathlog header icon toggles the original handler, mirrors active/visible state, keeps native anchors untouched and restores Classic/fullscreen behavior.')

    -- Simple action registrations and automatic toolbar overflow.
    Maps.db.customFrame=true
    local oldWidgets=#Maps.frameWidgets
    local clicks,visible,active=0,true,false
    local ok,button=Maps:RegisterMapAction('Test.simple',{
        icon=134400,tooltip='Test action',isActive=function() return active end,
        isShown=function() return visible end,onClick=function() clicks=clicks+1; active=not active end})
    assert(ok and not Maps:RegisterMapAction('Test.simple',{icon=134400,onClick=function() end}))
    assert(not Maps:RegisterMapAction('Invalid',{icon=134400}))
    Maps:Refresh(); button.scripts.OnClick(button,'LeftButton')
    assert(clicks==1 and not button.icon.desaturated)
    visible=false; Maps:Refresh(); assert(not button:IsShown())
    local external=Widget(map); external:SetSize(24,24)
    local entered=0
    external:SetScript('OnEnter',function()
        entered=entered+1; GameTooltip:SetOwner(external,'ANCHOR_BOTTOM')
        GameTooltip:SetText('External addon tooltip'); GameTooltip:Show()
    end)
    local originalEnter=external.scripts.OnEnter
    assert(Maps:RegisterFrameWidget('Test.externalTooltip',external,'buttons'))
    assert(external.scripts.OnEnter==originalEnter,'do not hook foreign tooltip scripts')
    Maps:Refresh(); external.scripts.OnEnter()
    assert(entered==1 and GameTooltip.text=='External addon tooltip' and GameTooltip.anchor=='ANCHOR_BOTTOM',
        'external addons keep their own tooltip placement without jumping')
    local elsewhere=Widget(UIParent)
    GameTooltip:SetOwner(elsewhere,'ANCHOR_BOTTOM'); GameTooltip:ClearAllPoints()
    Maps:PositionHeaderTooltip(external); assert(#GameTooltip.points==0,'leave unrelated tooltips untouched')
    Maps.db.customFrame=false; Maps:Refresh()
    GameTooltip:SetOwner(external,'ANCHOR_BOTTOM'); GameTooltip:ClearAllPoints()
    Maps:PositionHeaderTooltip(external); assert(#GameTooltip.points==0,'Classic keeps native tooltip placement')
    Maps.db.customFrame=true
    for i=1,30 do assert(Maps:RegisterMapAction('Test.extra'..i,{icon=134400,onClick=function() end})) end
    Maps:Refresh()
    local toolbar=Maps:GetToolbarLayout(500)
    assert(toolbar.stacked and toolbar.rows>1 and toolbar.extraHeight==toolbar.rows*27)
    for _,item in pairs(toolbar.items) do assert(item.x+item.width<=482+.00001) end
    local _,top=Maps:GetCustomFrameInsets(500); assert(top==-36-toolbar.extraHeight)
    local previousScale=Maps.windowDB.scale
    for _,factor in ipairs({.6,1,2}) do
        Maps.windowDB.scale=factor; Maps:Refresh()
        assert(math.abs(map:GetHeight()-Maps:GetCustomFrameHeight(map:GetWidth()))<.00001,
            'toolbar row changes must preserve the map viewport aspect ratio while resizing')
    end
    Maps.windowDB.scale=previousScale
    -- Remove fixture-only registrations, preserving the live adapters.
    for i=#Maps.frameWidgets,oldWidgets+1,-1 do
        local entry=table.remove(Maps.frameWidgets,i); entry.frame:Hide(); Maps.mapActions[entry.id]=nil
    end
    Maps:Refresh(); assert(not Maps:GetToolbarLayout(2000).stacked)
    print('PASS: simple icon action API, click/state/visibility updates, duplicate validation and title-above-toolbar wrapping without horizontal overflow.')
end

if era then
    combat=false; map.maximized=false; Maps.db.customFrame=true
    local nativeClick=WorldMapFrameCloseButton:GetScript('OnClick')
    Maps.nativeCloseAppearance.mouse=true
    for _,factor in ipairs({.6,.7,1,2}) do
        map:Show(); Maps.windowDB.scale=factor; Maps:Refresh()
        local close=Maps.customCloseButton
        assert(close:IsShown() and close:GetWidth()==32 and close:GetHeight()==32)
        local point,relative,relativePoint,x,y=close:GetPoint(1)
        assert(point=='TOPRIGHT' and relative==map and relativePoint=='TOPRIGHT' and x==-4 and y==-3)
        assert(close:GetScale()==1,'close hit area stays fixed')
        assert(HasTemplate(close,'UIPanelCloseButton') and not HasTemplate(close,'SecureActionButtonTemplate'))
        assert(close:GetParent()==map and not map:IsProtected(),'our close control must not protect the map')
        assert(close:GetScript('OnClick')==nil,'retain the inherited XML handler without addon click forwarding')
        close:Click('LeftButton'); assert(not map:IsShown())
    end
    map:Show(); Maps.windowDB.x=.17; Maps.windowDB.y=.82; Maps:Refresh()
    local width,height=map:GetSize()
    local wanted={map:GetPoint(1)}
    combat=true
    for _=1,2 do
        map:Show()
        -- Native Minimize resets dimensions and the panel manager resets anchors
        -- after OnShow. This is distinct from resetting only the canvas insets.
        map:SetSize(610,438); map:ClearAllPoints(); map:SetPoint('TOPLEFT',UIParent,'TOPLEFT',0,-104)
        scroll:ClearAllPoints(); scroll:SetPoint('TOPLEFT',map,'TOPLEFT',20,-22)
        scroll:SetPoint('BOTTOMRIGHT',map,'BOTTOMRIGHT',-10,28)
        Maps:Refresh()
        assert(map:GetWidth()==width and map:GetHeight()==height,'combat opening restores saved outer dimensions')
        local actual={map:GetPoint(1)}
        for i=1,5 do assert(actual[i]==wanted[i],'combat opening restores saved window position') end
        assert(scroll.points[1][4]==4 and scroll.points[1][5]==-36,'combat canvas remains aligned')
        Maps.customCloseButton:Click('LeftButton',true); assert(map:IsShown())
        Maps.customCloseButton:Click('LeftButton'); assert(not map:IsShown(),'native XML close works in combat')
    end
    map:Show(); assert(PressEscape() and not map:IsShown(),'native Escape closes in combat')
    assert(not escapeTarget,'no override binding should remain')
    map.protected=true; map.width=610
    Maps:RestoreCombatWindow(); assert(map:GetWidth()==610,'respect protection introduced by other addons')
    map.protected=nil; combat=false; map:Show(); Maps:Refresh()
    Maps.db.customFrame=false; Maps:Refresh()
    assert(not Maps.customCloseButton:IsShown() and WorldMapFrameCloseButton:IsMouseEnabled())
    assert(WorldMapFrameCloseButton:GetScript('OnClick')==nativeClick)
    Maps.db.customFrame=true; Maps:Refresh()
    map:Maximize(); assert(not Maps.customCloseButton:IsShown())
    map:Minimize(); assert(Maps.customCloseButton:IsShown())
    print('PASS: unprotected native close, saved combat window dimensions/position, native Escape and Classic/fullscreen restoration.')
end

if era then
    combat=false; map.protected=nil; map.maximized=false; Maps.db.customFrame=true
    Maps.db.extendedZoom=true; Maps.db.resizable=true; Maps.db.movable=true
    map:Show(); Maps:Refresh()
    scroll.currentScale=scroll.zoomLevels[1].scale; Maps.extraZoomScale=nil
    local secureBefore=secureCalls
    combat=true
    Wheel(1)
    assert(Maps.zoomDiagnostics.reason=='applied' and scroll.currentScale>scroll.zoomLevels[1].scale,
        'unprotected Era map supports the extended wheel zoom in combat')
    local previousMouseDown=IsMouseButtonDown
    IsMouseButtonDown=function() return true end
    local width=map:GetWidth()
    cursorX,cursorY=500,500
    Maps.resizeGrip.scripts.OnMouseDown(Maps.resizeGrip,'LeftButton')
    assert(Maps.resizing and Maps.resizeGrip.scripts.OnUpdate)
    Event('PLAYER_REGEN_DISABLED')
    assert(Maps.resizing,'combat alone must not cancel an unprotected resize')
    cursorX,cursorY=580,460
    Maps.resizeGrip.scripts.OnUpdate()
    assert(map:GetWidth()>width,'dragging the corner changes size during combat')
    Maps.resizeGrip.scripts.OnMouseUp()
    assert(not Maps.resizing and Maps.combatWindow.width==map:GetWidth())
    Maps.dragBar.scripts.OnDragStart()
    assert(Maps.moving)
    local x=Maps.windowDB.x
    cursorX=cursorX+40; Maps.moveDriver.scripts.OnUpdate()
    assert(Maps.windowDB.x~=x,'header movement also works in combat')
    Maps.dragBar.scripts.OnDragStop()
    assert(secureCalls==secureBefore,'ordinary combat map operations must not rely on securecallfunction')
    Maps.resizeGrip.scripts.OnMouseDown(Maps.resizeGrip,'LeftButton')
    width=map:GetWidth(); map.protected=true
    cursorX=cursorX+40; Maps.resizeGrip.scripts.OnUpdate()
    assert(not Maps.resizing and map:GetWidth()==width,'protection appearing mid-drag stops without mutation')
    local canvas=map:GetCanvas(); map.protected=nil; canvas.protected=true
    assert(not Maps:CanUseMapInCombat(),'protected canvas prevents extended zoom and resize')
    canvas.protected=nil; combat=false; IsMouseButtonDown=previousMouseDown
    Maps:Refresh()
    print('PASS: combat wheel zoom, resizing and movement on unprotected Era frames; live protection guards.')
end

local account=PatchToolsMapsDB
local first=Maps.windowDB
first.scale=.7; first.x=.3; first.y=.9
local register=PT.RegisterOptionsPage
PT.RegisterOptionsPage=function() return false end
PatchToolsMapsCharacterDB=nil; Maps.initialized=nil; Maps:Initialize()
assert(Maps.windowDB~=first and Maps.windowDB.scale==1 and Maps.windowDB.x==.2)
Maps.windowDB.scale=1.2
PatchToolsMapsCharacterDB=first; Maps:Initialize()
assert(Maps.windowDB.scale==.7 and Maps.windowDB.x==.3 and Maps.db==account)
Maps:ResetWindow(); Maps:Initialize()
assert(Maps.windowDB.scale==1 and Maps.windowDB.x==nil,'reset survives another initialization')
assert(account.scale==1 and account.x==.2,'legacy global geometry remains unchanged')
PT.RegisterOptionsPage=register
print('PASS: map character migration, isolation and reset without importing old geometry again.')
