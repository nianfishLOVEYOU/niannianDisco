-- ui/playlist.lua
local image = require "src.common.aUIImage"
local ui = require "src.ui.ui"

local PlaylistUI = ui:extend() -- 子类继承父类


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
    self:refresh()
end

function PlaylistUI:refresh()
    -- 创建本地列表
    self:clearStacks()
    self:addStack(self:getvstack())
    --self:addStack(self:getlocalPlayListStack())
end

---------------播放列表------------
function PlaylistUI:update(dt)

end

function PlaylistUI:getlocalPlayListStack()
    local title = Glove.HStack:new({ Glove.Text:new("tmp本地列表:") })
    title:setName("title tmp")

    local listVstack = Glove.VStack:new({}, 10)
    for i, v in ipairs(playlistManager.localPlaylist["tmp"].list) do
        local nameText = Glove.Text:new(v.name)
        nameText:setSize(120, 20)
        local button = Glove.Button:new("添加", function()
            audio:addPlayMusic(v.path, v.duration, v.name)
        end)
        button.padding = 5
        button:setSize(0, 0)

        local hstack = Glove.HStack:new({ nameText, button })
        hstack:setName(v.name)
        listVstack:addChild(hstack)
    end
    listVstack:layout()

    local vstack = Glove.VStack:new({ title, listVstack }, 10)
    vstack:setName("playerlistui vstack")
    --滑动条
    local slidePanel = Glove.SlidePanel:new(vstack)
    slidePanel:setPos(self.posx - 250, self.posy, self.z)
    slidePanel:setSize(200, 300)
    return slidePanel
end

-- 获得播放列表ui
function PlaylistUI:getvstack()
    local title = Glove.HStack:new({ Glove.Text:new("播放列表:") })
    title:setName("title")
    local title2 = Glove.Text:new(">拖拽音乐.mp3文件加入歌单<")
    title2.color = { 1, 0, 0 }
    title2:setSize(0, 20)

    local listVstack = Glove.VStack:new({}, 10)
    for i, v in ipairs(audio.playlist) do
        local iswaitstr = audio.stuck and "[ ↓ing " .. audio.downloadProgress .. "%]" or "[√]"
        local musicInfo = i == audio.currentIndex and "[播放]" .. iswaitstr or ""
        local nameText = Glove.Text:new(musicInfo .. v.name)
        nameText:setSize(140, 20)
        --删除按钮
        local button = Glove.Button:new("删除", function()
            audio:removePlayMusic(v.name)
        end)
        button.padding = 5
        button:setSize(0, 0)

        local hstack = Glove.HStack:new({ nameText ,button })
        hstack:setName(v.name)
        listVstack:addChild(hstack)
    end
    listVstack:layout()

    local vstack = Glove.VStack:new({ title, title2, listVstack }, 10)
    vstack:setName("playerlistui vstack")
    --滑动条
    local slidePanel = Glove.SlidePanel:new(vstack)
    slidePanel:setPos(self.posx, self.posy, self.z)
    slidePanel:setSize(200, 300)
    return slidePanel
end

function PlaylistUI:draw()
    self:drawStacks()

    -- 拖拽区域图片
    --self.inputImage:draw()
end

function PlaylistUI:wheelmoved(x, y)

end

function PlaylistUI:destroy()
    PlaylistUI.super.destroy(self)
    eventManager:off("fileDrop", musicInput)
end

return PlaylistUI
