-- 简化 ShadePanel：只在裁剪区内绘制并响应子对象
local widget = require "src.glove.widgets.widget"
local g = love.graphics

local ShadePanel = widget:extend()

function ShadePanel:init(children)
    self.type = "ShadePanel"
    self.w = 60
    self.h = 100
    self.z=-1
    self.contents = children or {}
    --每个都设置裁剪
    for _, entry in ipairs(self.contents) do
        entry:setShade(self)
    end
end

function ShadePanel:getPos()
    local x,y,_= widget.getPos(self)
    return x, y, -1
end

function ShadePanel:addContent(content)
    table.insert(self.contents, content)
    content:setShade(self)
end

function ShadePanel:removeContent(content)
    for i, entry in ipairs(self.contents) do
        if entry == content then
            table.remove(self.contents, i)
            entry:setShade(nil)
            break
        end
    end
end

-- --不会被点击
-- function ShadePanel:isOver(x,y)
--     return false
-- end

function ShadePanel:draw()
    if not self.visible then return end
    local sx, sy, sw, sh = g.getScissor()
    g.setScissor(self.x, self.y, self.w, self.h)
    for _, entry in ipairs(self.contents) do
        if entry.draw then
            entry:draw()
        end
    end
    g.setScissor(sx, sy, sw, sh)

    g.setColor(1, 1, 0)
    g.rectangle("line", self.x, self.y, self.w, self.h)
    --print("ShadePanel draw", self.x, self.y, self.w, self.h)
end

return ShadePanel
