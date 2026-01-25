--全局变暗
local imageItem = require "src.item.imageItem"
local lightShader = require("src.shader.lightPointEffect")

local fire = imageItem:extend()

function fire:init(imgPath)
    -- 初始化子类特有属性
    self.type = "fire"

    self:setImage("res/image/fire.png")
    self:setQuadAnimation(3, 3, 8, 0.1)
    self.color ={ 1, 0.5, 0}
    -- 创建点光源
    if lightShader.isCreatShader then
       self.light = lightShader.addPointLight({ radius = 350, intensity =0.9})
    end
end

function fire:setPos(x,y,z)
    fire.super.setPos(self,x,y,z)
    self.light.x,self.light.y=x,y
end



-- 全局参数配置（可调整效果）
local noiseParams = {
    baseSpeed = 0.05,        -- 基础噪声流动速度（越小越稳定）
    noiseScale = 0.2,      -- 噪声缩放（越小越平滑）
    minBrightness = 0.6,    -- 基础最小亮度（0-1）
    maxBrightness = 1,    -- 基础最大亮度（0-1）
    darkChance = 0.004,      -- 突发变暗的概率（每帧触发概率，0.02=2%）
}

-- 生成稳定的噪声亮度值（核心函数）
function fire:getFireBrightness(x, y,time)

    -- 3. 生成柏林噪声（稳定平滑的基础亮度）
    -- love.math.noise 是LÖVE2D内置的柏林噪声，返回0-1的稳定值
    local noiseValue = love.math.noise(
        x * noiseParams.noiseScale,
        y * noiseParams.noiseScale+time 
        
    )

    local randomDark = math.random()<noiseParams.darkChance and 0.1 or 0

    -- 4. 将噪声值映射到亮度区间（minBrightness ~ maxBrightness）
    local brightness = noiseParams.minBrightness + 
                       (noiseParams.maxBrightness - noiseParams.minBrightness) * noiseValue

    return brightness-randomDark
end

function fire:update(dt)
    self.light.intensity=fire:getFireBrightness(0,0,love.timer.getTime()*noiseParams.baseSpeed)
    self.light.radius=100+350 *self.light.intensity
    --设置灯光颜色
    self.light.r,self.light.g,self.light.b=self.color[1],self.color[2],self.color[3]
    --父类的方法执行
    fire.super.update(self,dt)
    
end

return fire
