-- slider

local image = require "src.common.aUIImage"
local widget = require "src.glove.widgets.widget"

local g = love.graphics
local SlidePanel = widget:extend()
local padding = 3

function SlidePanel:init( progress,onSet)
    self.type = "Slider"
    self.progress = progress or 0
    self.color =  { 0.2, 0.6, 1 }
    self.backColor = { 0.5, 0.5, 0.5 }
    self.onSet=onSet

    self.w = 60 
    self.h = 100

    self.spacing = 10

    self.offsetX=0
    self.offsetY=0

    self.lockOffsetX =false
    self.lockOffsetY =false
    
end

function SlidePanel:draw()

    self.progress=math.max(0, math.min(1, self.progress))

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

    for i, child in ipairs(children) do
        end

    if self.align == "center" then
        child:setLocalPos((self.w - cw) / 2, y)
    elseif self.align == "right" then
        child:setLocalPos(self.w - cw, y)
    else -- assume "left"
        child:setLocalPos(0, y)
    end
end

function SlidePanel:setSize(w, h)
    self.w = w
    self.h = h
end


function SlidePanel:onDragOver(x, y)
    self:dragProgress(x)
end

--被拖拽
function SlidePanel:onDrag(x, y, dx, dy)
    local minx,miny,maxx,maxy=self.x,self.y,self.x+self.w,self.y+self.h
    local childx,childy=self.children[1].getPos()
    local childw,childh=self.children[1].getSize()
    
    if not self.lockOffsetX then
        self.offsetX=self.offsetX+dx
    end
    if not self.lockOffsetY then
        
        self.offsetY=self.offsetY+dy
    end
end

function SlidePanel:onClick(x, y, button)
    Glove.setFocus(self)
    self:dragProgress(x)
end

function SlidePanel:justSetProgress(x)
    local ax = self.x
    local width = self.w
    self.progress = (x - ax) / width
    self.progress = math.max(0, math.min(1, self.progress))
end

function SlidePanel:dragProgress(x)
    local ax = self.x
    local width = self.w
    self.progress = (x - ax) / width
    self.progress = math.max(0, math.min(1, self.progress))
    if self.onSet then
        self.onSet(self.progress)
    end
end

function SlidePanel:setProgress(value)
    self.progress=math.max(0, math.min(1, value))
    self.onSet(self.progress)
end

return  SlidePanel