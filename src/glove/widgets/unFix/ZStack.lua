local fun = require "glove/fun"
local love = require "love"

local function layout(self)
  local align = self.align or "NW"
  local children = self.children
  local x = self.x or 0
  local y = self.y or 0

  -- Get width of widest child.
  local maxWidth = fun.max(
    children,
    function(child) return child:getWidth() or 0 end
  )
  self.maxWidth = maxWidth

  -- Get height of tallest child.
  local maxHeight = fun.max(
    children,
    function(child) return child:getHeight() or 0 end
  )
  self.maxHeight = maxHeight

  local centerX = self.maxWidth / 2
  local centerY = self.maxHeight / 2

  -- Set the x and y keys of each non-spacer child.
  for _, child in ipairs(children) do
    local width = child:getWidth()
    local height = child:getHeight()

    if align == "center" then
      child.localX = centerX - width / 2
      child.localY = centerY - height / 2
    elseif align == "up" then
      child.localX = centerX - width / 2
      child.localY = 0
    elseif align == "down" then
      child.localX = centerX - width / 2
      child.localY = maxHeight - height
    elseif align == "right" then
      child.localX = maxWidth - width
      child.localY = centerY - height / 2
    elseif align == "left" then
      child.localX = 0
      child.localY = centerY - height / 2
    elseif align == "rightup" then
      child.localX = maxWidth - width
      child.localY = 0
    elseif align == "rightdown" then
      child.localX = maxWidth - width
      child.localY = maxHeight - height
    elseif align == "leftdown" then
      child.localX = 0
      child.localY = maxHeight - height
    else -- assume leftup
      child.localX = 0
      child.localY = 0
    end
  end

  self.width = maxWidth
  self.height = maxHeight
end

local mt = {
  __index = {
    draw = function(self, parentX, parentY)
      parentX = parentX or Glove.margin
      parentY = parentY or Glove.margin
      local x = parentX + self.x
      local y = parentY + self.y
      for _, child in ipairs(self.children) do
        child:draw(x, y)
      end
    end,

    getHeight = function(self)
      return self.maxHeight
    end,

    getWidth = function(self)
      return self.maxWidth
    end,

    destroy = function(self)
      if self.__destroyed then return end
      self.__destroyed = true
      --孩子调用destroy
      for _, child in ipairs(self.children) do
        if child.destroy then child:destroy() end
      end
      if self.onDestroy then
        self.onDestroy()
      end
    end,
  }
}

--[[
This stacks widgets on top of each other.

To control the position of each widget in the stack,
specify the `align` option with a compass direction or `"center"`.

The parameters are:

- table of options

The supported options are:

- align: "center" or one of the following compass directions:
  "north", "south", "east", "west",
  "northeast", "southeast", "southwest", or "northwest" (default)
--]]
local function ZStack(options, childrenTB)
  local to = type(options)
  assert(to == "table" or to == "nil", "ZStack options must be a table.")

  local instance = options
  instance.type = "ZStack"
  instance.children = childrenTB
  instance.x = 0
  instance.y = 0
  setmetatable(instance, mt)
  layout(instance)
  return instance
end

return ZStack
