-- lib/audio.lua
local json = require "lib.json"

local Audio = {
    currentSource = nil,
    playlist = {},
    currentMusicName = "",
    currentIndex = 0,
    volume = 0.3
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
    local source = love.audio.newSource(path, "stream")
    if source then
        self.currentSource = source
        self.currentMusicName = path
        self.currentSource:setVolume(self.volume)
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
function Audio:pause(isBroadcast)
    if self.currentSource then
        self.currentSource:pause()
        if isBroadcast then
            self:sendUpdatePlayStatus()
        end
    end
end

-- 继续播放
function Audio:resume(isBroadcast)
    if self.currentSource and not self:isPlaying() then
        self.currentSource:play()
        if isBroadcast then
            self:sendUpdatePlayStatus()
        end
    end
end

function Audio:stop(isBroadcast)
    if self.currentSource then
        self.currentSource:stop()
        if isBroadcast then
            self:sendUpdatePlayStatus()
        end
    end
end

function Audio:next(index)
    -- 播放时去顶播下一首
    audio:stop()
    print("next -- ", index)
    ---是自己提交的音乐,播放下一首且广播
    if self.playlist[index].userid == network.userid then
        self.currentIndex = index
        print("-next-", network.userid, self.playlist[index].path)
        -- 发送音乐
        network:broadcast_mp3(self.playlist[index].path, self.playlist[index].name)
        self:sendUpdatePlayList()
        uiManager:refresh("playlistUI")
        eventManager:emit("event_playListUpdate")
    else
        local msg = {
            type = "tonext",
            index = index
        }
        network:send_unicast(msg)
    end
end

function Audio:seek(position, isBroadcast)
    if self.currentSource then
        self.currentSource:seek(position)
        if isBroadcast then
            self:sendUpdatePlayStatus()
        end
    end
end

local waittime = os.time()
function Audio:update(dt)
    if os.time() - waittime > 0.5 then
        waittime = os.time()
    else
        return
    end

    if self.currentIndex == 0 and #self.playlist > 0 then
        self:next(1)
    end

    if self:isOvered() then
        self:next(((audio.currentIndex) % #audio.playlist) + 1)
    end

    if #self.playlist ~= 0 and not self:isPlaying() then
        nonPlayTime = nonPlayTime + dt
    else
        nonPlayTime = 0
    end
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
    eventManager:emit("event_playListUpdate")
end

--发送列表信息
function Audio:sendUpdatePlayList(userid)
    -- 发送列表
    local msg = {
        type = "playlist_update",
        playlist = self.playlist,
        index = self.currentIndex
    }
    network:send_unicast(userid, msg)
end

--发送播放信息
function Audio:sendUpdatePlayStatus()
    if self.currentSource then
        ---发送现在状态
        local msg = {
            type = "updatePlayStatus",
            position = self:getPosition(),
            isPlaying = self:isPlaying(),
            index = self.currentIndex
        }
        network:send_Broadcast(msg)
    else
        print("currentSource is nil ")
    end
end

-- 暂时用不到
function Audio:removePlayMusic(name)
    eventManager:emit("event_playListRemove")
end

return Audio
