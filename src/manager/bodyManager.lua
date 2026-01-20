local bodyManager ={}

-- 物理设置
world = love.physics.newWorld(0, 0, true) -- x重力, y重力, 是否允许休眠

-- 感知
local function beginContact(a, b, coll)
    local ua, ub = a:getUserData(), b:getUserData()
    if ua and ua.isSensor then
        ua:onEnter(b)
    end
    if ub and ub.isSensor then
        ub:onEnter(a)
    end
end

local function endContact(a, b, coll)
    local ua, ub = a:getUserData(), b:getUserData()
    if ua and ua.isSensor then
        ua:onLeave(b)
    end
    if ub and ub.isSensor then
        ub:onLeave(a)
    end
end

world:setCallbacks(beginContact, endContact)

return bodyManager