local fun = require "src.glove.fun"
local widget = require "src.glove.widgets.widget"

-- 排序方式，顶格，居中，垫底
local aligtype = {"top", "center", "bottom"}
local HStack = widget:extend()

-- align: "top" | "center" | "bottom"
function HStack:init(childrenTB, spacing, align)
    self.type = "HStack"

    self.align = align or "center"

    self.w = 0
    self.h = 0 -- computed in layout method
    self.haveSpacer = fun.some(childrenTB, isSpacerWithoutSize)
    self.spacing = spacing or 10
    for i, child in ipairs(childrenTB) do
        self:addChild(child)
    end
    self.color = {0, 0, 0, 0}
    self:layout()
end

function HStack:draw()
    self:localPosRefresh()
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, self.padding, self.padding)
    for _, child in ipairs(self.children) do
        child:draw()
    end
end

function HStack:setSize(w, h)
    self.w = w
    self.h = h
end

function HStack:getSize()
    -- If there is a Spacer child then use screen width.
    if self.haveSpacer then
        print("haveSpacer!!!")
        return Glove.getAvailableWidth(), self.h
    end

    if not self.w then
        print("ui inside not w!!!")
    end
    return self.w, self.h
end

function HStack:layout()
    local children = self.children
    local spacerWidth = 0
    local spacing = self.spacing or 0
    local x = 0

    for i, child in ipairs(children) do
        if child.type == "VStack" or child.type == "HStack" then
            child:layout()
        end
    end

    self.h = fun.max(children, function(child, i)
        local _, h = child:getSize()
        return h or 0
    end) or self.h

    -- Count spacers with no size.
    local spacerCount = fun.count(children, isSpacerWithoutSize)

    -- If there are any spacers with no size ...
    if spacerCount > 0 then
        -- Get the total width of the all other children.
        local childrenWidth = fun.sumFn(children, function(child)
            return isSpacerWithoutSize(child) and 0 or child.h
        end)

        -- Get the number of children that are not spacers
        -- and not preceded by a spacer.
        local gapCount = fun.count(children, function(child, i)
            if child.type == "Spacer" then
                return false
            end
            local prevChild = children[i - 1]
            return prevChild and prevChild.type ~= "Spacer"
        end)

        -- Account for requested gaps between children.
        childrenWidth = childrenWidth + spacing * gapCount

        local availableWidth, _ = self:getSize()

        -- Compute the size of each zero width Spacer.
        spacerWidth = (availableWidth - childrenWidth) / spacerCount
    end
    -- Set the x and y keys of each non-spacer child.
    for i, child in ipairs(children) do
        if child.type == "Spacer" then
            x = x + (child.size or spacerWidth)
        else
            if i ~= 1 then
                x = x + spacing -- 除了首位全都加上间隔
            end
            local cw, ch = child:getSize()
            if self.align == "center" then
                child:setLocalPos(x, (self.h - ch) / 2)
            elseif self.align == "bottom" then
                child:setLocalPos(x, self.h - ch)
            else -- assume "top"
                child:setLocalPos(x, 0)
            end

            x = child.localX + cw

        end
    end

    -- 设置自己的size
    local children = self.children
    if #children > 0 then
        local lastChild = children[#children]
        self.w = lastChild.x + lastChild.w - self.x
    else
        self.w = 0
    end

    -- print("VS layout " .. self.w .. "  " .. self.h)
end

function HStack:setLocalPos(x, y, z)
    HStack.super.setLocalPos(self, x, y, z)
    self:layout()
end

function HStack:setPos(x, y, z)
    HStack.super.setPos(self, x, y, z)
    self:layout()
end

return HStack
