local player = require("src.player.player")
local remotePlayer = require("src.player.remotePlayer")
local playerControl = require("src.player.playerControl")

local PlayerManager = {
    name = "我!",
    player = nil,
    remotePlayers = {}
}

systemManager:update_regester(function(dt)
    PlayerManager:update(dt)
end)
systemManager:camdraw_regester(function()
    PlayerManager:draw()
end)
keybordManager:keypressed_regester(function(key)
    PlayerManager:keypressed(key)
end)
mouseManager:mousepressed_regester(function(x, y, button)
    PlayerManager:mousePressed(x, y, button)
end)

function PlayerManager:addPlayer(x, y)
    if self.player then
        return
    end
    local player = player:new( "res/image/player1.png")
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
        playerControl:keydown(key)
    end
end

function PlayerManager:mousePressed(x, y, button)
    -- 如果 Glove 在该位置有 UI 元素，阻断玩家移动
    if Glove and Glove.getFirstWidget then
        local w = Glove.getFirstWidget(x, y)
        if w then return end
    end
    if self.player then
        playerControl:mousePressed(x, y, button)
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
        playerControl:update(dt)
        self.player:update(dt)
    end
    for k, rp in pairs(self.remotePlayers) do
        rp:update(dt)
    end
end

function PlayerManager:draw()
    if self.player then
        self.player:draw()
        playerControl:draw()
    end
    for k, rp in pairs(self.remotePlayers) do
        rp:draw()
    end
end

return PlayerManager
