local playlistManager = {
    -- 结构为{listname,{list={musicinfo={name,path,duration,username},num,}}}
    localPlaylist = {},
    localMusic = {}, --只是用来读减少cpu压力的
}
--管理本地音乐
systemManager:init_regester(function()
    playlistManager:init()
end)

function playlistManager:clearlocalPlaylist()
    self.localPlaylist = {}
    self:savelocalPlaylist()
end

function playlistManager:init()
    self.localPlaylist = globleManager:getGameData("localPlaylist")
    --初始化空的歌单
    if self.localPlaylist == nil then
        self.localPlaylist = {}
        self:addlocalPlaylist("tmp", "暂存歌单")
    end
    self:updatelocalMusic()
    --读取文件查漏补缺
    self:readFolder()
    self:savelocalPlaylist()
end

function playlistManager:updatelocalMusic()
    for k, list in pairs(self.localPlaylist) do
        for k2, v2 in pairs(list.list) do
            self.localMusic[v2.name] = v2
        end
    end
end

function playlistManager:savelocalPlaylist()
    globleManager:saveGameData("localPlaylist", self.localPlaylist)
end

--校对文件夹内的文件，把没有在歌单里的文件加上去,也会创建歌单
function playlistManager:readFolder()
    local isadd = false
    --获取音乐文件夹表
    local localfiles = fileManager:listAllFiles(commonData.musicPath)
    --遍历添加歌单
    for i, f in ipairs(localfiles) do
        if f.type == "folder" then
            --如果没有这个歌单就创建一个
            if not self.localPlaylist[f.name] then
                self:addlocalPlaylist(f.name, "tips:好像是不小心进来的文件夹QAQ")
            end
            --遍历添加文件进入歌单
            for i2, f2 in ipairs(f.files) do
                if f2.type == "file" then
                    local extend = fileManager.getExtendName(f2.name)
                    --筛选类型
                    if extend == "mp3" or extend == "MP3" then
                        --需要吧没有加入过歌单的音乐也加入歌单
                        if not self.localMusic[f2.name] then
                            print("[readFolder] add music :" .. f2.name)
                            --获得音乐长度
                            local music = love.audio.newSource(f2.path, "stream")
                            self:addMusic(f2.name, f2.path, f.name, music:getDuration(), "self")
                            music = nil
                            isadd = true
                        end
                    else
                        return
                    end
                end
            end
        end
    end
    return isadd
end

-- 添加歌单
function playlistManager:addlocalPlaylist(listname, remark)
    fileManager.createDir(commonData.musicPath .. listname)

    if self.localPlaylist[listname] then
        print("! allready exsit list :" .. listname, remark)
    else
        self.localPlaylist[listname] = { list = {}, num = 0, remark = remark or "", }
        print("[addlocalPlaylist] :" .. listname, remark)
    end
    self:savelocalPlaylist()
end

--添加一个，默认是tmp
function playlistManager:addMusic(musicname, path, listname, duration, username)
    if self:musicExist(musicname) then
        print(" ## same music musicExist..")
        return
    end

    -- 包含一些用得到的信息
    local musicInfo = self.musicInfo(musicname, path, username)
    musicInfo.duration = duration

    if self.localPlaylist[listname] then
        table.insert(self.localPlaylist[listname].list, musicInfo)
        self.localMusic[musicInfo.name] = musicInfo
    else
        print("playlist is not exsit :" .. listname)
    end

    self:savelocalPlaylist()
end

function playlistManager:musicExist(name)
    if self:getMusicPath(name) then
        return true
    end
    return false
end

-- 获取path
function playlistManager:getMusicPath(name)
    for k, v in pairs(self.localPlaylist) do
        for k2, v2 in pairs(v.list) do
            if v2.name == name then
                return true
            end
        end
    end
    return false
end

-- 删除音乐
function playlistManager:removeMusic(name)
    local removeMusic
    for k, v in pairs(self.localPlaylist) do
        for k2, v2 in pairs(v.list) do
            if v2.name == name then
                removeMusic = k2
                table.remove(v.list, k2)
            end
        end
    end
    print("cant removeMusic :" .. name)
    if removeMusic then
        self.localMusic[removeMusic.name] = nil
        return removeMusic
    end
    return nil
    --删除音乐文件
end

--检查相同名字
function playlistManager:chackSamName()

end

function playlistManager.musicInfo(name, path, user)
    user = user or "不知道谁>>一个神秘的家伙"
    local musicInfo = {
        name = name,
        path = path,
        interTime = globleManager:getDate(),
        sendUser = user,
    }
    return musicInfo
end

-- 
function playlistManager:musicTransfer(name, targetListName)
    if self.localPlaylist[targetListName] then
        local TransferMusic = self:removeMusic(name)
        if TransferMusic then
            table.insert(self.localPlaylist[targetListName].list, TransferMusic)
            self.localMusic[TransferMusic.name] = TransferMusic
        else
            print("musicTransfer music not exsit :" .. name)
        end
    else
        print("playlist is not exsit :" .. targetListName)
    end
end

--根据日期来排序
function playlistManager:SortPlaylistByDate()

end

return playlistManager
