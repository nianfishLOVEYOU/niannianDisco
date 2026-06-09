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
systemManager:mousepressed_regester(function( x, y,button)
    if floatUI then
        floatUI:addFloatText("Hello, Nian!", x, y)
    end
end)
systemManager:keypressed_regester(function(key)
    if key == 'q' then
        print("dialogebox create")
        uiManager:getUI("floatUI"):addDialogeBox("hello world ", playerManager.player)
        -- 创建一个对话
    end
end)
-- 控制聊天
function NianAI:update(dt)

end

function NianAI:draw()

end

return NianAI
