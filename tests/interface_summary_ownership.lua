local interfaceMode = "battle_art"
local originalLove = love
local function image(width, height)
  return {
    getWidth = function() return width end,
    getDimensions = function() return width, height end,
  }
end
local replacement, rom = image(56, 56), image(56, 56)
local drawn
love = { graphics = {
  draw = function(drawable, x, y, rotation, scaleX, scaleY)
    drawn = { drawable, x, y, rotation, scaleX, scaleY }
  end,
} }
local native = { updates = 0 }
function native:update() self.updates = self.updates + 1 end
function native:image() return rom end

local SummaryMenu = {}
function SummaryMenu.new(_, mon)
  return setmetatable(
    { mon = mon, sprite = rom, spriteTrueColor = false, picAnim = native },
    { __index = SummaryMenu })
end
function SummaryMenu:update()
  if self.picAnim then self.picAnim:update() end
end
function SummaryMenu:draw()
  self.drawn = (self.picAnim and self.picAnim:image()) or self.sprite
  local width = self.drawn:getWidth()
  love.graphics.draw(self.drawn, 8 + width, 0, 0, -1, 1)
end
package.loaded["src.ui.SummaryMenu"] = SummaryMenu

local setting = { get = function() return interfaceMode end }
local flipFront = true
local BattleArt = {
  setting = { get = function() return "animated" end },
  frontAnimationSetting = { get = function() return "gen4" end },
  displayMode = function() return "color" end,
  flipsPlayerFront = function() return flipFront end,
  fitPreparedFrames = function(frames) return frames end,
}
local AnimatedBattleArt = {
  interfaceFront = function() return { replacement }, { 100 } end,
}
local V = {
  require = function(name)
    if name == "ModSetting" then
      return { new = function() return setting end }
    elseif name == "BattleArt" then
      return BattleArt
    elseif name == "AnimatedBattleArt" then
      return AnimatedBattleArt
    end
    error(name)
  end,
  mod = { assets = { path = function(_, path) return path end } },
}

local InterfaceSprites = assert(loadfile("lib/InterfaceSprites.lua"))(V)
InterfaceSprites.installSummary()

local summary = SummaryMenu.new({}, { species = "SPECIES_TEST" })
assert(summary.picAnim == nil,
  "summary retained its native Crystal animation under replacement art")
summary:update(1 / 60)
assert(native.updates == 0, "suppressed native summary animation still advanced")
summary:draw()
assert(summary.drawn == replacement, "summary did not draw replacement art")
assert(drawn[2] == 64 and drawn[5] == -1,
  "BATTLE ART no longer mirrors the summary front sprite")

flipFront = false
summary:draw()
assert(drawn[2] == 8 and drawn[5] == 1,
  "DEFAULT did not preserve summary sprite orientation")

interfaceMode = "off"
summary:draw()
assert(summary.sprite == rom and summary.picAnim == native,
  "summary did not restore its ROM sprite provider")

love = originalLove
print("interface summary ownership regression: ok")
