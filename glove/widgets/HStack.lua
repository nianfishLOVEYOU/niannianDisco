local fun = require "glove/fun"
local widget = require "glove.widgets.widget"

local aligtype={"top","center,buttom"}

local HStack = widget:extend()

function HStack:init(x, y, w, h,childrenTB,spacing, align)
  self.type = "HStack"

  self.align = align or "top"
  
  self.w=0
  self.h = 0 -- computed in layout method
  self.children = childrenTB
  self.haveSpacer = fun.some(childrenTB, isSpacerWithoutSize)
  self.spacing=spacing or 10
  for i, child in ipairs(childrenTB) do
    self:addChild(child)
  end
  self:layout()
end

function HStack:draw()
  for _, child in ipairs(self.children) do
    child:draw()
  end

  for _, child in ipairs(self.children) do
    if child.drawLater then child:drawLater(x, y) end
  end
end

function HStack:setSize(w, h)
  --self.w = w
  self.h = h
end

function HStack:getSize()
  -- If there is a Spacer child then use screen width.
  if self.haveSpacer then return Glove.getAvailableWidth() end

  -- Compute height based on children.
  local children = self.children
  local lastChild = children[#children]
 --如果有宽度用自己的宽度，不然就用孩子的
  local w, h = self.w or lastChild.x + lastChild.w- self.x, self.h
  return w, h
end

function HStack:layout()
  local children = self.children
  local spacerWidth = 0
  local spacing = self.spacing or 0
  local x = self.localX or 0
  local y = self.localY or 0

  -- Get height of tallest child.
  self.h = fun.max(
    children,
    function(child) return child.h or 0 end
  )
  print(self.type .."  ".. self.h)

  -- Count spacers with no size.
  local spacerCount = fun.count(children, isSpacerWithoutSize)

  -- If there are any spacers with no size ...
  if spacerCount > 0 then
    -- Get the total width of the all other children.
    local childrenWidth = fun.sumFn(
      children,
      function(child)
        return isSpacerWithoutSize(child) and 0 or child.h
      end
    )

    -- Get the number of children that are not spacers
    -- and not preceded by a spacer.
    local gapCount = fun.count(
      children,
      function(child, i)
        if child.type == "Spacer" then return false end
        local prevChild = children[i - 1]
        return prevChild and prevChild.type ~= "Spacer"
      end
    )

    -- Account for requested gaps between children.
    childrenWidth = childrenWidth + spacing * gapCount

    local availableWidth = self:getWidth()

    -- Compute the size of each zero width Spacer.
    spacerWidth = (availableWidth - childrenWidth) / spacerCount
  end

  -- Set the x and y keys of each non-spacer child.
  for i, child in ipairs(children) do
    if child.type == "Spacer" then
      x = x + (child.size or spacerWidth)
    else

      if align == "center" then
        child:setLocalPos(x,y + (self.h - child.h) / 2)
      elseif align == "bottom" then
        child:setLocalPos(x,y + self.h - child.h)
      else -- assume "top"
        child:setLocalPos(x,y)
      end

      local prevChild = children[i - 1]
      if prevChild and prevChild.type ~= "Spacer" then
        child.localX = child.localX + spacing
      end

      x = child.localX + child.w
    end
  end

  
  local lastChild = self.children[#children]
  self.w = lastChild.x + lastChild.w- self.x
end

function HStack:setLocalPos(x,y,z)
  HStack.super.setLocalPos(self,x,y,z)
  self:layout()
end


function HStack:setPos(x,y,z)
  HStack.super.setPos(self,x,y,z)
  self:layout()
end


function HStack:destroy()
  for _, child in ipairs(self.children) do
    if child.destroy then child:destroy() end
  end
  --父类删除
  HStack.super.destroy(self)
end

return HStack
