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

    self.dx, self.dy = 0, 0
    --锁定移动
    self.lockOffsetX = true
    self.lockOffsetY = false

    self.t = 0
    self.dt = 0
    self.viscous =0.2
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

    
    local scissorX = self.x
    local scissorY = self.y
    local scissorW = self.w
    local scissorH = self.h

    love.graphics.setScissor(scissorX, scissorY, scissorW, scissorH) -- 开启剪裁

    content:draw()

    love.graphics.setScissor() -- 关闭剪裁
end

-- 判断某点是否在可接收点击的可视区域内（即标题/面板可视内容区域）
function SlidePanel:hitTest(mouseX, mouseY)
    local px, py = self.x, self.y
    local pw, ph = self.w, self.h
    -- 必须在 panel 矩形内
    if not (px <= mouseX and mouseX <= px + pw and py <= mouseY and mouseY <= py + ph) then
        return false
    end

    local content = self:getContent()
    if not content then
        -- 没有内容，panel 本身可点击
        return true
    end

    -- 检查内容或其子项在该点是否可见且包含该点（递归）
    local function checkItem(item)
        if not item.visible then return false end
        local ix, iy = item:getPos()
        local iw, ih = item:getSize()
        if ix <= mouseX and mouseX <= ix + iw and iy <= mouseY and mouseY <= iy + ih then
            return true
        end
        if item.children and #item.children > 0 then
            for _, ch in ipairs(item.children) do
                if checkItem(ch) then return true end
            end
        end
        return false
    end

    -- 只有当内容或其子项在 panel 的可视区域内包含该点时才认为命中
    if checkItem(content) then
        return true
    end
    return false
end

-- 简化的 Glove 事件接口：点击、拖拽、释放、悬停
function SlidePanel:onClick(x, y)
    -- x,y 为全局坐标
    -- 只有在可视裁剪区内才处理
    if not self:hitTest(x, y) then return end
    -- 记录按下用于后续 drag/over
    self._pressed = true
    local content = self:getContent()
    if content and content.onClick then
        local cx, cy = content:getPos()
        content:onClick(x - cx, y - cy)
    end
    return
end

function SlidePanel:onDrag(x, y, dx, dy)
    if not self._pressed then return end
    -- 仍需保证拖拽点在可视区域内
    if not self:hitTest(x, y) then return end
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
    print("SlidePanel",dx,dy)
end

-- internal helper to reuse existing onDrag code
function SlidePanel:onDragInternal(dx, dy)
    local content = self:getContent()
    if not content then return end
    local cx, cy = content:getLocalPos()
    local cw, ch = content:getSize()
    if self.lockOffsetX then dx = 0 else
        if cx > 0 + self.spacingX and dx > 0 then dx = 0 end
        if cx + cw < self.w - self.spacingX and dx < 0 then dx = 0 end
    end
    if self.lockOffsetY then dy = 0 else
        if cy > 0 + self.spacingY and dy > 0 then dy = 0 end
        if cy + ch < self.h - self.spacingY and dy < 0 then dy = 0 end
    end
    content:setLocalPos(cx + dx, cy + dy)
    
    print("SlidePanel",dx,dy)
    local xspace, yspace = self:getSlideSpace()
    self.progressX = content.localX / (xspace == 0 and 1 or xspace)
    self.progressY = content.localY / (yspace == 0 and 1 or yspace)
end

function SlidePanel:onDragOver(x, y)
    if not self._pressed then return end
    self._pressed = false
    -- 触发回弹逻辑
    self.t = 0
    self.dt = 0
    local content = self:getContent()
    if content and content.onDragOver then
        local cx, cy = content:getPos()
        content:onDragOver(x - cx, y - cy)
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
    if not self:hitTest(x, y) then return end
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
        self.dx=self.dx*self.viscous
    end
    if self.dy ~= 0 then
        dy = dy + self.dy
        self.dy=self.dy*self.viscous
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
