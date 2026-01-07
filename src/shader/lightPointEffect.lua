-- 全局配置
local ShaderEffect = require("src.shader.shaderEffect")


local lightPointEffect = { isCreatShader = false }
local pointLights = {}   -- 点光源列表
local lightMaxCount = 32 -- 最大支持光源数（可根据性能调整）
local shadereffect = nil

local function drawFunc(canvas)
    love.graphics.draw(canvas, 0, 0)
end

function lightPointEffect.getshader()
    local lightShader = love.graphics.newShader(string.format([[
        // 全局参数
        uniform vec2 screenSize;
        uniform vec3 ambientColor; // 环境光
        uniform float ambientIntensity;

        // 点光源结构体（与Lua端对应）
        struct PointLight {
            vec2 position;   // 光源位置
            vec3 color;      // 光源颜色
            float radius;    // 光照半径
            float intensity; // 光照强度
            float falloff;   // 衰减系数（固定值）
            bool actived;     // 是否激活
        };

        // 光源数组（最大lightMaxCount个）
        uniform PointLight lights[32];

        // 片段着色器：计算每个像素的最终颜色
        vec4 effect(vec4 baseColor, Image tex, vec2 texCoord, vec2 screenCoord) {
            // 1. 获取原纹理颜色
            vec4 texColor = Texel(tex, texCoord);
            if (texColor.a < 0.1) discard; // 透明像素直接丢弃

            // 2. 环境光基础颜色
            vec3 finalColor = ambientColor * ambientIntensity;

            // 3. 遍历所有光源，计算光照贡献
            for (int i = 0; i < %d; i++) {
                if (!lights[i].actived) continue; // 跳过未激活光源

                // 计算像素到光源的距离（归一化到屏幕尺寸）
                vec2 lightPos = lights[i].position;
                float distance = length(screenCoord - lightPos);

                // 超出光照半径则跳过
                if (distance > lights[i].radius) continue;

                // 计算光照衰减（平方衰减 + 线性衰减）
                float normalizedDist = distance / lights[i].radius;
                float attenuation = 1.0 / (1.0 + lights[i].falloff * normalizedDist * normalizedDist);
                attenuation = mix(0.0, 1.0, 1.0 - normalizedDist) * attenuation;

                // 计算该光源对当前像素的颜色贡献
                vec3 lightContribution = lights[i].color * lights[i].intensity * attenuation;
                finalColor += lightContribution;
            }

            // 4. 混合最终颜色（保留Alpha）
            finalColor = clamp(finalColor, 0.0, 1.0); // 防止过亮
            return vec4(finalColor * texColor.rgb * baseColor.rgb, texColor.a * baseColor.a);
        }
    ]], lightMaxCount, lightMaxCount))



    shadereffect = ShaderEffect:new(lightShader, "Blur", drawFunc)

    shadereffect:setUniform("ambientColor", { 0.2, 0.2, 0.2 }) -- 环境光颜色（暗灰色）
    shadereffect:setUniform("ambientIntensity", 0.3)           -- 环境光强度
    shadereffect.setScreenSize = false
    --lightShader:send("screenSize", {screenW, screenH})

    lightPointEffect.addPointLight({ x = 200, y = 200, r = 1, g = 0.5, b = 0, radius = 350, intensity = 0.8 })

    systemManager:update_regester(lightPointEffect.lightUpdate)

    lightPointEffect.isCreatShader = true
    return shadereffect
end

--设置环境光
function lightPointEffect.setAmbient(color, light)
    shadereffect:setUniform("ambientColor",color)     -- 环境光颜色（暗灰色）
    shadereffect:setUniform("ambientIntensity", light)               -- 环境光强度
end

-- ===================== 光源操作接口（核心） =====================
-- 添加点光源（返回光源ID，用于后续移除）
function lightPointEffect.addPointLight(params)
    -- 默认参数
    local light = {
        id = #pointLights + 1,
        x = params.x or 0,
        y = params.y or 0,
        r = params.r or 1.0,
        g = params.g or 1.0,
        b = params.b or 1.0,
        radius = params.radius or 100,
        intensity = params.intensity or 1.0,
        falloff = 2.0, -- 固定衰减系数（可自定义）
        actived = true
    }
    table.insert(pointLights, light)
    lightPointEffect.updateShaderLights() -- 更新着色器光源数据
    return light.id
end

-- 移除指定ID的点光源
function lightPointEffect.removePointLight(lightId)
    for i, light in ipairs(pointLights) do
        if light.id == lightId then
            light.actived = false -- 标记为未激活（比直接删除更高效）
            -- 可选：彻底删除（需重新排序ID）
            -- table.remove(pointLights, i)
            lightPointEffect.updateShaderLights()
            return true
        end
    end
    return false
end

function lightPointEffect.removePointLightLast()
    if #pointLights > 0 then
        local lastLight = pointLights[#pointLights]
        lightPointEffect.removePointLight(lastLight.id)
        print("移除光源 ID:", lastLight.id)
    end
end

-- 更新着色器的光源数据（关键：将Lua光源同步到Shader）
function lightPointEffect.updateShaderLights()
    -- 填充光源数组（最多lightMaxCount个）
    for i = 1, lightMaxCount do
        local light = pointLights[i] or { actived = false }
        local x, y = cam:toScreen(light.x or 0, light.y or 0)
        -- 批量发送光源数据到着色器
        shadereffect:setUniform(string.format("lights[%d].position", i - 1), { x, y })
        shadereffect:setUniform(string.format("lights[%d].color", i - 1), { light.r or 0, light.g or 0, light.b or 0 })
        shadereffect:setUniform(string.format("lights[%d].radius", i - 1), light.radius or 0)
        shadereffect:setUniform(string.format("lights[%d].intensity", i - 1), light.intensity or 0)
        shadereffect:setUniform(string.format("lights[%d].falloff", i - 1), light.falloff or 0)
        shadereffect:setUniform(string.format("lights[%d].actived", i - 1), light.actived or false)
    end
end

--放在update下面做一闪一闪
function lightPointEffect.lightUpdate(dt)
    lightPointEffect.updateShaderLights()
end

function lightPointEffect.drawlightPositon()
    -- 绘制光源位置（调试）
    for _, light in ipairs(pointLights) do
        if light.actived then
            -- 绘制光源中心点
            love.graphics.setColor(light.r, light.g, light.b)
            love.graphics.circle("fill", light.x, light.y, 5)
            -- 绘制光照半径（半透明）
            love.graphics.setColor(light.r, light.g, light.b, 0.1)
            love.graphics.circle("line", light.x, light.y, light.radius)
        end
    end
end

return lightPointEffect
