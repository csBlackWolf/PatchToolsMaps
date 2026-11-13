local G=assert(loadfile(MODULE_PATH))()
local combat=false
local map,other={},{}
local calls={}
local function native(pin,...)
 assert(not(combat and pin.map==map),'protected operation reached in combat')
 calls[#calls+1]={pin=pin,n=select('#',...),...}
 return 'ok',17
end
local guard=G.New(map,function() return combat end)
local proto={CheckMouseButtonPassthrough=native}
assert(guard:Wrap(proto,'CheckMouseButtonPassthrough')==true)
local wrapper=proto.CheckMouseButtonPassthrough
guard:Wrap(proto,'CheckMouseButtonPassthrough')
assert(proto.CheckMouseButtonPassthrough==wrapper,'installation is idempotent')
local p=setmetatable({map=map,GetMap=function(self) return self.map end},{__index=proto})
local a,b=p:CheckMouseButtonPassthrough('RightButton',nil,3)
assert(a=='ok' and b==17 and #calls==1)
combat=true
p:CheckMouseButtonPassthrough('LeftButton')
p:CheckMouseButtonPassthrough('RightButton',nil,4)
assert(#calls==1 and guard:PendingCount()==1)
guard:Flush()
assert(#calls==1)
local q=setmetatable({map=other,GetMap=p.GetMap},{__index=proto})
q:CheckMouseButtonPassthrough('RightButton')
assert(#calls==2,'other maps retain their own behavior')
combat=false; guard:Flush()
assert(#calls==3 and calls[3].n==3 and calls[3][1]=='RightButton' and calls[3][3]==4)
assert(guard:PendingCount()==0)
combat=true;p:CheckMouseButtonPassthrough('RightButton');p.map=other
combat=false;guard:Flush()
assert(#calls==3,'do not replay a recycled pin')
p.map=map;combat=true;p:CheckMouseButtonPassthrough('RightButton')
p.IsForbidden=function() return true end
combat=false;guard:Flush()
assert(#calls==3 and guard:PendingCount()==0)
local replacement=function() return 'foreign' end
proto.CheckMouseButtonPassthrough=replacement
guard:Wrap(proto,'CheckMouseButtonPassthrough')
assert(proto.CheckMouseButtonPassthrough==replacement,'do not wrap another addon replacement')
assert(not guard:Wrap({},'missing'))
print('PASS deferred native pin input contract')
