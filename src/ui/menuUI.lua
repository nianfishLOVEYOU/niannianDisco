local colors = require "glove/colors"
local enet = require "enet"
local ui = require "src.ui.ui"

local MenuUI = {
    code = "0000",
    playername = "小比噶"
}
MenuUI.__index = MenuUI
setmetatable(MenuUI, {
    __index = ui
}) -- 子类继承父类
function MenuUI:new(...)
    local obj = ui:new(...) -- 先走父类构造
    setmetatable(obj, MenuUI) -- 再把实例的元表改为子类
    -- 初始化子类特有属性
    return obj
end

local connectFail = function()
    uiManager:removeUI("waitingUI")
end

local connectSeccess = function()
    statusManager:statusChange("game")
end

function MenuUI:init()
    MenuUI.posx = 100
    MenuUI.posy = 100
    MenuUI:refresh()
    eventManager:on("connectFail", connectFail)
    eventManager:on("connectSeccess", connectSeccess)
end

---------------播放列表------------

-- 更新播放列表显示
function MenuUI:refresh()
    -- 创建本地列表
    if self.stack then
        self.stack:destroy()
    end
    self.stack = self:getvstack()
    self.stack:setPos(self.posx, self.posy)
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
    if self.stack then
        self.stack:draw()
    end
end

function MenuUI:getvstack()
    local vstackchild = {}

    local linkButton = Glove.Button:new(0, 0, 0, 0, "link", function()
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

    local inputCode = Glove.Input:new(0, 0, 100, 20, self.code, function(input)
        self.code = input
    end)

    local inputPlayerName = Glove.Input:new(0, 0, 100, 20, self.playername, function(input)
        self.playername = input
    end)

    -- 房间号输入
    local first = Glove.HStack:new(0, 0, 0, 0, {Glove.Text:new(0, 0, 0, 0, "输入cod:"), inputCode})

    -- 名字输入
    local second = Glove.HStack:new(0, 0, 0, 0, {Glove.Text:new(0, 0, 0, 0, "输入name:"), inputPlayerName})

    local slider = Glove.Slider:new(0, 0, 200, 20, 0, function(input)
        self.code = input
    end)
    local bt = Glove.HStack:new(0, 0, 0, 0, {linkButton,slider})

    
    table.insert(vstackchild, first)
    table.insert(vstackchild, second)
    table.insert(vstackchild, bt)

    local stack = Glove.VStack:new(0, 0, 0, 0, vstackchild)
    stack.spacing=10
    return stack
end

function MenuUI:destroy()
    eventManager:off("connectFail", connectFail)
    eventManager:off("connectSeccess", connectSeccess)
    uiManager:removeUI("waitingUI")
    self.stack:destroy()
end

return MenuUI
