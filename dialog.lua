-- main.lua

local enet = require 'enet'
local json = require 'dkjson' -- 用于序列化消息，你需要下载 dkjson.lua 并放在项目中

local client = nil
local peer = nil

local messages = {} -- 存储所有消息对象的数组
local messageBuffer = "" -- 输入框中的文本
local scrollOffset = 0 -- 聊天窗口的滚动偏移量
local messageHeight = 40 -- 每条消息的高度（包括间距）
local emojiPanelOpen = false -- 表情面板是否打开
local emojiQuads = {} -- 存储表情图片的 Quad
local emojiTextures = {} -- 存储表情图片的 Texture
local emojiSize = 32 -- 表情大小
local historyFile = "assets/chat_history.json" -- 聊天历史记录文件

-- 消息对象结构: { type = "text" | "image" | "emoji", content = "...", time = "HH:MM:SS" }

function love.load()
    -- 加载 dkjson 库 (如果需要)
    -- json = require 'dkjson'

    -- 尝试连接到服务器
    client = enet.host_create()
    peer = client:connect("localhost:6789")

    -- 加载聊天历史记录
    loadChatHistory()

    -- 加载表情图片
    loadEmojis()
end

function love.update(dt)
    if client then
        -- 持续处理网络事件
        local event = client:service(10)
        while event do
            if event.type == "receive" then
                -- 接收到服务器广播的消息
                local msg = json.decode(event.data)
                table.insert(messages, msg)
                saveChatHistory() -- 收到新消息后立即保存
            elseif event.type == "connect" then
                print("成功连接到服务器")
            elseif event.type == "disconnect" then
                print("与服务器断开连接")
                client = nil
                peer = nil
            end
            event = client:service()
        end
    end
end

function love.draw()
    -- 绘制背景
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)

    -- 绘制聊天区域背景
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 50, 50, love.graphics.getWidth() - 100, love.graphics.getHeight() - 180)

    -- 绘制聊天内容 (只渲染可见部分)
    drawVisibleMessages()

    -- 绘制输入框
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", 50, love.graphics.getHeight() - 100, love.graphics.getWidth() - 200, 40)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(messageBuffer, 60, love.graphics.getHeight() - 95, love.graphics.getWidth() - 220)

    -- 绘制发送按钮
    love.graphics.setColor(0.4, 0.6, 0.8)
    love.graphics.rectangle("fill", love.graphics.getWidth() - 140, love.graphics.getHeight() - 100, 90, 40)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("发送", love.graphics.getWidth() - 120, love.graphics.getHeight() - 95)

    -- 绘制表情按钮
    love.graphics.setColor(0.8, 0.7, 0.2)
    love.graphics.rectangle("fill", love.graphics.getWidth() - 140, love.graphics.getHeight() - 50, 90, 40)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("表情", love.graphics.getWidth() - 120, love.graphics.getHeight() - 45)

    -- 如果表情面板打开，则绘制它
    if emojiPanelOpen then
        drawEmojiPanel()
    end
end

function love.mousepressed(x, y, button)
    -- 发送按钮
    if x > love.graphics.getWidth() - 140 and x < love.graphics.getWidth() - 50 and y > love.graphics.getHeight() - 100 and y < love.graphics.getHeight() - 60 then
        sendTextMessage()
    end

    -- 表情按钮
    if x > love.graphics.getWidth() - 140 and x < love.graphics.getWidth() - 50 and y > love.graphics.getHeight() - 50 and y < love.graphics.getHeight() - 10 then
        emojiPanelOpen = not emojiPanelOpen
    end

    -- 点击表情面板中的表情
    if emojiPanelOpen then
        local emojiPanelX = 50
        local emojiPanelY = love.graphics.getHeight() - 200
        local cols = 5 -- 每行显示5个表情
        for i, tex in ipairs(emojiTextures) do
            local row = math.floor((i - 1) / cols)
            local col = (i - 1) % cols
            local ex = emojiPanelX + col * (emojiSize + 5)
            local ey = emojiPanelY + row * (emojiSize + 5)
            if x > ex and x < ex + emojiSize and y > ey and y < ey + emojiSize then
                sendEmojiMessage(tex:getFilename()) -- 发送表情文件名
                emojiPanelOpen = false
                break
            end
        end
    end

    -- 聊天区域的滚动
    local chatAreaX = 50
    local chatAreaY = 50
    local chatAreaW = love.graphics.getWidth() - 100
    local chatAreaH = love.graphics.getHeight() - 180
    if x > chatAreaX and x < chatAreaX + chatAreaW and y > chatAreaY and y < chatAreaY + chatAreaH then
        if button == 1 then -- 左键双击可以快速滚动到底部
            scrollOffset = math.max(0, #messages * messageHeight - chatAreaH)
        end
    end
end

function love.wheelmoved(x, y)
    -- 鼠标滚轮控制聊天区域滚动
    local chatAreaH = love.graphics.getHeight() - 180
    scrollOffset = scrollOffset - y * 40
    local maxScroll = math.max(0, #messages * messageHeight - chatAreaH)
    scrollOffset = math.min(math.max(0, scrollOffset), maxScroll)
end

function love.textinput(t)
    messageBuffer = messageBuffer .. t
end

function love.keypressed(key)
    if key == "backspace" then
        -- 退格键
        messageBuffer = messageBuffer:sub(1, -2)
    elseif key == "return" then
        -- 回车键发送消息
        sendTextMessage()
    end
end

-- 发送文本消息
function sendTextMessage()
    if client and messageBuffer ~= "" then
        local msg = {
            type = "text",
            content = messageBuffer,
            time = os.date("%H:%M:%S")
        }
        peer:send(json.encode(msg))
        messageBuffer = ""
    end
end

-- 发送表情消息
function sendEmojiMessage(emojiFilename)
    if client and emojiFilename then
        local msg = {
            type = "emoji",
            content = emojiFilename, -- 发送表情的文件名
            time = os.date("%H:%M:%S")
        }
        peer:send(json.encode(msg))
    end
end

-- 只绘制可见区域的消息
function drawVisibleMessages()
    local chatAreaX = 50
    local chatAreaY = 50
    local chatAreaW = love.graphics.getWidth() - 100
    local chatAreaH = love.graphics.getHeight() - 180

    -- 计算可见的消息范围
    local firstVisibleIndex = math.floor(scrollOffset / messageHeight) + 1
    local lastVisibleIndex = math.floor((scrollOffset + chatAreaH) / messageHeight) + 1
    firstVisibleIndex = math.max(1, firstVisibleIndex)
    lastVisibleIndex = math.min(#messages, lastVisibleIndex)

    -- 绘制可见的消息
    for i = firstVisibleIndex, lastVisibleIndex do
        local msg = messages[i]
        local yPos = chatAreaY + (i - 1) * messageHeight - scrollOffset

        -- 绘制消息背景
        love.graphics.setColor(0.25, 0.25, 0.25)
        love.graphics.rectangle("fill", chatAreaX, yPos, chatAreaW, messageHeight - 5)

        -- 绘制时间戳
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.print(msg.time, chatAreaX + 10, yPos + 5)

        if msg.type == "text" then
            -- 绘制文本消息
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(msg.content, chatAreaX + 70, yPos + 5, chatAreaW - 80)
        elseif msg.type == "emoji" then
            -- 绘制表情消息
            local emojiTex = nil
            for _, tex in ipairs(emojiTextures) do
                if tex:getFilename() == msg.content then
                    emojiTex = tex
                    break
                end
            end
            if emojiTex then
                love.graphics.draw(emojiTex, chatAreaX + 70, yPos + 5, 0, 1, 1)
            end
        elseif msg.type == "image" then
            -- 绘制图片消息 (这里只显示占位符，实际项目中需要异步加载图片)
            love.graphics.setColor(0.5, 0.5, 1)
            love.graphics.rectangle("line", chatAreaX + 70, yPos + 5, 100, 80)
            love.graphics.print("图片: " .. msg.content, chatAreaX + 80, yPos + 45)
        end
    end
end

-- 绘制表情面板
function drawEmojiPanel()
    local panelX = 50
    local panelY = love.graphics.getHeight() - 200
    local panelW = 200
    local panelH = 100

    love.graphics.setColor(0.25, 0.25, 0.25)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH)

    local cols = 5
    for i, tex in ipairs(emojiTextures) do
        local row = math.floor((i - 1) / cols)
        local col = (i - 1) % cols
        local x = panelX + col * (emojiSize + 5)
        local y = panelY + row * (emojiSize + 5)
        love.graphics.draw(tex, x, y, 0, 1, 1)
    end
end

-- 加载聊天历史记录
function loadChatHistory()
    if love.filesystem.getInfo(historyFile) then
        local contents, size = love.filesystem.read(historyFile)
        if contents then
            messages = json.decode(contents) or {}
            print("已加载 " .. #messages .. " 条聊天记录")
        end
    end
end

-- 保存聊天历史记录
function saveChatHistory()
    local data = json.encode(messages, {indent = true})
    love.filesystem.write(historyFile, data)
end

-- 加载表情图片
function loadEmojis()
    local files = love.filesystem.getDirectoryItems("assets/emojis")
    for _, file in ipairs(files) do
        local path = "assets/emojis/" .. file
        if love.filesystem.getInfo(path, "file") then
            local tex = love.graphics.newImage(path)
            table.insert(emojiTextures, tex)
        end
    end
end