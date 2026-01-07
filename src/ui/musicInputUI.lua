local colors = require "glove/colors"
local enet = require "enet"
local ui = require "src.ui.ui"

local MusicInputUI = {}
MusicInputUI.__index = MusicInputUI
setmetatable(MusicInputUI, {
    __index = ui
}) -- 子类继承父类
function MusicInputUI:new(...)
    local obj = ui:new(...) -- 先走父类构造
    setmetatable(obj, MusicInputUI) -- 再把实例的元表改为子类
    -- 初始化子类特有属性
    return obj
end

local musicInput = function(file,name, fullname, extend)
    local x, y = love.mouse.getPosition()
    local isInUI = x > MusicInputUI.posx and x < MusicInputUI.posx + MusicInputUI.stack:getWidth() and y > MusicInputUI.posy and y < MusicInputUI.posy +
    MusicInputUI.stack:getHeight()
    if not isInUI then
        print("not in musicInput")
        return
    end
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

function MusicInputUI:init()
    MusicInputUI.posy = 30
    eventManager:on("fileDrop", musicInput)
    MusicInputUI:refresh()
    
    MusicInputUI.posx = love.graphics.getWidth() -self.stack:getWidth()- 30
end

local closeUI = function()
    print("closeUI")
    uiManager:removeUI("musicInputUI")
end

-- 更新播放列表显示
function MusicInputUI:refresh()
    -- 创建本地列表
    self.stack = self:getvstack()
    self.closehstack = Glove.HStack({}, {Glove.Button_img("","res/image/ui/x.png", {
        onClick = closeUI,
        width=20,
        height=20
    })})
end

function MusicInputUI:draw()
    if self.stack then
        self.stack:draw(self.posx, self.posy)
        self.closehstack:draw(self.posx+ self.stack:getWidth()-30,self.posy+30)
    end

end

function MusicInputUI:getvstack()

    local vstackchild = {}

    local addimage = Glove.Image("res/image/ui/add.png",{scale=2})
    -- 房间号输入
    local hstack = Glove.HStack({}, {addimage})
    local vstack = Glove.VStack({}, {hstack})

    return vstack
end

function MusicInputUI:destroy()
    eventManager:off("fileDrop", musicInput)
    self.stack:destroy()
end
return MusicInputUI
