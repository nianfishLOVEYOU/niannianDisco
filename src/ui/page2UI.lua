--自己歌单
--目前房间歌单
--自己的分类
-- 聊天界面
-- 粘的立绘
-- 目前在播放的歌,歌单界面
local ui = require "src.ui.ui"

local page2UI = ui:extend()

function page2UI:init()
    self:refresh()
end

-- 更新播放列表显示
function page2UI:refresh()
    self:clearStacks()
end


function page2UI:update(dt)

end


function page2UI:destroy()
    page2UI.super.destroy(self)
end

return page2UI
