-- bodyItem.lua
local spriteAnimation = require "src.common.spriteAnimation"
local item = require "src.item.item"

local imageItem = item:extend();

function imageItem:init(imgPath)
    -- 初始化子类特有属性
    self.type = "imageItem"
    --是否切片 是否动画
    self.isQuid = false
    self.isQuidAnimation = false
    -- 加载自定义图片 用动画播放图片，随时可转图片
    if imgPath and imgPath ~= "" then
        self.image = spriteAnimation:new(imgPath, 0, 0, 0.5, 1)
        -- 如果w h都为0则使用图片尺寸
        if self.w == 0 then
            self.w = self.image.originalW 
        end
        if self.h == 0 then
            self.h = self.image.originalH 
        end
    else
        self.image = spriteAnimation:new("res/image/nian.png", 0, 0, 0.5, 1)
        self.w = self.image.originalW 
        self.h = self.image.originalH 
    end
end

function imageItem:setSize(w,h)
    if self.isQuid then
        return 
    end
    self.image:setSize(w,h)
    self.w = w
    self.h = h
end


function imageItem:isOver(mouseX, mouseY)
    -- 0.5，1的偏移是否包含
    local w,h=self:getSize()
    local xin=mouseX >= self.x- w /2 and mouseX <= self.x + w /2
    local yin=mouseY >= self.y -h and mouseY <= self.y 
    return xin and yin
end

function imageItem:setAnchor(AnchorX, AnchorY)
    self.image:setAnchor(AnchorX, AnchorY)
end

-- 初始化动画
function imageItem:setQuadAnimation(frameW, frameH, frameCount, frameDuration)
    self.isQuid=true
    self.image:setQuadAnimation(frameW, frameH, frameCount, frameDuration)
    self.w,self.h =self.image:getSize()
    print(self.type,self.x,self.y,self.w,self.h,self.image.frameWidth,self.image.frameHeight)
end

function imageItem:setImage(imgPath, w, h)
    self.isQuid=false
    if imgPath ~= "" then
        self.image = spriteAnimation:new(imgPath, self.x, self.y, 0.5, 1)
        self.w = w or self.image.originalW 
        self.h = h or self.image.originalH 
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
