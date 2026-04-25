local ItemFactory = {
    types = {},
    news = {}
}

-- 自动加载 src/item 目录下的所有 Lua 文件，注册为可用的 item 类型
local itemFiles = love.filesystem.getDirectoryItems("src/item")
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
            table.insert(ItemFactory.types, module)
            ItemFactory.news[module] = require("src.item." .. module)
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