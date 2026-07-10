-- 所有ui的父类
local item = require "src.item.item"

local widget = item:extend()

-- 布局容器类型集合，这些容器会自己控制子项位置，posAlign 应让位给布局
local LAYOUT_TYPES = { VStack = true, HStack = true, GridStack = true }

-- is widget
function widget:init()
    Glove.widgets[self] = self
    self.visiable = true
    self.color = {1, 1, 1, 1}
    -- posAlign: nil=关闭（手动位置）
    -- 水平: "left" | "center" | "right"
    -- 垂直: "top"  | "middle" | "bottom"
    -- 组合格式: "left-top" / "center-middle" / "right-bottom" 等，共9种
    self.posAlign = nil
    -- 对齐填入边距（内边距）: {left, right, top, bottom}
    self.alignInset = {left = 0, right = 0, top = 0, bottom = 0}
    -- 对齐点相对偏移: {x, y}
    self.alignOffset = {x = 0, y = 0}
end

function widget:setvisiable(v)
    self.visiable = v
end


------------------------------------------------------------------------
-- 对齐系统
-- setAlign(posAlign) 设置对齐方式并立即应用
-- applyAlign()       计算位置并写入，可重复调用（如父对象改变尺寸后刷新）
-- 若父对象是布局容器（VStack/HStack/GridStack），applyAlign 会静默跳过，
-- 由布局自己控制子项位置（布局优先原则）
------------------------------------------------------------------------

-- 设置对齐并立即生效
-- posAlign: "left-top"|"left-middle"|"left-bottom"
--           "center-top"|"center-middle"|"center-bottom"
--           "right-top"|"right-middle"|"right-bottom"
--           nil 关闭对齐，回到手动设置位置
-- inset:
--   number -> 四边同值
--   table  -> {left=?, right=?, top=?, bottom=?}
-- offset:
--   table -> {x=?, y=?}
function widget:setAlign(posAlign, inset, offset)
    self.posAlign = posAlign
    if inset ~= nil then
        if type(inset) == "number" then
            self.alignInset = {left = inset, right = inset, top = inset, bottom = inset}
        elseif type(inset) == "table" then
            self.alignInset = {
                left = inset.left or 0,
                right = inset.right or 0,
                top = inset.top or 0,
                bottom = inset.bottom or 0
            }
        else
            print("[widget:setAlign] inset 类型错误:", type(inset))
        end
    end

    if offset ~= nil then
        if type(offset) == "table" then
            self.alignOffset = {
                x = offset.x or 0,
                y = offset.y or 0
            }
        else
            print("[widget:setAlign] offset 类型错误:", type(offset))
        end
    end

    self:applyAlign()
end

-- 应用当前 posAlign。
-- 无父对象时以游戏视窗为参照；有父对象且父对象是布局容器则跳过。
function widget:applyAlign()
    if not self.posAlign then return end

    -- 父对象是布局容器 → 布局优先，不干预
    if self.parent and LAYOUT_TYPES[self.parent.type] then
        return
    end

    -- 获取参照区域尺寸
    local pw, ph
    if self.parent and self.parent.setAlign then --家长是ui
        pw, ph = self.parent:getSize()
    else
        pw = love.graphics.getWidth()
        ph = love.graphics.getHeight()
    end

    local sw, sh = self:getSize()
    local inset = self.alignInset or {left = 0, right = 0, top = 0, bottom = 0}
    local offset = self.alignOffset or {x = 0, y = 0}

    -- 扣除 inset 后的可用区域（从参照区域内部往里收）
    local availableW = pw - inset.left - inset.right
    local availableH = ph - inset.top - inset.bottom
    if availableW < 0 then availableW = 0 end
    if availableH < 0 then availableH = 0 end

    -- 解析 "hAlign-vAlign"
    local hAlign, vAlign = self.posAlign:match("^(%a+)-(%a+)$")
    if not hAlign then
        print("[widget:applyAlign] 无法解析 posAlign:", tostring(self.posAlign))
        return
    end

    -- 水平偏移
    local ox = inset.left
    if hAlign == "center" then
        ox = inset.left + (availableW - sw) / 2
    elseif hAlign == "right" then
        ox = pw - inset.right - sw
    end -- "left" → 0

    -- 垂直偏移
    local oy = inset.top
    if vAlign == "middle" then
        oy = inset.top + (availableH - sh) / 2
    elseif vAlign == "bottom" then
        oy = ph - inset.bottom - sh
    end -- "top" → 0

    -- 在锚点结果上再叠加用户偏移
    ox = ox + (offset.x or 0)
    oy = oy + (offset.y or 0)

    if self.parent then
        self:setLocalPos(ox, oy)
    else
        self:setPos(ox, oy)
    end
end

-- 设置裁剪,只是裁剪掉isover ，显示还是需要统一来裁剪
function widget:setShade(shade)
    if self == shade then
        print("不能设置自己为裁剪对象!!!!!!!!")
        return
    end
    local function childSetShade(parent, shade)
        parent.shade = shade
        for _, child in pairs(parent.children) do
            childSetShade(child, shade)
        end
    end

    childSetShade(self, shade)
end

-- 0=没遮罩或者在遮罩里面 1=有遮罩在外面,不显示
function widget:isShade(mouseX, mouseY)
  --nianDebug.printStackTrace("widget:isShade")
    if self.parent then -- 是否对下面进行遮罩
        if self.parent.shade == true and self.parent.isShade then
            return not self.parent:isOver(mouseX, mouseY) -- 递归返回含有遮罩的父辈遮罩情况
        elseif self.parent.isShade then
            return self.parent:isShade(mouseX, mouseY) -- 如果没有遮罩则继续向上寻找
        end
    else
        return false
    end
    return false
end

function widget:isOver(mouseX, mouseY)
    -- 如果有裁剪点到外面就不算
    if self:isShade(mouseX, mouseY) then
        return false
    end
    -- 没遮罩则返回点击到自己了没
    local width, height = self:getSize()
    return self.x - self.overPadding <= mouseX and mouseX <= self.x + width and self.y <= mouseY and mouseY <= self.y +
               height
end

function widget:setParentInit()
    if self.parent.shade then
        self.shade = self.parent.shade
    end
    self.localZ = 1
    if self.posAlign and not LAYOUT_TYPES[self.parent.type] then
        -- 有对齐设置且父对象不是布局容器 → 直接应用对齐，忽略当前绝对位置
        self.localX = 0
        self.localY = 0
        self:applyAlign()
    else
        self.localX = self.x - self.parent.x
        self.localY = self.y - self.parent.y
    end
end

function widget:destroy()
    -- 父类删除
    widget.super.destroy(self)
    Glove.widgets[self] = nil
end

return widget
