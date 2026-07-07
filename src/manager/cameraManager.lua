local camera = require("lib.gamera")

local cameraManager = {}

systemManager:update_regester(function(dt)
    cameraManager:update(dt)
end)
---设置摄像机
pixSize = 4
local t = 0.1
-- 参数：left, top, width, height（世界边界）
cameraManager.cam = camera.new(-2000, -2000, 4000, 4000) -- 这里把整个游戏地图设为 2000×2000
-- 若想让摄像机只占屏幕的一部分（比如 UI 区域），可以限制窗口：
cameraManager.cam:setWindow(0, 0, love.graphics.getWidth(), love.graphics.getHeight()) -- 只在左上 800×600 区域绘制

cameraManager.cam:setScale(0.6)

local targetPos = {
    x = 0,
    y = 0
}

local gotoTarget = false
-- -- 创建离屏画布，尺寸与窗口相同
-- canvas = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight())
function cameraManager:update(dt)
    if gotoTarget then
        local x, y = self.cam:getPosition()
        self.cam:setPosition(lerp(x, targetPos.x, t), lerp(y, targetPos.y, t))
    end
end

function cameraManager:setTarget(x, y)
    targetPos.x = x
    targetPos.y = y
    gotoTarget = true
end

function cameraManager:setPos(x, y)
    self.cam:setPosition(x, y)
    gotoTarget = false
end

return cameraManager
