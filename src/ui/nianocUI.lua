local ui = require "src.ui.ui"
local psdData = require "src.common.artal.psdData"
local animator = require("src.animator")
local nianocUI = ui:extend()

function nianocUI:init()
    self:refresh()
    self.ani = animator.new()
    print("nianocUI:init()", self.ani, animator)
    self.stateType = ""
    self.state = {}
    self.states = self:_createStates()

    -- self.nianImage = love.graphics.newImage("res/image/nianPlayer.png")
    -- 自己的位置跟着父亲走
    self:setLocalPos(love.graphics.getWidth() - 230, love.graphics.getHeight() - 420)
    -- 创建动画轴

    self:_newNian()
end

function nianocUI:_newNian()
    self.psdData = psdData:new("res/image/nian/nian.psd")
    self.psdData:setPos(self.x, self.y)
    self:changeState("idle")
end

function nianocUI:changeState(state)
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

function nianocUI:_createStates()
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
            self:_mouseAction("close")

            -- 动画
            self:_defaultAni()

        end,
        update = function(self, dt)
            wait = wait + dt
            if wait > 3 then
                self:_eyeAction("blink")
                random = math.random(0, 1)
                print(random) -- 随机嘴型
                if random < 0.2 then
                    self:_mouseAction("happy")
                elseif random < 0.3 then
                    self:_mouseAction("open")
                else
                    self:_mouseAction("close")
                end
                wait = 0
            end

            -- print("11")
        end,
        leave = function(self)
            self.ani:clearKeyframes("psdy")
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
    return states
end

function nianocUI:_bodyAction(action)
    if action == "idle" then

    elseif action == "leftHand" then

    elseif action == "click" then

    end

end

local eye = ""
-- 眼睛动作
function nianocUI:_eyeAction(action)
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
function nianocUI:_mouseAction(action)
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

function nianocUI:_defaultAni()

    self.ani:clearKeyframes("psdy")
    self.ani:clearKeyframes("clothes")
    self.ani:clearKeyframes("head")
    self.ani:clearKeyframes("mic")
    self.ani:clearKeyframes("love")
    self.ani:clearKeyframes("hand_Left")

    -- defaultEnable 默认启用 loop 循环 pinpon 来回
    self.ani:addTrack("psdy", self.psdData, "y", true, true, false, "easeInOut")
    self.ani:addKeyframe("psdy", 0, self.psdData.y - 4)
    self.ani:addKeyframe("psdy", 2, self.psdData.y + 4)
    self.ani:addKeyframe("psdy", 4, self.psdData.y - 4)

    self.ani:addTrack("clothes", self.psdData, "imgs.clothes.y", true, true, true, "easeInOut")
    self.ani:addKeyframe("clothes", 0, self.psdData.imgs.clothes.y - 1)
    self.ani:addKeyframe("clothes", 2, self.psdData.imgs.clothes.y + 1)
    self.ani:addKeyframe("clothes", 4, self.psdData.imgs.clothes.y - 1)

    self.ani:addTrack("head", self.psdData, "imgs.head.y", true, true, true, "easeInOut")
    self.ani:addKeyframe("head", 0, self.psdData.imgs.head.y - 1)
    self.ani:addKeyframe("head", 2, self.psdData.imgs.head.y + 1)
    self.ani:addKeyframe("head", 4, self.psdData.imgs.head.y - 1)

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

-- 更新播放列表显示
function nianocUI:refresh()
    self:clearStacks()
end

function nianocUI:update(dt)
    if self.states[self.state] and self.states[self.state].update then
        self.states[self.state].update(self, dt)
    end
    self.ani:update(dt)
end

function nianocUI:onClick(x, y, button)
    -- 点击图片位置
    if x >= self.x and x <= self.x + 400 * 0.5 and y >= self.y and y <= self.y + 500 * 0.5 then
        print("点击了nian接待员")
    end
end

function nianocUI:_nianClickAnimation()

end

function nianocUI:_defaultPsd() -- 无脸基础体
    self.psdData:allVisiable(false)
    self.psdData:getLayer("body1").visiable = true
    self.psdData:getLayer("hand_Left2").visiable = true
    self.psdData:getLayer("clothes").visiable = true
    self.psdData:getLayer("hear_Down").visiable = true
    self.psdData:getLayer("head").visiable = true
    self.psdData:getLayer("ear").visiable = true
    self.psdData:getLayer("eyebrow").visiable = true
end

function nianocUI:draw()
    -- 画一个自己的正方体
    -- love.graphics.setColor(1,0,0)
    -- love.graphics.rectangle("fill",self.x,self.y,200,300)

    self:drawStacks()
    self.psdData:draw()
    idle = 1
end

function nianocUI:destroy()
    nianocUI.super.destroy(self)
end

return nianocUI
