function love.conf(t)
    
    t.identity = "nianListenStream"  -- 固定名称，避免使用默认的 "lovegame"  用来存储的位置名称
    t.window.title = "nianListenStream"
    t.window.width = 600
    t.window.height = 450
    t.window.resizable = true  -- 禁止调整窗口大小
    t.modules.audio = true
    t.modules.sound = true
    t.modules.math = true
    t.modules.timer = true
    t.console = true
end