--audio.localplaylist内的每个成员都有一个listBox  
--地图的map存储方式还要再加一个动态物品.listBox 之类的的位置

local bodyItem = require "src.item.bodyItem"

local playListBox = bodyItem:extend()

function playListBox:init( imgPath, bodyInfo)
    -- 初始化子类特有属性
    self.type="playListBox"
end

function playListBox:interact(player)
    
end

return playListBox