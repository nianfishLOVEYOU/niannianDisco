local ui = require "src.ui.ui"

local dialog = ui:extend()

local dialogW=love.graphics.getWidth() - 100
local dialogH=200

function dialog.keyboard(key)
    if key == "enter" then
        if dialog.message ~= "" then
            dialog:_sendMessage(dialog.message)
            dialog.message = ""
            dialog.inputMessageBox:setText("")
        end
    end
end

function dialog:init()
    self.name="dialog"
    self.message = ""
    self:refresh()
    self.keyboardEvent= systemManager:keypressed_regester(function(key)
        --print("dialog got key", key)

            if key == "return" and Glove.isFocused(self.inputMessageBox) then
        if self.message ~= "" then
            self:_sendMessage(self.message)
            self.message = ""
            self.inputMessageBox:setText("")
        end
    end
    end)
end

-- 更新播放列表显示
function dialog:refresh()
    self:clearStacks()
    self:_buildChatRoom()
    self:_buildInputBox()
end



-- 聊天历史记录
function dialog:_buildChatRoom()
    --滑动条
    local slidePanel = Glove.SlidePanel:new()
    self:addStack(slidePanel)
    slidePanel:setLocalPos(50, 20, self.z)
    slidePanel:setSize( dialogW, dialogH)
    slidePanel:setName("dialog chatroom slidePanel")

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
    sendButton:setSize(50, 20)
    local hstack = Glove.HStack:new({self.inputMessageBox, sendButton}, 5)
    hstack:setName("dialog input hstack")
    hstack:setPos(love.graphics.getWidth() - 200, 240)
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
    -- love.graphics.setColor(1, 1, 1, 0.5)
    -- love.graphics.rectangle("fill", 50, 20, love.graphics.getWidth() - 100, 200)
    -- love.graphics.setColor(1, 1, 1)
    
    dialog.super.draw(self)
end

function dialog:update(dt)

end

function dialog:destroy()
    systemManager:removeFunc(self.keyboardEvent)
    dialog.super.destroy(self)
end

return dialog
