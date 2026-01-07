-- Item.lua
local class = require "src.common.class"
local item = class:extend()

function item:init(x, y, w, h)
    self.id = ""
    self.type = "item"
    self.x, self.y = x, y 
    self.z=0
    self.layer=0.2
    local id = globleManager:guid()
    self:setId(id)
    self.w, self.h = w, h
    self.scaleW,self.scaleH=1,1
    self.color = { 1, 1, 1 }
    self.component = {}
    self.visiable =true
end


function item:addComponent(name)

end

function item:removeComponent(name)

end


function item:setId(id)
    self.id = id
end

function item:setPos(x, y, z)
    self.x,self.y =x,y
    self.z=z or self.z
end

function item:getPos()
    return self.x,self.y,self.z
end

function item:getScale()
    return self.scaleW,self.scaleH
end

function item:setScale(scaleW,scaleH)
    self.scaleW,self.scaleH=scaleW,scaleH
end


-- 设置尺寸（缩放时锚点位置不变）
function item:setSize(w, h)
    self.w = w
    self.h = h
end

function item:getSize()
    return self.w*self.scaleW,self.h*self.scaleH
end

function item:update(dt)
    
end

function item:draw()
    local x, y = self:getPos()
    love.graphics.setColor(self.color)
    love.graphics.rectangle('fill', x - self.w*self.scaleW / 2, y - self.h*self.scaleW / 2, self.w*self.scaleW, self.h*self.scaleW)
end

-- 确保没有被引用了
function item:destroy()
end

return item
