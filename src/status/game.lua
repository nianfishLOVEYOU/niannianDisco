-- 管理玩家，场景和可以交互的物品
local Game = {}



function Game:init()
    --ui
    local playerUI = require("src.ui.playerUI"):new()
    uiManager:addUI("playerUI",playerUI)
    local playerlistUI = require("src.ui.playerlistUI"):new()
    uiManager:addUI("playerlistUI",playerlistUI)

    playerManager:addPlayer(map.startPoint.x, map.startPoint.y)
    --playerManager:addRemotePlayer(1,"name",map.startPoint.x, map.startPoint.y)
end



function Game:update(dt)

    -- 通过 setPosition 把新位置写回摄像机
    if playerManager.player then
        local playerx=playerManager.player.x+playerManager.player.w/2
        local playery =playerManager.player.y+playerManager.player.h/2
        local x,y =cam:getPosition()
        local t=0.2
        cam:setPosition(lerp(x,playerx,t),lerp(y,playery,t) )
    end

    --设置地图

    --ui功能

    --退回菜单

    --设置界面

end


-- 结束生命周期等待下次初始化
function Game:leave()
    uiManager:removeUI("playlistUI")
    uiManager:removeUI("playerUI")
    uiManager:removeUI("playerlistUI")
end

return Game
