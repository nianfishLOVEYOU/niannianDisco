local ui = require "src.ui.ui"

local RoomUI = ui:extend()

local connectFail = function()
    uiManager:removeUI("waitingUI")
    -- 显示连接失败
    local width, height = love.graphics.getDimensions()
    --floatUI:addFloatText("连接失败", width / 2, height / 2)
    print("连接失败")
end

local connectSeccess = function()
    uiManager:removeUI("waitingUI")
    -- 显示连接成功
    local width, height = love.graphics.getDimensions()
    --floatUI:addFloatText("连接成功", width / 2, height / 2)
    print("连接成功")
end

function RoomUI:init()
    self.oldChannel = -1
    audio.playlist = globleManager:getGameData("playlist") or {}
    self:refresh()
    eventManager:on("connectFail", connectFail)
    eventManager:on("connectSeccess", connectSeccess)

    -- 一开始连接0号
    --self:_ChangeRoom(0)
end

function RoomUI:update(dt)
    local waitingUI = uiManager:getUI("waitingUI")
    if waitingUI then
        -- 超出等待上限
        if waitingUI.time > 10 then
            uiManager:removeUI("waitingUI")
            network:closeNetThread()
        end
    end
end

-- 更新播放列表显示
function RoomUI:refresh()
    self:clearStacks()
    self:_buildStack()
end

local tall = 20

function RoomUI:_ChangeRoom(value)
    -- 转游戏进程
    local channel = string.format("%02d", value)
    print("menu code =", channel)
    print("network.Start")
    network:startNetThread(channel)
    local waitingUI = require("src.ui.waitingUI"):new()
    uiManager:addUI("waitingUI", waitingUI)
    self.oldChannel = channel;
    print("RoomUI:network.Start")
end



function RoomUI:_buildStack()

    local width, height = love.graphics.getDimensions()
    -- 下面的拖拽换房间ui --
    self.dragRoomTip = Glove.Text:new("拖动换房间")
    self.dragRoomLogo = Glove.Image:new("res/image/dragRoomLogo.png") -- 拖动换房间
    self.Slider = Glove.Slider:new(0.5, function(value)
        print("Slider value changed to: " .. value)
        self:_ChangeRoom(value)
    end)
    self.Slider:setSize(width, 10)
    self.Slider.isDrawIcon = true
    self.Slider.discrete = 5
    self.Slider.drawProgressColor = false
    local dragBackground = Glove.Image:new("res/image/dragBackground.png")

    local dragRoomHStack = Glove.HStack:new({self.Slider})
    -- local dragRoomBackHStack = Glove.HStack:new({  })
    local sw, sh = dragRoomHStack:getSize()
    dragRoomHStack:setPos(width / 2 - sw / 2, height - sh - tall / 2) -- 将整个堆叠放在屏幕底部中央
    self:addStack(dragRoomHStack)
end

-- function RoomUI:update(dt)

-- end

function RoomUI:draw()
    -- 画一个长方形在底下
    love.graphics.setColor(1, 1, 1, 1) -- 设置颜色为白色
    local width, height = love.graphics.getDimensions()
    love.graphics.rectangle("fill", 0, height - tall, width, tall) -- 在底部画一个长方形
    self:drawStacks()
end

function RoomUI:dragProgress(progress)
    local duration = audio:getCurrentDuration()
    local newPosition = progress * duration
    audio:seek(newPosition)
    audio:sendUpdatePlayStatus()
end

function RoomUI:destroy()
    RoomUI.super.destroy(self)
    -- uiManager:removeUI("playlistUI")
end

return RoomUI
