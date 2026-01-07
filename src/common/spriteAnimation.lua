local image = require "src.common.anchoredImage"
local SpriteAnimation = image:extend()

function SpriteAnimation:init(path, x, y, anchorX, anchorY, frameW, frameH, frameCount, frameDuration)
    frameW = frameW or 1
    frameH = frameH or 1
    frameCount = frameCount or 1
    frameDuration = frameDuration or 1

    self.currentFrame = 1
    self.elapsedTime = 0
    --如果没有定义自然就不播放只有一张图
    self:setQuadAnimation(frameW, frameH, frameCount, frameDuration)

end

-- -- 按比例缩放（基于原始尺寸）
-- function SpriteAnimation:setScale(scaleX, scaleY)
--     scaleY = scaleY or scaleX -- 等比缩放
--     self.w = self.originalW * scaleX
--     self.h = self.originalH * scaleY
-- end

function SpriteAnimation:setQuadAnimation( frameW, frameH, frameCount, frameDuration)
    self.frameCount = frameCount
    self.frameDuration = frameDuration
    self.frameWidth = self.originalW / frameW
    self.frameHeight = self.originalH / frameH

    self.quads = {}
        -- 创建Quad切割序列
    for i = 0, frameCount - 1 do
        table.insert(self.quads, love.graphics.newQuad(
            (i % (self.originalW / self.frameWidth)) * self.frameWidth,
            math.floor(i / (self.originalW / self.frameWidth)) * self.frameHeight,
            self.frameWidth, self.frameHeight,
            self.originalW, self.originalH
        ))
    end
end

function SpriteAnimation:update(dt)
    if self.frameCount == 1 or self.frameCount == 0 then
        return
    end
    self.elapsedTime = self.elapsedTime + dt
    if self.elapsedTime >= self.frameDuration then
        self.currentFrame = (self.currentFrame % self.frameCount) + 1
        self.elapsedTime = self.elapsedTime - self.frameDuration
    end

    self:setQuid(self.quads[self.currentFrame])
end

return SpriteAnimation
