-- lib/network.lua
local Network = {
    userid = 0,
    connects = {},
    peers = {},
    musicTransfering = 0,
    enterRoom = false,
    signalKey =nil
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
    self.signalKey = globleManager:getGameData("signalKey")
    if not self.signalKey then
        self.signalKey = globleManager:guid()
        globleManager:saveGameData("signalKey", self.signalKey)
    end
end

function Network:update(dt)
    self:info()
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
        netThread = love.thread.newThread("src/network/network_thread.lua")
        netThread:start()
        ctrlNetworkCh:push{
            cmd = "start",
            code = code,
            key = self.signalKey,
            localmod = globleManager.getConfig("debug","local_Mod")
        }
        self.netThreadIsStart = true
        
        -- print("网络线程已启动")
    end
end

---关闭网络线程
function Network:closeNetThread()
    if self:NetThreadIsRun() then
        ctrlNetworkCh:push("quit")
    end
    self.peers = {}
end

-- 获得玩家id
function Network:getPeersId(address)
    for key, value in pairs(self.peers) do
        if value.address == address then
            return key
        end
    end
end

function Network:send_Broadcast(msg)
    ctrlNetworkCh:push{
        cmd = "send_Broadcast",
        msg = msg
    }
end

function Network:send_unicast(id, msg)
    ctrlNetworkCh:push{
        cmd = "send_unicast",
        msg = msg,
        peer_id = id
    }
end

function Network:broadcast_mp3(path, name)
    ctrlNetworkCh:push{
        cmd = "broadcast_mp3",
        path = path,
        name = name
    }
    self.musicTransfering = self.musicTransfering + 1
end

function Network:unicast_mp3(id, path, name)
    ctrlNetworkCh:push{
        cmd = "unicast_mp3",
        path = path,
        name = name,
        peer_id = id
    }
    self.musicTransfering = self.musicTransfering + 1
end

-- 网络线程回调
function Network:info()
    --必须要0.01没有数据就跳过，不然是阻塞的
    --窗口焦点切换会降低 Love2D 主线程的调度优先级，系统不再「宽容」这个阻塞请求，而是强制等待 pop() 返回
    
    local pktCh = infoNetworkCh:pop(0.01)
    if pktCh then
        -- print("pktCh type : "..pktCh.type )
        if pktCh.type == "audioOk" then
            -- 预缓冲 200ms，确保同步
            -- audio:loadMusic(pktCh.path)
            -- audio:play(0)
        elseif pktCh.type == "sendAudioOk" then
            -- 预缓冲 200ms，确保同步
            -- audio:loadMusic(pktCh.path)
            -- audio:play(0)
            self.musicTransfering = self.musicTransfering - 1
        elseif pktCh.type == "info_returnProgress" then
            audio.downloadProgress = pktCh.progress
        elseif pktCh.type == "getPeers" then
            self.peers = pktCh.peers
            self.userid = pktCh.userid
            self.enterRoom = true
            if (statusManager.status == "menu") then
                eventManager:emit("connectSeccess")
            end
        elseif pktCh.type == "connectedPeer" then
            -- 和玩家建立了连接
            -- 发送自己的名字和信息
            local msg = {
                type = "playerConnectInfo",
                userid = self.userid,
                name = playerManager.name,
                x = playerManager.player.x,
                y = playerManager.player.y,
                playerType = 1, -- 初始小海兔
                time = love.timer.getTime()
            }
            local id = self:getPeersId(pktCh.address)
            print("[connectedPeer]---chackID  :", id, pktCh.address)
            if id then
                network:send_unicast(id, msg)
                self.connects[id] = pktCh.address
                if self.userid < id then
                    -- id小的先发歌单
                    audio:sendUpdatePlayList(id)
                end
            end

            uiManager:refresh("playerlistUI")
        elseif pktCh.type == "disconnectPeer" then
            print("[getdisconnectPeer]---", pktCh.address)
            -- 删除这个角色 如果有角色的话
            local id = self:getPeersId(pktCh.address)
            if id then
                playerManager:removeRemotePlayer(id)
                self.connects[id] = nil
            end
        elseif pktCh.type == "connectFail" then
            eventManager:emit("connectFail")
        elseif pktCh.type == "networkHandle" then
            self:handleMessage(pktCh.msg, pktCh.address)
        end
    end
end

-- 回包回调
function Network:handleMessage(message, address)
    if message.type == "playlist_update" then
        -- 播放列表更新
        audio.playlist = message.playlist
        uiManager:refresh("playlistUI")
    elseif message.type == "updatePlayStatus" then
        -- 播放状态更新
        audio:seek(message.position)
        if message.isPlaying then
            audio:resume()
        else
            audio:pause()
        end
        audio.currentIndex = message.index
    elseif message.type == "tonext" then
        -- 通知下一首 客通知主->要准备下一首的资源

        audio:receiveToNext(message.index)
    elseif message.type == "requestFile" then
        -- 缺少资源请求发送
        local userid = self:getPeersId(address)
        audio:fileRequestAllow(userid, message.index)
    elseif message.type == "playermove" then
        -- 收到远程玩家移动信息 
        local remotePlayer = playerManager.remotePlayers[message.userid]
        if remotePlayer then
            remotePlayer:gotoPos(message.x, message.y)
        end
    elseif message.type == "playerspeek" then
        -- 收到远程玩家说话信息
        local remotePlayer = playerManager.remotePlayers[message.userid]
        if remotePlayer then
            remotePlayer:speak(message.speakInfo)
        end
    elseif message.type == "playerConnectInfo" then
        -- 收到玩家生成信息
        playerManager:addRemotePlayer(message.userid, message.name, message.x, message.y)

    elseif message.type == "chatMessage" then
        uiManager:getUI("dialog"):addMessage( message.content,message.userid)

    else
        print("## no handle by: " .. message.type)
    end
end

return Network
