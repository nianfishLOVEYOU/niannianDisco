nianTool = {}
timer= require "src.common.timer"
animation = require "src.animation"

function nianTool:dump(tbl, indent)
    indent = indent or 0
    local prefix = string.rep("  ", indent)
    for k, v in pairs(tbl) do
        local key = tostring(k)
        if type(v) == "table" then
            print(string.format("%s%s = {", prefix, key))
            dump(v, indent + 1) -- 递归
            print(string.format("%s}", prefix))
        else
            print(string.format("%s%s = %s", prefix, key, tostring(v)))
        end
    end
end

function lerp(a, b, t)
    return a + (b - a) * t -- t∈[0,1]
end

function normalize(x, y)
    -- w、h 为基准宽高，若不传则使用当前窗口尺寸
    local standard = math.sqrt(x * x + y * y)
    return x / standard, y / standard
end

bodyType = {
    dynamic = "dynamic",
    static = "static"
}

-- 默认 static 可以自己定义为
function setBody(x, y, w, h, anchorX, anchorY, bodyInfo)
    bodyInfo = bodyInfo or {}
    bodyInfo.x = x or 0
    bodyInfo.y = y or 0
    bodyInfo.w = bodyInfo.w or w
    bodyInfo.h = bodyInfo.h or h
    bodyInfo.anchorX = bodyInfo.anchorX or anchorX or 0
    bodyInfo.anchorY = bodyInfo.anchorY or anchorY or 0
    bodyInfo.type = bodyInfo.type or "static"
    bodyInfo.tag = bodyInfo.tag or "unknown"
    bodyInfo.friction = bodyInfo.friction or 0
    bodyInfo.sensor = not not bodyInfo.sensor
    -- 物理
    local body = love.physics.newBody(world, bodyInfo.x, bodyInfo.y, bodyInfo.type) -- 世界, 位置, 类型
    local shape = love.physics.newRectangleShape(bodyInfo.w * bodyInfo.anchorX, bodyInfo.h * bodyInfo.anchorY,
        bodyInfo.w, bodyInfo.h) -- 相对刚体的偏移和尺寸
    local fixture = love.physics.newFixture(body, shape, 1) -- 刚体, 形状, 密度
    fixture:setFriction(bodyInfo.friction) -- 摩擦力
    body:setPosition(bodyInfo.x, bodyInfo.y)
    body:setFixedRotation(true)
    fixture:setSensor(bodyInfo.sensor)
    return body, fixture, shape
end

function DebugPrint()
    love.graphics.setColor(1, 0, 0)

    -- 计算 FPS
    local fps = love.timer.getFPS()
    -- 在屏幕左上角显示 FPS
    love.graphics.print("FPS: " .. fps, 10, 10)

    love.graphics.setColor(1, 1, 1)

    if love.mouse.isDown(2) then
        local x, y = love.mouse.getPosition()
        local wx,wy = cam:toWorld(x,y)
        love.graphics.setColor(1, 0, 0)
        love.graphics.circle("fill", x, y,3)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("mouse screen: " .. x ..","..y, x+10, y-10)
        love.graphics.print("mouse world: " .. wx ..","..wy, x+10, y)
    end
end

function printCol()
    love.graphics.setColor(0, 1, 0) -- 白色轮廓
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

function debugPrintUi()
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

-- 打印完整的调用堆栈（模仿报错格式）
function printStackTrace(message)
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

-- 核心工具函数：判断鼠标是否点击到指定Body（兼容任意旋转角度）
function isBodyClicked(body, mx, my)
    -- 遍历刚体上的所有碰撞体
    for _, fixture in ipairs(body:getFixtureList()) do
        local shape = fixture:getShape()
        local shapeType = shape:getType()

        -- 关键：获取形状在「物理世界坐标」下的顶点（已自动包含旋转/位移）
        local worldPoints = {body:getWorldPoints(shape:getPoints())}

        if shapeType == "rectangle" then
            -- 旋转后的矩形：用多边形射线法检测（不再用轴对齐边界）
            if isPointInPolygon(mx, my, worldPoints) then
                return true
            end

        elseif shapeType == "circle" then
            -- 圆形不受旋转影响，检测逻辑不变
            local cx, cy = body:getWorldCenter()
            local radius = shape:getRadius()
            local dx = mx - cx
            local dy = my - cy
            if dx * dx + dy * dy <= radius * radius then
                return true
            end

        elseif shapeType == "polygon" then
            -- 多边形本身就支持旋转，直接用射线法
            if isPointInPolygon(mx, my, worldPoints) then
                return true
            end
        end
    end
    return false
end

-- 辅助函数：射线法判断点是否在多边形内（核心，兼容任意旋转）
function isPointInPolygon(px, py, points)
    local inside = false
    -- points是{x1,y1,x2,y2,...xn,yn}格式，遍历所有边
    local j = #points - 1 -- 最后一个点的索引（x坐标）
    for i = 1, #points, 2 do
        local xi, yi = points[i], points[i + 1] -- 当前点
        local xj, yj = points[j], points[j + 1] -- 上一个点

        -- 射线法核心逻辑：判断点是否与边相交
        local intersect = ((yi > py) ~= (yj > py)) -- 点在边的y轴范围内
        and (px < (xj - xi) * (py - yi) / (yj - yi) + xi) -- 点在边的x轴左侧
        if intersect then
            inside = not inside -- 每相交一次，内外状态翻转
        end
        j = i -- 更新上一个点为当前点
    end
    return inside
end

-- 为string添加方法
string.safeSub = function(self, start, finish)
    if not self or self == "" then
        return ""
    end

    -- 使用utf8库安全处理
    start = start or 1
    finish = finish or utf8.len(self)

    -- 将字符索引转换为字节索引
    local byteStart = utf8.offset(self, start)
    local byteFinish = utf8.offset(self, finish + 1)

    if byteFinish then
        byteFinish = byteFinish - 1
    end

    if byteStart then
        return string.sub(self, byteStart, byteFinish)
    else
        return ""
    end
end

---utf8 字符串的处理办法----
function initStringExtensions()
    -- 确保utf8可用
    if not utf8 and love and love.utf8 then
        utf8 = love.utf8
    elseif not utf8 then
        local ok, utf8_module = pcall(require, "utf8")
        if ok then
            utf8 = utf8_module
        end
    end

    -- 安全删除第一个字符
    string.removeFirstChar = function(self)
        if not self or self == "" then
            return ""
        end

        local bytePos = utf8.offset(self, 2)
        if bytePos then
            return string.sub(self, bytePos)
        else
            return "" -- 只剩一个字符
        end
    end

    -- 安全删除最后一个字符
    string.removeLastChar = function(self)
        if not self or self == "" then
            return ""
        end

        local charCount = utf8.len(self)
        if charCount <= 1 then
            return ""
        end

        local byteStart = utf8.offset(self, 1)
        local byteEnd = utf8.offset(self, charCount) - 1

        if byteStart and byteEnd then
            return string.sub(self, byteStart, byteEnd)
        end
        return ""
    end

    -- 获取UTF-8字符长度
    string.utf8len = function(self)
        return utf8.len(self)
    end

    -- 按字符分割字符串
    string.splitChars = function(self)
        local chars = {}
        for _, char in utf8.codes(self) do
            table.insert(chars, char)
        end
        return chars
    end

    -- 反转中文字符串
    string.utf8reverse = function(self)
        local chars = {}
        for _, char in utf8.codes(self) do
            table.insert(chars, 1, char)
        end
        return table.concat(chars)
    end

    string.utf8sub = function(self, start, finish)
        if not self or self == "" then
            return ""
        end

        -- 使用utf8库安全处理
        start = start or 1
        finish = finish or utf8.len(self)

        -- 将字符索引转换为字节索引
        local byteStart = utf8.offset(self, start)
        local byteFinish = utf8.offset(self, finish + 1)

        if byteFinish then
            byteFinish = byteFinish - 1
        end

        if byteStart then
            return string.sub(self, byteStart, byteFinish)
        else
            return ""
        end
    end

end

initStringExtensions()
