local Animator = {}
Animator.__index = Animator

local Easing = {
    linear = function(t)
        return t
    end, -- 线性
    easeIn = function(t)
        return t * t
    end, -- 加速
    easeOut = function(t)
        return 1 - (1 - t) * (1 - t)
    end, -- 减速
    easeInOut = function(t)
        return t < 0.5 and 2 * t * t or 1 - 2 * (1 - t) * (1 - t)
    end -- 加速减速
}

local function getNestedValue(root, path)
    local val = root
    for _, key in ipairs(path) do
        if val == nil then
            break
        end
        val = val[key]
    end
    return val
end

local function setNestedValue(root, path, value)
    local cur = root
    local len = #path
    for i = 1, len - 1 do
        local key = path[i]
        if cur[key] == nil then
            cur[key] = {}
        end
        cur = cur[key]
    end
    cur[path[len]] = value
end

local function strToPath(str)
    local path = {}
    for s in string.gmatch(str, "[^%.]+") do
        local num = tonumber(s)
        table.insert(path, num or s)
    end
    return path
end

local function lerpValue(a, b, t, easeFunc)
    if type(a) == "boolean" and type(b) == "boolean" then
        return t >= 0.5 and b or a
    end

    local tVal = easeFunc(t)
    if type(a) == "number" and type(b) == "number" then
        return a + (b - a) * tVal
    end

    if type(a) == "table" and type(b) == "table" then
        local res = {}
        for i = 1, math.max(#a, #b) do
            res[i] = (a[i] or 0) + ((b[i] or 0) - (a[i] or 0)) * tVal
        end
        return res
    end

    return a
end

function Animator.new()
    local self = setmetatable({}, Animator)
    self.tracks = {}
    self.globalSpeed = 1
    self.globalPlaying = true
    return self
end

function Animator:addTrack(trackName, target, pathInput, enable, loop, pingpong, ease)
    if self.tracks[trackName] then
        print("!!!  Track already exists: " .. trackName)
        return
    end
    local path = type(pathInput) == "string" and strToPath(pathInput) or pathInput

    self.tracks[trackName] = {
        target = target,
        path = path,
        enabled = enable ~= nil and enable or true,
        playing = true,
        time = 0,
        speed = 1,
        loop = loop or false,
        pingpong = pingpong or false,
        reverse = false,
        easeType = ease or "linear",
        keyframes = {}
    }
end

function Animator:clearKeyframes(trackName)
    local tr = self.tracks[trackName]
    if not tr then
        return
    end
    self.tracks[trackName] = nil
end

function Animator:clearAllKeyframes()
    for _, tr in pairs(self.tracks) do
        tr.keyframes = {}
    end
end

function Animator:addKeyframe(trackName, time, value)
    local tr = self.tracks[trackName]
    if not tr then
        return
    end
    for i = #tr.keyframes, 1, -1 do
        if tr.keyframes[i].time == time then
            table.remove(tr.keyframes, i)
        end
    end
    table.insert(tr.keyframes, {
        time = time,
        value = value
    })
    table.sort(tr.keyframes, function(a, b)
        return a.time < b.time
    end)
end

function Animator:removeKeyframe(trackName, time)
    local tr = self.tracks[trackName]
    if not tr then
        return
    end
    for i = #tr.keyframes, 1, -1 do
        if tr.keyframes[i].time == time then
            table.remove(tr.keyframes, i)
        end
    end
end

-- ======================= ✅ 核心修复：sampleTrack =======================
function Animator:sampleTrack(track)
    local f = track.keyframes
    local n = #f
    if n == 0 then
        return nil
    end
    if n == 1 then
        return f[1].value
    end

    local startTime = f[1].time
    local endTime = f[#f].time
    local duration = endTime - startTime

    local t = track.time

    -- 循环 + 往返（pingpong）逻辑修复
    if track.loop and duration > 0 then
        local cycle = t / duration
        local integral = math.floor(cycle)
        local frac = cycle - integral

        if track.pingpong then
            track.reverse = (integral % 2 == 1)
            if track.reverse then
                frac = 1 - frac
            end
            t = startTime + frac * duration
        else
            t = startTime + (t % duration)
        end
    end

    -- 查找关键帧区间
    local k1, k2 = f[1], f[#f]
    for i = 1, n - 1 do
        local curr = f[i]
        local nextf = f[i + 1]
        if t >= curr.time and t <= nextf.time then
            k1, k2 = curr, nextf
            break
        end
    end

    local dt = k2.time - k1.time
    if dt <= 0 then
        return k1.value
    end
    local ratio = (t - k1.time) / dt
    local ease = Easing[track.easeType] or Easing.linear
    return lerpValue(k1.value, k2.value, ratio, ease)
end

function Animator:update(dt)
    if not self.globalPlaying then
        return
    end
    for _, tr in pairs(self.tracks) do
        if not tr.enabled or not tr.playing then
            goto cont
        end
        tr.time = tr.time + dt * self.globalSpeed * tr.speed
        local val = self:sampleTrack(tr)
        if val ~= nil then
            setNestedValue(tr.target, tr.path, val)
        end
        ::cont::
    end
end

-- 保存 / 加载
function Animator:saveToFile(path)
    local json = require "lib.json"
    local data = {
        globalSpeed = self.globalSpeed,
        globalPlaying = self.globalPlaying,
        tracks = {}
    }
    for n, tr in pairs(self.tracks) do
        data.tracks[n] = {
            path = tr.path,
            enabled = tr.enabled,
            loop = tr.loop,
            pingpong = tr.pingpong,
            easeType = tr.easeType,
            keyframes = tr.keyframes
        }
    end
    return love.filesystem.write(path, json.encode(data, {
        indent = true
    }))
end

function Animator:loadFromFile(path)
    if not love.filesystem.getInfo(path) then
        return false
    end
    local dkjson = require("dkjson")
    local data = dkjson.decode(love.filesystem.read(path))
    if not data then
        return false
    end
    self.globalSpeed = data.globalSpeed or 1
    self.globalPlaying = data.globalPlaying ~= nil and data.globalPlaying
    for n, td in pairs(data.tracks or {}) do
        local tr = self.tracks[n]
        if tr then
            tr.enabled = td.enabled
            tr.loop = td.loop
            tr.pingpong = td.pingpong
            tr.easeType = td.easeType
            tr.keyframes = td.keyframes or {}
        end
    end
    return true
end

function Animator:setTrackEnable(n, e)
    if self.tracks[n] then
        self.tracks[n].enabled = e
    end
end
function Animator:resetAll()
    for _, t in pairs(self.tracks) do
        t.time = 0
        t.reverse = false
    end
end
function Animator:setGlobalPlay(p)
    self.globalPlaying = p
end

return Animator

-----------------说明书----------------

-- -- 禁用整条轨道（停止赋值该变量）
-- anim:setTrackEnable("posX", false)
-- -- 启用轨道
-- anim:setTrackEnable("posX", true)

-- -- 轨道单独暂停/播放
-- anim:setTrackPlay("scale", false)

-- -- 新增/覆盖关键帧 (时间, 数值)
-- anim:addKeyframe("轨道名", 时间, 值)

-- -- 删除指定时间关键帧
-- anim:removeKeyframe("轨道名", 时间)

-- -- 清空所有关键帧
-- anim:clearKeyframes("轨道名")

-- -- 保存到 json 文件
-- anim:saveToFile("anim_data.json")

-- -- 从文件加载
-- anim:loadFromFile("anim_data.json")

-- anim:setGlobalPlay(false) -- 全局暂停
-- anim:resetAll()           -- 重置所有轨道时间到起点

------------生命周期演示----------------

-- local Animator = require("keyframe_anim")

-- -- 被控制的目标对象 (任意自定义对象均可)
-- local actor = {
--     x = 200,
--     y = 200,
--     scale = 1,
--     color = {1, 1, 1, 1} -- RGBA 数组
-- }

-- local anim

-- function love.load()
--     -- 初始化动画器
--     anim = Animator.new()

--     -- 添加多条轨道：位置X、位置Y、缩放、颜色
--     -- 参数：轨道名, 目标, 字段, 启用, 循环, 往返, 插值模式
--     anim:addTrack("posX", actor, "x", true, true, true, "easeInOut")
--     anim:addTrack("posY", actor, "y", true, true, false, "linear")
--     anim:addTrack("scale", actor, "scale", true, true, false, "easeOut")
--     anim:addTrack("color", actor, "color", true, true, true, "linear")

--     -- ========== 设置关键帧 ==========
--     -- X 坐标关键帧
--     anim:addKeyframe("posX", 0, 200)
--     anim:addKeyframe("posX", 3, 500)
--     anim:addKeyframe("posX", 6, 200)

--     -- Y 坐标关键帧
--     anim:addKeyframe("posY", 0, 200)
--     anim:addKeyframe("posY", 3, 400)
--     anim:addKeyframe("posY", 6, 200)

--     -- 缩放关键帧
--     anim:addKeyframe("scale", 0, 1)
--     anim:addKeyframe("scale", 3, 1.8)
--     anim:addKeyframe("scale", 6, 1)

--     -- 颜色关键帧 (数组插值)
--     anim:addKeyframe("color", 0, {1,1,1,1})
--     anim:addKeyframe("color", 3, {1,0.2,0.2,1})
--     anim:addKeyframe("color", 6, {1,1,1,1})
-- end

-- function love.update(dt)
--     -- 必须每帧调用更新
--     anim:update(dt)
-- end

-- function love.draw()
--     -- 绘制被动画控制的图形
--     love.graphics.setColor(actor.color)
--     love.graphics.circle("fill", actor.x, actor.y, 40 * actor.scale)
--     love.graphics.setColor(1,1,1)

--     -- 操作提示
--     love.graphics.print([[
-- 操作说明：
-- 1 - 开关X轨道 | 2 - 开关颜色轨道
-- S - 保存动画 | L - 加载动画
-- SPACE - 全局暂停/播放
-- R - 重置所有动画
-- ]], 20, 20)
-- end

-- -- 键盘交互
-- function love.keypressed(key)
--     if key == "1" then
--         local tr = anim.tracks.posX
--         anim:setTrackEnable("posX", not tr.enabled)
--     end

--     if key == "2" then
--         local tr = anim.tracks.color
--         anim:setTrackEnable("color", not tr.enabled)
--     end

--     if key == "s" then
--         anim:saveToFile("anim_data.json")
--         print("动画已保存")
--     end

--     if key == "l" then
--         local ok = anim:loadFromFile("anim_data.json")
--         print(ok and "动画加载成功" or "加载失败")
--     end

--     if key == "space" then
--         anim:setGlobalPlay(not anim.globalPlaying)
--     end

--     if key == "r" then
--         anim:resetAll()
--     end
-- end

