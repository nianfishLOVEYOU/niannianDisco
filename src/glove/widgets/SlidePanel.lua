-- slider

local widget = require "src.glove.widgets.widget"

local g = love.graphics
local SlidePanel = widget:extend()
function SlidePanel:init(content)
    self.type = "SlidePanel"

    self.progressX = 0
    self.progressY = 0

    self.color = { 0, 0, 0, 0.5 }

    self.w = 60
    self.h = 100

    self.spacingX = 10
    self.spacingY = 10

    self.dx, self.dy = 0, 0
    --锁定移动
    self.lockOffsetX = true
    self.lockOffsetY = false

    self.t = 0
    self.dt = 0
    self.viscous = 0.2
    if not self.shadePanel then
        self.shadePanel = Glove.ShadePanel:new( )
        self.shadePanel:setPos(self.x, self.y)
        self.shadePanel:setSize(self.w, self.h)
    end
    self:setContent(content, self.spacingX, self.spacingY)


    --设置点击遮罩
end


function SlidePanel:addChild(child)
    self.shadePanel:addContent(child)
    widget.addChild(self, child)
end

function SlidePanel:removeChild(child)
    self.shadePanel:removeContent(child)
    widget.removeChild(self, child)
end


function SlidePanel:setPos(x, y)
    widget.setPos(self, x, y)
    if self.shadePanel then
        self.shadePanel:setPos(x, y)
    end
end

function SlidePanel:setSize(w, h)
    widget.setSize(self, w, h)
    if self.shadePanel then
        self.shadePanel:setSize(w, h)
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


    local content = self:getContent()
    if not content then return end

    if not self.isDrag then
        self:backToCenter()
    end

    self.shadePanel:draw()
end

-- 简化的 Glove 事件接口：点击、拖拽、释放、悬停
function SlidePanel:onClick(x, y)
    -- x,y 为全局坐标
    -- 只有在可视裁剪区内才处理
    if not self:isOver(x, y) then return end
    -- 记录按下用于后续 drag/over
    self._pressed = true
    local content = self:getContent()
    if content and content.onClick then
        local cx, cy = content:getPos()
        content:onClick(x - cx, y - cy)
    end
end

function SlidePanel:onDrag(x, y, dx, dy)
    if not self._pressed then return end
    -- 仍需保证拖拽点在可视区域内
    if not self:isOver(x, y) then return end
    -- 使用已有的滑动逻辑（传入 dx,dy 即可）
    local content = self:getContent()
    if not content then return end
    -- forward to content if it handles drag
    -- if content.onDrag then
    --     local cx, cy = content:getPos()
    --     content:onDrag(x - cx, y - cy, dx, dy)
    -- else
    self:onDragInternal(dx, dy)
    -- end
    --print("SlidePanel",dx,dy)
end

-- internal helper to reuse existing onDrag code
function SlidePanel:onDragInternal(dx, dy)
    local content = self:getContent()
    if not content then return end
    local cx, cy = content:getLocalPos()
    local cw, ch = content:getSize()
    if self.lockOffsetX then
        dx = 0
    else
        if cx > 0 + self.spacingX and dx > 0 then dx = 0 end
        if cx + cw < self.w - self.spacingX and dx < 0 then dx = 0 end
    end
    if self.lockOffsetY then
        dy = 0
    else
        if cy > 0 + self.spacingY and dy > 0 then dy = 0 end
        if cy + ch < self.h - self.spacingY and dy < 0 then dy = 0 end
    end
    content:setLocalPos(cx + dx, cy + dy)

    --print("SlidePanel", dx, dy)
    local xspace, yspace = self:getSlideSpace()
    self.progressX = content.localX / (xspace == 0 and 1 or xspace)
    self.progressY = content.localY / (yspace == 0 and 1 or yspace)
end

function SlidePanel:onDragOver(x, y)
    if not self._pressed then return end
    self._pressed = false
    self:dragProgress(x)
    self.t = 0
    self.dt = 0
    local content = self:getContent()
    if content and content.onDragOver then
        local gx, gy = content:getPos()
        content:onDragOver(x - gx, y - gy)
    end
end

function SlidePanel:onClickOver(x, y)
    self._pressed = false
    local content = self:getContent()
    if content and content.onClickOver then
        local cx, cy = content:getPos()
        content:onClickOver(x - cx, y - cy)
    end
end

function SlidePanel:onHold(x, y)
    -- hover 不做处理，但也应该在可视区域内才触发 child 的 onHold
    if not self:isOver(x, y) then return end
    local content = self:getContent()
    if not content then return end
    -- 转换为 content 本地坐标并调用其 onHold（若存在）
    local lx, ly = x - self.x, y - self.y
    if content.onHold then content:onHold(lx, ly) end
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

--被拖拽
-- function SlidePanel:onDrag(x, y, dx, dy)
--     if not self._pressed then return end
--     if not self:hitTest(x, y) then return end
--     local content = self:getContent()
--     if not content then return end
--     local cx, cy = content:getLocalPos()
--     local cw, ch = content:getSize()
--     --保持content的拖拽对边边界在panel中
--     if self.lockOffsetX then
--         dx = 0
--     else
--         if cx > 0 + self.spacingX and dx > 0 then dx = 0 end --child左边角超过了panel就不许更加右移动了
--         if cx + cw < self.w - self.spacingX and dx < 0 then dx = 0 end
--     end
--     if self.lockOffsetY then
--         dy = 0
--     else
--         if cy > 0 + self.spacingY and dy > 0 then dy = 0 end
--         if cy + ch < self.h - self.spacingY and dy < 0 then dy = 0 end
--     end

--     -- forward to content if it has handler
--     if content.onDrag then
--         local gx, gy = content:getPos()
--         content:onDrag(x - gx, y - gy, dx, dy)
--     else
--         content:setLocalPos(cx + dx, cy + dy)
--     end

--     --拖拽事件
--     local xspace, yspace = self:getSlideSpace()
--     if xspace == 0 then
--         self.progressX = 0
--     else
--         self.progressX = content.localX / xspace
--     end
--     if yspace == 0 then
--         self.progressY = 0
--     else
--         self.progressY = content.localY / yspace
--     end

--     self.t = self.t == 0 and love.timer.getTime() or self.t  --如果t为零先初始化
--     self.dt = love.timer.getTime() - self.t
--     self.t = love.timer.getTime()
--     if self.dt ~= 0 then
--         self.dx = dx / self.dt
--         self.dy = dy / self.dt --获得单位时间速度
--     end

--     self:dragProgress(self.progressX, self.progressY)
-- end

function SlidePanel:backToCenter()
    local dx, dy = 0, 0
    local content = self:getContent()
    if not content then return end
    local cx, cy = content:getLocalPos()
    local cw, ch = content:getSize()
    local backPower = 10
    --保持content的拖拽对边边界在panel中

    --x轴的边界回归
    if cx > (0 + self.spacingX) then dx = dx - backPower end --child左边角超过了panel就不许更加右移动了
    if (cx + cw) < (self.w - self.spacingX) then dx = dx + backPower end
    --y轴的边界回归
    if cy > (0 + self.spacingY) then dy = dy - backPower end
    if (cy + ch) < (self.h - self.spacingY) then dy = dy + backPower end

    --脱离指控后速度保持
    if self.dx ~= 0 then
        dx = dx + self.dx
        self.dx = self.dx * self.viscous
    end
    if self.dy ~= 0 then
        dy = dy + self.dy
        self.dy = self.dy * self.viscous
    end
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
