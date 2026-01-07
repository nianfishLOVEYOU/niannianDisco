-- 假设你的模块放在项目根目录下的  lib/  文件夹
-- 在任何需要加载模块的脚本最前面加入下面这行
if love.filesystem.isFused() then
    -- fused：只能使用虚拟文件系统的默认路径  打包之后
    package.path = package.path .. ";?.lua;?/init.lua"
else
    -- 开发阶段：磁盘上有 lib/、src/ 等目录
    -- package.path = package.path .. ";lib/?.lua;lib/?/init.lua;src/?.lua"
end

nianTool = require "lib.nianTool"
nianDraw = require "lib.nianDraw"
animation = require "src.animation"

eventManager = require "src.manager.eventManager"
mouseManager = require "src.manager.mouseManager"
keybordManager = require "src.manager.keybordManager"
systemManager = require "src.manager.systemManager"
require "glove"

network = require "src.network.network"
audio = require "src.audio"
fileManager = require "src.manager.fileManager"
uiManager = require "src.manager.uiManager"
globleManager = require "src.manager.globleManager"
resourceManager = require "src.manager.resourceManager"

itemManager = require "src.manager.itemManager"
playerManager = require "src.manager.playerManager"
-- 全局状态管理
statusManager = require "src.manager.statusManager"
shaderManager = require "src.manager.shaderLayerManager"


---修改debug字体
local ffi = require "ffi"
ffi.cdef [[
    int SetConsoleOutputCP(unsigned int wCodePageID);
]]
ffi.C.SetConsoleOutputCP(65001) -- 936 = GBK  65001 =utf-8

-- 设置为全局默认字体
myFont = love.graphics.newFont("fonts/msyh.ttc", 12)
love.graphics.setFont(myFont)

---主要变量------
openMapEditorMode = false
openlocalMod = true

---设置摄像机
pixSize = 4
-- 参数：left, top, width, height（世界边界）
cam =  require("lib.gamera").new(-2000, -2000, 4000, 4000) -- 这里把整个游戏地图设为 2000×2000
-- 若想让摄像机只占屏幕的一部分（比如 UI 区域），可以限制窗口：
cam:setWindow(0, 0, 600, 450) -- 只在左上 800×600 区域绘制
cam:setScale(0.7)
-- 物理设置
world = love.physics.newWorld(0, 0, true) -- x重力, y重力, 是否允许休眠

-- 创建离屏画布，尺寸与窗口相同
canvas = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight())
-- 感知
local function beginContact(a, b, coll)
    local ua, ub = a:getUserData(), b:getUserData()
    if ua and ua.isSensor then
        ua:onEnter(b)
    end
    if ub and ub.isSensor then
        ub:onEnter(a)
    end
end

local function endContact(a, b, coll)
    local ua, ub = a:getUserData(), b:getUserData()
    if ua and ua.isSensor then
        ua:onLeave(b)
    end
    if ub and ub.isSensor then
        ub:onLeave(a)
    end
end

world:setCallbacks(beginContact, endContact)

local function loadMap()
    local MapLoader = require "src.map.mapLoader"
    -- 读取已有地图（若不存在则手动指定背景）
    local mapPath = "res/maps/edited.json"
    if love.filesystem.getInfo(mapPath) then
        map = MapLoader.load(mapPath)
        for i, v in ipairs(map.items) do
            itemManager:addItem(v)
        end
        cam:setPosition(map.startPoint.x, map.startPoint.y)
    end
end

local function closeMap()
    map = nil
    itemManager:removeAll()
end

function love.load()
    print("save path:", love.filesystem.getSaveDirectory())
    print("LÖVE version:", love.getVersion())
    
    -- shaderManager:addEffect(require("src.shader.blurEffect").getshader(), 1)
    shaderManager:addEffect(require("src.shader.lightPointEffect").getshader(), 1)
    
    systemManager:init()
    if openMapEditorMode then
        statusManager:statusChange("editor")
    else
        statusManager:statusChange("menu")
    end

    if not openMapEditorMode then
        loadMap()
    end

end

function love.update(dt)
    world:update(dt)
    systemManager:update(dt)
    statusManager:update(dt)
    animation:update(dt)
    
    -- 使用时发送参数
    local mx, my = love.mouse.getPosition()
end

local function keypressed(k)
    if k == "b" then -- B 键 → 广播
        openMapEditorMode = true
        statusManager:statusChange("editor")
        closeMap()
    elseif k == "n" then -- N 键 → 游戏
        openlocalMod = true
    end
    -- 拖拽歌曲添加播放列表
    -- 暂停，下一首，功能
end
-- debug输入方案
keybordManager:keypressed_regester(function(key)
    keypressed(key)
end)


--- 绘制流程------
local function camDepth()
    nianDraw:renderDepthCanvas()
end

local function camDraw()
    -- if map then
    --     love.graphics.setColor(1, 1, 1)
    --     love.graphics.draw(map.background, 0, 0, 0, pixSize, pixSize)
    --     love.graphics.draw(map.background, 400, 0, 0, pixSize, pixSize)
    --     love.graphics.draw(map.background, 0, 400, 0, pixSize, pixSize)
    --     love.graphics.draw(map.background, 400, 400, 0, pixSize, pixSize)
    -- end

    nianDraw:drawFinal()
    systemManager:camdraw()

    if openMapEditorMode then
        printCol()
    end
end

-- 无画布场景绘制
local function drawNoCanvasScene()
    cam:draw(camDraw) -- 所有绘制都在摄像机坐标系下完成
end

function love.draw()
    if openMapEditorMode then
        cam:draw(camDepth)
        drawNoCanvasScene()
        systemManager:draw()
        return
    end


    -- 相机深度绘制
    cam:draw(camDepth)

    -- 使用Shader管理器渲染场景
    shaderManager:render(drawNoCanvasScene)

    -- 绘制最终结果
    shaderManager:drawFinal(0, 0)

    -- 绘制UI等覆盖内容
    systemManager:draw()

    love.graphics.setColor(1, 0, 0)
    love.graphics.print("localmod " .. tostring(openlocalMod), 100, 10)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(nianDraw.depthCanvas, love.graphics.getWidth()-nianDraw.depthCanvas:getWidth()*0.2, 0,0,0.2,0.2)
    -- debug
    DebugPrint()
end

function love.quit()
    print("游戏已正常退出")
    network:closeNetThread()

    systemManager:quit()
end
