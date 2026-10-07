--[[
MSP_SimpleStatusRulerBatch — Simple Status 狀態條每幀約 1,900 次 Lua→Java 呼叫，八成花在刻度記號的描邊

【上游】Simple Status（Workshop 2867431511，mod id simpleStatus，核對版本 modversion 2.260901.1、檔頭 VERSION 2.260913.1；
42.21 載入 `42.20/`）。upstream.json 有登記。

【缺陷】（行號為上游 42.20/media/lua/client/ISSSBar.lua）
`SSBar:prerender`（:452）每幀重畫整個面板（數值每 10 幀才重算，:459）。畫的是 `renderHBars`／`renderVBars`（:361／:396）：
有刻度的條各畫 4 個刻度，`drawRuler`（:72-97）每個刻度用 8 個 1 像素寬的矩形描背景色邊框、再畫 1 個白色實心矩形，共 9 次
`drawRectStatic`；原版 `ISUIElement:drawRectStatic` 每次又各呼叫一次 `getXScroll`／`getYScroll`（原版 ISUIElement.lua:1204-1208），
一個矩形＝3 次 Java 呼叫。預設 18 條（14 條有刻度）每幀約 1,900 次 Java 呼叫，其中刻度約 1,500 次。2026-10-07 正式服複本
DevProfiler：`ISSSBar.lua:453` 約 44 ms／秒，是最大的常駐 Lua 介面成本。

【修法】畫面逐像素相同，只減少呼叫次數。
- `drawRuler`：8 個邊框矩形改成 1 個（寬高各 +2）背景色矩形墊底，再畫同一個白色矩形。白色 alpha 1.0，UI 的混色
  （`UIManager.java:279-281`：SRC_ALPHA／ONE_MINUS_SRC_ALPHA，FBO 時 alpha 通道 ONE／ONE_MINUS_SRC_ALPHA）下不透明來源
  完全覆蓋底色，所以中間被墊的部分最後仍是純白，外圈 1 像素與原本 8 塊的聯集相同（座標由 `UIElement.DrawTextureScaledCol`
  逐一截成整數，`UIElement.java:469-483`）。9 次 drawRectStatic → 2 次。
- `drawRectStatic`：`prerender` 開頭讀一次 scroll，同一幀內的 drawRectStatic 直接呼叫 `javaObject:DrawTextureScaledColor`，
  參數與原版相同（x−scroll、y−scroll）。prerender 之外的呼叫照原版。面板不捲動，scroll 恆為 0；就算有值，一幀內也沒有人改它。
- 合計預設 18 條每幀約 1,900 → 約 400 次 Java 呼叫；文字（每個標籤 5 次 drawText）、量字寬、數值重算都不動。
已知差異：刻度的絕對座標落在 (−1, 1) 時（面板拖到螢幕左緣或上緣外），Java 對負數往 0 截斷，原版那一個像素會被描邊疊兩次、
本補丁只疊一次。其餘位置（含負座標的其他像素）相同。

【為什麼不改上游】他人的 Workshop MOD，本服不重新發布；只在客戶端減少同一畫面的繪製呼叫，不改數值、設定或存檔。

【軟依賴】不在載入時 require 上游。`getActivatedMods()` 沒有 simpleStatus 就直接 return，不註冊任何事件；有的話在
`OnGameBoot`（Lua 全部載入後）才 `require("ISSSBar")` 拿到同一個類別表（`LuaManager.java:1347-1350` 回傳已載入的結果），
形狀不符（缺 prerender／drawRuler／drawRectStatic）印一行 NOT installed，上游原樣。

【上游更新時要重核】見 upstream.json 的 recheck。
]]

local PREFIX = "[MinidoracatServerPatchFor42][simpleStatus]"
local MOD_ID = "simpleStatus"

local mods = getActivatedMods()
if not (mods:contains(MOD_ID) or mods:contains("\\" .. MOD_ID)) then return end

local function install()
    local SSBar = require("ISSSBar")
    if type(SSBar) ~= "table" or SSBar.MSP_rulerBatch then return end
    local prerender, drawRectStatic = SSBar.prerender, SSBar.drawRectStatic
    if type(prerender) ~= "function" or type(drawRectStatic) ~= "function" or type(SSBar.drawRuler) ~= "function" then
        print(PREFIX .. " NOT installed: ISSSBar shape changed; re-check upstream.json recheck notes")
        return
    end

    function SSBar:prerender()
        local jo = self.javaObject
        if jo then self.MSP_scrollX, self.MSP_scrollY = jo:getXScroll(), jo:getYScroll() end
        prerender(self)
        self.MSP_scrollX = nil
    end

    function SSBar:drawRectStatic(x, y, w, h, a, r, g, b)
        local sx = self.MSP_scrollX
        if sx == nil then return drawRectStatic(self, x, y, w, h, a, r, g, b) end
        self.javaObject:DrawTextureScaledColor(nil, x - sx, y - self.MSP_scrollY, w, h, r, g, b, a)
    end

    function SSBar:drawRuler(x, y, p)
        local w, h = 2, 4
        if self.config.isVertical then
            y, w, h = y + (1 - p) * self.barLength, 4, 2
        else
            x = x + p * self.barLength
        end
        local c = self.backgroundColor
        self:drawRectStatic(x - 1, y - 1, w + 2, h + 2, c.a, c.r, c.g, c.b)
        self:drawRectStatic(x, y, w, h, 1.0, 1.0, 1.0, 1.0)
    end

    SSBar.MSP_rulerBatch = true
    print(PREFIX .. " ruler batch installed")
end

Events.OnGameBoot.Add(install)
