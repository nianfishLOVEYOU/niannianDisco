local ui = require "src.ui.ui"

local MenuUI = ui:extend()

local connectFail = function()
    uiManager:removeUI("waitingUI")
end

local connectSeccess = function()
    statusManager:statusChange("game")
end

function MenuUI:init()
    self.code = "0000"
    self.playername = "小比噶"
    self.posx = 100
    self.posy = 100
    self:refresh()
    eventManager:on("connectFail", connectFail)
    eventManager:on("connectSeccess", connectSeccess)
end

---------------播放列表------------

-- 更新播放列表显示
function MenuUI:refresh()
    -- 创建本地列表

    self:clearStacks()
    self:addStack(self:getvstack())
end

function MenuUI:update(dt)
    local waitingUI = uiManager:getUI("waitingUI")
    if waitingUI then
        -- 超出等待上限
        if waitingUI.time > 10 then
            uiManager:removeUI("waitingUI")
            network:closeNetThread()
        end
    end
end

function MenuUI:draw()
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle('fill', self.posx - 20, self.posy - 20, 200, 200)
    self:drawStacks()
end

function MenuUI:getvstack()
    local linkButton = Glove.Button:new("link", function()
        print("got click")
        if (string.len(self.code) == 4 and self.playername ~= "") then
            -- 转游戏进程
            print("menu code =", self.code)
            network:startNetThread(self.code)

            playerManager.name = self.playername
            local waitingUI = require("src.ui.waitingUI"):new()
            uiManager:addUI("waitingUI", waitingUI)
        end
    end)

    local inputCode = Glove.Input:new(self.code, function(input)
        self.code = input
    end)
    inputCode:setSize(100, 20)

    local inputPlayerName = Glove.Input:new(self.playername, function(input)
        self.playername = input
    end)
    inputPlayerName:setSize(100, 20)


    -- 房间号输入
    local first = Glove.HStack:new({ Glove.Text:new("输入cod:"), inputCode })
    
    -- 名字输入
    local second = Glove.HStack:new({ Glove.Text:new("输入name:"), inputPlayerName })

    -- local slider = Glove.Slider:new(0, 0, 200, 20, 0, function(input)
    --     self.code = input
    -- end)
    local bt = Glove.HStack:new({ linkButton })

    local stack = Glove.VStack:new({first,second,bt,Toggle},10)
    stack.spacing = 10

    stack:setPos(self.posx, self.posy,self.z)
    return stack
end

function MenuUI:destroy()
    MenuUI.super.destroy(self)
    eventManager:off("connectFail", connectFail)
    eventManager:off("connectSeccess", connectSeccess)
    uiManager:removeUI("waitingUI")
end

return MenuUI
