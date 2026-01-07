-- fused：只能使用虚拟文件系统的默认路径  打包之后
package.path = package.path .. ";?.lua;?/init.lua"


local socket = require "socket"
local enet = require "enet"
local json = require "lib.json" -- 任意轻量 JSON 库
local stun = require "src.network.nianStun"
-- print(package.path)
local ctrlNetworkCh = love.thread.getChannel("ctrlNetwork")
local infoNetworkCh = love.thread.getChannel("infoNetwork")

local code = ""
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


-- ---------- 1. STUN 打洞 ----------
local function getPublicAddr()
    local STUN_HOST = "8.136.44.223"
    local STUN_PORT = 3478
    local success, publicIp, port, localPort = stun:getPublicIp(STUN_HOST, STUN_PORT)
    if success then
        return {
            ip = publicIp,
            port = port,
            localPort = localPort
        }
    end
    return nil
end

local myAddr = getPublicAddr() -- {ip,port}
if not myAddr then
    print("! STUN Hole Failed !")
    infoNetworkCh:push {
        type = "connectFail",
    }
    return
end
print("myAddr:", myAddr.ip .. ":" .. myAddr.port)
local localPort = myAddr.localPort

-- ---------- 2. 创建 ENet 主机 ----------
local ENET_PORT = myAddr.localPort
local host, err = enet.host_create("*:" .. ENET_PORT, 32, 2, 0, 0)
print("enet port :" .. "*:" .. ENET_PORT, host, err)

-- ---------- 3. 向信令服务器报告外网地址 ----------
local SIGNAL_HOST = "8.136.44.223"
local SIGNAL_PORT = 4000
local sigPeer = host:connect(SIGNAL_HOST .. ":" .. SIGNAL_PORT, 2) -- 多通道，来做发送文件，语音什么的  这里是2
local eventConnect = host:service(2000)
if eventConnect and eventConnect.type == "connect" then
    print("% signaling linked %")
else
    print("! signaling link fail !")
    infoNetworkCh:push {
        type = "connectFail",
    }
    return
end
local pkt = json.encode {
    type = "signalingRegister",
    addr = myAddr.ip .. ":" .. myAddr.port,
    code = code
}
sigPeer:send(pkt) -- 简单文本协议
print("signaling :", SIGNAL_HOST .. ":" .. SIGNAL_PORT)
local peers = {}  -- {id={ip,port,enetPeer}}

------------ 如果连接失败就直接结束线程 ---------


-- 连接到每个 Peer（ENet 会在内部完成 UDP 打洞后的可靠通道）
local function connectPeers()
    for id, p in pairs(peers) do
        if not p.enet then
            local peer = host:connect(p.ip .. ":" .. p.port, 2) -- 多通道，来做发送文件，语音什么的  这里是2
            p.enet = peer
            print("connect peer ", p.ip .. ":" .. p.port)
        end
    end
end

---文件广播---
local fileBroadcastTasks = {}
local function fileBroadcastTask(cmd)
    coroutine.yield()
    local info, err = love.filesystem.getInfo(cmd.path)
    local size = info.size -- 直接返回字节数
    local f, err = love.filesystem.newFile(cmd.path)
    f:open("r")
    local success, message = f:seek(0) -- 移动到文件开头
    local seq = 0
    while true do
        if f:isEOF() then
            break
        end
        local chunk = f:read(64 * 1024)
        seq = seq + 1
        local date = love.data.encode("string", "base64", chunk)
        for k, p in pairs(peers) do
            if p and p.enet then
                local pkt = json.encode {
                    type = "audio",
                    seq = seq,
                    ts = os.time(),
                    data = date,
                    musicname = cmd.name
                }

                local percent = seq / (size / 64 * 1024) * 100
                -- io.write("\r percent: " .. percent .. "%")
                -- io.flush()
                p.enet:send(pkt) -- ENet 单点发送
            end
        end

        coroutine.yield()
    end
    f:close()
    -- 结束
    for k, p in pairs(peers) do
        if p and p.enet then
            p.enet:send(json.encode {
                type = "AUDIOFIN",
                ts = os.time(),
                musicname = cmd.name
            })
        end
    end
    infoNetworkCh:push {
        type = "audioOk",
        path = cmd.path,
        ts = os.time(),
        name = cmd.name
    }
    print("[INFO] 文件发送完毕，已发送 FIN，退出", "还有任务：" .. #fileBroadcastTasks)
    table.remove(fileBroadcastTasks, 1)
end

---文件单播---
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
            if not chunk then
                break
            end
            seq = seq + 1
            local date = love.data.encode("string", "base64", chunk)

            local pkt = json.encode {
                type = "audio",
                seq = seq,
                data = date,
                ts = os.time(),
                musicname = cmd.name
            }
            p.enet:send(pkt) -- ENet 单点发送

            coroutine.yield()
        end
    end
    f:close()
    -- 结束
    p.enet:send(son.encode {
        type = "AUDIOFIN",
        ts = os.time(),
        musicname = cmd.name
    })
    print("[INFO] 文件发送完毕，已发送 FIN，退出")
    table.remove(fileUnicastTasks, 1)
end


---接收音乐文件---
local fileReceiveTasks = {}
local function fileReceiveTask(name)
    local tmp = "tmp/" .. name -- 临时文件名
    tmp = tmp:gsub("\\", "/")
    local f, err = love.filesystem.newFile(tmp)
    local ok, openErr = f:open("a")
    local msg
    while true do
        msg = coroutine.yield()
        if msg.type == "AUDIOFIN" then
            break
        end

        local raw = love.data.decode("string", "base64", msg.data)
        local written, writeErr = f:write(raw)
        if not written then
            print("!write 失败 :", writeErr or "未知错误")
        else
            f:flush() -- 强制把缓冲区写入磁盘[[2]]
        end
    end
    f:close()
    -- 下载结束
    infoNetworkCh:push {
        type = "audioOk",
        path = tmp,
        ts = msg.ts,
        seq = msg.seq
    }

    print("[INFO] 接收完毕 FIN，退出")
    fileReceiveTasks[msg.musicname] = nil
end

local peerHeartTime = os.time()
-- ---------- 4. 主循环 ----------
while true do
    local nowtime = os.time()
    -- ② 处理信令服务器的 Peer 信息（每 2 秒轮询一次）
    if nowtime - peerHeartTime > 2 then
        --print("heart")
        connectPeers()
        peerHeartTime = nowtime
        --给令信的心跳
        -- local pkt = json.encode {
        --     type = "heart"
        -- }
        --sigPeer:send(pkt)
    end

    -- ① 处理主线程指令

    local cmd = ctrlNetworkCh:pop()
    if cmd then
        if cmd == "quit" then
            sigPeer:disconnect()
            for id, p in pairs(peers) do
                if p.enet then
                    p.enet:disconnect()
                end
            end
            return
        elseif cmd.cmd == "broadcast_mp3" then -- 广播音乐
            print("##  Sender start ")
            -- 注册发送携程--避免阻断
            local task = coroutine.create(fileBroadcastTask)
            table.insert(fileBroadcastTasks, task)
            local ok, err = coroutine.resume(task, cmd)
            if not ok then
                print("ERROR:", err)         -- 输出：捕获到错误: 这里出错了
            end
        elseif cmd.cmd == "unicast_mp3" then -- 单播音乐
            print("##  Sender start  uni")
            -- 注册发送携程--避免阻断
            local task = coroutine.create(fileUnicastTask)
            table.insert(fileUnicastTasks, task)
            local ok, err = coroutine.resume(task, cmd)
            if not ok then
                print("ERROR:", err) -- 输出：捕获到错误: 这里出错了
            end
        elseif cmd.cmd == "send_Broadcast" then
            local msg = json.encode(cmd.msg)
            print("[Sand] >> " .. cmd.msg.type)
            for k, p in pairs(peers) do
                if p and p.enet then
                    p.enet:send(msg) -- ENet 广播
                end
            end
        elseif cmd.cmd == "send_unicast" then
            local msg = json.encode(cmd.msg)
            print("[Sand] >> " .. cmd.msg.type)
            local p = peers[cmd.peer_id]
            if p and p.enet then
                p.enet:send(msg) -- ENet 单点发送
            end
        end
    end

    ---广播resume
    if (fileBroadcastTasks[1]) then
        if coroutine.status(fileBroadcastTasks[1]) == "dead" then
            table.remove(fileUnicastTasks, 1)
        else
            local ok, err = coroutine.resume(fileBroadcastTasks[1])
            if not ok then
                print("ERROR:", #fileBroadcastTasks, coroutine.status(fileBroadcastTasks[1]) == "dead", err) -- 输出：捕获到错误: 这里出错了
            end
        end
    end

    ---单播resume
    if (fileUnicastTasks[1]) then
        if coroutine.status(fileBroadcastTasks[1]) == "dead" then
            table.remove(fileUnicastTasks, 1)
        else
            local ok, err = coroutine.resume(fileUnicastTasks[1])
            if not ok then
                print("ERROR:", err) -- 输出：捕获到错误: 这里出错了
            end
        end
    end

    -- ③ ENet 事件（接收音频块）
    local event = host:service(0)
    while event do
        print("ENet event:", event.type, tostring(event.peer), event.channel or "")
        if event.type == "connect" then 
            print("[CONNECT] 来自 " .. tostring(event.peer))

            infoNetworkCh:push {
                type = "connectedPeer",
                address = tostring(event.peer),
            }
        end
        if event.type == "receive" then
            local msg = json.decode(event.data)
            if msg.type == "audio" or msg.type == "AUDIOFIN" then
                --print("##  receive start")
                -- 注册发送携程--避免阻断
                if not fileReceiveTasks[msg.musicname] then
                    local task = coroutine.create(fileReceiveTask)
                    fileReceiveTasks[msg.musicname] = {
                        task = task,
                        persent = 0
                    }
                    local ok, err = coroutine.resume(task, msg.musicname)
                    if not ok then
                        print("ERROR:", err) -- 输出：捕获到错误: 这里出错了
                    end
                end
                local ok, err = coroutine.resume(fileReceiveTasks[msg.musicname].task, msg)
                if not ok then
                    print("ERROR:", err)        -- 输出：捕获到错误: 这里出错了
                end
            elseif msg.type == "signaling" then -- 令信返回
                -- 假设返回 "id:ip:port"
                local list = {}
                local userid
                local peersnum = 0
                for id, ip, port in msg.list:gmatch("(%d+):([^:]+):(%d+)") do
                    --print("#peers: " .. id .. " -- " .. ip .. ":" .. port)
                    list[tonumber(id)] = {
                        ip = ip,
                        port = tonumber(port)
                    }
                    if ip ~= myAddr.ip or tonumber(port) ~= myAddr.port then
                        peers[tonumber(id)] = {
                            ip = ip,
                            port = tonumber(port)
                        }
                    elseif ip == myAddr.ip and tonumber(port) == myAddr.port then
                        print("self : " .. id .. " -- " .. ip .. ":" .. port)
                        -- 获得自己的id
                        userid = tonumber(id)
                    end
                end
                -- 清除服务端缺掉的peer
                local to_remove = {}
                for k, v in pairs(peers) do
                    if not list[k] then
                        print("remove peer: " .. v.ip .. ":" .. v.port)
                        table.insert(to_remove, k)
                    end
                end
                for _, k in ipairs(to_remove) do
                    peers[k] = nil
                end

                infoNetworkCh:push {
                    type = "getPeers",
                    peers = peers,
                    userid = userid
                }

                for k, v in pairs(peers) do
                    peersnum = peersnum + 1
                end
                print("#lists: " .. #list)
                print("#peers: " .. peersnum)
            else
                print("[networkHandle] << " .. msg.type, event.data)
                local peer = event.peer              -- Peer 对象
                local address = tostring(event.peer) -- 返回 "IP:port" 字符串
                local ip, port = address:match("([^:]+):([^:]+)")
                infoNetworkCh:push {
                    type = "networkHandle",
                    address = address,
                    ip = ip,
                    port = port,
                    msg = msg
                }
            end
        elseif event.type == "disconnect" then
            infoNetworkCh:push {
                type = "disconnectPeer",
                address = tostring(event.peer),
            }
        end
        event = host:service(0)
    end

    socket.sleep(0.01)
end
