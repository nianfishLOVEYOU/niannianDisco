
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

    local title = Glove.HStack:new( {Glove.Text:new("房间里的小伙伴:",0)})
    table.insert(vstackchild, title)

    for k, v in pairs(network.peers) do
        --local hstack = Glove.HStack:new({Glove.Text:new("小比噶" .. k)})
        table.insert(vstackchild, hstack)
    end
    local stack = Glove.VStack:new(vstackchild ,30)

    stack:setPos(50,30,self.z)
    return stack
end

return PlayerlistUI
