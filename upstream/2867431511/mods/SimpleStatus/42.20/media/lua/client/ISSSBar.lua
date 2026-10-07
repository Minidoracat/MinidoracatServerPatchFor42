---@diagnostic disable: inject-field

local utils           = require("ss.utils")
local stats           = require("ss.stats")
local ssOptions       = require("ss.options")
local color           = utils.color

local getBarTitile    = utils.fn.getBarTitile
local getOptName      = utils.fn.getOptName
local getPColor       = utils.fn.getPColor
local getStrWidth     = utils.fn.getStrWidth
local getTempertueStr = utils.fn.getTempertueStr
local to_upper        = utils.fn.to_upper

-- Save all player config to ModData
---@param config table
---@param player IsoPlayer
local function savePlayerData(config, player)
    local data            = {}
    data["SS_pos_x"]      = config.pos[1]
    data["SS_pos_y"]      = config.pos[2]
    data["SS_locked"]     = config.locked
    data["SS_fontSize"]   = config.fontSize
    data["SS_isVertical"] = config.isVertical
    data["SS_isRulerOn"]  = config.isRulerOn
    for name, shown in pairs(config.shownConfig) do
        data["SS_shown_" .. name] = shown
    end
    for name, toggled in pairs(config.toggleStats) do
        data["SS_tog_" .. name] = toggled
    end

    local md = player:getModData()
    md["SimpleStatusConfig"] = data
    player:transmitModData()
end

---@class SSBar:ISPanel
---@field player IsoPlayer
---@field playerNum integer
---@field username string
---@field config table
---@field font UIFont
---@field barInfo table
---@field titleLength integer
---@field textLength integer
---@field barLength integer
---@field timer integer
---@field shown boolean
---@field reopenMenuNextFrame boolean
---@field lastMenuX integer
---@field lastMenuY integer
local SSBar = ISPanel:derive("SSBar")

local function getReverseStat(value)
    local tbl = stats._reverse
    if tbl[value] ~= nil then return tbl[value] end
    return stats._reverseLookup[value]
end

function SSBar:drawTextWithShadow(text, x, y)
    -- 4-directional shadow instead of 8: halves the drawText calls per label
    -- (called twice per bar per frame) with no noticeable readability loss.
    self:drawText(text, x + 1, y, 0.0, 0.0, 0.0, 0.66, self.font)
    self:drawText(text, x, y + 1, 0.0, 0.0, 0.0, 0.66, self.font)
    self:drawText(text, x - 1, y, 0.0, 0.0, 0.0, 0.66, self.font)
    self:drawText(text, x, y - 1, 0.0, 0.0, 0.0, 0.66, self.font)

    self:drawText(text, x, y, 1.0, 1.0, 1.0, 1.0, self.font)
end

function SSBar:drawRuler(x, y, p)
    local ruler_width = 4
    local c = self.backgroundColor
    local w, h

    if not self.config.isVertical then
        x, y = x + p * self.barLength, y
        w, h = 2, ruler_width
    else
        x, y = x, y + (1 - p) * self.barLength
        w, h = ruler_width, 2
    end


    self:drawRectStatic(x - 1, y - 1, 1, 1, c.a, c.r, c.g, c.b)
    self:drawRectStatic(x - 1, y + h, 1, 1, c.a, c.r, c.g, c.b)
    self:drawRectStatic(x + w, y - 1, 1, 1, c.a, c.r, c.g, c.b)
    self:drawRectStatic(x + w, y + h, 1, 1, c.a, c.r, c.g, c.b)

    self:drawRectStatic(x - 1, y, 1, h, c.a, c.r, c.g, c.b)
    self:drawRectStatic(x + w, y, 1, h, c.a, c.r, c.g, c.b)
    self:drawRectStatic(x, y - 1, w, 1, c.a, c.r, c.g, c.b)
    self:drawRectStatic(x, y + h, w, 1, c.a, c.r, c.g, c.b)

    self:drawRectStatic(x, y, w, h, 1.0, 1.0, 1.0, 1.0)
end

function SSBar:getBarColor(value, isNegative, ruler)
    if ruler == nil then
        ruler = { 75, 50, 25, 10 }
    end
    -- value in range [0, 100]
    -- ivalue is 0 or 100
    local c = color.green
    if isNegative then
        value = 100 - value
        ruler = {
            100 - ruler[1],
            100 - ruler[2],
            100 - ruler[3],
            100 - ruler[4]
        }
    end

    if value > ruler[1] then
        c = getPColor(color.yellow, color.green, (value - ruler[1]) / (100 - ruler[1]))
    elseif value > ruler[2] then
        c = getPColor(color.orangeyellow, color.yellow, (value - ruler[2]) / (ruler[1] - ruler[2]))
    elseif value > ruler[3] then
        c = getPColor(color.orange, color.orangeyellow, (value - ruler[3]) / (ruler[2] - ruler[3]))
    elseif value > ruler[4] then
        c = getPColor(color.red, color.orange, (value - ruler[4]) / (ruler[3] - ruler[4]))
    else
        c = color.red
    end
    return c
end

function SSBar:prepareBarInfo()
    local barInfo = {}
    -- title, valueText, color, percent, type, name, ruler

    local bars = {}
    for _, name in ipairs(stats._values) do
        if not stats._reverse[name] and self.config.shownConfig[name] then
            local n = name
            if self.config.toggleStats[name] then
                n = getReverseStat(name) or name
            end
            table.insert(bars, stats[n])
        end
    end

    for _, bar in ipairs(bars) do
        -- name -> title translation never changes during a session; resolve once and
        -- cache it back onto the shared stat table instead of re-translating every frame.
        if not bar.title then bar.title = getBarTitile(to_upper(bar.name)) end
        local title = bar.title
        local name = bar.name
        local _type = bar.type

        local value = nil
        local percent = 1.0
        local text = "-"
        ---@type {r:number, g:number, b:number}
        local c = color.black

        local ruler = nil
        if bar.ruler then
            ruler = { bar.ruler[1], bar.ruler[2], bar.ruler[3], bar.ruler[4] }
        end

        if bar.valueFn then value = bar.valueFn(self.player) end

        if string.sub(_type, 1, 6) == "simple" then
            local valueFlow = nil
            if value ~= nil then
                if value > 100 then
                    valueFlow, value = round(value - 100), 100
                end

                percent = value / 100
                text = tostring(value)
                c = self:getBarColor(value, string.sub(_type, -8) == "negative", ruler)
            end
            if valueFlow then
                text = text .. "(" .. valueFlow .. ")"
            end
            text = text .. " / 100"
        end
        if string.sub(_type, 1, 5) == "plain" then
            local vs = bar.vs

            local v1 = vs[1] or 0
            local v2 = vs[2] or 100
            local v3 = vs[3] or 100

            if string.find(_type, "pg") and vs ~= nil then
                if value < v1 then
                    percent = 0
                elseif value > v3 then
                    percent = 1
                else
                    if value ~= nil then
                        percent = (value - v1) / (v3 - v1)
                    else
                        percent = 0
                    end
                end
            end
            if string.find(_type, "bg") and vs ~= nil then
                local vmin = v1 + (v2 - v1) * 0.3
                local vmax = v2 + (v3 - v2) * 0.7
                local vt = value or 0
                if vt > vmax then
                    c = color.red
                elseif vt > v2 then
                    local p = (vt) / (vmax - v2)
                    c = getPColor(color.green, color.red, p)
                elseif vt > vmin then
                    local p = (v2 - vt) / (v2 - vmin)
                    c = getPColor(color.green, color.blue, p)
                else
                    c = color.blue
                end
            end

            if value then text = tostring(value) end
        end
        if _type == "temp" and value ~= nil then
            if name == "bodytemp" then
                text = getTempertueStr(value)
            else
                text = tostring(value)
            end
        end
        -- if _type == "custom" then pass end
        if bar.percentFn then percent = bar.percentFn(self.player) or percent end
        if bar.textFn then text = bar.textFn(self.player) or text end
        if bar.colorFn then c = bar.colorFn(self.player) or c end

        table.insert(barInfo, { title, text, c, percent, _type, name, ruler })
    end
    self.barInfo = barInfo
end

function SSBar:adjustWindowSize()
    local count = #self.barInfo

    for _, i in ipairs(self.barInfo) do
        local title = i[1]
        local text = i[2]
        local len = getStrWidth(self.font, title) + 20
        if len > self.titleLength then self.titleLength = len end
        len = getStrWidth(self.font, text)
        if len > self.textLength then self.textLength = len end
    end

    self.barLength = self.textLength + self.titleLength

    local w = self.barLength + 6
    local h = (self.config.barWidth + 3) * count + 3

    if self.config.isVertical then
        w = h
        self.barLength = 150
        h = self.barLength + self.config.barWidth + 9
    end

    self:setWidth(w)
    self:setHeight(h)
end

function SSBar:optClick(name)
    self.config.shownConfig[name] = not self.config.shownConfig[name]
    savePlayerData(self.config, self.player)
    self:prepareBarInfo()
    self:adjustWindowSize()
    self.reopenMenuNextFrame = true
end

function SSBar:optClickToggle(name)
    self.config.toggleStats[name] = not self.config.toggleStats[name]
    savePlayerData(self.config, self.player)
    self:prepareBarInfo()
    self:adjustWindowSize()
    self.reopenMenuNextFrame = true
end

function SSBar:optClickVertical()
    self.config.isVertical = not self.config.isVertical
    savePlayerData(self.config, self.player)
    self:adjustWindowSize()
    self.reopenMenuNextFrame = true
end

function SSBar:optClickRuler()
    self.config.isRulerOn = not self.config.isRulerOn
    savePlayerData(self.config, self.player)
    self.reopenMenuNextFrame = true
end

function SSBar:optClickFontSize(fontSize)
    self.config.fontSize = fontSize
    self.font            = utils.font[fontSize] or utils.font.Small
    self.config.barWidth = utils.fn.lineHight(self.font)
    self.titleLength     = 0
    self.textLength      = 0
    savePlayerData(self.config, self.player)
    self:prepareBarInfo()
    self:adjustWindowSize()
    self.reopenMenuNextFrame = true
end

function SSBar:drawTempBar(percent, i)
    -- horizontal bar, maybe there is an vertical one
    local gradientTex = getTexture("media/ui/BodyInsulation/heatbar_horz")
    local highlightTex = getTexture("media/ui/BodyInsulation/gradient_highlight")
    local radius = 20
    local darkAlpha = 0.6

    local barw = self.config.barWidth
    local barl = self.barLength
    local y = (barw + 3) * i - barw

    -- draw heatbar
    self:drawTextureScaled(gradientTex, 3, y, barl, barw, 1.0, 1.0, 1.0, 1.0)

    -- draw stat
    local valOffset = percent * barl
    valOffset = round(PZMath.clampFloat(valOffset, radius, barl - radius))
    if valOffset > radius then
        ---@diagnostic disable-next-line: param-type-mismatch
        self:drawTextureScaled(nil, 3, y, valOffset - radius, barw, darkAlpha, 0.0, 0.0, 0.0)
    end
    if valOffset < barl - radius then
        ---@diagnostic disable-next-line: param-type-mismatch
        self:drawTextureScaled(nil, 3 + valOffset + radius, y, barl - valOffset - radius, barw, darkAlpha, 0.0, 0.0, 0.0)
    end
    local highlightTexX = round(PZMath.clampFloat(valOffset - radius + 3, 3, 3 + barl - radius * 2))
    self:drawTextureScaled(highlightTex, highlightTexX, y, 2 * radius, barw, darkAlpha, 0.0, 0.0, 0.0)
end

function SSBar:getHoverBar(barWidth)
    local x = getMouseX()
    local y = getMouseY()
    local bar = {
        x = self.x,
        y = self.y,
        w = self.width,
        h = self.height,
    }
    if x <= bar.x or y <= bar.y or x >= bar.x + bar.w or y >= bar.y + bar.h then return nil end
    x = toInt(x - bar.x)
    y = toInt(y - bar.y)

    local xp = 0
    local index = 1
    while xp < bar.w do
        xp = xp + 3
        if x >= xp and x <= xp + barWidth then
            return index, x, y
        end
        index = index + 1
        xp = xp + barWidth
    end
    return nil
end

function SSBar:renderHBars()
    local barInfo = self.barInfo
    -- title, valueText, color, percent, _type, name, ruler

    for i, v in ipairs(barInfo) do
        local title = v[1]
        local valueText = v[2]
        local c = v[3]
        local percent = v[4]
        local _type = v[5]
        local ruler = v[7]

        local rectw = round(percent * self.barLength)
        local y = (self.config.barWidth + 3) * i - self.config.barWidth
        local textX = self.barLength - getStrWidth(self.font, valueText) - 6

        if _type == "temp" then
            self:drawTempBar(percent, i)
        else
            self:drawRectStatic(3, y, rectw, self.config.barWidth, 0.66, c.r, c.g, c.b)
            if ruler and self.config.isRulerOn then
                if i ~= 1 then
                    self:drawRectStatic(3, y - 2, self.barLength, 1, 0.66, 1.0, 1.0, 1.0)
                    self:drawRectStatic(3, y - 1, self.barLength, 1, 0.66, 0.0, 0.0, 0.0)
                end
                for _, r in ipairs(ruler) do
                    self:drawRuler(3, y, r / 100.0)
                end
            end
        end
        self:drawTextWithShadow(title, 6, y)
        self:drawTextWithShadow(valueText, textX, y)
    end
end

function SSBar:renderVBars()
    local barInfo = self.barInfo
    -- title, valueText, color, percent, _type, name

    for i, v in ipairs(barInfo) do
        local c = v[3]
        local percent = v[4]
        local _type = v[5]
        local name = v[6]
        local ruler = v[7]

        if _type == "temp" then percent = 1 end

        local x = (self.config.barWidth + 3) * i - self.config.barWidth
        local recth = round(percent * self.barLength)

        -- icon/name never change during a session; resolve the texture once and cache it
        -- back onto the shared stat table instead of doing a string-concat + lookup every frame.
        local bar = stats[name]
        local tex = bar._tex
        if not tex then
            if bar.icon then tex = getTexture(bar.icon) end
            if not tex then tex = getTexture("media/ui/ss-" .. name .. ".png") end
            if not tex then tex = getTexture("media/ui/ss-unknow.png") end
            bar._tex = tex
        end
        self:drawTextureScaled(tex, x, self.barLength + 6, self.config.barWidth, self.config.barWidth, 1.0, 1.0, 1.0, 1.0)

        self:drawRectStatic(x, self.barLength - recth + 3, self.config.barWidth, recth, 0.66, c.r, c.g, c.b)
        if ruler and self.config.isRulerOn then
            if i ~= 1 then
                self:drawRectStatic(x - 1, 3, 1, self.barLength, 0.66, 0.0, 0.0, 0.0)
                self:drawRectStatic(x - 2, 3, 1, self.barLength, 0.66, 1.0, 1.0, 1.0)
            end
            for _, r in ipairs(ruler) do
                self:drawRuler(x, 3, r / 100.0)
            end
        end
    end

    -- show tooltip
    local index, tooltipx, tooltipy = self:getHoverBar(self.config.barWidth)
    if index and tooltipx and tooltipy then
        local bar = barInfo[index]

        local title = bar[1]
        local valueText = bar[2]

        local tooltip = title .. " : " .. valueText

        if tooltip ~= "" then
            self:drawTextWithShadow(tooltip, tooltipx - 5, tooltipy - self.config.barWidth - 5)
        end
    end
end

function SSBar:prerender()
    ISPanel.prerender(self)
    self.timer = self.timer + 1
    -- Most stats (hunger, thirst, weight...) don't change fast enough to justify
    -- recomputing them at full framerate; refresh every 10 frames instead of every one.
    -- Direct calls from option handlers (optClick, optClickToggle, ...) still refresh
    -- immediately since they call prepareBarInfo() themselves.
    if self.timer % 10 == 0 then
        self:prepareBarInfo()
    end
    if self.timer == 60 then
        self.timer = 0
        self:adjustWindowSize()
    end
    -- reopen settings menu deferred (after current menu has finished closing)
    if self.reopenMenuNextFrame then
        self.reopenMenuNextFrame = false
        self:openSettingsMenu()
    end
    if self.config.isVertical then
        self:renderVBars()
    else
        self:renderHBars()
    end
end

function SSBar:onMouseUp(x, y)
    if self.config.locked then return end
    ISPanel.onMouseUp(self, x, y)
    self.config.pos = { self.x, self.y }
    savePlayerData(self.config, self.player)
end

function SSBar:openSettingsMenu()
    if not (self.player or {}).getPlayerNum then return end

    local contextMenu = ISContextMenu.get(self.player:getPlayerNum(), self.lastMenuX, self.lastMenuY)
    local configOpts = contextMenu:addOption("[ " .. getOptName("OPTION") .. " ]", self, nil)
    local configContectMenu = ISContextMenu:getNew(contextMenu)
    contextMenu:addSubMenu(configOpts, configContectMenu)

    local isv = configContectMenu:addOption(getOptName("VERTICAL"), self, self.optClickVertical)
    isv.checkMark = self.config.isVertical
    local ruler_on = configContectMenu:addOption(getOptName("RULER"), self, self.optClickRuler)
    ruler_on.checkMark = self.config.isRulerOn

    local fontSizeOpt = configContectMenu:addOption(getOptName("FONTSIZE"), self, nil)
    local fontSizeMenu = ISContextMenu:getNew(configContectMenu)
    configContectMenu:addSubMenu(fontSizeOpt, fontSizeMenu)
    for _, size in ipairs({ "Small", "Medium", "Large" }) do
        local opt = fontSizeMenu:addOption(getOptName("FONTSIZE_" .. to_upper(size)), self, self.optClickFontSize, size)
        opt.checkMark = (self.config.fontSize == size)
    end

    for _, name in ipairs(stats._reverse._values) do
        local opt = configContectMenu:addOption(getOptName("TOG_" .. to_upper(name)), self, self.optClickToggle, name)
        opt.checkMark = self.config.toggleStats[name]
    end

    for _, name in ipairs(stats._values) do
        if not stats._reverse[name] then
            local n = name
            if self.config.toggleStats[getReverseStat(name)] then
                n = getReverseStat(name)
            end
            local o = contextMenu:addOption(stats[n].title or getBarTitile(to_upper(n)), self, self.optClick, n)
            o.checkMark = self.config.shownConfig[n]
        end
    end
end

function SSBar:onRightMouseUp(x, y)
    if self.config.locked then return end
    ISPanel.onRightMouseUp(self, x, y)
    if not (self.player or {}).getPlayerNum then return end

    self.lastMenuX = getMouseX() + 5
    self.lastMenuY = getMouseY() + 5
    self:openSettingsMenu()
end

function SSBar:handleKey(key)
    if key == ssOptions.toggleKey:getValue() then
        self.shown = not self.shown
        if self.shown then
            self:setVisible(true)
            self:addToUIManager()
        else
            self:setVisible(false)
            self:removeFromUIManager()
        end
    elseif key == ssOptions.lockedKey:getValue() then
        self.config.locked = not self.config.locked
        self.moveWithMouse = not self.config.locked
        savePlayerData(self.config, self.player)
    end
end

---@param player IsoPlayer
---@param config table
---@return SSBar
function SSBar:new(player, config)
    local o = ISPanel:new(config.pos[1], config.pos[2], 0, 0)

    setmetatable(o, self)
    self.__index      = self

    o.moveWithMouse   = not config.locked
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.3 };


    o.player              = player
    o.playerNum           = player:getPlayerNum()

    o.config              = config
    o.font                = utils.font[config.fontSize] or utils.font.Small

    o.barInfo             = {}

    o.titleLength         = 0
    o.textLength          = 0
    o.barLength           = 0

    o.timer               = 0
    o.shown               = true
    o.reopenMenuNextFrame = false
    o.lastMenuX           = 0
    o.lastMenuY           = 0
    return o
end

function SSBar:initialise()
    ISPanel.initialise(self)
    self:prepareBarInfo()
    self:adjustWindowSize()
end

return SSBar
