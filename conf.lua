function love.conf(t)
    
    t.identity = "nianListenStream"  -- 固定名称，避免使用默认的 "lovegame"  用来存储的位置名称
    t.window.title = "nianListenStream"
    t.window.width = 400
    t.window.height =600
    t.window.resizable = true  -- 禁止调整窗口大小 -- 禁止自动旋转（锁定竖屏）
    t.modules.audio = true
    t.modules.sound = true
    t.modules.math = true
    t.modules.timer = true
    t.console = true

        -- 手机建议开全屏
    --t.window.fullscreen = true

end