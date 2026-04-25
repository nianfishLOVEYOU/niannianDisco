local spriteAnimation = require "src.common.spriteAnimation"

local GridFactory = {
    types = {},  -- 图片名列表
    images = {}   -- name -> 路径
}

-- 遍历 res/image/grid 目录，记录所有图片路径
local gridDir = "res/image/grid"
local gridFiles = love.filesystem.getDirectoryItems(gridDir)
table.sort(gridFiles)

for _, file in ipairs(gridFiles) do
    if file:match("%.png$") or file:match("%.jpg$") or file:match("%.jpeg$") then
        local name = file:gsub("%.[^%.]+$", "")
        table.insert(GridFactory.types, name)
        GridFactory.images[name] = gridDir .. "/" .. file
    end
end

function GridFactory:newGrid(type)
    if not self.images[type] then
        error("未知的 grid 类型：" .. type)
    else
        local grid = spriteAnimation:new(self.images[type], 32, 32)
        return grid
    end
end

return GridFactory