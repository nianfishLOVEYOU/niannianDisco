function love.conf(t)
    
    t.identity = "nianListenStream"  -- 固定名称，避免使用默认的 "lovegame"
    t.window.title = "nianListenStream"
    t.window.width = 600
    t.window.height = 450
    t.window.resizable = true
    t.modules.audio = true
    t.modules.sound = true
    t.modules.math = true
    t.modules.timer = true
    t.console = true
end