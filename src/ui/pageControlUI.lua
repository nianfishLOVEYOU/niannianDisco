-- 显示一个左滑右滑的ui可以右滑就显示左边箭头，左滑就显示右边箭头，点击箭头可以切换页面
-- 页面管理ui
local ui = require "src.ui.ui"

local pageControlUI = ui:extend()

function pageControlUI:init()
    self.currentPage = 1
    self.pages = {}

    local playerUI = require("src.ui.playerUI"):new()
    uiManager:addUI("playerUI", playerUI)
    self:addChild(playerUI)

    self:refresh()

end

function pageControlUI:update(dt)

end
---------------播放列表------------

-- 更新播放列表显示
function pageControlUI:refresh()
    -- 创建本地列表
    self:clearStacks()
    self:buildPage()

end

-- 获得播放列表ui
function pageControlUI:buildPage()
    -- 加载第一页

    local page1UI = require("src.ui.page1UI"):new()
    uiManager:addUI("page1UI", page1UI)
    self.pages[1] = page1UI
    local page2UI = require("src.ui.page2UI"):new()
    page2UI.visiable = false
    uiManager:addUI("page2UI", page2UI)
    self.pages[2] = page2UI

    local tabList = {{
        label = "一起听"
        -- widget = page1UI
    }, {
        label = "篝火堆"
        -- widget = page2UI
    }}

    -- 3. 创建Tabs控件实例
    local tabWidget = Glove.Tabs:new(tabList, {
        color = {1, 1, 1}, -- 标签条颜色
        backgroundColor = {0, 0, 0}, -- 标签条背景颜色
        lineColor = {1, 1, 1}, -- 标签条下划线颜色
        onChange = function(newIndex)
            self:turnPage(newIndex)
        end
    })
    self.tab = tabWidget

    local stack = Glove.VStack:new({tabWidget}, 10)
    stack:setPos(love.graphics.getWidth() / 2 - 50, love.graphics.getHeight() - 140)
    self:addStack(stack)

    self:turnPage(1)
end

local animationIsOver = true
function pageControlUI:turnPage(index)

    if index == 1 then
        self:_toUi()
        return
    elseif index == 2 then
        self:_toPlayer()
        return
    end

    if not animationIsOver then
        return
    end

    local newPage = index
    if newPage < 1 or newPage > #self.pages then
        return
    end

    -- 播放切换页面动画
    local width = love.graphics.getWidth()
    for k, v in pairs(self.pages) do
        animation:addAnimation(v, {
            localX = v.localX - width * (newPage - self.currentPage)
        }, 0.3, {
            onComplete = function()
                animationIsOver = true
            end
        })
    end
    self.currentPage = newPage
    animationIsOver = false

    -- self:refresh()
end

function pageControlUI:_toPlayer()
    playerManager.playerControl.playerAction = true
    if playerManager.player then --移动摄像机到玩家
        cameraManager:setTarget(playerManager.player.x, playerManager.player.y)
    end
    self:_TurnP2Ani()
end

function pageControlUI:_toUi()
    playerManager.playerControl.playerAction = false
    if playerManager.player then --移动摄像机离开玩家
        cameraManager:setTarget(-100, playerManager.player.y)
    end
    self:_TurnP1Ani()
end

function pageControlUI:_TurnP1Ani()
    self.tab.interaction = false
    aniExtend.uiLeftIn(self.pages[1], 0.8, 500, function()
        self.tab.interaction = true
    end)
    -- aniExtend.uiLeftOut(self.pages[2], 0.3, 100)
end

function pageControlUI:_TurnP2Ani()
    self.tab.interaction = false
    aniExtend.uiLeftOut(self.pages[1], 0.8, 500, function()
        self.tab.interaction = true
    end)
    -- aniExtend.uiLeftIn(self.pages[2], 0.3, 100)
end

function pageControlUI:destroy()
    pageControlUI.super.destroy(self)

end

function pageControlUI:mouse()

end

return pageControlUI

