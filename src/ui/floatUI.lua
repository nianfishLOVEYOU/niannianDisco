local dialogueBox = require("src.ui.uiHelpSrc.dialogueBox")
local ui = require "src.ui.ui"
local FloatUI = ui:extend()

local function getTextLength(text)
    if utf8 and utf8.len then
        local len = utf8.len(text)
        if len then
            return len
        end
    end
    return #text
end

local function subText(text, startIndex, endIndex)
    if utf8 and utf8.offset then
        local startByte = utf8.offset(text, startIndex)
        if not startByte then
            return ""
        end

        local endByte = #text
        if endIndex and endIndex >= 0 then
            local nextByte = utf8.offset(text, endIndex + 1)
            if nextByte then
                endByte = nextByte - 1
            end
        end

        return string.sub(text, startByte, endByte)
    end

    return string.sub(text, startIndex, endIndex)
end

function FloatUI:init()
    floatUI= self
    self.timers = {}
    self.widgets = {
    } -- floating items (tables with update/draw)
    self.floatTexts = {}
    self.dialogBoxs = {}
    self.currentDialogState = nil
    self.z = 1000
end

-- 创建一个渐隐并向上漂移的文字
-- opts: {duration=1.5, vy= -30, color={1,1,1,1}, font=nil}
function FloatUI:addFloatText(text, x, y, opts)
    opts = opts or {}
    local duration = opts.duration or 1.5
    local vy = opts.vy or -20
    local color = opts.color or { 1, 1, 1, 1 }
    local gtext = Glove.Text:new(text)
    gtext:setPos(x, y, 0)
    gtext.color = color
    gtext.outline=true

    table.insert(self.floatTexts, {
        text = gtext,
        x = x,
        y = y,
        elapsed = 0,
        duration = duration,
        vy = vy,
        baseColor = { color[1], color[2], color[3], color[4] }
    })
end

function FloatUI:closeDialogeBox()
    self.currentDialogState = nil
    self.dialogBoxs = {}
end

function FloatUI:closeDialogueBox()
    self:closeDialogeBox()
end

function FloatUI:addDialogeBox(text, x, y, opts)
    opts = opts or {}
    x = x or 200
    y = y or 300

    -- 场景内同时只保留一个对话框
    self:closeDialogeBox()

    local fullText = text or ""
    local totalChars = getTextLength(fullText)
    local isInstant = opts.instant == true -- opts.instant: 为 true 时跳过打字机效果，直接显示全文
    local startText = isInstant and fullText or ""
    local tailX = opts.tailX or (x + 50)
    local tailY = opts.tailY or (y + 50)

    local dialog1 = dialogueBox:new(
        startText,
        x, y,
        tailX, tailY
    )

    self.dialogBoxs[1] = dialog1
    self.currentDialogState = {
        dialog = dialog1,
        fullText = fullText,
        shownChars = isInstant and totalChars or 0,
        totalChars = totalChars,
        typeSpeed = opts.typeSpeed or 30, -- opts.typeSpeed: 打字速度，单位约等于 每秒显示多少字符
        charProgress = 0,
        finished = isInstant or totalChars == 0,
        autoClose = opts.autoClose or 0, -- opts.autoClose: 全文显示完成后，多少秒自动关闭；0 表示不自动关闭
        autoCloseTimer = 0
    }
end

function FloatUI:addDialogueBox(text, x, y, opts)
    self:addDialogeBox(text, x, y, opts)
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

    -- update float texts: move up and fade out, then remove
    for i = #self.floatTexts, 1, -1 do
        local ft = self.floatTexts[i]
        ft.elapsed = ft.elapsed + dt
        local p = ft.elapsed / ft.duration
        if p > 1 then p = 1 end

        local ny = ft.y + ft.vy * p
        ft.text:setPos(ft.x, ny, 0)

        local c = ft.baseColor
        ft.text.color = { c[1], c[2], c[3], c[4] * (1 - p) }

        if ft.elapsed >= ft.duration then
            self.floatTexts[i].text:destroy()
            table.remove(self.floatTexts, i)

        end
    end

    local dialogState = self.currentDialogState
    if dialogState then
        if not dialogState.finished then
            dialogState.charProgress = dialogState.charProgress + dt * dialogState.typeSpeed
            local addCount = math.floor(dialogState.charProgress)

            if addCount > 0 then
                dialogState.charProgress = dialogState.charProgress - addCount
                dialogState.shownChars = math.min(dialogState.shownChars + addCount, dialogState.totalChars)
                dialogState.dialog.text = subText(dialogState.fullText, 1, dialogState.shownChars)

                if dialogState.shownChars >= dialogState.totalChars then
                    dialogState.finished = true
                end
            end
        elseif dialogState.autoClose > 0 then
            dialogState.autoCloseTimer = dialogState.autoCloseTimer + dt
            if dialogState.autoCloseTimer >= dialogState.autoClose then
                self:closeDialogeBox()
            end
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
    --print(#self.floatTexts)
end

return FloatUI
--浮动文字
