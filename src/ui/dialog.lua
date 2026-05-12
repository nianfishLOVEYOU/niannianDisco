local ui = require "src.ui.ui"

local dialog = ui:extend()

function dialog:init()
    self.message = ""
    self:refresh()

end

-- 更新播放列表显示
function dialog:refresh()
    self:clearStacks()
    self:_buildChatRoom()
    self:_buildInputBox()
end

-- 聊天历史记录
function dialog:_buildChatRoom()
    local title = Glove.HStack:new({ Glove.Text:new("tmp本地列表:") })
    title:setName("title tmp")

    local vstack = Glove.VStack:new({ title, listVstack }, 10)
    --滑动条
    local slidePanel = Glove.SlidePanel:new()
    slidePanel:setPos(50, 100, self.z)
    slidePanel:setSize( love.graphics.getWidth() - 100, 200)
    slidePanel:setName("dialog chatroom slidePanel")
    vstack:setPos(0, 0) --大概是拖拽条的限制归为问题
    self:addStack(slidePanel)

    self.ChatRoomSlidePanel = slidePanel
end

-- 输入框
function dialog:_buildInputBox()
    self.inputMessageBox = Glove.Input:new(self.message, function(input)
        self.message = input
    end)
    self.inputMessageBox:setSize(100, 20)
    local sendButton = Glove.Button:new("send", function()
        print("got click", self.message)
        if self.message ~= "" then
            self:_sendMessage(self.message)
            self.message = ""
            self.inputMessageBox:setText("")
        end
    end)
    local hstack = Glove.HStack:new({self.inputMessageBox, sendButton}, 5)
    hstack:setName("dialog input hstack")
    hstack:setPos(love.graphics.getWidth() - 200, 320)
    self:addStack(hstack)
end

function dialog:_sendMessage(string)
    -- 发送列表
    local msg = {
        type = "chatMessage",
        message = string,
        userid = network.userid
    }
    network:send_Broadcast(msg)
    self:addMessage(string, network.userid)
end

-- 玩家头像
function dialog:_getPlayerHead(id)
    --local image = Glove.Image:new("res/image/head.png")
    local name = Glove.Text:new("玩家"..id)
    return name
end

-- 添加消息hstack
function dialog:addMessage(string, playerId)
    print ("addMessage", string, playerId)
    --左边是消息，右边是玩家头像
    local message = Glove.Text:new(": ".. string)
    message:setSize(200,0)
    local hstack = Glove.HStack:new({self:_getPlayerHead(playerId),message}, 10)
    self.ChatRoomSlidePanel:add(hstack)
end

function dialog:draw()
    -- 画一个底色方块
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.rectangle("fill", 50, 100, love.graphics.getWidth() - 100, 200)
    love.graphics.setColor(1, 1, 1)

    dialog.super.draw(self)
end

function dialog:update(dt)

end

function dialog:destroy()
    dialog.super.destroy(self)
end

return dialog
