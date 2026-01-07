-- resource.lua
local ResourceManager = {}

-- 统一的图片加载函数
function ResourceManager.loadImage(path)
    -- love.filesystem 能直接读取相对路径的文件
    local info = love.filesystem.getInfo(path)
    if info and info.type == "file" then
        local img=love.graphics.newImage(path)
        img:setFilter("nearest", "nearest")
        return img
    else
        -- 文件不存在时返回 nil，调用方自行决定 fallback
        return nil
    end
end

return ResourceManager