-- ui/playlist.lua
local image = require "src.common.aUIImage"
local colors = require "glove/colors"
local ui = require "src.ui.ui"

local PlaylistUI = ui:extend() -- 子类继承父类


local musicInput = function(file, name, fullname, extend)
    -- 判断文件格式
    if not (extend == "mp3" or extend == "MP3") then
        print("!Error fail extend!")
        return
    end
    -- 判断文件是否存在
    local tmpPath = "tmp/" .. name
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
end
---------------播放列表------------
function PlaylistUI:update(dt)

end

-- 获得播放列表ui
function PlaylistUI:getvstack()
    local title = Glove.HStack:new({ Glove.Text:new("播放列表:") })
    title:setName("title") 

    local listVstack = Glove.VStack:new({}, 30)
    for i, v in ipairs(audio.playlist) do
        local name = Glove.Text:new((i == audio.currentIndex and "[播放中]" or "") .. v.name)
        local hstack = Glove.HStack:new({ name })
        hstack:setName( name)
        listVstack:addChild(hstack)
    end
    listVstack:layout()

    local vstack = Glove.VStack:new({ title,listVstack }, 30)
    vstack:setName( "playerlistui vstack")
    vstack:setPos(self.posx,self.posy,self.z)
    return vstack
end

function PlaylistUI:draw()
    local pass = 10
    local scissorX = self.posx
    local scissorY = self.posy
    local scissorW = 200
    local scissorH = 300
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle('fill', scissorX - pass, scissorY - pass, scissorW + pass * 2, scissorH + pass * 2)
    love.graphics.setScissor(scissorX, scissorY, scissorW, scissorH) -- 开启剪裁
    -- 裁剪内容
    PlaylistUI.super.draw(self)

    love.graphics.setScissor() -- 关闭剪裁

    -- 拖拽区域图片
    self.inputImage:draw()
end

function PlaylistUI:wheelmoved(x, y)

end

function PlaylistUI:destroy()
    PlaylistUI.super.destroy(self)
    eventManager:off("fileDrop", musicInput)
end

return PlaylistUI
