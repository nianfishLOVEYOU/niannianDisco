-- ShaderManager.lua


local ShaderManager = {
    effects = {},
    canvasChain = {},
    finalCanvas = nil,
    enabled = true
}


-- shaderManager:addEffect(require("src.shader.blurEffect").getshader(), 1)


function ShaderManager:addEffect(effect, priority)
    effect.priority = priority or (#self.effects + 1)
    table.insert(self.effects, effect)
    table.sort(self.effects, function(a, b)
        return a.priority < b.priority
    end)
    return self
end

function ShaderManager:removeEffect(effectName)
    for i = #self.effects, 1, -1 do
        if self.effects[i].name == effectName then
            table.remove(self.effects, i)
        end
    end
    return self
end

function ShaderManager:getEffect(effectName)
    for _, effect in ipairs(self.effects) do
        if effect.name == effectName then
            return effect
        end
    end
    return nil
end

function ShaderManager:createCanvasChain(width, height)
    self.canvasChain = {
        love.graphics.newCanvas(width, height),
        love.graphics.newCanvas(width, height)
    }
    self.finalCanvas = love.graphics.newCanvas(width, height)
    return self
end

function ShaderManager:render(sceneDrawFunc, inCanvas)
    if not self.enabled or #self.effects == 0 then
        -- 直接绘制场景
        if (inCanvas) then
            love.graphics.draw(inCanvas, 0, 0)
        end
        sceneDrawFunc()
        return self.finalCanvas
    end

    local screenWidth, screenHeight = love.graphics.getDimensions()

    -- 确保画布链存在且尺寸正确
    if not self.canvasChain[1] or
        self.canvasChain[1]:getWidth() ~= screenWidth or
        self.canvasChain[1]:getHeight() ~= screenHeight then
        self:createCanvasChain(screenWidth, screenHeight)
    end

    -- 绘制原始场景到第一个画布
    love.graphics.setCanvas(self.canvasChain[1])
    love.graphics.clear()
    if (inCanvas) then
        love.graphics.draw(inCanvas, 0, 0)
    end
    sceneDrawFunc()
    love.graphics.setCanvas()

    local currentInput = self.canvasChain[1]
    local currentOutput = self.canvasChain[2]

    -- 按顺序应用所有shader效果
    for _, effect in ipairs(self.effects) do
        if effect.enabled then
            -- 更新屏幕尺寸uniform
            if effect.setScreenSize then
                effect:setUniform("screenSize", { screenWidth, screenHeight })
            end

            -- 应用效果
            currentOutput = effect:draw(currentInput)

            -- 交换输入输出
            currentInput, currentOutput = currentOutput, currentInput
        end
    end

    -- 最终结果在currentInput中
    self.finalCanvas = currentInput
    return self.finalCanvas
end

function ShaderManager:drawFinal(x, y, ...)
    if self.finalCanvas then
        love.graphics.draw(self.finalCanvas, x, y, ...)
    end
end

function ShaderManager:clear()
    self.effects = {}
    self.canvasChain = {}
    self.finalCanvas = nil
end

return ShaderManager
