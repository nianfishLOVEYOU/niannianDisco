-- /d:/lua/LOVEgame/niannianDisco/src/glove/widgets/window.lua
-- GitHub Copilot
-- A draggable window widget (like Windows), slidepanel-like API, supports child widgets,
-- clipping of children (using scissor), and closes when clicking outside.

local widget = require "src.glove.widgets.widget"
local love = require "love"

local Window = widget:extend()

function Window:init(opts)
    opts = opts or {}
    self.type = "Window"
    self.x = opts.x or 100
    self.y = opts.y or 100
    self.w = opts.w or 400
    self.h = opts.h or 300
    self.title = opts.title or "Window"
    self.titleHeight = opts.titleHeight or 26
    self.padding = opts.padding or 4
    self.bgColor = opts.bgColor or {0.12,0.12,0.12,0.95}
    self.titleColor = opts.titleColor or {0.08,0.08,0.08,1}
    self.titleTextColor = opts.titleTextColor or {1,1,1,1}
    self.closeSize = opts.closeSize or 18
    self.children = {} -- list of {widget, x, y}
    self.visible = opts.open or false
    self.draggable = true
    self.isDrag = false
    self._dragOffsetX = 0
    self._dragOffsetY = 0
    -- register in Glove via widget:init
    widget.init(self)
end

-- Add a child widget. child is expected to have draw/update/mouse* methods.
-- cx, cy are coordinates relative to content area's top-left.
function Window:addChild(child, cx, cy)
    cx = cx or 0; cy = cy or 0
    table.insert(self.children, {w=child, x=cx, y=cy})
    return child
end

function Window:removeChild(child)
    for i=#self.children,1,-1 do
        if self.children[i].w == child then
            table.remove(self.children, i)
            return true
        end
    end
    return false
end

function Window:setPosition(x,y) self.x, self.y = x, y end
function Window:setSize(w,h) self.w, self.h = w, h end
function Window:openWindow() self.visible = true end
function Window:close() self.visible = false end
function Window:isOpen() return self.visible end

-- internal: checks if a point is inside window rect
function Window:_inside(x,y)
    return x >= self.x and y >= self.y and x <= self.x + self.w and y <= self.y + self.h
end

-- called by global wrapper to close on outside click
function Window:update(dt)
    if not self.visible then return end
    for _,entry in ipairs(self.children) do
        local c = entry.w
        if c.update then
            c:update(dt)
        end
    end
end

function Window:draw()
    if not self.visible then return end
    -- window background
    love.graphics.setColor(self.bgColor)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, 6,6)
    -- title bar
    love.graphics.setColor(self.titleColor)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.titleHeight, 6,6)
    -- title text
    love.graphics.setColor(self.titleTextColor)
    local font = love.graphics.getFont()
    if font then
        love.graphics.print(self.title, self.x + 8, self.y + (self.titleHeight - font:getHeight())/2)
    else
        love.graphics.print(self.title, self.x + 8, self.y + 4)
    end
    -- close button
    local cs = self.closeSize
    local cx = self.x + self.w - cs - 6
    local cy = self.y + (self.titleHeight - cs)/2
    love.graphics.setColor(0.9,0.3,0.3,1)
    love.graphics.rectangle("fill", cx, cy, cs, cs, 4,4)
    -- content scissor
    local contentX = self.x + self.padding
    local contentY = self.y + self.titleHeight + self.padding
    local contentW = self.w - self.padding*2
    local contentH = self.h - self.titleHeight - self.padding*2
    -- save and set scissor
    local sx, sy, sw, sh = love.graphics.getScissor()
    love.graphics.setScissor(contentX, contentY, contentW, contentH)
    -- translate to content origin and draw children
    love.graphics.push()
    love.graphics.translate(contentX, contentY)
    for _,entry in ipairs(self.children) do
        local c = entry.w
        love.graphics.push()
        love.graphics.translate(entry.x, entry.y)
        if c.draw then c:draw() end
        love.graphics.pop()
    end
    love.graphics.pop()
    -- restore scissor
    love.graphics.setScissor(sx, sy, sw, sh)
end

-- helper: convert global coords to content-local coords
function Window:_toContentCoords(x,y)
    local contentX = self.x + self.padding
    local contentY = self.y + self.titleHeight + self.padding
    return x - contentX, y - contentY
end

-- event forwarding only for points inside content area
function Window:onClick(x, y)
    if not self.visible then return end
    -- close button
    local cs = self.closeSize
    local bx = self.x + self.w - cs - 6
    local by = self.y + (self.titleHeight - cs)/2
    if x >= bx and y >= by and x <= bx+cs and y <= by+cs then
        self:close()
        return
    end

    -- title drag start
    if self.draggable and x >= self.x and y >= self.y and x <= self.x + self.w and y <= self.y + self.titleHeight then
        self._dragging = true
        self._dragOffsetX = x - self.x
        self._dragOffsetY = y - self.y
        return
    end

    -- content area: forward to children (record pressed child)
    local contentX = self.x + self.padding
    local contentY = self.y + self.titleHeight + self.padding
    local contentW = self.w - self.padding*2
    local contentH = self.h - self.titleHeight - self.padding*2
    if x >= contentX and y >= contentY and x <= contentX + contentW and y <= contentY + contentH then
        local lx, ly = self:_toContentCoords(x, y)
        for i = #self.children, 1, -1 do
            local entry = self.children[i]
            local c = entry.w
            local cx_local = lx - entry.x
            local cy_local = ly - entry.y
            -- if child provides size, check bounds
            if c.getSize then
                local cw, ch = c:getSize()
                if cx_local >= 0 and cy_local >= 0 and cx_local <= cw and cy_local <= ch then
                    self._pressed_child = entry
                    if c.onClick then c:onClick(cx_local, cy_local) end
                    return
                end
            else
                -- no size info, forward and let child decide
                self._pressed_child = entry
                if c.onClick then c:onClick(cx_local, cy_local) end
                return
            end
        end
        return
    end
end

function Window:onClickOver(x, y)
    if not self.visible then return end
    -- stop dragging if was dragging
    if self._dragging then
        self._dragging = false
        return
    end
    -- forward release to pressed child
    if self._pressed_child then
        local entry = self._pressed_child
        local c = entry.w
        local lx, ly = self:_toContentCoords(x, y)
        local cx_local = lx - entry.x
        local cy_local = ly - entry.y
        if c.onClickOver then c:onClickOver(cx_local, cy_local) end
        self._pressed_child = nil
        return
    end
end

function Window:onDrag(x, y, dx, dy)
    if not self.visible then return end
    if self._dragging then
        self.x = self.x + dx
        self.y = self.y + dy
        return
    end
    -- forward drag to pressed child if any
    if self._pressed_child then
        local entry = self._pressed_child
        local c = entry.w
        local lx, ly = self:_toContentCoords(x, y)
        local cx_local = lx - entry.x
        local cy_local = ly - entry.y
        if c.onDrag then c:onDrag(cx_local, cy_local, dx, dy) end
        return
    end
end

function Window:onDragOver(x, y)
    if not self.visible then return end
    if self._dragging then
        self._dragging = false
        return
    end
    if self._pressed_child then
        local entry = self._pressed_child
        local c = entry.w
        local lx, ly = self:_toContentCoords(x, y)
        local cx_local = lx - entry.x
        local cy_local = ly - entry.y
        if c.onDragOver then c:onDragOver(cx_local, cy_local) end
        self._pressed_child = nil
        return
    end
end

function Window:onHold(x, y)
    if not self.visible then return end
    -- hover/hold: forward to children if inside
    local contentX = self.x + self.padding
    local contentY = self.y + self.titleHeight + self.padding
    local contentW = self.w - self.padding*2
    local contentH = self.h - self.titleHeight - self.padding*2
    if x >= contentX and y >= contentY and x <= contentX + contentW and y <= contentY + contentH then
        local lx, ly = self:_toContentCoords(x, y)
        for i = #self.children, 1, -1 do
            local entry = self.children[i]
            local c = entry.w
            local cx_local = lx - entry.x
            local cy_local = ly - entry.y
            if c.onHold then c:onHold(cx_local, cy_local) end
        end
    end
end

-- cleanup: remove registration
function Window:destroy()
    widget.destroy(self)
end
return Window