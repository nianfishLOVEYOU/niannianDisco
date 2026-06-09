-- DialogueManager.lua
local DialogueManager = {}
DialogueManager.__index = DialogueManager

-- 辅助：安全地解析简单条件表达式（支持 math.random, 全局状态变量）
local function eval_condition(cond, state)
    if cond == "true" then return true end
    if cond == "false" then return false end
    -- 构造一个函数，将 state 中的变量注入为局部变量
    -- 例如 cond = "player.hp > 10"  → 尝试用 state["player.hp"] 或 state.player.hp
    -- 这里简化处理：将点号替换为下划线，直接访问 state 表
    local expr = cond:gsub("([%w_]+)%.",
        function(var) return string.format("state['%s'].", var) end)
    -- 注意：为了支持 math.random，允许调用全局函数
    local f, err = load("return " .. expr, "condition", "t", { state = state, math = math })
    if not f then
        error("条件表达式错误: " .. cond .. " -> " .. err)
    end
    local ok, res = pcall(f)
    if not ok then return false end
    return res
end

-- 应用效果，修改 state
local function apply_effects(effects, state)
    for k, v in pairs(effects) do
        -- 支持嵌套路径，如 "player.hp"
        local parts = {}
        for part in string.gmatch(k, "[^%.]+") do
            table.insert(parts, part)
        end
        local cur = state
        for i = 1, #parts - 1 do
            if cur[parts[i]] == nil then cur[parts[i]] = {} end
            cur = cur[parts[i]]
        end
        cur[parts[#parts]] = v
    end
end

-- 从节点中获取实际文本（支持 text_variants）
local function get_node_text(node)
    if node.text_variants and #node.text_variants > 0 then
        local idx = math.random(1, #node.text_variants)
        return node.text_variants[idx]
    end
    return node.text or ""
end

-- 从 random_next 中按权重选择下一节点
local function get_random_next(node, state)
    if not node.random_next then return nil end
    local total = 0
    for _, opt in ipairs(node.random_next) do
        local cond = opt.condition or "true"
        if eval_condition(cond, state) then
            total = total + opt.weight
        end
    end
    if total == 0 then return nil end
    local r = math.random() * total
    local accum = 0
    for _, opt in ipairs(node.random_next) do
        local cond = opt.condition or "true"
        if eval_condition(cond, state) then
            accum = accum + opt.weight
            if r <= accum then
                if opt.effects then apply_effects(opt.effects, state) end
                return opt.next
            end
        end
    end
    return nil
end

-- 构造函数
function DialogueManager.new(dialogue_data, initial_state)
    local self = setmetatable({}, DialogueManager)
    self.data = dialogue_data          -- 节点表
    self.state = initial_state or {}   -- 游戏状态（可包含 player, world 等）
    self.current_node_id = dialogue_data.start_node or "start"
    self.history = {}                  -- 记录玩家选择，用于后续趣味逻辑（本示例未完全展开）
    return self
end

-- 获取当前节点（表）
function DialogueManager:get_current_node()
    return self.data.nodes[self.current_node_id]
end

-- 获取当前节点的可用选项（已过滤条件，并随机排序）
function DialogueManager:get_options()
    local node = self:get_current_node()
    if not node or not node.options then return {} end
    local opts = {}
    for _, opt in ipairs(node.options) do
        if eval_condition(opt.condition, self.state) then
            table.insert(opts, opt)
        end
    end
    -- 随机排序选项，增加新鲜感
    for i = #opts, 2, -1 do
        local j = math.random(i)
        opts[i], opts[j] = opts[j], opts[i]
    end
    return opts
end

-- 玩家选择一个选项（传入选项索引，从1开始）
-- 返回：是否成功（选项有效）、是否对话继续（若 next 存在则为 true，否则结束）
function DialogueManager:select_option(opt_idx)
    local opts = self:get_options()
    if opt_idx < 1 or opt_idx > #opts then return false, false end
    local opt = opts[opt_idx]
    -- 应用效果
    if opt.effects then
        apply_effects(opt.effects, self.state)
    end
    -- 跳转到下一节点
    local next_id = opt.next
    if not next_id or next_id == "" then
        self.current_node_id = nil
        return true, false   -- 对话结束
    end
    self.current_node_id = next_id
    return true, true
end

-- 自动前进（当节点没有选项时，按 random_next 或固定 next 跳转）
-- 返回：是否还有下一句（true表示继续，false表示对话结束）
function DialogueManager:auto_advance()
    local node = self:get_current_node()
    if not node then return false end

    -- 如果存在随机跳转，使用随机跳转
    local next_id = get_random_next(node, self.state)
    if not next_id and node.next then
        next_id = node.next
    end
    if next_id then
        self.current_node_id = next_id
        return true
    else
        self.current_node_id = nil
        return false
    end
end

-- 显示当前对话文本（用于UI）
function DialogueManager:get_current_text()
    local node = self:get_current_node()
    if not node then return "" end
    return get_node_text(node)
end

-- 判断对话是否结束
function DialogueManager:is_finished()
    return self.current_node_id == nil or self.data.nodes[self.current_node_id] == nil
end

-- 重置对话（从某个节点开始）
function DialogueManager:reset(start_node_id)
    self.current_node_id = start_node_id or self.data.start_node
end

return DialogueManager