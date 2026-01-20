local FileManager = {
}

systemManager:init_regester(function()
    -- 创建目录
    FileManager.createDir(commonData.tmpPath)
    FileManager.createDir("info/")
end)

systemManager:quit_regester(function()
    -- FileManager:clearTempFile()
end)

-- path 为完整路径
FileManager.get_dir = function(path)
    -- 先去掉结尾可能的斜杠/反斜杠，防止 “C:\folder\” 这种情况返回空
    local clean = path:gsub("[/\\]+$", "")
    -- 捕获最后一个斜杠/反斜杠之前的所有字符（包括可能的盘符）
    local dir = clean:match("^(.*[\\/])")
    -- 如果没有斜杠（说明是纯文件名），返回空字符串或 "."（当前目录）自行决定
    return dir or ""
end

-- 创建路径
FileManager.createDir = function(dirpath)
    local directory = dirpath
    local dirInfo = love.filesystem.getInfo(directory)
    if not dirInfo then
        print("! dir creat !" .. dirpath)
        love.filesystem.createDirectory(directory)
    else
        print("! dir exsit !" .. dirpath)
    end
end

function FileManager:fileIsExsit(path)
    local info = love.filesystem.getInfo(path)
    if not info then
        return false
    end
    return true -- 直接返回字节数
end

--检查所有文件夹，找到路径
function FileManager:getFilePathByName(name)
    local path = commonData.tmpPath .. name
    local info = love.filesystem.getInfo(path)
    if info then
        return path, info
    end
    return nil -- 直接返回字节数
end

local function getFileSize_love(path)
    local info = love.filesystem.getInfo(path)
    if not info then
        return nil, "! file cant find !"
    end
    return info.size -- 直接返回字节数
end

function FileManager:getFilename(path)
    -- 1）先把 Windows 反斜杠统一成正斜杠，方便后面的模式匹配
    local normalized = path:gsub("\\", "/")
    -- 2）使用 Lua 的模式匹配，取最后一个 “/” 之后的所有字符
    --    pattern 解释：
    --      ([^/]+)   → 捕获除 “/” 之外的连续字符（即文件名）
    --      $         → 必须出现在字符串末尾
    local filename = normalized:match("([^/]+)$")
    return filename
end

-- 获得路径
function FileManager:getExtension(path)
    -- 1. 先去掉查询字符串和锚点（?xxx#xxx）
    local clean = path:gsub("[?#].*$", "")

    -- 2. 只保留最后一个路径分隔符之后的部分
    --    支持 Windows（\）和 Unix（/）两种分隔符
    local filename = clean:match("^.+[\\/](.+)$") or clean

    -- 3. 处理点号开头的隐藏文件（如 .gitignore）——这类文件没有真正的后缀
    if filename:sub(1, 1) == "." and not filename:find("%.") then
        return nil
    end

    -- 4. 提取最后一个点号之后的内容
    local ext = filename:match("^.+%.([^%.]+)$")
    return ext -- 若没有匹配到则返回 nil
end

-- 保存表，避免无法序列化的文件
function FileManager:saveTable(tableName, table_in)
    local path = "info/" .. tableName .. ".json"
    -- 保存到本地的路径
    local data = require("lib.json").encode(table_in)

    local success, message = love.filesystem.write(path, data)
    if not success then
        error("! save file fail !: " .. message)
    end
end

-- 读取表，避免无法序列化的文件
function FileManager:readTable(tableName)
    local path = "info/" .. tableName .. ".json"
    -- 保存到本地的路径
    local fileinfo = love.filesystem.getInfo(path)
    if not fileinfo then
        print("! fileManager:readTable nil !: " .. path)
        return nil
    end

    local contents = love.filesystem.read(path)

    local ok, result = pcall(require("lib.json").decode, contents)
    if ok then
        return result
    end

    return nil
end

-- 在 main.lua 的 love.filedropped 中
function love.filedropped(file)
    -- 或者是文件夹
    local fullname = file:getFilename()
    local name = fullname:match("([^/\\]+)$") or fullname -- 从路径里提取文件名字
    local extend = FileManager:getExtension(name)

    eventManager:emit("fileDrop", file, name, fullname, extend)
    print("【filedropped】")
end

-- type = "file" or "folder"
-- 递归遍历 folder（相对路径）下的所有文件和文件夹,{type,name,filepath,files}
function FileManager:listAllFiles(folder)
    local files = {}
    local items = love.filesystem.getDirectoryItems(folder) -- 返回该目录下的文件+子文件夹名

    for _, name in ipairs(items) do
        local fullPath = folder .. "/" .. name
        if love.filesystem.isFile(fullPath) then
            table.insert(files, { type = "file", name = name, path = fullPath }) -- 记录文件路径
        elseif love.filesystem.isDirectory(fullPath) then                        --文件夹
            -- 递归子文件夹
            local sub = FileManager:listAllFiles(fullPath)
            table.insert(files, { type = "folder", name = name, path = fullPath, files = sub })
            for _, p in ipairs(sub) do
            end
        end
    end
    return files
end

-- 删除 folder（相对路径）下的所有文件（包括子文件夹里的文件），并可选删除空文件夹
function FileManager:deleteAllFiles(folder)
    local allFiles = FileManager:listAllFiles(folder)

    local function deleteFiles (files)
        for _, fileInfo in ipairs(files) do
            if fileInfo.type == "file" then
                local ok, err = love.filesystem.remove(fileInfo.path)
                if not ok then
                    print("[WARN] 删除文件失败:", path, err)
                else
                    print("[INFO] 已删除文件:", path)
                end
            elseif fileInfo.type == "folder" then
                deleteFiles(fileInfo.files)
            end

        end
    end

    deleteFiles(allFiles)
end

function FileManager:clearTempFile()
    self:deleteAllFiles("tmp")
end

--打开音乐文件夹
function FileManager.openMusicDirectory()
    -- 获取 Love2D 自带的存档目录
    local saveDir = love.filesystem.getSaveDirectory() .. commonData.musicPath
    print("游戏存档目录：" .. saveDir)

    -- 打开这个目录
    if love.system.getOS() == "Windows" then
        os.execute('explorer "' .. saveDir .. '"')
    elseif love.system.getOS() == "OS X" then
        os.execute('open "' .. saveDir .. '"')
    elseif love.system.getOS() == "Linux" then
        os.execute('xdg-open "' .. saveDir .. '"')
    end
end


return FileManager
