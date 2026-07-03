-- Item.lua
local object = require "src.common.object"
local ItemFactory = object:extend()

--path要是/格式的
function ItemFactory:init(path)
    self.types = {}
    self.news = {}

    -- 自动加载 src/item/items 目录下的所有 Lua 文件，注册为可用的 item 类型
    local itemFiles = love.filesystem.getDirectoryItems(path)
    table.sort(itemFiles)
    local excludedModules = {
        item = true,
        bodyItem = true,
        imageItem = true
    }

    for _, file in ipairs(itemFiles) do
        if file:match("%.lua$") then
            local module = file:gsub("%.lua$", "")
            if not excludedModules[module] then
                table.insert(self.types, module)
                self.news[module] = require(path .. "/" .. module)
            end
        end
    end
end

function ItemFactory:newItem(type)
    if not self.news[type] then
        error("未知的 item 类型：" .. type)
    else
        local item = self.news[type]:new()
        return item
    end
end

return ItemFactory
