------修改console debug字体----
if love.system.getOS and love.system.getOS() == "Windows" then
    local ffi = require "ffi"
    ffi.cdef [[
        int SetConsoleOutputCP(unsigned int wCodePageID);
    ]]
    ffi.C.SetConsoleOutputCP(65001) -- 936 = GBK  65001 =utf-8
end

------设置为全局默认字体-----
myFont = love.graphics.newFont("fonts/heiti.ttf", 12)
love.graphics.setFont(myFont)