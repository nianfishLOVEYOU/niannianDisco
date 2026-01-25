local bodyItem = require "src.item.bodyItem"
local spriteAnimation = require "src.common.spriteAnimation"

local cake = bodyItem:extend()

function cake:init( imgPath, bodyInfo)
    self.type="table"
    self:setImage("res/image/cake.png")
    self.candleImage = spriteAnimation:new("res/image/candle.png", 0, 0, 0.5, 1) 
    self:setBody(self.w,self.h/2)
end

--玩家点击，玩家长按，
function cake:Clicked(player)
    
end

-- 本地触发蛋糕点击的完整流程
local function handleCakeClickSequence()
    -- 先暂停并淡出当前 audio 音乐
    if audio and audio.pauseForCake then
        audio:pauseForCake()
    end

    -- 播放生日快乐歌
    local src
    if soundManager and soundManager.play then
        src = soundManager:play("res/soundeffects/happybirthday.mp3", 1, false)
    end

    -- 监听生日歌结束，再等待 2 秒恢复 audio 音乐
    if src and timer then
        timer:during(0.1, function() end, function()
            -- 轮询检查直到生日歌结束
            local function waitSongEnd()
                if src:isPlaying() then
                    timer:after(0.1, waitSongEnd)
                else
                    -- 歌放完后，再等 2 秒恢复 audio
                    timer:after(2.0, function()
                        if audio and audio.resumeAfterCake then
                            audio:resumeAfterCake()
                        end
                    end)
                end
            end
            waitSongEnd()
        end)
    else
        -- 如果没拿到 source，就直接 2 秒后恢复
        if timer then
            timer:after(2.0, function()
                if audio and audio.resumeAfterCake then
                    audio:resumeAfterCake()
                end
            end)
        end
    end
end

function cake:onClick(player)
    -- 检测玩家是否在50单位距离内
    if not player or not player.getPos then return end
    local px, py = player:getPos()
    local cx, cy = self:getPos()
    local dx, dy = px - cx, py - cy
    local dist2 = dx * dx + dy * dy
    local maxDist = 50
    if dist2 > maxDist * maxDist then
        return
    end

    -- 本地执行蛋糕点击流程
    handleCakeClickSequence()

    -- 通过网络广播蛋糕被点击的事件，让所有玩家同步此流程
    if network and network.send_Broadcast then
        local msg = {
            type = "cake_clicked",
            time = love.timer.getTime(),
        }
        network:send_Broadcast(msg)
    end
end

function cake:draw()
    bodyItem.draw(self)
    -- love.graphics.setColor(1, 0, 0)
    -- love.graphics.rectangle("fill", self.posx, self.posy, 5, 5)
end

function cake:animation()
    --星星一闪一闪
end

return cake