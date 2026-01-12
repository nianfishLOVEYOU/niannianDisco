local colors = require "glove/colors"
local enet = require "enet"
local ui = require "src.ui.ui"

local PlayerlistUI = {}
PlayerlistUI.__index = PlayerlistUI
setmetatable(PlayerlistUI, {
    __index = ui
}) -- 子类继承父类
function PlayerlistUI:new(...)
    local obj = ui:new(...) -- 先走父类构造
    setmetatable(obj, PlayerlistUI) -- 再把实例的元表改为子类
    -- 初始化子类特有属性
    return obj
end

function PlayerlistUI:init()
    self:refresh()

end

local waittime = os.time()
function PlayerlistUI:update(dt)
    if os.time() - waittime > 1 then
        PlayerlistUI:refresh()
    end
end
---------------播放列表------------

-- 更新播放列表显示
function PlayerlistUI:refresh()
    -- 创建本地列表
    if self.stack then
        self.stack:destroy()
    end
    self.stack = self:getvstack()
    self.posx = 50
    self.posy = 30

end

-- 获得播放列表ui
function PlayerlistUI:getvstack()

    local vstackchild = {}

    local title = Glove.HStack:new(0,0,0,0, {Glove.Text:new(0,0,0,0,"房间里的小伙伴:")})
    table.insert(vstackchild, title)

    for k, v in pairs(network.peers) do
        local name = Glove.Text:new(0,0,0,0,"小比噶" .. k)
        local hstack = Glove.HStack:new(0,0,0,0,{name})
        table.insert(vstackchild, hstack)
    end
    local stack = Glove.VStack:new(0,0,0,0,vstackchild ,30)
    return stack
end

return PlayerlistUI
