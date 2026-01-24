local playerControl = {
    interactItem=nil
}

function playerControl:update(dt)

    --self:interact(itemManager.items)
end

-- AABB 检查在范围内
local function checkInrange(ax, ay, aw, ah, bx, by, bw, bh)
    local range = 90
    return (ax - bx) * (ax - bx) + (ay - by + bw / 2) * (ay - by + bw / 2) <= range * range
end


-- 进入交互范围检测
function playerControl:interactInter(type)
    if type == "musicInput" then
        if not uiManager:getUI("musicInputUI") then
            uiManager:addUI("musicInputUI", require("src.ui.musicInputUI"):new())
        end
    end
end

-- 离开交互范围检测
function playerControl:interactLeave(type)
    if type == "musicInput" then
        if uiManager:getUI("musicInputUI") then
            uiManager:removeUI("musicInputUI")
        end
    end
end

function playerControl:mousePressed(x, y, button)
    if button == 1 then
        if (y > love.graphics.getHeight() - 100) then
            return
        end
        x, y = cameraManager.cam:toWorld(x, y)
        playerManager.player:gotoPos(x, y)
        local msg = {
            userid=network.userid,
            type = "playermove",
            x = x,
            y = y,
            time = love.timer.getTime()
        }
        network:send_Broadcast(msg)
    end
end

local pn = 0
function playerControl:keydown(key)

        if key == 'q' then
            print("dialogebox create")
            uiManager:getUI("floatUI"):createDialogBox("hello world ",playerManager.player)
            --创建一个对话
        end

end

function playerControl:draw()
    local player =playerManager.player
    if player.moveToTarget and player.targetX and player.targetY then
        -- love.graphics.setColor(1, 0, 0)
        -- love.graphics.circle("fill", player.targetX, player.targetY, 3)
        local siny=math.sin(love.timer.getTime()*20)*5
        local moveh =10
        love.graphics.setColor(0, 0, 0)
        love.graphics.circle("fill", player.targetX, player.targetY+siny -moveh, 5)
        love.graphics.circle("fill", player.targetX-3, player.targetY+siny -moveh-3, 5)
        love.graphics.circle("fill", player.targetX+3, player.targetY+siny -moveh-3, 5)

        love.graphics.print("到这>a<", player.targetX-20, player.targetY+siny -50)
        love.graphics.setColor(1, 1, 1)
        --love.graphics.line(self.x, self.y, self.targetX, self.targetY)
    end

    -- 事件通知
    if self.interactItem then
        -- player.infoImage.x, player.infoImage.y = player.x + player.h, player.y - player.h - 30
        -- player.infoImage:draw()
        -- love.graphics.print("Q", x + player.w, player.y - player.h - 30)
    end
end

return playerControl
