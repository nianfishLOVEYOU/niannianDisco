------------------------------------------------------------------------
-- 长按右下角唤起的扇形选择栏
------------------------------------------------------------------------
local ui = require "src.ui.ui"
local imageItem = require "src.item.imageItem"

local WheelSelectionUI = ui:extend()

local DEFAULT_ICON = "res/image/nian.png"
local DEFAULT_OPTIONS = {{
    label = "本地音乐",
    imagePath = "res/image/ui/add.png",
    action = function()
        local playlistUI = uiManager:getUI("playlistUI")
        playlistUI:open("localplaylist")
    end
}, {
    label = "目前歌单",
    imagePath = "res/image/ui/listbutton.png",
    action = function()
        local playlistUI = uiManager:getUI("playlistUI")
        playlistUI:open("playlist")
    end
}, {
    label = "角色",
    imagePath = "res/image/player1.png",
    action = function()
        -- if not uiManager:getUI("playerSelectUI") then
        --     uiManager:addUI("playerSelectUI", require("src.ui.playerSelectUI"):new())
        -- end
    end
}}

local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

local function lerpNumber(a, b, t)
    return a + (b - a) * t
end

local function easeOutBack(t)
    local c1 = 1.70158
    local c3 = c1 + 1
    return 1 + c3 * (t - 1) * (t - 1) * (t - 1) + c1 * (t - 1) * (t - 1)
end

local function safeCreateIcon(path)
    local iconPath = path or DEFAULT_ICON
    local ok, icon = pcall(function()
        return imageItem:new(iconPath)
    end)
    if ok then
        return icon
    end
    return imageItem:new(DEFAULT_ICON)
end

function WheelSelectionUI:init(options)

    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    -- WheelSelectionUI.super.init(self)
    self.type = "wheelSelectionUI"
    self.z = 9999
    self.triggerMargin = 8
    self.longPressDuration = 0.26 -- 点击超过这个时间才会触发长按
    self.cancelMoveDistance = 28
    self.openx = screenW - 100
    self.openy = screenH - 250
    self.fanRadius = 160 -- 圆心距离
    self.ballRadius = 34
    self.ballInterval = 30
    self.iconSize = 42
    self.psdindent=30 --点击范围缩入
    self.attractRadius = 100 -- 移动影响距离
    self.selectRadius = 48 -- 选择半径
    self.attractStrength = 20 -- 移动强度
    self.connectorAlpha = 0.38
    self.labelOffsetX = 10
    self.labelOffsetY = 10
    self.originPulse = 0
    self.pressing = false
    self.isOpen = false
    self.pressElapsed = 0 -- 按下计时器
    self.pointerX = 0
    self.pointerY = 0
    self.pressX = 0
    self.pressY = 0
    self.originX = 0 -- 手指点绘制位置
    self.originY = 0
    self.hoveredBall = nil
    self.options = {}
    self.balls = {}
    self.angles = {}

    self:setOptions(options or DEFAULT_OPTIONS)
end

function WheelSelectionUI:setOptions(options)
    self.options = {}
    for i = 1, #options do
        self.options[i] = options[i]
        self.angles[i] = math.rad(270 - i * self.ballInterval)
    end
    -- while #self.options < 3 do
    --     table.insert(self.options, DEFAULT_OPTIONS[#self.options + 1])
    -- end
    self:rebuildBalls()
end

function WheelSelectionUI:rebuildBalls()
    for _, ball in ipairs(self.balls) do
        if ball.icon then
            self:removeChild(ball.icon)
            ball.icon:destroy()
        end
    end
    self.balls = {}

    for index, option in ipairs(self.options) do
        local ball = {
            index = index,
            option = option,
            radius = self.ballRadius,
            drawX = 0,
            drawY = 0,
            targetX = 0,
            targetY = 0,
            baseX = 0,
            baseY = 0,
            attractX = 0,
            attractY = 0,
            spawnScale = 0.18,
            highlight = 0
        }
        ball.icon = safeCreateIcon(option.imagePath)
        ball.icon:setAnchor(0.5, 0.5)
        ball.icon:setSize(self.iconSize, self.iconSize)
        self:addChild(ball.icon)
        table.insert(self.balls, ball)
    end
end

function WheelSelectionUI:isInTriggerArea(x, y)
    local nianocUI = uiManager:getUI("nianocUI")
    if nianocUI then
        local nianocX, nianocY = nianocUI.psdData.x+self.psdindent, nianocUI.psdData.y
        local nianocW, nianocH = nianocUI.psdData.w-self.psdindent, nianocUI.psdData.h
        return x >= nianocX and x <= nianocX + nianocW and y >= nianocY and y <= nianocY + nianocH
    end
    return false
end

function WheelSelectionUI:beginPress(x, y)
    if not self:isInTriggerArea(x, y) then
        return
    end
    self.pressing = true
    self.isOpen = false
    self.pressElapsed = 0
    self.pressX = x
    self.pressY = y
    self.pointerX = x
    self.pointerY = y
    self.hoveredBall = nil
end

function WheelSelectionUI:openWheel(x, y)
    self.isOpen = true
    self.originPulse = 0

    for index, ball in ipairs(self.balls) do
        local angle = self.angles[index] or math.rad(225)
        local distance = self.fanRadius
        if index == 2 then
            distance = self.fanRadius + 8
        end
        ball.baseX = x + math.cos(angle) * distance
        ball.baseY = y + math.sin(angle) * distance
        ball.drawX = x
        ball.drawY = y
        ball.targetX = ball.baseX
        ball.targetY = ball.baseY
        ball.attractX = 0
        ball.attractY = 0
        ball.highlight = 0
        ball.spawnScale = 0.18

        animation:addAnimation(ball, {
            drawX = ball.baseX,
            drawY = ball.baseY,
            spawnScale = 1
        }, 0.18 + index * 0.03, {
            easing = easeOutBack
        })
    end
end

function WheelSelectionUI:closeWheel()
    self.pressing = false
    self.isOpen = false
    self.pressElapsed = 0
    self.hoveredBall = nil
    for _, ball in ipairs(self.balls) do
        ball.attractX = 0
        ball.attractY = 0
        ball.highlight = 0
        ball.spawnScale = 0.18
        ball.drawX = self.originX
        ball.drawY = self.originY
    end
end

function WheelSelectionUI:getHoveredBall(x, y)
    local hoveredBall = nil
    local bestDistance = self.selectRadius
    for _, ball in ipairs(self.balls) do
        local dx = x - ball.drawX
        local dy = y - ball.drawY
        local distance = math.sqrt(dx * dx + dy * dy)
        if distance <= bestDistance then
            bestDistance = distance
            hoveredBall = ball
        end
    end
    return hoveredBall
end

function WheelSelectionUI:updateBallAttraction(dt)
    self.hoveredBall = self:getHoveredBall(self.pointerX, self.pointerY)
    for _, ball in ipairs(self.balls) do
        local dx = self.pointerX - ball.baseX
        local dy = self.pointerY - ball.baseY
        local distance = math.sqrt(dx * dx + dy * dy)
        local attractX = 0
        local attractY = 0
        if distance > 0 and distance < self.attractRadius then
            local strength = (1 - distance / self.attractRadius) * self.attractStrength
            attractX = dx / distance * strength
            attractY = dy / distance * strength
        end
        ball.attractX = lerpNumber(ball.attractX, attractX, clamp(dt * 12, 0, 1))
        ball.attractY = lerpNumber(ball.attractY, attractY, clamp(dt * 12, 0, 1))
        ball.highlight = lerpNumber(ball.highlight, ball == self.hoveredBall and 1 or 0, clamp(dt * 12, 0, 1))
        ball.drawX = ball.baseX + ball.attractX
        ball.drawY = ball.baseY + ball.attractY
        ball.icon:setPos(ball.drawX, ball.drawY)
        local iconSize = self.iconSize * (0.92 + ball.highlight * 0.12) * ball.spawnScale
        ball.icon:setSize(iconSize, iconSize)
    end
end

function WheelSelectionUI:invokeOption(ball)
    if not ball or not ball.option then
        return
    end
    local option = ball.option
    if type(option.action) == "function" then
        option.action(self, option, ball)
        return
    end
    if option.uiName and type(option.uiFactory) == "function" then
        if option.toggle and uiManager:getUI(option.uiName) then
            uiManager:removeUI(option.uiName)
            return
        end
        if not uiManager:getUI(option.uiName) then
            uiManager:addUI(option.uiName, option.uiFactory())
        end
    end
end

function WheelSelectionUI:update(dt)
    if self.pressing and not self.isOpen then
        self.pressElapsed = self.pressElapsed + dt
        local moveDx = self.pointerX - self.pressX
        local moveDy = self.pointerY - self.pressY
        if moveDx * moveDx + moveDy * moveDy > self.cancelMoveDistance * self.cancelMoveDistance then
            self.pressing = false
            self.pressElapsed = 0
        elseif self.pressElapsed >= self.longPressDuration then -- 触发点击事件
            self:openWheel(self.openx, self.openy)

            self.originX = self.pressX
            self.originY = self.pressY
        end
    end

    if self.isOpen then
        self.originPulse = self.originPulse + dt * 4
        self:updateBallAttraction(dt)
    end
end

function WheelSelectionUI:drawTriggerArea()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    local nianocUI = uiManager:getUI("nianocUI")
    if nianocUI then
        local nianocX, nianocY = nianocUI.psdData.x+self.psdindent, nianocUI.psdData.y
        local nianocW, nianocH = nianocUI.psdData.w-self.psdindent, nianocUI.psdData.h
        love.graphics.setColor(1, 0, 0, 0.5)
        love.graphics.rectangle("line", nianocX, nianocY, nianocW, nianocH)
        if drawOutlinedText then
            drawOutlinedText("长按", nianocX + 50, nianocY + 80, 60, {1, 1, 1, 0.7}, {0, 0, 0, 0.7})
        end
    end

end

function WheelSelectionUI:drawBall(ball)
    local pulse = 1 + math.sin(self.originPulse * 3 + ball.index * 0.8) * 0.03
    local radius = ball.radius * (0.92 + ball.highlight * 0.12) * ball.spawnScale * pulse

    love.graphics.setColor(0, 0, 0, 0.24 * ball.spawnScale)
    love.graphics.circle("fill", ball.drawX + 4, ball.drawY + 6, radius)

    love.graphics.setColor(1, 1, 1, self.connectorAlpha * ball.spawnScale)
    love.graphics.setLineWidth(2)
    love.graphics.line(self.originX, self.originY, ball.drawX, ball.drawY)

    love.graphics.setColor(0.12, 0.13, 0.18, 0.95)
    love.graphics.circle("fill", ball.drawX, ball.drawY, radius)

    love.graphics.setColor(0.82 + ball.highlight * 0.18, 0.93, 1, 1)
    love.graphics.setLineWidth(2 + ball.highlight)
    love.graphics.circle("line", ball.drawX, ball.drawY, radius)

    ball.icon:draw()

    if ball.option.label and drawOutlinedText then
        local w= myFont:getWidth(ball.option.label)
        drawOutlinedText(ball.option.label, ball.drawX -w/2, ball.drawY - self.labelOffsetY, 100,
            {1, 1, 1, 0.95}, {0, 0, 0, 0.95})
    elseif ball.option.label then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(ball.option.label, ball.drawX - self.labelOffsetX, ball.drawY - self.labelOffsetY, 100,
            "center")
    end
end

-- 绘制玩家点击位置
function WheelSelectionUI:drawOrigin()
    local pulseRadius = 14 + math.sin(self.originPulse * 2) * 2
    love.graphics.setColor(1, 1, 1, 0.12)
    love.graphics.circle("fill", self.originX, self.originY, pulseRadius + 10)
    love.graphics.setColor(0.2, 0.23, 0.28, 0.92)
    love.graphics.circle("fill", self.originX, self.originY, pulseRadius)
    love.graphics.setColor(0.95, 0.98, 1, 0.86)
    love.graphics.circle("line", self.originX, self.originY, pulseRadius + 2)
end

function WheelSelectionUI:nianChange()

end

function WheelSelectionUI:draw()
    self:drawTriggerArea()
    if not self.isOpen then
        return
    end

    self:drawOrigin()
    for _, ball in ipairs(self.balls) do
        self:drawBall(ball)
    end
end

function WheelSelectionUI:onClick(x, y, button)
    if button ~= 1 then
        return
    end
    self:beginPress(x, y)
    if nianocUI and self:isInTriggerArea(x, y) then
        self.isNianClick = true
        nianocUI:getPress()
    end
end

function WheelSelectionUI:mouseMoved(x, y, dx, dy)
    if not self.pressing and not self.isOpen then
        return
    end
    self.pointerX = x
    self.pointerY = y

    if self.isOpen then
        self.originX = x
        self.originY = y
    end
end

function WheelSelectionUI:onClickOver(x, y, button)
    if button ~= 1 then
        return
    end
    if self.isNianClick and nianocUI then
        self.isNianClick = false
        nianocUI:getleave()
    end

    self.pointerX = x
    self.pointerY = y
    local selectedBall = self.isOpen and self:getHoveredBall(x, y) or nil
    self:closeWheel()
    self:invokeOption(selectedBall)
end

function WheelSelectionUI:destroy()
    WheelSelectionUI.super.destroy(self)
end

return WheelSelectionUI
