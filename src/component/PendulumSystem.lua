-- ==============================================
-- 摆钟管理器：支持单摆/多摆节点
-- ==============================================
PendulumSystem = {
    pendulums = {},  -- 存储所有摆钟实例
    g = 9.8,         -- 重力加速度
    damping = 0.995  -- 阻尼系数（0.995=轻微阻尼，1=无阻尼）
}

-- ==============================================
-- 创建单摆/多摆实例
-- @param type: "single"（单摆） / "multi"（多摆）
-- @param x,y: 摆的悬挂点坐标
-- @param params: 参数表 {
--     lengths: 摆长列表（单摆传[长度]，多摆传[长度1, 长度2,...]）
--     masses: 质量列表（单摆传[质量]，多摆传[质量1, 质量2,...]）
--     initAngles: 初始角度列表（弧度，单摆传[角度]，多摆传[角度1, 角度2,...]）
-- }
-- ==============================================
function PendulumSystem:createPendulum(type, x, y, params)
    local pendulum = {
        type = type,
        anchorX = x,
        anchorY = y,
        lengths = params.lengths or {100},  -- 默认摆长100
        masses = params.masses or {10},     -- 默认质量10
        angles = params.initAngles or {math.pi/4},  -- 默认初始角度45度
        angularVels = {},  -- 角速度列表（每个节点的角速度）
        nodes = {}         -- 每个节点的实时坐标
    }

    -- 初始化角速度（初始静止）
    for i = 1, #pendulum.lengths do
        pendulum.angularVels[i] = 0
    end

    -- 计算初始节点坐标
    self:updatePendulumNodes(pendulum)

    -- 加入管理器
    table.insert(self.pendulums, pendulum)
    return #self.pendulums  -- 返回实例ID
end

-- ==============================================
-- 更新摆钟节点坐标（根据角度计算）
-- ==============================================
function PendulumSystem:updatePendulumNodes(pendulum)
    pendulum.nodes = {}
    local currentX, currentY = pendulum.anchorX, pendulum.anchorY

    for i = 1, #pendulum.lengths do
        -- 角度转坐标：x = 悬挂点x + 摆长*sin(角度)，y = 悬挂点y + 摆长*cos(角度)
        local nodeX = currentX + pendulum.lengths[i] * math.sin(pendulum.angles[i])
        local nodeY = currentY + pendulum.lengths[i] * math.cos(pendulum.angles[i])
        table.insert(pendulum.nodes, {x = nodeX, y = nodeY})
        -- 下一个节点的悬挂点 = 当前节点坐标
        currentX, currentY = nodeX, nodeY
    end
end

-- ==============================================
-- 物理更新：计算角速度和角度（核心）
-- ==============================================
function PendulumSystem:update(dt)
    for _, pendulum in ipairs(self.pendulums) do
        if pendulum.type == "single" then
            -- 1. 单摆物理计算
            local L = pendulum.lengths[1]
            local angle = pendulum.angles[1]
            local angularVel = pendulum.angularVels[1]

            -- 角加速度 = -g/L * sin(角度)（小角度近似可替换为 -g/L * angle）
            local angularAcc = -(self.g / L) * math.sin(angle)
            -- 更新角速度（加阻尼）
            angularVel = (angularVel + angularAcc * dt) * self.damping
            -- 更新角度
            angle = angle + angularVel * dt

            -- 同步回摆钟实例
            pendulum.angularVels[1] = angularVel
            pendulum.angles[1] = angle

        elseif pendulum.type == "multi" then
            -- 2. 多摆物理计算（以双摆为例，可扩展N摆）
            local n = #pendulum.lengths
            local angles = pendulum.angles
            local angularVels = pendulum.angularVels
            local lengths = pendulum.lengths
            local masses = pendulum.masses

            -- 临时存储新的角速度（避免计算时覆盖）
            local newAngularVels = {}

            -- 双摆核心公式（扩展N摆需增加更多项，此处简化双摆）
            if n >= 2 then
                local m1, m2 = masses[1], masses[2]
                local L1, L2 = lengths[1], lengths[2]
                local a1, a2 = angles[1], angles[2]
                local v1, v2 = angularVels[1], angularVels[2]

                -- 计算分子分母（双摆角加速度公式）
                local num1 = -self.g * (2*m1 + m2) * math.sin(a1) - m2 * self.g * math.sin(a1 - 2*a2) - 2*math.sin(a1 - a2)*m2*(v2*v2*L2 + v1*v1*L1*math.cos(a1 - a2))
                local num2 = 2*math.sin(a1 - a2)*(v1*v1*L1*(m1 + m2) + self.g*(m1 + m2)*math.cos(a1) + v2*v2*L2*m2*math.cos(a1 - a2))
                local den = L1*(2*m1 + m2 - m2*math.cos(2*a1 - 2*a2))
                local den2 = L2*(2*m1 + m2 - m2*math.cos(2*a1 - 2*a2))

                local a1Acc = num1 / den  -- 第一个摆的角加速度
                local a2Acc = num2 / den2  -- 第二个摆的角加速度

                -- 更新角速度（加阻尼）
                newAngularVels[1] = (v1 + a1Acc * dt) * self.damping
                newAngularVels[2] = (v2 + a2Acc * dt) * self.damping

                -- 超过2个节点时，简化为跟随前一个节点（可扩展更复杂公式）
                for i = 3, n do
                    newAngularVels[i] = (angularVels[i] - (self.g / lengths[i]) * math.sin(angles[i]) * dt) * self.damping
                end
            end

            -- 更新角度和角速度
            for i = 1, n do
                pendulum.angularVels[i] = newAngularVels[i] or pendulum.angularVels[i]
                pendulum.angles[i] = pendulum.angles[i] + pendulum.angularVels[i] * dt
            end
        end

        -- 更新所有节点坐标
        self:updatePendulumNodes(pendulum)
    end
end

-- ==============================================
-- 绘制摆钟（悬挂点+摆杆+摆锤）
-- ==============================================
function PendulumSystem:draw()
    for _, pendulum in ipairs(self.pendulums) do
        love.graphics.setLineWidth(2)
        local currentX, currentY = pendulum.anchorX, pendulum.anchorY

        -- 绘制摆杆（悬挂点到每个节点）
        love.graphics.setColor(1, 1, 1)  -- 白色摆杆
        for i, node in ipairs(pendulum.nodes) do
            love.graphics.line(currentX, currentY, node.x, node.y)
            currentX, currentY = node.x, node.y
        end

        -- 绘制悬挂点（红色小圆圈）
        love.graphics.setColor(1, 0, 0)
        love.graphics.circle("fill", pendulum.anchorX, pendulum.anchorY, 5)

        -- 绘制摆锤（每个节点的质量球，质量越大球越大）
        for i, node in ipairs(pendulum.nodes) do
            local radius = math.max(5, pendulum.masses[i]/2)  -- 质量转半径
            love.graphics.setColor(0, 0.7, 1)  -- 蓝色摆锤
            love.graphics.circle("fill", node.x, node.y, radius)
            -- 绘制节点序号（多摆时区分）
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(i, node.x - 3, node.y - 3)
        end
    end

    -- 绘制调试信息
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("单摆+多摆演示 | 重力="..self.g.." | 阻尼="..self.damping, 10, 10)
    love.graphics.print("单摆：左侧 | 双摆：右侧", 10, 30)
end

-- ==============================================
-- Love2D 生命周期函数
-- ==============================================
function love.load()
    love.window.setTitle("摆钟与多重摆钟节点")
    love.window.setMode(800, 600)

    -- 1. 创建单摆（左侧，摆长150，质量15，初始角度60度）
    PendulumSystem:createPendulum("single", 200, 100, {
        lengths = {150},
        masses = {15},
        initAngles = {math.pi/3}  -- 60度（弧度）
    })

    -- 2. 创建双摆（右侧，两个节点，摆长120/100，质量12/10，初始角度45/30度）
    PendulumSystem:createPendulum("multi", 600, 100, {
        lengths = {120, 100},
        masses = {12, 10},
        initAngles = {math.pi/4, math.pi/6}  -- 45度/30度
    })

    -- 可选：创建三摆（扩展示例）
    -- PendulumSystem:createPendulum("multi", 400, 100, {
    --     lengths = {100, 80, 60},
    --     masses = {10, 8, 6},
    --     initAngles = {math.pi/4, math.pi/6, math.pi/8}
    -- })
end

function love.update(dt)
    -- 物理更新（dt=帧时间，保证运动速度稳定）
    PendulumSystem:update(dt)
end

function love.draw()
    -- 黑色背景
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)
    -- 绘制摆钟
    PendulumSystem:draw()
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "r" then
        -- 重置所有摆钟（重新加载）
        love.load()
    elseif key == "up" then
        -- 增加重力
        PendulumSystem.g = PendulumSystem.g + 1
    elseif key == "down" then
        -- 减少重力
        PendulumSystem.g = math.max(1, PendulumSystem.g - 1)
    elseif key == "left" then
        -- 减少阻尼（摆动更久）
        PendulumSystem.damping = math.min(1, PendulumSystem.damping + 0.001)
    elseif key == "right" then
        -- 增加阻尼（摆动衰减更快）
        PendulumSystem.damping = math.max(0.98, PendulumSystem.damping - 0.001)
    end
end