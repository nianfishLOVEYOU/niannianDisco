-- slider

local image = require "src.common.aUIImage"
local widget = require "src.glove.widgets.widget"

local g = love.graphics
local SlidePanel = widget:extend()
local padding = 3

function SlidePanel:init(content)
    self.type = "SlidePanel"

    self.progressX = 0
    self.progressY = 0

    self.color = { 0, 0, 0, 0.5 }

    self.w = 60
    self.h = 100

    self.spacingX = 10
    self.spacingY = 10

    --锁定移动
    self.lockOffsetX = true
    self.lockOffsetY = false

    if content then
        self:setContent(content, self.spacingX, self.spacingY)
    end
end

--设置滑页内的内容
function SlidePanel:setContent(child, x, y)
    self:clearChild()
    self:addChild(child)
    x = x or 0
    y = y or 0
    child:setLocalPos(x, y)
end

function SlidePanel:getContent()
    if #self.children == 1 then
        return self.children[1]
    end
    return nil
end

function SlidePanel:draw()
    -- 进度条

    g.setColor(self.color)
    g.rectangle("fill", self.x, self.y, self.w, self.h)
    local cx, cy = self:getContent():getLocalPos()
    local content = self:getContent()
    if not content then return end

    if not self.isDrag then
        self:backToCenter()
    end
    content:draw()
end

--可滑动空间
function SlidePanel:getSlideSpace()
    local content = self:getContent()
    if content then
        local xspace, yspace = self.w - content.w, self.h - content.h
        xspace = xspace < 0 and 0 or xspace
        yspace = yspace < 0 and 0 or yspace
        return xspace, yspace
    end
    return 0, 0
end

function SlidePanel:onDragOver(x, y)
    self:dragProgress(x)
end

--被拖拽
function SlidePanel:onDrag(x, y, dx, dy)
    local content = self:getContent()
    if not content then return end
    local cx, cy = content:getLocalPos()
    local cw, ch = content:getSize()
    --保持content的拖拽对边边界在panel中
    if self.lockOffsetX then
        dx = 0
    else
        if cx > 0 + self.spacingX and dx > 0 then dx = 0 end --child左边角超过了panel就不许更加右移动了
        if cx + cw < self.w - self.spacingX and dx < 0 then dx = 0 end
    end
    if self.lockOffsetY then
        dy = 0
    else
        if cy > 0 + self.spacingY and dy > 0 then dy = 0 end
        if cy + ch < self.h - self.spacingY and dy < 0 then dy = 0 end
    end

    content:setLocalPos(cx + dx, cy + dy)

    --拖拽事件
    local xspace, yspace = self:getSlideSpace()
    self.progressX = content.localX / xspace
    self.progressY = content.localY / yspace

    self:dragProgress(self.progressX, self.progressY)
end

function SlidePanel:backToCenter()
    local dx, dy = 0, 0
    local content = self:getContent()
    if not content then return end
    local cx, cy = content:getLocalPos()
    local cw, ch = content:getSize()
    local backPower =10
    --保持content的拖拽对边边界在panel中

    --x轴的边界回归
    if cx > (0 + self.spacingX) then dx = dx - backPower end --child左边角超过了panel就不许更加右移动了
    if (cx + cw) < (self.w - self.spacingX) then dx = dx + backPower end
    --y轴的边界回归
    if cy > (0 + self.spacingY) then dy = dy - backPower end
    if (cy + ch) < (self.h - self.spacingY) then dy = dy + backPower end

    content:setLocalPos(cx + dx, cy + dy)
end

--设置滑页进度x
function SlidePanel:setProgressX(p)
    if self.lockOffsetX then return end
    local content = self:getContent()
    if content then
        local xspace, yspace = self:getSlideSpace()
        content:setLocalPos(p * xspace, content.localY)
        self.progressX = p
        self:dragProgress(self.progressX, self.progressY)
    end
end

--设置滑页进度y
function SlidePanel:setProgressY(p)
    if self.lockOffsetY then return end
    local content = self:getContent()
    if content then
        local xspace, yspace = self:getSlideSpace()
        content:setLocalPos(content.localX, p * yspace)
        self.progressY = p
        self:dragProgress(self.progressX, self.progressY)
    end
end

function SlidePanel:dragProgress(progressX, progressY)
    --如果有拖拽条
end

return SlidePanel
