local ui = require "src.ui.ui"

local dialogUI = ui:extend()

local dialogW = 120
local dialogH = 150

function dialogUI.keyboard(key)
    if key == "enter" then
        if dialogUI.message ~= "" then
            dialogUI:_sendMessage(dialogUI.message)
            dialogUI.message = ""
            dialogUI.inputMessageBox:setText("")
        end
    end
end

function dialogUI:init()
    self.name = "dialogUI"
    self.message = ""
    self:refresh()
    self.keyboardEvent = systemManager:keypressed_regester(function(key)
        -- print("dialog got key", key)

        if key == "return" and Glove.isFocused(self.inputMessageBox) then
            if self.message ~= "" then
                self:_sendMessage(self.message)
                self.message = ""
                self.inputMessageBox:setText("")
            end
        end
    end)
    self.z = 100
end

-- 更新播放列表显示
function dialogUI:refresh()
    self:clearStacks()
    self:_buildChatRoom()
    self:_buildInputBox()
    self:SeeChatRoom(false)
end

-- 聊天历史记录
function dialogUI:_buildChatRoom()
    -- 滑动条
    local slidePanel = Glove.SlidePanel:new()
    self:addStack(slidePanel)
    slidePanel:setSize(dialogW, dialogH)
    slidePanel:setName("dialog chatroom slidePanel")

    self.ChatRoomSlidePanel = slidePanel
end

-- 输入框
function dialogUI:_buildInputBox()
    self.inputMessageBox = Glove.Input:new(self.message, function(input)
        self.message = input
    end)
    self.inputMessageBox:setSize(80, 20)

    --发送按钮
    local sendButton = Glove.Button:new("发送", function()
        print("got click", self.message)
        if self.message ~= "" then
            self:_sendMessage(self.message)
            self.message = ""
            self.inputMessageBox:setText("")
        end
    end)
    sendButton.color = {1, 0, 0}
    sendButton:setSize(40, 20)

    --显示历史记录按钮
    local printHistoryButton = Glove.Button:new("历史", function()
        self:SeeChatRoom(not self.ChatRoomSlidePanel.visiable)
    end)
    printHistoryButton.color = {0.1, 0.5, 1}
    printHistoryButton:setSize(40, 20)

    local hstack = Glove.HStack:new({sendButton, printHistoryButton}, 5)
    local Vstack = Glove.VStack:new({self.inputMessageBox, hstack}, 5)
    Vstack:setName("dialog input vstack")
    self:addStack(Vstack)

    local playerUI = uiManager:getUI("playerUI")
    Vstack:setPos(playerUI.buttonHStack.x + playerUI.buttonHStack.w +10 , playerUI.buttonHStack.y )
    -- Vstack:setPos(playerUI.playerStack.x + playerUI.playerStack.w +
    --Vstack:setPos(0, dialogH + 10)
end

function dialogUI:SeeChatRoom(bool)

    self.ChatRoomSlidePanel:setVisiable(bool)
    -- self.inputMessageBox:setVisiable(bool)
    self.ChatRoomSlidePanel:setPos(250, 30)
end

function dialogUI:_sendMessage(string)
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
function dialogUI:_getPlayerHead(id)
    -- local image = Glove.Image:new("res/image/head.png")
    local name = Glove.Text:new("玩家" .. id)
    return name
end

-- 添加消息hstack
function dialogUI:addMessage(string, playerId)
    print("addMessage", string, playerId)
    -- 左边是消息，右边是玩家头像
    local message = Glove.Text:new(playerId .. ":" .. string)
    message:setSize(dialogW-30, 0)
    self.ChatRoomSlidePanel:add(message)

    local playerListUI = uiManager:getUI("playerlistUI")
    if playerListUI and playerListUI:getRealVisiable() then
        playerListUI:playerTalk(playerId, string)
    end
end

function dialogUI:draw()
    -- 画一个底色方块
    dialogUI.super.draw(self)
end

function dialogUI:update(dt)

end

function dialogUI:destroy()
    systemManager:removeFunc(self.keyboardEvent)
    dialogUI.super.destroy(self)
end

return dialogUI
