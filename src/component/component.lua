local Class = require "src.common.class"

local Component = Class:new()

function Component:init()
    self.name = self.type  or "Component"
    self.enabled =  true
    self.owner = nil
    self.type = self.type or "Component"
end

-- attach to an owner (game object / entity)
function Component:attach(owner)
    if self.owner == owner then return end
    if self.owner and self.owner.removeComponent then
        self.owner:removeComponent(self)
    end
    self.owner = owner
    if owner and owner.addComponent then
        owner:addComponent(self)
    end
    if self.onAttach then self:onAttach(owner) end
end

function Component:detach()
    if not self.owner then return end
    if self.onDetach then self:onDetach(self.owner) end
    if self.owner.removeComponent then
        self.owner:removeComponent(self)
    end
    self.owner = nil
end

function Component:update(dt)
    -- override in subclass
end

function Component:enable()
    self.enabled = true
end

function Component:disable()
    self.enabled = false
end

function Component:isEnabled()
    return self.enabled
end

function Component:getOwner()
    return self.owner
end

function Component:serialize()
    -- return minimal serializable state; override as needed
    return { name = self.name, type = self.type, enabled = self.enabled }
end

function Component:deserialize(data)
    if not data then return end
    if data.name then self.name = data.name end
    if data.enabled ~= nil then self.enabled = data.enabled end
    if data.type then self.type = data.type end
end
-- default hooks (can be overridden in subclasses)
function Component:onAttach(owner)
    -- owner: the object this component was attached to
    -- default: no-op, subclasses may setup event hooks or state here
end

function Component:onDetach(owner)
    -- owner: the object this component was detached from
    -- default: no-op, subclasses may cleanup here
end

return Component
