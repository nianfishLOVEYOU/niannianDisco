local bodyItem = require "src.item.bodyItem"

local wall = bodyItem:extend()

function wall:init(imgPath, bodyInfo)
    
    self.type="wall"
    self.autoBody=true
    self:setImage("res/image/wall.png")
    self:setSize(mapManager.map.gridSize,mapManager.map.gridSize)
end

return wall