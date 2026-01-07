local KeybordManager={}

---注册---
function KeybordManager:keypressed_regester(func)
    print("press regester")
    eventManager:on("event_keypressed",func)
end


---调用---
function love.keypressed(keyPressed)
    eventManager:emit("event_keypressed",keyPressed)
end


return KeybordManager















