-- slider拖拽条
local image = require "src.common.aUIImage"
local widget = require "src.glove.widgets.widget"

local g = love.graphics
local Slider = widget:extend()
local padding = 3

function Slider:init(progress, onSet)
    self.type = "Slider"
    self.progress = progress or 0
    self.color = {0.2, 0.6, 1}
    self.backColor = {0.5, 0.5, 0.5}
    self.onSet = onSet
    self.isDrawIcon = false
    self.backGroundimage = nil -- image 的类
    self.iconImage = nil

    -- 特殊的属性
    self.drawProgressColor = true
    self.slideNoSet = true
    self.discrete = 0 -- 离散滑块（Discrete Slider）

    self.w = 60
    self.h = 10

end

function Slider:draw()
    -- 如果有自动尺寸则用自动尺寸，否则用
    local width = self.w
    local height = self.h

    -- 去头去尾，离散
    local progress = self.progress
    if self.discrete > 0 then
        progress = self:getDiscrete(progress) / self.discrete
    end
    self.progress = math.max(0, math.min(1, progress))

    if self.backGroundimage then
        self.backGroundimage:setPos(self.x, self.y)
        self.backGroundimage:setSize(self.w, self.h)
        self.backGroundimage:draw()
    else
        g.setColor(self.backColor)
        g.rectangle("fill", self.x, self.y, self.w, self.h)
    end

    -- 尺标
    if self.discrete > 0 then
        for i = 0, self.discrete do
            local w = 10
            local h = 10
            local x = self.x + (self.w * i / self.discrete)
            local y = self.y - h
            g.setColor(self.backColor)
            g.rectangle("fill", x - w / 2, y, w, h)
            g.print(i, x - w / 2, y - h - 5)

        end
    end

    -- 进度条
    if self.drawProgressColor then
        g.setColor(self.color)
        g.rectangle("fill", self.x, self.y, self.w * progress, self.h)

    end

    -- 画当前进度的小图标
    if self.isDrawIcon then
        if self.iconImage then
            self.iconImage:setPos(self.x + self.w * progress, self.y + self.h / 2)
            self.iconImage:draw()
        else
            local iconX = self.x + self.w * progress
            local iconY = self.y + self.h / 2
            local iconRadius = self.h * 0.6
            g.setColor(1, 0, 0)
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
    self:setProgress(self.progress)
end

-- 被拖拽
function Slider:onDrag(x, y, dx, dy)
    self:dragProgress(x)
    if not self.slideNoSet then
        self:setProgress(self.progress)

    end
end

function Slider:onClick(x, y, button)
    Glove.setFocus(self) 
    if not self.slideNoSet then
        self:dragProgress(x)   
        self:setProgress(self.progress)

    end
end

function Slider:getDiscrete(progress)
    return math.floor(progress * self.discrete + 0.5)
end

-- 输出值
function Slider:setProgress(value)
    if self.onSet then
        if self.discrete > 0 then
            value = self:getDiscrete(value)
        end
        self.onSet(value)
    end
end

function Slider:dragProgress(x)
    local ax = self.x
    local width = self.w
    self.progress = (x - ax) / width
    self.progress = math.max(0, math.min(1, self.progress))

end

function Slider:setProgress(value)
    self.progress = math.max(0, math.min(1, value))
    self.onSet(self.progress)
end

return Slider
