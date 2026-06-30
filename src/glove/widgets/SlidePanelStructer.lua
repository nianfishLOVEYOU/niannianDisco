-- slider
local widget = require "src.glove.widgets.widget"

local g = love.graphics
local SlidePanelStructer = widget:extend()

-- 虚拟内容容器：只负责绘制当前复用池中的可见构造体
local VirtualContent = widget:extend()

function VirtualContent:init()
    self.type = "VirtualContent"
    self.w = 0
    self.h = 0
    self.color = {0, 0, 0, 0}
end

function VirtualContent:draw()
    self:localPosRefresh()
    for _, child in ipairs(self.children) do
        if child.getRealVisiable and child:getRealVisiable() and child.draw then
            child:draw()
        elseif child.visiable ~= false and child.draw then
            child:draw()
        end
    end
end

-- 可拖拽内容content，新内容的构造方法constructor(index),超出范围的index会被禁止构造然后几月资源给目前看得到的内容
-- length是内容的总长度，index范围是1-length
function SlidePanelStructer:init(content)
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
    self.shade = true
    -- 滚动条配置
    self.scrollBarWidth = 10
    self.isDraggingScrollBar = false
    self.scrollBarColor = {1, 1, 1, 1} -- 白色背景
    self.scrollThumbColor = {0, 0, 0, 1} -- 黑色滚动块

    -- 虚拟化配置：用于结构化列表/网格的“固定池 + 滚动复用”
    self.virtual = {
        enabled = false,
        mode = "list",
        count = 0,
        structerFunction = nil,
        opts = {},
        bufferRows = 2,
        cols = 1,
        itemW = 80,
        itemH = 24,
        rowStride = 34,
        colStride = 90,
        poolRows = 0,
        poolCols = 0,
        poolSize = 0,
        pool = {},
        topRow = 1,
        contentPaddingX = self.spacingX,
        contentPaddingY = self.spacingY,
        align = "left"
    }
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

function SlidePanelStructer:refresh()
    -- 结构化模式：只刷新池映射，不重建全部子项
    if self.virtual.enabled then
        self:_computeVirtualMetrics()
        self:_updateVirtualPool(true)
        return
    end

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
function SlidePanelStructer:refreshByStruct(toConstruct, length)
    -- 与旧接口兼容：统一走 add(构造函数, 总数, 配置)
    self:add(toConstruct, length)
end

-- 后期需要加入新的元素时 function number
function SlidePanelStructer:add(arg1, arg2, arg3)
    -- 新创建方式：add(structerFunction, count, opts)
    if type(arg1) == "function" and type(arg2) == "number" then
        local structerFunction = arg1
        local count = arg2
        local opts = arg3 or {}

        self.virtual.enabled = true
        self.virtual.structerFunction = structerFunction
        self.virtual.count = math.max(0, math.floor(count))
        self.virtual.mode = opts.mode == "gridlist" and "gridlist" or "list"
        self.virtual.opts = opts
        self.virtual.bufferRows = opts.bufferRows or 2
        self.virtual.align = opts.align or "left"
        self.virtual.contentPaddingX = opts.paddingX or self.spacingX
        self.virtual.contentPaddingY = opts.paddingY or self.spacingY

        if opts.spacingX then
            self.spacingX = opts.spacingX
        end
        if opts.spacingY then
            self.spacingY = opts.spacingY
        end

        self:_buildVirtualContent()
        return
    end

    -- 旧方式兼容：add(child)
    local child = arg1
    self.virtual.enabled = false
    self:getContent():addChild(child)
    self:getContent():layout()
end

function SlidePanelStructer:_buildVirtualContent()
    -- 创建虚拟容器并初始化池
    local content = VirtualContent:new()
    content:setName("virtual content")
    self:setContent(content, self.spacingX, self.spacingY)
    self:_computeVirtualMetrics()
    self:_createVirtualPool()
    self:_updateVirtualPool(true)
end

function SlidePanelStructer:_calcColumns(innerW)
    -- list 固定单列；gridlist 支持自动列数或手动 columns
    local opts = self.virtual.opts or {}
    if self.virtual.mode ~= "gridlist" then
        return 1
    end

    if opts.columns and opts.columns > 0 then
        return math.max(1, math.floor(opts.columns))
    end

    local itemW = self.virtual.itemW
    local spacingX = self.spacingX
    if itemW <= 0 then
        itemW = 1
    end
    local cols = math.floor((innerW + spacingX) / (itemW + spacingX))
    return math.max(1, cols)
end

function SlidePanelStructer:_ensureSampleSize()
    -- 优先使用外部传入尺寸；否则通过样本构造体测量尺寸
    local opts = self.virtual.opts or {}
    if opts.itemWidth and opts.itemHeight then
        self.virtual.itemW = opts.itemWidth
        self.virtual.itemH = opts.itemHeight
        return
    end

    if self.virtual.count <= 0 then
        self.virtual.itemW = opts.itemWidth or self.virtual.itemW
        self.virtual.itemH = opts.itemHeight or self.virtual.itemH
        return
    end

    local sample = self.virtual.structerFunction(1, nil)
    if sample then
        local sw, sh = sample.getSize and sample:getSize() or nil, nil
        if sample.getSize then
            sw, sh = sample:getSize()
        end
        if sw and sw > 0 then
            self.virtual.itemW = opts.itemWidth or sw
        end
        if sh and sh > 0 then
            self.virtual.itemH = opts.itemHeight or sh
        end
        sample:destroy()
    else
        self.virtual.itemW = opts.itemWidth or self.virtual.itemW
        self.virtual.itemH = opts.itemHeight or self.virtual.itemH
    end
end

function SlidePanelStructer:_computeVirtualMetrics()
    -- 计算网格参数、可视行数、池大小以及虚拟内容总尺寸
    if not self.virtual.enabled then
        return
    end

    self:_ensureSampleSize()

    local content = self:getContent()
    if not content then
        return
    end

    local innerW = math.max(1, self.w - 2 * self.padding - self.scrollBarWidth)
    local innerH = math.max(1, self.h - 2 * self.padding)

    self.virtual.cols = self:_calcColumns(innerW)
    self.virtual.rowStride = self.virtual.itemH + self.spacingY
    self.virtual.colStride = self.virtual.itemW + self.spacingX

    local totalRows = math.max(0, math.ceil(self.virtual.count / self.virtual.cols))
    local visibleRows = math.max(1, math.ceil(innerH / math.max(1, self.virtual.rowStride)))
    self.virtual.poolRows = visibleRows + self.virtual.bufferRows * 2
    self.virtual.poolCols = self.virtual.cols
    self.virtual.poolSize = self.virtual.poolRows * self.virtual.poolCols

    local contentGridW = self.virtual.cols * self.virtual.itemW + math.max(0, self.virtual.cols - 1) * self.spacingX
    local contentGridH = totalRows * self.virtual.itemH + math.max(0, totalRows - 1) * self.spacingY

    content.w = math.max(innerW, contentGridW + self.virtual.contentPaddingX * 2)
    content.h = math.max(innerH, contentGridH + self.virtual.contentPaddingY * 2)
end

function SlidePanelStructer:_replacePoolWidget(slot, newWidget)
    -- 槽位替换：销毁旧构造体并挂载新构造体
    local content = self:getContent()
    if slot.widget then
        content:removeChild(slot.widget)
        slot.widget:destroy()
    end
    slot.widget = newWidget
    if newWidget then
        content:addChild(newWidget)
    end
end

function SlidePanelStructer:_rebindSlot(slot, dataIndex)
    -- 将某个池槽位绑定到数据索引（超出范围则隐藏）
    -- structerFunction 约定：fn(index, oldWidget) -> widget（可复用或返回新对象）
    local fn = self.virtual.structerFunction
    if not fn then
        return
    end

    if dataIndex < 1 or dataIndex > self.virtual.count then
        slot.dataIndex = nil
        if slot.widget then
            slot.widget.visiable = false
        end
        return
    end

    if slot.dataIndex == dataIndex and slot.widget then
        slot.widget.visiable = true
        return
    end

    local bound = fn(dataIndex, slot.widget)
    if bound and bound ~= slot.widget then
        self:_replacePoolWidget(slot, bound)
    elseif not slot.widget then
        self:_replacePoolWidget(slot, fn(dataIndex, nil))
    end

    if slot.widget and slot.widget.setName then
        slot.widget:setName("virtual_item_" .. tostring(dataIndex))
    end

    slot.dataIndex = dataIndex
    if slot.widget then
        slot.widget.visiable = true
    end
end

function SlidePanelStructer:_positionSlotWidget(slot)
    -- 根据索引换算行列并定位；支持 left/center/right 对齐
    if not slot.widget or not slot.dataIndex then
        return
    end

    local index = slot.dataIndex
    local col = ((index - 1) % self.virtual.cols) + 1
    local row = math.floor((index - 1) / self.virtual.cols) + 1

    local baseX = self.virtual.contentPaddingX
    local innerW = math.max(1, self.w - 2 * self.padding - self.scrollBarWidth)
    local gridW = self.virtual.cols * self.virtual.itemW + math.max(0, self.virtual.cols - 1) * self.spacingX
    if self.virtual.align == "center" then
        baseX = self.virtual.contentPaddingX + math.max(0, (innerW - gridW) / 2)
    elseif self.virtual.align == "right" then
        baseX = self.virtual.contentPaddingX + math.max(0, innerW - gridW)
    end

    local x = baseX + (col - 1) * self.virtual.colStride
    local y = self.virtual.contentPaddingY + (row - 1) * self.virtual.rowStride
    slot.widget:setLocalPos(x, y)
end

function SlidePanelStructer:_createVirtualPool()
    -- 创建固定数量槽位，后续滚动只更新绑定关系，不增删总对象数
    local content = self:getContent()
    if not content then
        return
    end

    for _, slot in ipairs(self.virtual.pool) do
        if slot.widget then
            content:removeChild(slot.widget)
            slot.widget:destroy()
        end
    end
    self.virtual.pool = {}

    for i = 1, self.virtual.poolSize do
        table.insert(self.virtual.pool, {
            widget = nil,
            dataIndex = nil,
            slotIndex = i
        })
    end
end

function SlidePanelStructer:_updateVirtualPool(force)
    -- 根据当前滚动位置计算顶部行，并重绑定可见窗口（上下各 bufferRows 余量）
    if not self.virtual.enabled then
        return
    end

    self:_computeVirtualMetrics()

    local content = self:getContent()
    if not content then
        return
    end

    if #self.virtual.pool ~= self.virtual.poolSize then
        self:_createVirtualPool()
        force = true
    end

    local scrollY = -content.localY
    if scrollY < 0 then
        scrollY = 0
    end
    local rowStride = math.max(1, self.virtual.rowStride)
    local topRow = math.floor(scrollY / rowStride) - self.virtual.bufferRows + 1
    if topRow < 1 then
        topRow = 1
    end

    if not force and topRow == self.virtual.topRow then
        return
    end
    self.virtual.topRow = topRow

    local indexStart = (topRow - 1) * self.virtual.cols + 1
    for slotId, slot in ipairs(self.virtual.pool) do
        local dataIndex = indexStart + slotId - 1
        self:_rebindSlot(slot, dataIndex)
        self:_positionSlotWidget(slot)
    end
end

function SlidePanelStructer:remove(name)
    if self.virtual.enabled then
        return
    end

    local contents = self:getContents()
    if contents then
        for i, c in ipairs(contents) do
            if c.name == name then
                contents[i]:destroy()
                table.remove(contents, i)
                self:getContent():layout()
                break
            end
        end
    end
end

function SlidePanelStructer:removeIndex(index)
    if self.virtual.enabled then
        return
    end

    local contents = self:getContents()
    if contents then
        if index < 1 or index > #contents then
            return
        end
        contents[index]:destroy()
        table.remove(contents, index)
        self:getContent():layout()
    end
end

function SlidePanelStructer:get(name)

end

function SlidePanelStructer:getContents()
    if self.virtual.enabled then
        -- 结构化模式下返回“当前池中有效构造体”，不是全量数据
        local out = {}
        for _, slot in ipairs(self.virtual.pool) do
            if slot.widget and slot.dataIndex then
                table.insert(out, slot.widget)
            end
        end
        return out
    end

    local content = self:getContent()
    if content then
        return content.children
    end
    return {}
end

function SlidePanelStructer:setTitle(str)
    self.title = Glove.Text:new(str)
    self.title:setSize(200, 0)
    self.title:setLocalPos(self.spacingX + self.x, self.spacingY + self.y)
end

-- 设置滑页内的内容
function SlidePanelStructer:setContent(child, x, y)
    self:clearChild()
    self:addChild(child)
    x = x or 0
    y = y or 0
    child:setLocalPos(x, y)
end

-- 获取垂直排列的vstack
function SlidePanelStructer:getContent()
    if #self.children == 1 then
        return self.children[1]
    end
    return nil
end

function SlidePanelStructer:draw()
    -- 进度条

    if not self.isDrag then
        -- self:backToCenter()
    end

    --  裁剪
    if not self:getRealVisiable() then
        return
    end

    g.setColor(self.color)
    g.rectangle("fill", self.x, self.y, self.w, self.h, self.padding, self.padding)
    g.setColor(0, 0, 0, 0.5)
    g.rectangle("line", self.x, self.y, self.w, self.h, self.padding, self.padding)
    g.rectangle("line", self.x + self.padding, self.y + self.padding, self.w - 2 * self.padding,
        self.h - 2 * self.padding)
    local content = self:getContent()
    if not content then
        return
    end

    if self.virtual.enabled then
        -- 绘制前确保池映射与滚动位置同步
        self:_updateVirtualPool(false)
    end

    -- 减去padding的裁剪，避免内容被完全遮挡无法拖动
    local sx, sy, sw, sh = g.getScissor()
    g.setScissor(self.x + self.padding, self.y + self.padding, self.w - 2 * self.padding - self.scrollBarWidth,
        self.h - 2 * self.padding)
    for _, entry in ipairs(self.children) do
        if entry.draw then
            entry:draw()
        end
    end
    g.setScissor(sx, sy, sw, sh)

    -- 绘制滚动条
    self:drawScrollBar()

    if self.title then
        self.title:draw()
    end
    -- g.setColor(1, 1, 0)
    -- g.rectangle("line", self.x, self.y, self.w, self.h)

    -- self.shadePanel:draw()
end

-- 处理点击事件（包括滚动条点击） 暂时没有点击，都会穿透到内容上
function SlidePanelStructer:onClick(x, y)
    -- 检测是否点击了滚动条
    if self:isOverScrollBar(x, y) then
        print("213123123213")
        if self:isOverScrollThumb(x, y) then
            -- 点击了滚动块，开始拖拽
            self.isDraggingScrollBar = true
        else
            -- 点击了滚动条其他位置，直接导航
            self:dragScrollBar(y)
            self.isDraggingScrollBar = true
        end
    else
        self.isDraggingScrollBar = false
    end

    print("Clicked on scroll bar, dragging:", self.isDraggingScrollBar)
end

function SlidePanelStructer:onDrag(x, y, dx, dy)
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
function SlidePanelStructer:dragScrollBar(y)
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
function SlidePanelStructer:onDragInternal(dx, dy)
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

    if self.virtual.enabled then
        -- 拖拽滚动时实时更新复用池
        self:_updateVirtualPool(false)
    end

    -- print("SlidePanelStructer", dx, dy)
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

function SlidePanelStructer:onDragOver(x, y)
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

function SlidePanelStructer:onClickOver(x, y)
    local content = self:getContent()
    if content and content.onClickOver then
        local cx, cy = content:getPos()
        content:onClickOver(x - cx, y - cy)
    end
    self.isDraggingScrollBar = false
end

function SlidePanelStructer:onHold(x, y)
    -- hover 不做处理，但也应该在可视区域内才触发 child 的 onHold
    if not self:isOver(x, y) then
        return
    end
    local content = self:getContent()
    if not content then
        return
    end
    -- 转换为 content 本地坐标并调用其 onHold（若存在）
    local gx, gy = content:getPos()
    if content.onHold then
        content:onHold(x - gx, y - gy)
    end
end

-- 计算滚动条的尺寸和位置
function SlidePanelStructer:getScrollBarInfo()
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
    thumbHeight = math.max(thumbHeight, 20) -- 最小高度为20像素

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
function SlidePanelStructer:drawScrollBar()
    local scrollBarX = self.x + self.w - self.scrollBarWidth
    local scrollBarY = self.y + self.padding
    local scrollBarHeight = self.h - 2 * self.padding

    -- 绘制滚动条背景（白色+黑色描边）
    g.setColor(self.scrollBarColor)
    g.rectangle("fill", scrollBarX, scrollBarY, self.scrollBarWidth, scrollBarHeight)
    g.setColor(0, 0, 0, 0.5) -- 黑色描边
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
function SlidePanelStructer:isOverScrollBar(x, y)
    local scrollBarX = self.x + self.w - self.scrollBarWidth
    local scrollBarY = self.y + self.padding
    local scrollBarHeight = self.h - 2 * self.padding

    return x >= scrollBarX and x < scrollBarX + self.scrollBarWidth and y >= scrollBarY and y < scrollBarY +
               scrollBarHeight
end

-- 判断点击是否在滚动块上
function SlidePanelStructer:isOverScrollThumb(x, y)
    local scrollBarX = self.x + self.w - self.scrollBarWidth
    local scrollBarY = self.y + self.padding
    local info = self:getScrollBarInfo()

    if not info or not info.canScroll then
        return false
    end

    return
        x >= scrollBarX and x < scrollBarX + self.scrollBarWidth and y >= scrollBarY + info.thumbY and y < scrollBarY +
            info.thumbY + info.thumbHeight
end
function SlidePanelStructer:getSlideSpace()
    local content = self:getContent()
    if content then
        local xspace, yspace = content.w - self.w, content.h - self.h
        xspace = xspace < 0 and 0 or xspace
        yspace = yspace < 0 and 0 or yspace
        return xspace, yspace
    end
    return 0, 0
end

function SlidePanelStructer:backToCenter()
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
function SlidePanelStructer:setProgressX(p)
    if self.lockOffsetX then
        return
    end
    local content = self:getContent()
    if content then
        local xspace, yspace = self:getSlideSpace()
        content:setLocalPos(p * xspace, content.localY)
        self.progressX = p
        self:dragProgress(self.progressX, self.progressY)
        if self.virtual.enabled then
            -- 进度条跳转后同步池
            self:_updateVirtualPool(false)
        end
    end
end

-- 设置滑页进度y
function SlidePanelStructer:setProgressY(p)
    if self.lockOffsetY then
        return
    end
    local content = self:getContent()
    if content then
        local xspace, yspace = self:getSlideSpace()
        content:setLocalPos(content.localX, p * yspace)
        self.progressY = p
        self:dragProgress(self.progressX, self.progressY)
        if self.virtual.enabled then
            -- 进度条跳转后同步池
            self:_updateVirtualPool(false)
        end
    end
end

function SlidePanelStructer:dragProgress(progressX, progressY)
    -- 如果有拖拽条
end

function SlidePanelStructer:destroy()
    -- 主动释放池中构造体，避免残留引用
    if self.virtual and self.virtual.pool then
        for _, slot in ipairs(self.virtual.pool) do
            if slot.widget then
                slot.widget:destroy()
                slot.widget = nil
            end
        end
    end

    widget.destroy(self)
    if self.title then
        self.title:destroy()
    end
    -- self.shadePanel:destroy()
end

return SlidePanelStructer


-- 调用 slide:add(构造函数,数字,opts) → 自动开启虚拟复用
-- 调用 slide:getContent():addChild() → 自动关闭虚拟模式

-- local SlidePanel = require "src.glove.widgets.SlidePanelStructer"
-- local Glove = -- 你的UI全局对象

-- function testVirtualGridSlide()
--     local slide = SlidePanel:new()
--     slide:setSize(420, 500)
--     slide:setLocalPos(800, 50)
--     slide.lockOffsetX = true
--     slide.lockOffsetY = false

--     local totalGoods = 360 -- 360个商品

--     -- 网格Item构造器
--     local function createGridItem(index, oldWidget)
--         local item = oldWidget
--         if not item then
--             item = Glove.Text:new("")
--             item:setSize(80, 80) -- 单格尺寸80*80
--         end
--         item:setText("道具#"..index)
--         return item
--     end

--     -- gridlist网格模式
--     slide:add(createGridItem, totalGoods, {
--         mode = "gridlist",
--         columns = 4, -- 固定4列
--         bufferRows = 2,
--         itemWidth = 80,
--         itemHeight = 80,
--         spacingX = 12,
--         spacingY = 12,
--         align = "left"
--     })

--     rootUI:addChild(slide)
-- end