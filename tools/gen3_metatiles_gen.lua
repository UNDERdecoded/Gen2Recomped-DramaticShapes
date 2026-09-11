-- ============================================================================
-- GEN 3 METATILE ROLE TABLE -- generator.
--
-- The voxel passes have been inferring what a cell IS from whatever was to
-- hand: the colour of one pixel, whether the cell was walkable, how tall the
-- drawing happened to be.  That is why a purple rock became a skyscraper and
-- a house's siding became a cliff.  This builds the answer ONCE, from the
-- cartridge, for every metatile Hoenn actually places.
--
-- Three sources, all measured, none guessed:
--
--   the CENSUS   how many cells place this metatile, in how many maps, and
--                which collision and elevation values the map data pairs it
--                with.  Blocked-at-elevation-0 is Emerald saying "a level
--                boundary"; blocked-at-elevation-3 is "a thing standing on
--                the ground".
--   the ART      each of the sixteen pixel rows reduced to a material, so a
--                cliff brow reads GGGGGGGGGRRRRRRR -- nine rows of terrace
--                top, seven of face -- and a pure face reads RRRRRRRRRRRRRRRR.
--   the BEHAVIOUR byte, which names the handful of surfaces the cartridge
--                cares about itself: MB_MOUNTAIN_TOP, the jump ledges, the
--                water family, the tree family.
--
-- The id space is split: 0..511 belong to the map's PRIMARY tileset and
-- 512..1023 to its SECONDARY, so the table is keyed by the tileset that OWNS
-- the metatile.  Hoenn has three primaries and seventy secondaries; keying by
-- the 75 pairs instead would have described General's cliffs 75 times.
-- ============================================================================
--
-- REGENERATING IT.
--
--   cd /tmp/work && SHAPEMOD=<tree>/ OUT=<out>.lua \
--     luajit <tree>/tools/gen3_metatiles_gen.lua          -- the whole table
--   ... ONLY=S03DFB24 ...                                 -- one owner
--
-- A WHOLE REGENERATION IS REPRODUCIBLE, AND IT HAD TO BE MADE SO.
--
-- Two runs of this generator with no code change at all used to differ in
-- 1,479 emitted rows over 55 of the 72 owners, so "regenerate the role
-- table" was an instruction nobody could obey: it rewrote roles on nearly
-- every map in Hoenn for no stated reason, and no reviewer could tell the
-- intended change from the noise.  Both causes were `pairs()` order, and
-- both are fixed below where they occur:
--
--   the REPRESENTATIVE MAP was picked with a strict `>` on a score that
--   ties -- Route111 and Route119 both score 740.00 for P03DF704, and the
--   six Route110_TrickHousePuzzle maps all score 8.25 -- so whichever the
--   hash happened to reach first won, and the whole owner was then
--   profiled through that map's palette;
--
--   `pairKeyFor` returned the FIRST tileset key that matched, which for a
--   layout with no secondary is any pair sharing its primary.
--
-- Both now break the tie explicitly, and the rule is the one the shipped
-- data/gen3_metatiles.lua was built with: the LAST name in ASCII order
-- wins (Route119 over Route111, TrickHousePuzzle6 over 1..5).  Two whole
-- regenerations are byte-identical to each other and to the shipped file.
--
-- The emitted banner still names /tmp/t/mkroles.lua, which is where this
-- file was recovered from, precisely so that a regeneration can be `cmp`d
-- against the shipped table without a spurious first-line difference.
-- ============================================================================
package.path = "/tmp/work/?.lua;/tmp/work/?/init.lua;" .. package.path
local MOD=os.getenv("SHAPEMOD") or "/tmp/modwork/DRAMATIC_SHAPE/"
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
local shapes=V.data("gen3_shapes")
local BEH=shapes.behaviour or {}
local CENSUS=dofile("/tmp/t/census_owned.lua")

-- THE PAIR KEY, PICKED THE SAME WAY TWICE.
--
-- This returned the first key `pairs(tilesets)` happened to yield, and a
-- layout with no secondary matches every pair that shares its primary, so the
-- answer changed between runs.  Collect the matches and take the lowest in
-- ASCII order: one candidate is the overwhelmingly common case and the sort
-- costs nothing, but the answer is now the same on every run.
local function pairKeyFor(l)
  local function hex(a) return a and ("%07X"):format(a) or nil end
  local p,s=hex(l.primaryTileset),hex(l.secondaryTileset)
  local hit={}
  for id in pairs(tilesets) do if type(id)=="string" and p and id:find(p,1,true) then
    if s==nil or id:find(s,1,true) then hit[#hit+1]=id end end end
  table.sort(hit)
  return hit[1]
end
local layIdxByName={}
for i,ln in pairs(layoutNames) do layIdxByName[ln.name]=i end
local OUTDOOR={} for l in io.lines("/tmp/t/outdoor.txt") do l=l:gsub("%s+$","") if #l>0 then OUTDOOR[l]=true end end

-- ONE REPRESENTATIVE MAP PER OWNER, and it matters which.
--
-- The atlas is baked per PAIR and Emerald's palettes are per tileset, so the
-- same primary metatile renders in whatever light its partner supplies.  The
-- first version took the alphabetically first "outdoor" map, which for the
-- General tileset was AbandonedShip_Underwater1: every cliff in Hoenn was
-- profiled through a blue underwater palette and came back green.  Score the
-- candidates instead -- daylight overworld first, then size, since a bigger
-- map places more of the owner's vocabulary.
local mapRec={}
do
  local all=assert(loadfile(GEN.."maps.lua"))()
  for _,v in pairs(all) do if v.id then mapRec[v.id]=v end end
end
local function score(name, id, lay)
  local r=mapRec[id]
  local s=0
  if r and r.outdoor then s=s+400 end
  if r and r.mapType=="UNDERWATER" then s=s-800 end
  if name:find("Underwater") then s=s-800 end
  if r and (r.mapType=="TOWN" or r.mapType=="CITY" or r.mapType=="ROUTE") then s=s+200 end
  return s + math.min(200, (lay.width or 0)*(lay.height or 0)/40)
end
local rep={}
for id,ent in pairs(g3maps.maps or {}) do
  local li=layIdxByName[ent.layout]
  local lay=li and layouts[li]
  if lay and lay.blocks then
    local pkey=("P%07X"):format(lay.primaryTileset or 0)
    local skey=("S%07X"):format(lay.secondaryTileset or 0)
    local sc=score(ent.name, id, lay)
    for _,k in ipairs({pkey,skey}) do
      local cur=rep[k]
      -- ...AND THE TIE IS BROKEN BY NAME, NOT BY HASH ORDER.
      --
      -- The scores tie often enough to matter: Route111 and Route119 both
      -- score 740.00 for P03DF704, and Route110_TrickHousePuzzle1..8 all
      -- score 8.25.  A strict `>` over `pairs()` order left the winner to the
      -- hash, and with it the palette every row of that owner was profiled
      -- through.  LOWEST name in ASCII order wins -- the same rule as the
      -- material tie below and as every `table.sort` in this file.
      --
      -- It does NOT reproduce the shipped data/gen3_metatiles.lua, and
      -- nothing can: the shipped table names Route110_TrickHousePuzzle6 for
      -- S03DFBFC, which is neither the first nor the last of the eight tied
      -- candidates by name OR by map id.  Measured over all four orderings:
      -- lowest name misses 6 owners of 72, highest name 7, lowest id 6,
      -- highest id 8, and every one of them misses TrickHousePuzzle6.  The
      -- shipped table's representative maps are an address, and are gone.
      if not cur or sc > cur.score
         or (sc == cur.score and ent.name < cur.name) then
        rep[k]={id=id,name=ent.name,lay=lay,score=sc}
      end
    end
  end
end

-- ---- materials -------------------------------------------------------------
local function mat(r,g,b)
  local mx,mn=math.max(r,g,b),math.min(r,g,b)
  if mx-mn<=22 then
    if mx>205 then return "stone" end
    if mx>95 then return "grey" end
    return "dark"
  end
  if b==mx and b-r>35 then return "water" end
  if g==mx and g-r>22 then return "green" end
  if r==mx and r-b>12 then
    if (g-b) < (r-g)*0.9+6 then return "rock" end
    return "sand"
  end
  if b==mx then return "water" end
  if g==mx then return "green" end
  return "other"
end
-- SURFACE materials are things a terrace's top is drawn in; ROCK/stone-face
-- materials are things a vertical wall is drawn in.
local SURFACE={green=true,sand=true,stone=true}
local FACE={rock=true,grey=true,dark=true}

-- ---- helpers over the census strings ---------------------------------------
local function parse(s)
  local a={} local tot=0
  for k,v in (s or ""):gmatch("(%-?%d+):(%d+)") do
    k,v=tonumber(k),tonumber(v) a[#a+1]={k,v} tot=tot+v
  end
  return a, tot
end
local function share(s, want)
  local a,tot=parse(s)
  if tot==0 then return 0 end
  for _,x in ipairs(a) do if x[1]==want then return x[2]/tot end end
  return 0
end
local function dominant(s)
  local a=parse(s)
  return a[1] and a[1][1] or nil
end

-- ---- the classifier --------------------------------------------------------
local out={}
local stats={}
-- ONLY=<owner> restricts the run to one owning tileset, so a change aimed at
-- one tileset produces a diff a reviewer can read.
local ONLY=os.getenv("ONLY")
local owners={} for k in pairs(CENSUS) do
  if (not ONLY) or k==ONLY then owners[#owners+1]=k end
end table.sort(owners)
for _,owner in ipairs(owners) do
  local r=rep[owner]
  local T=CENSUS[owner]
  if r and T then
    local lay=r.lay
    local key=pairKeyFor(lay)
    if key and tilesets[key] then
      local def={id=r.id,width=lay.width,height=lay.height,blocks=lay.blocks,
        collisionCells=lay.collisionCells,elevationCells=lay.elevationCells,
        border=lay.border,
        borderBlock=lay.border and (lay.border:byte(1)+lay.border:byte(2)*256)%1024 or 0,
        tileset=key}
      local okm,map=pcall(Map.new,def,tilesets[key])
      local a=okm and Gen3.atlasDataForTileset(map.tileset)
      if a then
        local function px(m,x,y)
          local qx,qy=math.floor(x/8),math.floor(y/8)
          local t=m*4+qy*2+qx
          return a:getPixel((t%16)*8+(x%8), math.floor(t/16)*8+(y%8))
        end
        local rows={}
        for m,e in pairs(T) do
          local prof={}
          local count={}
          for y=0,15 do
            local tally={}
            for x=0,15 do
              local rr,gg,bb,al=px(m,x,y)
              local k=(al and al>0) and mat(rr*255,gg*255,bb*255) or "none"
              tally[k]=(tally[k] or 0)+1
            end
            -- ...AND A TIE BETWEEN TWO MATERIALS IS BROKEN BY NAME.
            --
            -- A pixel row split evenly -- eight rock, eight green -- had its
            -- winning material chosen by `pairs()` order over a table keyed
            -- by material NAME, so it was chosen by the hash.  With the two
            -- ordering faults above fixed this was still worth 28 disagreeing
            -- rows between two runs of the generator with no code change:
            -- 573/575 of one owner came out cap 5 in one run and cap 16 in
            -- the next, and 566 of another `face`/16 then `brow`/13.  Lowest
            -- material name wins, which is a rule rather than an address.
            local best,bn=nil,0
            local tks={} for k in pairs(tally) do tks[#tks+1]=k end
            table.sort(tks)
            for _,k in ipairs(tks) do
              local v=tally[k]
              if v>bn then best,bn=k,v end
            end
            prof[y+1]=best or "none"
            count[best]=(count[best] or 0)+1
          end
          -- leading surface rows, then face rows
          local cap=0
          while cap<16 and SURFACE[prof[cap+1]] do cap=cap+1 end
          -- ...and the same count taken from the BOTTOM, which is what gives
          -- a cliff its FACING.  Emerald draws a south-facing cliff with the
          -- terrace on top and the wall beneath it (104: nine rows of grass
          -- over seven of rock), so the higher ground is NORTH.  It also
          -- draws north-facing rims -- 38 of them in the General tileset --
          -- where the wall is on top and the terrace below, and the higher
          -- ground is SOUTH.  Reading both the same way is what made the
          -- terrace pass close a switchback with a sign error in it.
          local trailCap=0
          while trailCap<16 and SURFACE[prof[16-trailCap]] do trailCap=trailCap+1 end
          local faceRun=0
          for y=cap+1,16 do if FACE[prof[y]] then faceRun=faceRun+1 else break end end
          local nSurf,nFace=0,0
          for _,p in ipairs(prof) do
            if SURFACE[p] then nSurf=nSurf+1 elseif FACE[p] then nFace=nFace+1 end
          end
          -- ==============================================================
          -- WHAT THE DRAWING IS -- not what the cell is.
          --
          -- The first version of this table baked collision into the role and
          -- it was wrong for the reason this whole mod keeps rediscovering:
          -- in Gen 3 collision belongs to the CELL, not the metatile.  Route
          -- 111's desert plateau and the wall holding it up are drawn with
          -- the SAME metatile 113 -- 3490 cells of it blocked, 2242 walkable
          -- -- so a per-metatile "is this a cliff" question has no answer.
          -- Asked of the art alone it does: 113 is sixteen rows of rock, and
          -- whether that rock is a floor you stand on or a face you walk past
          -- is the blockdata's business, resolved per cell at mesh time.
          --
          --   art       surface  every row is a top -- grass, sand, worked stone
          --             face     every row is a vertical material
          --             brow     surface rows then face rows: the drawn lip
          --                      of a drop, and `cap` is where it turns over
          --             banded   alternating rows of worked material: treads
          --   material  what it is made of, which is what separates a crater
          --             wall (rock) from a house wall (manmade) when both are
          --             blocked and both sit at elevation 0
          -- ==============================================================
          local flips=0
          for y=2,16 do if prof[y]~=prof[y-1] then flips=flips+1 end end
          -- ------------------------------------------------------------------
          -- A TREAD IS PERIODIC.  Emerald draws two 8-pixel steps into one
          -- metatile, so a staircase's row luminance REPEATS at period eight:
          -- 175 reads 182 202 205 208 250 133 133 133 and then those eight
          -- values again, exactly.  Rock does not -- 191 is a cliff face whose
          -- rows wander (108 140 175 199 ... 183 186 175 177) and never line
          -- up with themselves.
          --
          -- Counting material changes per row, which is what this used to do,
          -- could not tell the two apart: both flip plenty.  Periodicity plus
          -- a real light-to-dark drop inside each period is the tread, and it
          -- needs no palette, so it finds Mt Pyre's grey treads and
          -- Sootopolis' white ones with one test.
          -- ------------------------------------------------------------------
          -- ...and WHICH WAY the treads run, which is the same measurement
          -- taken along the other axis.  Horizontal bands mean you climb
          -- north-south; vertical bands mean east-west.  Every stair metatile
          -- Hoenn actually places is emphatic about it -- Mt Pyre's 175 and
          -- Sootopolis' 580 both read rows rep8=0.0 over a drop of 80-120
          -- with their columns dead flat -- so the flight's axis is a fact
          -- about the art and never needs to be inferred from which pair of
          -- landings happens to sit further apart.
          local rowL, colL = {}, {}
          for y=0,15 do
            local acc=0
            for x=0,15 do local rr,gg,bb=px(m,x,y) acc=acc+(rr+gg+bb)/3*255 end
            rowL[y+1]=acc/16
          end
          for x=0,15 do
            local acc=0
            for y=0,15 do local rr,gg,bb=px(m,x,y) acc=acc+(rr+gg+bb)/3*255 end
            colL[x+1]=acc/16
          end
          local function band(t)
            local lo,hi=t[1],t[1]
            for _,L in ipairs(t) do if L<lo then lo=L end if L>hi then hi=L end end
            local rep=0
            for i=1,8 do rep=rep+math.abs(t[i]-t[i+8]) end
            return (hi-lo), rep/8
          end
          local dRow,pRow = band(rowL)
          local dCol,pCol = band(colL)
          local rowBanded = dRow >= 55 and pRow <= 16
          local colBanded = dCol >= 55 and pCol <= 16
          local periodic = rowBanded or colBanded
          -- ------------------------------------------------------------------
          -- DOES THIS METATILE DRAW A LEDGE?
          --
          -- The count of stacked ledges is what a cliff's height IS, and the
          -- first attempt counted "brow" metatiles -- which in Sootopolis
          -- counts the raised BODY as well as its edge, because a cap of one
          -- pixel over a face of one pixel is texture, not a step.
          --
          -- A ledge is a hard SHADOW LINE: one row far darker than the rows
          -- either side of it.  Sootopolis' terrace edge, 577, reads
          -- 220 211 [106] 229 229 255 208 169 ... 169 [81] 133 133 -- two
          -- shadow lines bracketing one course of masonry.  Its raised body,
          -- 737, reads 206 189 179 165 159 158 ... and never dips.  The
          -- street, 729, never dips either.  One test separates all three.
          -- ------------------------------------------------------------------
          local ledge = false
          for y = 2, 15 do
            local L, a1, b1 = rowL[y], rowL[y - 1], rowL[y + 1]
            if a1 - L >= 40 and b1 - L >= 40 then ledge = true break end
          end
          -- when both read banded, the one with the deeper light-to-dark
          -- swing is the tread face and the other is its shading
          local bandAxis = ""
          if rowBanded and colBanded then
            bandAxis = (dRow >= dCol) and "y" or "x"
          elseif rowBanded then bandAxis = "y"
          elseif colBanded then bandAxis = "x" end
          local rocky   = count.rock or 0
          local manmade = (count.grey or 0)+(count.stone or 0)+(count.other or 0)
          local greeny  = count.green or 0
          local sandy   = count.sand or 0
          local watery  = count.water or 0
          local material
          if watery >= 10 then material="water"
          elseif rocky >= manmade and rocky >= greeny and rocky >= sandy and rocky > 0 then material="rock"
          elseif greeny >= manmade and greeny >= sandy and greeny > 0 then material="green"
          elseif sandy >= manmade and sandy > 0 then material="sand"
          elseif manmade > 0 then material="manmade"
          else material="other" end
          local facing = ""
          if nFace > 0 then
            if cap > trailCap then facing = "S"
            elseif trailCap > cap then facing = "N" end
          end
          local art
          if periodic and material ~= "water" and material ~= "green" then
            art = "banded"
          elseif nFace == 0 then art="surface"
          elseif nSurf == 0 then art="face"
          elseif cap >= 1 and faceRun >= 2 then art="brow"
          else art="brow" end
          local cls = BEH[e.beh]
          local kind
          if cls=="water" or cls=="deep" or cls=="waterfall" or cls=="dive" then kind="water"
          elseif cls=="ledge" then kind="ledge"
          elseif cls=="tree" then kind="tree"
          elseif e.beh==0x0C then kind="mountain"      -- MB_MOUNTAIN_TOP
          else kind="" end
          local role=art  -- the emitted role IS the art family now
          rows[m]={role=role, art=art, material=material, kind=kind,
                   axis=bandAxis, facing=facing, ledge=ledge,
                   cap=cap, face=faceRun, beh=e.beh, layer=e.layer,
                   n=e.n, nmaps=e.nmaps, nFace=nFace, nSurf=nSurf,
                   green=greeny, rock=rocky, down=e.down, up=e.up}
        end

        -- ------------------------------------------------------------------
        -- PASS 2: A CAP MUST HAVE A FACE UNDER IT.
        --
        -- The first pass calls any blocked, all-surface metatile a cliff cap,
        -- and Hoenn's TREES are exactly that: 468 over 476 on the General
        -- pair is a tree, drawn entirely in green, blocked, and at elevation
        -- 0 like every other thing you cannot stand on.  Three and a half
        -- thousand cells of forest were being meshed as clifftop.
        --
        -- A real cap is the top of an assembly: walk DOWN the dominant
        -- neighbour chain and a cliff reaches rock within a few cells, while
        -- a tree bottoms out on grass.  That is the test, and it needs no
        -- list of tree ids.
        -- ------------------------------------------------------------------
        local function domDown(m)
          local best,bn=nil,0
          for k,v in (rows[m] and rows[m].down or ""):gmatch("(%-?%d+):(%d+)") do
            k,v=tonumber(k),tonumber(v)
            if v>bn then best,bn=k,v end
          end
          return best
        end
        for m,rr in pairs(rows) do
          if rr.art=="surface" and rr.material~="water" then
            local cur, ok, seen = m, false, {}
            for _=1,4 do
              local d=domDown(cur)
              if not d or seen[d] then break end
              seen[d]=true
              local rd=rows[d]
              if not rd then break end
              if rd.nFace and rd.nFace > 0 then ok=true break end
              if rd.role=="floor" or rd.role=="water" then break end
              cur=d
            end
            -- a surface with no face anywhere under it is not the top of a
            -- drop; it is foliage or a standalone object
            rr.motif = (not ok) and true or nil
          end
        end
        for _,rr in pairs(rows) do
          stats[rr.art.."/"..rr.material]=(stats[rr.art.."/"..rr.material] or 0)+1
        end
        out[owner]={rows=rows, via=r.name}
      end
    end
  end
end

-- ---- emit ------------------------------------------------------------------
local L={green="G",rock="R",sand="S",water="B",grey="Y",stone="W",dark="K",other="O",none="-"}
local f=io.open(os.getenv("OUT") or "/tmp/t/gen3_metatiles.lua","w")
f:write("-- GENERATED by /tmp/t/mkroles.lua from the Emerald ROM data.\n")
f:write("-- Do not hand-edit: regenerate.  See lib/Gen3.lua roleOf().\nreturn {\n  version = 1,\n  roles = {\n")
table.sort(owners)
for _,owner in ipairs(owners) do
  local o=out[owner]
  if o then
    local ms={} for m in pairs(o.rows) do ms[#ms+1]=m end table.sort(ms)
    f:write(("    [%q] = { -- profiled via %s\n"):format(owner, o.via))
    for _,m in ipairs(ms) do
      local r=o.rows[m]
      f:write(("      [%d]={%q,%q,%d,%d,%q,%s,%q,%q,%s},\n")
        :format(m, r.art, r.material, r.cap, r.face, r.kind,
                r.motif and "true" or "false", r.axis or "", r.facing or "",
                r.ledge and "true" or "false"))
    end
    f:write("    },\n")
  end
end
f:write("  },\n}\n")
f:close()
local tot=0
local ks={} for k in pairs(stats) do ks[#ks+1]=k end table.sort(ks)
for _,k in ipairs(ks) do tot=tot+stats[k] io.stderr:write(("%-12s %d\n"):format(k,stats[k])) end
io.stderr:write(("TOTAL        %d rows over %d owners\n"):format(tot,#owners))
