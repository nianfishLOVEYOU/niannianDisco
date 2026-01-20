-- fused：只能使用虚拟文件系统的默认路径  打包之后
package.path = package.path .. ";?.lua;?/init.lua"

if type(love) == "nil" then
    love = require "love" -- 仅在编辑器检查时定义空表，避免未定义提示
end

require "lib.nianTool"
require "src.manager"
require "src.glove"

camera = require("lib.gamera")
network = require "src.network.network"
audio = require "src.audio"


------设置为全局默认字体-----
myFont = love.graphics.newFont("fonts/heiti.ttf", 12)
love.graphics.setFont(myFont)

local function loadMap()
    love.keyboard.setTextInput(true, 50, 50, 400, 30)
    local MapLoader = require "src.map.mapLoader"
    -- 读取已有地图（若不存在则手动指定背景）
    local mapPath = "res/maps/edited.json"
    if love.filesystem.getInfo(mapPath) then
        map = MapLoader.load(mapPath)
        for i, v in ipairs(map.items) do
            itemManager:addItem(v)
        end
        cameraManager.cam:setPosition(map.startPoint.x, map.startPoint.y)
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

    statusManager:statusChange("menu")

    loadMap()
end

function love.update(dt)
    world:update(dt)
    systemManager:update(dt)
    statusManager:update(dt)
    animation:update(dt)
    timer:update(dt)
    --debug检测
    nianDebug.DebugUpdate(dt)
    -- 使用时发送参数
    local mx, my = love.mouse.getPosition()
end

-- 方法2：监控窗口焦点事件，避免在里面做耗时操作
function love.focus(focus)
    if focus then
        print("窗口获得焦点")
        -- 仅做轻量操作，比如恢复音效，不要加载大量资源
    else
        print("窗口失去焦点")
        -- 仅做轻量操作，比如暂停音效，不要销毁/重建资源
    end
end

local function keypressed(k)
    if k == "b" then -- B 键 → 广播
        commonData.openMapEditorMode = true
        statusManager:statusChange("editor")
        closeMap()
    end
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
    nianDraw:drawFinal()
    systemManager:camdraw()
end

-- 无画布场景绘制
local function drawNoCanvasScene()
    cameraManager.cam:draw(camDraw) -- 所有绘制都在摄像机坐标系下完成
end

function love.draw()
    if commonData.openMapEditorMode then
        cameraManager.cam:draw(camDepth)
        cameraManager.cam:draw(camDraw)
        systemManager:draw()
        -- debug
        nianDebug.DebugPrint()
        return
    end

    -- 相机深度绘制
    cameraManager.cam:draw(camDepth)

    -- 使用Shader管理器渲染场景
    shaderManager:render(drawNoCanvasScene)

    -- 绘制最终结果
    shaderManager:drawFinal(0, 0)

    -- 绘制UI等覆盖内容
    systemManager:draw()

    -- debug
    nianDebug.DebugPrint()
end

function love.quit()
    print("游戏已正常退出")
    --保存当前歌单数据
    audio:savePlaylist()
    network:closeNetThread()
    systemManager:quit()
end
