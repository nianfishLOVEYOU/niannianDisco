local item = require "src.item.bodyItem"

local EventZone = {}
EventZone.__index = EventZone
setmetatable(EventZone, {
    __index = item
}) -- 子类继承父类
function EventZone:new(x,y,sizew,sizeh, imgPath, onInteract)
    local obj = item:new(x , y , 200, 200, "res/image/ui/add.png",{sensor=true}) -- 先走父类构造
    setmetatable(obj, EventZone) -- 再把实例的元表改为子类
    -- 初始化子类特有属性
    obj.type="eventZone"
    obj.color = {1,1,1} 
    obj:setInteract(function ()
        EventZone:openMusicUI()
    end)
    obj.image.depth=0
    obj.image.depthByY=false
    return obj
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