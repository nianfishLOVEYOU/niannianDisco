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
    local editorModule = require "src.map.mapEditor"
    self.editor = editorModule
    self.editor:init()
end

function Editor:update(dt)
    if self.editor then
        self.editor:update(dt)
    end
end

function Editor:uidraw()
    -- 现在 UI 完全由 uiManager 里的 MapEditorUI 绘制，这里可以留空或保留兼容接口
    if self.editor and self.editor.uidraw then
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
    if self.editor and self.editor.leave then
        self.editor:leave()
    end
end

return Editor
