-- 显示一个左滑右滑的ui可以右滑就显示左边箭头，左滑就显示右边箭头，点击箭头可以切换页面
-- 页面管理ui
local ui = require "src.ui.ui"

local pageControlUI = ui:extend()

function pageControlUI:init()
    self.currentPage = 1
    self.pages = {}
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
    uiManager:addUI("page2UI", page2UI)
    self.pages[2] = page2UI

    -- 加载切换页面的按钮
    -- local leftButton = Glove.Button_img:new("", "res/image/ui/left.png", {
    --     mousePressed = function()
    --         self:turnPage(-1)
    --     end
    -- })
    -- local rightButton = Glove.Button_img:new("", "res/image/ui/right.png", {
    --     mousePressed = function()
    --         self:turnPage(1)
    --     end
    -- })

end

local animationIsOver = true
function pageControlUI:turnPage(direction)
    if not animationIsOver then
        return
    end
    
    local newPage = self.currentPage + direction
    if newPage < 1 or newPage > #self.pages then
        return
    end
    self.currentPage = newPage

    -- 播放切换页面动画
    local width = love.graphics.getWidth()
    for k, v in pairs(self.pages) do
        animation:addAnimation(v, {localX=v.localX-width*direction}, 0.3, {
            onComplete = function()
                animationIsOver = true
            end
        })
    end
    animationIsOver = false

    -- self:refresh()
end

function pageControlUI:destroy()
    pageControlUI.super.destroy(self)

end

function pageControlUI:mouse()

end

return pageControlUI

