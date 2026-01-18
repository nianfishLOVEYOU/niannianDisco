-- lib/audio.lua
local json = require "lib.json"

local Audio = {
    currentSource = nil,
    playlist = {}, --*{userid , path , duration, name }
    localplaylist = {}, -- 指向本地的tmp文件夹内，也指向其他music文件夹
    currentMusicName = "",
    currentIndex = 0,
    volume = 0.3,
    stuck = false,
    downloadProgress = 100

}

systemManager:update_regester(function(dt)
    Audio:update(dt)
end)

local nonPlayTime = 0

function Audio:isPlaying()
    return self.currentSource and self.currentSource:isPlaying()
end

function Audio:getPosition()
    return self.currentSource and self.currentSource:tell() or 0
end

function Audio:isOvered()
    if (self.currentSource) then
        return self:getCurrentDuration() - Audio:getPosition() < 0.1
    end
    return false
end

function Audio:getCurrentTrack()
    if (self.currentIndex ~= 0) then
        return self.playlist[self.currentIndex]
    end
    return nil
end

function Audio:getCurrentDuration()
    local track = self:getCurrentTrack()
    if track then
        return track.duration
    end
    return 0
end

function Audio:loadMusic(path)
    if self.currentSource then
        self.currentSource:stop()
    end
    print("loadMusic path：", path)
    local source = love.audio.newSource(path, "stream")
    if source then
        print("loadMusic path success")
        self.currentSource = source
        self.currentMusicName = path
        self.currentSource:setVolume(self.volume)
        self:setStuck(false)
        return true, source
    end
    print("loadMusic error")
    return false
end

function Audio:play(position)
    if (not self.currentSource) then
        print("! Audio:play() no music !")
        return false
    end
    self.currentSource:seek(position)
    self.currentSource:setLooping(false)
    self.currentSource:play()
    uiManager:refresh("playerUI")
    return true
end

-- 暂停
function Audio:pause()
    if self.currentSource then
        self.currentSource:pause()
    end
end

-- 继续播放
function Audio:resume()
    if self.currentSource and not self:isPlaying() then
        self.currentSource:play()
    end
end

function Audio:stop()
    if self.currentSource then
        self.currentSource:stop()
    end
end

function Audio:setStuck(stuck)

    self.stuck = stuck
    self.downloadProgress = stuck and 0 or 100
end

function Audio:sendRequestFile(musicindex)
    local uerid = audio.playlist[musicindex].uerid
    local msg = {
        type = "requestFile",
        index = musicindex
    }
    network:send_unicast(uerid, msg) -- 相拥有资源的人请求
    print("sendRequestFile" ,uerid ,audio.playlist[musicindex].name,musicindex)
end
-- 按钮按下，进入下一首
function Audio:next(index)
    if self.currentIndex == index then
        return
    end

    self.currentIndex = index
    self:sendUpdatePlayList()

    local msg = {
        type = "tonext",
        index = index,
        uerid = self.playlist[index].userid
    }
    network:send_Broadcast(msg)

    -- 询问下一首是否缺少资源
    local musicname = audio.playlist[index].name
    local path, info = fileManager:getFilePathByName(musicname)
    -- 播放时去顶播下一首
    print("next -- ", index, self.playlist[index].userid, path, musicname, info)
    if path then
        -- 播放
        self:MusicStart(path, 0)
    else
        self:sendRequestFile(index)
        network:send_unicast(uerid, msg) -- 相拥有资源的人请求
        self:setStuck(true)
        uiManager:refresh("playlistUI")
    end

end

-- 接收到消息，检查并播放下一首
function Audio:receiveToNext(index)
    if self.currentIndex == index then
        return
    end

    self.currentIndex = index
    print("receiveToNext----", index, #audio.playlist)
    -- 询问下一首是否缺少资源
    local musicname = audio.playlist[index].name
    local path = fileManager:getFilePathByName(musicname)
    if path then
        -- 播放
        self:MusicStart(path, 0)
    else
        self:sendRequestFile(index)
        self:setStuck(true)
        self.downloadProgress = 0
    end
    uiManager:refresh("playlistUI")
end

-- 发送回去
function Audio:fileRequestAllow(userid, index)
    network:unicast_mp3(userid, audio.playlist[index].path, audio.playlist[index].name)
end

function Audio:seek(position)
    if self.currentSource then
        self.currentSource:seek(position)
    end
end

local waittime = os.time()
function Audio:update(dt)
    -- 如果没有音乐资源就等待，直到下载好
    if os.time() - waittime > 0.5 then
        waittime = os.time()
    else
        return
    end

    -- 从0开始播放
    if self.currentIndex == 0 and #self.playlist > 0 then
        self:next(1)
    end

    -- 从播放结束之后开始播放
    if self:isOvered() then
        self:next(((audio.currentIndex) % #audio.playlist) + 1)
    end

    if self.stuck then
        print("stuck!!")
        local musicpath = fileManager:getFilePathByName(self.playlist[self.currentIndex].name)
        if musicpath then
            self:MusicStart(musicpath, 0)
            self.downloadProgress = 0
        end
    end

    if #self.playlist ~= 0 and not self:isPlaying() then
        nonPlayTime = nonPlayTime + dt
    else
        nonPlayTime = 0
    end
end

-- 开启音乐播放
function Audio:MusicStart(path, delay)
    timer:after(delay, function()
        self:loadMusic(path)
        self:play(0)
        uiManager:refresh("playlistUI")
    end)
end

function Audio:setVolume(vol)
    self.volume = math.max(0, math.min(1, vol))
    if self.currentSource then
        self.currentSource:setVolume(self.volume)
    end
end

function Audio:musicExist(name)
    for k, v in pairs(self.playlist) do
        if v.name == name then
            return true
        end
    end
    return false
end

function Audio:addPlayMusic(path, duration, name)
    if self:musicExist(name) then
        print(" ## same music musicExist..")
        return
    end
    print("add " .. name)
    local stack = {
        userid = network.userid,
        path = path,
        duration = duration,
        name = name
    }
    table.insert(self.playlist, stack)
    self:sendUpdatePlayList()

    uiManager:refresh("playlistUI")
end

-- 发送列表信息
function Audio:sendUpdatePlayList()
    -- 发送列表
    local msg = {
        type = "playlist_update",
        playlist = self.playlist,
        index = self.currentIndex
    }
    network:send_Broadcast(msg)
end

-- 发送播放信息
function Audio:sendUpdatePlayStatus()
    ---发送现在状态
    local msg = {
        type = "updatePlayStatus",
        position = self:getPosition(),
        isPlaying = self:isPlaying(),
        index = self.currentIndex
    }
    network:send_Broadcast(msg)
end

-- 暂时用不到
function Audio:removePlayMusic(name)
    eventManager:emit("event_playListRemove")
end

return Audio
