-- bodyItem.lua
local imageItem = require "src.item.imageItem"
local bodyItem = imageItem:extend()

function bodyItem:init(x, y, w, h, imgPath, bodyInfo)
    -- 初始化子类特有属性
    self.type = "bodyItem"
    self.colw, self.colh = w, h
    self.body, self.fixture, self.shape = setBody(x, y, self.w, self.h, 0, -0.5, bodyInfo)
end

function bodyItem:setBody(w, h, AnchorX, AnchorY, bodyInfo)
    self:destoryBody()
    w = w or self.w
    h = h or self.h
    AnchorX = AnchorX or 0
    AnchorY = AnchorY or -0.5
    self.body, self.fixture, self.shape = setBody(self.x, self.y, w, h, AnchorX, AnchorY, bodyInfo)
end

function bodyItem:setPos(x, y, z)
    self.z = z or 0
    self.body:setPosition(x, y)
end

function bodyItem:getPos()
    local x, y = self.body:getPosition()
    return x, y, self.z
end

function bodyItem:update(dt)
    self.x, self.y = self:getPos()
end

function bodyItem:destoryBody()
    if self.body then
        self.body:destroy()
    end

    -- 2. 释放 shape
    if self.shape then
        self.shape:release()
    end

    self.body = nil
    self.fixture = nil
    self.shape = nil
end

-- 确保没有被引用了
function bodyItem:destroy()
    bodyItem.super.destroy(self)
    self:destoryBody()
end

return bodyItem
