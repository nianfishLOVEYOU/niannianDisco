-- dialogue.lua
local json = require "lib.json"

local DialogueEngine = {}
DialogueEngine.__index = DialogueEngine

-- 安全的条件求值（只暴露 state 和 math）
local function eval_condition(cond, state)
    if cond == "true" then
        return true
    end
    if cond == "false" then
        return false
    end
    -- 构建一个 Lua 函数，限制全局环境为 { state = state, math = math }
    local env = {
        state = state,
        math = math
    }
    local func, err = load("return " .. cond, "condition", "t", env)
    if not func then
        print("[警告] 条件表达式错误: " .. cond .. " -> " .. err)
        return false
    end
    local ok, res = pcall(func)
    if not ok then
        print("[警告] 条件执行错误: " .. cond .. " -> " .. res)
        return false
    end
    return res
end

-- 应用效果（支持嵌套路径，如 "player.hp"）
local function apply_effects(effects, state)
    if not effects then
        return
    end
    for path, value in pairs(effects) do
        local parts = {}
        for part in string.gmatch(path, "[^%.]+") do
            table.insert(parts, part)
        end
        local cur = state
        for i = 1, #parts - 1 do
            if cur[parts[i]] == nil then
                cur[parts[i]] = {}
            end
            cur = cur[parts[i]]
        end
        cur[parts[#parts]] = value
    end
end

-- 获取节点的实际文本（支持变体、变量替换）
local function get_node_text(node, state)
    local raw_text = nil
    if node.text_variants and #node.text_variants > 0 then
        local idx = math.random(1, #node.text_variants)
        raw_text = node.text_variants[idx]
    else
        raw_text = node.text or ""
    end
    -- 替换变量 {{path}}
    local result = raw_text:gsub("{{([^}]+)}}", function(path)
        local parts = {}
        for part in string.gmatch(path, "[^%.]+") do
            table.insert(parts, part)
        end
        local cur = state
        for _, part in ipairs(parts) do
            if type(cur) ~= "table" then
                return "?"
            end
            cur = cur[part]
            if cur == nil then
                return "?"
            end
        end
        return tostring(cur)
    end)
    return result
end

-- 从 random_next 中按权重选择一项（并应用其 effects）
local function select_random_next(node, state)
    if not node.random_next then
        return nil
    end
    local weighted = {}
    local total = 0
    for _, item in ipairs(node.random_next) do
        local cond = item.condition or "true"
        if eval_condition(cond, state) then
            table.insert(weighted, item)
            total = total + item.weight
        end
    end
    if total == 0 then
        return nil
    end
    local r = math.random() * total
    local accum = 0
    for _, item in ipairs(weighted) do
        accum = accum + item.weight
        if r <= accum then
            if item.effects then
                apply_effects(item.effects, state)
            end
            return item.next
        end
    end
    return nil
end

function DialogueEngine.new(json_data, initial_state)
    local self = setmetatable({}, DialogueEngine)
    -- 如果传入的是 JSON 字符串，先解析
    if type(json_data) == "string" then
        self.data = json.decode(json_data)
    else
        self.data = json_data
    end

    if self.data==nil then
        print("[错误] 对话数据解析失败！")
        self.data = { nodes = {}, start_node = nil }
    end
    self.state = initial_state or {}
    self.current_node_id = self.data.start_node
    self.history = {} -- 可选：记录选择历史
    return self
end

function DialogueEngine:get_current_node()
    return self.data.nodes[self.current_node_id]
end

-- 获取当前节点可用的选项（已过滤条件、已随机排序）
function DialogueEngine:get_options()
    local node = self:get_current_node()
    if not node or not node.options then
        return {}
    end
    local opts = {}
    for _, opt in ipairs(node.options) do
        if eval_condition(opt.condition or "true", self.state) then
            table.insert(opts, opt)
        end
    end
    -- 随机打乱顺序，增加新鲜感
    for i = #opts, 2, -1 do
        local j = math.random(i)
        opts[i], opts[j] = opts[j], opts[i]
    end
    return opts
end

-- 玩家选择某个选项（按索引 1..n）
-- 返回: (success, continue_flag)
function DialogueEngine:select_option(opt_index)
    local opts = self:get_options()
    if opt_index < 1 or opt_index > #opts then
        return false, false
    end
    local opt = opts[opt_index]
    if opt.effects then
        apply_effects(opt.effects, self.state)
    end
    local next_id = opt.next
    if not next_id then
        self.current_node_id = nil
        return true, false
    end
    self.current_node_id = next_id
    return true, true
end

-- 自动前进（用于无选项的节点，按 random_next 或 固定 next）
-- 返回是否还有下一句
function DialogueEngine:auto_advance()
    local node = self:get_current_node()
    if not node then
        return false
    end
    local next_id = select_random_next(node, self.state)
    if not next_id then
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

function DialogueEngine:get_current_text()
    local node = self:get_current_node()
    if not node then
        return ""
    end
    return get_node_text(node, self.state)
end

function DialogueEngine:get_current_speaker()
    local node = self:get_current_node()
    return node and node.speaker or nil
end

function DialogueEngine:is_finished()
    return self.current_node_id == nil or self.data.nodes[self.current_node_id] == nil
end

function DialogueEngine:reset(start_node_id)
    self.current_node_id = start_node_id or self.data.start_node
end

--重置
function DialogueEngine:reNew()
    GlobleManager:saveGameData("好感度", 10)
    GlobleManager:saveGameData("听歌时长", 10)
    GlobleManager:saveGameData("上次下线时间", 10)
    GlobleManager:saveGameData("听歌次数", 10)
end

return DialogueEngine
