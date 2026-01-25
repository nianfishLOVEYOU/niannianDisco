local bodyItem = require "src.item.bodyItem"
local spriteAnimation = require "src.common.spriteAnimation"

local cake = bodyItem:extend()

function cake:init(imgPath, bodyInfo)
    self.type = "cake"
    self:setImage("res/image/cake.png")
    self.interaction = true
    self.layer = 0.3
    self.interaction = true
    self.candleImage = spriteAnimation:new("res/image/candle.png", 0, 0, 0.5, 1)
    self.candleImage.z = 0.4
    self.candleImage.layer = 0.4
    self.candleImage:setScale(4, 4)

    self.z = 0.3
    self:setBody(self.w, self.h / 2)
    self.isOnclick=false
end

-- 玩家点击，玩家长按，
function cake:ani()
    self.candleImage = spriteAnimation:new("res/image/candleA.png", 0, 0, 0.5, 1)
    self.candleImage.z = 0.4
    self.candleImage.layer = 0.4
    self.candleImage:setQuadAnimation(2, 1, 2, 0.2)
    self.candleImage:setSize(0,0)
    self.candleImage:setScale(2, 4)
end

function cake:update(dt)
    self.candleImage:update(dt)
    self.candleImage.x, self.candleImage.y = self.x, self.y - self.h / 2

end

-- 本地触发蛋糕点击的完整流程
function cake:handleCakeClickSequence()
    self:ani()
    -- 先暂停并淡出当前 audio 音乐
    audio:pauseForCake()

    -- 播放生日快乐歌
    local src = soundManager:play("res/soundeffects/happybirthday.mp3", 1, false)

    -- 监听生日歌结束，再等待 2 秒恢复 audio 音乐
    if src then
        local idT={}
        idT.id = timer:during(0.1, 100,function()
            if not src:isPlaying() then
                audio:resumeAfterCake()
                timer:cancel(idT.id)
                self.isOnclick=false
            end
        end, function()
            print("cake song")
        end)
    else
        return
    end

    -- --添加一个球在地图startpoint
    -- itemManager:addItem()
end

-- 点击按钮才触发
function cake:onClick()
    if self.isOnclick then
        return
    end
    self.isOnclick=true
    -- 本地执行蛋糕点击流程
    self:handleCakeClickSequence()
    -- 通过网络广播蛋糕被点击的事件，让所有玩家同步此流程
    if network and network.send_Broadcast then
        local msg = {
            type = "cake_clicked",
            time = love.timer.getTime()
        }
        network:send_Broadcast(msg)
    end
end

function cake:draw()
    bodyItem.draw(self)
    self.candleImage:draw()

    -- love.graphics.setColor(1, 0, 0)
    -- love.graphics.rectangle("fill", self.posx, self.posy, 5, 5)
end

return cake
