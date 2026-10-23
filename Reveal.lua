local _, Maps = ...
local function FileSize(pixels)
    local size=16
    while size<pixels do size=size*2 end
    return size
end
function Maps:TextureSize(fdid, width, height)
    local _,build=GetBuildInfo()
    local sizes=self.catalogTextureSizes and self.catalogTextureSizes[tonumber(build)]
    local actual=sizes and sizes[fdid]
    if actual and actual[1]>=width and actual[2]>=height then return actual[1],actual[2] end
    return FileSize(width),FileSize(height)
end
function Maps:ClearReveal()
    for _,texture in ipairs(self.textures or {}) do texture:Hide() end
end
function Maps:UpdateRevealMasks()
    local map=self.map
    if not map then return end
    local mask
    if map.GetMaskTexture and map.GetUseMaskTexture and map:GetUseMaskTexture() then mask=map:GetMaskTexture() end
    self.textureMasks=self.textureMasks or {}
    for _,texture in ipairs(self.textures or {}) do
        local previous=self.textureMasks[texture]
        if previous~=mask then
            if previous then texture:RemoveMaskTexture(previous) end
            if mask then texture:AddMaskTexture(mask) end
            self.textureMasks[texture]=mask
        end
    end
end
function Maps:GetReadyLayerIndex()
    local container=self.map and self.map:GetCanvasContainer()
    -- Minimize/scale hooks also fire during Blizzard's first map setup.
    -- GetCurrentLayerIndex iterates zoomLevels internally and cannot run yet.
    if not container or type(container.zoomLevels)~="table" or #container.zoomLevels==0
        or type(container.GetCurrentLayerIndex)~="function" then return nil end
    return container:GetCurrentLayerIndex()
end
function Maps:RefreshReveal()
    self:ClearReveal()
    local map=self.map
    if not map or not map:IsShown() or not C_Map or not C_MapExplorationInfo then return end
    local mapID=map:GetMapID()
    local artID=mapID and C_Map.GetMapArtID(mapID)
    local layers=mapID and C_Map.GetMapArtLayers(mapID)
    local index=self:GetReadyLayerIndex()
    if not index then return end
    local layer=layers and layers[index]
    if not artID or not layer then return end
    local key=self:ContextKey(mapID,artID,index or 1,layer)
    local explored=C_MapExplorationInfo.GetExploredMapTextures(mapID) or {}
    local known=self.db.knownOverlays[key]
    if not known then known={}; self.db.knownOverlays[key]=known end
    local count=0
    for _ in pairs(known) do count=count+1 end
    for _,overlay in ipairs(explored) do
        local valid,id=self:ValidateOverlay(overlay,layer)
        if valid and (known[id] or count<512) then
            if not known[id] then count=count+1 end
            known[id]=valid
        end
    end
    local combined={}
    for id,overlay in pairs(known) do combined[id]=overlay end
    for _,overlay in ipairs(self:GetCatalog(artID,index or 1,layer)) do
        local valid,id=self:ValidateOverlay(overlay,layer)
        if valid then combined[id]=valid end
    end
    local plan=self:PlanOverlays(combined,explored,layer,self.db.mode)
    local canvas=map:GetCanvas()
    if not self.revealFrame then
        self.revealFrame=CreateFrame("Frame",nil,canvas)
        self.revealFrame:SetAllPoints(canvas)
        self.revealFrame:EnableMouse(false)
        self.textures={}
    end
    local textureIndex=0
    for _,overlay in ipairs(plan) do
        local columns=math.ceil(overlay.textureWidth/layer.tileWidth)
        local rows=math.ceil(overlay.textureHeight/layer.tileHeight)
        for row=1,rows do for col=1,columns do
            textureIndex=textureIndex+1
            local texture=self.textures[textureIndex]
            if not texture then
                texture=self.revealFrame:CreateTexture(nil,"ARTWORK")
                self.textures[textureIndex]=texture
            end
            local width=math.min(layer.tileWidth,overlay.textureWidth-(col-1)*layer.tileWidth)
            local height=math.min(layer.tileHeight,overlay.textureHeight-(row-1)*layer.tileHeight)
            texture:ClearAllPoints()
            texture:SetPoint("TOPLEFT",overlay.offsetX+(col-1)*layer.tileWidth,-overlay.offsetY-(row-1)*layer.tileHeight)
            texture:SetSize(width,height)
            local fdid=overlay.fileDataIDs[(row-1)*columns+col]
            local fileWidth,fileHeight=self:TextureSize(fdid,width,height)
            texture:SetTexCoord(0,width/fileWidth,0,height/fileHeight)
            texture:SetTexture(fdid,nil,nil,"TRILINEAR")
            texture:SetDesaturated(false)
            texture:SetVertexColor(1,1,1)
            texture:SetAlpha(overlay.alpha)
            texture:Show()
        end end
    end
    self:UpdateRevealMasks()
end
