local bodyManager = {}

-- 物理设置
world = love.physics.newWorld(0, 0, true) -- x重力, y重力, 是否允许休眠

-- 1感知第一次接触的时候触发  
-- coll 包括接触点、接触法线、碰撞是否启用、反弹系数等
local function beginContact(a, b, coll)
    local ua, ub = a:getUserData(), b:getUserData()
    if ua and ua.isSensor then
        ua:onEnter(b)
    end
    if ub and ub.isSensor then
        ub:onEnter(a)
    end
end

-- 2分离的时候触发
-- coll 包括接触点、接触法线、碰撞是否启用、反弹系数等
local function endContact(a, b, coll)
    local ua, ub = a:getUserData(), b:getUserData()
    if ua and ua.isSensor then
        ua:onLeave(b)
    end
    if ub and ub.isSensor then
        ub:onLeave(a)
    end
end


-- 3. 碰撞求解前回调（仅普通碰撞体，每帧触发）
-- coll 包括接触点、接触法线、碰撞是否启用、反弹系数等
local function preSolve(a, b, coll)
    local ua, ub = a:getUserData(), b:getUserData()
    local aName = ua and ua.name or "未知"
    local bName = ub and ub.name or "未知"
    
    -- 示例1：禁用“箱子撞地面”的反弹（让箱子落地不弹）
    if (aName == "box" and bName == "ground") or (aName == "ground" and bName == "box") then
        coll:setRestitution(0) -- 设置反弹系数为0
        print("→ [preSolve] 禁用箱子落地反弹")
    end
    
    -- 示例2：按空格键时，禁用玩家和箱子的碰撞（玩家可穿透箱子）
    if love.keyboard.isDown("space") and ((aName == "player" and bName == "box") or (aName == "box" and bName == "player")) then
        coll:setEnabled(false) -- 禁用本次碰撞求解
        print("→ [preSolve] 玩家穿透箱子！")
    end
end

-- 4. 碰撞求解后回调（仅普通碰撞体，每帧触发）
-- coll 包括接触点、接触法线、碰撞是否启用、反弹系数等
-- normalImpulse 法向冲量  沿接触法线方向的冲量（垂直于碰撞面的力），决定 “反弹 / 挤压” 的力度。
-- tangentImpulse 切向冲量  沿接触切面方向的冲量（平行于碰撞面的力），决定 “摩擦 / 滑动” 的力度。
local function postSolve(a, b, coll, normalImpulse, tangentImpulse)
    local ua, ub = a:getUserData(), b:getUserData()
    local aName = ua and ua.name or "未知"
    local bName = ub and ub.name or "未知"
    
    -- 示例：获取碰撞冲量，冲量过大时让箱子“损坏”
    if (aName == "player" and bName == "box") or (aName == "box" and bName == "player") then
        local totalImpulse = normalImpulse + tangentImpulse
        print(string.format("→ [postSolve] 碰撞冲量：%.2f", totalImpulse))
        if totalImpulse > 500 then
            print("→ 箱子被撞坏了！")
        end
    end
end

world:setCallbacks(beginContact, endContact,preSolve,postSolve)

-- bodyinfo.item 碰撞时得到的对象
-- bodyinfo.bodyType 碰撞体类型（static ， dynamic）
-- bodyinfo.fixture 摩擦力  bodyinfo.density 密度 bodyinfo.restitution 弹性
-- bodyinfo.onEnter 是进入方法，bodyinfo.onLeave 是离开方法
-- 默认 static 可以自己定义为
function bodyManager:setBody(x, y, w, h, anchorX, anchorY, bodyInfo)
    bodyInfo = bodyInfo or {}
    x = x or 0
    y = y or 0
    w = w or 10
    h = h or 100
    anchorX = anchorX or 0 --body默认是居中的
    anchorY = anchorY or 0

    --bodyinfo设置
    bodyInfo.bodyType = bodyInfo.bodyType or "static"
    bodyInfo.name = bodyInfo.name or "unknownBody"
    bodyInfo.friction = bodyInfo.friction or 0 
    bodyInfo.density = bodyInfo.density or 1
    bodyInfo.restitution=bodyInfo.restitution or 0
    -- 物理
    local body = love.physics.newBody(world, x, y, bodyInfo.bodyType)                -- 世界, 位置, 类型
    local shape = love.physics.newRectangleShape(w * anchorX, h * anchorY, w, h) -- 相对刚体的偏移和尺寸
    local fixture = love.physics.newFixture(body, shape, bodyInfo.density)       -- 刚体, 形状, 密度
    fixture:setFriction(bodyInfo.friction)                                       -- 摩擦力
    fixture:setRestitution(bodyInfo.restitution)                                 -- 弹性
    body:setPosition(x, y)
    body:setFixedRotation(true)
    fixture:setSensor(false) --不是检测器

    -- 设置UserData，包含传感器标识和回调方法
    fixture:setUserData({
        name = bodyInfo.name,
        item = bodyInfo.item,
        isSensor = false,                -- 标记为传感器，对应你的回调逻辑
        onEnter = function(otherFixture) -- 进入传感器时执行
            local otherData = otherFixture:getUserData()
            if bodyInfo.onEnter then
                bodyInfo.onEnter(otherData)
            end
        end,
        onLeave = function(otherFixture) -- 离开传感器时执行
            local otherData = otherFixture:getUserData()
            if bodyInfo.onEnter then
                bodyInfo.onLeave(otherData)
            end
        end
    })

    return body, fixture, shape
end



-- bodyinfo.item 碰撞时得到的对象
-- bodyinfo.bodyType 碰撞体类型（static ， dynamic）
-- bodyinfo.fixture 摩擦力  bodyinfo.density 密度 bodyinfo.restitution 弹性
-- bodyinfo.onEnter 是进入方法，bodyinfo.onLeave 是离开方法
-- 默认 static 可以自己定义为
function bodyManager:setSensor(x, y, w, h, anchorX, anchorY, bodyInfo)
    bodyInfo = bodyInfo or {}
    x = x or 0
    y = y or 0
    w = w or 10
    h = h or 100
    anchorX = anchorX or 0 --body默认是居中的
    anchorY = anchorY or 0

    --bodyinfo设置
    bodyInfo.bodyType = "static"
    bodyInfo.name = bodyInfo.name or "unknownSensor"
    -- 物理
    local body = love.physics.newBody(world, x, y, bodyInfo.bodyType)                -- 世界, 位置, 类型
    local shape = love.physics.newRectangleShape(w * anchorX, h * anchorY, w, h) -- 相对刚体的偏移和尺寸
    local fixture = love.physics.newFixture(body, shape)       -- 刚体, 形状, 密度
    body:setPosition(x, y)
    fixture:setSensor(true) 

    -- 设置UserData，包含传感器标识和回调方法
    fixture:setUserData({
        name = bodyInfo.name,
        item = bodyInfo.item,
        isSensor = true,                -- 标记为传感器，对应你的回调逻辑
        onEnter = function(otherFixture) -- 进入传感器时执行
            local otherData = otherFixture:getUserData()
            if bodyInfo.onEnter then
                bodyInfo.onEnter(otherData)
            end
        end,
        onLeave = function(otherFixture) -- 离开传感器时执行
            local otherData = otherFixture:getUserData()
            if bodyInfo.onEnter then
                bodyInfo.onLeave(otherData)
            end
        end
    })

    return body, fixture, shape
end



return bodyManager
