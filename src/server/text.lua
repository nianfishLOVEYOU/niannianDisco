--物理
world = love.physics.newWorld(0, 9.8*64, true) -- x重力, y重力, 是否允许休眠
body = love.physics.newBody(world, x, y, "dynamic") -- 世界, 位置, 类型
shape = love.physics.newRectangleShape(0, 0, width, height) -- 相对刚体的偏移和尺寸
fixture = love.physics.newFixture(body, shape, density) -- 刚体, 形状, 密度
fixture:setFriction(0.3)
fixture:setRestitution(0.2) -- 弹性

function love.update(dt)
    world:update(dt)
end