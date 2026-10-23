local _, Maps = ...
-- The generated catalog is loaded next; learned entries use ContextKey below.
Maps.catalog = {}

function Maps:GetCatalog(artID, layerIndex, layer)
    local _, build = GetBuildInfo()
    local arts = self.catalog[tonumber(build)]
    local layers = arts and arts[artID]
    local key = table.concat({layerIndex, layer.layerWidth, layer.layerHeight,
        layer.tileWidth, layer.tileHeight}, ":")
    return layers and layers[key] or {}
end

function Maps:ContextKey(mapID, artID, layerIndex, layer)
    local _, build = GetBuildInfo()
    return table.concat({tostring(build), mapID, artID, layerIndex,
        layer.layerWidth, layer.layerHeight, layer.tileWidth, layer.tileHeight}, ":")
end

local function Positive(value, limit)
    return type(value)=="number" and value==value and value>0 and value<=limit and value%1==0
end
function Maps:ValidateOverlay(overlay, layer)
    if type(overlay)~="table" or overlay.isShownByMouseOver or overlay.isDrawOnTopLayer then return nil end
    if not Positive(layer.tileWidth,4096) or not Positive(layer.tileHeight,4096)
        or not Positive(overlay.textureWidth,16384) or not Positive(overlay.textureHeight,16384) then return nil end
    for _, value in ipairs({overlay.offsetX, overlay.offsetY}) do
        if type(value)~="number" or value~=value or value<0 or value>32768 or value%1~=0 then return nil end
    end
    if overlay.offsetX==nil or overlay.offsetY==nil or type(overlay.fileDataIDs)~="table" then return nil end
    local count=math.ceil(overlay.textureWidth/layer.tileWidth)*math.ceil(overlay.textureHeight/layer.tileHeight)
    if count>256 or #overlay.fileDataIDs~=count then return nil end
    local result={textureWidth=overlay.textureWidth,textureHeight=overlay.textureHeight,
        offsetX=overlay.offsetX,offsetY=overlay.offsetY,fileDataIDs={}}
    for index,id in ipairs(overlay.fileDataIDs) do
        if not Positive(id,2147483647) then return nil end
        result.fileDataIDs[index]=id
    end
    local key=table.concat({result.offsetX,result.offsetY,result.textureWidth,result.textureHeight,
        table.concat(result.fileDataIDs,",")},":")
    return result,key
end

function Maps:PlanOverlays(known, explored, layer, mode)
    if mode=="classic" then return {} end
    local current,plan={},{}
    for _,overlay in ipairs(explored or {}) do
        -- Leave any native hover/top-layer version of a known image alone too.
        local entry=type(overlay)=="table" and {
            textureWidth=overlay.textureWidth,textureHeight=overlay.textureHeight,
            offsetX=overlay.offsetX,offsetY=overlay.offsetY,fileDataIDs=overlay.fileDataIDs,
        } or overlay
        local valid,key=self:ValidateOverlay(entry,layer)
        if valid then current[key]=true end
    end
    for _,overlay in pairs(known or {}) do
        local valid,key=self:ValidateOverlay(overlay,layer)
        if valid and not current[key] then
            valid.alpha=mode=="mist" and .5 or 1
            plan[#plan+1]=valid
        end
    end
    return plan
end
