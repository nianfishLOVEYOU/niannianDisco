-- /d:/lua/LOVEgame/niannianDisco/src/glove/widgets/window.lua
-- GitHub Copilot
-- A draggable window widget (like Windows), slidepanel-like API, supports child widgets,
-- clipping of children (using scissor), and closes when clicking outside.

local widget = require "src.glove.widgets.widget"
local item = require "src.item.item"
local love = require "love"

local Window = widget:extend()

function Window:init(title, children, close)
    self.type = "Window"
    -- 使用 item 的字段（item:init 已由构造链初始化）
    self.x = 100
    self.y = 100
    self.w = 200
    self.h = 120
    self.title = title or "Window"
    self.titleHeight = 26
    self.padding = 4
    self.bgColor = { 0.12, 0.12, 0.12, 0.95 }
    self.titleColor = { 0.08, 0.08, 0.08, 1 }
    self.titleTextColor = { 1, 1, 1, 1 }
    self.closeSize = 18
    self.draggable = true
    self._dragging = false

    self.close = close or function()
        self:destroy()
    end
    if not self.shadePanel then
        self.shadePanel = Glove.ShadePanel:new()
        self.shadePanel:setPos(self.x, self.y)
        self.shadePanel:setSize(self.w, self.h)
    end
    if children then
        for _, child in ipairs(children) do
            self:addChild(child)
        end
    end

end

function Window:addChild(child)
    self.shadePanel:addContent(child)
    widget.addChild(self, child)
end

function Window:removeChild(child)
    self.shadePanel:removeContent(child)
    widget.removeChild(self, child)
end


function Window:setPos(x, y)
    widget.setPos(self, x, y)
    if self.shadePanel then
        self.shadePanel:setPos(x, y)
    end
end

function Window:setSize(w, h)
    widget.setSize(self, w, h)
    if self.shadePanel then
        self.shadePanel:setSize(w, h)
    end
end

function Window:draw()
    -- window background
    love.graphics.setColor(self.bgColor)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, 6, 6)
    -- title bar
    love.graphics.setColor(self.titleColor)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.titleHeight, 6, 6)
    -- title text
    love.graphics.setColor(self.titleTextColor)
    local font = love.graphics.getFont()
    if font then
        love.graphics.print(self.title, self.x + 8, self.y + (self.titleHeight - font:getHeight()) / 2)
    else
        love.graphics.print(self.title, self.x + 8, self.y + 4)
    end
    -- close button
    local cs = self.closeSize
    local cx = self.x + self.w - cs - 6
    local cy = self.y + (self.titleHeight - cs) / 2
    love.graphics.setColor(0.9, 0.3, 0.3, 1)
    love.graphics.rectangle("fill", cx, cy, cs, cs, 4, 4)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.line(cx + 4, cy + 4, cx + cs - 4, cy + cs - 4)
    love.graphics.line(cx + cs - 4, cy + 4, cx + 4, cy + cs - 4)
    -- content scissor

    -- draw children of content (they have global positions via parent relationship)

    self.shadePanel:draw()
    --print("Window draw", self.x, self.y, self.w, self.h)
end



-- event forwarding only for points inside content area
function Window:onClick(x, y)
    if not self.visible then return end
    -- close button
    local cs = self.closeSize
    local bx = self.x + self.w - cs - 6
    local by = self.y + (self.titleHeight - cs) / 2
    if x >= bx and y >= by and x <= bx + cs and y <= by + cs then
        self:close()
        return
    end
end

function Window:onClickOver(x, y)
    if not self.visible then return end
end

function Window:onDrag(x, y, dx, dy)
    if not self.visible then return end
    if self.draggable then
        -- use item:setPos so child global positions refresh correctly
        self:setPos(self.x + dx, self.y + dy)
        return
    end
end

-- cleanup: remove registration
function Window:destroy()
    widget.destroy(self)
end

return Window
