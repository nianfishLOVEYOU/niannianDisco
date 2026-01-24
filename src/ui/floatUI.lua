local dialogueBox = require("src.ui.uiHelpSrc.dialogueBox")
local ui = require "src.ui.ui"
local FloatUI = ui:extend()

function FloatUI:init()
    self.timers = {}
    self.widgets = {
    } -- floating items (tables with update/draw)
    self.floatTexts = {}
    self.dialogBoxs = {}
    self.z = 1000
end

-- 创建一个渐隐并向上漂移的文字
-- opts: {duration=1.5, vy= -30, color={1,1,1,1}, font=nil}
function FloatUI:addFloatText(text, x, y)
    local duration = 1.5
    local vy = -30
    local color = { 1, 1, 1, 1 }
    local gtext = Glove.Text:new(text)
    gtext:setPos(x, y, 0)
    gtext.color = color

    table.insert(self.floatTexts, { text = gtext, duration = duration, vy = vy })
end

function FloatUI:addDialogeBox(text, player)
    -- 创建第一个对话框（使用默认样式）
    local dialog1 = dialogueBox:new(
        text,     -- 文字
        150, 100, -- 对话框位置
        200, 180  -- 尾巴指向位置
    )

    table.insert(self.dialogBoxs, dialog1)
end

-- 创建一个简单的弹窗（若 Glove.Window 可用则使用之）
-- opts: {w=200,h=120,duration=2,title=""}
function FloatUI:addWindow(text, x, y)
    -- prefer Glove.widgets.Window if available


    local Window = Glove.Window:new(text, function(window)
        --关闭window
    end)
    local textLable = Glove.Label:new(text)
    Window:addChild(textLable)
    textLable:setLocalPos(10, 10)
    local button = Glove.Button:new("确认", function()
        --关闭window
    end)
    Window:addChild(button)
    button:setLocalPos(10, 40)

    Window:layout() --还没写layout

    table.insert(self.widgets, Window)
end

function FloatUI:update(dt)
    -- update floating items
    for i = #self.widgets, 1, -1 do
        local it = self.widgets[i]
        if it.update then it:update(dt) end
        if it.t and it.duration and it.t >= it.duration then
            table.remove(self.widgets, i)
        end
    end

    -- timers for stacks like Window
    for i = #self.timers, 1, -1 do
        local tm = self.timers[i]
        tm.t = tm.t + dt
        if tm.t >= tm.duration then
            if tm.type == "window" and tm.target and tm.target.destroy then
                tm.target:destroy()
            end
            table.remove(self.timers, i)
        end
    end
end

function FloatUI:draw()
    -- draw underlying stacks first
    self:drawStacks()
    -- draw floating items on top
    for _, it in ipairs(self.widgets) do
        if it.draw then it:draw() end
    end

    for i, d in ipairs(self.dialogBoxs) do
        d:draw()
    end

    for i, t in ipairs(self.floatTexts) do
        t.text:draw()
    end
end

return FloatUI
--浮动文字
