-- slider拖拽条

local image = require "src.common.aUIImage"
local widget = require "src.glove.widgets.widget"

local g = love.graphics
local Slider = widget:extend()
local padding = 3

function Slider:init( progress,onSet)
    self.type = "Slider"
    self.progress = progress or 0
    self.color =  { 0.2, 0.6, 1 }
    self.backColor = { 0.5, 0.5, 0.5 }
    self.onSet=onSet
    self.isDrawIcon = false
    self.backGroundimage = nil --用love的图片，不用glove图片
    self.iconImage = nil --用love的图片，不用glove图片

    self.w = 60 
    self.h = 10 

end

function Slider:draw()
    -- 如果有自动尺寸则用自动尺寸，否则用
    local width = self.w
    local height = self.h

    self.progress=math.max(0, math.min(1, self.progress))
    
    -- 进度条
    if self:isOver(love.mouse.getPosition()) then --鼠标点击时
        g.setColor(self.backColor)
        g.rectangle("fill", self.x, self.y, self.w, self.h)

        g.setColor(self.color)
        g.rectangle("fill", self.x, self.y, self.w * self.progress, self.h)
    else --鼠标没点击的时候
        g.setColor(self.backColor)
        g.rectangle("fill", self.x, self.y, self.w, self.h)

        g.setColor(self.color)
        g.rectangle("fill", self.x, self.y, self.w * self.progress, self.h)
    end

    -- 画当前进度的小图标
    if self.isDrawIcon then 
        if self.iconImage then
            g.draw(self.iconImage, self.x + self.w * self.progress, self.y + self.h / 2)
        else
             local iconX = self.x + self.w * self.progress
            local iconY = self.y + self.h / 2
            local iconRadius = self.h *0.6
            g.setColor(1,0,0)
            g.circle("fill", iconX, iconY, iconRadius)
        end
       
    end
end

function Slider:setSize(w, h)
    self.w = w
    self.h = h
end


function Slider:onDragOver(x, y)
    self:dragProgress(x)
end

--被拖拽
function Slider:onDrag(x, y, dx, dy)
    
    self:justSetProgress(x)
end

function Slider:onClick(x, y, button)
    Glove.setFocus(self)
    self:dragProgress(x)
end

function Slider:justSetProgress(x)
    local ax = self.x
    local width = self.w
    self.progress = (x - ax) / width
    self.progress = math.max(0, math.min(1, self.progress))
end

function Slider:dragProgress(x)
    local ax = self.x
    local width = self.w
    self.progress = (x - ax) / width
    self.progress = math.max(0, math.min(1, self.progress))
    if self.onSet then
        self.onSet(self.progress)
    end
end

function Slider:setProgress(value)
    self.progress=math.max(0, math.min(1, value))
    self.onSet(self.progress)
end

return  Slider