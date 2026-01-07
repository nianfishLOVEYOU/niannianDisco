local colors = require "glove/colors"
local enet = require "enet"
local ui = require "src.ui.ui"

local MenuUI = {
    state = {
        code = "0000",
        playername = "小比噶"
    }
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
        self.stack:draw(self.posx, self.posy)
    end
end

function MenuUI:getvstack()
    local vstackchild = {}

    local linkButton = Glove.Button("link", {
        buttonColor = colors.red,
        labelColor = colors.yellow,
        onClick = function()
            print("got click")
            if (string.len(self.state.code) == 4 and self.state.playername ~= "") then
                -- 转游戏进程
                print("menu code =", self.state.code)
                network:startNetThread(self.state.code)

                playerManager.name = self.state.playername
                local waitingUI = require("src.ui.waitingUI"):new()
                uiManager:addUI("waitingUI", waitingUI)
            end
        end
    })

    local inputCode = Glove.Input(self.state, "code", {
        width = 100
    })

    local inputPlayerName = Glove.Input(self.state, "playername", {
        width = 100
    })
    -- 房间号输入
    local first = Glove.HStack({
        align = "start",
        spacing = 0
    }, {Glove.Text("输入cod:", {
        color = colors.red
    }), inputCode})
    -- 名字输入
    local second = Glove.HStack({
        align = "start",
        spacing = 0
    }, {Glove.Text("输入name:", {
        color = colors.red
    }), inputPlayerName})

    local bt = Glove.HStack({
        align = "start",
        spacing = 0
    }, {linkButton})

    table.insert(vstackchild, first)
    table.insert(vstackchild, second)
    table.insert(vstackchild, bt)

    local stack = Glove.VStack({
        spacing = 30
    }, vstackchild -- Glove.Spacer()
    )
    return stack
end

function MenuUI:destroy()
    eventManager:off("connectFail", connectFail)
    eventManager:off("connectSeccess", connectSeccess)
    uiManager:removeUI("waitingUI")
    self.stack:destroy()
end

return MenuUI
