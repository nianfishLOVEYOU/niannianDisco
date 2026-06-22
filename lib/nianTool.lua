nianTool = {}
timer = require "src.common.timer"
animation = require "src.animation"
animator = require "src.animator"
commonData = require "src.common.commonData"

require "lib.nianMath"
require "lib.nianDebug"
require "lib.nianDraw"

if love.filesystem.isFused() then
    print("打包模式")
else
    print("代码模式")
end

function nianTool.dump(tbl, indent)
    indent = indent or 0
    local prefix = string.rep("  ", indent)
    for k, v in pairs(tbl) do
        local key = tostring(k)
        if type(v) == "table" then
            print(string.format("%s%s = {", prefix, key))
            nianTool.dump(v, indent + 1) -- 递归
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

    --     --物理
    -- world = love.physics.newWorld(0, 9.8*64, true) -- x重力, y重力, 是否允许休眠
    -- body = love.physics.newBody(world, x, y, "dynamic") -- 世界, 位置, 类型
    -- shape = love.physics.newRectangleShape(0, 0, width, height) -- 相对刚体的偏移和尺寸
    -- fixture = love.physics.newFixture(body, shape, density) -- 刚体, 形状, 密度
    -- fixture:setFriction(0.3)
    -- fixture:setRestitution(0.2) -- 弹性
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

-- 使用io读取文件的方法
-- local dir = love.filesystem.getSaveDirectory():gsub("/", "\\")
-- local f = io.open(dir .. "\\" .. cmd.path, "rb")

--- 画箭头
-- 画箭头函数：起点(x1,y1)，终点(x2,y2)，可选颜色、线宽、箭头大小
function drawArrow(x1, y1, x2, y2, r, g, b, a, lineWidth, arrowSize)
    -- 默认值（不传参数也能用）
    r = r or 1
    g = g or 1
    b = b or 1
    a = a or 1
    lineWidth = lineWidth or 2
    arrowSize = arrowSize or 15

    -- 计算方向
    local dx = x2 - x1
    local dy = y2 - y1
    local angle = math.atan2(dy, dx)

    love.graphics.setColor(r, g, b, a)
    love.graphics.setLineWidth(lineWidth)

    -- 画箭身
    love.graphics.line(x1, y1, x2, y2)

    -- 画箭头两翼
    local wing1x = x2 - arrowSize * math.cos(angle - math.pi / 6)
    local wing1y = y2 - arrowSize * math.sin(angle - math.pi / 6)
    local wing2x = x2 - arrowSize * math.cos(angle + math.pi / 6)
    local wing2y = y2 - arrowSize * math.sin(angle + math.pi / 6)

    love.graphics.line(x2, y2, wing1x, wing1y)
    love.graphics.line(x2, y2, wing2x, wing2y)

    -- 恢复默认
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
end

local outlineSize = 1 -- 描边粗细（像素）
-- 辅助：绘制带描边文字
function drawOutlinedText(t, x, y, w, color, outlineColor)
    
    local fillColor = color or {1, 1, 1, 1} -- 文字：白色
    local outlineColor = outlineColor or {0, 0, 0, 1} -- 描边：黑色
    -- 1. 画8个方向描边
    love.graphics.setColor(outlineColor)
    for dx = -outlineSize, outlineSize do
        for dy = -outlineSize, outlineSize do
            if dx ~= 0 or dy ~= 0 then -- 跳过原位
                if w and w > 0 then
                    love.graphics.printf(t, x + dx, y + dy, w, "left")
                else
                    love.graphics.print(t, x + dx, y + dy)
                end
            end
        end
    end
    -- 2. 画主体文字
    love.graphics.setColor(fillColor)

    if w and w > 0 then
        love.graphics.printf(t, x, y, w, "left")
    else
        love.graphics.print(t, x, y)
    end
    --love.graphics.print(t, x, y)
end


local drawTailFillColor = {1, 1, 1, 1} -- 尾巴填充颜色（白色）
local drawTailLineColor = {0, 0, 0, 1} -- 尾巴边框颜色（黑色）
local drawTailBorderWidth = 1 -- 尾巴边框宽度（像素
local drawTailSize = 20 -- 尾巴大小（像素，控制宽度和长度）
-- 绘制对话框尾巴
-- x, y, boxW, boxH, self.targetX, self.targetY, self.config.tailSize, self.config.borderWidth, self.config.bgColor, self.config.borderColor)
function drawTail(anchorX, anchorY, targetX, targetY, size, borderWidth, fillColor, lineColor)
    fillColor=fillColor or drawTailFillColor
    lineColor=lineColor or drawTailLineColor
    borderWidth=borderWidth or drawTailBorderWidth
    size=size or drawTailSize


    local vx = targetX - anchorX -- 尾巴向量X分量
    local vy = targetY - anchorY -- 尾巴向量Y分量

    local len = math.sqrt(vx * vx + vy * vy)
    if len < 1e-5 then
        return
    end

    local dx = vx / len
    local dy = vy / len

    -- 法线方向用于控制尾巴宽度
    local nx = -dy
    local ny = dx

    local baseHalfWidth = size
    local tipHalfWidth = math.max(1, size * 0.01)
    local tipBackOffset = math.min(len * 0.35, math.max(4, size * 0.8))
    local tipArcSegments = 8

    local baseLeftX = anchorX + nx * baseHalfWidth
    local baseLeftY = anchorY + ny * baseHalfWidth
    local baseRightX = anchorX - nx * baseHalfWidth
    local baseRightY = anchorY - ny * baseHalfWidth

    local tipCenterX = targetX - dx * tipBackOffset
    local tipCenterY = targetY - dy * tipBackOffset
    local tipLeftX = tipCenterX + nx * tipHalfWidth
    local tipLeftY = tipCenterY + ny * tipHalfWidth
    local tipRightX = tipCenterX - nx * tipHalfWidth
    local tipRightY = tipCenterY - ny * tipHalfWidth


    local points = {
        baseLeftX, baseLeftY,
        tipLeftX, tipLeftY
    }



    table.insert(points, tipRightX)
    table.insert(points, tipRightY)
    table.insert(points, baseRightX)
    table.insert(points, baseRightY)

    -- 填充与边框共用同一条外轮廓
    love.graphics.setColor(fillColor)
    love.graphics.polygon("fill", points)

    love.graphics.setColor(lineColor)
    love.graphics.setLineWidth(borderWidth)
    love.graphics.polygon("line", points)
end


-- 绘制对话框尾巴
-- x, y, boxW, boxH, self.targetX, self.targetY, self.config.tailSize, self.config.borderWidth, self.config.bgColor, self.config.borderColor)
function drawTailStandard(anchorX, anchorY,type, targetX, targetY, size, borderWidth, fillColor, lineColor)
    fillColor=fillColor or drawTailFillColor
    lineColor=lineColor or drawTailLineColor
    borderWidth=borderWidth or drawTailBorderWidth
    size=size or drawTailSize

    
    local vx = targetX - anchorX -- 尾巴向量X分量
    local vy = targetY - anchorY -- 尾巴向量Y分量

    local len = math.sqrt(vx * vx + vy * vy)
    if len < 1e-5 then
        return
    end

    local dx = vx / len
    local dy = vy / len

    -- 根部宽度方向：x=水平，y=垂直；其他值回退为默认（跟随方向法线）
    local nx, ny
    if type == "x" then
        nx, ny = 1, 0
    elseif type == "y" then
        nx, ny = 0, 1
    else
        nx, ny = -dy, dx
    end

    local baseHalfWidth = size
    local tipHalfWidth = math.max(1, size * 0.01)
    local tipBackOffset = math.min(len * 0.35, math.max(4, size * 0.8))

    local baseLeftX = anchorX + nx * baseHalfWidth
    local baseLeftY = anchorY + ny * baseHalfWidth
    local baseRightX = anchorX - nx * baseHalfWidth
    local baseRightY = anchorY - ny * baseHalfWidth

    local tipCenterX = targetX - dx * tipBackOffset
    local tipCenterY = targetY - dy * tipBackOffset
    local tipLeftX = tipCenterX + nx * tipHalfWidth
    local tipLeftY = tipCenterY + ny * tipHalfWidth
    local tipRightX = tipCenterX - nx * tipHalfWidth
    local tipRightY = tipCenterY - ny * tipHalfWidth


    local points = {
        baseLeftX, baseLeftY,
        tipLeftX, tipLeftY
    }



    table.insert(points, tipRightX)
    table.insert(points, tipRightY)
    table.insert(points, baseRightX)
    table.insert(points, baseRightY)

    -- 填充与边框共用同一条外轮廓
    love.graphics.setColor(fillColor)
    love.graphics.polygon("fill", points)

    love.graphics.setColor(lineColor)
    love.graphics.setLineWidth(borderWidth)
    love.graphics.polygon("line", points)
end
