nianMath={}

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
