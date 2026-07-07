local ui = require "src.ui.ui"
local psdData = require "src.common.artal.psdData"
local NianocUI = ui:extend()
nianAI = require "src.common.nianAI.nianAI"

function NianocUI:init()
    nianocUI = self
    nianAI:init()
    self:refresh()
    self.ani = animator
    self.stateType = ""
    self.state = {}
    self.states = self:_createStates()
    self.isClickAniOver = true
    self.clickNianZoom = 5 -- 点击缩放比例

    -- self.nianImage = love.graphics.newImage("res/image/nianPlayer.png")
    -- 自己的位置跟着父亲走
    self:setLocalPos(love.graphics.getWidth() - 230, love.graphics.getHeight() - 420)
    -- 创建动画轴

    self:_newNian()
end

function NianocUI:_newNian()
    self.psdData = psdData:new("res/image/nian/nian.psd")
    -- self.psdData:setSize(100, 100)
    self:addChild(self.psdData)
    self.psdData:setLocalPos(0, 0)
    self:changeState("idle")
    -- 添加播放按钮
end

function NianocUI:changeState(state)
    if self.state ~= state then
        if self.states[self.state] and self.states[self.state].leave then
            self.states[self.state].leave(self)
        end
        self.state = state
        if self.states[self.state] and self.states[self.state].start then
            self.states[self.state].start(self)
        end
    end
end

local wait = 0
local random = 0

function NianocUI:_createStates()
    local states = {}
    states["idle"] = {}
    states["happy"] = {}
    states["speak"] = {}
    states["love"] = {}
    states["music"] = {}
    states["click"] = {}

    -- 开始写状态，一个状态有三个方法，进入，更新，离开

    states["idle"] = {
        start = function(self)

            -- 图层开关
            self:_defaultPsd()
            self:_eyeAction("right")
            self:_mouseAction("happy")

            -- 动画
            self:_defaultAni()

        end,
        update = function(self, dt)
            wait = wait + dt
            if wait > 3 then
                self:_eyeAction("blink")
                wait = 0
            end

        end,
        leave = function(self)
            --self.ani:clearKeyframes("psdy")
        end
    }

    states["happy"] = {
        start = function(self)

        end,
        update = function(self, dt)

        end,
        leave = function(self)

        end
    }

    states["speak"] = {
        start = function(self)

        end,
        update = function(self, dt)

        end,
        leave = function(self)

        end
    }

    states["music"] = {
        start = function(self)
            -- 图层开关
            self:_defaultPsd()
            self.psdData:getLayer("hand_Left").visiable = true
            self.psdData:getLayer("hand_Left2").visiable = false
            self.psdData:getLayer("mic").visiable = true
            self.psdData:getLayer("love").visiable = true
            self.psdData:getLayer("love").x = -55

            self:_eyeAction("left")
            self:_mouseAction("open")
            -- 动画
            self:_musicAni()
            self.ani.globalSpeed = 2
        end,
        update = function(self, dt)

            wait = wait + dt
            if wait > 3 then
                self:_eyeAction("blink")
                wait = 0
            end
        end,
        leave = function(self)
            self.ani.globalSpeed = 1
        end
    }

    states["click"] = {
        start = function(self)

        end,
        update = function(self, dt)

        end,
        leave = function(self)

        end
    }

    states["clickDown"] = {
        start = function(self)

        end,
        update = function(self, dt)

        end,
        leave = function(self)

        end
    }

    states["clickUp"] = {
        start = function(self)

        end,
        update = function(self, dt)

        end,
        leave = function(self)

        end
    }

    states["Leave"] = {
        start = function(self)
            -- 图层开关
            self:_defaultPsd()
            self:_eyeAction("right")
            self:_mouseAction("happy")

            -- 动画
            self:_defaultAni()
        end,
        update = function(self, dt)

        end,
        leave = function(self)

        end
    }
    return states
end

function NianocUI:_bodyAction(action)
    if action == "idle" then

    elseif action == "leftHand" then

    elseif action == "click" then

    end

end

local eye = ""
-- 眼睛动作
function NianocUI:_eyeAction(action)
    self.psdData.imgs.eye_OpenRight.visiable = false
    self.psdData.imgs.eye_OpenLeft.visiable = false
    self.psdData.imgs.eyeClose.visiable = false

    if action == "left" then
        self.psdData.imgs.eye_OpenLeft.visiable = true
        eye = "left"
    elseif action == "right" then
        self.psdData.imgs.eye_OpenRight.visiable = true
        eye = "right"
    elseif action == "close" then
        self.psdData.imgs.eyeClose.visiable = true
    elseif action == "blink" then
        self.psdData.imgs.eyeClose.visiable = true
        if eye == "left" then
            self.psdData.imgs.eye_OpenLeft.visiable = false
        elseif eye == "right" then
            self.psdData.imgs.eye_OpenRight.visiable = false
        end
        timer:after(0.2, function()
            if eye == "left" then
                self.psdData.imgs.eye_OpenLeft.visiable = true
            elseif eye == "right" then
                self.psdData.imgs.eye_OpenRight.visiable = true
            end
            self.psdData.imgs.eyeClose.visiable = false
        end)
    end
end

-- 嘴巴动作
function NianocUI:_mouseAction(action)
    self.psdData.imgs.mouseClose.visiable = false
    self.psdData.imgs.mouthOpen.visiable = false
    self.psdData.imgs.mouseHappy.visiable = false
    if action == "happy" then
        self.psdData.imgs.mouseHappy.visiable = true
    elseif action == "open" then
        self.psdData.imgs.mouthOpen.visiable = true
    elseif action == "close" then
        self.psdData.imgs.mouseClose.visiable = true
    end
end

function NianocUI:_clearAni()
    self.ani:clearAllKeyframes()
end

function NianocUI:_defaultAni()

    self:_clearAni()
    -- defaultEnable 默认启用 loop 循环 pinpon 来回
    self.ani:addTrack("psdy", self.psdData, "localY", true, true, false, "easeInOut")
    self.ani:addKeyframe("psdy", 0, self.psdData.localY - 4)
    self.ani:addKeyframe("psdy", 2, self.psdData.localY + 4)
    self.ani:addKeyframe("psdy", 4, self.psdData.localY - 4)

    self.ani:addTrack("clothes", self.psdData, "imgs.clothes.y", true, true, true, "easeInOut")
    self.ani:addKeyframe("clothes", 0, self.psdData.imgs.clothes.y - 1)
    self.ani:addKeyframe("clothes", 2, self.psdData.imgs.clothes.y + 1)
    self.ani:addKeyframe("clothes", 4, self.psdData.imgs.clothes.y - 1)

    self.ani:addTrack("hear_Down", self.psdData, "imgs.hear_Down.y", true, true, true, "easeInOut")
    self.ani:addKeyframe("hear_Down", 0, self.psdData.imgs.hear_Down.y - 1)
    self.ani:addKeyframe("hear_Down", 2, self.psdData.imgs.hear_Down.y + 1)
    self.ani:addKeyframe("hear_Down", 4, self.psdData.imgs.hear_Down.y - 1)

    self.ani:addTrack("head_fold", self.psdData, "imgsTree.head_fold.y", true, true, true, "easeInOut")
    self.ani:addKeyframe("head_fold", 0, self.psdData.imgsTree.head_fold.y + 1)
    self.ani:addKeyframe("head_fold", 2, self.psdData.imgsTree.head_fold.y - 1)
    self.ani:addKeyframe("head_fold", 4, self.psdData.imgsTree.head_fold.y + 1)

    self.ani:addTrack("mic", self.psdData, "imgs.mic.y", true, true, true, "easeInOut")
    self.ani:addKeyframe("mic", 0, self.psdData.imgs.mic.y + 3)
    self.ani:addKeyframe("mic", 2, self.psdData.imgs.mic.y - 3)
    self.ani:addKeyframe("mic", 4, self.psdData.imgs.mic.y + 3)

    self.ani:addTrack("love", self.psdData, "imgs.love.y", true, true, true, "easeInOut")
    self.ani:addKeyframe("love", 0, self.psdData.imgs.love.y - 4)
    self.ani:addKeyframe("love", 2, self.psdData.imgs.love.x + 4)
    self.ani:addKeyframe("love", 4, self.psdData.imgs.love.y - 4)

    self.ani:addTrack("hand_Left", self.psdData, "imgs.hand_Left.y", true, true, true, "easeInOut")
    self.ani:addKeyframe("hand_Left", 0, self.psdData.imgs.hand_Left.y + 1)
    self.ani:addKeyframe("hand_Left", 2, self.psdData.imgs.hand_Left.y - 1)
    self.ani:addKeyframe("hand_Left", 4, self.psdData.imgs.hand_Left.y + 1)

end

function NianocUI:_musicAni()
    self:_clearAni()

    -- defaultEnable 默认启用 loop 循环 pinpon 来回
    self.ani:addTrack("psdy", self.psdData, "localY", true, true, false, "easeInOut")
    self.ani:addKeyframe("psdy", 0, self.psdData.localY + 4)
    self.ani:addKeyframe("psdy", 1, self.psdData.localY - 4)
    self.ani:addKeyframe("psdy", 2, self.psdData.localY + 4)
    self.ani:addTrack("psdx", self.psdData, "localX", true, true, false, "easeInOut")
    self.ani:addKeyframe("psdx", 0, self.psdData.localX - 5)
    self.ani:addKeyframe("psdx", 2, self.psdData.localX + 5)
    self.ani:addKeyframe("psdx", 4, self.psdData.localX - 5)

    self.ani:addTrack("clothes", self.psdData, "imgs.clothes.y", true, true, true, "easeInOut")
    self.ani:addKeyframe("clothes", 0, self.psdData.imgs.clothes.y - 1)
    self.ani:addKeyframe("clothes", 1, self.psdData.imgs.clothes.y + 1)
    self.ani:addKeyframe("clothes", 2, self.psdData.imgs.clothes.y - 1)

    self.ani:addTrack("hear_Down", self.psdData, "imgs.hear_Down.y", true, true, true, "easeInOut")
    self.ani:addKeyframe("hear_Down", 0, self.psdData.imgs.hear_Down.y - 2)
    self.ani:addKeyframe("hear_Down", 1, self.psdData.imgs.hear_Down.y + 0)
    self.ani:addKeyframe("hear_Down", 2, self.psdData.imgs.hear_Down.y - 2)

    self.ani:addTrack("head_fold", self.psdData, "imgsTree.head_fold.y", true, true, true, "easeInOut")
    self.ani:addKeyframe("head_fold", 0, self.psdData.imgsTree.head_fold.y + 1)
    self.ani:addKeyframe("head_fold", 1, self.psdData.imgsTree.head_fold.y - 1)
    self.ani:addKeyframe("head_fold", 2, self.psdData.imgsTree.head_fold.y + 1)

    self.ani:addTrack("mic", self.psdData, "imgs.mic.y", true, true, true, "easeInOut")
    self.ani:addKeyframe("mic", 0, self.psdData.imgs.mic.y + 3)
    self.ani:addKeyframe("mic", 1, self.psdData.imgs.mic.y - 3)
    self.ani:addKeyframe("mic", 2, self.psdData.imgs.mic.y + 3)

    self.ani:addTrack("love", self.psdData, "imgs.love.y", true, true, true, "easeInOut")
    self.ani:addKeyframe("love", 0, self.psdData.imgs.love.y - 4)
    self.ani:addKeyframe("love", 1, self.psdData.imgs.love.x + 4)
    self.ani:addKeyframe("love", 2, self.psdData.imgs.love.y - 4)

    self.ani:addTrack("hand_Left", self.psdData, "imgs.hand_Left.y", true, true, true, "easeInOut")
    self.ani:addKeyframe("hand_Left", 0, self.psdData.imgs.hand_Left.y + 1)
    self.ani:addKeyframe("hand_Left", 1, self.psdData.imgs.hand_Left.y - 2)
    self.ani:addKeyframe("hand_Left", 2, self.psdData.imgs.hand_Left.y + 1)
end

function NianocUI:_clickAni()

    self:_clearAni()

    -- defaultEnable 默认启用 loop 循环 pinpon 来回
    self.ani:addTrack("psdy", self.psdData, "localY", true, false, false, "easeInOut")
    self.ani:addKeyframe("psdy", 0, self.psdData.localY - 5)
    self.ani:addKeyframe("psdy", 0.1, self.psdData.localY + 7)
    self.ani:addKeyframe("psdy", 0.2, self.psdData.localY - 5)

    self.ani:addTrack("clothes", self.psdData, "imgs.clothes.y", true, false, false, "easeInOut")
    self.ani:addKeyframe("clothes", 0, self.psdData.imgs.clothes.y - 1)
    self.ani:addKeyframe("clothes", 0.1, self.psdData.imgs.clothes.y + 4)
    self.ani:addKeyframe("clothes", 0.2, self.psdData.imgs.clothes.y - 1)

    self.ani:addTrack("hear_Down", self.psdData, "imgs.hear_Down.y", true, false, false, "easeInOut")
    self.ani:addKeyframe("hear_Down", 0, self.psdData.imgs.hear_Down.y + 1)
    self.ani:addKeyframe("hear_Down", 0.2, self.psdData.imgs.hear_Down.y - 1)
    self.ani:addKeyframe("hear_Down", 0.4, self.psdData.imgs.hear_Down.y + 1)

    self.ani:addTrack("mic", self.psdData, "imgs.mic.y", true, false, false, "easeInOut")
    self.ani:addKeyframe("mic", 0, self.psdData.imgs.mic.y + 6)
    self.ani:addKeyframe("mic", 0.2, self.psdData.imgs.mic.y - 3)
    self.ani:addKeyframe("mic", 0.4, self.psdData.imgs.mic.y + 6)

    self.ani:addTrack("love", self.psdData, "imgs.love.y", true, false, false, "easeInOut")
    self.ani:addKeyframe("love", 0, self.psdData.imgs.love.y - 4)
    self.ani:addKeyframe("love", 0.2, self.psdData.imgs.love.y + 8)
    self.ani:addKeyframe("love", 0.4, self.psdData.imgs.love.y - 4)

    self.ani:addTrack("hand_Left", self.psdData, "imgs.hand_Left.y", true, false, false, "easeInOut")
    self.ani:addKeyframe("hand_Left", 0, self.psdData.imgs.hand_Left.y + 4)
    self.ani:addKeyframe("hand_Left", 0.2, self.psdData.imgs.hand_Left.y - 1)
    self.ani:addKeyframe("hand_Left", 0.4, self.psdData.imgs.hand_Left.y + 4)

    timer:after(0.5, function()
        self:_defaultAni()
    end)
end

function NianocUI:getClick()
    if not self.isClickAniOver then
        return
    end
    self.isClickAniOver = false
    local w, h = self.psdData.w, self.psdData.h
    self.ani:addTrack("getClick_W", self.psdData, "w", true, false, false, "easeIn")
    self.ani:addKeyframe("getClick_W", 0, w)
    self.ani:addKeyframe("getClick_W", 0.1, w + self.clickNianZoom)
    self.ani:addKeyframe("getClick_W", 0.3, w)

    self.ani:addTrack("getClick_H", self.psdData, "h", true, false, false, "easeIn")
    self.ani:addKeyframe("getClick_H", 0, h)
    self.ani:addKeyframe("getClick_H", 0.1, h + self.clickNianZoom)
    self.ani:addKeyframe("getClick_H", 0.3, h)

    timer:after(0.3, function()
        print("")
        self.ani:clearKeyframes("getClick_W")
        self.ani:clearKeyframes("getClick_H")
        self.isClickAniOver = true
    end)

end

function NianocUI:getPress()
    local w, h = self.psdData.w, self.psdData.h
    self.psdData.w = w + self.clickNianZoom
    self.psdData.h = h + self.clickNianZoom

end

function NianocUI:getleave()

    local w, h = self.psdData.w, self.psdData.h
    self.psdData.w = w - self.clickNianZoom
    self.psdData.h = h - self.clickNianZoom
end
-- 更新播放列表显示
function NianocUI:refresh()
    self:clearStacks()
end

function NianocUI:update(dt)
    if self.states[self.state] and self.states[self.state].update then
        self.states[self.state].update(self, dt)
    end
    self.ani:update(dt)
    self.psdData:localPosRefresh() --从local位置刷新
end

function NianocUI:onClick(x, y, button)
    -- 点击图片位置
    if x >= self.x and x <= self.x + 400 * 0.5 and y >= self.y and y <= self.y + 500 * 0.5 then
        print("点击了nian接待员")
    end
    -- 处理鼠标释放事件
    if floatUI then
        floatUI:addFloatText("Hello, Nian!", x - 10, y - 10)
    end
end

function NianocUI:_nianClickAnimation()

end

function NianocUI:_defaultPsd() -- 无脸基础体
    self.psdData:allVisiable(false)
    self.psdData:getLayer("body1").visiable = true
    self.psdData:getLayer("hand_Left2").visiable = true
    self.psdData:getLayer("clothes").visiable = true
    self.psdData:getLayer("hear_Down").visiable = true
    self.psdData:getLayer("head").visiable = true
    self.psdData:getLayer("ear").visiable = true
    self.psdData:getLayer("eyebrow").visiable = true
end

function NianocUI:addMessage()
    floatUI:addDialogueBox("Hello, Nian!", self.x + 100, self.y - 50, {
        typeSpeed = 10,
        autoClose = 4,
        tailX = self.x + 100,
        tailY = self.y
    })
end

function NianocUI:draw()
    -- 画一个自己的正方体
    -- love.graphics.setColor(1,0,0)
    -- love.graphics.rectangle("fill",self.x,self.y,200,300)

    self:drawStacks()
    self.psdData:draw()
    idle = 1
end

function NianocUI:destroy()
    NianocUI.super.destroy(self)
    nianAI:destroy()
end

return NianocUI
