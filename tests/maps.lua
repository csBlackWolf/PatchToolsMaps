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
UISpecialFrames={}; tinsert=table.insert
function GetLocale() return os.getenv('PATCHTOOLS_TEST_LOCALE') or 'enUS' end
function GetBuildInfo() return '1.60.1','70532','',16001 end
function InCombatLockdown() return combat end
function GetCursorPosition() return cursorX,cursorY end
local panelCloses=0
function HideUIPanel(frame) panelCloses=panelCloses+1; frame:Hide() end
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
assert(loadfile(base..'Locales.lua'))('PatchTools',PT)
assert(loadfile(base..'Extensions.lua'))('PatchTools',PT)
assert(loadfile(base..'Options.lua'))('PatchTools',PT)
-- The base addon has no map page while the optional addon is absent.
PT:CreateOptions()
assert(not PT.optionPages.maps)
PT:SelectOptionsPage('general')
assert(PT:SelectOptionsPage('missing')==false and PT.optionPages.general:IsShown())
local Maps={}
for _,name in ipairs({'Locales.lua','OverlayData.lua','GeneratedCatalog.lua','Reveal.lua','Window.lua','Options.lua','Core.lua'}) do
    assert(loadfile(MAPS_PATH..name))('PatchToolsMaps',Maps)
end
Event('ADDON_LOADED','PatchToolsMaps')
assert(Maps.initialized and Maps.db.mode=='mist' and PT.optionPages.maps)
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
map.maximized=false
map:SetPoint('CENTER',UIParent,'CENTER',0,0)
function map:IsMaximized() return self.maximized end
function map:Maximize() self.maximized=true end
function map:Minimize() self.maximized=false end
function map:GetMapID() return 100 end
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
function scroll:CreateZoomLevels() self.zoomLevels={{scale=1,layerIndex=1},{scale=2,layerIndex=1}} end
function scroll:ResetZoom(ignoreScaleRatio)
    assert(ignoreScaleRatio==true)
    self.currentScale=self.zoomLevels[1].scale
    self.panX,self.panY=.5,.5
    self.resets=(rawget(self,'resets') or 0)+1
end
scroll:CreateZoomLevels()
Event('ADDON_LOADED','Blizzard_WorldMap')
assert(Maps.map==map and Maps.dragBar:IsShown() and Maps.resizeGrip:IsShown())
Maps.db.extendedZoom=true; Maps:Refresh(true)
assert(#scroll.zoomLevels==3 and scroll.zoomLevels[3].scale==4)
scroll:CreateZoomLevels(); assert(#scroll.zoomLevels==3)
Maps.db.extendedZoom=false; Maps:Refresh(true); assert(#scroll.zoomLevels==2)
-- The extra overlay renderer never changes the explored list.
local overlay={textureWidth=300,textureHeight=200,offsetX=0,offsetY=0,fileDataIDs={111,222}}
explored={overlay}; Maps:RefreshReveal()
explored={}; Maps:RefreshReveal()
assert(#explored==0 and #Maps.textures==2)
assert(Maps.textures[1].alpha==.5 and Maps.textures[2].width==44)
assert(not Maps.textures[1].desaturated and Maps.textures[1].vertexColor[1]==1)
assert(Maps.textures[2].texCoord[2]==44/64)
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
for art,layers in pairs(Maps.catalog[70532]) do
    artCount=artCount+1
    for key,overlays in pairs(layers) do
        local index,lw,lh,tw,th=key:match('^(%d+):(%d+):(%d+):(%d+):(%d+)$')
        for _,entry in ipairs(overlays) do
            assert(Maps:ValidateOverlay(entry,{tileWidth=tonumber(tw),tileHeight=tonumber(th)}))
            catalogCount=catalogCount+1
        end
    end
end
assert(artCount==45 and catalogCount==572)
local oldLayer=layer
layer={layerWidth=1002,layerHeight=668,tileWidth=256,tileHeight=256}
artID=2031; Maps.db.knownOverlays={}; explored={}; Maps.db.mode='mist'
Maps:RefreshReveal()
assert(Maps.textures[1]:IsShown() and Maps.textures[1].alpha==.5 and #explored==0)
assert(#Maps:GetCatalog(2031,1,layer)==15)
explored=Maps:GetCatalog(2031,1,layer); Maps:RefreshReveal()
assert(not Maps.textures[1]:IsShown())
assert(#Maps:GetCatalog(2031,2,layer)==0)
local savedBuild=GetBuildInfo
function GetBuildInfo() return '1.60.1','99999','',16001 end
assert(#Maps:GetCatalog(2031,1,layer)==0)
GetBuildInfo=savedBuild
local fw,fh=Maps:TextureSize(8124659,237,9)
assert(fw==256 and fh==32)
layer=oldLayer; artID=56; explored={}; Maps.db.knownOverlays={}
-- Window scale, reset, fullscreen and combat deferral.
Maps.db.scale=1.3; Maps:Refresh(); assert(map.scale==1.3)
map:Maximize(); assert(map.scale==1 and not Maps.dragBar:IsShown())
map:Minimize(); assert(map.scale==1.3 and Maps.dragBar:IsShown())
combat=true; Maps.db.scale=.8; Maps:Refresh(); assert(map.scale==1.3)
Maps.db.extendedZoom=true; Maps:Refresh(true); assert(#scroll.zoomLevels==2)
combat=false; Event('PLAYER_REGEN_ENABLED'); assert(map.scale==.8 and #scroll.zoomLevels==3)
Maps.dragBar.scripts.OnDragStart(); assert(Maps.moving)
Maps.dragBar.scripts.OnDragStop(); assert(not Maps.moving and Maps.db.x and Maps.db.y)
Maps.dragBar.scripts.OnDragStart()
combat=true; Event('PLAYER_REGEN_DISABLED')
assert(not Maps.moving and not Maps.dragBar.scripts.OnUpdate)
combat=false; Event('PLAYER_REGEN_ENABLED')
Maps.resizeGrip.scripts.OnMouseDown(Maps.resizeGrip,'LeftButton')
cursorX,cursorY=100000,-100000
Maps.resizeGrip.scripts.OnUpdate(); assert(Maps.db.scale==1.5)
Maps.resizeGrip.scripts.OnMouseUp(); assert(not Maps.resizeGrip.scripts.OnUpdate)
Maps:ResetWindow(); assert(map.scale==1 and Maps.db.x==nil and Maps.db.y==nil)
-- Full reset is wired to the options button, including native view/zoom.
local anchor=Maps.resizeGrip.points[1]
assert(anchor[1]=='BOTTOMRIGHT' and anchor[2]==map and anchor[3]=='BOTTOMRIGHT')
assert(anchor[4]==12 and anchor[5]==-12)
assert(Maps.resizeGrip.width==24 and Maps.resizeGrip.height==24)
assert(Maps.dragBar.height==19 and #Maps.dragBar.points==2)
Maps.db.extendedZoom=true; Maps.db.scale=1.4; Maps.db.x=.4; Maps.db.y=.6
Maps:Refresh(true); scroll.currentScale=4; scroll.panX,scroll.panY=.9,.1
Maps.optionsUI.reset.scripts.OnClick()
assert(not map:IsShown() and panelCloses==1)
assert(map.scale==1 and Maps.db.x==nil and Maps.db.y==nil and not Maps.db.extendedZoom)
assert(#scroll.zoomLevels==2 and scroll.currentScale==1 and scroll.panX==.5 and scroll.panY==.5)
assert(Maps.optionsUI.checks.extendedZoom.checked==false)
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
artID=2031; layer={layerWidth=1002,layerHeight=668,tileWidth=256,tileHeight=256}
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
