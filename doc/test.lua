
-------检查enet位置-------------

-- 1️⃣ 加载模块
-- local ok, enet = pcall(require, "enet")
-- if not ok then
--     print("[FAIL] require enet 失败：")
--     print(enet)               -- enet 此时是错误字符串
--     os.exit(1)
-- end
-- print("[OK] enet 加载成功")

-- -- 2️⃣ 从模块中挑选一个函数（任意一个即可）
-- local function pick_c_function(tbl)
--     for _, v in pairs(tbl) do
--         if type(v) == "function" then
--             return v
--         end
--     end
--     return nil
-- end

-- local any_func = pick_c_function(enet)
-- if not any_func then
--     print("enet 模块中未找到函数，无法定位库文件")
--     return
-- end

-- -- 3️⃣ 用 debug.getinfo 读取 source（路径）信息
-- local info = debug.getinfo(any_func, "S")   -- "S" 只返回 source 相关字段
-- if info and info.source then
--     -- source 形如 "@/usr/local/lib/lua/5.4/enet.so"（Linux/macOS）
--     -- 或   "@C:\\Program Files\\Lua\\5.4\\enet.dll"（Windows）
--     local path = info.source:match("^@(.+)$")
--     if path then
--         print("实际加载的 enet 动态库路径：", path)
--     else
--         print("source 信息不含文件路径，可能是内部 C 绑定被 strip")
--     end
-- else
--     print("debug.getinfo 未返回 source 信息")
-- end