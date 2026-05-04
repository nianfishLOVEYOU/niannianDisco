-- 单选按钮
local colors = require "src.glove.colors"
local love = require "love"
local widget = require "src.glove.widgets.widget"

local g = love.graphics

local RadioButtons = widget:extend()

local size = 24
local circleRadius = size / 2

--[[
This widget allows the user to select one radiobutton from a set.

The selected value is tied to value of a given key in a given table.

The parameters are:

- choices described by an array-like table containing
  tables with `label` and `value` keys
- table that holds its state
- key within the table that holds its state
- table of options

The supported options are:

- `color`: of the radiobuttons and their labels; defaults to white
- `font`: used for the labels
- `onChange`: optional function to be called when a choice is selected
- `vertical`: boolean indicating whether the radiobuttons
  should be arranged vertically; defaults to false
--]]
function RadioButtons:init(choices, onChange)
    assert(type(choices) == "table", "RadioButtons choices must be a table.")

    local font = g.getFont()

    self.type = "RadioButtons"
    self.choices = choices
    self.font = font
    self.table = {}
    self.key = "key"
    self.visible = true
    self.onChange = onChange
    self.vertical = true
    local fontHeight = font:getHeight()
    local height = 0
    local width = 0

    local spacing = circleRadius
    if self.vertical then
        height = #choices * (size + spacing) - spacing
        for _, choice in ipairs(choices) do
            local w = size + spacing + font:getWidth(choice.label)
            if w > width then
                width = w
            end
        end
    else
        local height = fontHeight
        local width = 0
        for _, choice in ipairs(choices) do
            width = width + size + spacing + font:getWidth(choice.label) + spacing * 2
        end
        width = width - spacing * 2
    end

    self:setSize(width, height)

end

function RadioButtons:draw()
    g.setColor(self.color)
    local height = self.font:getHeight()
    local dy = (size - height) / 2

    local spacing = circleRadius
    local selectedValue = self.table[self.key]

    -- print("RadioButtons draw:", #self.choices,dy)
    if self.vertical then
        local circleCenterX = self.x + circleRadius
        local y = self.y
        for _, choice in ipairs(self.choices) do
            local circleCenterY = y + circleRadius
            local labelWidth = self.font:getWidth(choice.label)
            local choiceWidth = size + spacing + labelWidth
            local over = self:isOver(self.x, y, choiceWidth, love.mouse.getPosition())
            g.setColor(self.color)
            g.circle("line", circleCenterX, circleCenterY, circleRadius)

            g.setColor(self.color)
            if choice.value == selectedValue then
                g.circle("fill", circleCenterX, circleCenterY, circleRadius - 2)
            end
            g.print(choice.label, self.x + size + spacing, y + dy)
            y = y + size + spacing
        end
    else -- horizontal
        local x = self.x
        local circleCenterY = self.y + circleRadius
        for _, choice in ipairs(self.choices) do
            local circleCenterX = x + circleRadius
            local labelWidth = self.font:getWidth(choice.label)
            local choiceWidth = size + spacing + labelWidth
            local over = self:isOver(x, self.y, choiceWidth, love.mouse.getPosition())
            g.setColor(self.color)
            g.circle("line", circleCenterX, circleCenterY, circleRadius)

            g.setColor(self.color)
            if choice.value == selectedValue then
                g.circle("fill", circleCenterX, circleCenterY, circleRadius - 2)
            end
            x = x + size + spacing
            g.print(choice.label, x, self.y + dy)
            x = x + self.font:getWidth(choice.label) + spacing * 2
        end
    end
end

local function isOver(x, y, width, mouseX, mouseY)
    if not x or not y then
        return false
    end
    return x <= mouseX and mouseX <= x + width and y <= mouseY and mouseY <= y + size
end

function RadioButtons:onClick(mouseX, mouseY, button)
    local x = self.x
    local y = self.y
    if not x or not y then
        return
    end

    local font = self.font
    local spacing = circleRadius

    if self.vertical then
        for _, choice in ipairs(self.choices) do
            local labelWidth = font:getWidth(choice.label)
            local choiceWidth = size + spacing + labelWidth
            if isOver(x, y, choiceWidth, mouseX, mouseY) then
                Glove.setFocus(self)
                local value = choice.value
                local t = self.table
                local key = self.key
                t[key] = value
                if self.onChange then
                    self.onChange(value)
                end
                return true -- captured click
            end
            y = y + size + spacing
        end
    else -- horizontal
        for _, choice in ipairs(self.choices) do
            local labelWidth = font:getWidth(choice.label)
            local choiceWidth = size + spacing + labelWidth
            if isOver(x, y, choiceWidth, mouseX, mouseY) then
                Glove.setFocus(self)
                local value = choice.value
                local t = self.table
                local key = self.key
                t[key] = value
                if self.onChange then
                    self.onChange(value)
                end
                return true -- captured click
            end
            x = x + size + spacing
            x = x + labelWidth + spacing * 2
        end
    end

    return false -- did not capture click
end

return RadioButtons
