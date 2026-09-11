-- FOUR PANELS OVER ONE MAP, so a claim about height can be looked at instead
-- of asserted:  the 2D art, the terrace level of every cell, the role the
-- table resolved, and the DEFECTS -- staircases that do not change level,
-- cells sunken below the terrace they belong to, cliff tops that do not meet
-- the ground they retain.
package.path = "/tmp/work/?.lua;/tmp/work/?/init.lua;" .. package.path
local MOD="/tmp/modwork/DRAMATIC_SHAPE/"
local GEN = "/mnt/user-data/uploads/Gen2Recomp/emerald/data/generated/"
_G.love = require("tests.love_stub")
local function obj(t) return setmetatable(t or {}, { __index = function() return function() end end }) end
love.image=love.image or {}
love.image.newImageData=function(w,h) local px={} return obj({_w=w,_h=h,getWidth=function() return w end,getHeight=function() return h end,getDimensions=function() return w,h end,
 setPixel=function(_,x,y,r,g,b,a) px[y*w+x]={r,g,b,a} end,
 getPixel=function(_,x,y) local c=px[y*w+x] if not c then return 0,0,0,0 end return c[1],c[2],c[3],c[4] end}) end
love.graphics.newImage=function(d) return obj({__data=d,getWidth=function() return d:getWidth() end,getHeight=function() return d:getHeight() end,getDimensions=function() return d:getDimensions() end}) end
love.graphics.newMesh=function(f,v) return obj({getVertexCount=function() return type(v)=="table" and #v or 0 end}) end
local V={} local modules,dataFiles={},{}
function V.require(n) local h=modules[n] if h~=nil then return h end local v=assert(loadfile(MOD.."lib/"..n..".lua"))(V) modules[n]=v return v end
function V.data(n) local h=dataFiles[n] if h~=nil then return h end local v=assert(loadfile(MOD.."data/"..n..".lua"))(V) dataFiles[n]=v return v end
local function load_(f) return assert(loadfile(GEN..f))() end
local tilesets,constants,mapts,layouts = load_("tilesets.lua"),load_("constants.lua"),load_("map_tilesets.lua"),load_("map_layouts.lua")
local allmaps=load_("maps.lua")
local byId={} for _,v in pairs(allmaps) do if v.id then byId[v.id]=v end end
_G.Game={data={tilesets=tilesets,map_tilesets=mapts,constants=constants,maps=byId}}
local layoutNames=dofile("/tmp/idx/layoutnames.lua")
local g3maps=V.data("gen3_maps")
local want=os.getenv("MAPNAME") or "Route110"
local mid,layIdx
for id,e in pairs(g3maps.maps or {}) do if e.name==want then mid=id
  for i,ln in pairs(layoutNames) do if ln.name==e.layout then layIdx=i end end end end
assert(mid and layIdx, "map not found")
local lay=layouts[layIdx]
local function pairKeyFor(l)
  local function hex(a) return a and ("%07X"):format(a) or nil end
  local p,s=hex(l.primaryTileset),hex(l.secondaryTileset)
  for id in pairs(tilesets) do if type(id)=="string" and p and id:find(p,1,true) then
    if s==nil or id:find(s,1,true) then return id end end end
end
local key=pairKeyFor(lay)
local Map=require("src.world.Map")
local def={id=mid,width=lay.width,height=lay.height,blocks=lay.blocks,
 collisionCells=lay.collisionCells,elevationCells=lay.elevationCells,border=lay.border,
 borderBlock=lay.border and (lay.border:byte(1)+lay.border:byte(2)*256)%1024 or 0,tileset=key}
local map=Map.new(def,tilesets[key]) map.id=mid
local Gen3=V.require("Gen3")
local d=(Gen3.shapeDataForMap and Gen3.shapeDataForMap(map)) or Gen3.shapeDataForTileset(map.tileset)
local a=Gen3.atlasDataForTileset(map.tileset)
local function px(img,m,x,y)
  local qx,qy=math.floor(x/8),math.floor(y/8)
  local t=m*4+qy*2+qx
  return img:getPixel((t%16)*8+(x%8), math.floor(t/16)*8+(y%8))
end
local Structures=V.require("Structures")
local S=Structures.forMap(map)
local ctx=Gen3.forMap(map)
local VS=V.require("VoxelScene")
local W,H=map.def.width,map.def.height
local function keyOf(x,y) return (y+64)*4096+(x+64) end
local a=Gen3.atlasDataForTileset(map.tileset)
local function px(m,x,y)
  local qx,qy=math.floor(x/8),math.floor(y/8)
  local t=m*4+qy*2+qx
  return a:getPixel((t%16)*8+(x%8), math.floor(t/16)*8+(y%8))
end
local X0=tonumber(os.getenv("CX0")) or 0
local Y0=tonumber(os.getenv("CY0")) or 0
local CW=tonumber(os.getenv("CW")) or math.min(W,40)
local CH=tonumber(os.getenv("CH")) or math.min(H,30)
local Z=tonumber(os.getenv("Z")) or 16     -- px per cell

-- level palette: one clearly distinct colour per course
local LV={[0]={40,70,150},[1]={40,150,120},[2]={120,180,50},
          [3]={230,200,50},[4]={235,140,40},[5]={220,70,60},[6]={190,60,180}}
local ROLE={floor={205,205,205},cliff={90,70,60},stair={60,235,235},
            wall={235,70,230},water={45,90,235},tree={40,165,60},
            prop={140,90,200},ledge={255,255,255}}

local function terrace(cx,cy) return S.synthZ and S.synthZ[cy*8192+cx] end
local function lvl(cx,cy) local z=terrace(cx,cy) return z and math.floor(z/16) or nil end
local function role(cx,cy) local ok,r=pcall(Gen3.roleAt,map,cx,cy) return ok and r or nil end
local function walk(cx,cy) local ok,w=pcall(map.isWalkableCell,map,cx,cy) return ok and w end

-- ---- defects -------------------------------------------------------------
local defect={}
local nFlat,nSunk,nEdge=0,0,0
-- 1. a staircase whose two ends are the SAME level
for cy=0,H-1 do for cx=0,W-1 do
  if role(cx,cy)=="stair" then
    local z0,z1=Structures.flightEnds(map,cx,cy)
    if not (z0 and z1 and z0~=z1) then defect[cy*8192+cx]="flat" nFlat=nFlat+1 end
  end
end end
-- 2. a walkable cell whose RENDERED ground is below its own terrace
for cy=0,H-1 do for cx=0,W-1 do
  if walk(cx,cy) and role(cx,cy)~="stair" then
    local t=terrace(cx,cy)
    local okg,g=pcall(VS.groundAt,map,cx,cy,3)
    if t and okg and g and (t-g)>=8 then
      defect[cy*8192+cx]="sunk" nSunk=nSunk+1
    end
  end
end end
-- 3. a cliff whose top does not reach the higher floor beside it
for cy=0,H-1 do for cx=0,W-1 do
  local shx=S.shapeAt[keyOf(cx*2,cy*2)]
  local isRail = shx and (shx.class=="fence" or shx.class=="post" or shx.class=="sign" or shx.class=="signpost")
  if role(cx,cy)=="cliff" and not isRail then
    local hi=nil
    for _,d in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
      local z=terrace(cx+d[1],cy+d[2])
      if z and (hi==nil or z>hi) then hi=z end
    end
    local sh=S.shapeAt[keyOf(cx*2,cy*2)]
    local top=sh and sh.h
    if hi and top and (hi-top)>=8 and not defect[cy*8192+cx] then
      defect[cy*8192+cx]="edge" nEdge=nEdge+1
    end
  end
end end

-- ---- draw ----------------------------------------------------------------
local PW,PH=CW*Z,CH*Z
local GAP=10
local IW,IH=PW*2+GAP, PH*2+GAP
local buf={} for i=1,IW*IH*3 do buf[i]=18 end
local function put(x,y,r,g,b)
  if x<0 or y<0 or x>=IW or y>=IH then return end
  local i=(y*IW+x)*3+1 buf[i]=r buf[i+1]=g buf[i+2]=b
end
local function fill(px0,py0,c,dim)
  dim=dim or 1
  for yy=0,Z-1 do for xx=0,Z-1 do
    put(px0+xx,py0+yy,math.floor(c[1]*dim),math.floor(c[2]*dim),math.floor(c[3]*dim))
  end end
end
for cy=0,CH-1 do for cx=0,CW-1 do
  local mx,my=X0+cx,Y0+cy
  local ox,oy=cx*Z,cy*Z
  -- PANEL 1 (top-left): the art
  local m=ctx.metatileAt(mx,my)
  if m then
    for yy=0,Z-1 do for xx=0,Z-1 do
      local sx,sy=math.floor(xx*16/Z),math.floor(yy*16/Z)
      local r,g,b,al=px(m,sx,sy)
      if al and al>0 then put(ox+xx,oy+yy,math.floor(r*255),math.floor(g*255),math.floor(b*255)) end
    end end
  end
  -- PANEL 2 (top-right): terrace level
  local bx=PW+GAP+ox
  local L=lvl(mx,my)
  local rr=role(mx,my)
  if rr=="water" then fill(bx,oy,{25,45,120})
  elseif L then fill(bx,oy,LV[math.min(6,L)] or {255,255,255}, (rr=="floor" or rr=="stair") and 1 or 0.55)
  else fill(bx,oy,{45,45,45}) end
  -- grid line so cells are countable
  for xx=0,Z-1 do put(bx+xx,oy,10,10,10) end
  for yy=0,Z-1 do put(bx,oy+yy,10,10,10) end
  -- PANEL 3 (bottom-left): roles
  local cxp,cyp=ox,PH+GAP+oy
  fill(cxp,cyp, ROLE[rr or "prop"] or {60,60,60})
  for xx=0,Z-1 do put(cxp+xx,cyp,10,10,10) end
  for yy=0,Z-1 do put(cxp,cyp+yy,10,10,10) end
  -- PANEL 4 (bottom-right): defects over a faint level wash
  local dxp,dyp=PW+GAP+ox,PH+GAP+oy
  if L then fill(dxp,dyp, LV[math.min(6,L)] or {255,255,255}, 0.25)
  else fill(dxp,dyp,{30,30,30}) end
  local d=defect[my*8192+mx]
  if d=="flat" then fill(dxp,dyp,{255,60,60})
  elseif d=="sunk" then fill(dxp,dyp,{255,190,40})
  elseif d=="edge" then fill(dxp,dyp,{80,220,255}) end
  if rr=="stair" and not d then fill(dxp,dyp,{60,255,120}) end
end end
local f=io.open(os.getenv("OUT") or "/tmp/t/heightmap.ppm","wb")
f:write(("P6\n%d %d\n255\n"):format(IW,IH))
local t={} for i=1,IW*IH*3 do t[i]=string.char(buf[i]) end
f:write(table.concat(t)) f:close()
io.stderr:write(("%s  flat-stairs=%d  sunken-cells=%d  short-cliff-edges=%d\n"):format(want,nFlat,nSunk,nEdge))
