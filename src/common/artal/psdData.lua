local artal = require("src.common.artal.artal")

local item = require "src.item.item"

local PsdData = item:extend()

function PsdData:init(path)
    self.img = artal.newPSD(path)
    for i = 1, #self.img do
        self.img[i].visiable = true
        print("加载pad图片" .. self.img[i].name)
    end
    -- self.w = self.img[2].image:getWidth()
    -- self.h = self.img[2].image:getHeight()
end

function PsdData:getLayer(layerName)
    for k, layer in pairs(self.img) do
        if layer.name == layerName then
            return layer
        end
    end
    return nil
end


function PsdData:setLayerVisiable(layerName, visiable)
    for k, layer in pairs(self.img) do
        if layer.name == layerName then
            layer.visiable = visiable
            break
        end
    end
    self.visiable = visiable
end

function PsdData:allVisiable(boo)
    for i = 1, #self.img do
        self.img[i].visiable = boo
    end
end

function PsdData:draw()
    love.graphics.setColor(1, 1, 1)
    for i = 1, #self.img do
        if self.img[i].visiable then
            love.graphics.draw(self.img[i].image, self.x, -- Position X
            self.y, -- Position Y
            nil, -- Rotation
            nil, -- Scale X
            nil, -- Scale Y
            self.img[i].ox, -- Offset X
            self.img[i].oy) -- Offset Y
        end
    end
end

return PsdData
