--path


GlobleManager = {
    config ={},
    allData = {},
    map=nil, --地图
}

config=require "src.manager.config"

systemManager:init_regester(function()
    GlobleManager:init()
end)

function GlobleManager:init()
    --初始化设定，音量什么的，保存到文件
    GlobleManager.allData = fileManager:readTable("allData")
    if not self.allData then
        self.allData = {}
        fileManager:saveTable("allData", GlobleManager.allData)
    end

    -- game
    -- debug
    -- srceen
    self.config = config.load();

    print("[GlobleManager] 初始化完成，当前config：")
    for k, v in pairs(self.config) do
        print(string.format("  %s = %s", k, tostring(v)))
    end
end

-- 获取配置
function GlobleManager.getConfig(group, key)
    if GlobleManager.config[group] and GlobleManager.config[group][key] ~= nil then
        return GlobleManager.config[group][key]
    else
        print(string.format("[GlobleManager] 获取配置失败：group=%s, key=%s 不存在", tostring(group), tostring(key)))
        return nil
    end
end


-- 保存数据到本地 value 支持数字，字符串，table
function GlobleManager:saveGameData(key, value)
    -- 1. 校验key的合法性：必须是非空字符串
    if type(key) ~= "string" or key == "" then
        print(string.format("[错误] 保存数据失败：key必须是非空字符串，当前key类型=%s，值=%s", type(key), tostring(key)))
        return false -- 返回false标记保存失败
    end

    -- 2. 校验value的类型：仅允许number（整数/小数）、string、table
    local valueType = type(value)
    local allowedTypes = { ["number"] = true, ["string"] = true, ["table"] = true }
    if not allowedTypes[valueType] then
        print(string.format("[错误] 保存数据失败：key=%s 的value类型不支持（仅支持number/string/table），当前类型=%s", key, valueType))
        return false
    end

    -- 3. 特殊处理：table类型避免循环引用（防止序列化失败）
    if valueType == "table" then
        -- 简单检测：如果table包含自身引用，禁止保存（可根据需求扩展）
        if value == GlobleManager.allData or value == self then
            print(string.format("[错误] 保存数据失败：key=%s 的table包含循环引用，无法序列化", key))
            return false
        end
        -- 可选：深拷贝table，避免后续修改原table影响已保存数据
        local function deepCopy(t)
            local newT = {}
            for k, v in pairs(t) do
                if type(v) == "table" then
                    newT[k] = deepCopy(v)
                else
                    newT[k] = v
                end
            end
            return newT
        end
        value = deepCopy(value)
    end
    -- 4. 执行保存逻辑
    GlobleManager.allData[key] = value
    local saveResult = fileManager:saveTable("allData", GlobleManager.allData)

    -- 5. 校验保存结果（假设saveTable返回布尔值标记成功/失败）
    if saveResult then
        -- 优化打印：数字类型区分整数/小数，更清晰
        --print(string.format("[成功] 保存数据：key=%s，类型=%s，值=%s", key, valueType, value))
        return true
    else
        print(string.format("[错误] 保存数据失败：fileManager保存table失败，key=%s", key))
        return false
    end
end

-- 读取数据（增加空值和类型提示）
function GlobleManager:getGameData(key)
    -- 1. 校验key的合法性
    if type(key) ~= "string" or key == "" then
        print(string.format("[错误] 读取数据失败：key必须是非空字符串，当前key类型=%s，值=%s", type(key), tostring(key)))
        return nil
    end

    -- 2. 读取数据并返回
    local data = GlobleManager.allData[key]
    if data ~= nil then
        -- 优化打印：数字类型区分整数/小数
        local dataType = type(data)
        --print(string.format("[成功] 读取数据：key=%s，类型=%s，值=%s", key, dataType, data))
        return data
    else
        print(string.format("[提示] 读取数据：key=%s 不存在，返回nil", key))
        return nil
    end
end

-- 生成 128 位十六进制字符串
local function raw_uuid()
    local hex = "0123456789abcdef"
    local parts = {}
    for i = 1, 32 do
        parts[i] = hex:sub(math.random(1, 16), math.random(1, 16))
    end
    return table.concat(parts)
end

-- 按 UUID 8‑4‑4‑4‑12 格式输出
function GlobleManager:guid()
    -- 重新播种，确保每次调用的随机序列不同
    math.randomseed(os.time() * 1000 + tonumber(tostring({}):sub(8), 16))
    local raw = raw_uuid()
    return string.format(
        "%s-%s-%s-%s-%s",
        raw:sub(1, 8), --分段，1-8的字符
        raw:sub(9, 12),
        raw:sub(13, 16),
        raw:sub(17, 20),
        raw:sub(21, 32)
    )
end

function GlobleManager:getDate()
    local today = os.date("*t") -- "*t" 表示返回日期table

    -- 提取核心日期组件
    local year = today.year    -- 年（如 2026）
    local month = today.month  -- 月（1-12）
    local day = today.day      -- 日（1-31）
    local weekday = today.wday -- 星期（1=周日，2=周一...7=周六）

    -- 示例：转换星期为中文
    local weekNames = { "周日", "周一", "周二", "周三", "周四", "周五", "周六" }
    local chineseWeek = weekNames[weekday]

    -- 提取时间组件（24小时制）
    local hour = today.hour -- 时（0-23）
    local min = today.min -- 分（0-59）
    local sec = today.sec -- 秒（0-59


    local date = string.format(" %d.%d.%d.", year, month, day) ..">3"
    date = date .. string.format("time：%02d:%02d:%02d", hour, min, sec)

    return date
end

return GlobleManager
