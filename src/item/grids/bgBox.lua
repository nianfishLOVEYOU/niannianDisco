local bodyItem = require "src.item.imageItem"

local bgBox = bodyItem:extend()

function bgBox:init(imgPath)
    
    self.type="bgBox"
    self.z = 0
    self:setImage("res/image/grid/bgBox.png")
    self.ground=nil
    self.sea=nil
    self.skybox=nil
    self:setSize(mapManager.map.gridSize,mapManager.map.gridSize)
    
end

function bgBox:update(dt)
    
end

function bgBox:draw()
    bgBox.super.destroy(self)
    self.skybox:draw()
    self.sea:draw()
    self.ground:draw()
end

return bgBox