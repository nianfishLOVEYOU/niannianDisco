
local ui = require "src.ui.ui"

local nianocUI = ui:extend()

function nianocUI:init()
    self:refresh()

    self.nianImage = love.graphics.newImage("res/image/nianPlayer.png")
    
    self:setLocalPos(love.graphics.getWidth()-180, love.graphics.getHeight()-320)
end

-- 更新播放列表显示
function nianocUI:refresh()
    self:clearStacks()

end

function nianocUI:update(dt)
end

function nianocUI:onClick(x,y,button)
    --点击图片位置
    if x >= self.x and x <= self.x + self.nianImage:getWidth() * 0.5 and y >= self.y and y <= self.y + self.nianImage:getHeight() * 0.5 then
        print("点击了nian接待员")
    end
end

function nianocUI:_nianStateChange(state)
    -- 根据状态改变nian的表情或动作
    if state == "happy" then
        -- 切换到开心的表情
        self.nianImage = love.graphics.newImage("res/image/nianPlayer_happy.png")
    elseif state == "sad" then
        -- 切换到伤心的表情
        self.nianImage = love.graphics.newImage("res/image/nianPlayer_sad.png")
    else
        -- 默认表情
        self.nianImage = love.graphics.newImage("res/image/nianPlayer.png")
    end
    
end

function nianocUI:_nianClickAnimation()
    
end

function nianocUI:_nianSpeakAnimation()
    
end

function nianocUI:_nianHappyAnimation()
    
end

function nianocUI:draw()
    self:drawStacks()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.nianImage, self.x, self.y, 0, 0.5, 0.5)
end

function nianocUI:destroy()
    nianocUI.super.destroy(self)
end

return nianocUI
