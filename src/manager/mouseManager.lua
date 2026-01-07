local mouseManager={}

---注册---
function mouseManager:mousepressed_regester(func)
    print("press regester")
    eventManager:on("event_mousePressed",func)
end

function mouseManager:mouseLeased_regester(func)
    eventManager:on("event_mouseLeased",func)
end

function mouseManager:mouseMoved_regester(func)
    eventManager:on("event_mouseMoved",func)
end

function mouseManager:wheelMoved_regester(func)
    eventManager:on("event_wheelMoved",func)
end


---调用---
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

return mouseManager















