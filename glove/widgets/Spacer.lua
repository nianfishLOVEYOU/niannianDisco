function isSpacerWithoutSize(child)
  return child.type == "Spacer" and not child.size
end


local Spacer = require "src.common.aUIImage"
local widget = require "glove.widgets.widget"

local Spacer = widget:extend()

--[[
This widget adds space inside an `HStack` or `VStack`.

Adding a `Spacer` at the end of a table of child widgets
pushes them to the left.

Adding a `Spacer` at the beginning of a table of child widgets
pushes them to the right.

Adding a `Spacer` between widgets in a table of child widgets
pushes the ones preceding it to the left and
pushes the ones following it to the right.

Any number of `Spacer` widgets can be added to a table of widgets.
The amount of space consumed by each is computed by
dividing the unused space by the number of `Spacer` widgets.
--]]
function Spacer:init(x, y, w, h, size)
  self.type = "Spacer"

  local to = type(size)
  assert(to == "number" or to == "nil", "Spacer size must be a number or nil.")
  self.size = size
end

function Spacer:draw()
end


function Spacer:getSize(w, h)
  return 0,0
end

return Spacer
