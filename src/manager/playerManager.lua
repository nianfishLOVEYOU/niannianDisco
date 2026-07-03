local player = require("src.player.player")
local remotePlayer = require("src.player.remotePlayer")
local bonfireArea = require("src.map.bonfireArea") --限制玩家位置

local PlayerManager = {
    name = "我!",
    player = nil,
    remotePlayers = {},
    playerControl = require("src.player.playerControl")
}

systemManager:update_regester(function(dt)
    PlayerManager:update(dt)
end)
systemManager:camdraw_regester(function()
    PlayerManager:draw()
end)
systemManager:keypressed_regester(function(key)
    PlayerManager:keypressed(key)
end)
systemManager:mousepressed_regester(function(x, y, button)
    PlayerManager:mousePressed(x, y, button)
end)

function PlayerManager:addPlayer(x, y)
    if self.player then
        return
    end
    local selected = globleManager:getGameData("selectedPlayerImage")
    local img = selected or "res/image/player1.png"
    local player = player:new(img)
    player:setPos(x, y)
    player:setName(self.name)
    self.player = player
end

function PlayerManager:addRemotePlayer(id, name, x, y)
    if not self.remotePlayers[id] then
        print("[creat remote player ]:" .. id, name)
        local rplayer = remotePlayer:new("res/image/player1.png")
        rplayer:setPos(x, y)
        rplayer:setName(name)
        self.remotePlayers[id] = rplayer
    end
end

function PlayerManager:keypressed(key)
    if self.player then
        self.playerControl:keydown(key)
    end
end

function PlayerManager:mousePressed(x, y, button)
    -- 如果 Glove 在该位置有 UI 元素，阻断玩家移动
    local w = Glove.getFirstWidget(x, y)
    if w then
        return
    end

    -- 如果点击到可交互 item 且在 100 范围内，则不走路，只做 item 操作
    local wx, wy = cameraManager.cam:toWorld(x, y)
    local item = itemManager:getFirstItem(wx, wy, true)
    if item and item.interaction and itemManager.isItemInRange and itemManager:isItemInRange(item) then
        return
    end

    if self.player then
        self.playerControl:mousePressed(x, y, button)
    end
end

function PlayerManager:removePlayer()
    if self.player then
        self.player:destroy()
        self.player = nil
    end
end

function PlayerManager:removeRemotePlayer(id)
    if self.remotePlayers[id] then
        self.remotePlayers[id]:destroy()
        self.remotePlayers[id] = nil
    end
end

function PlayerManager:update(dt)

    if self.player then
        self.playerControl:update(dt)
        self.player:update(dt)
    end
    for k, rp in pairs(self.remotePlayers) do
        rp:update(dt)
    end


end

function PlayerManager:draw()
    if self.player then
        self.player:draw()
        self.playerControl:draw()
    end
    for k, rp in pairs(self.remotePlayers) do
        rp:draw()
    end
end

return PlayerManager
