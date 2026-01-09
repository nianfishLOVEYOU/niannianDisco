-- Item.lua
local class = require "src.common.class"
local item = class:extend()

--gc执行句柄
item.__gc = function(u)
    print("Cleaning up resources for", u)
end

function item:init(x, y, w, h)
    self.id = ""
    self.type = "item"

    self.x, self.y = x, y
    self.z = 0

    self.localX, self.localY = 0, 0 --和父母的相对位置，用来区别普通位置
    self.localZ = 0

    self.layer = 0.2
    local id = globleManager:guid()
    self:setId(id)
    self.w, self.h = w, h
    self.scaleW, self.scaleH = 1, 1
    self.color = { 1, 1, 1 }
    self.component = {}
    self.visiable = true
    --父对象
    self.parent = nil
    --子对象
    self.children = {}

    --清理方法
end

function item:setParent(parent)
    self.parent = parent
    self.localX = self.x - parent.x
    self.localY = self.y - parent.y
end

function item:addChild(child)
    self.children[child.id] = child
end

function item:removeChild(id)
    self.children[id] = nil
end

function item:addComponent(name)

end

function item:removeComponent(name)

end

--点击事件
function item:onClick(x, y, button)

end

--被拖拽
function item:onDrag(x, y, dx, dy)

end

--悬停
function item:onHold(x, y)

end

function item:setId(id)
    self.id = id
end

function item:setLocalPos(x, y, z)
    if self.parent then
        local px, py, pz = self.parent:getPos()
        self.x, self.y = px + x, py + y
        self.z = z and pz + z or self.z + pz

        self.localX, self.localY = x, y
        self.localZ = z or 0
    end
end

function item:isOver(mouseX, mouseY)
    local width, height = self:getSize()
    return self.x <= mouseX and mouseX <= self.x + width and
        self.y <= mouseY and mouseY <= self.y + height
end

function item:setPos(x, y, z)
    self.x, self.y = x, y
    self.z = z or self.z
end

function item:getPos()
    return self.x, self.y, self.z
end

function item:getScale()
    return self.scaleW, self.scaleH
end

function item:setScale(scaleW, scaleH)
    self.scaleW, self.scaleH = scaleW, scaleH
end

-- 设置尺寸（缩放时锚点位置不变）
function item:setSize(w, h)
    self.w = w
    self.h = h
end

function item:getSize()
    return self.w * self.scaleW, self.h * self.scaleH
end

function item:update(dt)

end

function item:draw()
    local x, y = self:getPos()
    love.graphics.setColor(self.color)
    love.graphics.rectangle('fill', x - self.w * self.scaleW / 2, y - self.h * self.scaleW / 2, self.w * self.scaleW,
        self.h * self.scaleW)
end

-- 确保没有被引用了
function item:destroy()
    if self.__destroyed then return end
    self.__destroyed = true
end

return item
