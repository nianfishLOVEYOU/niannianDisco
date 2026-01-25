-- Item.lua
local object = require "src.common.object"
local item = object:extend()

-- gc执行句柄
item.__gc = function(u)
    print("Cleaning up resources for", u)
end

function item:init()
    self.name = "n_name"
    self.id = ""
    self.type     = "item"

    self.x, self.y = 10, 10
    self.z = 0

    self.localX, self.localY = 0, 0 -- 和父母的相对位置，用来区别普通位置
    self.localZ = 0

    self.layer = 0.2
    local id = globleManager:guid()
    self:setId(id)
    self.w, self.h = 100, 100
    -- 点击边界缩放
    self.overPadding = 0
    -- 自身颜色
    self.color = { 1, 1, 1 }
    -- 组件
    self.component = {}
    self.componentMap = {}
    self.visiable = true
    -- 父对象
    self.parent = nil
    -- 子对象
    self.children = {}

    -- 清理方法

    -- 可交互
    self.interaction = false
end

function item:setName(name)
    self.name = name
end

function item:setParentInit()
    self.localX = self.x - self.parent.x
    self.localY = self.y - self.parent.y
end

function item:addChild(child)
    --避免循环嵌套，要遍历自己的父亲的父亲。。。有没有这个孩子

    -- prevent creating cycles: ensure 'child' is not an ancestor of self
    if child == self then
        print("item:addChild: cannot add self as child")
        return
    end
    local p = self
    while p do
        if p == child then
            print("item:addChild: cannot add child — it is an ancestor (would create cycle)")
            return
        end
        p = p.parent
    end

    if child.parent then
        child.parent:removeChild(child)
    end
    table.insert(self.children, child)
    child.parent = self
    child:setParentInit()
end

function item:removeChild(child)
    if #self.children == 0 then return end
    for i = #self.children, 1, -1 do
        if self.children[i] == child then
            table.remove(self.children, i)
            child.parent = nil
        end
    end
end

function item:clearChild()
    if #self.children == 0 then return end
    for i = #self.children, 1, -1 do
        self.children[i].parent = nil
        table.remove(self.children, i)
    end
end

function item:addComponent(name)

    -- Accept either a component instance or a module name
    local comp = name
    if type(name) == "string" then
        local ok, mod = pcall(require, "src.component." .. name)
        if not ok then
            print("item:addComponent require failed:", mod)
            return
        end
        if type(mod.new) == "function" then
            comp = mod:new()
        else
            comp = mod
        end
    end
    if type(comp) ~= "table" then return end

    -- prevent duplicate
    if comp.name and self.componentMap[comp.name] then return end

    -- if comp already has different owner, remove from it
    if comp.owner and comp.owner ~= self and comp.owner.removeComponent then
        comp.owner:removeComponent(comp)
    end

    -- set owner and register
    comp.owner = self
    table.insert(self.component, comp)
    if comp.name then self.componentMap[comp.name] = comp end

    -- call attach hook if present
    if comp.onAttach then
        comp:onAttach(self)
    end
    -- if component has enable flag, keep it; otherwise default true
    if comp.enabled == nil then comp.enabled = true end
end

function item:removeComponent(name)

    -- remove by instance or by name
    local comp = name
    if type(name) == "string" then
        comp = self.componentMap[name]
    end
    if not comp then return end

    for i = #self.component, 1, -1 do
        if self.component[i] == comp then
            table.remove(self.component, i)
        end
    end
    if comp.name then self.componentMap[comp.name] = nil end

    -- call detach/destroy hooks
    if comp.onDetach then
        comp:onDetach(self)
    end
    if comp.destroy then
        comp:destroy()
    end
    comp.owner = nil
end

-- 点击事件
function item:onClick(x, y, button)

end

-- 被拖拽
function item:onDrag(x, y, dx, dy)

end

function item:onDragOver(x, y)

end

function item:onClickOver(x, y)

end

-- 悬停
function item:onHold(x, y)

end

function item:setId(id)
    self.id = id
end

function item:setLocalPos(x, y, z)
    if self.parent then
        self.localX = x or self.localX
        self.localY = y or self.localY
        self.localZ = z or self.localZ
        self:localPosRefresh()
    else
        self:setPos(x, y, z)
    end
end

function item:getLocalPos()
    if self.parent then
        return self.localX, self.localY, self.localZ
    else
        return self.x, self.y, self.z
    end
end

-- 刷新本地位置
function item:localPosRefresh()
    if self.parent then
        local px, py, pz = self.parent:getPos()
        self.x, self.y, self.z = px + self.localX, py + self.localY, pz + self.localZ
    end
end

function item:isOver(mouseX, mouseY)
    local width, height = self:getSize()
    return self.x - self.overPadding <= mouseX and mouseX <= self.x + width and self.y <= mouseY and mouseY <= self.y +
        height
end

function item:setPos(x, y, z)
    if self.parent then
        self:localPosRefresh()
    end

    self.x = x or self.x
    self.y = y or self.y
    self.z = z or self.z
end

function item:getPos()
    self:localPosRefresh()
    return self.x, self.y, self.z
end

function item:setScale(scaleW, scaleH)
    self.w = self.w * scaleW
    self.h = self.h * scaleH
end

-- 设置尺寸（缩放时锚点位置不变）
function item:setSize(w, h)
    self.w = w
    self.h = h
end

function item:getSize()
    return self.w, self.h
end

function item:update(dt)
    self:localPosRefresh()
    -- update components
    for _, comp in ipairs(self.component) do
        if comp and comp.enabled and comp.update then
            comp:update(dt)
        end
    end
end

function item:draw()
    local x, y = self:getPos()
    love.graphics.setColor(self.color)
    love.graphics.rectangle('fill', x - self.w / 2, y - self.h / 2, self.w,
        self.h)
end

-- 确保没有被引用了
function item:destroy()
    item.super.destroy(self)
    for _, child in ipairs(self.children) do
        if child.destroy then
            child:destroy()
        end
    end
    -- destroy components
    for _, comp in ipairs(self.component) do
        if comp and comp.destroy then
            comp:destroy()
        end
        if comp and comp.onDetach then
            comp:onDetach(self)
        end
        if comp then comp.owner = nil end
    end
end

return item
