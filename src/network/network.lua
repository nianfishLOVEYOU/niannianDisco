-- lib/network.lua
local Network = {
    userid = 0,
    connects = {},
    peers = {},
    musicTransfering = false,
    enterRoom = false
}

-- 初始化挂起
systemManager:init_regester(function()
    Network:init()
end)
systemManager:update_regester(function(dt)
    Network:update(dt)
end)

function Network:init()
    ctrlNetworkCh = love.thread.getChannel("ctrlNetwork")
    infoNetworkCh = love.thread.getChannel("infoNetwork")
end

function Network:getPeersId(address)
    for key, value in pairs(self.peers) do
        print("getPeersId", key, value.address, address)
        if value.address == address then
            return key
        end
    end
end

function Network:update(dt)
    local pktCh = infoNetworkCh:pop()
    if pktCh then
        -- print("pktCh type : "..pktCh.type )
        if pktCh.type == "audioOk" then
            -- 预缓冲 200ms，确保同步
            local now = love.timer.getTime()
            audio:loadMusic(pktCh.path)
            audio:play(0)
            self.musicTransfering = false
        elseif pktCh.type == "getPeers" then
            print("getPeers out")
            self.peers = pktCh.peers
            self.enterRoom = true
            if (statusManager.status == "menu") then
                eventManager:emit("connectSeccess")
            end
        elseif pktCh.type == "connectedPeer" then
            --和玩家建立了连接
            --发送自己的名字和信息
            local msg = {
                type = "playerConnectInfo",
                userid = self.userid,
                name = playerManager.name,
                x=playerManager.player.x,
                y=playerManager.player.y,
                playerType = 1, --初始小海兔
                time = love.timer.getTime()
            }
            local id = self:getPeersId(pktCh.address)
            print("connectedPeer---chackID  :", id, pktCh.address)
            if id then
                network:send_unicast(id, msg)
                self.connects[id] = pktCh.address
                if self.userid < id then
                    --id小的先发歌单
                    audio:sendUpdatePlayList()
                end
            end

            uiManager:refresh("playerlistUI")
        elseif pktCh.type == "disconnectPeer" then
            print("getdisconnectPeer---", pktCh.address)
            --删除这个角色 如果有角色的话
            local id = self:getPeersId(pktCh.address)
            if id then
                playerManager:removeRemotePlayer(id)
                self.connects[id] = nil
            end
        elseif pktCh.type == "connectFail" then
            eventManager:emit("connectFail")
        elseif pktCh.type == "networkHandle" then
            self:handleMessage(pktCh.msg, pktCh.ip, pktCh.port)
        end
    end
    if self.enterRoom then
        self.enterRoom = self:NetThreadIsRun()
    end
end

function Network:NetThreadIsRun()
    if netThread then
        return netThread:isRunning()
    end
    return false
end

---开启网络线程
function Network:startNetThread(code)
    if not self:NetThreadIsRun() then
        if openlocalMod then
            netThread = love.thread.newThread("src/network/network_threadlocal.lua")
        else
            netThread = love.thread.newThread("src/network/network_thread.lua")
        end
        netThread:start()
        ctrlNetworkCh:push {
            cmd = "start",
            code = code
        }
        self.netThreadIsStart = true
    end
end

---关闭网络线程
function Network:closeNetThread()
    if self:NetThreadIsRun() then
        ctrlNetworkCh:push("quit")
    end
    self.peers = {}
end

function Network:send_Broadcast(msg)
    ctrlNetworkCh:push {
        cmd = "send_Broadcast",
        msg = msg
    }
end

function Network:send_unicast(id, msg)
    ctrlNetworkCh:push {
        cmd = "send_unicast",
        msg = msg,
        peer_id = id
    }
end

function Network:broadcast_mp3(path, name)
    ctrlNetworkCh:push {
        cmd = "broadcast_mp3",
        path = path,
        name = name
    }
    self.musicTransfering = true
end

function Network:unicast_mp3(id, path, name)
    ctrlNetworkCh:push {
        cmd = "unicast_mp3",
        path = path,
        name = name,
        peer_id = id
    }
    self.musicTransfering = true
end

function Network:handleMessage(message, ip, port)
    if message.type == "playlist_update" then
        for k, v in pairs(message.playlist) do
            print(v.name)
        end
        audio.playlist = message.playlist
        uiManager:refresh("playlistUI")
        eventManager:emit("event_playListUpdate")
        audio.currentIndex = message.index
    elseif message.type == "updatePlayStatus" then
        audio:seek(message.position)
        if message.isPlaying then
            audio:resume()
        else
            audio:pause()
        end
        audio.currentIndex = message.index
    elseif message.type == "tonext" then
        if message.uerid == self.userid then
            audio:next(message.index)
        end
    elseif message.type == "playermove" then
        --收到远程玩家移动信息
        local remotePlayer = playerManager.remotePlayers[message.userid]
        if remotePlayer then
            remotePlayer:gotoPos(message.x, message.y)
        end
    elseif message.type == "playerspeek" then
        --收到远程玩家说话信息
        local remotePlayer = playerManager.remotePlayers[message.userid]
        if remotePlayer then
            remotePlayer:speak(message.speakInfo)
        end
    elseif message.type == "playerConnectInfo" then
        --收到玩家生成信息
        playerManager:addRemotePlayer(message.userid, message.name,message.x,message.y)
    else
        print("## no handle by: " .. message.type)
    end
end

return Network
