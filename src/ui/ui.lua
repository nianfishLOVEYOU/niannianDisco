local UI = {
    posx = 0,
    posy = 0,
    scalex = 1, -- 缩放倍数
    scaley = 1, -- 缩放倍数
    stack = nil
}

UI.__index = UI
function UI:new(...)
    local obj = setmetatable({}, UI)
    -- 初始化父类属性
    return obj
end

function UI:init()

end

function UI:refresh()
    if self.stack then
        self.stack:destroy()
    end
end

function UI:update(dt)

end

function UI:draw()
    love.graphics.push()
    love.graphics.scale(self.scalex, self.scaley)
    -- 这里绘制所有 UI 元素
    if (self.stack) then
        self.stack:draw(self.posx, self.posy)
    end

    love.graphics.pop()
end

function UI:mouseLeased(x, y, button)

end

function UI:mousePressed(x, y, button)

end

function UI:mouseMoved(x, y, dx, dy)

end

function UI:wheelmoved(x, y)

end

function UI:destroy()
    if (self.stack) then
        self.stack:destroy()
    end
end

-- local Child = {}
-- Child.__index = Child
-- setmetatable(Child, { __index = UI })   -- 子类继承父类
-- function Child:new(...)
--     local obj = UI:new(...)               -- 先走父类构造
--     setmetatable(obj, Child)                 -- 再把实例的元表改为子类
--     -- 初始化子类特有属性
--     return obj
-- end

return UI
