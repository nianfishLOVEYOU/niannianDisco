-- Item.lua
local class = require "src.common.class"
local object = class:extend()

-- gc执行句柄
object.__gc = function(u)
    print("Cleaning up resources for", u)
end

function object:init()
    self.id = ""
    self.type = "object"
    local id = globleManager:guid()
    self:setId(id)
end


function object:setId(id)
    self.id = id
end

function object:update(dt)

end

function object:draw()

end

-- 确保没有被引用了
function object:destroy()
    if self.__destroyed then
        --nianDebug.printStackTrace("destory object: " .. tostring(self.type))
        print("! duble destory !",self.type, self.id)
        return
    end
    self.__destroyed = true
end

return object
