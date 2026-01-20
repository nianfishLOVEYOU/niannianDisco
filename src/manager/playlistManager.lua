local playlistManager = {
    -- 结构为{listname,{list={musicinfo={name,path,duration,username},num,}}}
    localPlaylist = {}

}

function playlistManager:init()
    self.localPlaylist = globleManager.getGameData("localPlaylist")
    if self.localPlaylist == nil then
        
        self.localPlaylist = {}
        self:addList("tmp")
    end
end

function playlistManager:savelocalPlaylist()
    globleManager.saveGameData("localPlaylist", self.localPlaylist)
end

function playlistManager:getlocalPlaylist()
    --获取音乐文件夹表
    local localPlayList = fileManager:listAllFiles(commonData.musicPath)
    --遍历添加歌单
    for i, foldInfo in ipairs(localPlayList) do
        self.localPlaylist[foldInfo.name] = {}
        if foldInfo.type == "folder" then
            --遍历添加文件进入歌单
            for j, fileInfo in ipairs(foldInfo.files) do
                if foldInfo.type == "file" then
                    table.insert(self.localPlaylist[foldInfo.name], self.musicInfo(fileInfo.name, fileInfo.path))
                end
            end
        end
    end
end

-- 添加歌单
function playlistManager:addList(listname, remark)
    if self.localPlaylist[listname] then
        print("! allready exsit list :" .. listname)
    else
        self.localPlaylist[listname] = { list = {}, num = 0, remark = remark or "", }
    end
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
    else

    end
end

function playlistManager:musicExist(name)
    if self:getMusicPath(name) then
        return true
    end
    return false
end

function playlistManager:getMusicPath(name)
    for k, v in pairs(self.localPlaylist) do
        for k2, v2 in pairs(v.list) do
            if v.name == name then
                return true
            end
        end
    end
    return false
end

--检查相同名字
function playlistManager:chackSamName()

end

--校对文件夹内的文件，把没有在歌单里的文件加上去
function playlistManager:readFolder()

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

function playlistManager:musicTransfer(name, targetList)

end

--根据日期来排序
function playlistManagerSortPlaylistByDate()

end

return playlistManager
