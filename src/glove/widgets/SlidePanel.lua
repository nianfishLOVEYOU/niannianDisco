-- slider
local widget = require "src.glove.widgets.widget"

local g = love.graphics
local SlidePanel = widget:extend()

-- 可拖拽内容content，新内容的构造方法constructor(index),超出范围的index会被禁止构造然后几月资源给目前看得到的内容
-- length是内容的总长度，index范围是1-length
function SlidePanel:init(content)
    self.type = "SlidePanel"

    self.progressX = 0
    self.progressY = 0

    self.color = {1, 1, 1, 0.2}

    self.w = 60
    self.h = 100

    self.spacingX = 10
    self.spacingY = 10

    self.dx, self.dy = 0, 0
    -- 锁定移动
    self.lockOffsetX = true
    self.lockOffsetY = false

    -- 用来计算拖拽速度
    self.t = 0
    self.dt = 0
    self.viscous = 0.2

  self.padding = 10
    -- 滚动条配置
    self.scrollBarWidth = 10
    self.isDraggingScrollBar = false
    self.scrollBarColor = {1, 1, 1, 1}  -- 白色背景
    self.scrollThumbColor = {0, 0, 0, 1}  -- 黑色滚动块
    -- if not self.shadePanel then
    --     self.shadePanel = Glove.ShadePanel:new()
    --     self.shadePanel:setPos(self.x, self.y)
    --     self.shadePanel:setSize(self.w, self.h)
    -- end
    if content then
        self:setContent(content, self.spacingX, self.spacingY)
    else
        local vstack = Glove.VStack:new({}, 10)
        vstack:setName("playerlistui vstack")
        self:setContent(vstack, self.spacingX, self.spacingY)
    end

    -- 设置点击遮罩
end

function SlidePanel:refresh()
    self:clearChild()
    for i = 0, self.length do
        local content = self.toConstruct(i)
        if content then
            self:setContent(content, self.spacingX, self.spacingY)
            break
        end
    end
end

-- 一次性按照规则生成内容，适用于内容较多但一次只能看一个的情况,目的是在内容较多时节省资源而且动态加载内容，不会一次性显示所有
function SlidePanel:refreshByStruct(toConstruct, length)
    self:clearChild()
    self.toConstruct = toConstruct
    self.length = length
    for i = 0, self.length do

        local content = self.toConstruct(i)
        if content then
            self:setContent(content, self.spacingX, self.spacingY)
            break
        end
    end
end

-- 后期需要加入新的元素时
function SlidePanel:add(child)
    print("SlidePanel add child", child.type)
    self:getContent():addChild(child)
    self:getContent():layout()
end

function SlidePanel:remove(child)
    local content = self:getContent()
    if content then
        for i, c in ipairs(content) do
            if c == child then
                table.remove(content, i)
                break
            end
        end
        content:layout()
    end
end

-- 设置滑页内的内容
function SlidePanel:setContent(child, x, y)
    self:clearChild()
    self:addChild(child)
    x = x or 0
    y = y or 0
    child:setLocalPos(x, y)
end

-- 获取垂直排列的vstack
function SlidePanel:getContent()
    if #self.children == 1 then
        return self.children[1]
    end
    return nil
end

function SlidePanel:draw()
    -- 进度条

    g.setColor(self.color)
    g.rectangle("fill", self.x, self.y, self.w, self.h,self.padding,self.padding)
    g.setColor(0,0,0,0.5)
    g.rectangle("line", self.x, self.y, self.w, self.h,self.padding,self.padding)
    g.rectangle("line", self.x + self.padding, self.y + self.padding, self.w - 2 * self.padding, self.h - 2 * self.padding)
    local content = self:getContent()
    if not content then
        return
    end

    if not self.isDrag then
        -- self:backToCenter()
    end

    --  裁剪
    if not self.visible then
        return
    end
    --减去padding的裁剪，避免内容被完全遮挡无法拖动
    local sx, sy, sw, sh = g.getScissor()
    g.setScissor(self.x + self.padding, self.y + self.padding, self.w - 2 * self.padding - self.scrollBarWidth, self.h - 2 * self.padding)
    for _, entry in ipairs(self.children) do
        if entry.draw then
            entry:draw()
        end
    end
    g.setScissor(sx, sy, sw, sh)

    -- 绘制滚动条
    self:drawScrollBar()

    -- g.setColor(1, 1, 0)
    -- g.rectangle("line", self.x, self.y, self.w, self.h)

    -- self.shadePanel:draw()
end

-- 处理点击事件（包括滚动条点击） 暂时没有点击，都会穿透到内容上
function SlidePanel:onClick(x, y)
    -- 检测是否点击了滚动条
    if self:isOverScrollBar(x, y) then
        if self:isOverScrollThumb(x, y) then
            -- 点击了滚动块，开始拖拽
            self.isDraggingScrollBar = true
        else
            -- 点击了滚动条其他位置，直接导航
            self:dragScrollBar(y)
            self.isDraggingScrollBar = true
        end
    end
        print ("Clicked on scroll bar, dragging:", self.isDraggingScrollBar)
end

function SlidePanel:onDrag(x, y, dx, dy)
    -- 如果正在拖拽滚动条，更新进度
    if self.isDraggingScrollBar then
        self:dragScrollBar(y)
        return
    end
    
    -- 仍需保证拖拽点在可视区域内
    if not self:isOver(x, y) then
        return
    end
    -- 使用已有的滑动逻辑（传入 dx,dy 即可）
    local content = self:getContent()
    if not content then
        return
    end
    self:onDragInternal(dx, dy)
end

-- 拖拽滚动条时更新进度
function SlidePanel:dragScrollBar(y)
    local scrollBarY = self.y + self.padding
    local scrollBarHeight = self.h - 2 * self.padding
    
    local info = self:getScrollBarInfo()
    if not info or not info.canScroll then
        return
    end
    
    -- 计算滚动块在滚动条中的相对位置
    local relY = y - scrollBarY
    relY = math.max(0, math.min(relY, scrollBarHeight - info.thumbHeight))
    
    -- 更新 progressY
    local maxThumbY = scrollBarHeight - info.thumbHeight
    self.progressY = maxThumbY > 0 and (relY / maxThumbY) or 0
    self.progressY = math.max(0, math.min(1, self.progressY))
    
    -- 更新内容位置
    local content = self:getContent()
    if content then
        local xspace, yspace = self:getSlideSpace()
        local newY = -self.progressY * yspace
        local cx, cy = content:getLocalPos()
        content:setLocalPos(cx, newY)
    end
end
function SlidePanel:onDragInternal(dx, dy)
    local content = self:getContent()
    if not content then
        return
    end
    local cx, cy = content:getLocalPos()
    local cw, ch = content:getSize()
    if self.lockOffsetX then
        dx = 0
    else
        if cx > 0 + self.spacingX and dx > 0 then
            dx = 0
        end
        if cx + cw < self.w - self.spacingX and dx < 0 then
            dx = 0
        end
    end
    if self.lockOffsetY then
        dy = 0
    else
        if cy > 0 + self.spacingY and dy > 0 then
            dy = 0
        end
        if cy + ch < self.h - self.spacingY and dy < 0 then
            dy = 0
        end
    end
    content:setLocalPos(cx + dx, cy + dy)

    -- print("SlidePanel", dx, dy)
    local xspace, yspace = self:getSlideSpace()
    self.progressX = -content.localX / (xspace == 0 and 1 or xspace)
    self.progressY = -content.localY / (yspace == 0 and 1 or yspace)
    self.progressX = math.min(1, math.max(0, self.progressX))
    self.progressY = math.min(1, math.max(0, self.progressY))

    -- self.t = self.t == 0 and love.timer.getTime() or self.t     --如果t为零先初始化
    -- self.dt = love.timer.getTime() - self.t
    -- self.t = love.timer.getTime()
    -- if self.dt ~= 0 then
    --     self.dx = dx / self.dt
    --     self.dy = dy / self.dt --获得单位时间速度
    -- end
end

function SlidePanel:onDragOver(x, y)
    -- 结束滚动条拖拽
    if self.isDraggingScrollBar then
        self.isDraggingScrollBar = false
        return
    end
    
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
    local content = self:getContent()
    if content and content.onClickOver then
        local cx, cy = content:getPos()
        content:onClickOver(x - cx, y - cy)
    end
end

function SlidePanel:onHold(x, y)
    -- hover 不做处理，但也应该在可视区域内才触发 child 的 onHold
    if not self:isOver(x, y) then
        return
    end
    local content = self:getContent()
    if not content then
        return
    end
    -- 转换为 content 本地坐标并调用其 onHold（若存在）
    local lx, ly = x - self.x, y - self.y
    if content.onHold then
        content:onHold(lx, ly)
    end
end

-- 计算滚动条的尺寸和位置
function SlidePanel:getScrollBarInfo()
    local content = self:getContent()
    if not content then
        return nil
    end
    
    local contentHeight = content.h
    local panelHeight = self.h - 2 * self.padding
    
    -- 如果内容小于等于面板高度，不需要滚动条
    if contentHeight <= panelHeight then
        return {
            thumbHeight = panelHeight,
            thumbY = 0,
            canScroll = false
        }
    end
    
    -- 计算滚动块的高度（比例）
    local thumbHeight = panelHeight * (panelHeight / contentHeight)
    thumbHeight = math.max(thumbHeight, 20)  -- 最小高度为20像素
    
    -- 根据 progressY 计算滚动块的位置
    local maxThumbY = panelHeight - thumbHeight
    local thumbY = self.progressY * maxThumbY
    
    return {
        thumbHeight = thumbHeight,
        thumbY = thumbY,
        canScroll = true
    }
end

-- 绘制滚动条
function SlidePanel:drawScrollBar()
    local scrollBarX = self.x + self.w - self.scrollBarWidth
    local scrollBarY = self.y + self.padding
    local scrollBarHeight = self.h - 2 * self.padding
    
    -- 绘制滚动条背景（白色+黑色描边）
    g.setColor(self.scrollBarColor)
    g.rectangle("fill", scrollBarX, scrollBarY, self.scrollBarWidth, scrollBarHeight)
    g.setColor(0, 0, 0, 0.5)  -- 黑色描边
    g.setLineWidth(1)
    g.rectangle("line", scrollBarX, scrollBarY, self.scrollBarWidth, scrollBarHeight)
    
    -- 绘制滚动块（黑色长块）
    local info = self:getScrollBarInfo()
    if info and info.canScroll then
        g.setColor(self.scrollThumbColor)
        g.rectangle("fill", scrollBarX + 1, scrollBarY + info.thumbY, self.scrollBarWidth - 2, info.thumbHeight)
    end
end

-- 判断点击是否在滚动条上
function SlidePanel:isOverScrollBar(x, y)
    local scrollBarX = self.x + self.w - self.scrollBarWidth
    local scrollBarY = self.y + self.padding
    local scrollBarHeight = self.h - 2 * self.padding
    
    return x >= scrollBarX and x < scrollBarX + self.scrollBarWidth and
           y >= scrollBarY and y < scrollBarY + scrollBarHeight
end

-- 判断点击是否在滚动块上
function SlidePanel:isOverScrollThumb(x, y)
    local scrollBarX = self.x + self.w - self.scrollBarWidth
    local scrollBarY = self.y + self.padding
    local info = self:getScrollBarInfo()
    
    if not info or not info.canScroll then
        return false
    end
    
    return x >= scrollBarX and x < scrollBarX + self.scrollBarWidth and
           y >= scrollBarY + info.thumbY and y < scrollBarY + info.thumbY + info.thumbHeight
end
function SlidePanel:getSlideSpace()
    local content = self:getContent()
    if content then
        local xspace, yspace = content.w - self.w, content.h - self.h
        xspace = xspace < 0 and 0 or xspace
        yspace = yspace < 0 and 0 or yspace
        return xspace, yspace
    end
    return 0, 0
end

function SlidePanel:backToCenter()
    local dx, dy = 0, 0
    local content = self:getContent()
    if not content then
        return
    end
    local cx, cy = content:getLocalPos()
    local cw, ch = content:getSize()
    local backPower = 10
    -- 保持content的拖拽对边边界在panel中

    -- x轴的边界回归
    if cx > (0 + self.spacingX) then
        dx = dx - backPower
    end -- child左边角超过了panel就不许更加右移动了
    if (cx + cw) < (self.w - self.spacingX) then
        dx = dx + backPower
    end
    -- y轴的边界回归
    if cy > (0 + self.spacingY) then
        dy = dy - backPower
    end
    if (cy + ch) < (self.h - self.spacingY) then
        dy = dy + backPower
    end

    -- 脱离指控后速度保持
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

-- 设置滑页进度x
function SlidePanel:setProgressX(p)
    if self.lockOffsetX then
        return
    end
    local content = self:getContent()
    if content then
        local xspace, yspace = self:getSlideSpace()
        content:setLocalPos(p * xspace, content.localY)
        self.progressX = p
        self:dragProgress(self.progressX, self.progressY)
    end
end

-- 设置滑页进度y
function SlidePanel:setProgressY(p)
    if self.lockOffsetY then
        return
    end
    local content = self:getContent()
    if content then
        local xspace, yspace = self:getSlideSpace()
        content:setLocalPos(content.localX, p * yspace)
        self.progressY = p
        self:dragProgress(self.progressX, self.progressY)
    end
end

function SlidePanel:dragProgress(progressX, progressY)
    -- 如果有拖拽条
end

function SlidePanel:destroy()
    widget.destroy(self)
    -- self.shadePanel:destroy()
end

return SlidePanel
