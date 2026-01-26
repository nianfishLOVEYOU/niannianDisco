--[[ -------------------------------------------------
   EventManager：通用事件监听管理器
   功能：注册、注销、一次性监听、优先级、批量清理
   适用：游戏、UI、网络、插件等任意模块
   新增：支持通过注册 ID 精确卸载事件监听器
---------------------------------------------------]]
local EventManager = {
    _listeners = {},   -- { [event] = { list = {}, need_sort = false, id_map = {} } }
    _idCounter = 0,    -- 为每个监听生成唯一 id
    _idToEvent = {},   -- 存储 id 到事件的映射 { [id] = event }
    _idToIndex = {},   -- 存储 id 到索引的映射 { [id] = index }
}

-- 内部工具：确保事件表存在
local function ensure(event)
    if not EventManager._listeners[event] then
        EventManager._listeners[event] = { 
            list = {}, 
            need_sort = false,
            id_map = {}  -- 存储该事件下的 id 映射
        }
    end
end

-- 注册监听
-- opts 可选字段：target（对象）、once（bool）、priority（数值，默认 0）
-- 返回：注册 ID，可用于精确卸载
function EventManager:on(event, func, opts)
    --print("eventmanager on : "..event)
    assert(event, "event name is nil")
    assert(type(func) == "function", "listener must be a function")
    opts = opts or {}

    ensure(event)
    local id = EventManager._idCounter + 1
    EventManager._idCounter = id
    
    local entry = {
        id       = id,
        func     = func,
        target   = opts.target,
        once     = opts.once or false,
        priority = opts.priority or 0,
    }
    
    local eventTable = EventManager._listeners[event]
    local index = #eventTable.list + 1
    eventTable.list[index] = entry
    eventTable.id_map[id] = index
    
    -- 存储反向映射
    EventManager._idToEvent[id] = event
    EventManager._idToIndex[id] = index

    -- 若有优先级则标记需要排序
    if entry.priority ~= 0 then
        eventTable.need_sort = true
    end
    
    return id   -- 返回 id，方便后续精确删除
end

-- 通过 ID 移除监听（推荐使用这种方式，效率更高）
function EventManager:offById(id)
    local event = EventManager._idToEvent[id]
    if not event then
        return false
    end
    
    local eventTable = EventManager._listeners[event]
    if not eventTable then
        EventManager._idToEvent[id] = nil
        EventManager._idToIndex[id] = nil
        return false
    end
    
    local index = EventManager._idToIndex[id]
    if not index or not eventTable.list[index] or eventTable.list[index].id ~= id then
        -- 如果找不到对应的条目，可能是索引已过时
        -- 重新扫描整个列表
        for i, entry in ipairs(eventTable.list) do
            if entry.id == id then
                index = i
                break
            end
        end
        if not index then
            EventManager._idToEvent[id] = nil
            EventManager._idToIndex[id] = nil
            return false
        end
    end
    
    -- 移除条目
    table.remove(eventTable.list, index)
    
    -- 清理 ID 映射
    eventTable.id_map[id] = nil
    EventManager._idToEvent[id] = nil
    EventManager._idToIndex[id] = nil
    
    -- 更新其他索引
    for otherId, otherIndex in pairs(eventTable.id_map) do
        if otherIndex > index then
            eventTable.id_map[otherId] = otherIndex - 1
            EventManager._idToIndex[otherId] = otherIndex - 1
        end
    end
    
    -- 如果列表为空，清理整个事件表
    if #eventTable.list == 0 then
        EventManager._listeners[event] = nil
    end
    
    return true
end

-- 移除监听（兼容原有接口）
-- 可以传 func 和 target，也可以只传 func
function EventManager:off(event, func, target)
    -- 如果第一个参数是数字，说明是 ID
    if type(event) == "number" then
        return self:offById(event)
    end
    
    local eventTable = EventManager._listeners[event]
    if not eventTable then 
        return false 
    end
    
    local removed = false
    local i = 1
    while i <= #eventTable.list do
        local l = eventTable.list[i]
        if l.func == func and (target == nil or l.target == target) then
            -- 清理 ID 映射
            local id = l.id
            eventTable.id_map[id] = nil
            EventManager._idToEvent[id] = nil
            EventManager._idToIndex[id] = nil
            
            -- 移除条目
            table.remove(eventTable.list, i)
            
            -- 更新其他索引
            for otherId, otherIndex in pairs(eventTable.id_map) do
                if otherIndex > i then
                    eventTable.id_map[otherId] = otherIndex - 1
                    EventManager._idToIndex[otherId] = otherIndex - 1
                end
            end
            
            removed = true
        else
            i = i + 1
        end
    end
    
    -- 如果列表为空，清理整个事件表
    if #eventTable.list == 0 then
        EventManager._listeners[event] = nil
    end
    
    return removed
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
    local eventTable = EventManager._listeners[event]
    if not eventTable or #eventTable.list == 0 then 
        return 
    end

    -- 若有优先级需要排序，按 priority 降序排列（数值大先执行）
    if eventTable.need_sort then
        table.sort(eventTable.list, function(a, b) 
            return a.priority > b.priority 
        end)
        
        -- 重新建立索引映射
        eventTable.id_map = {}
        for i, entry in ipairs(eventTable.list) do
            eventTable.id_map[entry.id] = i
            EventManager._idToIndex[entry.id] = i
        end
        
        eventTable.need_sort = false
    end

    -- 复制一份列表，防止回调里修改原表导致遍历错误
    local listeners = {}
    for i, v in ipairs(eventTable.list) do 
        listeners[i] = v 
    end
    
    local toRemove = {}  -- 记录需要移除的一次性监听器 ID

    for _, l in ipairs(listeners) do
        if l.target then
            l.func(l.target, ...)  -- 目标对象作为第一个参数
        else
            l.func(...)
        end
        
        if l.once then
            -- 记录需要移除的一次性监听器
            table.insert(toRemove, l.id)
        end
    end
    
    -- 移除一次性监听器
    for _, id in ipairs(toRemove) do
        self:offById(id)
    end
end

-- 清空指定事件或全部事件的监听
function EventManager:clear(event)
    if event then
        local eventTable = EventManager._listeners[event]
        if eventTable then
            -- 清理该事件下的所有 ID 映射
            for id, _ in pairs(eventTable.id_map) do
                EventManager._idToEvent[id] = nil
                EventManager._idToIndex[id] = nil
            end
        end
        self._listeners[event] = nil
    else
        -- 清空所有
        self._listeners = {}
        self._idToEvent = {}
        self._idToIndex = {}
    end
end

-- 检查 ID 是否有效
function EventManager:isValidId(id)
    return EventManager._idToEvent[id] ~= nil
end

-- 获取指定事件的所有监听器 ID
function EventManager:getListenerIds(event)
    local eventTable = self._listeners[event]
    if not eventTable then
        return {}
    end
    
    local ids = {}
    for id, _ in pairs(eventTable.id_map) do
        table.insert(ids, id)
    end
    return ids
end

-- 获取所有监听器 ID
function EventManager:getAllListenerIds()
    local allIds = {}
    for id, _ in pairs(self._idToEvent) do
        table.insert(allIds, id)
    end
    return allIds
end

-- 通过 ID 获取监听器信息
function EventManager:getListenerInfo(id)
    local event = self._idToEvent[id]
    if not event then
        return nil
    end
    
    local eventTable = self._listeners[event]
    if not eventTable then
        return nil
    end
    
    local index = self._idToIndex[id]
    if not index or not eventTable.list[index] then
        return nil
    end
    
    local entry = eventTable.list[index]
    return {
        event = event,
        func = entry.func,
        target = entry.target,
        once = entry.once,
        priority = entry.priority
    }
end

-- 让模块直接返回单例
return EventManager