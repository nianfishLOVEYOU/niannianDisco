local bodyItem = require "src.item.bodyItem"

local ball = bodyItem:extend()

function ball:init(imgPath, bodyInfo)
    -- 初始化子类特有属性
    self.type = "ball"
    self:setImg("res/item/gift.png")
    self.z = 0.3
    self:setBody(self.w, self.h / 2)
    self.interaction = true
end

-- 计算从玩家到球的方向向量（单位向量）
local function getKickDir(player, ball)
    if not player or not player.getPos then return 1, 0 end
    local px, py = player:getPos()
    local bx, by = ball:getPos()
    local dx, dy = bx - px, by - py
    local len = math.sqrt(dx * dx + dy * dy)
    if len == 0 then return 1, 0 end
    return dx / len, dy / len
end

-- 本地执行踢球动作
function ball:doKickFromPlayer(player)
    local dirx, diry = getKickDir(player, self)
    local power = 200 -- 踢的力度，可按需要调整
    if self.body and self.body.applyLinearImpulse then
        self.body:applyLinearImpulse(dirx * power, diry * power)
    else
        -- 无物理刚体时，直接改位置作为一个简单效果
        local x, y = self:getPos()
        self:setPos(x + dirx * 30, y + diry * 30)
    end
end

-- 通用的动作广播方法
-- actionType: 字符串，例如 "kick_ball"
-- data: 任意表，含玩家 id/位置/方向等
local function broadcastAction(actionType, data)
    if network and network.send_Broadcast then
        local msg = data or {}
        msg.type = actionType
        msg.time = love.timer.getTime()
        network:send_Broadcast(msg)
    end
end

-- 点击按钮才触发
function ball:onClick()


end

function ball:interact(player)
    -- 预留：如果以后希望靠近自动交互，可以复用 onClick 逻辑
    self:onClick()
end

return ball