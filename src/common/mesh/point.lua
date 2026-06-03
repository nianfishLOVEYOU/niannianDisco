local class = require "src.common.class"
local point = class:extend()


function point:init(x,y,weight)
    self.x = x
    self.y = y
    self.originalX = x
    self.originalY = y
    self.weight = 1
end


function point:effect(x,y)
    self.x = self.originalX + (x - self.originalX) * self.weight
    self.y = self.originalY + (y - self.originalY) * self.weight
end

function point:add(point)
    self.x = self.x + point.x
    self.y = self.y + point.y
end

function point:reduce(point)
    self.x = self.x - point.x
    self.y = self.y - point.y
end



return point