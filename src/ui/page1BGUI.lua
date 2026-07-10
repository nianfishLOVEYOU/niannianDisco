-- 聊天界面
-- 粘的立绘
-- 目前在播放的歌,歌单界面
local json = require "lib.json"
local ui = require "src.ui.ui"

local page1BGUI = ui:extend()

function page1BGUI:init()
    self:refresh()
    self.z=0
end

-- 更新播放列表显示
function page1BGUI:refresh()
    self:clearStacks()
    --self:buildBg()
end

function page1BGUI:buildBg()
    --print("buildBg111111111111111111")
    local width, height = love.graphics.getDimensions()
    local bg = Glove.Image:new("res/image/ui/pageControlBg.png")
    bg:setSize(width, height)
    bg:setPos(0, 0)
    bg.active=false
    local stack = Glove.VStack:new({ bg }, 0)
    self:addStack(stack)
end


function page1BGUI:update(dt)

end


function page1BGUI:destroy()
    page1BGUI.super.destroy(self)
end

return page1BGUI
