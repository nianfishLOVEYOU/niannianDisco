
local ui = require "src.ui.ui"

local PlayerlistUI = ui:extend()  

function PlayerlistUI:init()
    self:refresh()

end

local waittime = os.time()
function PlayerlistUI:update(dt)
    if os.time() - waittime > 1 then
        self:refresh()
        waittime=os.time()
    end
end
---------------播放列表------------

-- 更新播放列表显示
function PlayerlistUI:refresh()
    -- 创建本地列表
    self:clearStacks()
    
    self:addStack(self:getvstack())

end

-- 获得播放列表ui
function PlayerlistUI:getvstack()

    local vstackchild = {}

    local roomguy = Glove.VStack:new( {Glove.Text:new("房间里的小伙伴:",0)})
    for k, v in pairs(network.peers) do
        roomguy:addChild(Glove.Text:new("小比噶" .. k))
    end
    roomguy:layout()

    roomguy:setPos(50,30,self.z)
    return roomguy
end

return PlayerlistUI
