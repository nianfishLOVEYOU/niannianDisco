local item = require "src.item.item"
local lightShader = require("src.shader.lightPointEffect")
local darkAmbient = item:extend()

function darkAmbient:init(x, y)
    -- 初始化子类特有属性
    self.type = "darkAmbient"
    if lightShader.isCreatShader then
        lightShader.setAmbient({1, 1, 1}, 0.2)
    end
    self.w = 32
    self.h = 32
    self.color = {1, 0, 0}
end



function darkAmbient:destroy()
    darkAmbient.super.destroy(self)
    lightShader.setAmbient({1, 1, 1}, 1)
end

return darkAmbient
