--[[ -------------------------------------------------
   EventManager：通用事件监听管理器
   功能：注册、注销、一次性监听、优先级、批量清理
   适用：游戏、UI、网络、插件等任意模块
---------------------------------------------------]]
local EventManager = {
    _listeners = {},   -- { [event] = { {func=..., target=..., once=bool, priority=number}, ... } }
    _idCounter = 0,    -- 为每个监听生成唯一 id（内部使用）
}

-- 内部工具：确保事件表存在
local function ensure(event)
    if not EventManager._listeners[event] then
        EventManager._listeners[event] = { list = {}, need_sort = false }
    end
end

-- 注册监听
-- opts 可选字段：target（对象）、once（bool）、priority（数值，默认 0）
function EventManager:on(event, func, opts)
    --print("eventmanager on : "..event)
    assert(event, "event name is nil")
    assert(type(func) == "function", "listener must be a function")
    opts = opts or {}

    ensure(event)
    local entry = {
        id       = EventManager._idCounter + 1,
        func     = func,
        target   = opts.target,
        once     = opts.once or false,
        priority = opts.priority or 0,
    }
    EventManager._idCounter = entry.id

    table.insert(EventManager._listeners[event].list, entry)

    -- 若有优先级则标记需要排序
    if entry.priority ~= 0 then
        EventManager._listeners[event].need_sort = true
    end
    return entry.id   -- 返回 id，方便后续精确删除
end

-- 移除监听
-- 既可以只传 func，也可以同时传 target（防止同一函数在不同对象上重复注册的情况）
function EventManager:off(event, func, target)
    local tbl = EventManager._listeners[event]
    if not tbl then return false end

    for i = #tbl.list, 1, -1 do
        local l = tbl.list[i]
        if l.func == func and (target == nil or l.target == target) then
            table.remove(tbl.list, i)   -- 参考实现：直接删除对应条目[[4]]
            return true
        end
    end
    return false
end

-- 一次性监听（触发后自动注销）
function EventManager:once(event, func, opts)
    opts = opts or {}
    opts.once = true
    return self:on(event, func, opts)
end

-- 触发事件
function EventManager:emit(event, ...)
    -- if event~="update" and event ~="draw" and event ~="event_mouseMoved" then
    --     print("      {} event :",event)
    -- end
    local tbl = EventManager._listeners[event]
    if not tbl or #tbl.list == 0 then return end

    -- 若有优先级需要排序，按 priority 降序排列（数值大先执行）[[5]]
    if tbl.need_sort then
        table.sort(tbl.list, function(a, b) return a.priority > b.priority end)
        tbl.need_sort = false
    end

    -- 复制一份列表，防止回调里修改原表导致遍历错误
    local listeners = {}
    for i, v in ipairs(tbl.list) do listeners[i] = v end

    for _, l in ipairs(listeners) do
        if l.target then
            l.func(l.target, ...)          -- 目标对象作为第一个参数
        else
            l.func(...)
        end
        if l.once then      
            --print("!!!  remove  event  :".. event)               -- 一次性监听自动移除
            self:off(event, l.func, l.target)
        end
    end
end

-- 清空指定事件或全部事件的监听
function EventManager:clear(event)
    if event then
        self._listeners[event] = nil
    else
        self._listeners = {}
    end
end

-- 让模块直接返回单例
return EventManager