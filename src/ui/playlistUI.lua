-- ui/playlist.lua
local image = require "src.common.aUIImage"
local colors = require "glove/colors"
local ui = require "src.ui.ui"

local PlaylistUI = {}
PlaylistUI.__index = PlaylistUI
setmetatable(PlaylistUI, {
    __index = ui
}) -- 子类继承父类
function PlaylistUI:new(...)
    local obj = ui:new(...) -- 先走父类构造
    setmetatable(obj, PlaylistUI) -- 再把实例的元表改为子类
    -- 初始化子类特有属性
    local width = love.graphics.getWidth()
    self.posx = width - 200
    self.posy = 30

    self.inputImage = image:new("res/image/ui/add.png", 20, 20, 0, 0, "ui")
    self.inputImage:setScale(2, 2)
    return obj
end

local musicInput = function(file, name, fullname, extend)
    -- local x, y = love.mouse.getPosition()
    -- local isInUI = x > self.inputImage.x and x < self.inputImage.x + self.inputImage.width and y >
    --                    self.inputImage.y and y < self.inputImage.y + self.inputImage.height
    -- if not isInUI then
    --     print("not in musicInput")
    --     return
    -- end

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

function PlaylistUI:refresh()
    -- 创建本地列表
    -- print("##playlist UpdateUi")
    if self.stack then
        self.stack:destroy()
    end
    self.stack = self:getvstack()
end

function PlaylistUI:init()
    eventManager:on("fileDrop", musicInput)
    self.scrollPosition = 0
    self.itemHeight = 30
    self:refresh()
end

---------------播放列表------------
function PlaylistUI:update(dt)

end

-- 获得播放列表ui
function PlaylistUI:getvstack()
    local vstackchild = {}

    local title = Glove.HStack({
        align = "start",
        spacing = 0
    }, {Glove.Text("播放列表:", {
        color = colors.white
    })})
    table.insert(vstackchild, title)

    for i, v in ipairs(audio.playlist) do
        local name = Glove.Text((i == audio.currentIndex and "[播放中]" or "") .. v.name, {
            color = colors.white
        })
        local hstack = Glove.HStack({
            align = "start",
            spacing = 0
        }, -- glove.Spacer(), --把剩下的部件推到右边
        {name})
        table.insert(vstackchild, hstack)
    end
    local vstack = Glove.VStack({
        spacing = 30
    }, vstackchild -- Glove.Spacer()
    )
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
    self.stack:draw(self.posx, self.posy)

    love.graphics.setScissor() -- 关闭剪裁

    -- 拖拽区域图片
    self.inputImage:draw()
    
    -- local x, y = love.mouse.getPosition()
    -- local isInUI = x > self.inputImage.x and x < self.inputImage.x + self.inputImage.w and y > self.inputImage.y and
    --                    y < self.inputImage.y + self.inputImage.h
    -- if isInUI then
    --     love.graphics.setColor(1, 1, 0)
    --     love.graphics.rectangle("line", self.inputImage.x, self.inputImage.y, self.inputImage.w,
    --         self.inputImage.h)
    -- end
end

function PlaylistUI:wheelmoved(x, y)

end

function PlaylistUI:destroy()
    eventManager:off("fileDrop", musicInput)
    self.scrollPosition = 0
    self.itemHeight = 30
    self.stack:destroy()
end

return PlaylistUI
