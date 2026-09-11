-- METATILE CENSUS, keyed by the tileset that OWNS the metatile.
-- Emerald splits the id space: 0..511 come from the map's PRIMARY tileset
-- and 512..1023 from its SECONDARY.  Hoenn has three primaries and seventy
-- secondaries, so keying by the pair (75 combinations) counted the same
-- General-tileset cliff seventy-five times.  Keyed by owner, every outdoor
-- map's terrain collapses onto one table of at most 512 rows.
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
local function pairKeyFor(l)
  local function hex(a) return a and ("%07X"):format(a) or nil end
  local p,s=hex(l.primaryTileset),hex(l.secondaryTileset)
  for id in pairs(tilesets) do if type(id)=="string" and p and id:find(p,1,true) then
    if s==nil or id:find(s,1,true) then return id end end end
end
local layIdxByName={}
for i,ln in pairs(layoutNames) do layIdxByName[ln.name]=i end
local acc = {}
local function slot(key, m)
  local t=acc[key] if not t then t={} acc[key]=t end
  local e=t[m]
  if not e then e={n=0,beh=nil,layer=nil,coll={},elev={},nmaps=0,maps={},
                   up={},down={},left={},right={},pairs_={}} t[m]=e end
  return e
end
local nmap=0
for id,ent in pairs(g3maps.maps or {}) do
  local li=layIdxByName[ent.layout]
  local lay=li and layouts[li]
  if lay and lay.blocks and lay.width and lay.height then
    local key=pairKeyFor(lay)
    if key and tilesets[key] then
      local pkey=("P%07X"):format(lay.primaryTileset or 0)
      local skey=("S%07X"):format(lay.secondaryTileset or 0)
      local def={id=id,width=lay.width,height=lay.height,blocks=lay.blocks,
        collisionCells=lay.collisionCells,elevationCells=lay.elevationCells,
        border=lay.border,
        borderBlock=lay.border and (lay.border:byte(1)+lay.border:byte(2)*256)%1024 or 0,
        tileset=key}
      local ok,map=pcall(Map.new,def,tilesets[key])
      if ok and map then
        map.id=id
        local okc,ctx=pcall(Gen3.forMap,map)
        if okc and ctx then
          nmap=nmap+1
          local W,H=lay.width,lay.height
          local function mt(cx,cy)
            if cx<0 or cy<0 or cx>=W or cy>=H then return nil end
            return ctx.metatileAt(cx,cy)
          end
          for cy=0,H-1 do for cx=0,W-1 do
            local i=cy*W+cx+1
            local m=mt(cx,cy)
            if m then
              local e=slot(m<512 and pkey or skey, m)
              e.n=e.n+1
              if not e.maps[ent.name] then e.maps[ent.name]=0 e.nmaps=e.nmaps+1 end
              e.maps[ent.name]=e.maps[ent.name]+1
              e.pairs_[key]=true
              if e.beh==nil then local b,l=ctx.attributes(m) e.beh,e.layer=b,l end
              local c=(lay.collisionCells and lay.collisionCells[i]) or 0
              local z=(lay.elevationCells and lay.elevationCells[i]) or 0
              e.coll[c]=(e.coll[c] or 0)+1
              e.elev[z]=(e.elev[z] or 0)+1
              local u,d,l2,r=mt(cx,cy-1),mt(cx,cy+1),mt(cx-1,cy),mt(cx+1,cy)
              if u then e.up[u]=(e.up[u] or 0)+1 end
              if d then e.down[d]=(e.down[d] or 0)+1 end
              if l2 then e.left[l2]=(e.left[l2] or 0)+1 end
              if r then e.right[r]=(e.right[r] or 0)+1 end
            end
          end end
        end
      end
    end
  end
end
local out=io.open(os.getenv("OUT") or "/tmp/t/census_owned.lua","w")
out:write("-- generated by /tmp/t/mkcensus.lua -- do not hand-edit\nreturn {\n")
local keys={} for k in pairs(acc) do keys[#keys+1]=k end table.sort(keys)
local total=0
for _,k in ipairs(keys) do
  local t=acc[k]
  local ms={} for m in pairs(t) do ms[#ms+1]=m end table.sort(ms)
  total=total+#ms
  out:write(("  [%q] = {\n"):format(k))
  for _,m in ipairs(ms) do
    local e=t[m]
    local function top(tab,lim)
      local a={} for kk,v in pairs(tab) do a[#a+1]={kk,v} end
      table.sort(a,function(x,y) return x[2]>y[2] end)
      local s={} for i=1,math.min(lim or 4,#a) do s[#s+1]=("%d:%d"):format(a[i][1],a[i][2]) end
      return table.concat(s,",")
    end
    local np=0 for _ in pairs(e.pairs_) do np=np+1 end
    out:write(("    [%d]={n=%d,beh=%d,layer=%d,nmaps=%d,npairs=%d,coll=%q,elev=%q,up=%q,down=%q,left=%q,right=%q},\n")
      :format(m,e.n,e.beh or 0,e.layer or 0,e.nmaps,np,top(e.coll,4),top(e.elev,4),
              top(e.up,4),top(e.down,4),top(e.left,4),top(e.right,4)))
  end
  out:write("  },\n")
end
out:write("}\n") out:close()
io.stderr:write(("maps=%d owners=%d rows=%d\n"):format(nmap,#keys,total))
