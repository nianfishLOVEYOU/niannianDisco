-- ui/playlist.lua
local image = require "src.common.aUIImage"
local ui = require "src.ui.ui"

local PlaylistUI = ui:extend() -- 子类继承父类

local slideW = love.graphics.getWidth() - 200
local slideH = 160
local inPlaylistColor = {0.15, 0.50, 0.1, 1}
local normalColor = {0, 0, 0, 1}
local playingColor = {0.80, 0.3, 0.12, 1}

local state = {
    playlist = "playlist",
    localplaylist = "localplaylist",
    playlistPos = {
        x = 20,
        y = 30
    },
    playlistSize = {
        w = 200,
        h = 280
    },
    localplaylistPos = {
        x = 20,
        y = 30
    },
    localplaylistSize = {
        w = 200,
        h = 280
    }
}

local musicInput = function(file, name, fullname, extend)
    -- 判断文件格式
    if not (extend == "mp3" or extend == "MP3") then
        print("!Error fail extend!")
        return
    end
    -- 判断文件是否存在
    local tmpPath = commonData.tmpPath .. name
    if (fileManager:fileIsExsit(tmpPath)) then
        print(">x<  file exsit do not cope: " .. tmpPath)
        local music = love.audio.newSource(tmpPath, "stream")
        audio:addPlayMusic(tmpPath, music:getDuration(), name)
        music = nil

        return
    end

    -- 加入音乐文件索引表
    local data = file:read()
    local success, message = love.filesystem.write(tmpPath, data)
    if not success then
        error("! save file fail !: : " .. message)
    end

    local music = love.audio.newSource(tmpPath, "stream")
    playlistManager:addMusic(name, tmpPath, "tmp", music:getDuration(), "self")
    audio:addPlayMusic(tmpPath, music:getDuration(), name)
    music = nil
end

function PlaylistUI:init()
    local width = love.graphics.getWidth()
    self.posx = width - 200
    self.posy = 30

    self.inputImage = image:new("res/image/ui/add.png", 20, 20, 0, 0, "ui")
    self.inputImage:setScale(2, 2)

    eventManager:on("fileDrop", musicInput)
    self.scrollPosition = 0
    self.itemHeight = 30
    self.playListItemMap = {}
    self.localPlayListItemMap = {}
    self:refresh()
end

function PlaylistUI:refresh()
    -- 创建本地列表
    self:clearStacks()
    self.playListItemMap = {}
    self.localPlayListItemMap = {}
    self:_buildPlayListStack()
    self:_buildLocalPlayListStack()

    if self.LLimage == nil then
        self.LLimage = image:new("res/image/ui/lineTail.png", self.playList.x + self.playList.w + 8,
            self.playList.y + self.playList.h + 8)
        self.LLimage:setScale(0.7, 0.7)
        self.LLimage.rotation = 0.8

        self.LLimage2 = image:new("res/image/ui/lineTail.png", self.LocalPlayList.x + self.LocalPlayList.w + 8,
            self.LocalPlayList.y + self.LocalPlayList.h + 8)
        self.LLimage2:setScale(0.7, 0.7)
        self.LLimage2.rotation = 0.8
    end

    self:open(self.mode or "playlist")
end

---------------播放列表------------
function PlaylistUI:update(dt)
    self:updatePlayListStateText()
    self:updateLocalPlayListStateText()
end

-- 刷新按钮状态和音乐提示,或者记录之前的拖动数据
function PlaylistUI:updateListInfo()

end

function PlaylistUI:open(mode)
    self.playList.visiable = mode == "playlist"
    self.LocalPlayList.visiable = mode == "localplaylist"
    self.mode = mode
end

function PlaylistUI:addPlayListItem(name, index)
    if not index then
        for i, v in ipairs(audio.playlist) do
            if v.name == name then
                index = i
                break
            end
        end
    end

    local nameText = Glove.Text:new(name)
    nameText:setSize(120, 30)
    nameText:setOmit(true)
    nameText.color = inPlaylistColor
    -- 删除按钮
    local button = Glove.Button:new("删除", function()
        audio:removePlayMusic(name)
        -- self:removePlayListItem(name)
    end)
    button.padding = 5
    button:setSize(0, 0)
    button.color = {0, 0, 0, 0}

    local hstack = Glove.HStack:new({nameText, button})
    hstack.color = {0, 0, 0, 0.3}
    hstack:setName(name)
    self.playList:add(hstack)

    self.playListItemMap[name] = {
        textWidget = nameText,
        button = button,
        stack = hstack,
        index = index
    }

    self:updatePlayListStateText()
end

function PlaylistUI:removePlayListItem(name)
    self.playList:remove(name)
    self.playListItemMap[name] = nil
end

-- 获得播放列表ui
function PlaylistUI:_buildPlayListStack()
    local vstack = Glove.VStack:new({}, 10)
    vstack:setName("playerlistui vstack _buildPlayListStack")
    -- 滑动条
    local slidePanel = Glove.SlidePanelStructer:new(vstack)
    slidePanel:setTitle("播放列表:>拖入音乐.mp3")
    self.playList = slidePanel
    self:addStack(slidePanel)
    slidePanel:setLocalPos(state.playlistPos.x, state.playlistPos.y, self.z)
    slidePanel:setSize(state.playlistSize.w, state.playlistSize.h)
    slidePanel.color = {1, 1, 1, 1} -- 设置滑动面板的颜色为白色
    for i, v in ipairs(audio.playlist) do
        self:addPlayListItem(v.name, i)
    end
end

-- 获得本地播放列表ui
function PlaylistUI:addLocalPlayListItem(path, name, duration)
    -- local stateText = Glove.Text:new("tmp")

    local nameText = Glove.Text:new(name)
    nameText:setSize(120, 30)
    nameText:setOmit(true)
    nameText.color = {0, 0, 0}
    local button = Glove.Button:new("添加", function()
        audio:addPlayMusic(path, duration, name)
    end)
    button.padding = 5
    button:setSize(0, 0)
    button.color = {0, 0, 0, 0}

    local hstack = Glove.HStack:new({nameText, button})
    hstack.color = {0, 0, 0, 0.3}
    hstack:setName(name)
    self.LocalPlayList:add(hstack)

    self.localPlayListItemMap[name] = {
        textWidget = nameText,
        stack = hstack,
        path = path,
        duration = duration
    }
end

function PlaylistUI:_buildLocalPlayListStack()
    -- 本地音乐列表
    local vstack = Glove.VStack:new({}, 10)
    vstack:setName("playerlistui vstack _buildLocalPlayListStack")

    local slidePanel = Glove.SlidePanelStructer:new(vstack)
    slidePanel:setTitle("tmp本地列表:")
    self.LocalPlayList = slidePanel
    slidePanel.color = {1, 1, 1, 1} -- 设置滑动面板的颜色为白色
    self:addStack(slidePanel)
    slidePanel:setSize(state.localplaylistSize.w, state.localplaylistSize.h)
    slidePanel:setLocalPos(state.localplaylistPos.x, state.localplaylistPos.y, self.z)
    for i, v in ipairs(playlistManager.localPlaylist["tmp"].list) do
        self:addLocalPlayListItem(v.path, v.name, v.duration)
    end

    -- vstack:setPos(0, 0) --大概是拖拽条的限制归为问题
end

-- 更新状态，绿色表示在歌单，黄色表示在播放
function PlaylistUI:updatePlayListStateText()
    if not self.playListItemMap then
        return
    end

    local currentIndex = audio.currentIndex or 0
    local isStuck = audio.stuck and currentIndex > 0
    local waitingText = isStuck and (" [缓冲 " .. (audio.downloadProgress or 0) .. "%]") or ""

    for i, info in ipairs(audio.playlist) do
        local itemInfo = self.playListItemMap[info.name]
        if itemInfo and itemInfo.textWidget then
            local isCurrent = (i == currentIndex)
            local prefix = isCurrent and "[播放中] " or ""
            itemInfo.textWidget:setText(prefix .. info.name .. (isCurrent and waitingText or ""))
            -- itemInfo.button.clickFunc = function()
            --     audio:removePlayMusic(info.name)
            --     -- self:removePlayListItem(name)
            -- end
            if isCurrent then
                itemInfo.textWidget.color = playingColor
            else
                itemInfo.textWidget.color = inPlaylistColor
            end
            itemInfo.index = i
        end
    end
end

-- 更新状态，绿色表示在歌单，黄色表示在播放
function PlaylistUI:updateLocalPlayListStateText()
    if not self.localPlayListItemMap then
        return
    end

    local currentTrack = audio:getCurrentTrack()
    local currentName = currentTrack and currentTrack.name or nil

    local inPlaylist = {}
    for _, info in ipairs(audio.playlist) do
        inPlaylist[info.name] = true
    end

    for name, itemInfo in pairs(self.localPlayListItemMap) do
        if itemInfo and itemInfo.textWidget then
            if currentName and name == currentName then
                itemInfo.textWidget.color = playingColor
                itemInfo.textWidget:setText("[播放中] " .. name)
            elseif inPlaylist[name] then
                itemInfo.textWidget.color = inPlaylistColor
                itemInfo.textWidget:setText(name)
            else
                itemInfo.textWidget.color = normalColor
                itemInfo.textWidget:setText(name)
            end
        end
    end
end

function PlaylistUI:draw()

    self:drawStacks()

    if self.mode == "playlist" then
        -- if nianAI then
        --     local nianx, niany = nianAI:getNianPos()
        --     drawTailStandard(self.playList.x + self.playList.w, self.playList.y + self.playList.h / 2,"y", nianx+20, niany-100)
        -- end
    elseif self.mode == "localplaylist" then
        -- if nianAI then
        --     local nianx, niany = nianAI:getNianPos()
        --     drawTailStandard(self.playList.x + self.playList.w, self.playList.y + self.playList.h / 2,"y", nianx+20, niany-100)
        -- end
    end
end

function PlaylistUI:wheelmoved(x, y)

end

function PlaylistUI:destroy()
    PlaylistUI.super.destroy(self)
    eventManager:off("fileDrop", musicInput)
end

return PlaylistUI
