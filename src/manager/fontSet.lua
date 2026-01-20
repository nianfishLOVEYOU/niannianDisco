
------修改console debug字体----
local ffi = require "ffi"
ffi.cdef [[
    int SetConsoleOutputCP(unsigned int wCodePageID);
]]
ffi.C.SetConsoleOutputCP(65001) -- 936 = GBK  65001 =utf-8