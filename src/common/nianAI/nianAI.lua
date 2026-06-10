-- src/map_loader.lua
local json = require "lib.json" -- 需要放入 json.lua（常用的纯 Lua JSON 库）
local Item = require "src.item.item"
local DialogueEngine = require "src.common.nianAI.nianAIDialogue"
-- 管理nian的动作和对接对话选项
local NianAI = {}

systemManager:update_regester(function(dt)
    NianAI:update(dt)
end)
systemManager:draw_regester(function()
    NianAI:draw()
end)
systemManager:mousepressed_regester(function(x, y, button)
    if floatUI then
        floatUI:addFloatText("Hello, Nian!", x, y)
    end
end)
systemManager:keypressed_regester(function(key)
    NianAI:keypressed(key)
end)

-- 切换状态
local function audioChange(state)
    print("NianAI:" .. state)
    if state == "play" then
        nianocUI:changeState("music")
    elseif state == "pause" then
        nianocUI:changeState("idle")
    elseif state == "resume" then
        nianocUI:changeState("music")
    elseif state == "stop" then
        nianocUI:changeState("idle")
    end
end

-- 切换到音乐的时候切换粘动画
eventManager:on("audio_state_changed", audioChange)

function NianAI:init()
    -- 1. 加载对话 JSON
    local file = love.filesystem.newFile("dialogue.json")
    file:open("r")
    local json_str = file:read(file:getSize())
    file:close()
    -- 2. 初始化游戏状态（这里可以改成你的实际数据）
    self.game_state = {
        player = {
            level = 1, -- 改成 2 可以看到“接任务”选项
            name = "无名",
            reputation = 0,
            quest = nil
        },
        world = {
            time = "day"
        }
    }

    -- 3. 创建对话引擎实例
    self.dialog = DialogueEngine.new(json_str, self.game_state)

    -- UI 控制
    self.show_dialog = true
    self.selected_option = 1
    self.message = nil -- 用于显示额外信息
end

-- 控制聊天
function NianAI:update(dt)
    if not self.show_dialog then
        return
    end
    if self.dialog:is_finished() then
        self.show_dialog = false
        self.message = "对话结束。按 R 重新开始对话，按 ESC 退出。"
        return
    end

    local opts = self.dialog:get_options()
    if #opts == 0 then
        -- 无选项时自动前进
        local cont = self.dialog:auto_advance()
        if not cont then
            self.show_dialog = false
            self.message = "对话结束。"
        end
    end
end

function NianAI:keypressed(key)
    if key == 'q' then
        print("dialogebox create")
        uiManager:getUI("floatUI"):addDialogeBox("hello world", playerManager.player)
        -- 创建一个对话
    end

    if not self.show_dialog then
        if key == "r" then
            -- 重新开始对话，重置状态（可选）
            self.dialog:reset()
            self.show_dialog = true
            self.selected_option = 1
            self.message = nil
        end
        return
    end

    local opts = self.dialog:get_options()
    if #opts == 0 then
        return
    end

    if key == "up" then
        self.selected_option = math.max(1, self.selected_option - 1)
    elseif key == "down" then
        self.selected_option = math.min(#opts, self.selected_option + 1)
    elseif key == "return" or key == "space" then
        local success, cont = self.dialog:select_option(self.selected_option)
        if success then
            self.selected_option = 1 -- 重置高亮
            if not cont then
                self.show_dialog = false
                self.message = "对话结束。"
            end
        else
            self.message = "无效选项（不应该发生）"
        end
    end
end

function NianAI:draw()
    -- 背景
    love.graphics.setBackgroundColor(0.2, 0.2, 0.3)
    if self.message then
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf(self.message, 50 + 1, 50 + 1, love.graphics.getWidth() - 100, "center")
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(self.message, 50, 50, love.graphics.getWidth() - 100, "center")

        love.graphics.setColor(0, 0, 0)
        love.graphics.print("按 R 重新开始", 50+1, 100+1)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("按 R 重新开始", 50, 100)
        return
    end

    if not self.show_dialog then
        return
    end

    local text = self.dialog:get_current_text()
    local speaker = self.dialog:get_current_speaker()
    local opts = self.dialog:get_options()

    -- 绘制对话背景框
    love.graphics.setColor(0, 0, 0, 180)
    love.graphics.rectangle("fill", 40, love.graphics.getHeight() - 200, love.graphics.getWidth() - 80, 180)
    love.graphics.setColor(1, 1, 1)

    -- 说话人
    if speaker then
        love.graphics.print(speaker .. "：", 55, love.graphics.getHeight() - 190)
    end

    -- 对话文本（自动换行）
    love.graphics.printf(text, 55, love.graphics.getHeight() - 170, love.graphics.getWidth() - 100, "left")

    -- 选项列表
    local opt_y = love.graphics.getHeight() - 70
    for i, opt in ipairs(opts) do
        if i == self.selected_option then
            love.graphics.setColor(1, 1, 0) -- 高亮黄色
        else
            love.graphics.setColor(0.8, 0.8, 0.8)
        end
        love.graphics.print(opt.text, 65, opt_y + (i - 1) * 22)
    end
    love.graphics.setColor(0, 0, 0)

    -- 提示按键
    love.graphics.print("↑/↓ 选择， Enter/Space 确认", 50, love.graphics.getHeight() - 25)
end

return NianAI
