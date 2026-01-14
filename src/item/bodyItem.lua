-- bodyItem.lua
local imageItem = require "src.item.imageItem"
local bodyItem = imageItem:extend()

function bodyItem:init( imgPath, bodyInfo)
    -- 初始化子类特有属性
    self.type = "bodyItem"
    self.bodyInfo=bodyInfo
    self.colw, self.colh = self.w, self.h
    self.body, self.fixture, self.shape = setBody(0, 0, self.w, self.h, 0, -0.5, bodyInfo)
end

function bodyItem:setBody(w,h, AnchorX, AnchorY, bodyInfo)
    self:destoryBody()
    self.bodyInfo=bodyInfo
    self.autoBody=false
    AnchorX = AnchorX or 0
    AnchorY = AnchorY or -0.5
    self.body, self.fixture, self.shape = setBody(self.x, self.y, w, h, AnchorX, AnchorY, bodyInfo)
end

function bodyItem:setSize(w,h)
    bodyItem.super.setSize(self,w,h)
    if self.autoBody then
        self:setBody(w,h, 0, -0.5,self.bodyInfo)
    end
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
