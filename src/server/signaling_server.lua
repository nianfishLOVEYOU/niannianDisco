--[[
    ENet 信令服务器
    功能：
        1. 监听指定 UDP 端口（本例 4000）
        2. 客户端发送 {type="signalingRegister", addr="x.x.x.x:yyyy"}
        3. 服务器把该客户端加入 peers 表
        4. 服务器把所有已注册的客户端列表以
           {type="signaling", list="id:ip:port|id:ip:port|..."} 广播给每个客户端
--]] -- print(package.path)
local enet = require "enet"
local json = require "json"
local socket = require "socket"
dofile("/opt/lua/nianTool.lua")

local LISTEN_PORT = 4000 -- 服务器监听端口
local MAX_PEERS = 64 -- 同时最多接受的客户端数
local CHANNELS = 1 -- 只用 0 号通道（可靠）

-- 创建 ENet 主机（绑定本机 UDP 端口）
local host = assert(enet.host_create("*:" .. LISTEN_PORT, MAX_PEERS, CHANNELS, 0, 0))
print(string.format("[ENet] 信令服务器已启动，监听 %d 端口", LISTEN_PORT))

-- 保存已注册的客户端
-- 结构： peers[id] = {peer = <enet_peer>, ip = "x.x.x.x", port = 12345}
local rooms ={}
local addressToRooms ={}
--local peers = {}
local next_id = 1

while true do
    -- 非阻塞轮询，0 表示立即返回
    local ev = host:service(0)

    if ev then
        print("get event :", ev.type)
        --------------------------------------------------------------------
        -- 1️⃣ 新客户端建立 ENet 连接（握手成功）
        --------------------------------------------------------------------
        if ev.type == "connect" then
            local ip = ev.host or ev.ip or ev.address
            local port = ev.port or ev.remote_port
            print("peer:", ip, port)
            -- nianTool:dump(ev.peer)
            print("[CONNECT] 来自 " .. tostring(ev.peer))

            -- 这里不立即分配 id，等收到注册消息后再加入 peers

            --------------------------------------------------------------------
            -- 2️⃣ 收到业务数据
            --------------------------------------------------------------------
        elseif ev.type == "receive" then
            local ok, msg = pcall(json.decode, ev.data)
            if not ok then
                print("[WARN] 收到非 JSON 数据，已丢弃")
            else
                print("receive")
                ----------------------------------------------------------------
                -- 处理 signalingRegister 消息
                ----------------------------------------------------------------
                if msg.type == "signalingRegister" then
                    local code =msg.code
                    


                    local ip, port = msg.addr:match("([^:]+):(%d+)")
                    if not ip then
                        print("[WARN] 注册数据格式错误:", msg.addr)
                    elseif  type(code)~="string" or string.len(code)~=4 then 
                        print("[WARN] 房间code错误:", msg.addr)
                    else
                        local peers
                        if rooms[code] then
                            peers=rooms[code].peers
                        else
                            rooms[code]={
                                next_id=1,
                                peers={},
                                code=code
                            }
                            peers=rooms[code].peers
                        end

                        local id = rooms[code].next_id
                        rooms[code].next_id = id + 1
                        peers[id] = {
                            peer = ev.peer,
                            ip = ip,
                            port = tonumber(port)
                        }
                        print(string.format("[REGISTER] id=%d, %s:%d ,room :%s", id, ip, port,code))
                        
                        --加入索引
                        local addr=tostring(ev.peer)
                        if not addressToRooms[addr] then
                            addressToRooms[addr]={
                                code = code,
                                id = id
                            }
                        end
                         

                        ----------------------------------------------------------------
                        -- 3️⃣ 生成并广播当前 Peer 列表（type = "signaling"）
                        ----------------------------------------------------------------
                        local list_parts = {}
                        for pid, pinfo in pairs(peers) do
                            table.insert(list_parts, string.format("%d:%s:%d", pid, pinfo.ip, pinfo.port))
                        end
                        local list_str = table.concat(list_parts, "|")
                        local broadcast = {
                            type = "signaling",
                            list = list_str
                        }
                        local payload = json.encode(broadcast)

                        -- 向所有已注册的客户端发送（可靠发送，使用通道 0）
                        for _, pinfo in pairs(peers) do
                            pinfo.peer:send(payload, 0) -- 0 为通道号
                        end
                        print("[BROADCAST] 已发送 peer 列表给全部客户端")
                    end

                else
                    print("[INFO] 收到未知类型消息:", msg.type or "nil")
                end
            end

            --------------------------------------------------------------------
            -- 4️⃣ 客户端主动断开
            --------------------------------------------------------------------
        elseif ev.type == "disconnect" then
            -- 找到对应的 id 并从 peers 表中移除
            local removed_id = nil
            local peers=nil
            local addr =tostring(ev.peer)

            if addressToRooms[addr]then
                local code=addressToRooms[addr].code
                peers =rooms[code].peers
                removed_id =addressToRooms[addr].id
            else
                print("[WARN] disconnect unknow address:", addr)
            end
            
            if removed_id then

                peers[removed_id] = nil
                print(string.format("[DISCONNECT] id=%d 已移除", removed_id))

                ----------------------------------------------------------------
                -- 3️⃣ 生成并广播当前 Peer 列表（type = "signaling"）
                ----------------------------------------------------------------
                local list_parts = {}
                for pid, pinfo in pairs(peers) do
                    table.insert(list_parts, string.format("%d:%s:%d", pid, pinfo.ip, pinfo.port))
                end
                local list_str = table.concat(list_parts, "|")
                local broadcast = {
                    type = "signaling",
                    list = list_str
                }
                local payload = json.encode(broadcast)

                -- 向所有已注册的客户端发送（可靠发送，使用通道 0）
                for _, pinfo in pairs(peers) do
                    pinfo.peer:send(payload, 0) -- 0 为通道号
                end

            else
                print("[DISCONNECT] 未登记的 peer 断开")
            end
        end
    end

    -- 防止 CPU 100% 占用，可适当 sleep（10 ms）
    -- enet.host_sleep(0.01)   -- 等价于 socket.sleep，ENet 自带的轻量 sleep
    socket.sleep(0.01)
end
