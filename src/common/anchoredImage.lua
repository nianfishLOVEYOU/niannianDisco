local class = require "src.common.class"
local AnchoredImage = class:extend()

-- 锚点预设（可选，方便快速调用）
AnchoredImage.ANCHOR = {
    CENTER = { 0.5, 0.5 },
    TOP_LEFT = { 0, 0 },
    TOP_RIGHT = { 1, 0 },
    BOTTOM_LEFT = { 0, 1 },
    BOTTOM_RIGHT = { 1, 1 }
}

-- 构造函数
-- @param path 图片路径
-- @param x,y 初始位置
-- @param anchorX,anchorY 锚点比例（0~1，例如0.5,0.5是中心）
function AnchoredImage:init(path, x, y, anchorX, anchorY)
    self.img = resourceManager.loadImage(path)
    if not self.img then 
        print("!ERROR non path ! : "..path)
    end
    self.quad = nil
    -- 原始尺寸
    self.originalW = self.img:getWidth()
    self.originalH = self.img:getHeight()
    -- 当前尺寸（初始为原始尺寸）
    self.w = self.originalW
    self.h = self.originalH
    -- 锚点比例（0~1），默认中心锚点
    self.anchorX = anchorX or 0.5
    self.anchorY = anchorY or 0.5
    -- 物体位置（锚点对应的世界坐标）
    self.x = x or 0
    self.y = y or 0
    self.z = 0
    self.layer = 0
    -- 额外属性：旋转、颜色
    self.rotation = 0
    self.color = { 1, 1, 1, 1 }

    -- **翻转标记**（默认不翻转）
    self.flipX = false -- true → 水平镜像
    self.flipY = false -- true → 垂直镜像
    self.depth = 0
    self.depthByY = true

    return self
end

function AnchoredImage:setAnchor(AnchorX, AnchorY)
    self.anchorX = AnchorX or 0.5
    self.anchorY = AnchorY or 0.5
end

function AnchoredImage:setPos(x, y, z)
    z = z or 0
    self.x, self.y, self.z = x, y, z
end

function AnchoredImage:setLayer(layer)
    self.layer = layer
end

-- 设置尺寸（缩放时锚点位置不变）
function AnchoredImage:setSize(w, h)
    self.w = w
    self.h = h
end

function AnchoredImage:getSize()
    return self.w,self.h
end

function AnchoredImage:setQuid(quad)
    self.quad = quad
end

-- 按比例缩放（基于原始尺寸）
function AnchoredImage:setScale(scaleX, scaleY)
    scaleY = scaleY or scaleX -- 等比缩放
    self.w = self.originalW * scaleX
    self.h = self.originalH * scaleY
end

-- -----------------------------------------------------------------
-- 翻转相关 API
function AnchoredImage:setFlip(flipX, flipY)
    self.flipX = not not flipX -- 强制转成布尔
    self.flipY = not not flipY
end

function AnchoredImage:flipHorizontal()
    self.flipX = not self.flipX
end

function AnchoredImage:flipVertical()
    self.flipY = not self.flipY
end

function AnchoredImage:isFlippedX()
    return self.flipX
end

function AnchoredImage:isFlippedY()
    return self.flipY
end

-- 绘制函数（核心：计算锚点偏移）
function AnchoredImage:draw()
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

    if (self.quad) then
        local qx, qy, qw, qh = self.quad:getViewport()
        -- 锚点偏移量 = 锚点比例 * 当前尺寸
        local offsetX = self.anchorX * qw
        local offsetY = self.anchorY * qh
        drawInfo.parameters = { self.img, self.quad, self.x, self.y, self.rotation, scaleX, scaleY, offsetX, offsetY }
        nianDraw:drawReg(drawInfo)
    else
        -- 锚点偏移量 = 锚点比例 * 当前尺寸
        local offsetX = self.anchorX * self.originalW
        local offsetY = self.anchorY * self.originalH

        drawInfo.parameters = { self.img, self.x, self.y, self.rotation, scaleX, scaleY, offsetX, offsetY }
        nianDraw:drawReg(drawInfo)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

-- 辅助方法：设置锚点
function AnchoredImage:setAnchor(anchorX, anchorY)
    self.anchorX = anchorX
    self.anchorY = anchorY
end

-- 辅助方法：获取当前锚点对应的绘制原点偏移
function AnchoredImage:getAnchorOffset()
    return self.anchorX * self.w, self.anchorY * self.h
end

return AnchoredImage

-- -- 测试示例
-- function love.load()
--     -- 创建中心锚点的图片
--     local imgPath = "test.png" -- 替换成你的图片路径
--     img1 = AnchoredImage.new(imgPath, 400, 300, 0.5, 0.5)
--     -- 创建左上角锚点的图片
--     img2 = AnchoredImage.new(imgPath, 200, 200, 0, 0)
-- end

-- function love.update(dt)
--     -- 按上下键缩放img1，观察锚点（中心）位置不变
--     if love.keyboard.isScancodeDown("up") then
--         img1:setScale(img1.width / img1.originalW + 0.01)
--     elseif love.keyboard.isScancodeDown("down") then
--         img1:setScale(img1.width / img1.originalW - 0.01)
--     end
-- end

-- function love.draw()
--     img1:draw()
--     img2:draw()
--     -- 绘制锚点指示器
--     love.graphics.setColor(1, 0, 0)
--     love.graphics.circle("fill", img1.x, img1.y, 5)
--     love.graphics.circle("fill", img2.x, img2.y, 5)
-- end
