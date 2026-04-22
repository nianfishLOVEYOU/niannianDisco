-- 专门用来检测错误
local debugManager = require("src.manager.debugManager")

-- 第二步：初始化全局错误捕获
debugManager.init()

nianDebug = {}

-- 显示碰撞体积
local function printCol()
    love.graphics.setColor(0, 1, 0, 0.3)
    love.graphics.setLineWidth(2)

    for _, body in ipairs(world:getBodies()) do
        for _, fixture in ipairs(body:getFixtures()) do
            local shape = fixture:getShape()
            local shapeType = shape:getType()

            if shapeType == "circle" then
                -- 圆心在局部坐标 (0,0)，需要转成世界坐标
                local x, y = body:getWorldPoints(shape:getPoint())
                local radius = shape:getRadius()
                love.graphics.circle("line", x, y, radius)
            elseif shapeType == "polygon" then
                -- shape:getPoints() 返回局部坐标序列
                local points = {body:getWorldPoints(shape:getPoints())}
                love.graphics.polygon("line", points)
            elseif shapeType == "edge" then
                local points = {body:getWorldPoints(shape:getPoints())}
                love.graphics.line(points)
            end
        end
    end
end

local function debugPrintUi()
    love.graphics.setLineWidth(2)

    for _, widget in pairs(Glove.widgets) do
        love.graphics.setColor(0, 1, 0, 0.3) -- 白色轮廓
        if widget.type == "VStack" then
            love.graphics.setColor(1, 1, 0, 0.5)
        end
        if widget.type == "HStack" then
            love.graphics.setColor(0, 1, 1, 0.3)
        end
        local x, y = widget:getPos()
        local w, h = widget:getSize()
        if not w or not h then
            -- print("!!!!!!" ,widget.type,widget.name,widget.x,widget.y,widget.w,widget.h)
        end
        love.graphics.rectangle("line", x, y, w, h)
    end
end

-- debug 输出
function nianDebug.DebugPrint()
    -- 显示碰撞体积
    if globleManager.getConfig("debug","showDebugData") then
        -- 计算 FPS
        local fps = love.timer.getFPS()
        love.graphics.setColor(1, 1, 0)
        love.graphics.print("FPS: " .. fps, 10, 10)
        -- love.graphics.print("音乐声值："..audio:getMusicSpectrum())
        love.graphics.setColor(1, 1, 1)
        -- 显示鼠标位置
        if love.mouse.isDown(2) then
            local x, y = love.mouse.getPosition()
            local wx, wy = cameraManager.cam:toWorld(x, y)
            love.graphics.setColor(1, 0, 0)
            love.graphics.circle("fill", x, y, 3)
            love.graphics.setColor(1, 1, 1)

            love.graphics.print("mouse screen: " .. x .. "," .. y, x + 10, y - 10)
            love.graphics.print("mouse world: " .. wx .. "," .. wy, x + 10, y)
        end
    end

    if globleManager.getConfig("debug","showCollision") then
        --------------物理碰撞体积----------------
        cameraManager.cam:draw(printCol)
    end

    if globleManager.getConfig("debug","showUiCollision") then
        --------------ui碰撞体积----------------
        debugPrintUi()
    end

    if globleManager.getConfig("debug","mapEditor_Mode") then
        love.graphics.print("按下b 编辑地图", 10, 20)
    end

    -- 显示深度图
    love.graphics.setColor(1, 1, 1)
    local deepSize = 0.1
    love.graphics.draw(nianDraw.depthCanvas, love.graphics.getWidth() - nianDraw.depthCanvas:getWidth() * deepSize, 0,
        0, deepSize, deepSize)

    debugManager.draw()
end

-- 方法1：在love.update里加帧率监控，判断是否阻塞
local lastTime = 0
function nianDebug.DebugUpdate(dt)
    local currentTime = love.timer.getTime()
    -- 若两次update间隔超过0.5秒，说明主线程被阻塞
    if currentTime - lastTime > 0.5 then
        print("[nianDebug]主线程阻塞！间隔：" .. (currentTime - lastTime) .. "秒")
    end
    lastTime = currentTime

    -- 【重点检查】你的业务逻辑是否有无限循环/耗时操作
    -- 错误示例：while true do end （绝对不能写）
    -- 错误示例：大量for循环计算（比如10万次循环）
end

-- 打印完整的调用堆栈（模仿报错格式）
function nianDebug.printStackTrace(message)
    -- 如果传入了自定义消息，先打印消息
    if message then
        print("=== 调用堆栈信息: " .. message .. " ===")
    else
        print("=== 调用堆栈信息 ===")
    end

    -- 获取完整堆栈信息（skip=2 跳过当前函数本身，让堆栈从调用者开始）
    local stackTrace = debug.traceback("", 2)
    -- 打印堆栈（和LÖVE2D原生报错格式完全一致）
    print(stackTrace)
    print("=======================")
end
