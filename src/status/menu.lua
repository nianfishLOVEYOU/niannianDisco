-- 菜单 包含填写房间号，名字，连接，进入game的功能   然后还有回到菜单功能
local Menu = {}

function Menu:init()
    
    local menuUI = require("src.ui.menuUI"):new()
    uiManager:addUI("menuUI",menuUI)
end

function Menu:update(dt)

end
--结束生命周期等待下次初始化
function Menu:leave()
    uiManager:removeUI("menuUI")
end

return Menu