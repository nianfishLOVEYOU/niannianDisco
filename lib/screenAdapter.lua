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


