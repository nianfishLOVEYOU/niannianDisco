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

function playerControl:interact(obstacles)
    self.interactItem = nil
    local player = playerManager.player
    local haveZone = false
    for _, obj in ipairs(obstacles) do
        local objx, objy = obj:getPos()
        -- 交互
        if obj.onInteract and checkInrange(player.x, player.y, player.w, player.h, objx, objy, obj.w, obj.h) then
            self.interactItem = obj
            if obj.type == "eventZone" then
                haveZone = true
            end
            break
        end
    end

    if haveZone then
        if not uiManager:getUI("musicInputUI") then
            local musicInputUI = require("src.ui.musicInputUI"):new()
            uiManager:addUI("musicInputUI", musicInputUI)
        end
    else
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
        x, y = cam:toWorld(x, y)
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

    -- 交互
    if self.interactItem then
        if key == 'q' then
            -- self.interactItem:interact()
        end

    end
    if key == 'h' then
        print("h")
        playerManager:addRemotePlayer(pn, "name", map.startPoint.x, map.startPoint.y)
        pn = pn + 1
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
