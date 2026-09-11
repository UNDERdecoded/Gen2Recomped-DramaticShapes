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
_G.Game={data={tilesets=tilesets,map_tilesets=mapts,constants=constants,maps={}}}
local layoutNames=dofile("/tmp/idx/layoutnames.lua")
local g3maps=V.data("gen3_maps")
local Map=require("src.world.Map")
local Gen3=V.require("Gen3")
local ROLES=dofile("/tmp/t/gen3_metatiles.lua").roles
local want=os.getenv("MAPNAME") or "Route111"
local mid,layIdx
for id,e in pairs(g3maps.maps or {}) do if e.name==want then mid=id
  for i,ln in pairs(layoutNames) do if ln.name==e.layout then layIdx=i end end end end
assert(mid and layIdx,"map not found")
local lay=layouts[layIdx]
local function pairKeyFor(l)
  local function hex(a) return a and ("%07X"):format(a) or nil end
  local p,s=hex(l.primaryTileset),hex(l.secondaryTileset)
  for id in pairs(tilesets) do if type(id)=="string" and p and id:find(p,1,true) then
    if s==nil or id:find(s,1,true) then return id end end end
end
local key=pairKeyFor(lay)
local pkey=("P%07X"):format(lay.primaryTileset or 0)
local skey=("S%07X"):format(lay.secondaryTileset or 0)
local def={id=mid,width=lay.width,height=lay.height,blocks=lay.blocks,
 collisionCells=lay.collisionCells,elevationCells=lay.elevationCells,border=lay.border,
 borderBlock=lay.border and (lay.border:byte(1)+lay.border:byte(2)*256)%1024 or 0,tileset=key}
local map=Map.new(def,tilesets[key]) map.id=mid
local ctx=Gen3.forMap(map)
local a=Gen3.atlasDataForTileset(map.tileset)
local function px(m,x,y)
  local qx,qy=math.floor(x/8),math.floor(y/8)
  local t=m*4+qy*2+qx
  return a:getPixel((t%16)*8+(x%8), math.floor(t/16)*8+(y%8))
end
local COL={
  floor      ={205,205,205},
  cliff_top  ={255,225, 60},
  cliff_brow ={255,150, 30},
  cliff_face ={220, 55, 40},
  wall       ={235, 70,230},
  stair      ={ 60,235,235},
  water      ={ 45, 90,235},
  tree       ={ 40,165, 60},
  prop       ={140, 90,200},
  boulder    ={110, 70,150},
  ledge      ={255,255,255},
  none       ={ 25, 25, 25},
}
local X0=tonumber(os.getenv("CX0")) or 0
local Y0=tonumber(os.getenv("CY0")) or 0
local CW=tonumber(os.getenv("CW")) or math.min(30,lay.width)
local CH=tonumber(os.getenv("CH")) or math.min(24,lay.height)
local S=16
local W,H=CW*S*2+8, CH*S
local buf={}
for i=1,W*H*3 do buf[i]=0 end
local function put(x,y,r,g,b)
  if x<0 or y<0 or x>=W or y>=H then return end
  local i=(y*W+x)*3+1 buf[i]=r buf[i+1]=g buf[i+2]=b
end
local tally={}
for cy=0,CH-1 do for cx=0,CW-1 do
  local mx,my=X0+cx,Y0+cy
  local m=ctx.metatileAt(mx,my)
  local owner = (m and m<512) and pkey or skey
  local rec = m and ROLES[owner] and ROLES[owner][m]
  -- RESOLVE THE ROLE FROM THE ART PLUS THIS CELL'S OWN COLLISION.
  local role = "none"
  if rec then
    local art, material, kind = rec[1], rec[2], rec[5]
    local okw, wk = pcall(map.isWalkableCell, map, mx, my)
    local walk = okw and wk
    if kind == "water" or material == "water" and not walk then role="water"
    elseif kind == "ledge" then role="ledge"
    elseif walk then
      role = (art == "banded") and "stair" or "floor"
    elseif material == "manmade" then role="wall"
    elseif kind == "tree" or (material == "green" and rec[6]) then role="tree"
    elseif art == "surface" and rec[6] then role="prop"
    elseif material == "rock" or material == "sand" then role="cliff_face"
    elseif art == "brow" then role="cliff_brow"
    else role="prop" end
  end
  tally[role]=(tally[role] or 0)+1
  local c=COL[role] or COL.none
  for y=0,S-1 do for x=0,S-1 do
    -- left panel: the art
    if m then
      local r,g,b,al=px(m,x,y)
      if al and al>0 then put(cx*S+x, cy*S+y, math.floor(r*255),math.floor(g*255),math.floor(b*255)) end
    end
    -- right panel: the role
    local dim = (x==0 or y==0) and 0.55 or 1
    put(CW*S+8+cx*S+x, cy*S+y, math.floor(c[1]*dim), math.floor(c[2]*dim), math.floor(c[3]*dim))
  end end
end end
local f=io.open(os.getenv("OUT") or "/tmp/t/rolemap.ppm","wb")
f:write(("P6\n%d %d\n255\n"):format(W,H))
local t={} for i=1,W*H*3 do t[i]=string.char(buf[i]) end
f:write(table.concat(t)) f:close()
local ks={} for k in pairs(tally) do ks[#ks+1]=k end table.sort(ks)
for _,k in ipairs(ks) do io.stderr:write(("%-12s %d\n"):format(k,tally[k])) end
