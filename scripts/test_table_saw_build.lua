-- 離線測試：ISMSPBuildTableSaw:new() 的 modData 組裝與 haveMaterial 的閘門。最小引擎 stub，不需遊戲。
--   lua scripts/test_table_saw_build.lua
local LUA = "MOD/MinidoracatServerPatchFor42/Contents/mods/MinidoracatServerPatchFor42/42/media/lua/"

ISBuildingObject = {}
function ISBuildingObject:derive(name) local o = { Type = name }; setmetatable(o, self); self.__index = self; return o end
function ISBuildingObject:init() self.modData = {} end
function ISBuildingObject:setSprite(s) self.sprite = s end
function ISBuildingObject:setNorthSprite(s) self.northSprite = s end
function ISBuildingObject:setEastSprite(s) self.eastSprite = s end
function ISBuildingObject:setSouthSprite(s) self.southSprite = s end
function ISBuildingObject:haveMaterial() return true end
function ISBuildingObject:isValid() return true end
function ISBuildingObject:render() end
buildUtil = { stairIsBlockingPlacement = function() return false end }
Perks = { MetalWelding = "MetalWelding" }
ISBuildMenu = { cheat = false }
SandboxVars = {}

local player = { recipes = {}, perk = 0, mask = false, cheat = false }
function player:getKnownRecipes() return { contains = function(_, r) return player.recipes[r] == true end } end
function player:getPerkLevel(_) return self.perk end
function player:isBuildCheat() return self.cheat end
function player:getInventory()
    return { getFirstTypeRecurse = function(_, t) return (t == "Base.WeldingMask" and player.mask) and {} or nil end }
end
function getSpecificPlayer(_) return player end

dofile(LUA .. "shared/Patches/TableSaw/MSP_TableSawBuild.lua")
dofile(LUA .. "server/Patches/TableSaw/MSP_TableSawBuildCursor.lua")
local TSB = MSP_TableSawBuild

local pass, fail = 0, 0
local function check(name, cond)
    if cond then pass = pass + 1; print("  PASS  " .. name) else fail = fail + 1; print("  FAIL  " .. name) end
end

local o = ISMSPBuildTableSaw:new(0)
check("sprite 四向", o.sprite == "TableSaw_0" and o.northSprite == "TableSaw_1" and o.eastSprite == "TableSaw_2" and o.southSprite == "TableSaw_3")
check("noNeedHammer / firstItem / secondItem", o.noNeedHammer == true and o.firstItem == "BlowTorch" and o.secondItem == "WeldingMask")
check("dragNilAfterPlace", o.dragNilAfterPlace == true)
local needN, useN = 0, 0
for k in pairs(o.modData) do
    if k:sub(1, 5) == "need:" then needN = needN + 1 end
    if k:sub(1, 4) == "use:" then useN = useN + 1 end
end
check("need: 6 項", needN == 6)
check("use: 2 項", useN == 2)
check("need:Base.SheetMetal = 8", o.modData["need:Base.SheetMetal"] == 8)
check("use:Base.BlowTorch = 4", o.modData["use:Base.BlowTorch"] == 4)
check("xp:MetalWelding = 1", o.modData["xp:MetalWelding"] == 1)

local function setPlayer(recipe, perk, mask, cheat)
    player.recipes = recipe and { [TSB.RECIPE_NAME] = true } or {}
    player.perk, player.mask, player.cheat = perk, mask, cheat
end
setPlayer(true, 5, true, false);  check("全部符合 → true", o:haveMaterial() == true)
setPlayer(false, 5, true, false); check("缺配方 → false", o:haveMaterial() == false)
setPlayer(true, 4, true, false);  check("技能 4 → false", o:haveMaterial() == false)
setPlayer(true, 5, false, false); check("無面罩 → false", o:haveMaterial() == false)
setPlayer(false, 0, false, true); check("build cheat → true", o:haveMaterial() == true)
ISBuildMenu.cheat = true; setPlayer(false, 0, false, false)
check("ISBuildMenu.cheat → true", o:haveMaterial() == true)
ISBuildMenu.cheat = false
local savedHM = ISBuildingObject.haveMaterial
ISBuildingObject.haveMaterial = function() return false end
setPlayer(true, 5, true, false);  check("vanilla 材料不足 → false", o:haveMaterial() == false)
ISBuildingObject.haveMaterial = savedHM

TableSawSpriteList = nil;                 check("TableSaw 未載入 → false", TSB.isTableSawLoaded() == false)
TableSawSpriteList = { TableSaw_0 = {} }; check("TableSaw 已載入 → true", TSB.isTableSawLoaded() == true)

print(string.format("PASS %d / FAIL %d", pass, fail))
os.exit(fail == 0 and 0 or 1)
