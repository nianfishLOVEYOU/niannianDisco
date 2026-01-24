local KeybordManager={}

---注册---
function KeybordManager:keypressed_regester(func)
    eventManager:on("event_keypressed",func)
end

function KeybordManager:textinput_regester(func)
    eventManager:on("event_textinput", func)
end


---调用---
function love.keypressed(keyPressed)
    eventManager:emit("event_keypressed",keyPressed)
end

function love.textinput(t)
    eventManager:emit("event_textinput", t)
end


return KeybordManager















