
------修改console debug字体----
local ffi = require "ffi"
ffi.cdef [[
    int SetConsoleOutputCP(unsigned int wCodePageID);
]]
ffi.C.SetConsoleOutputCP(65001) -- 936 = GBK  65001 =utf-8


------设置为全局默认字体-----
myFont = love.graphics.newFont("fonts/heiti.ttf", 14)
smallFont = love.graphics.newFont("fonts/heiti.ttf", 10)
BigFont = love.graphics.newFont("fonts/heiti.ttf", 18)
love.graphics.setFont(myFont)