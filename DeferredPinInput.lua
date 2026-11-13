local Guard = {}
local Methods = {}
local unpack = unpack or table.unpack

function Guard.New(map, inCombat)
    return setmetatable({map=map,inCombat=inCombat,
        wrapped=setmetatable({}, {__mode="k"}),
        pending=setmetatable({}, {__mode="k"})}, {__index=Methods})
end

function Methods:Wrap(owner, name)
    if type(owner)~="table" then return false end
    local original=owner[name]
    if type(original)~="function" then return false end
    local registered=self.wrapped[owner]
    if not registered then registered={}; self.wrapped[owner]=registered end
    if registered[name] then return false end
    registered[name]=true
    local guard=self
    owner[name]=function(pin,...)
        if guard.inCombat() and pin.GetMap and pin:GetMap()==guard.map then
            local pending=guard.pending[pin]
            if not pending then pending={}; guard.pending[pin]=pending end
            pending[name]={method=original,count=select("#",...),args={...}}
            return
        end
        local pending=guard.pending[pin]
        if pending then pending[name]=nil end
        return original(pin,...)
    end
    return true
end

function Methods:PendingCount()
    local count=0
    for _,entries in pairs(self.pending) do
        for _ in pairs(entries) do count=count+1 end
    end
    return count
end

function Methods:Flush()
    if self.inCombat() then return end
    for pin,entries in pairs(self.pending) do
        self.pending[pin]=nil
        if not (pin.IsForbidden and pin:IsForbidden()) and pin.GetMap and pin:GetMap()==self.map then
            for _,entry in pairs(entries) do
                entry.method(pin,unpack(entry.args,1,entry.count))
            end
        end
    end
end

local _, Maps = ...
if type(Maps)=="table" then Maps.DeferredPinInput=Guard end
return Guard
