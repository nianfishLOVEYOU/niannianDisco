local bodyItem = require "src.item.imageItem"

local map01 = bodyItem:extend()

function map01:init(imgPath)
    
    self.type="map01"
    self.z = 0
    self:setImage("res/image/grid/map01.png")
    self:setSize(mapManager.map.gridSize,mapManager.map.gridSize)
end

return map01