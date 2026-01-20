local cameraManager ={}

---设置摄像机
pixSize = 4
-- 参数：left, top, width, height（世界边界）
cameraManager.cam =  camera.new(-2000, -2000, 4000, 4000) -- 这里把整个游戏地图设为 2000×2000
-- 若想让摄像机只占屏幕的一部分（比如 UI 区域），可以限制窗口：
cameraManager.cam:setWindow(0, 0, 600, 450) -- 只在左上 800×600 区域绘制
cameraManager.cam:setScale(0.7)

-- -- 创建离屏画布，尺寸与窗口相同
-- canvas = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight())


return cameraManager