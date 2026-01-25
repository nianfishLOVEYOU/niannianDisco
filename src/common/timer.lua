-- 计时器模块（支持延迟执行、委托回调、任务取消）
local Timer = {
    tasks = {},  -- 存储所有计时任务
    nextId = 1   -- 任务唯一ID生成器
}

-- 注册延迟执行任务（核心函数）
-- 参数：
--   delay: 延迟时间（秒）
--   callback: 延迟后执行的委托（回调函数）
--   args: 可选，传递给回调的参数（可变参数）
-- 返回值：任务ID（用于取消任务）
function Timer:after(delay, callback)
    -- 参数校验
    if type(delay) ~= "number" or delay < 0 then
        error("延迟时间必须是大于等于0的数字")
    end
    if type(callback) ~= "function" then
        error("回调必须是函数（委托）")
    end

    -- 生成唯一任务ID
    local taskId = self.nextId
    self.nextId = self.nextId + 1

    -- 存储任务信息
    table.insert(self.tasks, {
        id = taskId,
        delay = delay,
        elapsed = 0,       -- 已流逝时间
        callback = callback,
        isCanceled = false, -- 是否取消
        type = "once"      -- 任务类型：一次性
    })

    return taskId
end

-- 在指定时间内不断执行的任务
-- 参数：
--   interval: 每次执行间隔（秒）
--   duration: 总持续时间（秒）
--   callback: 每次触发执行的函数，签名为 function(passed, remain) end
--             passed 为已运行时间，remain 为剩余时间
-- 返回：任务ID（用于取消）
function Timer:during(interval, duration, callback)
    if type(interval) ~= "number" or interval <= 0 then
        error("interval 必须是大于0的数字")
    end
    if type(duration) ~= "number" or duration <= 0 then
        error("duration 必须是大于0的数字")
    end
    if type(callback) ~= "function" then
        error("callback 必须是函数")
    end

    local taskId = self.nextId
    self.nextId = self.nextId + 1

    table.insert(self.tasks, {
        id = taskId,
        delay = interval,
        elapsed = 0,
        passed = 0,         -- 已运行总时间
        duration = duration,
        callback = callback,
        isCanceled = false,
        type = "interval"  -- 任务类型：在一段时间内循环
    })

    return taskId
end

-- 取消指定ID的延迟任务
-- 参数：taskId 调用:after 返回的任务ID
function Timer:cancel(taskId)
    for i, task in ipairs(self.tasks) do
        if task.id == taskId then
            task.isCanceled = true
            table.remove(self.tasks, i) -- 立即移除，减少遍历开销
            return true -- 取消成功
        end
    end
    return false -- 未找到任务
end

-- 清空所有未执行的任务
function Timer:clear()
    self.tasks = {}
end

-- 每帧更新（必须在love.update中调用）
-- 参数：dt 每帧时间增量（秒）
function Timer:update(dt)
    -- 倒序遍历，避免移除元素导致索引错乱
    for i = #self.tasks, 1, -1 do
        local task = self.tasks[i]
        
        -- 跳过已取消的任务（理论上已被移除，做双重校验）
        if task.isCanceled then
            table.remove(self.tasks, i)
            goto continue
        end

        -- 累计时间
        task.elapsed = task.elapsed + dt
        if task.type == "interval" then
            task.passed = task.passed + dt
        end

        -- 时间达标，执行委托回调
        if task.elapsed >= task.delay then
            if task.type == "once" then
                -- 一次性任务：直接调用并移除
                task.callback()
                table.remove(self.tasks, i)
            elseif task.type == "interval" then
                -- 在持续时间内循环执行
                if task.passed <= task.duration then
                    task.elapsed = task.elapsed - task.delay
                    local remain = task.duration - task.passed
                    task.callback(task.passed, remain)
                    -- 如果已经超过总时长，则移除
                    if task.passed >= task.duration then
                        table.remove(self.tasks, i)
                    end
                else
                    -- 超出总时长，直接移除
                    table.remove(self.tasks, i)
                end
            end
        end

        ::continue::
    end
end

-- 导出模块（支持单例使用）
return Timer