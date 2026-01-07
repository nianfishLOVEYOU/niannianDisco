-- bodyItem.lua
local spriteAnimation = require "src.common.spriteAnimation"
local item = require "src.item.item"

local imageItem = item:extend();

function imageItem:init(x, y, w, h, imgPath)
    -- 初始化子类特有属性
    self.type = "imageItem"
    --是否切片 是否动画
    self.isQuid = false
    self.isQuidAnimation = false
    -- 加载自定义图片 用动画播放图片，随时可转图片
    if imgPath and imgPath ~= "" then
        self.image = spriteAnimation:new(imgPath, x, y, 0.5, 1)
        -- 如果w h都为0则使用图片尺寸
        if self.w == 0 then
            self.w = self.image.originalW * pixSize
        end
        if self.h == 0 then
            self.h = self.image.originalH * pixSize
        end
    end
end

function imageItem:setAnchor(AnchorX, AnchorY)
    self.image:setAnchor(AnchorX, AnchorY)
end

-- 初始化动画
function imageItem:setQuadAnimation(frameW, frameH, frameCount, frameDuration)
    self.image:setQuadAnimation(frameW, frameH, frameCount, frameDuration)
    self.w = self.image.frameWidth * pixSize
    self.h = self.image.frameHeight * pixSize
end

function imageItem:setImage(imgPath, w, h)
    if imgPath ~= "" then
        self.image = spriteAnimation:new(imgPath, self.x, self.y, 0.5, 1)
        self.w = w or self.image.originalW * pixSize
        self.h = h or self.image.originalH * pixSize
    end
end

function imageItem:update(dt)
    self.image:update(dt)
end

function imageItem:draw()
    --有动画状态时候

    self.image:setPos(self:getPos())
    self.image:setSize(self:getSize())
    self.image:setLayer(self.layer)
    self.image:draw()
end

return imageItem
