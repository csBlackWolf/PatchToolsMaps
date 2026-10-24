local frames={}
unpack=table.unpack or unpack
local combat=false
local cursorX,cursorY=100,100
local function Widget(parent)
    local w={parent=parent,scripts={},events={},shown=true,width=1000,height=700,scale=1,points={},frameLevel=1}
    local methods={}
    function methods:SetScript(k,v) self.scripts[k]=v end
    function methods:HookScript(k,v)
        local old=self.scripts[k]
        self.scripts[k]=function(...) if old then old(...) end; v(...) end
    end
    function methods:RegisterEvent(k) self.events[k]=true end
    function methods:SetSize(x,y) self.width,self.height=x,y end
    function methods:SetWidth(x) self.width=x end
    function methods:SetHeight(y) self.height=y end
    function methods:GetWidth() return self.width end
    function methods:GetHeight() return self.height end
    function methods:GetSize() return self.width,self.height end
    function methods:SetPoint(...) self.points[#self.points+1]={...} end
    function methods:ClearAllPoints() self.points={} end
    function methods:GetNumPoints() return #self.points end
    function methods:GetPoint(i) return unpack(self.points[i]) end
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
    function methods:GetText() return self.text end
    function methods:SetChecked(s) self.checked=s end
    function methods:GetChecked() return self.checked end
    function methods:Show() self.shown=true; if self.scripts.OnShow then self.scripts.OnShow(self) end end
    function methods:Hide() self.shown=false; if self.scripts.OnHide then self.scripts.OnHide(self) end end
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
function CreateFrame(_,name,parent)
    local w=Widget(parent); w.TitleText=Widget(w); frames[#frames+1]=w
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
function HideUIPanel(frame) panelCloses=panelCloses+1; frame:Hide() end
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
-- Without the module, the Map entry offers installation and feature information.
PT:CreateOptions()
assert(PT.optionPages.maps==PT.mapsPlaceholder)
PT:SelectOptionsPage('maps'); assert(PT.mapsPlaceholder:IsShown())
assert(PT.optionNavigation.maps.points[1][3]>PT.optionNavigation.about.points[1][3])
local placeholder=PT.mapsPlaceholder
PT:SelectOptionsPage('general')
assert(PT:SelectOptionsPage('missing')==false and PT.optionPages.general:IsShown())
local Maps={}
for _,name in ipairs({'Locales.lua','OverlayData.lua','GeneratedCatalog.lua','GeneratedCatalogEra.lua','Reveal.lua','Zoom.lua','Window.lua','Options.lua','Core.lua'}) do
    assert(loadfile(MAPS_PATH..name))('PatchToolsMaps',Maps)
end
Event('ADDON_LOADED','PatchToolsMaps')
assert(Maps.initialized and Maps.db.mode=='mist' and PT.optionPages.maps)
assert(Maps.db.extendedZoom==true,'new installations enable map zoom by default')
assert(not PT.mapsPlaceholder and PT.optionPages.maps~=placeholder and not placeholder:IsShown())
assert(PT.optionNavigation.maps.points[1][3]>PT.optionNavigation.about.points[1][3])
assert(not PT:RegisterOptionsPage('maps','Duplicate',function() error('duplicate builder ran') end))
assert(not PT:RegisterOptionsPage('about','Reserved',function() end))
assert(not Maps.map)
PT:SelectOptionsPage('maps'); assert(PT.optionPages.maps:IsShown())
assert(Maps.optionsUI.checks.movable.checked==true)
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
Maps.db.scale=1.3; Maps:Refresh(); assert(math.abs(WindowFactor()-1.3)<.00001)
map:Maximize(); assert(map.scale==1 and not Maps.dragBar:IsShown())
map:Minimize(); assert(math.abs(WindowFactor()-1.3)<.00001 and Maps.dragBar:IsShown())
combat=true; Maps.db.scale=.8; Maps:Refresh(); assert(math.abs(WindowFactor()-1.3)<.00001)
Maps.db.extendedZoom=true; Maps:Refresh(true); assert(#scroll.zoomLevels==2)
combat=false; Event('PLAYER_REGEN_ENABLED'); assert(math.abs(WindowFactor()-.8)<.00001 and #scroll.zoomLevels==2)
Maps.dragBar.scripts.OnDragStart(); assert(Maps.moving)
Maps.dragBar.scripts.OnDragStop(); assert(not Maps.moving and Maps.db.x and Maps.db.y)
Maps.dragBar.scripts.OnDragStart()
combat=true; Event('PLAYER_REGEN_DISABLED')
assert(not Maps.moving and not Maps.moveDriver.scripts.OnUpdate)
assert(Maps.dragBar:IsShown() and Maps.resizeGrip:IsShown())
Maps.resizeGrip.scripts.OnMouseDown(Maps.resizeGrip,'LeftButton')
assert(Maps.resizeGrip:IsShown() and not Maps.resizeGrip.scripts.OnUpdate)
combat=false; Event('PLAYER_REGEN_ENABLED')
Maps.resizeGrip.scripts.OnMouseDown(Maps.resizeGrip,'LeftButton')
cursorX,cursorY=100000,-100000
Maps.resizeGrip.scripts.OnUpdate(); assert(Maps.db.scale>1.5)
Maps.resizeGrip.scripts.OnMouseUp(); assert(not Maps.resizeGrip.scripts.OnUpdate)
Maps:ResetWindow(); assert(map.scale==1 and Maps.db.x==nil and Maps.db.y==nil)
-- Full reset is wired to the options button, including native view/zoom.
local anchor=Maps.resizeGrip.points[1]
assert(anchor[1]=='BOTTOMRIGHT' and anchor[2]==map and anchor[3]=='BOTTOMRIGHT')
assert(anchor[4]==2 and anchor[5]==-2)
assert(Maps.resizeGrip.width==20 and Maps.resizeGrip.height==20)
if era then assert(Maps.dragBar==WorldMapTitleButton and not Maps.ownsDragBar and nativeDragCalls>0 and Maps.dragBar.scripts.OnUpdate)
else assert(Maps.dragBar.height==19 and #Maps.dragBar.points==2) end
Maps.db.extendedZoom=true; Maps.db.scale=1.4; Maps.db.x=.4; Maps.db.y=.6
Maps:Refresh(true); scroll.currentScale=4; scroll.panX,scroll.panY=.9,.1
Maps.optionsUI.reset.scripts.OnClick()
assert(not map:IsShown() and panelCloses==1)
assert(secureCalls>=2)
assert(map.scale==1 and Maps.db.x==nil and Maps.db.y==nil and Maps.db.extendedZoom)
assert(#scroll.zoomLevels==2 and scroll.currentScale==1 and scroll.panX==.5 and scroll.panY==.5)
assert(Maps.optionsUI.checks.extendedZoom.checked==true)
map:Show()
local resets=scroll.resets
combat=true; Maps.db.extendedZoom=true; Maps.db.scale=1.2
Maps:ResetMap(); assert(scroll.resets==resets and Maps.resetViewPending and Maps.resetPending)
assert(map:IsShown() and panelCloses==1) -- protected UI close waits for combat to end
combat=false; Event('PLAYER_REGEN_ENABLED')
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
assert(Maps.db.x<0 and Maps.db.y>1)
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
combat=true; local secureBefore=secureCalls
Wheel(1); assert(secureCalls==secureBefore and scroll.currentScale==2)
SlashCmdList.PATCHTOOLSMAPS('reset')
assert(Maps.resetPending and map:IsShown())
combat=false; Event('PLAYER_REGEN_ENABLED')
assert(not map:IsShown() and Maps.db.scale==1 and not Maps.db.x and not Maps.db.y)
map:Show(); Maps.db.scale=5; Maps.db.x=-2; Maps.db.y=3; Maps:ApplyWindow()
SlashCmdList.PATCHTOOLSMAPS('reset')
assert(not map:IsShown() and Maps.db.scale==1 and not Maps.db.x and not Maps.db.y)
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
    Maps.db.extendedZoom=true; combat=true
    Wheel(1); assert(scroll.currentScale==.75)
    combat=false
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
Maps.db.scale=5; Maps.db.x=-2; Maps.db.y=3
Maps:Initialize()
assert(Maps.db.scale==5 and Maps.db.x==-2 and Maps.db.y==3)

Maps.initialized=false; Maps.db.extendedZoom=false; Maps:Initialize()
assert(Maps.db.extendedZoom==false,"preserve explicit saved zoom preference")

-- Regression: Era's native hit test reads physical cursor coordinates. Scaling
-- the entire frame shifts continent selection; growing its dimensions must not.
if era then
    combat=false; map.maximized=false; map:Show()
    local cursorMethod=scroll.GetCursorPosition
    local function NativeEraHitTest(px,py,canvasScale,left,top,width,height)
        return (px/canvasScale-left)/width,(top-py/canvasScale)/height
    end
    for _,factor in ipairs({.6,1,1.3,2,5}) do
        Maps.db.scale=factor; Maps:ApplyWindow()
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
    combat=false; map.maximized=false; map:Show()
    local rebuilds=0
    function map:OnFrameSizeChanged()
        rebuilds=rebuilds+1
        local fit=self:GetWidth()/Maps.originalWidth
        scroll.zoomLevels={{scale=fit,layerIndex=1},{scale=2*fit,layerIndex=1}}
        scroll.currentScale=fit
    end
    Maps.db.scale=1; Maps:ApplyWindow()
    scroll.zoomLevels={{scale=1,layerIndex=1},{scale=2,layerIndex=1}}
    scroll.currentScale=3
    Maps.db.extendedZoom=true; Maps.db.scale=2; Maps:ApplyWindow()
    assert(rebuilds==1 and scroll.currentScale==6 and Maps.extraZoomScale==6)
    Maps:ApplyWindow(); assert(rebuilds==1,'unchanged dimensions must not rebuild/reset zoom')
    combat=true; Maps.db.scale=3; Maps:ApplyWindow()
    assert(rebuilds==1 and map:GetWidth()==2*Maps.originalWidth)
    combat=false; Maps:Refresh()
    assert(rebuilds==2 and scroll.currentScale==9)
    Maps:ResetMap(); assert(map:GetWidth()==Maps.originalWidth)
end

if era then
    combat=false; map.maximized=false; map:Show()
    for _,factor in ipairs({.6,1,1.3,2,5}) do
        Maps.db.scale=factor; Maps:ApplyWindow()
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
    map:Minimize(); assert(map.MiniBorderFrame:GetScale()==Maps.db.scale)
    combat=true; local before=map.MiniBorderFrame:GetScale()
    Maps.db.scale=1.7; Maps:ApplyWindow(); assert(map.MiniBorderFrame:GetScale()==before)
    combat=false; Maps:Refresh(); assert(map.MiniBorderFrame:GetScale()==1.7)
    Maps:ResetMap(); assert(map.MiniBorderFrame:GetScale()==1 and WorldMapFrameCloseButton:GetScale()==1)
    assert(scroll.points[1][4]==20 and scroll.points[2][5]==28)
end

if era then
    -- Resize a zoomed/panned canvas using Era's native pan interpolation and
    -- viewport-dependent scroll getters. Neither repeated resets nor focus
    -- drift may be hidden by the simpler InstantPanAndZoom fixture above.
    combat=false; map.maximized=false; Maps.db.scale=1; map:Show(); Maps:ApplyWindow()
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
        assert(not combat)
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
    combat=true; local before=fitUpdates; Maps:FinishResize()
    assert(not Maps.resizing and fitUpdates==before and Maps.viewportRebuildPending)
    combat=false; Maps:Refresh(); assert(not Maps.viewportRebuildPending and fitUpdates==before+1)

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
