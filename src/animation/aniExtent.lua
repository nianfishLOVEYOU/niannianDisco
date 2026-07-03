-- 动画脚本
local aniExtend = {}

-- ui inherit item
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
    timer:after(time+0.1, function()
        ui:setVisiable(false)
        ui:setPos(ox, ui.y)
        animator:clearKeyframes(name)
        if callback then
            callback()
        end
    end)
end

-- ui inherit item
function aniExtend.uiLeftIn(ui, time, distance, callback)

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
    timer:after(time+0.1, function()
        ui:setVisiable(true)
        ui:setPos(ox, ui.y)
        animator:clearKeyframes(name)
        if callback then
            callback()
        end
    end)
end

return aniExtend
