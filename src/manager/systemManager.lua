local systemManager={

}

---注册---
function systemManager:init_regester(func)
    return eventManager:on("init",func)
end

function systemManager:update_regester(func)
    return eventManager:on("update",func)
end

function systemManager:draw_regester(func)
    return eventManager:on("draw",func)
end

function systemManager:camdraw_regester(func)
    return eventManager:on("camdraw",func)
end

function systemManager:quit_regester(func)
    return eventManager:on("quit",func)
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


-- 鼠标事件---
--注册
function systemManager:mousepressed_regester(func)
    return eventManager:on("event_mousePressed",func)
end

function systemManager:mouseLeased_regester(func)
    return eventManager:on("event_mouseLeased",func)
end

function systemManager:mouseMoved_regester(func)
    return eventManager:on("event_mouseMoved",func)
end

function systemManager:wheelMoved_regester(func)
    return eventManager:on("event_wheelMoved",func)
end

--调用
function love.mousepressed(x, y, button) 
    eventManager:emit("event_mousePressed",x,y,button)
end

function love.mousereleased(x, y, button)
    eventManager:emit("event_mouseLeased",x,y,button)
end

function love.mousemoved(x, y, dx, dy)
    eventManager:emit("event_mouseMoved",x, y, dx, dy)
end

function love.wheelmoved(x, y)
    eventManager:emit("event_wheelMoved",x, y)
end


--- 键盘事件---
---注册---
function systemManager:keypressed_regester(func)
    return eventManager:on("event_keypressed",func)
end

function systemManager:textinput_regester(func)
    return eventManager:on("event_textinput", func)
end


---调用---
function love.keypressed(keyPressed)
    eventManager:emit("event_keypressed",keyPressed)
end

function love.textinput(t)
    eventManager:emit("event_textinput", t)
end



return systemManager