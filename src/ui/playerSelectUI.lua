local ui = require "src.ui.ui"
local fileManager = require "src.manager.fileManager"
local globleManager = require "src.manager.globleManager"
local playerManager = require "src.manager.playerManager"

local PlayerSelectUI = {}
PlayerSelectUI.__index = PlayerSelectUI
setmetatable(PlayerSelectUI, { __index = ui })

function PlayerSelectUI:new()
    local obj = ui:new()
    setmetatable(obj, PlayerSelectUI)
    obj:init()
    return obj
end

local DEFAULTS = {
    "res/image/player1.png",
    "res/image/player2.png",
    "res/image/sher.png",
    "res/image/shaoge.png",
}

function PlayerSelectUI:init()
    -- place UI on right half of the screen
    local screenW = love.graphics.getWidth()
    self.x = math.floor(screenW / 2)
    self.w = math.floor(screenW / 2)
    self.h = 360
    self.y = (love.graphics.getHeight() - self.h) / 2
    self.padding = 16

    -- load images list from globleManager
    local saved = globleManager:getGameData("playerImages") or {}
    self.images = {}
    -- load defaults first
    for _, p in ipairs(DEFAULTS) do
        local ok, img = pcall(love.graphics.newImage, p)
        if ok then table.insert(self.images, {path = p, image = img}) end
    end
    -- then saved ones
    for _, p in ipairs(saved) do
        local ok, img = pcall(love.graphics.newImage, p)
        if ok then table.insert(self.images, {path = p, image = img}) end
    end

    self.selected = 1

    -- Check for previously selected player image
    local lastSelected = globleManager:getGameData("selectedPlayerImage")
    if lastSelected then
        for i, img in ipairs(self.images) do
            if img.path == lastSelected then
                self.selected = i
                break
            end
        end
    end

    -- register drop and mouse
    local function onFileDrop(file, name, fullname, extend)
        local mx, my = love.mouse.getPosition()
        -- only accept when dropped inside our UI box
        if mx < self.x or mx > self.x + self.w or my < self.y or my > self.y + self.h then
            return
        end
        extend = extend and extend:lower()
        if not (extend == "png" or extend == "jpg" or extend == "jpeg") then return end

        local tmpPath = "tmp/Image/" .. name
        if fileManager:fileIsExsit(tmpPath) then
            -- already exists, just add
        else
            local data = file:read()
            love.filesystem.createDirectory("tmp/image")
            local ok, msg = love.filesystem.write(tmpPath, data)
            if not ok then print("save drop fail", msg); return end
        end

        -- add to list and save via globleManager
        table.insert(self.images, { path = tmpPath, image = love.graphics.newImage(tmpPath) })
        -- persist path list
        local saved = globleManager:getGameData("playerImages") or {}
        table.insert(saved, tmpPath)
        globleManager:saveGameData("playerImages", saved)
    end

    eventManager:on("fileDrop", onFileDrop)
    self._onFileDrop = onFileDrop

    local function onMousePressed(x, y, button)
        if x < self.x or x > self.x + self.w or y < self.y or y > self.y + self.h then return end
        -- calculate grid with small thumbnails (32x32)
        local thumbW = 32
        local thumbH = 32
        local pad = 8
        local startX = self.x + self.padding
        local startY = self.y + self.padding + 24
        local cols = math.max(1, math.floor((self.w - self.padding * 2 + pad) / (thumbW + pad)))
        for i, it in ipairs(self.images) do
            local col = (i-1) % cols
            local row = math.floor((i-1) / cols)
            local ix = startX + col * (thumbW + pad)
            local iy = startY + row * (thumbH + pad)
            if x >= ix and x <= ix + thumbW and y >= iy and y <= iy + thumbH then
                self.selected = i
                self:confirmSelection()
                return
            end
        end
    end
    eventManager:on("event_mousePressed", onMousePressed)
    self._onMouse = onMousePressed
end

function PlayerSelectUI:confirmSelection()
    local sel = self.images[self.selected]
    if not sel then return end
    globleManager:saveGameData("selectedPlayerImage", sel.path)
    -- also set playerManager preview
    playerManager.selectedImage = sel.path
    --uiManager:removeUI("playerSelectUI")
end

function PlayerSelectUI:draw()
    love.graphics.setColor(0,0,0,0.6)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, 8,8)
    love.graphics.setColor(1,1,1)
    love.graphics.print("选择角色（可拖入图片）", self.x + 12, self.y + 8)

    local thumbW = 32
    local thumbH = 32
    local pad = 8
    local startX = self.x + self.padding
    local startY = self.y + self.padding + 24
    local cols = math.max(1, math.floor((self.w - self.padding * 2 + pad) / (thumbW + pad)))
    for i, it in ipairs(self.images) do
        local col = (i-1) % cols
        local row = math.floor((i-1) / cols)
        local ix = startX + col * (thumbW + pad)
        local iy = startY + row * (thumbH + pad)
        love.graphics.setColor(0.2,0.2,0.2)
        love.graphics.rectangle("fill", ix, iy, thumbW, thumbH, 4,4)
        if it.image then
        love.graphics.setColor(1,1,1)
            local iw = it.image:getWidth()
            local ih = it.image:getHeight()
            local scale = math.min(thumbW/iw, thumbH/ih, 1)
            love.graphics.draw(it.image, ix + (thumbW - iw*scale)/2, iy + (thumbH - ih*scale)/2, 0, scale, scale)
        end
        if i == self.selected then
            love.graphics.setColor(1,1,0)
            love.graphics.circle("fill", ix + thumbW/2, iy + 8, 6)
        end
    end

end

function PlayerSelectUI:destroy()
    if self._onFileDrop then eventManager:off("fileDrop", self._onFileDrop) end
    if self._onMouse then eventManager:off("event_mousePressed", self._onMouse) end
end

return PlayerSelectUI
