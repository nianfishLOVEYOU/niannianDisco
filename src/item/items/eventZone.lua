local bodyItem = require "src.item.bodyItem"

local EventZone = bodyItem:extend() -- 子类继承父类
function EventZone:init( imgPath, onInteract)
    self:setSize(100,100)
    -- 初始化子类特有属性
    self.type="eventZone"
    
    self.image.depth=0
    self.image.depthByY=false
end

--打开拖入ui
function EventZone:openMusicUI()
    print(" openMusicUI ")
    if(not uiManager:getUI("musicInputUI")) then
        local musicInputUI = require("src.ui.musicInputUI"):new()
        uiManager:addUI("musicInputUI",musicInputUI)
    end
end

return EventZone