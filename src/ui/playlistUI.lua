-- ui/playlist.lua
local image = require "src.common.aUIImage"
local ui = require "src.ui.ui"

local PlaylistUI = ui:extend() -- 子类继承父类

local slideW = love.graphics.getWidth() - 200
local slideH = 160

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
    uiManager:refresh("playlistUI")
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
    self:refresh()
end

function PlaylistUI:refresh()

    -- 创建本地列表
    self:clearStacks()
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
end

---------------播放列表------------
function PlaylistUI:update(dt)

end

-- 刷新按钮状态和音乐提示,或者记录之前的拖动数据
function PlaylistUI:updateListInfo()

end

function PlaylistUI:addPlayListItem(name)
    local iswaitstr = audio.stuck and "[ ↓ing " .. audio.downloadProgress .. "%]" or "[√]"
    local musicInfo = i == audio.currentIndex and "[播放]" .. iswaitstr or ""
    local nameText = Glove.Text:new(musicInfo .. name)
    nameText:setSize(120, 30)
    nameText:setOmit(true)
    nameText.color = {0, 0, 0}
    -- 删除按钮
    local button = Glove.Button:new("删除", function()
        audio:removePlayMusic(name)
        self:removePlayListItem(name)
    end)
    button.padding = 5
    button:setSize(0, 0)
    button.color = {0, 0, 0, 0}

    local hstack = Glove.HStack:new({nameText, button})
    hstack.color = {0, 0, 0, 0.3}
    hstack:setName(name)
    self.playList:add(hstack)
end

function PlaylistUI:removePlayListItem(name)
    for i, v in ipairs(self.playList.children) do
        if v.name == name then
            table.remove(self.playList.children, i)
            break
        end
    end
end

-- 获得播放列表ui
function PlaylistUI:_buildPlayListStack()
    local tT = Glove.Text:new("播放列表:")
    tT.color = {1, 1, 1}
    local tT2 = Glove.Text:new(">拖拽音乐.mp3文件加入歌单<")
    tT2.color = {1, 0, 0}
    tT2:setSize(200, 20)
    local title = Glove.HStack:new({tT, tT2})
    title:setName("title")
    self:addStack(title)
    title:setLocalPos(0, 20, self.z)

    local vstack = Glove.VStack:new({}, 10)
    vstack:setName("playerlistui vstack")
    -- 滑动条
    local slidePanel = Glove.SlidePanel:new(vstack)
    self.playList = slidePanel
    self:addStack(slidePanel)
    slidePanel:setLocalPos(0, 50, self.z)
    slidePanel:setSize(slideW, slideH)
    slidePanel.color = {1, 1, 1, 1} -- 设置滑动面板的颜色为白色
    for i, v in ipairs(audio.playlist) do
        self:addPlayListItem(v.name)
    end
end

-- 获得本地播放列表ui
function PlaylistUI:addLocalPlayListItem(path, name, duration)
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
end

function PlaylistUI:_buildLocalPlayListStack()
    local tT = Glove.Text:new("tmp本地列表:")
    tT.color = {1, 1, 1}
    tT:setSize(200, 20)
    local title = Glove.HStack:new({tT})
    self:addStack(title)
    title:setLocalPos(0, 230, self.z)

    -- 本地音乐列表
    local vstack = Glove.VStack:new({}, 10)
    vstack:setName("playerlistui vstack")

    local slidePanel = Glove.SlidePanel:new(vstack)
    self.LocalPlayList = slidePanel
    slidePanel:setSize(slideW, slideH)
    slidePanel.color = {1, 1, 1, 1} -- 设置滑动面板的颜色为白色
    self:addStack(slidePanel)
    slidePanel:setLocalPos(0, 250, self.z)
    for i, v in ipairs(playlistManager.localPlaylist["tmp"].list) do
        self:addLocalPlayListItem(v.path, v.name, v.duration)
    end

    -- vstack:setPos(0, 0) --大概是拖拽条的限制归为问题
end

function PlaylistUI:draw()

    -- if self.LLimage then
    --     self.LLimage:draw()
    --     self.LLimage2:draw()
    -- end
    self:drawStacks()
    -- 拖拽区域图片
    -- self.inputImage:draw()
end

function PlaylistUI:wheelmoved(x, y)

end

function PlaylistUI:destroy()
    PlaylistUI.super.destroy(self)
    eventManager:off("fileDrop", musicInput)
end

return PlaylistUI
