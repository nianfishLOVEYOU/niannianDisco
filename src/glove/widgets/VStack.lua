local fun = require "src.glove.fun"
local widget = require "src.glove.widgets.widget"

-- 排序方式，靠左，居中，靠右
local aligtype = {"left", "center", "right"}
local VStack = widget:extend()

function VStack:init(childrenTB, spacing, align)
    self.type = "VStack"

    self.align = align or "left"
    self.w = 0 -- computed in layout method
    self.h = 0
    self.haveSpacer = fun.some(childrenTB, isSpacerWithoutSize)
    self.spacing = spacing or 10
    for i, child in ipairs(childrenTB) do
        self:addChild(child)
    end
    self.color = {0, 0, 0, 0}
    self:layout()
end

function VStack:draw()
    self:localPosRefresh()
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, self.padding, self.padding)
    for _, child in ipairs(self.children) do
        child:draw()
    end
end

function VStack:setSize(w, h)
    self.w = w
    self.h = h
end

function VStack:getSize()
    -- If there is a Spacer child then use screen height.
    if self.haveSpacer then
        return self.w, Glove.getAvailableHeight()
    end
    return self.w, self.h
end

function VStack:layout()
    local children = self.children
    local spacerWidth = 0
    local spacing = self.spacing or 0
    local y = 0

    for i, child in ipairs(children) do
        if child.type == "VStack" or child.type == "HStack" then
            child:layout()
        end
    end

    -- Get width of widest child.
    self.w = fun.max(children, function(child)
        return child.w or 0
    end) or self.w

    -- Count spacers with no size.
    local spacerCount = fun.count(children, isSpacerWithoutSize)

    -- If there are any spacers with no size ...
    if spacerCount > 0 then
        -- Get the total height of the all other children.
        local childrenHeight = fun.sumFn(children, function(child)
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
        childrenHeight = childrenHeight + spacing * gapCount

        local availableHeight = self.h

        -- Compute the size of each zero width Spacer.
        spacerWidth = (availableHeight - childrenHeight) / spacerCount
    end

    -- Set the x and y keys of each non-spacer child.
    for i, child in ipairs(children) do
        if child.type == "Spacer" then
            y = y + (child.size or spacerWidth)
        else

            if i ~= 1 then
                y = y + spacing -- 除了首位全都加上间隔
            end

            local cw, ch = child:getSize()
            if self.align == "center" then
                child:setLocalPos((self.w - cw) / 2, y)
            elseif self.align == "right" then
                child:setLocalPos(self.w - cw, y)
            else -- assume "left"
                child:setLocalPos(0, y)
            end

            y = child.localY + ch

        end
    end
    -- Compute height based on children.
    local children = self.children
    if #children > 0 then
        local lastChild = children[#children]
        self.h = lastChild.y + lastChild.h - self.y
    else
        self.h = 0
    end

    -- print("VS layout " .. self.w .. "  " .. self.h)
end

function VStack:setLocalPos(x, y, z)
    VStack.super.setLocalPos(self, x, y, z)
    self:layout()
end

function VStack:setPos(x, y, z)
    VStack.super.setPos(self, x, y, z)
    self:layout()
end

return VStack
