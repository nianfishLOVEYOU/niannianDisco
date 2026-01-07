local colors = require "glove/colors"
local enet = require "enet"
local ui = require "src.ui.ui"

local WaitingUI = {
    time=0
}
WaitingUI.__index = WaitingUI
setmetatable(WaitingUI, {
    __index = ui
}) -- 子类继承父类
function WaitingUI:new()
    local obj = ui:new() -- 先走父类构造
    setmetatable(obj, WaitingUI) -- 再把实例的元表改为子类

    -- 初始化子类特有属性
    return obj
end


function WaitingUI:init()
    WaitingUI.posx = 100
    WaitingUI.posy = 100
    self.time=0
    WaitingUI:refresh()
    --全局无法操作

end

---------------播放列表------------

function WaitingUI:update(dt)
    self.time=self.time+dt
end

local bgColor = {0, 0, 0,0.8}
local screen = {w = love.graphics.getWidth(), h = love.graphics.getHeight()}

function WaitingUI:draw()
    
    -- 记录当前窗口尺寸
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", 0, 0, screen.w, screen.h)
    
    local msg="waiting...".. self.time
    local textW = myFont:getWidth(msg)
    local textH = myFont:getHeight()
    local x = (screen.w - textW) / 2
    local y = (screen.h - textH) / 2

    love.graphics.setColor({1,1,1})
    love.graphics.print(msg, x, y)
end


return WaitingUI