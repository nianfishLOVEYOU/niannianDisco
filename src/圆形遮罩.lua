local rotateOuter = 0 -- 外层旋转角度
local rotateInner = 0 -- 内层旋转角度

function love.update(dt)
    rotateOuter = (rotateOuter + dt * 0.3) % (math.pi*2)
    rotateInner = (rotateInner + dt * 1) % (math.pi*2)
end

function love.draw()
    local winW, winH = love.graphics.getWidth()/2, love.graphics.getHeight()/2

    -- ============== 外层push/pop（大圆形） ==============
    love.graphics.push() -- 保存原始状态（栈：[原始状态] → [原始状态, 外层状态]）
        -- 外层变换：平移到窗口中心 + 旋转
        love.graphics.translate(winW, winH)
        love.graphics.rotate(rotateOuter)
        
        -- 绘制外层大圆形（红色，仅做参考）
        love.graphics.setColor(1, 0, 0, 0.3)
        love.graphics.circle("fill", 0, 0, 150)
        love.graphics.setColor(1,1,1)

        -- ============== 内层嵌套push/pop（小方形） ==============
        love.graphics.push() -- 保存外层变换后的状态（栈：[原始, 外层] → [原始, 外层, 内层]）
            -- 内层变换：仅作用于内层，和外层无关
            love.graphics.translate(80, 0) -- 相对于外层中心右移80像素
            love.graphics.rotate(rotateInner) -- 内层独立旋转（速度更快）
            love.graphics.scale(0.8) -- 缩放为0.8倍

            -- 绘制内层小方形（嵌套内的独立变换）
            love.graphics.rectangle("fill", -30, -30, 60, 60)
        love.graphics.pop() -- 恢复到外层push后的状态（栈：[原始, 外层, 内层] → [原始, 外层]）
        -- ============== 内层结束 ==============

        -- 绘制外层的另一个图形（不受内层变换影响）
        love.graphics.circle("line", -80, 0, 30)
    love.graphics.pop() -- 恢复到原始状态（栈：[原始, 外层] → [原始]）
    -- ============== 外层结束 ==============

    -- 绘制原始状态的文字（不受任何push/pop影响）
    love.graphics.print("嵌套push/pop演示：\n外层红圆慢速旋转，内层方块快速旋转\n方块仅受内层变换影响，不污染外层", 10, 10)
end