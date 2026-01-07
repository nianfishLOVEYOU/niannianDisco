-- slider
local colors = require "glove/colors"
local love = require "love"

local g = love.graphics
local padding = 3

local mt = {
    __index = {

        isDragging = false,
        draw = function(self, parentX, parentY)
            local cornerRadius = padding
            local x = parentX + self.x
            local y = parentY + self.y
            self.actualX = x
            self.actualY = y
            -- 如果有自动尺寸则用自动尺寸，否则用
            local width = self.width
            local height = self.height

            -- 进度条
            if self:isOver(love.mouse.getPosition()) then
                g.setColor(self.backColor )
                g.rectangle("fill", x, y, width, height)

                g.setColor(self.frontColor )
                g.rectangle("fill", x, y, width * self.progress, height)
            else
                g.setColor(self.backColor)
                g.rectangle("fill", x, y, width, height)

                g.setColor(self.frontColor)
                g.rectangle("fill", x, y, width * self.progress, height)
            end

        end,

        mousereleased = function(self,x, y)
            self.isDragging = false
        end,

        mousemoved = function(self,x, y, dx, dy)
            if self.isDragging then
                self:dragProgress(x)
            end
        end,

        dragProgress = function(self,x)
            local ax = self.actualX
            local width = self.width
            self.progress = (x - ax) / width
            self.progress = math.max(0, math.min(1, self.progress))
            self.onSet(self.progress)
        end,

        getHeight = function(self)
          local labelHeight = self.height
          return labelHeight-- + padding * 2
        end,
    
        getWidth = function(self)
          local labelWidth = self.width
          return labelWidth-- + padding * 2
        end,
    

        handleClick = function(self, clickX, clickY)
            local clicked = self:isOver(clickX, clickY) ---------测试是不是两个按钮按其中一个会触发两次
            if clicked then
                Glove.setFocus(self)
            end
            -- 进度条拖动
            if clicked then
                self.isDragging = true
                self:dragProgress(clickX)
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
        end
    }
}


local function Slider(progress, options)
    options = options or {}
    assert(type(options) == "table", "slider options must be a table.")

    local font = options.font or g.getFont()
    local instance = options
    instance.progress = progress
    instance.kind = "Slider"
    instance.frontColor = instance.frontColor or {0.2, 0.6, 1}
    instance.backColor = instance.backColor or {0.5, 0.5, 0.5}
    instance.visible = true
    instance.width = instance.width or 60
    instance.height = instance.height or 10
    setmetatable(instance, mt)

    table.insert(Glove.clickables, instance)
    table.insert(Glove.mousemoveables, instance)
    table.insert(Glove.mousereleaseables, instance)
    
    return instance
end

return Slider
