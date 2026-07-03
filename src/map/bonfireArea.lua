local bonfireArea = {}
--椭圆控制玩家不走出去
--椭圆公式：((x-h)^2)/a^2 + ((y-k)^2)/b^2 = 1
--椭圆地面和背景墙


-- 椭圆参数
local ellipse = {
    cx = 400,    -- 中心x
    cy = 300,    -- 中心y
    a = 250,     -- 水平半轴
    b = 180      -- 垂直半轴
}

-- 玩家
local player = {
    x = 400,
    y = 300,
    size = 16,
    speed = 220
}

-- 判断点(px,py)是否在椭圆内部
local function pointInEllipse(px, py, e)
    local dx = px - e.cx
    local dy = py - e.cy
    local val = (dx/e.a)^2 + (dy/e.b)^2
    return val <= 1
end

-- 将超出椭圆的点拉回椭圆边缘
local function clampPointToEllipse(px, py, e)
    local dx = px - e.x
    local dy = py - e.y

    -- 单位化椭圆边界比例
    local t = math.sqrt( (dx/e.a)^2 + (dy/e.b)^2 )
    if t < 0.0001 then t = 0.0001 end -- 避免除0

    local scale = 1 / t
    local newX = e.x + dx * scale
    local newY = e.y + dy * scale
    return newX, newY
end

function bonfireArea:update(dt)
    -- 预移动
    local targetX = player.x 
    local targetY = player.y 

    -- 如果玩家中心跑出椭圆，拉回边界
    if not pointInEllipse(targetX, targetY, ellipse) then
        targetX, targetY = clampPointToEllipse(targetX, targetY, ellipse)
    end

    player.x = targetX
    player.y = targetY
end

function bonfireArea:draw()
    -- 绘制椭圆边界（碰撞区域）
    love.graphics.setColor(0.3,0.7,1)
    love.graphics.ellipse("line", ellipse.cx, ellipse.cy, ellipse.a, ellipse.b)
end