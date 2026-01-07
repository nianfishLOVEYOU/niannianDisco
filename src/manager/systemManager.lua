local systemManager={

}

---注册---
function systemManager:init_regester(func)
    eventManager:on("init",func)
end

function systemManager:update_regester(func)
    eventManager:on("update",func)
end

function systemManager:draw_regester(func)
    eventManager:on("draw",func)
end

function systemManager:camdraw_regester(func)
    eventManager:on("camdraw",func)
end

function systemManager:quit_regester(func)
    eventManager:on("quit",func)
end

---调用---
function systemManager:init()
    eventManager:emit("init")
end

function systemManager:update(dt)
    eventManager:emit("update",dt)
end

function systemManager:draw()
    eventManager:emit("draw")
end

function systemManager:camdraw()
    eventManager:emit("camdraw")
end

function systemManager:quit()
    eventManager:emit("quit")
end

return systemManager