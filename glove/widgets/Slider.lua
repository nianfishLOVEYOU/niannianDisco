-- slider

local image = require "src.common.aUIImage"
local widget = require "glove.widgets.widget"

local g = love.graphics
local Slider = widget:extend()
local padding = 3

function Slider:init(x, y, w, h, progress)
    self.type = "Slider"
    self.progress = progress or 0
    self.color =  { 0.2, 0.6, 1 }
    self.backColor = { 0.5, 0.5, 0.5 }

    self.w = w==0 and 60 or w
    self.h = h==0 and 10 or h

end

function Slider:draw()
    -- 如果有自动尺寸则用自动尺寸，否则用
    local width = self.w
    local height = self.h

    -- 进度条
    if self:isOver(love.mouse.getPosition()) then
        g.setColor(self.backColor)
        g.rectangle("fill", self.x, self.y, self.w, self.h)

        g.setColor(self.color)
        g.rectangle("fill", self.x, self.y, self.w * self.progress, self.h)
    else
        g.setColor(self.backColor)
        g.rectangle("fill", self.x, self.y, self.w, self.h)

        g.setColor(self.color)
        g.rectangle("fill", self.x, self.y, self.w * self.progress, self.h)
    end
end

function Slider:setSize(w, h)
    self.image:setSize(w, h)
    self.w = w
    self.h = h
end

--被拖拽
function Slider:onDrag(x, y, dx, dy)
    self:dragProgress(x)
end

function Slider:onClick(x, y, button)
    Glove.setFocus(self)
    self:dragProgress(x)
end

function Slider:dragProgress(x)
    local ax = self.actualX
    local width = self.width
    self.progress = (x - ax) / width
    self.progress = math.max(0, math.min(1, self.progress))
    self.onSet(self.progress)
end
