
local ui = require "src.ui.ui"
local psdData = require "src.common.artal.psdData"
local nianocUI = ui:extend()

function nianocUI:init()
    self:refresh()

    --self.nianImage = love.graphics.newImage("res/image/nianPlayer.png")
    --自己的位置跟着父亲走
    self:setLocalPos(love.graphics.getWidth()-230, love.graphics.getHeight()-420)

    -- 1. 创建Mesh（ID: test_mesh，位置(100,100)，尺寸200x200）
    -- local nianMeshId= meshAnimator:createMesh("res/image/nianPlayer.png", 200, 200, self.nianImage:getWidth()/2, self.nianImage:getHeight()/2,"res/image/nianPlayer.png")
    -- self.nianMesh = meshAnimator:getMeshData(nianMeshId).mesh
    --pendulumSystem:bindMesh(meshAnimator:getMeshData(nianMeshId),200,200)

    self:_newNian()
end

function nianocUI:_newNian()
    self.psdData = psdData:new("res/image/nian/nian.psd")
    self.psdData:setPos(self.x, self.y)
    self:_ani_idle()
    
end

-- 更新播放列表显示
function nianocUI:refresh()
    self:clearStacks()

end

function nianocUI:update(dt)

end

function nianocUI:onClick(x,y,button)
    --点击图片位置
    if x >= self.x and x <= self.x + 400 * 0.5 and y >= self.y and y <= self.y + 500 * 0.5 then
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

function nianocUI:_clear() --无脸基础体
    self.psdData:allVisiable(false)
    self.psdData:getLayer("body1").visiable=true
    self.psdData:getLayer("hand_Left2").visiable=true
    self.psdData:getLayer("clothes").visiable=true
    self.psdData:getLayer("hear_Down").visiable=true
    self.psdData:getLayer("head").visiable=true
    self.psdData:getLayer("ear").visiable=true
    self.psdData:getLayer("eyebrow").visiable=true
end

function nianocUI:_ani_idle()
    self:_clear()
    self.psdData:getLayer("mouseClose").visiable=true
    self.psdData:getLayer("eye_OpenRight").visiable=true
    self.psdData:getLayer("body1").visiable=true

end

function nianocUI:_ani_speak()
    
end

function nianocUI:_ani_happy()
    
end

function nianocUI:draw()
    --画一个自己的正方体
    --love.graphics.setColor(1,0,0)
    --love.graphics.rectangle("fill",self.x,self.y,200,300)

    self:drawStacks()
    self.psdData:draw()
end

function nianocUI:destroy()
    nianocUI.super.destroy(self)
end

return nianocUI
