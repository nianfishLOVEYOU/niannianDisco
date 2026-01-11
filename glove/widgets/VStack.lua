local fun = require "glove/fun"
local widget = require "glove.widgets.widget"

local aligtype={"start","center,end"}
local VStack = widget:extend()

function VStack:init(x, y, w, h, childrenTB,spacing, align)
  self.type = "HStack"

  self.align = align or "start"
  self.w = 0 -- computed in layout method
  self.h=0
  self.children = childrenTB
  self.haveSpacer = fun.some(childrenTB, isSpacerWithoutSize)
  self.spacing=spacing or 10
  for i, child in ipairs(childrenTB) do
    self:addChild(child)
  end
  self:layout()
end

function VStack:draw()
  for _, child in ipairs(self.children) do
    child:draw(x, y)
  end

  for _, child in ipairs(self.children) do
    if child.drawLater then child:drawLater(x, y) end
  end
end

function VStack:setSize(w, h)
  self.w = w
  --self.h = h
end

function VStack:getSize()
  -- If there is a Spacer child then use screen height.
  if self.haveSpacer then return Glove.getAvailableHeight() end

  -- Compute height based on children.
  local children = self.children
  local lastChild = children[#children]
  local w, h = self.w , lastChild.y + lastChild.h - self.y
  return w, h
end

function VStack:layout()
  local children = self.children
  local spacerWidth = 0
  local spacing = self.spacing or 0
  local x = self.localX or 0
  local y = self.localY or 0

  -- Get width of widest child.
  self.w = fun.max(
    children,
    function(child) return child.w or 0 end
  )

  -- Count spacers with no size.
  local spacerCount = fun.count(children, isSpacerWithoutSize)

  -- If there are any spacers with no size ...
  if spacerCount > 0 then
    -- Get the total height of the all other children.
    local childrenHeight = fun.sumFn(
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


      if align == "center" then
        child:setLocalPos(x + (self.w - child.h) / 2,y)
      elseif align == "end" then
        child:setLocalPos(x + self.w - child.h,y)
      else -- assume "start"
        child:setLocalPos(x,y)
      end

      local prevChild = children[i - 1]
      if prevChild and prevChild.type ~= "Spacer" then
        child.localY = child.localY + spacing
      end

      y = child.localY + child.h
    end
  end
  print("!!! layout")
  local lastChild = self.children[#children]
  self.h=lastChild.y + lastChild.h- self.y
  print("VS  "..self.w.."  "..self.h)
end

function VStack:setLocalPos(x,y,z)
  VStack.super.setLocalPos(self,x,y,z)
  self:layout()
end


function VStack:setPos(x,y,z)
  VStack.super.setPos(self,x,y,z)
  self:layout()
end

function VStack:destroy()
  for _, child in ipairs(self.children) do
    if child.destroy then child:destroy() end
  end
  --父类删除
  VStack.super.destroy(self)
end

return VStack
