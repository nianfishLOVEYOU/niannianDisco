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
        isCanceled = false -- 是否取消
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

        -- 时间达标，执行委托回调
        if task.elapsed >= task.delay then
            -- 执行回调并传递参数
            task.callback()
            -- 移除已完成的任务
            table.remove(self.tasks, i)
        end

        ::continue::
    end
end

-- 导出模块（支持单例使用）
return Timer