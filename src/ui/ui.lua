local object = require "src.common.object"
local UI = object:extend()

function UI:init()
    self.scalex = 1 -- 缩放倍数
    self.scaley = 1 -- 缩放倍数
    self.stacks = {}
    self.z = 0
end

function UI:refresh()

end

function UI:addStack(stack)
   
    table.insert(self.stacks, stack)
end

function UI:clearStacks()
    if #self.stacks == 0 then return end
    for i = #self.stacks, 1, -1 do
        self.stacks[i]:destroy()
        table.remove(self.stacks, i)
    end
end

function UI:update(dt)

end

function UI:draw()
    love.graphics.push()
    love.graphics.scale(self.scalex, self.scaley)
    -- 这里绘制所有 UI 元素
    if (#self.stacks > 0) then
        for i, stack in ipairs(self.stacks) do
            stack:draw()
        end
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
    UI.super.destroy(self)
    self:clearStacks()
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
