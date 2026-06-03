local world
local anchor, pendulum, pendulum2 -- 锚点（固定）、摆锤（动态）
local joint, joint2
local ropeLen = 40 -- 摆长
local radius = 5 -- 摆锤半径
local meter = 200

local physicsProps = {
    gravity = 9.81, -- m/s^2
    linearDamping = 0.5, -- 线性衰减
    angularDamping = 0.5, -- 角速度衰减
    jointDampingRatio = 0.01, -- 关节阻尼比
    impulseScale = 0.5 -- 鼠标点击冲量系数
}

local PendulumSystem = {
    Binder = {}
}

systemManager:init_regester(function()
    PendulumSystem:init()
end)

systemManager:update_regester(function(dt)
    PendulumSystem:update(dt)
end)

systemManager:draw_regester(function()
    PendulumSystem:draw()
end)

local function safeDestroy(obj)
    if obj and not obj:isDestroyed() then
        obj:destroy()
    end
end

-- 清理摆锤与关节（不删除锚点）
local function clearPendulums()
    safeDestroy(joint2)
    safeDestroy(joint)
    safeDestroy(pendulum2)
    safeDestroy(pendulum)

    joint2 = nil
    joint = nil
    pendulum2 = nil
    pendulum = nil
end


function PendulumSystem:_getBinder(x,y,jointNum, length)
    local binder = {
        pendulums = {},
        controllers = {}
    }

    -- 2. 顶部固定锚点（静态刚体）
    binder.pendulums[1] = love.physics.newBody(world, x, y, "static")
    love.physics.newFixture(binder.pendulums[1], love.physics.newCircleShape(5))

    local prevPendulum = nil
    for i = 2, jointNum do
        -- 3. 摆锤（动态刚体）
        local pendulum = love.physics.newBody(world, x + length * i, y + length, "dynamic")
        pendulum:setMass(10)
        love.physics.newFixture(pendulum, love.physics.newCircleShape(radius), 1)
        pendulum:setLinearDamping(physicsProps.linearDamping)
        pendulum:setAngularDamping(physicsProps.angularDamping)
        pendulum:setFixedRotation(false) -- 锁定旋转，保持竖直
        -- 4. 关节：把摆锤拴在锚点上（距离关节=刚性摆杆）
        local joint = nil
        if i == 2 then
            joint = love.physics.newDistanceJoint(binder.pendulums[1], pendulum,
                binder.pendulums[1]:getX(), binder.pendulums[1]:getY(),
                pendulum:getX(), pendulum:getY())
        else
            joint = love.physics.newDistanceJoint(prevPendulum, pendulum,
                prevPendulum:getX(), prevPendulum:getY(),
                pendulum:getX(), pendulum:getY())
        end
        joint:setLength(length)
        binder.pendulums[i] = pendulum

        binder. controllers[i] = { x=0, y= y + length * i, rot=0, radius=150, strength=1 } -- 控制点1用来控制网格

        
        prevPendulum = pendulum
    end

    return binder
end

--跟新旋转关节的旋转角度
function PendulumSystem:updatePendulumAngle()
    for id, binder in pairs(self.Binder) do
        local meshData = binder.meshData
        local pendulum = binder.pendulums[1]
        local anchor = binder.anchor
        for index, pendulum in pairs(binder.pendulums) do
            local px, py
            if index==1 then
                px=anchor:getX()
                py=anchor:getY()
            else
                px=binder.pendulums[index-1]:getX()
                py=binder.pendulums[index-1]:getY()
            end

                -- 2. 计算 摆锤 ↔ 上一级 的方向向量
                local dx = pendulum:getX() - px
                local dy = pendulum:getY() - py

                -- 3. 计算连线角度（摆杆角度）
                local rodAngle = math.atan2(dy, dx)
                pendulum:setAngle(rodAngle + math.pi/2)
        end

    end
end

function PendulumSystem:bindMesh(meshData,x,y)

    local binder = self:_getBinder(x, y, 1, meshData.h) -- 1个关节，长度根据Mesh高度调整
    binder.meshData = meshData
    self.Binder[meshData.id] = binder

    print(string.format("绑定Mesh ID=%s 到Pendulum系统，锚点=(%.1f, %.1f)，摆锤初始位置=(%.1f, %.1f)",
        meshData.id, binder.anchor:getX(), binder.anchor:getY(), binder.pendulums[1]:getX(), binder.pendulums[1]:getY()))

end


function PendulumSystem:effectVertex(points)
     local meshData = self.meshes[id]
    if not meshData then
        print("错误：Mesh ID="..id.." 不存在")
        return
    end

    

    for id, vertices in pairs(meshData.originalVertices) do
        --遍历每一个定点计算影响后的坐标
        local v = meshData.currentVertices[id]

        local ox = meshData.originalVertices[id].x -- 原始坐标
        local oy = meshData.originalVertices[id].y
        local totalWeight = 0
        local finalX, finalY = 0,0

        -- 遍历所有控制点，计算影响
        for _, c in ipairs(controllers) do
            -- 顶点到控制点的距离
            local dx = ox - c.x
            local dy = oy - c.y
            local dist = math.sqrt(dx*dx + dy*dy)

            -- 平滑权重（软分配，安全不抖动）
            local weight = math.max(0, 1 - (dist / c.radius)) * c.strength
            if weight <= 0 then goto continue end
            totalWeight = totalWeight + weight

            -- 相对坐标
            local rx = ox - c.x
            local ry = oy - c.y

            -- 【应用控制点旋转】（相对位置绕点旋转）
            local cos = math.cos(c.rot)
            local sin = math.sin(c.rot)
            local rdx = rx * cos - ry * sin
            local rdy = rx * sin + ry * cos

            -- 旋转后位置 = 控制点位置 + 相对旋转位置
            local wx = c.x + rdx
            local wy = c.y + rdy

            -- 加权累加
            finalX = finalX + wx * weight
            finalY = finalY + wy * weight

            ::continue::
        end

        -- 归一化权重（安全混合）
        if totalWeight > 0 then
            finalX = finalX / totalWeight
            finalY = finalY / totalWeight
        else
            finalX = ox -- 不受任何控制 → 保持原位
            finalY = oy
        end

        -- 写回顶点
        verts[i][1] = finalX
        verts[i][2] = finalY
    end


    ------------------------------------------------
    local verts = mesh:getVertices()

    for i=1, #verts do
        
    end

    -- 同步到Love2D Mesh
    meshData.mesh:setVertices(meshData.currentVertices)
end

function PendulumSystem:_meshsPositionTrack()
    for id, binder in pairs(self.Binder) do
        local meshData = binder.meshData
        local pendulum = binder.pendulums[1]
        local anchor = binder.anchor

        local leftBottom = {
            x = anchor:getX() - meshData.w / 2,
            y = anchor:getY() 
        }
        local rightBottom = {
            x = anchor:getX() + meshData.w / 2,
            y = anchor:getY() 
        }
        local rightTop = {
            x = pendulum:getX() + meshData.w / 2,
            y = pendulum:getY()
        }
        local leftTop = {
            x = pendulum:getX() - meshData.w / 2,
            y = pendulum:getY()
        }

        if meshData and pendulum then
            meshAnimator:quadDeform(meshData.id, leftBottom, rightBottom, rightTop, leftTop)
        end
    end
end

function PendulumSystem:init()
    -- 1. 初始化物理世界
    love.physics.setMeter(meter)
    world = love.physics.newWorld(0, physicsProps.gravity * meter, true) -- 重力向下
end

function PendulumSystem:update(dt)
    world:update(dt)
    self:updatePendulumAngle()
    self:_meshsPositionTrack()
end

function PendulumSystem:draw()
    -- 画摆杆
    for id, binder in pairs(self.Binder) do
        local anchor = binder.anchor
        local pendulum = binder.pendulums[1]

        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.line(anchor:getX(), anchor:getY(), pendulum:getX(), pendulum:getY())

        -- 画锚点
        love.graphics.setColor(0, 1, 0)
        love.graphics.circle("fill", anchor:getX(), anchor:getY(), 5)

        -- 画摆锤
        love.graphics.setColor(1, 0, 0)
        love.graphics.circle("fill", pendulum:getX(), pendulum:getY(), radius)

        --画摆锤角度
        local angle = pendulum:getAngle()
        local dir_x = math.cos(angle)*50
        local dir_y = math.sin(angle)*50
        drawArrow(pendulum:getX(), pendulum:getY(), pendulum:getX() + dir_x, pendulum:getY() + dir_y)
    end
    

    love.graphics.setColor(1, 1, 1)
    love.graphics.print(string.format("gravity: %.2f", physicsProps.gravity), 20, 20)
    -- love.graphics.print(string.format("linearDamping: %.3f", physicsProps.linearDamping), 20, 40)
    -- love.graphics.print(string.format("angularDamping: %.3f", physicsProps.angularDamping), 20, 60)
    -- love.graphics.print(string.format("jointDampingRatio: %.3f", physicsProps.jointDampingRatio), 20, 80)
    -- love.graphics.print(string.format("impulseScale: %.2f", physicsProps.impulseScale), 20, 100)
    --love.graphics.print("[Q/A] gravity  [W/S] linear  [E/D] angular  [T/G] joint  [C] clear  [R] reset", 20, 125)
end

function PendulumSystem:mousemoved(x, y, dx, dy)
    -- 鼠标拖动锚点
    if love.mouse.isDown(1) and anchor then
        anchor:setPosition(x, y)
    end
end

return PendulumSystem
