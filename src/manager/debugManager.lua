-- debugManager.lua - LOVE2D安卓全局错误捕获模块
-- 功能：捕获所有错误、保存日志、屏幕显示错误、不中断游戏

local debugManager = {
    -- 错误信息存储
    errorLog = "",
    errorTime = "",
    isError = false,
    -- 安卓日志保存路径（LOVE2D安卓版可读写的路径）
    logPath = love.filesystem.getSaveDirectory() .. "/game_error.log",
    -- 屏幕显示错误的样式配置
    drawConfig = {
        x = 10,
        y = 10,
        width = love.graphics.getWidth() - 20,
        height = love.graphics.getHeight() - 20,
        font = love.graphics.newFont(14), -- 安卓适配的小字体
        color = {1, 0.2, 0.2, 0.9}, -- 红色半透明
        bgColor = {0, 0, 0, 0.8} -- 黑色背景
    }
}

-- 初始化：重写LOVE2D全局错误处理函数
function debugManager.init()
    -- 备份原始错误处理函数（可选恢复）
    debugManager.originalErrhand = love.errhand
    
    -- 重写全局错误处理
    love.errhand = function(msg)
        -- 1. 格式化错误信息（包含时间）
        local currentTime = os.date("%Y-%m-%d %H:%M:%S")
        debugManager.errorTime = currentTime
        debugManager.errorLog = string.format(
            "[%s] 错误信息：%s\n调用栈：\n%s",
            currentTime,
            tostring(msg),
            debug.traceback() -- 获取完整调用栈
        )
        
        -- 2. 标记有错误
        debugManager.isError = true
        
        -- 3. 保存错误日志到文件（安卓本地）
        debugManager.saveLog()
        
        -- 4. 打印到控制台（电脑端可见，安卓端可通过adb logcat查看）
        print("[GAME ERROR] " .. debugManager.errorLog)
        
        -- 5. 不中断游戏：注释掉默认的崩溃退出逻辑
        -- love.event.quit() -- 禁用默认退出
        return debugManager.originalErrhand(msg)
    end

    -- 额外：捕获require/函数调用的局部错误（可选）
    -- 封装安全调用函数，用于包裹可能出错的代码
    function debugManager.safeCall(func, ...)
        local args = {...}
        return xpcall(function()
            return func(unpack(args))
        end, function(err)
            -- 局部错误也记录到全局日志
            local errMsg = string.format("[局部错误] %s\n%s", err, debug.traceback())
            debugManager.errorLog = debugManager.errorLog .. "\n" .. errMsg
            debugManager.saveLog()
            debugManager.isError = true
            print(errMsg)
        end)
    end
end

-- 保存错误日志到安卓文件
function debugManager.saveLog()
    -- LOVE2D安卓版需要先创建文件（如果不存在）
    if not love.filesystem.getInfo(debugManager.logPath) then
        love.filesystem.write(debugManager.logPath, "游戏错误日志\n====================\n")
    end
    
    -- 追加错误信息到日志文件
    local logContent = "\n" .. debugManager.errorLog .. "\n====================\n"
    love.filesystem.append(debugManager.logPath, logContent)
end

-- 屏幕绘制错误信息（在draw函数中调用）
function debugManager.draw()
    if not debugManager.isError or debugManager.errorLog == "" then
        return -- 无错误则不绘制
    end

    -- 绘制背景框
    love.graphics.setColor(debugManager.drawConfig.bgColor)
    love.graphics.rectangle(
        "fill",
        debugManager.drawConfig.x,
        debugManager.drawConfig.y,
        debugManager.drawConfig.width,
        debugManager.drawConfig.height
    )

    -- 绘制错误文本（自动换行）
    love.graphics.setColor(debugManager.drawConfig.color)
    love.graphics.setFont(debugManager.drawConfig.font)
    
    -- 拆分文本为多行（适配屏幕宽度）
    local maxWidth = debugManager.drawConfig.width - 10
    local lines = {}
    local currentLine = ""
    for word in string.gmatch(debugManager.errorLog, "%S+") do
        local testLine = currentLine .. " " .. word
        if love.graphics.getFont():getWidth(testLine) > maxWidth then
            table.insert(lines, currentLine)
            currentLine = word
        else
            currentLine = testLine
        end
    end
    table.insert(lines, currentLine)

    -- 逐行绘制
    local y = debugManager.drawConfig.y + 5
    for i, line in ipairs(lines) do
        if y > debugManager.drawConfig.y + debugManager.drawConfig.height - 20 then
            break -- 超出高度则停止绘制
        end
        love.graphics.print(line, debugManager.drawConfig.x + 5, y)
        y = y + 20 -- 行间距
    end
end

-- 清除错误信息（可选：游戏内手动调用）
function debugManager.clearError()
    debugManager.errorLog = ""
    debugManager.isError = false
end

-- 读取错误日志文件内容（可选）
function debugManager.getLogContent()
    if love.filesystem.getInfo(debugManager.logPath) then
        return love.filesystem.read(debugManager.logPath)
    else
        return "暂无错误日志"
    end
end

return debugManager