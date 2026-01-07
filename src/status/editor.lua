-- 管理玩家，场景和可以交互的物品
local Editor = {}

systemManager:camdraw_regester(function()
    if (statusManager.status == "editor") then
        Editor:draw()
    end
end)
systemManager:draw_regester(function()
    if (statusManager.status == "editor") then
        Editor:uidraw()
    end
end)

function Editor:init()
    self.editor = require "src.map.mapEditor"
    print("12112121s")
    self.editor:init()
end

function Editor:update(dt)
    if self.editor then
        self.editor:update(dt)
    end
    -- 通过 setPosition 把新位置写回摄像机
end

function Editor:uidraw()
    if self.editor then
        self.editor:uidraw()
    end
end

function Editor:draw()
    if self.editor then
        self.editor:draw()
    end
end

-- 结束生命周期等待下次初始化
function Editor:leave()
    if self.editor then
        self.editor:leave()
    end
end

return Editor
