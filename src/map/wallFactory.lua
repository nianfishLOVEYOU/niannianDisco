
-- 壁工厂，负责创建各种类型的墙体
local bodyItem = require "src.item.bodyItem"
local wall = bodyItem:extend()
function wall:init(imgPath, bodyInfo)
    
    self.type="wall"
    self.autoBody=true
    self:setImage("res/image/wall.png")
end


local WallFactory = {
    types = {},
    images = {}   -- name -> 路径
}

-- 遍历 res/image/grid 目录，记录所有图片路径
local wallDir = "res/image/wall"
local wallFiles = love.filesystem.getDirectoryItems(wallDir)
table.sort(wallFiles)

for _, file in ipairs(wallFiles) do
    if file:match("%.png$") or file:match("%.jpg$") or file:match("%.jpeg$") then
        local name = file:gsub("%.[^%.]+$", "")
        table.insert(WallFactory.types, name)
        WallFactory.images[name] = wallDir .. "/" .. file
    end
end


function WallFactory:newWall(type)
    if not self.images[type] then
        error("未知的 wall 类型：" .. type)
    else
        local wall = wall:new(self.images[type])
        return wall
    end
end

return WallFactory