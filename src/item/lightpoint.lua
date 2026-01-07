local item = require "src.item.item"
local lightShader=require("src.shader.lightPointEffect")
local LightPoint = item:extend()

function LightPoint:init(x, y, w, h)
    -- 初始化子类特有属性
    self.type = "lightpoint"
    if lightShader.isCreatShader then
        lightShader.addPointLight({ x = x, y = y, r = 0.5, g = 0.5, b = 0.5, radius = 350, intensity = 0.8 })
    end
end

return LightPoint
