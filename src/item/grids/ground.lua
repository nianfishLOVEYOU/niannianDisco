local bodyItem = require "src.item.imageItem"

local ground = bodyItem:extend()

function ground:init(imgPath)
    
    self.type="ground"
    self.z = 0
    self:setImage("res/image/grid/ground.png")
    self:setSize(mapManager.map.gridSize,mapManager.map.gridSize)
end

return ground