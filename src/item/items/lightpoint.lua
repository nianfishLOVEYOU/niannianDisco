local item = require "src.item.item"
local lightShader=require("src.shader.lightPointEffect")
local LightPoint = item:extend()

function LightPoint:init(x, y)
    -- 初始化子类特有属性
    self.type = "lightpoint"
    if lightShader.isCreatShader then
       self.light = lightShader.addPointLight({ radius = 350, intensity = 0.8 })
    end
end

function LightPoint:setPos(x,y,z)
    LightPoint.super.setPos(self,x,y,z)
    self.light.x,self.light.y=x,y
end

function LightPoint:update(dt)
    --设置灯光颜色
    self.light.r,self.light.g,self.light.b=self.color[1],self.color[2],self.color[3]
    --父类的方法执行
    LightPoint.super.update(self,dt)
    
end
return LightPoint
