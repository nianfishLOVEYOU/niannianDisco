-- 菜单 包含填写房间号，名字，连接，进入game的功能   然后还有回到菜单功能
local Menu = {}

function Menu:init()
    
    uiManager:addUI("menuUI",require("src.ui.menuUI"):new())
    --uiManager:addUI("playerSelectUI",require("src.ui.playerSelectUI"):new())
end

function Menu:update(dt)

end
--结束生命周期等待下次初始化
function Menu:leave()
    uiManager:removeUI("menuUI")
    --uiManager:removeUI("playerSelectUI")
end

return Menu