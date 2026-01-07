--local Ease = require "ease"


-- animation.lua
local Animation = {}
Animation.__index = Animation

--- 创建一个新的动画对象
--- @param target table   需要被驱动的对象（如 UI 按钮 table）
--- @param props  table   需要动画的属性列表，形如 {x = 400, y = 300, scale = 1.5, alpha = 0.8}
--- @param duration number   动画时长（秒）
--- @param opts    table    可选参数：
---        .easing = function(t)   -- 缓动函数，默认线性
---        .onComplete = function() -- 动画结束回调
function Animation:new(target, props, duration, opts)
    opts = opts or {}
    local self = setmetatable({
        target = target,
        startProps = {}, -- 动画开始时的属性快照
        endProps = props, -- 目标属性
        duration = math.max(duration, 0.001),
        elapsed = 0,
        easing = opts.easing or function(t)
            return t
        end, -- 线性
        onComplete = opts.onComplete,
        finished = false
    }, Animation)

    -- 记录起始值（若目标属性不存在则使用 0）
    for k, v in pairs(props) do
        self.startProps[k] = target[k] or 0
    end
    return self
end

--- 更新动画进度（在 love.update 中调用）
function Animation:update(dt)
    if self.finished then
        return
    end

    self.elapsed = self.elapsed + dt
    local t = math.min(self.elapsed / self.duration, 1) -- 归一化到 [0,1]
    t = self.easing(t) -- 应用缓动

    for k, vEnd in pairs(self.endProps) do
        local vStart = self.startProps[k] or 0
        -- 线性插值（lerp）
        self.target[k] = vStart + (vEnd - vStart) * t
    end

    if self.elapsed >= self.duration then
        self.finished = true
        if self.onComplete then
            self.onComplete()
        end
    end
end

--- 立即结束动画（可选）
function Animation:finish()
    for k, vEnd in pairs(self.endProps) do
        self.target[k] = vEnd
    end
    self.finished = true
    if self.onComplete then
        self.onComplete()
    end
end

-- local function test()
--     table.insert(anims, Animation:new(button, {
--         x = 400,
--         y = 300,
--         scale = 1.5
--     }, 1.2, {
--         easing = Ease.outQuad,
--         onComplete = function()
--             print("移动+放大完成")
--             -- 再做一次淡出动画作为演示
--             table.insert(anims, Animation:new(button, {
--                 alpha = 0
--             }, 0.8, {
--                 easing = Ease.inOutCubic
--             }))
--         end
--     }))
-- end


local animationOut={
    anims={},
    animation=Animation
}

function animationOut:update(dt)
    local removeid ={}
    for i, v in ipairs(animationOut.anims) do
        v:update(dt)
        if v.finished then
            table.insert(removeid,i)
        end
    end
    for i = #removeid, 1, -1 do
        table.remove(animationOut.anims,removeid[i])
    end
end

function animationOut:addAnimation(target, props, duration, opts)
    table.insert(self.anims, Animation:new(target, props, duration,opts))
end 

return animationOut
