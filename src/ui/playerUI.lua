local json = require "lib.json"
local ui = require "src.ui.ui"

local PlayerUI = ui:extend()

function PlayerUI:init()
    audio.playlist = globleManager:getGameData("playlist") or {}
    self:refresh()
end

-- 更新播放列表显示
function PlayerUI:refresh()
    self:clearStacks()
    --背景
    self:addStack(self:getBackStack())
    -- 创建本地列表
    self:addStack(self:getvstack())

    self:addStack(Glove.Window:new("hello",function (widget)
        self:removeStack(widget)
    end))
end

local click = function()
    if audio:isPlaying() then
        print("-music pause-")
        audio:pause()
        audio:sendUpdatePlayStatus()
    else
        print("-music play-")
        audio:resume()
        audio:sendUpdatePlayStatus()
    end
end

local next = function()
    if #audio.playlist == 0 then
        return
    end
    if network.musicTransfering == 0 then
        print("-music next-")
        audio:next(((audio.currentIndex) % #audio.playlist) + 1)
    else
        print("!! during file transfer")
    end
end

local per = function()
    if #audio.playlist == 0 then
        return
    end
    if network.musicTransfering== 0 then
        print("-music next-")
        local index = audio.currentIndex - 1
        if index < 1 then
            index = #audio.playlist
        end
        audio:next(index)
    else
        print("!! during file transfer")
    end
end

local list = function()
    if not uiManager:getUI("playlistUI") then
        local playlistUI = require("src.ui.playlistUI"):new()
        uiManager:addUI("playlistUI", playlistUI)
    else
        uiManager:removeUI("playlistUI")
    end
end

function PlayerUI:getvstack()
    

    local width, height = love.graphics.getDimensions()
    ------playbutton------
    local playimg = audio.isPlaying and "res/image/ui/resume.png" or "res/image/ui/pase.png"
    local playButton = Glove.Button_img:new("", playimg, click)
    playButton:setScale(2, 2)
    local nextButton = Glove.Button_img:new("", "res/image/ui/next.png", next)
    nextButton:setScale(2, 2)
    local perButton = Glove.Button_img:new("", "res/image/ui/per.png", per)
    perButton:setScale(2, 2)
    local listButton = Glove.Button_img:new("", "res/image/ui/listbutton.png", list)
    listButton:setScale(2, 2)
    local openMusicDirButton = Glove.Button:new("打开音乐文件夹", fileManager.openMusicDirectory)
    openMusicDirButton.color ={0.5,0.8,0.5}

    ------ slider-------
    local playSlider = Glove.Slider:new(0, function(value)
        PlayerUI:dragProgress(value)
    end)
    playSlider:setSize(width - 80, 10)
    self.playSlider=playSlider
    ------ musicvoice slider------

    local infoText = Glove.Text:new("正在播放: ")
    self.infoText =infoText 
    local progressText = Glove.Text:new("进度:")
    self.progressText =progressText
    self.progressText:setSize(120,20)
    local volumeText = Glove.Text:new("音量:")
    local volumeSlider = Glove.Slider:new(audio.volume, function(value)
        audio:setVolume(value)
    end)

    --右边对其
    local musiVoiceHStack = Glove.HStack:new({infoText, progressText, volumeText, volumeSlider })
    local sliderHStack = Glove.HStack:new({ playSlider })
    local buttonHStack = Glove.HStack:new({ perButton, playButton, nextButton, listButton,openMusicDirButton} )
    local stack = Glove.VStack:new({ musiVoiceHStack, sliderHStack, buttonHStack },10,"center")

    local sw, sh = stack:getSize()
    stack:setPos(width / 2 - sw / 2, height - sh)
    return stack
end

function PlayerUI:getBackStack()
    local width, height = love.graphics.getDimensions()
    local c = {}
    for i = 1, 12, 1 do
        local ima = Glove.Image:new("res/image/ui/blackdrag.png")
        ima:setSize(50, 100)
        table.insert(c, ima)
    end


    local backstuck = Glove.HStack:new(c, 0)
    backstuck:setPos(0, height - 100)
    backstuck:setLocalPos(nil, nil, -1)

    return backstuck
end

function PlayerUI:update(dt)
    -- 当前播放信息
    local currentTrack = audio:getCurrentTrack()
    if network.musicTransfering > 0 then
        self.infoText:setText("正在传输.... ")
    else
        if currentTrack then
            self.infoText:setText("正在播放: " .. currentTrack.name)
            local duration = audio:getCurrentDuration()
            -- 时间显示
            local currentMinutes = math.floor(audio:getPosition() / 60)
            local currentSeconds = math.floor(audio:getPosition() % 60)
            local totalMinutes = math.floor(duration / 60)
            local totalSeconds = math.floor(duration % 60)
            self.progressText:setText("进度:" ..
                string.format("%02d:%02d / %02d:%02d", currentMinutes, currentSeconds, totalMinutes,
                    totalSeconds))
            local progress = audio:getPosition() / duration
            if(not self.playSlider.isDrag)then
                self.playSlider.progress=progress
            end
            --self.playSlider:setVisible(true)
        else
            self.infoText:setText("没有正在播放的音乐 ")
            self.playSlider.progress=0
            --self.playSlider:setVisible(false)
        end
    end
end

function PlayerUI:draw()
    self:drawStacks()
    local width, height = love.graphics.getDimensions()
    -- if network.musicTransfering > 0 then
    --     love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
    --     love.graphics.rectangle("fill", 0, height - 100, width, 100)
    --     love.graphics.setColor(1, 1, 1)
    --     love.graphics.print("正在传输", width / 2 - 20, height - 70)
    -- end
end

function PlayerUI:dragProgress(progress)
    local duration = audio:getCurrentDuration()
    local newPosition = progress * duration
    audio:seek(newPosition)
    audio:sendUpdatePlayStatus()
end

function PlayerUI:destroy()
    PlayerUI.super.destroy(self)
    uiManager:removeUI("playlistUI")
end

return PlayerUI
