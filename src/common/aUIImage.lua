local anchoredImage = require "src.common.anchoredImage"

local UiAnchoredImage = anchoredImage:extend()


-- 绘制函数（核心：计算锚点偏移）
function UiAnchoredImage:draw()
    -- 计算实际的缩放系数（正数为正常，负数为镜像）
    local scaleX = self.w / self.originalW
    local scaleY = self.h / self.originalH
    if self.flipX then
        scaleX = -scaleX
    end
    if self.flipY then
        scaleY = -scaleY
    end

    if self.depthByY then
        local _, sy = cam:toScreen(0, self.y)
        self.depth = sy / love.graphics.getHeight()
        --print(self.depth)
        self.depth = self.depth > 1 and 1 or self.depth
        self.depth = self.depth < 0 and 0 or self.depth
    end

    local drawInfo = {
        type = "draw",
        parameters = {},
        depth = self.depth,
        color = self.color,
        z = self.z,
        layer = self.layer
    }

    love.graphics.setColor(1, 1, 1, 1)
    if (self.quad) then
        local qx, qy, qw, qh = self.quad:getViewport()
        -- 锚点偏移量 = 锚点比例 * 当前尺寸
        local offsetX = self.anchorX * qw
        local offsetY = self.anchorY * qh

        love.graphics.draw(self.img, self.quad, self.x, self.y, self.rotation, scaleX, -- X 缩放（可能为负）
            scaleY,                                                                    -- Y 缩放（可能为负）
            offsetX, offsetY                                                           -- 锚点偏移，保持锚点在 (self.x,self.y)
        )
    else
        -- 锚点偏移量 = 锚点比例 * 当前尺寸
        local offsetX = self.anchorX * self.originalW
        local offsetY = self.anchorY * self.originalH
        love.graphics.draw(self.img, self.x, self.y, self.rotation, scaleX,         -- X 缩放（可能为负）
            scaleY,                                                                 -- Y 缩放（可能为负）
            offsetX, offsetY                                                        -- 锚点偏移，保持锚点在 (self.x,self.y)
        )
    end
end


return UiAnchoredImage
