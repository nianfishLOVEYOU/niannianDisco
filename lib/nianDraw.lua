local nianDraw = {
    depthCanvas = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight()),
    finalCanvas = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight()),
    drawObjects = {},         -- 存储所有要渲染的对象
    drawByShaderObjects = {}, -- 存储使用特定shader渲染的对象
    shader = nil              -- 深度裁剪着色器
}
-- 设置画布过滤模式为最近邻
nianDraw.depthCanvas:setFilter("nearest", "nearest")
nianDraw.finalCanvas:setFilter("nearest", "nearest")

-- 创建深度测试着色器
nianDraw.shader = love.graphics.newShader([[

extern sampler2D deeptexture;
extern float depth;
extern float z;
extern float layer;
extern float writeDepth;
extern vec2 screenSize;
extern int mode;  // 0:只测试不写入，1:测试并写入

vec4 effect(vec4 color, Image texture, vec2 texcoord, vec2 pixcoord) {

    vec4 pixel = Texel(texture, texcoord);
    vec4 pixeldeep = Texel(deeptexture, pixcoord/screenSize) ;


    bool canPrint=false;
    float diff =0.005;

    

    if (mode == 0) {
        // 深度测试模式：如果当前深度 >= 比较深度，则显示
        //depth只能大不能小
        if (abs(layer - pixeldeep.b) <= diff && abs(z - pixeldeep.g) <= diff && 
        depth >= pixeldeep.r-diff) {
            canPrint = true;
        }

        if (canPrint){
            return pixel;
        } else{
            return vec4(0.0, 0.0, 0.0, 0.0); 
        }
          
    } else {

        bool canPrint=false;

        // 1. 比较 Layer（最高优先级）
        if (layer > pixeldeep.b + diff) {
            // 当前 layer 明显高于缓冲区 layer，直接通过
            canPrint = true;
        }
        else if (abs(layer - pixeldeep.b) <= diff) {
            // Layer 基本相等，比较 Z（第二优先级）
            if (z > pixeldeep.g + diff) {
                canPrint = true;
            }
            else if (abs(z - pixeldeep.b) <= diff) {
                
                // Z 也基本相等，比较 Depth（最低优先级）
                if (depth > pixeldeep.r - diff) {
                    canPrint = true;
                }
            }
        }
    
        // 深度写入模式：写入新的深度值
        if (canPrint){
            return vec4( depth, z, layer, pixel.a);
        } else{
            return vec4(0.0, 0.0, 0.0, 0.0);  // 丢弃像素
        }
    }
}
]])


local function drawObject(obj)
    love.graphics.setColor(obj.drawInfo.color)
    if obj.drawInfo.type == "rect" then
        love.graphics.rectangle(unpack(obj.drawInfo.parameters))
    elseif obj.drawInfo.type == "circle" then
        love.graphics.circle(unpack(obj.drawInfo.parameters))
    elseif obj.drawInfo.type == "print" then
        love.graphics.print(unpack(obj.drawInfo.parameters))
    elseif obj.drawInfo.type == "draw" then
        love.graphics.draw(unpack(obj.drawInfo.parameters))
    end
end

function nianDraw:renderDepthCanvas()
    love.graphics.setCanvas(self.depthCanvas)
    love.graphics.clear(0, 0, 0, 0) -- 初始深度为0（最远）
    love.graphics.setCanvas()
    love.graphics.setShader(self.shader)
    self.shader:send("screenSize", { love.graphics.getWidth(), love.graphics.getHeight() })

    -- 深度绘制
    for _, obj in ipairs(self.drawObjects) do
        self.shader:send("deeptexture", self.depthCanvas)
        self.shader:send("depth", obj.drawInfo.depth)
        self.shader:send("z", obj.drawInfo.z)
        self.shader:send("layer", obj.drawInfo.layer)
        self.shader:send("mode", 1) -- 写入模式
        --设置画布
        love.graphics.setCanvas({
            self.depthCanvas,
            stencil = true
        })
        -- 写入深度图深度值
        drawObject(obj)
        love.graphics.setCanvas()
    end
    love.graphics.setShader()
end

function nianDraw:drawFinal()
    love.graphics.setShader(self.shader)
    -- 深度测试 场景绘制
    for _, obj in ipairs(self.drawObjects) do
        self.shader:send("deeptexture", self.depthCanvas)
        self.shader:send("depth", obj.drawInfo.depth)
        self.shader:send("z", obj.drawInfo.z)
        self.shader:send("layer", obj.drawInfo.layer)
        self.shader:send("mode", 0) -- 只测试不写入
        -- 写入深度图深度值
        drawObject(obj)
    end
    love.graphics.setShader()

    -- 用自带shader绘制的对象
    for _, obj in ipairs(self.drawByShaderObjects) do
        love.graphics.setShader(obj.shader)
        drawObject(obj)
        love.graphics.setShader()
    end

    self.drawObjects = {}        -- 清空渲染列表
    self.drawByShaderObjects = {} -- 清空渲染列表
end

function nianDraw:drawReg(drawInfo)
    table.insert(nianDraw.drawObjects, {
        drawInfo = drawInfo,
    })
end

function nianDraw:drawByShaderReg(drawInfo, shader)
    -- 使用特定shader绘制
    drawInfo.z=drawInfo.z or 0
    drawInfo.layer=drawInfo.layer or 0
    local shader = shader or nil
    table.insert(nianDraw.drawObjects, {
        drawInfo = drawInfo,
        shader = shader
    })
end

return nianDraw
