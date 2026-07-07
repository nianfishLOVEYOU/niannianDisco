-- 动画脚本
local aniExtend = {}

-- ui 左滑动离场
-- time 离场动画时间
-- distance 离场动画距离
-- callback 离场动画完成回调
function aniExtend.uiLeftOut(ui, time, distance,callback)
    ui:setVisiable(true)
    local name = tostring(ui.id)

    if animator.tracks[name] then --如果已经有就不再添加
        return
    end
    local ox = ui.x
    local targetx=ui.x - distance
    animator:addTrack(name, ui, "x", true, false, false, "easeIn")
    animator:addKeyframe(name, 0, ox)
    animator:addKeyframe(name, time , targetx)
    timer:after(time, function()
        ui:setVisiable(false)
        ui:setPos(ox, ui.y)
        animator:clearKeyframes(name)
        if callback then
            callback()
        end
    end)
end

-- ui 右滑动入场
-- time 入场动画时间
-- distance 入场动画距离
-- callback 入场动画完成回调
function aniExtend.uiRightIn(ui, time, distance, callback)

    ui:setVisiable(true)
    local name = tostring(ui.id)

    if animator.tracks[name] then--如果已经有就不再添加
        return
    end
    local ox = ui.x
    local Startx=ui.x - distance
    ui:setPos(Startx, ui.y)
    animator:addTrack(name, ui, "x", true, false, false, "easeIn")
    animator:addKeyframe(name, 0, Startx)
    animator:addKeyframe(name, time, ox)
    timer:after(time, function()
        ui:setVisiable(true)
        ui:setPos(ox, ui.y)
        animator:clearKeyframes(name)
        if callback then
            callback()
        end
    end)
end
-- ui inherit item
-- time: 完整跳跃总时长(ms)
-- distance: 水平移动总距离
-- jumpHeight: 新增参数，跳跃最高点高度
-- callback: 落地完成回调
function aniExtend.jump(item, time, jumpHeight, callback)
    local ui = item
    ui:setVisiable(true)
    local name = tostring(ui.id)

    -- 已有动画直接退出，防止叠加
    if animator.tracks[name] then
        return
    end

    -- 初始坐标
    -- local originX = ui.x
    local originY = ui.y -- 落地基准高度，全程落地回到此值
    -- local startX = originX - distance

    -- 起点复位
    --ui:setPos(startX, originY)

    -- 拆分时间：上升占总时长一半，下落一半，模拟重力对称抛物
    local halfTime = time / 2

    -- 1. X轴动画：匀速从startX移动到originX（全程线性）
    -- animator:addTrack(name, ui, "x", true, false, false, "linear")
    -- animator:addKeyframe(name, 0, startX)
    -- animator:addKeyframe(name, time, originX)

    -- 2. Y轴跳跃动画，带重力缓动：先上升到最高点，再下落回原高度
    animator:addTrack(name, ui, "y", true, false, false, "easeOut") -- 上升减速(重力拉扯)
    animator:addKeyframe(name, 0, originY)
    animator:addKeyframe(name, halfTime, originY - jumpHeight) -- 最高点

    animator:addTrack(name, ui, "y", true, false, false, "easeIn") -- 下落加速(重力加速)
    animator:addKeyframe(name, halfTime, originY - jumpHeight)
    animator:addKeyframe(name, time, originY) -- 落回初始高度

    -- 动画结束清理
    timer:after(time, function()
        ui:setVisiable(true)
        ui:setPos(ui.x, originY) -- 强制归位，防止动画误差
        animator:clearKeyframes(name)
        if callback then
            callback()
        end
    end)
end

return aniExtend
