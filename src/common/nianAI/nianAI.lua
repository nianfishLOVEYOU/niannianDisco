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
    NianAI:click(x, y, button)
end)
systemManager:mouseLeased_regester(function(x, y, button)

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
    nianAI = self
    -- 3. 创建对话引擎实例
    self.dialog = DialogueEngine:new("excel/dialogue.json")
    self.dialog:stop() -- 初始状态停止，等待触发
    -- self.dialog:reset("first")
    self.selected_option = 1
    self.message = nil -- 用于显示额外信息
end

-- 控制聊天
function NianAI:update(dt)
    self.dialog:update(dt) -- 更新对话状态

    -- if not self.dialog:is_waiting() then
    --     local cont = self.dialog:auto_advance() -- 等待时间到，自动继续
    --     -- 等待打字结束，然后和等待时间下一步
    --     --print("[auto advance, cont] =", cont)

    -- end

end

function NianAI:getNianPos()
    if nianocUI then
        return nianocUI.psdData.x + 80, nianocUI.psdData.y + 120
    end
    return love.graphics.getWidth() / 2, love.graphics.getHeight() / 2
end

function NianAI:keypressed(key)
    if key == 'q' then
        print("DialogueBox create")
        uiManager:getUI("floatUI"):addDialogueBox("hello world", playerManager.player)
        -- 创建一个对话
    end

    if key == "r" then
        print("重新设置成功")
        -- 重新开始对话，重置状态（可选）
        self.dialog:reset("first")
        self.selected_option = 1
    end

    local opts = self.dialog:get_options()
    if #opts == 0 then
        return
    end
end

function NianAI:click(x, y, button)
    if self.dialog:is_waitMode() then
        if self.dialog:is_waiting() then
            -- 如果正在等待时间，点击则立即继续
            -- self.dialog:continue() -- 继续对话
        end
    else -- 如果是点击才能继续就可以点击
        self.dialog:continue() -- 继续对话
    end
end

function NianAI:draw()
    -- 背景
    -- love.graphics.setBackgroundColor(0.2, 0.2, 0.3)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("按 R 重新开始", 250 + 1, 20 + 1)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("按 R 重新开始", 250, 20)
    return

end

function NianAI:destroy()
    if self.dialog then
        self.dialog:destroy()
    end
end

return NianAI
