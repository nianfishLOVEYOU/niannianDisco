-- lib/audio.lua
local json = require "lib.json"

local Audio = {
    currentSource = nil,
    playlist = {}, -- *{userid , path , duration, name }
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

--限制每次播放结束自动下一首只有一人广播
function Audio:automusicNext()
    -- 从0开始播放
    if #self.playlist==0 then return end

    local nextId =0
    --还没开始播放的时候播放
    if self.currentIndex == 0  then
        nextId=1
    end
    -- 从播放结束之后开始播放
    if self:isOvered() then
        nextId=((audio.currentIndex) % #audio.playlist) + 1
    end

    if nextId ~=0 and network.userid == self.playlist[nextId].userid then
        self:next(nextId)
    end
end

local waittime = os.time()
function Audio:update(dt)
    -- 如果没有音乐资源就等待，直到下载好
    if os.time() - waittime > 0.5 then
        waittime = os.time()

        self:automusicNext()
        --音乐资源等待下载
        if self.stuck then
            print("stuck!!")
            local musicpath = fileManager:getFilePathByName(self.playlist[self.currentIndex].name)
            if musicpath then
                self:MusicStart(musicpath, 0)
                self.downloadProgress = 0
            end
        end

    else
        --不是定时的逻辑
    end

end



local spectrumBars = 1    -- 仅获取1个频率能量值
local fftSize = 64      -- 满足 1024 ≥ 1 即可
local smoothFactor = 0.2  -- 平滑因子，避免圆形大小突变
local currentEnergy = 0   -- 当前能量值
function Audio:getMusicSpectrum()
    -- 参数1: 要获取的柱形数量 (spectrumBars)
    -- 参数2: FFT的大小 (通常是 512, 1024, 2048)
    -- 参数3: 结果存放的数组 (可选)
    local spectrum = love.audio.getSpectrum(spectrumBars, fftSize)
    local rawEnergy = spectrum[1]  -- 数组只有1个元素，取索引1
    
    -- 平滑处理能量值，让圆形大小变化更自然
    currentEnergy = currentEnergy * smoothFactor + rawEnergy * (1 - smoothFactor)
    return currentEnergy
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
function Audio:sendUpdatePlayList(id)
    if id then
        -- 发送列表
        local msg = {
            type = "playlist_update",
            playlist = self.playlist,
        }
        network:send_unicast(id,msg)
    else
        -- 发送列表
        local msg = {
            type = "playlist_update",
            playlist = self.playlist,
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

-- 暂时用不到
function Audio:removePlayMusic(name)
    eventManager:emit("event_playListRemove")
end

return Audio
