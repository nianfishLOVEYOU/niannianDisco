-- 聊天界面
-- 粘的立绘
-- 目前在播放的歌,歌单界面
local json = require "lib.json"
local ui = require "src.ui.ui"

local page1UI = ui:extend()

function page1UI:init()
    local playerUI = require("src.ui.playerUI"):new()
    uiManager:addUI("playerUI", playerUI)
    self:addChild(playerUI)
    local playlistUI = require("src.ui.playlistUI"):new()
    uiManager:addUI("playlistUI", playlistUI)
    self:addChild(playlistUI)
    -- 立绘ui
    local nianocUI = require("src.ui.nianocUI"):new()
    uiManager:addUI("nianocUI",nianocUI)
    self:addChild(nianocUI)
    local roomUI = require("src.ui.roomUI"):new()
    uiManager:addUI("roomUI", roomUI)
    self:addChild(roomUI)
    


    self:refresh()
end

-- 更新播放列表显示
function page1UI:refresh()
    self:clearStacks()
    self:buildCurrentInfo()
end

function page1UI:buildCurrentInfo()

end

function page1UI:update(dt)

end

function page1UI:dragProgress(progress)
    local duration = audio:getCurrentDuration()
    local newPosition = progress * duration
    audio:seek(newPosition)
    audio:sendUpdatePlayStatus()
end

function page1UI:destroy()
    page1UI.super.destroy(self)
    uiManager:removeUI("playlistUI") -- 播放列表，是在ui内展开的，这里直接remove就行了
    uiManager:removeUI("playerUI")
    uiManager:removeUI("nianocUI")
    uiManager:removeUI("roomUI")

    -- uiManager:removeUI("playerlistUI")
end

return page1UI
