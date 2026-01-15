local json = require "lib.json"
local ui = require "src.ui.ui"

local PlayerUI = ui:extend()

function PlayerUI:init()
    self.isDragging = false
    self:refresh()
end

-- 更新播放列表显示
function PlayerUI:refresh()
    
    self:clearStacks()
    --背景
    self:addStack(self:getBackStack())
    -- 创建本地列表
    self:addStack(self:getvstack())

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
    if not network.musicTransfering > 0 then
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
    if not network.musicTransfering > 0 then
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
    print("list")
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
    ------ slider-------
    local playSlider = Glove.Slider:new(0,function (value)
        PlayerUI:dragProgress(value)
    end)
    playSlider:setSize(width - 80,20)
    ------ musicvoice slider------
    
    local progressText = Glove.Text:new("进度:")
    local voiceText = Glove.Text:new("音量:")
    local voiceSlider = Glove.Slider:new(0,function (value)
        audio:setVolume(value)
    end)

    --右边对其
    local musiVoiceHStack= Glove.HStack:new({progressText, voiceText,voiceSlider}, 0, "center")
    local sliderHStack= Glove.HStack:new({ playSlider }, 0, "center")
    local buttonHStack = Glove.HStack:new({ perButton, playButton, nextButton, listButton }, 20, "center")
    local stack = Glove.VStack:new({musiVoiceHStack, sliderHStack ,buttonHStack })

    local sw, sh = stack:getSize()
    stack:setPos(width / 2 - sw / 2, height - 50)
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

function PlayerUI:draw()

    
    PlaylistUI.super.draw(self)
    local width, height = love.graphics.getDimensions()

    -- 当前播放信息
    local currentTrack = audio:getCurrentTrack()
    if currentTrack then
        local duration = audio:getCurrentDuration()
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("正在播放: " .. currentTrack.name, 20, height - 90)

        -- 进度条
        local progressWidth = width - 40
        local progress = 0
        if duration > 0 then
            progress = audio:getPosition() / duration
        end

        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("fill", 20, height - 60, progressWidth, 10)

        love.graphics.setColor(0.2, 0.6, 1)
        love.graphics.rectangle("fill", 20, height - 60, progressWidth * progress, 10)

        -- 时间显示
        local currentMinutes = math.floor(audio:getPosition() / 60)
        local currentSeconds = math.floor(audio:getPosition() % 60)
        local totalMinutes = math.floor(duration / 60)
        local totalSeconds = math.floor(duration % 60)

        love.graphics.print(string.format("%02d:%02d / %02d:%02d", currentMinutes, currentSeconds, totalMinutes,
            totalSeconds), width / 2 - 50, height - 90)
    else
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("没有正在播放的音乐", 20, height - 90)
    end

    -- 音量控制
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("音量:", width - 150, height - 90)

    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("fill", width - 120, height - 80, 100, 10)

    love.graphics.setColor(0.2, 0.6, 1)
    love.graphics.rectangle("fill", width - 120, height - 80, 100 * audio.volume, 10)

    self.stack:draw()

    if network.musicTransfering > 0 then
        love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
        love.graphics.rectangle("fill", 0, height - 100, width, 100)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("正在传输", width / 2 - 20, height - 70)
    end
end

function PlayerUI:mousePressed(x, y, button)
    if button ~= 1 then
        return
    end

    local width, height = love.graphics.getDimensions()
    -- 进度条拖动
    if y > height - 65 and y < height - 50 and x > 20 and x < width - 20 then
        self.isDragging = true
        self:dragProgress(x)
    end

    -- 音量控制
    if y > height - 85 and y < height - 65 and x > width - 120 and x < width - 20 then
        local volume = (x - (width - 120)) / 100
        audio:setVolume(volume)
    end
end

function PlayerUI:mouseLeased(x, y, button)
    if button ~= 1 then
        return
    end
    self.isDragging = false
end

function PlayerUI:mouseMoved(x, y, dx, dy)
    if self.isDragging then
        self:dragProgress(x)
    end
end

function PlayerUI:dragProgress(x)
    local width = love.graphics.getWidth()
    local progressWidth = width - 40
    local progress = (x - 20) / progressWidth
    progress = math.max(0, math.min(1, progress))
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
