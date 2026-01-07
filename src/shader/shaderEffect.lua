-- ShaderEffect.lua

local class =require "src.common.class"
local ShaderEffect = class:new()

function ShaderEffect:init(shaderCode, name,drawFunc)
    self.name = name or "unnamed_effect"
    self.shader = type(shaderCode) == "string" and love.graphics.newShader(shaderCode) or shaderCode
    self.uniforms = {}      -- 存储uniform值
    self.enabled = true     -- 是否启用
    self.setScreenSize = true -- 是否自动设置屏幕尺寸uniform
    self.drawFunc = drawFunc
    self.priority = 0       -- 渲染优先级
end

function ShaderEffect:setUniform(name, value) 
    self.uniforms[name] = value
    return self
end

function ShaderEffect:setEnabled(enabled)
    self.enabled = enabled
    return self
end

function ShaderEffect:setPriority(priority)
    self.priority = priority
    return self
end

function ShaderEffect:apply()
    if not self.enabled then return self end
    
    -- 应用所有uniforms
    for name, value in pairs(self.uniforms) do
        if type(value) == "table" and value.__instance then
            -- 如果是Canvas对象
            self.shader:send(name, value)
        else
            self.shader:send(name, value)
        end
    end
    
    
    -- 应用shader
    love.graphics.setShader(self.shader)
    return self
end

function ShaderEffect:draw(canvas)
    if not self.enabled then return canvas end
    
    -- 创建临时画布
    local tempCanvas = love.graphics.newCanvas(canvas:getDimensions())
    
    -- 设置渲染目标
    love.graphics.setCanvas(tempCanvas)
    love.graphics.clear()
    
    -- 应用shader
    self:apply()
    
    -- 绘制原始canvas
    if self.drawFunc then
        self.drawFunc(canvas)
    else
        love.graphics.draw(canvas, 0, 0)
    end
    
    -- 重置shader
    love.graphics.setShader()
    love.graphics.setCanvas()
    
    return tempCanvas
end

return ShaderEffect