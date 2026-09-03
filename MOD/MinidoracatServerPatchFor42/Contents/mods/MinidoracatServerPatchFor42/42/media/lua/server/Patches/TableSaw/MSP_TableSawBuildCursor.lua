--[[
ISMSPBuildTableSaw — 台鋸建造游標（vanilla ISBuildingObject 老路徑）。上游與缺陷見 shared 檔頭。

流程全走 vanilla：右鍵 → getCell():setDrag(cursor) → DoTileBuilding → isValid（內含
haveMaterial）→ tryBuild（裝備 firstItem BlowTorch、穿上 secondItem WeldingMask、
ISBuildAction）→ create。材料消耗交給 buildUtil.consumeMaterial（吃 modData 的
need:/use:/xp:），動畫由 firstItem=="BlowTorch" 自動選 BlowTorch
（ISBuildingObject.lua:323-333）。

create 的物件形狀照 TableSaw 自己的 ISBuildTableSaw:create（IsoThumpable、modData.Durable／
SawBladeDurable、容器由 sprite 屬性建立並套 ContainerCapacity）——右鍵選單／隨機生成
辨識台鋸只看 sprite 名（TableSawRightClickMenu.lua:38-44），所以只要 sprite 與 modData 對，
TableSaw 自己的鋸木／修理／換鋸片全部照常運作。不能直接復用它的 class：其 create 在 server 端
會經 setFurnitureData 索引 Building_Data（ISBuildTableSaw.lua:53）。

放 server/ 目錄：與 vanilla ISWoodenWall 等同目錄；MP client 也會載入 server/
（GameLoadingState.java:149 LoadDirBase("server")），dedicated server 端 create 時可用。
]]

local TSB = MSP_TableSawBuild

ISMSPBuildTableSaw = ISBuildingObject:derive("ISMSPBuildTableSaw")

-- 消耗前先讀一把鋸片的耐久，讓新台鋸沿用玩家實際投入的那片（照 TableSaw 的
-- consumeMaterial :69-75／:98-103 語意）；找不到就沿用它的預設值。
local function peekBladeDurable(self)
    local fallback = (SawBladeMaxDurable or SandboxVars.TableSawSawBladeDurable or 100) - ZombRandFloat(0.00, 8.00)
    local playerObj = getSpecificPlayer(self.player)
    if not playerObj then return fallback end
    local blade = playerObj:getInventory():getFirstTypeEvalRecurse("Base.CircularSawblade", buildUtil.predicateMaterial)
    if not blade and self.sq then
        local ground = buildUtil.getMaterialOnGround(self.sq)["Base.CircularSawblade"]
        blade = ground and ground[1] or nil
    end
    if blade then
        local d = blade:getModData().Durable
        if type(d) == "number" then return d end
    end
    return fallback
end

function ISMSPBuildTableSaw:create(x, y, z, north, sprite)
    local cell = getWorld():getCell()
    self.sq = cell:getGridSquare(x, y, z)
    local bladeDurable = peekBladeDurable(self)

    self.javaObject = IsoThumpable.new(cell, self.sq, sprite, north, self)
    buildUtil.setInfo(self.javaObject, self)
    buildUtil.consumeMaterial(self)
    self.javaObject:setMaxHealth(self:getHealth())
    self.javaObject:setHealth(self.javaObject:getMaxHealth())
    self.javaObject:setBreakSound(IsoThumpable.GetBreakFurnitureSound(sprite))

    local modData = self.javaObject:getModData()
    local maxDurable = TableSawMaxDurable or SandboxVars.TableSawDurable or 80
    modData.Durable = maxDurable - ZombRandFloat(0.00, 5.00)
    modData.SawBladeDurable = bladeDurable

    local capacity = 50
    local sharedSprite = getSprite(sprite)
    local props = sharedSprite and sharedSprite:getProperties()
    if props and props:has("ContainerCapacity") then
        capacity = tonumber(props:get("ContainerCapacity")) or capacity
    end
    self.javaObject:createContainersFromSpriteProperties()
    for i = 1, self.javaObject:getContainerCount() do
        local container = self.javaObject:getContainerByIndex(i - 1)
        container:setCapacity(capacity)
        container:setExplored(true)
    end

    self.sq:AddSpecialObject(self.javaObject)
    self.javaObject:transmitCompleteItemToClients()
    self.sq:RecalcProperties()
    self.sq:RecalcAllWithNeighbours(true)
end

function ISMSPBuildTableSaw:getHealth()
    return 100 + buildUtil.getWoodHealth(self)
end

-- 材料之外再要求：雜誌配方、技能、焊接面罩。isValid 會呼叫本函式，不符時游標變紅。
function ISMSPBuildTableSaw:haveMaterial(square)
    if not ISBuildingObject.haveMaterial(self, square) then return false end
    local playerObj = self.character or getSpecificPlayer(self.player)
    if not playerObj then return false end
    if TSB.isCheat(playerObj) then return true end
    return TSB.knowsRecipe(playerObj) and TSB.hasSkill(playerObj) and TSB.hasWeldingMask(playerObj)
end

function ISMSPBuildTableSaw:isValid(square)
    if not ISBuildingObject.isValid(self, square) then return false end
    if buildUtil.stairIsBlockingPlacement(square, true) then return false end
    return true
end

function ISMSPBuildTableSaw:render(x, y, z, square)
    ISBuildingObject.render(self, x, y, z, square)
end

function ISMSPBuildTableSaw:new(playerNum)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o:init()
    o:setSprite(TSB.SPRITES[1])
    o:setNorthSprite(TSB.SPRITES[2])
    o:setEastSprite(TSB.SPRITES[3])
    o:setSouthSprite(TSB.SPRITES[4])
    o.player = playerNum
    o.name = "TableSaw"
    o.canBeAlwaysPlaced = true   -- 照 ISBuildTableSaw:new :329
    o.isContainer = true
    o.dismantable = false        -- 拆解會依 vanilla 木材表退料，與此配方不符
    o.noNeedHammer = true
    o.firstItem = "BlowTorch"    -- tryBuild 會裝備；onTimedActionStart 據此選焊接動畫
    o.secondItem = "WeldingMask" -- tryBuild 對 Clothing 會自動穿上
    o.dragNilAfterPlace = true
    for fullType, n in pairs(TSB.NEED) do o.modData["need:" .. fullType] = n end
    for fullType, n in pairs(TSB.USE) do o.modData["use:" .. fullType] = n end
    o.modData["xp:MetalWelding"] = TSB.XP
    -- ponytail: 建造時間沿用 vanilla 預設（200 − 木工×5，ISBuildingObject.lua:186）；
    -- 要改成依焊接等級就設 o.maxTime
    return o
end
