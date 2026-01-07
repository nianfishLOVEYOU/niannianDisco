
local ShaderEffect = require("src.shader.shaderEffect")

local BlurEffect={}
function BlurEffect.getshader()
    local shaderCode = [[
        extern vec2 screenSize;
        extern float blurRadius;
        extern int blurSamples;
        extern int blurType;  // 0=高斯, 1=方框, 2=径向
        
        vec4 effect(vec4 color, Image texture, vec2 texcoord, vec2 pixcoord) {
            vec2 texelSize = 1.0 / screenSize;
            vec4 result = vec4(0.0);
            
            if (blurType == 0) {
                // 高斯模糊
                float weight = 0.0;
                float radius = blurRadius;
                
                for (int x = -blurSamples; x <= blurSamples; x++) {
                    for (int y = -blurSamples; y <= blurSamples; y++) {
                        float dist = sqrt(float(x*x + y*y));
                        float w = exp(-dist * dist / (2.0 * radius * radius));
                        result += Texel(texture, texcoord + vec2(x, y) * texelSize) * w;
                        weight += w;
                    }
                }
                result /= weight;
            } else if (blurType == 1) {
                // 方框模糊
                for (int x = -blurSamples; x <= blurSamples; x++) {
                    for (int y = -blurSamples; y <= blurSamples; y++) {
                        result += Texel(texture, texcoord + vec2(x, y) * texelSize);
                    }
                }
                float samples = float((blurSamples*2+1)*(blurSamples*2+1));
                result /= samples;
            }
            
            return result * color;
        }
    ]]
    local shadereffect =ShaderEffect:new( shaderCode, "Blur")
    shadereffect:aa()
    shadereffect:setUniform("blurRadius", 2.0)
    shadereffect:setUniform("blurSamples", 5)
    shadereffect:setUniform("blurType", 0)
    return shadereffect
end

return BlurEffect