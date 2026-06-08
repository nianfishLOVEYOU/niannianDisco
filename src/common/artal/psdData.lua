local artal = require("src.common.artal.artal")

local item = require "src.item.item"

local PsdData = item:extend()

function PsdData:init(path)
    self.sortimgs = artal.newPSD(path)
    self.imgs={}
    for i = 1, #self.sortimgs do
        local name = self.sortimgs[i].name
        self.imgs[name] = self.sortimgs[i]
        self.imgs[name].visiable = true
        self.imgs[name].x=self.imgs[name].ox --ox为位置备份
        self.imgs[name].y=self.imgs[name].oy
        
        print("加载pad图片" .. name)
    end
    -- self.w = self.img[2].image:getWidth()
    -- self.h = self.img[2].image:getHeight()
end

function PsdData:getLayer(layerName)
    return self.imgs[layerName]
end


function PsdData:setLayerVisiable(layerName, visiable)
    local layer = self:getLayer(layerName)
    if layer then
        layer.visiable = visiable
    end
end

function PsdData:allVisiable(boo)
    for _, layer in ipairs(self.sortimgs) do
        layer.visiable = boo
    end
end

function PsdData:draw()
    love.graphics.setColor(1, 1, 1)
    for _, layer in ipairs(self.sortimgs) do
        if layer.visiable then
            love.graphics.draw(layer.image, self.x, -- Position X
            self.y, -- Position Y
            nil, -- Rotation
            nil, -- Scale X
            nil, -- Scale Y
            layer.x, -- Offset X
            layer.y) -- Offset Y
        end
    end
end

return PsdData
