local ui = require "src.ui.ui"
local imageItem = require "src.item.imageItem"

local PlayerlistUI = ui:extend()

function PlayerlistUI:init()
    self:refresh()
    self.playerItems = {}

    self:setPos(20, uiManager:getUI("playerUI").playerStack.y - 150)
    self:addPlayer(network.userid, playerManager.name)
end

local waittime = os.time()
function PlayerlistUI:update(dt)
    if os.time() - waittime > 1 then
        self:refresh()
        waittime = os.time()
    end
end
---------------播放列表------------

-- 更新播放列表显示
function PlayerlistUI:refresh()
    -- 创建本地列表
    self:clearStacks()

    self:buildUI()
end

function PlayerlistUI:removePlayer(id)
    if self.playerItems[id] then
        -- self.playerItems[id].psd:destroy()
        self.playerItems[id].text:destroy()
        self.playerItems[id] = nil
    end
end

function PlayerlistUI:addPlayer(id, name)
    print("添加玩家", id, name)
    self.playerItems[id] = {
        text = Glove.Text:new(name, 0),
        -- psd = artal.newPSD("res/image/ui/playerlistUI.psd"),
        image = Glove.Image:new("res/image/ui/nian_littleSmail.png")
    }
    if id == network.userid then
        self.playerItems[id].text.color = {1, 0, 0, 1}
    end
    self:addChild(self.playerItems[id].image)
    self:addChild(self.playerItems[id].text)
    self.playerItems[id].image:setScale(0.3, 0.3)
    self:updatePlayers()
end

-- 玩家动画
function PlayerlistUI:updatePlayers()
    local index = 0
    local startY = -10
    for id, player in pairs(self.playerItems) do
        -- 更新玩家图片位置，依次排开
        player.pos = {
            x = 50 + (index) * 50,
            y = self.y + player.image.h + startY
        }
        player.image:setPos(50 + (index) * 50, self.y + player.image.h + startY + 20, self.z)
        player.text:setPos(50 + (index) * 50 + player.image.w / 3, self.y + player.image.h + startY, self.z)
        index = index + 1
        timer:after(0.1, function()
            aniExtend.move8(player.image, 2, 3, function()
            end)
        end)

    end
end

function PlayerlistUI:update(dt)

end

-- 聊天接口
function PlayerlistUI:playerTalk(id, text)
    if self.playerItems[id] then
        -- self.playerItems[id].text:setText(text)

        floatUI:addDialogueBox(text, self.playerItems[id].image.x - 100, self.playerItems[id].image.y - 40, {
            typeSpeed = 10,
            autoClose = 4,
            tailX = self.playerItems[id].image.x,
            tailY = self.playerItems[id].image.y
        })

        aniExtend.end_move8(self.playerItems[id].image)
        aniExtend.jump(self.playerItems[id].image, 0.5, 20, function()
            timer:after(0.1, function()
                self.playerItems[id].image:setPos(self.playerItems[id].pos.x, self.playerItems[id].pos.y, self.z)
                aniExtend.move8(self.playerItems[id].image, 2, 3, function()
                end)
            end)
        end)
    end
end

-- 获得播放列表ui
function PlayerlistUI:buildUI()

    local vstackchild = {}
    local text = Glove.Text:new("房间里的小伙伴:", 0)
    text.outline = true
    local roomguy = Glove.VStack:new({text})

    self:addStack(roomguy)
    roomguy:setLocalPos(50, 30, self.z)
    self.roomguy = roomguy
end

function PlayerlistUI:draw()
    PlayerlistUI.super.draw(self)
    for k, v in pairs(self.playerItems) do
        -- v.psd:draw()
        v.image:draw()
        v.text:draw()
    end
end

return PlayerlistUI
