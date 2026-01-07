
--path
GlobleManager={
    allData={},
}

systemManager:init_regester(function ()
    GlobleManager:init()
end)

function GlobleManager:init()
    --初始化设定，音量什么的，保存到文件
    GlobleManager.allData=fileManager:readTable("allData")
    if not self.allData then
        self.allData={}
        fileManager:saveTable("allData",GlobleManager.allData)
    end
end

function GlobleManager:saveGameData(key,table)
    GlobleManager.allData[key]=table
    fileManager:saveTable("allData",GlobleManager.allData)
end

function GlobleManager:getGameData(key)
    if GlobleManager.allData[key] then
        return GlobleManager.allData[key]
    end
    return nil
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
function  GlobleManager:guid()
    -- 重新播种，确保每次调用的随机序列不同
    math.randomseed(os.time() * 1000 + tonumber(tostring({}):sub(8), 16))
    local raw = raw_uuid()
    return string.format(
        "%s-%s-%s-%s-%s",
        raw:sub(1, 8),  --分段，1-8的字符
        raw:sub(9, 12),
        raw:sub(13, 16),
        raw:sub(17, 20),
        raw:sub(21, 32)
    )
end

return GlobleManager