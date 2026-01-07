-- player.lua
local bodyItem = require "src.item.bodyItem"
local player = bodyItem:extend()

function player:init(x, y, w, h, imgPath, bodyInfo)
    print("--------------local")
    self.type = "player"

    self:setImage(imgPath)
    self:setBody(self.w / 2, 10,0,-0.5,{type="dynamic"})

    
    self.speed = 200
    self.direct = 1
    self.ismove = false
    self.animationAttribute = {
        h = 1,
        w = 1
    }
    -- 目标移动相关
    self.targetX = nil
    self.targetY = nil
    self.moveToTarget = false

    self.name = "比噶"

    -- 动画移动动画注册
    self.aniidx = true
    self.animationtime = 0.2
    self.isAnimation = true
    self:Animaiton()
end

function player:setName(name)
    self.name = name
end

function player:gotoPos(x, y)
    -- 设置目标点，角色会朝该点移动直到到达
    self.targetX = x
    self.targetY = y
    self.moveToTarget = true
end


-- 尝试移动，若与阻挡物体相撞则阻止该方向的位移
function player:move(dx, dy)
    self.body:setLinearVelocity(dx, dy)
end

-- 聊天
function player:speak(speakInfo)

end

function player:update(dt)
    --父类的方法执行
    player.super.update(self, dt)
    local vx, vy = 0, 0
    -- 鼠标操作：按住左键直接人工控制，优先级高于目标点移动
    if self.moveToTarget and self.targetX and self.targetY then
        -- 自动朝目标点移动
        local tx = self.targetX - self.x
        local ty = self.targetY - self.y
        local dist = math.sqrt(tx * tx + ty * ty)
        local STOP_DIST = 4 -- 到达阈值（像素）
        if dist <= STOP_DIST then
            -- 到达目的地，停止并精确对位
            self.body:setLinearVelocity(0, 0)
            self:setPos(self.targetX, self.targetY)
            self.moveToTarget = false
            vx, vy = 0, 0
        else
            local nx, ny = normalize(tx, ty)
            vx, vy = nx * self.speed, ny * self.speed
            if vx > 0 then
                self.direct = 1
            elseif vx < 0 then
                self.direct = -1
            end
        end
    end

    self.ismove = vx ~= 0 or vy ~= 0
    self:move(vx, vy)

    for i, v in ipairs(self.component) do
        v:update(self, dt)
    end
end

--走路动画
function player:Animaiton()
    if not self.isAnimation then
        return
    end

    local h, w = 1, 1
    if self.ismove then
        if self.aniidx then
            self.animationAttribute.w, self.animationAttribute.h = 0.8, 1.3
            w, h = 1.3, 0.8
        end
        if not self.aniidx then
            self.animationAttribute.w, self.animationAttribute.h = 1.3, 0.8
            w, h = 0.8, 1.3
        end
    else
        self.aniidx = true
    end

    local aniSize = {
        h = h,
        w = w
    }
    animation:addAnimation(self.animationAttribute, aniSize, self.animationtime, {
        onComplete = function()
            self:Animaiton()
        end
    })
    self.aniidx = not self.aniidx
end

function player:draw()
    --有动画状态时候

    self.image:setPos(self:getPos())
    self.image:setSize(self:getSize())
    self.image:setFlip(self.direct == 1, false)
    self.image:setScale(self.animationAttribute.w * pixSize, self.animationAttribute.h * pixSize)
    self.image:setLayer(self.layer)
    self.image:draw()

    -- 显示名字

    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle('fill', self.x - self.w / 2, self.y - self.h - 30, self.w, 20)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print(self.name, self.x + 20 - self.w / 2, self.y - self.h - 30)

end

function player:destroy()
    --父类的方法执行
    player.super.destroy(self)
    self.isAnimation = false
end

return player
