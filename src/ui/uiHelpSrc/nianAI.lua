-- src/map_loader.lua
local json = require "lib.json" -- 需要放入 json.lua（常用的纯 Lua JSON 库）
local Item = require "src.item.item"

local NianAI = {}

systemManager:update_regester(function(dt)
    NianAI:update(dt)
end)
systemManager:camdraw_regester(function()
    NianAI:draw()
end)
systemManager:mousepressed_regester(function(x, y, button)
    if floatUI then
        floatUI:addFloatText("Hello, Nian!", x, y)
    end
end)
systemManager:keypressed_regester(function(key)
    if key == 'q' then
        print("dialogebox create")
        uiManager:getUI("floatUI"):addDialogeBox("hello world", playerManager.player)
        -- 创建一个对话
    end
end)

-- 切换状态
local function audioChange(state)
    print("NianAI:"..state)
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

-- 控制聊天
function NianAI:update(dt)
    --nianocUI:changeState("music")
end

function NianAI:draw()

end

return NianAI
