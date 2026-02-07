-- screenAdapter.lua - LOVE2D安卓屏幕自适应模块
-- 适配所有手机屏幕尺寸，自动缩放游戏内容

local screenAdapter = {
    -- 1. 设定游戏基础分辨率（推荐720×1280，适配大多数安卓手机）
    baseWidth = 720,
    baseHeight = 1280,
    
    -- 缩放比例（自动计算）
    scaleX = 1,
    scaleY = 1,
    scale = 1, -- 统一缩放比例（取X/Y中较小值，避免内容超出屏幕）
    
    -- 屏幕偏移（处理宽高比差异，让内容居中）
    offsetX = 0,
    offsetY = 0
}

-- 初始化屏幕适配（在love.load中调用）
function screenAdapter.init()
    -- 获取安卓手机真实屏幕尺寸
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- 计算X/Y方向的缩放比例
    screenAdapter.scaleX = screenWidth / screenAdapter.baseWidth
    screenAdapter.scaleY = screenHeight / screenAdapter.baseHeight
    
    -- 取最小缩放比例，保证游戏内容完全显示在屏幕内
    screenAdapter.scale = math.min(screenAdapter.scaleX, screenAdapter.scaleY)
    
    -- 计算偏移量（让游戏内容在屏幕中居中）
    screenAdapter.offsetX = (screenWidth - screenAdapter.baseWidth * screenAdapter.scale) / 2
    screenAdapter.offsetY = (screenHeight - screenAdapter.baseHeight * screenAdapter.scale) / 2
    
    -- 打印适配信息（调试用，安卓端可通过日志查看）
    print(string.format(
        "屏幕适配：手机分辨率(%dx%d)，基础分辨率(%dx%d)，缩放比例=%.2f，偏移=(%d,%d)",
        screenWidth, screenHeight,
        screenAdapter.baseWidth, screenAdapter.baseHeight,
        screenAdapter.scale,
        screenAdapter.offsetX, screenAdapter.offsetY
    ))
end

-- 开始适配绘制（在love.draw最顶部调用）
function screenAdapter.start()
    -- 保存当前绘制状态
    love.graphics.push()
    
    -- 平移+缩放：让游戏内容居中且按比例缩放
    love.graphics.translate(screenAdapter.offsetX, screenAdapter.offsetY)
    love.graphics.scale(screenAdapter.scale, screenAdapter.scale)
    
    -- 可选：设置裁剪区域，防止内容超出屏幕
    love.graphics.setScissor(
        screenAdapter.offsetX,
        screenAdapter.offsetY,
        screenAdapter.baseWidth * screenAdapter.scale,
        screenAdapter.baseHeight * screenAdapter.scale
    )
end

-- 结束适配绘制（在love.draw最底部调用）
function screenAdapter.finish()
    -- 恢复裁剪区域
    love.graphics.setScissor()
    
    -- 恢复绘制状态
    love.graphics.pop()
end

-- 适配后的坐标转换（将基础分辨率坐标转为手机屏幕坐标，可选）
function screenAdapter.getAdaptedPos(x, y)
    return x * screenAdapter.scale + screenAdapter.offsetX,
           y * screenAdapter.scale + screenAdapter.offsetY
end

-- 适配后的触摸坐标转换（安卓触摸事件用，关键！）
function screenAdapter.getTouchPos(touchX, touchY)
    -- 将手机屏幕的触摸坐标，转换为游戏基础分辨率的坐标
    return (touchX - screenAdapter.offsetX) / screenAdapter.scale,
           (touchY - screenAdapter.offsetY) / screenAdapter.scale
end

return screenAdapter






-- main.lua
-- 1. 引入屏幕适配模块和调试模块（之前的debugManager）
local screenAdapter = require("src.manager.screenAdapter")
local debugManager = require("src.debug.debugManager")

-- 2. 初始化
function love.load()
    -- 先初始化屏幕适配（必须最先执行）
    screenAdapter.init()
    
    -- 初始化调试模块
    debugManager.init()
    
    -- 你的游戏资源加载（示例：加载一张图片）
    gameImage = love.graphics.newImage("assets/background.png")
    
    -- 你的游戏变量初始化
    playerX = 360 -- 基础分辨率下的X坐标（720/2）
    playerY = 640 -- 基础分辨率下的Y坐标（1280/2）
end

-- 3. 游戏更新
function love.update(dt)
    -- 你的游戏逻辑（比如移动玩家）
    if love.keyboard.isDown("right") then
        playerX = playerX + 200 * dt -- 基于基础分辨率的移动速度
    end
    if love.keyboard.isDown("left") then
        playerX = playerX - 200 * dt
    end
end

-- 4. 游戏绘制（核心：包裹在screenAdapter.start/finish之间）
function love.draw()
    -- 开始屏幕适配（所有绘制内容都放在这之后）
    screenAdapter.start()
    
    -- ********** 你的所有绘制代码 **********
    -- 示例1：绘制背景（基础分辨率720×1280）
    love.graphics.draw(gameImage, 0, 0, 0, 
        screenAdapter.baseWidth / gameImage:getWidth(), 
        screenAdapter.baseHeight / gameImage:getHeight()
    )
    
    -- 示例2：绘制玩家（坐标基于基础分辨率）
    love.graphics.setColor(1, 0, 0)
    love.graphics.circle("fill", playerX, playerY, 50)
    
    -- 示例3：绘制文字（基础分辨率下的坐标）
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("自适应屏幕测试", 10, 10, 0, 2, 2)
    -- *************************************
    
    -- 结束屏幕适配
    screenAdapter.finish()
    
    -- 绘制调试信息（错误日志）
    debugManager.draw()
end

-- 5. 适配安卓触摸事件（关键！）
function love.touchpressed(id, touchX, touchY)
    -- 将手机触摸坐标转换为游戏基础分辨率坐标
    local gameX, gameY = screenAdapter.getTouchPos(touchX, touchY)
    
    -- 示例：点击玩家区域（基础分辨率下的判断）
    local dx = gameX - playerX
    local dy = gameY - playerY
    if dx*dx + dy*dy < 50*50 then
        print("点击了玩家！游戏坐标：" .. gameX .. "," .. gameY)
    end
    
    -- 调试模块的触摸清除错误逻辑
    if gameX > screenAdapter.baseWidth - 100 and gameY > screenAdapter.baseHeight - 100 then
        debugManager.clearError()
    end
end

-- 6. 适配窗口大小变化（可选，安卓横竖屏切换时生效）
function love.resize(w, h)
    screenAdapter.init() -- 重新计算适配参数
end