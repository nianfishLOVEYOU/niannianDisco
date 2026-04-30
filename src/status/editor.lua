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
    -- 创建一个 mapEditor 实例，并在其中初始化和注册 MapEditorUI
    self.mapEditor = require "src.map.mapEditor"
    self.mapEditor:init()
end

function Editor:update(dt)
    if self.mapEditor then
        self.mapEditor:update(dt)
    end
end

function Editor:uidraw()
    -- 现在 UI 完全由 uiManager 里的 MapEditorUI 绘制，这里可以留空或保留兼容接口
    if self.mapEditor and self.mapEditor.uidraw then
        self.mapEditor:uidraw()
    end
end

function Editor:draw()
    if self.mapEditor then
        self.mapEditor:draw()
    end
end

-- 结束生命周期等待下次初始化
function Editor:leave()
    if self.mapEditor and self.mapEditor.leave then
        self.mapEditor:leave()
    end
end

return Editor
