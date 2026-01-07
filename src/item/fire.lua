--全局变暗
local imageItem = require "src.item.imageItem"
local lightShader = require("src.shader.lightPointEffect")

local fire = imageItem:extend()

function fire:init(x, y, w, h, imgPath)
    -- 初始化子类特有属性
    self.type = "fire"

    self:setImage("res/image/fire.png")
    self:setQuadAnimation(3, 3, 8, 0.1)

    -- 创建点光源
    if lightShader.isCreatShader then
        lightShader.addPointLight({ x = x, y = y, r = 1, g = 0.5, b = 0, radius = 350, intensity = 0.8 })
    end
end

function fire:update(dt)
    --父类的方法执行
    fire.super.update(self,dt)
    
end

return fire
