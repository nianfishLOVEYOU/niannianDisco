local ui = require "src.ui.ui"

local RoomUI = ui:extend()

function RoomUI:init()
    audio.playlist = globleManager:getGameData("playlist") or {}
    self:refresh()
end

-- 更新播放列表显示
function RoomUI:refresh()
    self:clearStacks()
    self:_buildStack()
end

    local tall = 20

function RoomUI:_ChangeRoom()
    
end


function RoomUI._slidded(value)
    print("Slider value changed to: " .. value)
end

function RoomUI:_buildStack()

    local width, height = love.graphics.getDimensions()
    -- 下面的拖拽换房间ui --
    self.dragRoomTip = Glove.Text:new("拖动换房间")
    self.dragRoomLogo = Glove.Image:new("res/image/dragRoomLogo.png") --拖动换房间
    self.Slider= Glove.Slider:new(0.5, self._slidded)
    self.Slider:setSize(width , 20)
    self.Slider.isDrawIcon = true
    local dragBackground = Glove.Image:new("res/image/dragBackground.png")

    local dragRoomHStack = Glove.HStack:new({ self.Slider })
    --local dragRoomBackHStack = Glove.HStack:new({  })
    local sw, sh = dragRoomHStack:getSize()
    dragRoomHStack:setPos(width / 2 - sw / 2, height - sh-tall/2) -- 将整个堆叠放在屏幕底部中央
    self:addStack(dragRoomHStack)
end

function RoomUI:update(dt)

end

function RoomUI:draw()
    --画一个长方形在底下
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
