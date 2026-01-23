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
function FloatUI:createFloatText(text, x, y)
    local duration = 1.5
    local vy = -30
    local color = { 1, 1, 1, 1 }
    local gtext = Glove.Text:new(text)
    gtext:setPos(x, y, 0)
    gtext.color = color

    table.insert(self.floatTexts, { text = gtext, duration = duration, vy = vy })
end

function FloatUI:createDialogBox(text, player)
    -- 创建第一个对话框（使用默认样式）
    local dialog1 = dialogueBox:new(
        text, -- 文字
        150, 100, -- 对话框位置
        200, 180 -- 尾巴指向位置
    )

    table.insert(self.dialogBoxs, dialog1)
end

-- 创建一个简单的弹窗（若 Glove.Window 可用则使用之）
-- opts: {w=200,h=120,duration=2,title=""}
function FloatUI:createPopup(text, x, y, opts)
    -- prefer Glove.widgets.Window if available
    if Glove and Glove.widgets and Glove.widgets.Window then
        local Window = Glove.widgets.Window
        local Button = Glove.widgets.Button or Glove.Button
        local Label = Glove.widgets.Label or Glove.widgets.Text or Glove.Text

        local win = Window:new(title)
        if win.setPos then win:setPos(x, y) end
        if win.setSize then win:setSize(w, h) end

        -- add text/label if class available
        if Label and Label.new then
            local lbl = Label:new(text)
            if lbl.setLocalPos then lbl:setLocalPos(8, 8) end
            if win.addChild then win:addChild(lbl, 8, 8) end
        end

        -- add confirm button
        if Button and Button.new then
            local btn = Button:new("OK")
            if btn.setLocalPos then btn:setLocalPos(w - 80, h - 36) end
            if btn.setOnClick then
                btn:setOnClick(function() if win.destroy then win:destroy() end end)
            else
                btn.onClick = function() if win.destroy then win:destroy() end end
            end
            if win.addChild then win:addChild(btn) end
        end

        self:addStack(win)
        if duration and duration > 0 then
            table.insert(self.timers, { t = 0, duration = duration, target = win, type = "window" })
        end
        return win
    elseif Glove and Glove.Window then
        -- legacy Glove.Window path
        local win = Glove.Window:new(title)
        win:setPos(x, y)
        win:setSize(w, h)
        -- draw simple text inside
        local label = nil
        if Glove.Text and Glove.Text.new then
            label = Glove.Text:new(text)
        elseif Glove.Label and Glove.Label.new then
            label = Glove.Label:new(text)
        end
        if label then
            if label.setLocalPos then label:setLocalPos(8, 8) end
            if win.addChild then win:addChild(label, 8, 8) end
        end
        -- add confirm button if available
        local BtnClass = Glove.Button or (Glove.widgets and Glove.widgets.Button)
        if BtnClass and BtnClass.new then
            local btn = BtnClass:new("OK")
            if btn.setLocalPos then btn:setLocalPos(w - 80, h - 36) end
            if btn.setOnClick then
                btn:setOnClick(function() if win.destroy then win:destroy() end end)
            else
                btn.onClick = function() if win.destroy then win:destroy() end end
            end
            if win.addChild then win:addChild(btn) end
        end

        self:addStack(win)
        local timer = { t = 0, duration = duration, target = win, type = "window" }
        table.insert(self.timers, timer)
        return win
    else
        -- fallback simple pop item
        local item = {
            type = "popup",
            x = x,
            y = y,
            w = w,
            h = h,
            text = text,
            t = 0,
            duration = duration,
            update = function(self, dt)
                self.t = self.t + dt
                -- small fade and float
                self.y = self.y - 10 * dt
            end,
            draw = function(self)
                love.graphics.setColor(0, 0, 0, 0.8)
                love.graphics.rectangle('fill', self.x, self.y, self.w, self.h, 6, 6)
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.print(self.text, self.x + 8, self.y + 8)
            end
        }
        table.insert(self.widgets, item)
        return item
    end
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
