-- fused：只能使用虚拟文件系统的默认路径  打包之后
package.path = package.path .. ";?.lua;?/init.lua"

local commonData = require "src.common.commonData"
local socket = require "socket"
local enet = require "enet"
local json = require "lib.json" -- 任意轻量 JSON 库
local stun = require "src.network.nianStun"
-- print(package.path)
local ctrlNetworkCh = love.thread.getChannel("ctrlNetwork")
local infoNetworkCh = love.thread.getChannel("infoNetwork")

-- 房间号
local code = ""
local localmod = false
while true do
    local cmd = ctrlNetworkCh:pop()
    if cmd then
        if cmd == "quit" then
            return
        elseif cmd.cmd == "start" then
            code = cmd.code
            localmod = cmd.localmod
            print("code =", code)
            break
        end
    end
    socket.sleep(0.01)
end

------------- 1. STUN 打洞 ----------
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

local myAddr
local peers = {} -- {id={ip,port,enetPeer}}
local sigPeer --令信服务器peer
local host  --enet端口服务
------------------区分本地测试和正式服务---------------------
if localmod then

    ---------------------------------
    -- 本地两个固定端口连接
    ---------------------------------
    myAddr = {
        ip = "127.0.0.1",
        port = nil, -- 稍后由 ENet 主机获取
        remotePort = nil -- 远程的
    }
    local a5002 = false
    local err
    -- 3️⃣ 创建 ENet 主机（绑定到本机 127.0.0.1，端口交给系统随机分配）
    host, err = enet.host_create("127.0.0.1:5001", 32, 2, 0, 0) -- 0 表示让系统挑选空闲端口
    if not host then
        print("! ENet host 创建失败 :", err)
        -- infoNetworkCh:push { type = "connectFail" }
        host, err = enet.host_create("127.0.0.1:5002", 32, 2, 0, 0)
        a5002 = true
    end

    -- 取得系统分配的端口，填入 myAddr
    myAddr.port = a5002 and 5002 or 5001 -- 提取端口号字符串
    myAddr.remotePort = a5002 and 5001 or 5002
    print(string.format("ENet 本机监听：%s:%d", myAddr.ip, myAddr.port))

    --假填入另一个玩家ip
    table.insert(peers, {
        ip = "127.0.0.1",
        port = myAddr.remotePort,
        address = "127.0.0.1" .. ":" .. myAddr.remotePort
    })

    -- 假发送获取到连接
    infoNetworkCh:push{
        type = "getPeers",
        peers = peers
    }
else
    ---------------------------------
    -- 获得外网ip 连接令信服务器
    ---------------------------------
    myAddr = getPublicAddr() -- {ip,port}
    if not myAddr then
        print("! STUN Hole Failed !")
        infoNetworkCh:push{
            type = "connectFail"
        }
        return
    end
    print("myAddr:", myAddr.ip .. ":" .. myAddr.port)
    local localPort = myAddr.localPort

    -- ---------- 2. 创建 ENet 主机 ----------
    local ENET_PORT = myAddr.localPort
    local err
    host, err = enet.host_create("*:" .. ENET_PORT, 32, 2, 0, 0)
    print("enet port :" .. "*:" .. ENET_PORT, host, err)

    -- ---------- 3. 向信令服务器报告外网地址 ----------
    local SIGNAL_HOST = "8.136.44.223"
    local SIGNAL_PORT = 4000
    sigPeer = host:connect(SIGNAL_HOST .. ":" .. SIGNAL_PORT, 2) -- 多通道，来做发送文件，语音什么的  这里是2
    local eventConnect = host:service(2000)
    if eventConnect and eventConnect.type == "connect" then
        print("% signaling linked %")
    else
        print("! signaling link fail !")
        infoNetworkCh:push{
            type = "connectFail"
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
end

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

local function filesystemReadFile(path)
    local info, err = love.filesystem.getInfo(path)
    local size = info.size -- 直接返回字节数
    local f, err = love.filesystem.newFile(path)
    f:open("r")
    local success, message = f:seek(0) -- 移动到文件开头

    return f, size
end

-------------文件单播------------
local fileUnicastTaskId = 0
local fileUnicastTasks = {}
local function fileUnicastTask(name, path, peer_id, id)
    local taskId = id
    coroutine.yield()
    local p = peers[peer_id]
    if p and p.enet then
        print("【发送文件给】: ", peer_id, name)
        local f, size = filesystemReadFile(path)
        local seq = 0
        while true do
            if f:isEOF() then
                break
            end
            local chunk = f:read(64 * 1024)
            seq = seq + 1
            local date = love.data.encode("string", "base64", chunk)
            local progress = seq / (size / 64 * 1024) * 100
            local pkt = json.encode {
                type = "audio",
                seq = seq,
                data = date,
                ts = os.time(),
                musicname = name,
                progress = progress
            }
            p.enet:send(pkt) -- ENet 单点发送

            coroutine.yield()
        end
        f:close()
        -- 结束
        p.enet:send(json.encode {
            type = "AUDIOFIN",
            ts = os.time(),
            musicname = name
        })
    end

    infoNetworkCh:push{
        type = "sendAudioOk",
        path = path,
        ts = os.time(),
        name = name
    }
    print("[INFO] 文件发送完毕，已发送 FIN，退出 " .. taskId)
    fileUnicastTasks[taskId] = nil
end

-- 注册文件单播任务
local function registerFileUnicastTask(musicname, path, peerid)
    -- 注册发送携程--避免阻断--可以并列注册
    local task = coroutine.create(fileUnicastTask)
    fileUnicastTasks[fileUnicastTaskId] = task
    local ok, err = coroutine.resume(task, musicname, path, peerid, fileUnicastTaskId)
    if not ok then
        print("ERROR:", err) -- 输出：捕获到错误: 这里出错了
    end
    -- 加id
    fileUnicastTaskId = fileUnicastTaskId + 1
end

-- 执行单播文件
local function fileUnicastTaskUpdate()
    for taskId, task in pairs(fileUnicastTasks) do
        if coroutine.status(task) == "dead" then
            print("! fileUnicastTasks ! isdead " .. taskId)
        else
            local ok, err = coroutine.resume(task)
            if not ok then
                print("Tasks ERROR:", err) -- 输出：捕获到错误: 这里出错了
            end
        end
    end
end

---------接收音乐文件------------
local fileReceiveTasks = {}
local function fileReceiveTask(name)
    local tmp = commonData.tmpPath .. name -- 临时文件名
    tmp = tmp:gsub("\\", "/")
    local f, err = love.filesystem.newFile(tmp)
    local ok, openErr = f:open("a")
    local msg

    -- 发送进度计数
    local returnProgressCount = 200
    local i = 1
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

        if i >= returnProgressCount then
            infoNetworkCh:push{
                type = "info_returnProgress",
                progress = msg.progress,
                musicname = msg.musicname
            }
            i = 1
        end

        i = i + 1
    end
    f:close()
    -- 下载结束
    infoNetworkCh:push{
        type = "audioOk",
        path = tmp,
        ts = msg.ts,
        seq = msg.seq
    }

    print("[INFO] 接收完毕 FIN，退出")
    fileReceiveTasks[msg.musicname] = nil
end

local function getFileReceiveTask(musicname)
    if not fileReceiveTasks[musicname] then
        local task = coroutine.create(fileReceiveTask)
        fileReceiveTasks[musicname] = task
        local ok, err = coroutine.resume(task, musicname)
        if not ok then
            print("ERROR:", err) -- 输出：捕获到错误: 这里出错了
        end
    end
    return fileReceiveTasks[musicname]
end

local peerHeartTime = os.time()
-- ---------- 4. 主循环 ----------
while true do
    local nowtime = os.time()
    -- ② 处理信令服务器的 Peer 信息（每 2 秒轮询一次）
    if nowtime - peerHeartTime > 2 then
        -- print("heart")
        connectPeers()
        peerHeartTime = nowtime
        -- 给令信的心跳
        -- local pkt = json.encode {
        --     type = "heart"
        -- }
        -- sigPeer:send(pkt)
    end

    -- ① 处理主线程指令

    local cmd = ctrlNetworkCh:pop()
    if cmd then
        if cmd == "quit" then
            if sigPeer then
            sigPeer:disconnect()
            end
            for id, p in pairs(peers) do
                if p.enet then
                    p.enet:disconnect()
                end
            end
            return
        elseif cmd.cmd == "broadcast_mp3" then -- 广播音乐
            print("##  Sender start ")
            for id, p in pairs(peers) do
                if p and p.enet then
                    registerFileUnicastTask(cmd.name, cmd.path, id)
                end
            end
        elseif cmd.cmd == "unicast_mp3" then -- 单播音乐
            print("##  Sender start  uni")
            registerFileUnicastTask(cmd.name, cmd.path, cmd.peer_id)
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

    ---单播resume
    fileUnicastTaskUpdate()

    -- ③ ENet 事件（接收音频块）
    local event = host:service(0)
    while event do
        print("ENet event:", event.type, tostring(event.peer), event.channel or "")
        if event.type == "connect" then
            print("[CONNECT] 来自 " .. tostring(event.peer))

            infoNetworkCh:push{
                type = "connectedPeer",
                address = tostring(event.peer)
            }
        end
        if event.type == "receive" then
            local msg = json.decode(event.data)
            if msg.type == "audio" or msg.type == "AUDIOFIN" then
                -- 注册发送携程--避免阻断
                local task = getFileReceiveTask(msg.musicname)
                local ok, err = coroutine.resume(task, msg)
                if not ok then
                    print("ERROR:", err) -- 输出：捕获到错误: 这里出错了
                end
            elseif msg.type == "signaling" then -- 令信返回
                -- 假设返回 "id:ip:port"
                local list = {}
                local userid
                local peersnum = 0
                for id, ip, port in msg.list:gmatch("(%d+):([^:]+):(%d+)") do
                    -- print("#peers: " .. id .. " -- " .. ip .. ":" .. port)
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

                infoNetworkCh:push{
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
                local peer = event.peer -- Peer 对象
                local address = tostring(event.peer) -- 返回 "IP:port" 字符串
                local ip, port = address:match("([^:]+):([^:]+)")
                infoNetworkCh:push{
                    type = "networkHandle",
                    address = address,
                    ip = ip,
                    port = port,
                    msg = msg
                }
            end
        elseif event.type == "disconnect" then
            infoNetworkCh:push{
                type = "disconnectPeer",
                address = tostring(event.peer)
            }
        end
        event = host:service(0)
    end

    socket.sleep(0.01)
end
