local colors = require "src.glove.colors"
local love = require "love"
local widget = require "src.glove.widgets.widget"

local g = love.graphics
local tabPadding = 5

local Tabs = widget:extend()

local function getTabHeight(font)
    return font:getHeight() + tabPadding * 2
end

local function setvisiable(widget, visiable)
    widget.visiable = visiable
    -- if widget.children then
    --     for _, child in ipairs(widget.children) do
    --         setvisiable(child, visiable)
    --     end
    -- end
end

function Tabs:init(tabs, options)
    self.type = "Tabs"

    -- for index, tab in ipairs(tabs) do
    --     local widget = tab.widget
    --     widget.visiable = index == 1
    -- end

    self.color = options.color or colors.white
    self.backgroundColor = options.backgroundColor or colors.black
    self.lineColor = options.lineColor or colors.white
    self.font = myFont
    self.selectedTabIndex = options.selectedTabIndex or 1
    self.onChange = options.onChange
    self.tabs = tabs
    self.isline = true

    self.w = 0
    for index, tab in ipairs(self.tabs) do
        self.w = self.w + self.font:getWidth(tab.label) + tabPadding * 2
    end
    self.h = getTabHeight(self.font)
end

function Tabs:getHeight()
    return self.h
end

function Tabs:getWidth()
    return self.w or Glove.getAvailableWidth()
end

function Tabs:draw()
    local x = self.x or Glove.margin
    local y = self.y or Glove.margin

    local tabHeight = self.h

    for index, tab in ipairs(self.tabs) do
        local selected = index == self.selectedTabIndex
        local mode = "fill" -- selected and "fill" or "line"
        if selected then
            g.setColor(colors.gray)
        end

        local label = tab.label
        local tabWidth = self.font:getWidth(label) + tabPadding * 2

        -- Draw a rounded rectangle.
        g.setColor(selected and self.color or self.backgroundColor)
        g.rectangle(mode, x, y, tabWidth, tabHeight, tabPadding, tabPadding)

        -- Draw a non-rounded rectangle.
        g.setColor(selected and self.color or self.backgroundColor)
        g.rectangle("fill", x, y + tabHeight - tabPadding + 1, tabWidth, tabPadding)

        -- line
        if self.isline then
            g.setColor(self.lineColor)
            g.line(x, y + tabHeight, x + tabWidth, y + tabHeight)
            -- Draw a line across the bottom.
            g.setColor(self.color)
            g.line(x, y + tabHeight, x + tabWidth, y + tabHeight)
        end

        -- Draw the tab text.
        g.setColor(selected and self.backgroundColor or self.color)
        g.print(label, x + tabPadding, y + tabPadding)
        x = x + tabWidth
    end

    -- Draw vertical lines to close the bottom of the rounded rectangles
    -- that was erased by the non-rounded rectangles drawn above.
    x = self.x
    for index, tab in ipairs(self.tabs) do
        local selected = index == self.selectedTabIndex
        local label = tab.label
        local tabWidth = self.font:getWidth(label) + tabPadding * 2

        g.setColor(self.color)
        local y1 = y + tabHeight - 1
        local y2 = y1 - tabPadding + 2
        if not selected then
            g.line(x, y1, x, y2)
        end

        local x2 = x + tabWidth
        g.line(x2, y1, x2, y2)

        x = x + tabWidth
    end

    -- local selectedTab = self.tabs[self.selectedTabIndex]
    -- selectedTab.widget:draw(self.x, self.y + tabHeight + tabPadding)
end

function Tabs:setText(text)
    self.label = text
    self:setSize(0, 0)
end

function Tabs:getFontSize()
    local labelWidth = self.font:getWidth(self.label) + self.padding * 2
    local labelHeight = self.font:getHeight() + self.padding * 2
    return labelWidth, labelHeight
end

function Tabs:setSize(w, h)
    w = w - self.padding * 2
    h = h - self.padding * 2

    local labelWidth, labelHeight = self:getFontSize()
    self.w = labelWidth > w and labelWidth or w
    self.h = labelHeight > h and labelHeight or h
end

function Tabs:onClick(x, y, button)
    if self.active == false then
        return
    end

    local currentTab = self.tabs[self.selectedTabIndex]
    local clicked = self:isOver(x, y)
    if clicked then
        local index = self:getSelect(x, y)
        local newTab = self.tabs[index]
        if self.onChange then
            self.onChange(index)
        end

        if currentTab.widget  then
            currentTab.widget.visiable = false
        end
        if newTab.widget then
            newTab.widget.visiable = true
        end

        self.selectedTabIndex = index
        print("从：", currentTab.label, "到：", newTab.label)
    end

    return clicked
end

function Tabs:onClickOver(x, y, button)
    -- self.onChange()
end

function Tabs:getSelect(mouseX, mouseY)
    local x = self.x
    local y = self.y
    for index, tab in ipairs(self.tabs) do
        local tabWidth = myFont:getWidth(tab.label) + tabPadding * 2
        local endX = x + tabWidth
        local over = mouseX >= x and mouseX <= endX and mouseY >= y and mouseY <= y + self.h
        if over then
            return index
        end
        x = endX
    end
end
return Tabs

