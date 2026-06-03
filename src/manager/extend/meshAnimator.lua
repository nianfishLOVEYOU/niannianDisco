-- ==============================================
-- 1. 全局Mesh管理器（核心模块）
-- ==============================================
local MeshAnimator = {
    meshes = {},          -- 存储所有Mesh实例 {id: {mesh, vertices, animData}}
    currentTime = 0,      -- 全局动画时间（秒）
    isPlaying = true      -- 是否播放动画
}


-- addKeyframe(id, time, data)	定义指定时间点的 Mesh 顶点 / 自定义属性值（关键帧）
-- saveAnimation(id, path)	将动画数据保存为 JSON 文件（可持久化）
-- loadAnimation(id, path)	从 JSON 文件读取动画数据（复用动画）
-- update(dt)	驱动动画：根据当前时间插值计算关键帧之间的数值，自动更新 Mesh
-- interpolateKeyframes(id, time)	核心插值逻辑：线性插值计算两个关键帧之间的顶点 / 属性值（平滑动画）


-- ==============================================
-- 2. Mesh基础操作：创建/顶点修改/四角形变
-- ==============================================

--- 创建基础Mesh（四边形为例，可扩展为任意多边形）
-- @param id: Mesh唯一标识
-- @param x,y: 初始位置
-- @param width,height: 尺寸
function MeshAnimator:createMesh(path, x, y, width, height)
    -- 1. 加载图片（皮肤）
    local texture = love.graphics.newImage(path)
    local id =globleManager:guid()

    local meshSize =2

    -- local vertices={}
    -- for i=1,meshSize do
    --     for j=1,meshSize do
    --          local x = (j-1)*width/(meshSize-1)
    --          local y = (i-1)*height/(meshSize-1)
    --          table.insert(vertices,{x,y,(j-1)/(meshSize-1),(i-1)/(meshSize-1)})
    --     end
    -- end

    -- 四边形顶点（顺序：左下、右下、右上、左上）
    local vertices = {
        {x, y, 0, 0},          -- 顶点1：坐标(x,y)，UV(0,0)
        {x+width, y, 1, 0},    -- 顶点2：坐标(x+width,y)，UV(1,0)
        {x+width, y+height, 1, 1}, -- 顶点3：坐标(x+width,y+height)，UV(1,1)
        {x, y+height, 0, 1}    -- 顶点4：坐标(x,y+height)，UV(0,1)
    }

    -- 创建Love2D Mesh（三角形扇模式，四边形需要2个三角形）
    local mesh = love.graphics.newMesh({
        {"VertexPosition", "float", 2}, -- 顶点位置
        {"VertexTexCoord", "float", 2}  -- UV坐标（纹理用）
    }, vertices, "fan")

    -- 存储Mesh实例
    self.meshes[id] = {
        id = id,
        mesh = mesh,
        w= width,
        h= height,
        originalVertices = deepcopy(vertices), -- 原始顶点（用于复位）
        currentVertices = deepcopy(vertices),  -- 当前顶点
        animData = {                          -- 动画数据
            keyframes = {},                   -- 关键帧：{time: {顶点索引: {x/y}, 全局属性: {}}}
            duration = 0                      -- 动画总时长
        }
    }

    print("Mesh创建成功：ID="..id)
    mesh:setTexture(texture)

    love.graphics.draw(mesh, 200, 200)
    return id
end

function MeshAnimator:getMeshData(id)
    return self.meshes[id]
end




--- 修改单个顶点的坐标
-- @param id: Mesh唯一标识
-- @param vertexIndex: 顶点索引（1-4，对应四边形4个顶点）
-- @param x,y: 新坐标（可选：不传则保留原坐标）
function MeshAnimator:modifyVertex(id, vertexIndex, x, y)
    local meshData = self.meshes[id]
    if not meshData then
        print("错误：Mesh ID="..id.." 不存在")
        return
    end

    -- 验证顶点索引
    if vertexIndex < 1 or vertexIndex > #meshData.currentVertices then
        print("错误：顶点索引超出范围（1-"..#meshData.currentVertices..")")
        return
    end

    -- 更新顶点坐标（保留UV）
    local v = meshData.currentVertices[vertexIndex]
    v[1] = x or v[1]  -- x坐标
    v[2] = y or v[2]  -- y坐标

    -- 同步到Love2D Mesh
    meshData.mesh:setVertices(meshData.currentVertices)
end

--- 四角形变：独立修改四个角的位置（整体形变核心方法）
-- @param id: Mesh唯一标识
-- @param leftBottom: {x,y} 左下角
-- @param rightBottom: {x,y} 右下角
-- @param rightTop: {x,y} 右上角
-- @param leftTop: {x,y} 左上角
function MeshAnimator:quadDeform(id, leftBottom, rightBottom, rightTop, leftTop)
    local meshData = self.meshes[id]
    if not meshData then
        print("错误：Mesh ID="..id.." 不存在")
        return
    end
    --print(string.format("开始四角形变：Mesh ID=%s", id))

    -- 按顺序更新四个顶点（保持UV不变）
    self:modifyVertex(id, 1, leftBottom.x, leftBottom.y)
    self:modifyVertex(id, 2, rightBottom.x, rightBottom.y)
    self:modifyVertex(id, 3, rightTop.x, rightTop.y)
    self:modifyVertex(id, 4, leftTop.x, leftTop.y)

    --print("Mesh "..id.." 四角形变完成")
end

--- 复位Mesh到原始状态
function MeshAnimator:resetMesh(id)
    local meshData = self.meshes[id]
    if not meshData then return end
    meshData.currentVertices = deepcopy(meshData.originalVertices)
    meshData.mesh:setVertices(meshData.currentVertices)
end

-- ==============================================
-- 3. 动画编辑器核心接口（无界面）
-- ==============================================

--- 定义关键帧：指定时间点的Mesh顶点/属性值
-- @param id: Mesh唯一标识
-- @param time: 关键帧时间（秒，如1.5表示1.5秒处）
-- @param keyframeData: 关键帧数据 {
--     vertices: {顶点索引: {x,y}},  -- 顶点位置
--     customProps: {任意自定义属性}   -- 其他table数值（如缩放、旋转）
-- }
function MeshAnimator:addKeyframe(id, time, keyframeData)
    local meshData = self.meshes[id]
    if not meshData then
        print("错误：Mesh ID="..id.." 不存在")
        return
    end

    -- 存储关键帧（按时间排序）
    table.insert(meshData.animData.keyframes, {
        time = time,
        data = keyframeData
    })

    -- 排序关键帧（保证时间递增）
    table.sort(meshData.animData.keyframes, function(a,b)
        return a.time < b.time
    end)

    -- 更新动画总时长
    meshData.animData.duration = math.max(meshData.animData.duration, time)
    print("关键帧添加成功：Mesh="..id.." 时间="..time.."秒")
end

--- 绑定定点摆动动画（示例：让Mesh某个顶点像钟摆一样来回摆动）以及权重
function  MeshAnimator:bindPointPendulum(id, time, keyframeData)
    
end

--- 保存动画数据到文件（JSON格式）
-- @param id: Mesh唯一标识
-- @param path: 保存路径（如 "anim/mesh_anim.json"）
function MeshAnimator:saveAnimation(id, path)
    local meshData = self.meshes[id]
    if not meshData then return end

    -- 序列化动画数据（仅保存关键帧和时长）
    local saveData = {
        duration = meshData.animData.duration,
        keyframes = meshData.animData.keyframes
    }

    -- 写入文件（需确保目录存在）
    love.filesystem.createDirectory(path:match("^(.*[/\\])"))
    love.filesystem.write(path, json.encode(saveData))
    print("动画保存成功："..path)
end

--- 从文件读取动画数据
-- @param id: Mesh唯一标识
-- @param path: 读取路径
function MeshAnimator:loadAnimation(id, path)
    local meshData = self.meshes[id]
    if not meshData then return end

    -- 读取文件
    local content = love.filesystem.read(path)
    if not content then
        print("错误：动画文件不存在 "..path)
        return
    end

    -- 反序列化
    local loadData = json.decode(content)
    meshData.animData.duration = loadData.duration
    meshData.animData.keyframes = loadData.keyframes
    print("动画加载成功："..path.." 总时长="..loadData.duration.."秒")
end

--- Update驱动动画：根据当前时间插值更新Mesh
-- @param dt: 帧时间（Love2D update的dt参数）
function MeshAnimator:update(dt)
    if not self.isPlaying then return end

    -- 全局时间递增（循环播放）
    self.currentTime = self.currentTime + dt
    for id, meshData in pairs(self.meshes) do
        if meshData.animData.duration > 0 then
            -- 循环动画：时间超过总时长则重置
            local animTime = self.currentTime % meshData.animData.duration
            -- 插值更新Mesh状态
            self:interpolateKeyframes(id, animTime)
        end
    end
end

--- 插值计算关键帧之间的数值（核心动画逻辑）
-- @param id: Mesh唯一标识
-- @param currentTime: 当前动画时间（秒）
function MeshAnimator:interpolateKeyframes(id, currentTime)
    local meshData = self.meshes[id]
    local keyframes = meshData.animData.keyframes
    if #keyframes < 2 then return end

    -- 找到当前时间前后的两个关键帧
    local prevKeyframe, nextKeyframe = nil, nil
    for i, kf in ipairs(keyframes) do
        if kf.time <= currentTime then
            prevKeyframe = kf
        else
            nextKeyframe = kf
            break
        end
    end

    -- 边界处理：超过最后一帧则用最后一帧
    if not nextKeyframe then
        nextKeyframe = prevKeyframe
    end
    -- 还没到第一帧则用第一帧
    if not prevKeyframe then
        prevKeyframe = nextKeyframe
    end

    -- 计算插值比例（0-1）
    local deltaTime = nextKeyframe.time - prevKeyframe.time
    local t = deltaTime == 0 and 1 or (currentTime - prevKeyframe.time) / deltaTime

    -- 1. 插值更新顶点坐标
    if prevKeyframe.data.vertices and nextKeyframe.data.vertices then
        for vertexIndex, prevPos in pairs(prevKeyframe.data.vertices) do
            local nextPos = nextKeyframe.data.vertices[vertexIndex]
            if nextPos then
                -- 线性插值计算当前坐标
                local currentX = prevPos.x + (nextPos.x - prevPos.x) * t
                local currentY = prevPos.y + (nextPos.y - prevPos.y) * t
                -- 更新Mesh顶点
                self:modifyVertex(id, vertexIndex, currentX, currentY)
            end
        end
    end

    -- 2. 插值更新自定义属性（示例：可扩展缩放、旋转等）
    -- （此处仅打印，你可根据需求修改Mesh的其他属性）
    if prevKeyframe.data.customProps and nextKeyframe.data.customProps then
        for propName, prevVal in pairs(prevKeyframe.data.customProps) do
            local nextVal = nextKeyframe.data.customProps[propName]
            local currentVal = prevVal + (nextVal - prevVal) * t
            print("Mesh "..id.." 自定义属性 "..propName.." = "..currentVal)
        end
    end
end

-- ==============================================
-- 辅助函数：深拷贝（避免引用传递）
-- ==============================================
function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

return MeshAnimator
-- -- ==============================================
-- -- Love2D 生命周期函数（测试示例）
-- -- ==============================================
-- function love.load()
--     -- 初始化JSON库（Love2D 11.x+ 内置）
--     json = require("dkjson")

--     -- 1. 创建Mesh（ID: test_mesh，位置(100,100)，尺寸200x200）
--     MeshAnimator:createMesh("test_mesh", 100, 100, 200, 200)

--     -- 2. 添加关键帧（动画：四角形变+自定义属性）
--     -- 0秒：初始状态
--     MeshAnimator:addKeyframe("test_mesh", 0, {
--         vertices = {
--             [1] = {x=100, y=100},  -- 左下
--             [2] = {x=300, y=100},  -- 右下
--             [3] = {x=300, y=300},  -- 右上
--             [4] = {x=100, y=300}   -- 左上
--         },
--         customProps = {scale = 1.0}  -- 自定义属性：缩放
--     })

--     -- 2秒：形变（右下右移，左上上移）
--     MeshAnimator:addKeyframe("test_mesh", 2, {
--         vertices = {
--             [1] = {x=100, y=100},
--             [2] = {x=400, y=150},
--             [3] = {x=300, y=300},
--             [4] = {x=100, y=250}
--         },
--         customProps = {scale = 1.2}
--     })

--     -- 4秒：恢复初始状态
--     MeshAnimator:addKeyframe("test_mesh", 4, {
--         vertices = {
--             [1] = {x=100, y=100},
--             [2] = {x=300, y=100},
--             [3] = {x=300, y=300},
--             [4] = {x=100, y=300}
--         },
--         customProps = {scale = 1.0}
--     })

--     -- 3. 保存动画（可选）
--     -- MeshAnimator:saveAnimation("test_mesh", "anim/test_mesh_anim.json")

--     -- 4. 加载动画（可选，注释上面保存，取消下面注释测试）
--     -- MeshAnimator:loadAnimation("test_mesh", "anim/test_mesh_anim.json")
-- end

-- function love.update(dt)
--     -- 驱动动画更新
--     MeshAnimator:update(dt)
-- end

-- function love.draw()
--     -- 绘制Mesh（填充白色，方便看形变）
--     local mesh = MeshAnimator.meshes["test_mesh"].mesh
--     love.graphics.setColor(1, 1, 1)
--     love.graphics.draw(mesh)

--     -- 绘制调试信息
--     love.graphics.setColor(1, 0, 0)
--     love.graphics.print("动画时间："..string.format("%.2f", MeshAnimator.currentTime).."秒", 10, 10)
--     love.graphics.print("按空格暂停/播放", 10, 30)
--     love.graphics.print("按R复位Mesh", 10, 50)
-- end

-- function love.keypressed(key)
--     if key == "space" then
--         -- 暂停/播放动画
--         MeshAnimator.isPlaying = not MeshAnimator.isPlaying
--     elseif key == "r" then
--         -- 复位Mesh
--         MeshAnimator:resetMesh("test_mesh")
--     elseif key == "escape" then
--         love.event.quit()
--     end
-- end