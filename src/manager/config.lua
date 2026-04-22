-- 读取 .ini 配置文件
local Config = {}

-- 初始化：把 res/config.ini 复制到 save 目录（可写）
function Config.init()
    if not love.filesystem.getInfo("config.ini") then
        local default = love.filesystem.read("res/config.ini")
        love.filesystem.write("config.ini", default)
    end
end

-- 读取 INI
function Config.load()
    Config.init()
    local data = {}
    local sec = nil

    for line in love.filesystem.lines("config.ini") do
        line = line:match("^%s*(.-)%s*$")
        if line == "" or line:sub(1,1) == ";" then
        elseif line:match("^%[(.-)%]$") then
            sec = line:match("^%[(.-)%]$")
            data[sec] = data[sec] or {}
        elseif sec then
            local k, v = line:match("^(.-)%s*=%s*(.*)$")
            if k and v then
                if v == "true" then v = true
                elseif v == "false" then v = false
                else v = tonumber(v) or v end
                data[sec][k] = v
            end
        end
    end
    return data
end

-- 保存 INI
function Config.save(data)
    local lines = {}
    for sec, vals in pairs(data) do
        table.insert(lines, "["..sec.."]")
        for k, v in pairs(vals) do
            table.insert(lines, k.."="..tostring(v))
        end
    end
    love.filesystem.write("config.ini", table.concat(lines, "\n"))
end

return Config