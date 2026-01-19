-- 渲染类型有两种
-- 伽马空间（Gamma）：默认模式，计算快但色彩精度低，适合手机等性能有限的平台；
-- 线性空间（Linear）：物理更准确，光照、后处理效果更真实，但对纹理 / 计算要求更高，性能消耗大。

-- HDRRenderer.lua - HDR（高动态范围）渲染接口模块
-- 核心功能：小尺寸浮点Canvas计算HDR颜色，拉伸渲染到全屏，保留高亮度细节
local HDRRenderer = {}
HDRRenderer.__index = HDRRenderer

-- 默认配置（贴合HDR渲染规范）
local DEFAULT_CONFIG = {
    hdrCanvasSize = {width = 400, height = 300},  -- HDR计算用的小尺寸Canvas（越小性能越好）
    hdrFormat = "rgba16f",                        -- HDR Canvas浮点格式：rgba16f(平衡)/rgba32f(高精度)
    textureFilter = "linear",                     -- 纹理过滤：linear(平滑放大)/nearest(像素风格)
    hdrComputeShader = nil,                       -- 自定义HDR颜色计算着色器（GPU端线性计算）
    toneMapShader = nil                           -- 自定义色调映射着色器（HDR→LDR转换）
}

-- 默认HDR计算着色器（GPU端线性计算，支持无限大亮度值）
local DEFAULT_HDR_COMPUTE_SHADER = [[
    uniform float time;
    vec4 position(mat4 transform_projection, vec4 vertex_position) {
        return transform_projection * vertex_position;
    }
    vec4 effect(vec4 color, Image texture, vec2 tex_coords, vec2 screen_coords) {
        // HDR原色定义（亮度值>1，线性空间）
        vec3 hdrRed = vec3(3.0, 0.2, 0.2);    // 高亮度红色（亮度≈3倍标准白）
        vec3 hdrBlue = vec3(0.3, 0.4, 2.5);   // 高亮度蓝色（亮度≈2.5倍标准白）
        
        // 动态混合HDR颜色（线性插值，保留HDR细节）
        float blendFactor = sin(time) * 0.5 + 0.5;
        vec3 linearHDR = mix(hdrRed, hdrBlue, blendFactor);

        // 叠加HDR高光（模拟真实场景的高亮度区域，亮度进一步提升）
        float highlight = pow(sin(screen_coords.x / 50.0) * cos(screen_coords.y / 50.0), 4.0) * 4.0;
        linearHDR += vec3(highlight);

        // 输出未钳制的HDR颜色（浮点Canvas完整存储）
        return vec4(linearHDR, 1.0);
    }
]]

-- 默认色调映射着色器（行业标准ACES映射，HDR→LDR（0-1），保留高光细节）
local DEFAULT_TONE_MAP_SHADER = [[
    vec4 position(mat4 transform_projection, vec4 vertex_position) {
        return transform_projection * vertex_position;
    }
    vec4 effect(vec4 color, Image texture, vec2 tex_coords, vec2 screen_coords) {
        // 从HDR Canvas读取未钳制的线性HDR颜色
        vec4 hdrColor = Texel(texture, tex_coords);
        
        // ACES色调映射（电影级标准，比Reinhard更自然）
        vec3 aces = hdrColor.rgb * (0.9 * hdrColor.rgb + 0.05) / (hdrColor.rgb * (0.9 * hdrColor.rgb + 0.5) + 0.04);
        // 伽马校正（线性空间→伽马空间，匹配显示器输出）
        vec3 ldrColor = pow(aces, vec3(1.0/2.2));
        
        return vec4(ldrColor, hdrColor.a);
    }
]]

-- 【核心接口1】创建HDR渲染器实例
-- 参数：customConfig - 自定义配置表，可选覆盖默认配置
function HDRRenderer.new(customConfig)
    local self = setmetatable({}, HDRRenderer)
    
    -- 合并默认配置与自定义配置
    self.config = table.merge(DEFAULT_CONFIG, customConfig or {})
    
    -- 1. 创建HDR专用浮点Canvas（核心：支持存储>1的亮度值）
    self.hdrCanvas = love.graphics.newCanvas(
        self.config.hdrCanvasSize.width, 
        self.config.hdrCanvasSize.height, 
        {
            format = self.config.hdrFormat,
            readable = true  -- 允许读取Canvas内容用于后续渲染
        }
    )
    
    -- 2. 初始化着色器（优先使用自定义，否则用默认）
    self.hdrComputeShader = love.graphics.newShader(self.config.hdrComputeShader or DEFAULT_HDR_COMPUTE_SHADER)
    self.toneMapShader = love.graphics.newShader(self.config.toneMapShader or DEFAULT_TONE_MAP_SHADER)
    
    -- 3. 设置纹理过滤（影响HDR Canvas放大后的视觉效果）
    love.graphics.setDefaultFilter(self.config.textureFilter, self.config.textureFilter)
    
    -- 4. 初始化窗口尺寸（用于拉伸渲染）
    self.windowWidth = love.graphics.getWidth()
    self.windowHeight = love.graphics.getHeight()
    
    return self
end

-- 【核心接口2】更新HDR渲染器
-- 参数：uniforms - 着色器uniform参数表（如 {time = 1.0, intensity = 2.0}）
function HDRRenderer:update(uniforms)
    -- 自动适配窗口尺寸变化
    self.windowWidth = love.graphics.getWidth()
    self.windowHeight = love.graphics.getHeight()
    
    -- 传递uniform参数到HDR计算着色器（支持动态调整HDR参数）
    if uniforms and type(uniforms) == "table" then
        for paramName, paramValue in pairs(uniforms) do
            self.hdrComputeShader:send(paramName, paramValue)
        end
    end
end

-- 【核心接口3】渲染HDR内容到全屏
-- 内部流程：HDR计算（小Canvas）→ 色调映射 → 拉伸到全屏
function HDRRenderer:draw()
    -- 第一步：在小尺寸HDR Canvas中完成线性HDR计算（无亮度钳制）
    love.graphics.setCanvas(self.hdrCanvas)
    love.graphics.clear(0, 0, 0, 0)  -- 清空HDR Canvas（黑色背景）
    love.graphics.setShader(self.hdrComputeShader)
    -- 绘制全屏矩形触发HDR计算（仅在小Canvas尺寸下计算，性能稳定）
    love.graphics.rectangle("fill", 0, 0, self.hdrCanvas:getWidth(), self.hdrCanvas:getHeight())
    love.graphics.setShader()
    love.graphics.setCanvas()  -- 恢复到屏幕渲染
    
    -- 第二步：将HDR Canvas拉伸渲染到全屏（并完成色调映射）
    love.graphics.setShader(self.toneMapShader)
    local scaleX = self.windowWidth / self.hdrCanvas:getWidth()  -- X轴缩放比例
    local scaleY = self.windowHeight / self.hdrCanvas:getHeight() -- Y轴缩放比例
    love.graphics.draw(self.hdrCanvas, 0, 0, 0, scaleX, scaleY)
    love.graphics.setShader()
end

-- 【辅助接口】销毁HDR渲染器（释放GPU资源）
function HDRRenderer:destroy()
    if self.hdrCanvas then self.hdrCanvas:release() end
    if self.hdrComputeShader then self.hdrComputeShader:release() end
    if self.toneMapShader then self.toneMapShader:release() end
end

-- 工具函数：表合并（Lua标准库无此函数，补充实现）
function table.merge(t1, t2)
    local merged = {}
    for k, v in pairs(t1) do merged[k] = v end
    for k, v in pairs(t2 or {}) do merged[k] = v end
    return merged
end


--------------------------------------------------
---------------------使用 ------------------------
--------------------------------------------------

-- main.lua - HDR渲染器使用示例
local HDRRenderer = require("HDRRenderer")

local hdrRenderer  -- HDR渲染器实例

function love.load()
    -- 1. 自定义HDR配置（可选）
    local hdrConfig = {
        hdrCanvasSize = {width = 320, height = 180},  -- 更小的HDR Canvas，更低渲染压力
        textureFilter = "linear",                     -- 平滑放大
        -- 可选：替换为自定义HDR计算着色器
        -- hdrComputeShader = [[你的自定义HDR着色器代码]],
        -- 可选：替换为自定义色调映射着色器
        -- toneMapShader = [[你的自定义色调映射代码]]
    }
    
    -- 2. 创建HDR渲染器实例
    hdrRenderer = HDRRenderer.new(hdrConfig)
end

function love.update(dt)
    -- 3. 更新HDR渲染器：传递time参数（驱动HDR颜色动态变化）
    hdrRenderer:update({
        time = love.timer.getTime()
    })
end

function love.draw()
    -- 4. 渲染HDR内容到全屏
    hdrRenderer:draw()
    
    -- 调试信息（可选）
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("HDR Canvas尺寸：" .. hdrRenderer.hdrCanvas:getWidth() .. "x" .. hdrRenderer.hdrCanvas:getHeight(), 10, 10)
    love.graphics.print("屏幕尺寸：" .. love.graphics.getWidth() .. "x" .. love.graphics.getHeight(), 10, 30)
    love.graphics.print("HDR格式：" .. hdrRenderer.config.hdrFormat, 10, 50)
end

-- 窗口大小变化自动适配
function love.resize(w, h)
    -- 无需额外代码，hdrRenderer:update()会自动处理
end

-- 退出时释放资源
function love.quit()
    hdrRenderer:destroy()
end
return HDRRenderer


