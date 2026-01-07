local anchoredImage = require "src.common.anchoredImage"

local UiAnchoredImage = anchoredImage:extend()

-- 绘制函数（核心：计算锚点偏移）
function UiAnchoredImage:draw()
    -- 计算实际的缩放系数（正数为正常，负数为镜像）
    local scaleX = self.width / self.originalW
    local scaleY = self.height / self.originalH
    if self.flipX then
        scaleX = -scaleX
    end
    if self.flipY then
        scaleY = -scaleY
    end

    love.graphics.setColor(self.color)
    if (self.quad) then
        local qx, qy, qw, qh = self.quad:getViewport()
        -- 锚点偏移量 = 锚点比例 * 当前尺寸
        local offsetX = self.anchorX * qw
        local offsetY = self.anchorY * qh

        love.graphics.draw(self.img, self.quad, self.x, self.y, self.rotation, scaleX, -- X 缩放（可能为负）
        scaleY, -- Y 缩放（可能为负）
        offsetX, offsetY -- 锚点偏移，保持锚点在 (self.x,self.y)
        )

    else
        -- 锚点偏移量 = 锚点比例 * 当前尺寸
        local offsetX = self.anchorX * self.originalW
        local offsetY = self.anchorY * self.originalH
        love.graphics.draw(self.img, self.x, self.y, self.rotation, scaleX, -- X 缩放（可能为负）
        scaleY, -- Y 缩放（可能为负）
        offsetX, offsetY -- 锚点偏移，保持锚点在 (self.x,self.y)
        )

    end
    love.graphics.setColor(1, 1, 1, 1)
end

return UiAnchoredImage