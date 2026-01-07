-- ease.lua
-- 常用缓动（easing）函数集合
-- 所有函数接受一个归一化的进度 t（0 ≤ t ≤ 1），返回经过缓动后的进度

local Ease = {}

--- 线性（不做任何缓动）
function Ease.linear(t)
    return t
end

--- 二次缓出（先快后慢）
function Ease.outQuad(t)
    -- f(t) = -t * (t - 2)
    return -t * (t - 2)
end

--- 二次缓入（先慢后快）
function Ease.inQuad(t)
    return t * t
end

--- 二次缓入缓出（先慢中速后慢）
function Ease.inOutQuad(t)
    if t < 0.5 then
        return 2 * t * t
    else
        return -2 * t * t + 4 * t - 1
    end
end

--- 三次缓出（先快后慢）
function Ease.outCubic(t)
    local p = t - 1
    return p * p * p + 1
end

--- 三次缓入（先慢后快）
function Ease.inCubic(t)
    return t * t * t
end

--- 三次缓入缓出（先慢中速后慢）
function Ease.inOutCubic(t)
    if t < 0.5 then
        return 4 * t * t * t
    else
        local p = 2 * t - 2
        return 0.5 * p * p * p + 1
    end
end

--- 四次缓出
function Ease.outQuart(t)
    local p = t - 1
    return 1 - p * p * p * p
end

--- 四次缓入
function Ease.inQuart(t)
    return t * t * t * t
end

--- 四次缓入缓出
function Ease.inOutQuart(t)
    if t < 0.5 then
        return 8 * t * t * t * t
    else
        local p = t - 1
        return 1 - 8 * p * p * p * p
    end
end

--- 正弦缓出（先快后慢，常用于 UI 弹入）
function Ease.outSine(t)
    return math.sin(t * math.pi * 0.5)
end

--- 正弦缓入（先慢后快）
function Ease.inSine(t)
    return 1 - math.cos(t * math.pi * 0.5)
end

--- 正弦缓入缓出
function Ease.inOutSine(t)
    return -0.5 * (math.cos(math.pi * t) - 1)
end

--- 指数缓出（快速衰减）
function Ease.outExpo(t)
    if t == 1 then return 1 end
    return 1 - 2 ^ (-10 * t)
end

--- 指数缓入（慢速起步）
function Ease.inExpo(t)
    if t == 0 then return 0 end
    return 2 ^ (10 * (t - 1))
end

--- 指数缓入缓出
function Ease.inOutExpo(t)
    if t == 0 then return 0 end
    if t == 1 then return 1 end
    if t < 0.5 then
        return 0.5 * 2 ^ (20 * t - 10)
    else
        return 1 - 0.5 * 2 ^ (-20 * t + 10)
    end
end

--- 弹性缓出（常用于“弹跳”效果）
function Ease.outElastic(t)
    local c4 = (2 * math.pi) / 3
    if t == 0 then return 0 end
    if t == 1 then return 1 end
    return 2 ^ (-10 * t) * math.sin((t * 10 - 0.75) * c4) + 1
end

--- 弹性缓入
function Ease.inElastic(t)
    local c4 = (2 * math.pi) / 3
    if t == 0 then return 0 end
    if t == 1 then return 1 end
    return - (2 ^ (10 * t - 10)) * math.sin((t * 10 - 10.75) * c4)
end

--- 弹性缓入缓出
function Ease.inOutElastic(t)
    local c5 = (2 * math.pi) / 4.5
    if t == 0 then return 0 end
    if t == 1 then return 1 end
    if t < 0.5 then
        return -(2 ^ (20 * t - 10)) * math.sin((20 * t - 11.125) * c5) / 2
    else
        return (2 ^ (-20 * t + 10)) * math.sin((20 * t - 11.125) * c5) / 2 + 1
    end
end

return Ease