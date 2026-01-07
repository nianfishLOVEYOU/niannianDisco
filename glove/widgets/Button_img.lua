local colors = require "glove/colors"
local love = require "love"

local g = love.graphics
local padding = 10
local mt = {
    __index = {
        draw = function(self, parentX, parentY)
            local x = parentX + self.x
            local y = parentY + self.y
            local rotation = 0
            self.actualX = x
            self.actualY = y
            -- 如果有自动尺寸则用自动尺寸，否则用

            love.graphics.setColor(1, 1, 1)
            if self:isOver(love.mouse.getPosition()) and not love.mouse.isDown(1) then
                local offsetx = padding / 2
                local offsety = padding / 2
                g.draw(self.image, x - offsetx, y - offsety, rotation, (self.width + padding) / self.image:getWidth(),
                    (self.height + padding) / self.image:getHeight())
            else
                g.draw(self.image, x, y, rotation, self.width / self.image:getWidth(),
                    self.height / self.image:getHeight())
            end

            -- 字
            g.setColor(self.labelColor)
            g.setFont(self.font)
            g.print(self.label, x + self.width / 2, y + self.height / 2)
        end,

        getHeight = function(self)
            return self.width
        end,

        getWidth = function(self)
            return self.height
        end,

        handleClick = function(self, clickX, clickY)
            local clicked = self:isOver(clickX, clickY)
            if clicked then
                --print("by clicked -----------------")
                Glove.setFocus(self)
                if self.onClick then
                    self.onClick()
                end
            end
            return clicked
        end,

        isOver = function(self, mouseX, mouseY)
            local x = self.actualX
            local y = self.actualY
            if not x or not y then
                return false
            end

            local width = self:getWidth()
            local height = self:getHeight()
            return x <= mouseX and mouseX <= x + width and y <= mouseY and mouseY <= y + height
        end,

        destroy = function(self)
            if self.__destroyed then return end
            self.__destroyed = true
            if self.onDestroy then
                self.onDestroy()
            end
        end,
    }
}

--[[
This widget is a clickable button.

The parameters are:

- text to display on the button
- table of options

The supported options are:

- `buttonColor`: background color of the button; defaults to white
- `font`: font used for the button label
- `labelColor`: color of the label; defaults to black
- `onClick`: function called when the button is clicked
--]]
local function Button_img(label, imagepath, options)
    options = options or {}
    assert(type(options) == "table", "Button options must be a table.")

    local font = options.font or g.getFont()
    local instance = options
    instance.kind = "Button_img"
    instance.font = font
    instance.label = label
    instance.image = resourceManager.loadImage(imagepath)
    instance.visible = true
    instance.labelColor = instance.labelColor or colors.black
    instance.buttonColor = instance.buttonColor or colors.white
    instance.x = 0
    instance.y = 0

    local scale = options.scale or 1
    --如果没有填尺寸就默认
    local imagew, imageh = instance.image:getDimensions()
    if not options.width or not options.height then
        instance.width = scale * imagew
        instance.height = scale * imageh
    end

    setmetatable(instance, mt)

    Glove.clickables[instance] = instance

    instance.onDestroy = function()
        Glove.clickables[instance] = nil
    end

    return instance
end

return Button_img
