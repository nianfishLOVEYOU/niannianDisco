-- lib/audio.lua
local json = require "lib.json"

local Audio = {
    currentSource = nil,
    playlist = {}, -- *{userid , path , duration, name }
    localplaylist = {}, -- 指向本地的tmp文件夹内，也指向其他music文件夹
    currentMusicName = "",
    currentIndex = 0,
    volume = 1,
    stuck = false,
    downloadProgress = 100,
}

systemManager:init_regester(function()
    Audio:init()
end)

function Audio:init()
    self:setVolume(globleManager.getConfig("game", "musicVolume") or 1)
    print("Audio:init() volume", self.volume)
end

function Audio:savePlaylist()
    globleManager:saveGameData("playlist", self.playlist)
end

systemManager:update_regester(function(dt)
    Audio:update(dt)
end)

function Audio:isPlaying()
    return self.currentSource and self.currentSource:isPlaying()
end

function Audio:getPosition()
    return self.currentSource and self.currentSource:tell() or 0
end

function Audio:isOvered()
    if (self.currentSource) then
        return self:getCurrentDuration() - Audio:getPosition() < 0.2
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
    local userid = audio.playlist[musicindex].userid
    local msg = {
        type = "requestFile",
        index = musicindex
    }
    network:send_unicast(userid, msg) -- 相拥有资源的人请求
    print("sendRequestFile", userid, audio.playlist[musicindex].name, musicindex)
end

-- 按钮按下，进入下一首
function Audio:next(index)
    if self.currentIndex == index then
        return
    end

    self.currentIndex = index

    local msg = {
        type = "tonext",
        index = index,
        userid = self.playlist[index].userid
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
        self:setStuck(true)
        uiManager:refresh("playlistUI")
    end

end

-- 非主动下一首，检查并播放下一首
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

-- 限制每次播放结束自动下一首只有一人广播
function Audio:automusicNext()
    -- 从0开始播放
    if #self.playlist == 0 then
        return
    end

    local nextId = self.currentIndex
    -- 还没开始播放的时候播放
    if self.currentIndex == 0 then
        nextId = 1
    end
    -- 从播放结束之后开始播放
    if self:isOvered() then
        nextId = ((audio.currentIndex) % #audio.playlist) + 1
    end

    -- 如果当前正在播放的音乐没有结束，就不自动下一首
    if self.playlist[nextId] then
        if nextId ~= 0 and network.userid == self.playlist[nextId].userid then
            self:next(nextId)
        end
    else
        print(" ## automusicNext no nextId..", nextId)
    end
end


local waittime = os.time()
function Audio:update(dt)

    -- 如果没有音乐资源就等待，直到下载好
    if os.time() - waittime > 0.5 then
        waittime = os.time()


    else
        -- 不是定时的逻辑
    end
    
    self:automusicNext()
    -- 音乐资源等待下载
    if self.stuck then
        print("stuck!!")
        local musicpath = fileManager:getFilePathByName(self.playlist[self.currentIndex].name)
        if musicpath then
            self:MusicStart(musicpath, 0)
            self.downloadProgress = 0
        end
    end

end



-- 开启音乐播放（带淡入）
function Audio:MusicStart(path, delay)
        self:loadMusic(path)
        if self.currentSource then
            --self:setVolume(0)
            self:play(0)
        end
        uiManager:refresh("playlistUI")
end

function Audio:setVolume(vol)
    self.volume = math.max(0, math.min(1, vol))
    if self.currentSource then
        self.currentSource:setVolume(self.volume)
    end
    print("setVolume", self.volume)
end

-- 判断音乐是否存在
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
    self:savePlaylist()
    uiManager:refresh("playlistUI")
end

function Audio:removePlayMusic(name)
    print("remove music ", name)
    if not self:musicExist(name) then
        print(" ## musicNotExist..")
        return
    end
    for index, value in ipairs(self.playlist) do
        if value.name == name then
            table.remove(self.playlist, index)
        end
    end
    self:sendUpdatePlayList()
    self:savePlaylist()
    uiManager:refresh("playlistUI")
end

-- 发送列表信息
function Audio:sendUpdatePlayList(id)
    if id then
        -- 发送列表
        local msg = {
            type = "playlist_update",
            playlist = self.playlist
        }
        network:send_unicast(id, msg)
    else
        -- 发送列表
        local msg = {
            type = "playlist_update",
            playlist = self.playlist
        }
        network:send_Broadcast(msg)
    end

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

return Audio
