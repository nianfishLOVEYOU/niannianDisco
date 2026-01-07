-- stun_client.lua
-- 兼容 Lua 5.1（LÖVE 11.x） 的 STUN 客户端实现
-- 只实现 Binding Request → XOR‑MAPPED‑ADDRESS 解析
local nianStun = {}

local socket = require "socket"

--------------------------------------------------------------------
-- 1️⃣ 辅助函数
--------------------------------------------------------------------
-- 生成 n 个随机字节（返回二进制字符串）
local function rand_bytes(n)
    local t = {}
    for i = 1, n do
        t[i] = string.char(math.random(0, 255))
    end
    return table.concat(t)
end

-- 5.1 没有 bit 库，这里实现最小的 XOR
local function bxor(a, b)
    local r = 0
    local bit = 1
    while a > 0 or b > 0 do
        local abit = a % 2
        local bbit = b % 2
        if abit ~= bbit then
            r = r + bit
        end
        a = math.floor(a / 2)
        b = math.floor(b / 2)
        bit = bit * 2
    end
    return r
end

--------------------------------------------------------------------
-- 2️⃣ 生成 STUN Binding Request（20 字节）
--------------------------------------------------------------------
local function build_request()
    -- Header: Message Type(2) | Message Length(2) | Magic Cookie(4) | Transaction ID(12)
    local msg_type = "\x00\x01" -- 0x0001 Binding Request
    local msg_len = "\x00\x00" -- 0 长度（无属性）
    local magic = "\x21\x12\xA4\x42" -- 0x2112A442
    local transaction = rand_bytes(12) -- 12‑byte Transaction ID
    return msg_type .. msg_len .. magic .. transaction, transaction
end

--------------------------------------------------------------------
-- 3️⃣ 解析 STUN 响应，提取 XOR‑MAPPED‑ADDRESS
--------------------------------------------------------------------
local function parse_response(resp, sent_tx)
    -- 先检查 Header（前 20 字节）
    if #resp < 20 then
        return false, "response too short"
    end

    local msg_type = string.byte(resp, 1) * 256 + string.byte(resp, 2)
    local msg_len = string.byte(resp, 3) * 256 + string.byte(resp, 4)
    local magic = string.byte(resp, 5) * 0x1000000 + string.byte(resp, 6) * 0x10000 + string.byte(resp, 7) * 0x100 +
                      string.byte(resp, 8)

    if msg_type ~= 0x0101 then
        return false, "not a Binding Success response"
    end
    if magic ~= 0x2112A442 then
        return false, "magic cookie mismatch"
    end
    local resp_tx = resp:sub(9, 20)
    if resp_tx ~= sent_tx then
        return false, "transaction ID mismatch"
    end

    -- 读取属性（从第 21 字节开始）
    local offset = 21 -- Lua 索引从 1 开始
    while offset <= #resp do
        if offset + 3 > #resp then
            break
        end
        local attr_type = string.byte(resp, offset) * 256 + string.byte(resp, offset + 1)
        local attr_len = string.byte(resp, offset + 2) * 256 + string.byte(resp, offset + 3)
        offset = offset + 4

        if attr_type == 0x0020 then -- XOR‑MAPPED‑ADDRESS
            -- 1 byte: Reserved (0), 1 byte: Family, 2 bytes: X‑Port, 4 bytes: X‑IP
            local family = string.byte(resp, offset + 1)
            local xport_hi = string.byte(resp, offset + 2)
            local xport_lo = string.byte(resp, offset + 3)
            local xport = xport_hi * 256 + xport_lo
            local port = bxor(xport, 0x2112)

            -- 取出 4 字节 X‑IP
            local xip_bytes = {resp:byte(offset + 4, offset + 7)}
            local ip_bytes = {}
            for i = 1, 4 do
                ip_bytes[i] = bxor(xip_bytes[i], 0x21) -- 0x21 = high‑byte of magic cookie
            end
            local ip = table.concat(ip_bytes, ".")
            return true, ip, port
        else
            -- 跳过非目标属性
            offset = offset + attr_len
        end
    end

    return false, "XOR‑MAPPED‑ADDRESS not found"
end

--------------------------------------------------------------------
-- 4️⃣ 公共 API
--------------------------------------------------------------------
function nianStun:getPublicIp(server, port)
    local client = assert(socket.udp())
    client:settimeout(5) -- 5 秒超时
    client:setsockname("0.0.0.0", 0) 

    local request, tx = build_request()
    client:sendto(request, server, port)
    print("[STUN] request sent to " .. server .. ":" .. port)
    local resp, src_ip, src_port = client:receivefrom()
    if not resp then
        print("resp:", "timeout", resp, src_ip, src_port)
        return false, nil, nil, "timeout"
        
    end
    local nonip, localPort =client:getsockname()
    local ok, ip, p_or_err = parse_response(resp, tx)
    if ok then
        -- print(string.format("[STUN] Public IP %s:%d", ip, p_or_err))
        client:close()
        return true, ip, p_or_err,localPort
    else
        client:close()
        print("resp:", resp)
        return false, nil, nil, p_or_err
    end
end

return nianStun
