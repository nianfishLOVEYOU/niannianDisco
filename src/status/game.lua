-- 管理玩家，场景和可以交互的物品
local Game = {}



function Game:init()
    --ui
    mapManager:loadMap("res/maps/edited.json")

    local floatUI = require("src.ui.floatUI"):new()
    uiManager:addUI("floatUI",floatUI)
    --玩家聊天ui
    --播放列表ui
    --左右切换页面系统
    local pageControlUI = require("src.ui.pageControlUI"):new()
    uiManager:addUI("pageControlUI",pageControlUI)

    
    
end



function Game:update(dt)

    -- 通过 setPosition 把新位置写回摄像机
    if playerManager.player then
        local playerx=playerManager.player.x+playerManager.player.w/2
        local playery =playerManager.player.y+playerManager.player.h/2
        local x,y =cameraManager.cam:getPosition()
        local t=0.2
        cameraManager.cam:setPosition(lerp(x,playerx,t),lerp(y,playery,t) )
    end

    --设置地图

    --ui功能

    --退回菜单

    --设置界面

end


-- 结束生命周期等待下次初始化
function Game:leave()

    uiManager:removeUI("floatUI")
    uiManager:removeUI("pageControlUI")
    uiManager:removeUI("wheelSelectionUI")
end

return Game
