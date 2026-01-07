-- player.lua
local player = require "src.player.player"
local class = require "src.common.class"
local RemotePlayer = player:extend()


function RemotePlayer:init(x, y, speed, imgPath)
    print("--------------remote",x,y)
    self.type="remotePlayer"
end

return RemotePlayer
