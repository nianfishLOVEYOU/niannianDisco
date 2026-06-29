local artal = require("src.common.artal.artal")

local item = require "src.item.item"

local PsdData = item:extend()

function PsdData:init(path)
    self.sortimgs = artal.newPSD(path)
    self.imgs = {}
    for i = 1, #self.sortimgs do
        local name = self.sortimgs[i].name
        self.imgs[name] = self.sortimgs[i]
        self.imgs[name].visiable = true
        self.imgs[name].x = self.imgs[name].ox -- ox为位置备份
        self.imgs[name].y = self.imgs[name].oy

        --print("加载pad图片" .. name)
    end

    -- 树化
    self.sortTree = buildLayerTree(self.sortimgs)
    self.imgsTree = {}
    for i = 1, #self.sortTree do
        local name = self.sortTree[i].name
        self.imgsTree[name] = self.sortTree[i]
        self.imgsTree[name].visiable = true
        self.imgsTree[name].x = self.sortTree[i].ox -- ox为位置备份
        self.imgsTree[name].y = self.sortTree[i].oy

        --print("加载pad图片" .. name)
    end
    self.baseW = self.sortimgs.width
    self.baseH = self.sortimgs.height
    self.w = self.baseW
    self.h = self.baseH
    print(self.w, self.h, "加载pad图片完成")
    self.scale = 1
end

-- function PsdData:setScale(scaleW, scaleH)
--     scaleW = scaleW or 1
--     scaleH = scaleH or scaleW
--     self.w = self.w * scaleW
--     self.h = self.h * scaleH
-- end

function PsdData:getDrawScale()
    local baseW = (self.baseW and self.baseW ~= 0) and self.baseW or self.w
    local baseH = (self.baseH and self.baseH ~= 0) and self.baseH or self.h
    if not baseW or baseW == 0 then
        baseW = 1
    end
    if not baseH or baseH == 0 then
        baseH = 1
    end

    local sx = (self.w and self.w ~= 0) and (self.w / baseW) or 1
    local sy = (self.h and self.h ~= 0) and (self.h / baseH) or 1
    return sx, sy
end

function PsdData:getLayer(layerName)
    if self.imgs[layerName] then
        return self.imgs[layerName]
    elseif self.imgsTree[layerName] then
        return self.imgsTree[layerName]
    end

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

local function drawImgTree(x, y, sortTree)
    for _, layer in ipairs(sortTree) do
        if layer.visiable then
            if layer.type == "folder" then
                local newx, newy = x + layer.x, y + layer.y
                drawImgTree(newx, newy, layer.layers)
            elseif layer.type == "image" then
                love.graphics.draw(layer.image, x, -- Position X
                y, -- Position Y
                nil, -- Rotation
                nil, -- Scale X
                nil, -- Scale Y
                layer.x, -- Offset X
                layer.y) -- Offset Y
            end

        end
    end
end

function PsdData:draw()
    love.graphics.setColor(1, 1, 1)
    -- for _, layer in ipairs(self.sortimgs) do
    --     if layer.visiable then

    --         love.graphics.draw(layer.image, self.x, -- Position X
    --         self.y, -- Position Y
    --         nil, -- Rotation
    --         nil, -- Scale X
    --         nil, -- Scale Y
    --         layer.x, -- Offset X
    --         layer.y) -- Offset Y
    --     end
    -- end
    local sx, sy = self:getDrawScale()
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.scale(sx, sy)
    drawImgTree(0, 0, self.sortTree)
    love.graphics.pop()
end

return PsdData
