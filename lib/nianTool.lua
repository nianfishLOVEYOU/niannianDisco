nianTool = {}

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

--默认 static
function setBody(x, y, w, h, anchorX, anchorY, bodyInfo)
    bodyInfo          = bodyInfo or {}
    bodyInfo.x        = x or 0
    bodyInfo.y        = y or 0
    bodyInfo.w        = bodyInfo.w or w 
    bodyInfo.h        = bodyInfo.h or h
    bodyInfo.anchorX  = bodyInfo.anchorX or anchorX or 0
    bodyInfo.anchorY  = bodyInfo.anchorY or anchorY or 0
    bodyInfo.type     = bodyInfo.type or "static"
    bodyInfo.tag      = bodyInfo.tag or "unknown"
    bodyInfo.friction = bodyInfo.friction or 0
    bodyInfo.sensor   = not not bodyInfo.sensor
    -- 物理
    local body        = love.physics.newBody(world, bodyInfo.x, bodyInfo.y, bodyInfo.type)                                         -- 世界, 位置, 类型
    local shape       = love.physics.newRectangleShape(bodyInfo.w * bodyInfo.anchorX, bodyInfo.h * bodyInfo.anchorY,
        bodyInfo.w, bodyInfo.h)                                                                                                    -- 相对刚体的偏移和尺寸
    local fixture     = love.physics.newFixture(body, shape, 1)                                                                    -- 刚体, 形状, 密度
    fixture:setFriction(bodyInfo.friction)                                                                                         --摩擦力
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
                local points = { body:getWorldPoints(shape:getPoints()) }
                love.graphics.polygon("line", points)
            elseif shapeType == "edge" then
                local points = { body:getWorldPoints(shape:getPoints()) }
                love.graphics.line(points)
            end
        end
    end
end

-- 辅助函数：兼容低版本Lua的math.random（可选）
function math.random(min, max)
    if min and max then
        return love.math.random() * (max - min) + min
    elseif min then
        return love.math.random() * min
    else
        return love.math.random()
    end
end
