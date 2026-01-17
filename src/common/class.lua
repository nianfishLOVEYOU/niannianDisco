-- class.lua
local Class = {}

-- 创建一个新类（静态方法，不是实例方法）
function Class:new(base)
    local cls = {}
    cls.__index = cls

    -- 设置继承
    if base then
        setmetatable(cls, {
            -- 核心改造：__index包装函数，保留查找上下文
            __index = function(t, k)
                -- 1. 先检查基类是否有这个key（避免直接返回base导致上下文丢失）
                local value = base[k]
                
                -- 2. 安全防护：避免覆盖核心属性（比如super）
                if k == "super" then
                    return base  -- 强制返回基类，防止super被误赋值
                end
                
                -- 3. 返回基类的属性/方法，同时保留t（子类）的上下文
                return value
            end
        })
        cls.super = base
    end

    -- 类的构造函数（实例化方法）...初始化函数参数顺序要一样，只能多不能少
    function cls:new(...)
        local instance = self.super and self.super:new(...) or {}
        setmetatable(instance, self)

        -- 调用初始化方法
        if self.init then
            self.init(instance, ...)
        end

        return instance
    end

    --衍生类的init属性要和父类对的上
    function cls:extend()
        return Class:new(self)
    end

    --这玩意导致我再其他地方调用 子类对象.x 然后就把super设置为x了
    -- 让类可以像函数一样调用
    -- setmetatable(cls, {
    --     __call = function(self, ...)
    --         return self:new(...)
    --     end
    -- })

    return cls
end

function Class:init(...)

end

-- 扩展类（创建子类）的快捷方法
function Class:extend()
    return Class:new(self)
end

-- 让Class本身也可以像函数一样调用
setmetatable(Class, {
    __call = function(_, base)
        return Class:new(base)
    end
})

return Class

-- 使用案例
-- 1. 创建基类
-- local Animal = Class:new()  -- 或 Animal = Class()

-- function Animal:init(name)
--     self.name = name
-- end

-- function Animal:speak()
--     return "Animal sound"
-- end

-- -- 2. 创建子类（两种方式都可以）
-- local Dog = Class.new(Animal)  -- 方式1：使用Class.new
-- -- local Dog = Animal:extend()  -- 方式2：使用extend方法

-- function Dog:init(name, breed)

--     -- 调用父类构造函数
--     if self.super and self.super.init then
--         self.super.init(self, name)
--     end
--     self.breed = breed
-- end
