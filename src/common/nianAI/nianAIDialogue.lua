-- dialogue.lua
local json = require "lib.json"

local DialogueEngine = {
    data = nil, -- 对话数据表
    state = nil, -- 当前游戏状态（可供条件判断和文本替换）
    topic_interval = 3,
    topic_intervalMax = 10, -- 最长冷却话题
    start=true
}

DialogueEngine.__index = DialogueEngine

local dialogWaitTime = 2
local isDialogueFinished = true
local WaitTimeMode = true -- 是否自动下一句
local dialogUI = nil -- 对话UI实例

local function getRandomTopicInterval()
    return math.random(3, DialogueEngine.topic_intervalMax)
end

-- 检查是否达到要求的冷却时间
local function chackNodeInterval(node)
    if node.type ~= "topic" then
        return false
    end
    if node.interval=="" or tonumber(node.interval) == 0 then
        return true
    end

    local lastTime = DialogueEngine.state.dialogue_Record[node.id] and
                         DialogueEngine.state.dialogue_Record[node.id].lastTime or os.time()
    local interval = os.time() - lastTime
    if interval >=  tonumber(node.interval) then
        return true
    else
        print(string.format("节点 %s 冷却中，剩余时间: %ds", node.id, interval -  tonumber(node.interval)))
        return false
    end
end

-- 安全的条件求值（只暴露 state 和 math）通过str表达式来执行代码
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

function DialogueEngine:nodePrint(dialog, node, WaitTimeMode)
    if node then
        -- 弹出窗口聊天
        if self.lastDialogueId then --关闭上次
            floatUI:closeDialogueBox(self.lastDialogueId)
        end

        local nodeTime = dialog.state.dialogue_Record[node.id] and dialog.state.dialogue_Record[node.id].times or 0
        print("[当前节点]", node.id, "经历次数：", nodeTime, "文本:", node.text, "选项:", #node.options)

        local text = dialog:get_current_text()
        local speaker = dialog:get_current_speaker()
        local opts = dialog:get_options()
        local waitTime = 0
        if WaitTimeMode then
            waitTime = tonumber(node.waitTime)
        else
            waitTime = 0
        end
        print("waitTime:", waitTime)
        nianDebug.printStackTrace("当前节点ID:", node.id)
        self.lastDialogueId =floatUI:addDialogueBox(text, 130, 280, {
            typeSpeed = 10,
            autoClose = waitTime,
            tailX = 250,
            tailY = 300
        })
        -- nianAI.message = print("当前节点ID:", dialog.current_node_id)
    else
        print("当前没有有效节点")
    end
end

-- 获取节点的实际文本（支持变体、变量替换）
function DialogueEngine:get_node_text(node, state)
    local raw_text = nil

    local nodeTime = self.state.dialogue_Record[node.id] and self.state.dialogue_Record[node.id].times or 0

    if nodeTime > 0 and node.text_variants ~= "" then -- 获取变体，在第一个已经经历之后
        -- nianTool.dump(node.text_variants)
        local vNode_id = self:_nodeSelect(node, node.text_variants, state)
        local vNode = self.data[vNode_id]
        print("文本变体选择:", vNode)

        raw_text = vNode and vNode.text
    else
        raw_text = node.text or ""
    end

    if raw_text == nil then
        print("[警告] 节点文本为空，id:", node.id)
        return ""
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

    if tonumber(node.waitTime) == -1 then
        result = result .. " ...... "
    end
    return result
end

-- 返回node_id
-- 从 random_next 中按权重选择一项（并应用其 effects） 或者根据条件判断选择
function DialogueEngine:select_random_next(node, state)
    if node.next == "" then
        return nil
    end

    local next_id = self:_nodeSelect(node, node.next, state)
    local next_node = self.data[next_id]

    return next_node
end

-- 从nodelist中选择下一步node
function DialogueEngine:_nodeSelect(node, nodeIdList, state)

    local total = 0
    local weighted = {}

    for key, nextId in ipairs(nodeIdList) do
        local node_Next = self.data[nextId]
        if not node_Next then
            nianDebug.printStackTrace("nodeSelect node缺失 : " .. nextId)
            break
        end
        print("nodeSelect:", nextId, node_Next.condition.type)
        if node_Next.condition ~= "" then -- 有条件
            if node_Next.condition.type == "weight" then -- 根据权重选择
                total = total + node_Next.condition.value
                table.insert(weighted, { -- 加入判断表
                    weight = tonumber(node_Next.condition.value),
                    nodeid = nextId
                })
            elseif node_Next.condition.type == "auto" then -- 没有条件

            elseif node_Next.condition.type == "manual" then -- 需要满足条件才会出现
                local cond = node_Next.condition.value or "true"
                if eval_condition(cond, state) then -- 执行操作了
                    return nextId -- 返回条件判断的下一步
                end
            end
        else -- 没有条件
            return nextId
        end
    end
    -- print("开始按权---")
    if total ~= 0 then -- 说明是权重选择
        local random = math.random() * total
        for _, item in ipairs(weighted) do
            random = random - item.weight
            -- print("按照权重选择node对象:", node.id, "下一步node对象:", item.nodeid, "权重:", item.weight,
            --    "剩余随机数:", random)
            if random <= 0 then
                return item.nodeid -- 返回权重的下一步
            end
        end
    end

    -- print("[警告] 没有符合条件的下一步，node id:", node.id)
    return nil
end

function DialogueEngine:new(json_Path)
    -- 1. 加载对话 JSON
    local file = love.filesystem.newFile("excel/dialogue.json")
    file:open("r")
    local json_str = file:read(file:getSize())
    file:close()
    local json_data = json_str
    local self = setmetatable({}, DialogueEngine)

    -- 如果传入的是 JSON 字符串，先解析
    if type(json_data) == "string" then
        self.data = json.decode(json_data)
    else
        self.data = json_data
    end

    if self.data == nil then
        print(json_data, "[错误] 对话数据解析失败！")
        self.data = {
            nodes = {},
            start_node = nil
        }
    end

    self:reNew() -- 加载状态
    --self:reset("first") -- 初始化当前节点
    self.history = {} -- 可选：记录选择历史
    return self
end

function DialogueEngine:get_current_node()
    return self.data[self.current_node_id]
end

-- 获取当前节点可用的选项（已过滤条件、已随机排序）
function DialogueEngine:get_options()
    local node = self:get_current_node()
    if not node or node.options == "" then
        return {}
    end
    local opts = {}
    for _, opt in ipairs(node.options) do
        if eval_condition(opt.condition, self.state) then
            table.insert(opts, opt) -- 收集选项
        end
    end
    return opts
end

-- 玩家选择某个选项（按索引 1..n）
-- 返回: (success, continue_flag)
function DialogueEngine:select_option(opt_index)
    local opts = self:get_options()
    local node = self:get_current_node()
    local options_resoult = node.options_resoult or {}

    if opt_index < 1 or opt_index > #opts then
        return false, false
    end
    local opt = opts[opt_index]
    if opt.effects then
        apply_effects(opt.effects, self.state)
    end
    local next_id = options_resoult[opt_index]
    if not next_id then
        self.current_node_id = nil
        print("选项下一步剧情缺失", self.current_node_id)
        return true, false
    end
    self.current_node_id = next_id
    return true, true
end

-- 自动前进（用于无选项的节点，按 random_next 或 固定 next）
-- 返回是否还有下一句
-- 如果没有下一句了则就随机开机对话
function DialogueEngine:auto_advance()
    local node = self:get_current_node()
    local next_node = nil
    if node then
        local random_node = self:select_random_next(node, self.state) -- 根据当前node进行下一步
        -- print("auto_advance: next_id =", random_node)
        if random_node then
            next_node = random_node
        else -- 没找到下一步，可以自由开始话题
            self.current_node_id = nil
            isDialogueFinished = true
            WaitTimeMode = true
            dialogWaitTime = getRandomTopicInterval() -- 进入对话冷却期间
            print("[auto advance, cont] = nil")
        end
    else -- 当前剧情走完了会没有node，可以自由开始话题
        local topic_node = self:_auto_findTopic()
        if topic_node then
            next_node = topic_node
        end
    end

    -- 找到下一步了之后
    if next_node then
        self.current_node_id = next_node.id
        if tonumber(next_node.waitTime) >= 0 then
            dialogWaitTime = tonumber(next_node.waitTime) -- 等待时间
            isDialogueFinished = false
            WaitTimeMode = true
        elseif tonumber(next_node.waitTime) == -1 then
            dialogWaitTime = 0 -- 等待时间 
            isDialogueFinished = false
            WaitTimeMode = false
        else
            print("未知waitTime", next_node.waitTime)
        end

        if self.state.dialogue_Record[next_node.id] then -- 添加经历次数
            self.state.dialogue_Record[next_node.id].times = self.state.dialogue_Record[next_node.id].times + 1
            self.state.dialogue_Record[next_node.id].lastTime = os.time()
        else
            self.state.dialogue_Record[next_node.id] = {
                times = 1,
                lastTime = os.time()
            }
        end

        self:nodePrint(self, next_node, WaitTimeMode)
        print("[auto advance, cont] =", next_node.id)
    else

    end

    return next_node
end

-- 查找话题
function DialogueEngine:_auto_findTopic()

    local total = 0
    local weighted = {}

    for id, node in pairs(self.data) do
        if node.type == "topic" then

            -- print("寻找话题node对象:", node.id, node.type)
            if node.condition == "" then
                return node
            else
                if node.condition.type == "weight" then -- 根据权重选择
                    total = total + node.condition.value
                    table.insert(weighted, { -- 加入判断表
                        weight = tonumber(node.condition.value),
                        nodeid = node.id
                    })
                elseif node.condition.type == "auto" then -- 没有条件

                elseif node.condition.type == "manual" then -- 需要满足条件才会出现
                    local cond = node.condition.value or "true"
                    if eval_condition(cond, self.state) then -- 执行操作了
                        return node -- 返回条件判断的下一步
                    end
                end
            end
        end
    end

    if total ~= 0 then -- 说明是权重选择
        local random = math.random() * total
        for _, item in ipairs(weighted) do
            -- print("判断选择node对象:", item.nodeid)
            random = random - item.weight
            if random <= 0 then
                return self.data[item.nodeid] -- 返回权重的下一步
            end
        end
        return nil
    end

    return nil
end

-- 获取对话
function DialogueEngine:get_current_text()
    local node = self:get_current_node()
    if not node then
        return ""
    end
    return self:get_node_text(node, self.state) -- 返回文本
end

function DialogueEngine:get_current_speaker()
    local node = self:get_current_node()
    return node and node.speaker or nil
end

function DialogueEngine:is_finished()
    return isDialogueFinished
end

function DialogueEngine:is_waiting()
    return dialogWaitTime > 0
end

function DialogueEngine:is_waitMode()
    return WaitTimeMode
end

function DialogueEngine:reset(start_node_id)
    self.current_node_id = start_node_id or self.data["first"]
    self:nodePrint(self, self:get_current_node(), true)
    print("对话重置到节点:", self.current_node_id)
end

-- 加载状态
function DialogueEngine:reNew()
    local state = globleManager:getGameData("DialogueBoxState")

    if  globleManager.getConfig("debug","dialogue_new") then
        print("对话状态重置")
        state = nil
    end

    if state then -- 打开更新
        print("加载对话状态:", state)
        self.state = state
        self.state.lastTime = os.time()
        self.state.cumulativeToday = 0 -- 累计听歌时间今日
        globleManager:saveGameData("DialogueBoxState", self.state)
    else -- 没有就创建
        self.state = {}
        self.state.lastTime = os.time()
        self.state.time = os.time()
        self.state.name = "你"
        self.state.musicNum = 0
        self.state.dialogue_Record = {}
        self.state.intervalList = {}
        -- self.state.musicName = audio.currentMusicName() -- 当前音乐
        self.state.cumulative = 0 -- 累计听歌时间
        self.state.cumulativeToday = 0 -- 累计听歌时间今日
        globleManager:saveGameData("DialogueBoxState", self.state)
    end
end

-- 加载状态
function DialogueEngine:reUpdate(dt)
    self.state.time = os.time() -- 更新时间
    -- self.state.musicName = audio.currentMusicName() -- 当前音乐
    --self.state.cumulative = 0 -- 累计听歌时间
    --self.state.cumulativeToday = self.state.cumulativeToday + dt -- 累计听歌时间今日
end

function DialogueEngine:stop()
    self.start=false
    floatUI:closeDialogueBox()
end

function DialogueEngine:start()
    self.current_node_id = nil
    self.start = true
end

function DialogueEngine:continue()
    dialogWaitTime = 0
    WaitTimeMode = true
    -- self.current_node_id = nil
    floatUI:closeDialogueBox()
end

function DialogueEngine:update(dt)
    --print(self.state.time)

    if not self.start then
        return
    end

    self:reUpdate(dt)

    if not WaitTimeMode then
        -- 等待玩家点击设置WaitTimeMode为false
        return
    end

    if isDialogueFinished then
        if dialogWaitTime > 0 then
            dialogWaitTime = dialogWaitTime - dt
        else
            print("对话结束，等待下一话题...")
            -- dialogWaitTime = getRandomTopicInterval()
            local node = self:auto_advance() -- 对话结束后自动寻找下一个话题

        end
    else
        if dialogWaitTime > 0 then
            dialogWaitTime = dialogWaitTime - dt
        else
            local node = self:auto_advance()
        end
    end
end

function DialogueEngine:saveState()
    self.state.lastTime = self.state.time
    globleManager:saveGameData("DialogueBoxState", self.state)
end

function DialogueEngine:destroy()
    self:saveState()
end

return DialogueEngine
