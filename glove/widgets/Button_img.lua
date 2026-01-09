local colors = require "glove/colors"
local love = require "love"
local widget = require "glove.widgets.widget"
local image = require "src.common.aUIImage"

local g = love.graphics
local padding = 10

local Button_img = widget:extend()


function Button_img:init(x, y, w, h, label, imagepath, func)
    local font = g.getFont()
    self.type = "Button"
    self.font = font
    self.label = label
    self.labelColor = colors.black
    self.clickFunc = func

    self.image = image:new(imagepath, 0, 0, 0, 0)
    self.w,self.h = self.image:getSize()
end

function Button_img:draw()
    local cornerRadius = padding

    --先显示图片
    love.graphics.setColor(self.color)
    if self:isOver(love.mouse.getPosition()) and not love.mouse.isDown(1) then
        local offsetx = padding / 2
        local offsety = padding / 2
        self.image:setPos(self.x - offsetx,self.y - offsety)
        self.image:setSize( (self.width + padding),(self.height + padding))
        self.image:draw()
    else
        self.image:setPos(self.x,self.y)
        self.image:setScale(1,1)
        self.image:draw()
    end

    g.setColor(self.labelColor)
    g.setFont(self.font)

    --减去字体宽度
    local fw, fh = self:getFontSize()

    g.print(self.label, self.x + self.w / 2 - fw / 2 + padding,
        self.y + self.h / 2 - fh / 2 + padding)
end

function Button_img:setText(text)
    self.label = text
    Button_img:setSize(0, 0)
end

function Button_img:getFontSize()
    local labelWidth = self.font:getWidth(self.label) + padding * 2
    local labelHeight = self.font:getHeight() + padding * 2
    return labelWidth, labelHeight
end

function Button_img:setSize(w, h)
    self.image:setSize(w,h)
    self.w = w
    self.h = h
end

function Button_img:onClick(x, y, button)
    self.clickFunc()
end

function Button_img:destroy()
    if self.__destroyed then return end
    self.__destroyed = true
    Glove.clickables[self] = nil
end

return Button_img

