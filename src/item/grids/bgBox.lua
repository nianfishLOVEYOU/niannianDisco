local Item = require "src.item.item"
local spriteAnimation = require "src.common.spriteAnimation"
local bgBox = Item:extend()

function bgBox:init(imgPath)

    self.type = "bgBox"
    self.z = 0
    self.ground = spriteAnimation:new("res/image/scence/sand_ground.png", 0, 0, 0.5, 0.5)
    self.sea = spriteAnimation:new("res/image/scence/sand_sea.png", 0, 0, 0.5, 0.4)
    self.skybox = spriteAnimation:new("res/image/scence/sand_bg.png", 0, 0, 0.5, 0.9)

    self.ground:setScale(1.3,1.3)
    -- self.sea:setScale(0.5,0.5)  
    -- self.skybox:setScale(0.5,0.5)

    self.w = self.ground.originalW
    self.h = self.ground.originalH
    self:setSize(mapManager.map.gridSize, mapManager.map.gridSize)

    self:newBody(self.x,self.y,self.ground.w/2, self.ground.h/2, 36)
end

function bgBox:update(dt)

end

function bgBox:setPos(x, y, z)
    bgBox.super.setPos(self, x, y, z)
    self.skybox:setPos(self.x, self.y, self.z)
    self.sea:setPos(self.x, self.y, self.z)
    self.ground:setPos(self.x, self.y, self.z)
    self:newBody(self.x,self.y ,self.ground.w/2, self.ground.h/2, 36)
end

function bgBox:draw()

    self.skybox:draw()
    self.sea:draw()
    self.ground:draw()

    
    -- 绘制边界 (需要获取顶点位置，此处省略)
    -- 绘制圆形
    -- local x, y = self.physics.ballBody:getPosition()
    -- love.graphics.circle("fill", x, y, 15)
    -- print("ball position:", x, y)
end



function bgBox:newBody(cx,cy,a, b, segments)
    self:destroyBody()  -- 先销毁已有的物理对象
    -- 2. 创建椭圆边界 (静态刚体)
    local body = love.physics.newBody(world, cx, cy, "static")
    -- 生成椭圆顶点 (与之前类似)
    local vertices = {}
    local a, b, segments = a or 250, b or 150, segments or 36
    for i = 0, segments do
        local theta = i / segments * 2 * math.pi
        local x = a * math.cos(theta)
        local y = b * math.sin(theta)
        table.insert(vertices, x)
        table.insert(vertices, y)
    end
    -- 用顶点创建链状形状，并附加到刚体上
    local shape = love.physics.newChainShape(false, vertices)
    local fixture = love.physics.newFixture(body, shape)

    -- 保存引用以便绘制
    self.physics = {
        world = world,
        boundaryBody = body,
        boundaryShape = shape,
        boundaryFixture = fixture,
    }
end

function bgBox:destroyBody()
    if self.physics then
        self.physics.boundaryBody:destroy()
        -- self.physics.ballBody:destroy()
        self.physics = nil
    end
end

function bgBox:destroy()
    bgBox.super.destroy(self)
    self:destroyBody()
end

return bgBox

