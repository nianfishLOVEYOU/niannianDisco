-- fused：只能使用虚拟文件系统的默认路径  打包之后
package.path        = package.path .. ";?.lua;?/init.lua"

local socket        = require "socket"
local enet          = require "enet"
local json          = require "lib.json"      -- 任意轻量 JSON 库
local stun          = require "src.network.nianStun" -- ← 仍保留引用，后面不再使用

local ctrlNetworkCh = love.thread.getChannel("ctrlNetwork")
local infoNetworkCh = love.thread.getChannel("infoNetwork")

--------------------------------------------------------------------
-- 1️⃣ 读取主线程指令，获取 “code” （仍保留原有逻辑）
--------------------------------------------------------------------
local code          = ""
while true do
    local cmd = ctrlNetworkCh:pop()
    if cmd then
        if cmd == "quit" then
            return
        elseif cmd.cmd == "start" then
            code = cmd.code
            print("code =", code)
            break
        end
    end
    socket.sleep(0.01)
end

--------------------------------------------------------------------
-- 2️⃣ 本机地址（不再走 STUN）
--------------------------------------------------------------------
local myAddr = {
    ip        = "127.0.0.1",
    port      = nil, -- 稍后由 ENet 主机获取
    remotePort = nil --远程的
}
local a5002 = false
--------------------------------------------------------------------
-- 3️⃣ 创建 ENet 主机（绑定到本机 127.0.0.1，端口交给系统随机分配）
--------------------------------------------------------------------
local host, err = enet.host_create("127.0.0.1:5001", 32, 2, 0, 0) -- 0 表示让系统挑选空闲端口
if not host then
    print("! ENet host 创建失败 :", err)
    --infoNetworkCh:push { type = "connectFail" }
    host, err = enet.host_create("127.0.0.1:5002", 32, 2, 0, 0)
    a5002 = true
end

-- 取得系统分配的端口，填入 myAddr
myAddr.port      = a5002 and 5002 or 5001 -- 提取端口号字符串
myAddr.remotePort = a5002 and 5001 or 5002
print(string.format("ENet 本机监听：%s:%d", myAddr.ip, myAddr.port))

--------------------------------------------------------------------
-- 4️⃣ 记录 Peer 列表（由外部指令自行填充），保持原有结构
--------------------------------------------------------------------
local peers = {} -- {id = {ip = "...", port = ..., enet = enetPeer}}

-- table.insert(peers, {
--     ip   = "127.0.0.1",
--     port =myAddr.port 
-- })
table.insert(peers, {
    ip   = "127.0.0.1",
    port =myAddr.remotePort ,
    address = "127.0.0.1"..":"..myAddr.remotePort
})


infoNetworkCh:push { type = "getPeers", peers = peers }
--------------------------------------------------------------------
-- 5️⃣ 连接到已知 Peer（ENet 会在内部完成 UDP 打洞后的可靠通道）
--------------------------------------------------------------------
local function connectPeers()
    for id, p in pairs(peers) do
        if not p.enet then
            local peer = host:connect(p.ip .. ":" .. p.port, 2) -- 2 条通道
            p.enet = peer
            print("connect peer ", p.ip .. ":" .. p.port)
        end
    end
end

--------------------------------------------------------------------
-- 6️⃣ 文件广播协程（保持原实现，仅改动少量变量名）
--------------------------------------------------------------------
local fileBroadcastTasks = {}
local function fileBroadcastTask(cmd)
    coroutine.yield()
    local info, err = love.filesystem.getInfo(cmd.path)
    local size = info.size
    local f, err = love.filesystem.newFile(cmd.path)
    f:open("r")
    local seq = 0
    while true do
        if f:isEOF() then break end
        local chunk = f:read(64 * 1024)
        seq = seq + 1
        local data = love.data.encode("string", "base64", chunk)

        for _, p in pairs(peers) do
            if p and p.enet then
                local pkt = json.encode {
                    type      = "audio",
                    seq       = seq,
                    ts        = os.time(),
                    data      = data,
                    musicname = cmd.name
                }
                p.enet:send(pkt)
            end
        end
        coroutine.yield()
    end
    f:close()

    -- 发送结束标记
    for _, p in pairs(peers) do
        if p and p.enet then
            p.enet:send(json.encode {
                type      = "AUDIOFIN",
                ts        = os.time(),
                musicname = cmd.name
            })
        end
    end

    infoNetworkCh:push {
        type = "audioOk",
        path = cmd.path,
        ts   = os.time(),
        name = cmd.name
    }
    print("[INFO] 文件发送完毕，已发送 FIN，退出")
    table.remove(fileBroadcastTasks, 1)
end

--------------------------------------------------------------------
-- 7️⃣ 文件单播协程（保持原实现）
--------------------------------------------------------------------
local fileUnicastTasks = {}
local function fileUnicastTask(cmd)
    coroutine.yield()
    local p = peers[cmd.peer_id]
    if p and p.enet then
        local dir = love.filesystem.getSaveDirectory():gsub("/", "\\")
        local f = io.open(dir .. "\\" .. cmd.path, "rb")
        local seq = 0
        while true do
            local chunk = f:read(64 * 1024)
            if not chunk then break end
            seq = seq + 1
            local data = love.data.encode("string", "base64", chunk)
            local pkt = json.encode {
                type      = "audio",
                seq       = seq,
                data      = data,
                ts        = os.time(),
                musicname = cmd.name
            }
            p.enet:send(pkt)
            coroutine.yield()
        end
        f:close()
        p.enet:send(json.encode {
            type      = "AUDIOFIN",
            ts        = os.time(),
            musicname = cmd.name
        })
        print("[INFO] 单播文件发送完毕，已发送 FIN")
        table.remove(fileUnicastTasks, 1)
    end
end

--------------------------------------------------------------------
-- 8️⃣ 接收音乐文件协程（保持原实现）
--------------------------------------------------------------------
local fileReceiveTasks = {}
local function fileReceiveTask(name)
    local tmp = "tmp/" .. name
    tmp = tmp:gsub("\\", "/")
    local f, err = love.filesystem.newFile(tmp)
    f:open("a")
    local msg
    while true do
        msg = coroutine.yield()
        if msg.type == "AUDIOFIN" then break end
        local raw = love.data.decode("string", "base64", msg.data)
        f:write(raw)
        f:flush()
    end
    f:close()
    infoNetworkCh:push {
        type = "audioOk",
        path = tmp,
        ts   = msg.ts,
        seq  = msg.seq
    }
    print("[INFO] 接收完毕 FIN，退出")
    fileReceiveTasks[msg.musicname] = nil
end

--------------------------------------------------------------------
-- 9️⃣ 主循环
--------------------------------------------------------------------
local peerHeartTime = os.time()
while true do
    local nowtime = os.time()

    ----------------------------------------------------------------
    -- ① 心跳：每 2 秒尝试一次对已知 Peer 的连接
    ----------------------------------------------------------------
    if nowtime - peerHeartTime > 2 then
        connectPeers()
        peerHeartTime = nowtime
    end

    ----------------------------------------------------------------
    -- ② 处理主线程指令（广播、单播、退出等）
    ----------------------------------------------------------------
    local cmd = ctrlNetworkCh:pop()
    if cmd then
        if cmd == "quit" then
            -- 关闭所有 ENet 连接
            print("quit")
            for _, p in pairs(peers) do
                if p.enet then p.enet:disconnect() end
            end
            return
        elseif cmd.cmd == "broadcast_mp3" then
            local task = coroutine.create(fileBroadcastTask)
            table.insert(fileBroadcastTasks, task)
            coroutine.resume(task, cmd)
        elseif cmd.cmd == "unicast_mp3" then
            local task = coroutine.create(fileUnicastTask)
            table.insert(fileUnicastTasks, task)
            coroutine.resume(task, cmd)
        elseif cmd.cmd == "send_Broadcast" then
            print("[Sand] >> " .. cmd.msg.type)
            local msg = json.encode(cmd.msg)
            for _, p in pairs(peers) do
                if p.enet then p.enet:send(msg) end
            end
        elseif cmd.cmd == "send_unicast" then
            print("[Sand] >> " .. cmd.msg.type)
            local msg = json.encode(cmd.msg)
            local p = peers[cmd.peer_id]
            if p and p.enet then p.enet:send(msg) end
        end
    end

    ----------------------------------------------------------------
    -- ③ 继续执行挂起的广播 / 单播 协程
    ----------------------------------------------------------------
    if fileBroadcastTasks[1] then
        if coroutine.status(fileBroadcastTasks[1]) == "dead" then
            table.remove(fileBroadcastTasks, 1)
        else
            coroutine.resume(fileBroadcastTasks[1])
        end
    end

    if fileUnicastTasks[1] then
        if coroutine.status(fileUnicastTasks[1]) == "dead" then
            table.remove(fileUnicastTasks, 1)
        else
            coroutine.resume(fileUnicastTasks[1])
        end
    end

    ----------------------------------------------------------------
    -- ④ ENet 事件处理（接收、连接、断开）
    ----------------------------------------------------------------
    local event = host:service(0)
    while event do
        if event.type == "connect" then
            print("[ENet] 与 Peer 建立连接：" .. tostring(event.peer))
            -- infoNetworkCh:push {
            --     type    = "getPeersss",
            --     peers    = peers,
            -- }  --也许无法序列化peers 所以导致闪退

            infoNetworkCh:push {
                type    = "connectedPeer",
                address = tostring(event.peer)
            }
            
        elseif event.type == "receive" then
            local msg = json.decode(event.data)

            if msg.type == "audio" or msg.type == "AUDIOFIN" then
                -- 若是新文件，创建接收协程
                if not fileReceiveTasks[msg.musicname] then
                    local task = coroutine.create(fileReceiveTask)
                    fileReceiveTasks[msg.musicname] = { task = task }
                    coroutine.resume(task, msg.musicname)
                end
                coroutine.resume(fileReceiveTasks[msg.musicname].task, msg)
            else
                print("[networkHandle] << " .. msg.type, event.data)
                -- 其它业务消息直接转发给主线程
                local address = tostring(event.peer)
                local ip, port = address:match("([^:]+):([^:]+)")
                infoNetworkCh:push {
                    type    = "networkHandle",
                    address = address,
                    ip      = ip,
                    port    = port,
                    msg     = msg
                }
                print("[networkHandle] << over")
            end
        elseif event.type == "disconnect" then
            infoNetworkCh:push {
                type    = "disconnectPeer",
                address = tostring(event.peer)
            }
        end
        event = host:service(0)
    end

    socket.sleep(0.01)
end
