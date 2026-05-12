local item = require "src.item.item"

local nianPlayer = item:extend()

function nianPlayer:init()

    self.nianImage = love.graphics.newImage("res/image/nianPlayer.png")
    -- 初始化子类特有属性
    self.type="nianPlayer"
    self.layer =0
    self.z=0
    --生成nian图片
end

function nianPlayer:update(dt)
    local screenx, screeny = love.graphics.getWidth()-200, love.graphics.getHeight()-300
    local targetx, targety = cameraManager.cam:toWorld(screenx, screeny)
    self:setPos(targetx, targety)
end

function nianPlayer:draw()
    love.graphics.draw(self.nianImage, self.x, self.y, 0, 1, 1, self.nianImage:getWidth()/2, self.nianImage:getHeight()/2)

    
end

return nianPlayer