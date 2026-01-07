-- stun_server.lua
local socket = require "socket"

local bit = {
    band = function(a, b) return a & b end,
    bor = function(a, b) return a | b end,
    bxor = function(a, b) return a ~ b end,
    lshift = function(a, n) return a << n end,
    rshift = function(a, n) return a >> n end,
    arshift = function(a, n) return a >> n end,  -- 算术右移
    tohex = function(x, n)
        n = n or 8
        return string.format("%0" .. n .. "x", x)
    end,
    bnot = function(a) return ~a end
}



local STUN_PORT = 3478          -- RFC 推荐端口
local server = assert(socket.udp())
server:setoption('reuseaddr', true)

local ok, err = server:setsockname("0.0.0.0", STUN_PORT)
if ok then
    print("绑定成功")
else
    print("绑定失败 →", err)   -- err 为错误描述，如 “address already in use”
end
server:settimeout(1)           -- 非阻塞

print("[STUN] Server Start UDP " .. STUN_PORT)

while true do
    local data, ip, port = server:receivefrom()
    
    if data then
        print(data,ip,port)
        -- 只处理长度 >= 20（STUN Header 最小长度）
        if #data >= 20 then
            -- 读取 Header
            local msg_type, msg_len, magic, transaction_id = string.unpack(">I2 I2 I4 c12", data)
            -- 检查 Magic Cookie (0x2112A442) 是否匹配
            if magic == 0x2112A442 then
                -- 只处理 Binding Request (0x0001)
                if msg_type == 0x0001 then
                    -- 构造 XOR‑MAPPED‑ADDRESS 属性
                    local family = 0x01          -- IPv4
                    local xport = bit.bxor(port, 0x2112)   -- XOR high 16 位
                    local xip   = {}
                    for oct in ip:gmatch("(%d+)") do
                        table.insert(xip, bit.bxor(tonumber(oct), 0x21))
                    end
                    local xor_ip = string.char(table.unpack(xip))

                    -- 属性 Header: Type(0x0020) Length(8)
                    local attr = string.pack(">I2 I2 I1 I1 I2 c4",
                                            0x0020, 8, family, 0, xport, xor_ip)

                    -- 完整响应报文
                    local resp = string.pack(">I2 I2 I4 c12",
                                            0x0101,          -- Binding Success Response
                                            #attr,          -- Message Length
                                            0x2112A442,      -- Magic Cookie
                                            transaction_id) ..
                                 attr

                    server:sendto(resp, ip, port)
                    print(string.format("[STUN] 响应给 %s:%d", ip, port))
                else
                    -- 其它类型直接忽略（可扩展为错误响应）
                end
            end
        end
    end
    socket.sleep(0.01)   -- 防止 CPU 100%
end