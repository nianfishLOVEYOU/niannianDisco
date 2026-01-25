local soundManager = {}

soundManager.sources = {}

-- 播放一次性音效，path 是文件路径，volume 可选（0~1），loop 可选
function soundManager:play(path, volume, loop)
    if not path then return end
    local ok, src = pcall(love.audio.newSource, path, "static")
    if not ok or not src then
        print("soundManager: failed to load sound:", path, src)
        return
    end

    if volume then
        src:setVolume(math.max(0, math.min(1, volume)))
    end
    if loop ~= nil then
        src:setLooping(loop and true or false)
    else
        src:setLooping(false)
    end

    table.insert(self.sources, src)
    src:play()
    return src
end

-- 停止并移除一个具体的 source（如果外部保留了引用）
function soundManager:stop(source)
    if not source then return end
    for i = #self.sources, 1, -1 do
        if self.sources[i] == source then
            self.sources[i]:stop()
            table.remove(self.sources, i)
            break
        end
    end
end

-- 每帧更新：清理播放结束的音效
function soundManager:update(dt)
    for i = #self.sources, 1, -1 do
        local s = self.sources[i]
        if (not s:isPlaying()) then
            table.remove(self.sources, i)
        end
    end
end

-- 停止并清空所有音效
function soundManager:stopAll()
    for i = #self.sources, 1, -1 do
        self.sources[i]:stop()
        self.sources[i] = nil
    end
    self.sources = {}
end

return soundManager
