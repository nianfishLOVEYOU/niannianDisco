-- src/main_editor.lua
local MapLoader = require "src.map.mapLoader"
local Item = require "src.item.item"

local mapEditor = {}
local history ={}

mouseManager:mousepressed_regester(function(x, y, button)
    mapEditor:mousepressed(x, y, button)
end)
mouseManager:mouseMoved_regester(function(x, y, dx, dy)
    mapEditor:mousemoved(x, y, dx, dy)
end)
mouseManager:mouseLeased_regester(function(x, y, button)
    mapEditor:mousereleased(x, y, button)
end)
mouseManager:wheelMoved_regester(function(x, y)
    mapEditor:wheelmoved(x, y)
end)
keybordManager:keypressed_regester(function(key)
    mapEditor:keypressed(key)
end)

local itemTypes = { "floor","tree", "wall", "mic", "ball", "sofa","startPoint","eventZone","lightpoint","fire" }
local itemnews = {}
local ItemIndex = 1

function mapEditor:init()
    print("开始地图编辑")

    love.window.setTitle("Love2D 简易地图编辑器")
    love.graphics.setBackgroundColor(0.2, 0.2, 0)

    for _, module in ipairs(itemTypes) do
        itemnews[module] = require("src.item." .. module)
    end

    -- 读取已有地图（若不存在则手动指定背景）
    local mapPath = "res/maps/edited.json"
    if love.filesystem.getInfo(mapPath) then
        mapEditor.map = MapLoader.load(mapPath)
    else
        -- 手动指定背景图片路径
        mapEditor.map = {
            items = {},
            startPoint={x=0,y=0}
        }
    end

    mapEditor.selected = nil -- 当前选中的块
    mapEditor.dragOffset = {
        x = 0,
        y = 0
    } -- 拖拽时的相对位移

end


--- 判断鼠标是否在某个块内部
local function hitTest(item, mx, my)
    local xin=mx >= item.x- item.w /2 and mx <= item.x + item.w /2
    local yin=my >= item.y -item.h and my <= item.y 
    print("xin yin",xin,yin)
    return xin and yin
end

function mapEditor:update(dt)
    -- 这里不需要任何实时更新，仅处理输入
    for _, it in ipairs(mapEditor.map.items) do
        it:update(dt)
    end
end

local function floorToPixSize(x)
    return math.floor(x / pixSize) * pixSize
end

function mapEditor:mousepressed(x, y, button)
    local worldX, worldY = cam:toWorld( x, y )
    print("button",x,y,"world", worldX,worldY)
    local getlayer=-1;
    if button == 1 then -- 左键：选中或新建
        mapEditor.selected = nil
        for i = #mapEditor.map.items, 1, -1 do -- 从上到下遍历，先选中最上层
            local it = mapEditor.map.items[i]
            print("item xywh id: ",i,it.x,it.y,it.w,it.h)
            if hitTest(it, worldX, worldY) and it.layer > getlayer then
                print("select")
                mapEditor.selected = it
                mapEditor.dragOffset.x =  it.x-worldX
                mapEditor.dragOffset.y =  it.y-worldY
                getlayer=it.layer;
            end
        end

    elseif button == 2 then -- 右键：创建
        if not mapEditor.selected then
            -- 在空白处创建新块（默认 64×64，使用默认图片 block.png）
            local newItem = itemnews[itemTypes[ItemIndex]]:new(floorToPixSize(worldX), floorToPixSize(worldY), 64, 64)
            table.insert(mapEditor.map.items, newItem)
            --mapEditor.selected = newItem
            mapEditor.dragOffset.x = 0
            mapEditor.dragOffset.y = 0

            if(itemTypes[ItemIndex]=="startPoint") then
                self.map.startPoint.x=floorToPixSize(worldX) 
                self.map.startPoint.y=floorToPixSize(worldY)
                print(self.map.startPoint)
            end
        end
    elseif button == 3 then
    end
end

function mapEditor:mousereleased(x, y, button)
    if button == 1 then
        if(mapEditor.selected ) then
        print("item xywh2",mapEditor.selected.x,mapEditor.selected.y,mapEditor.selected.w,mapEditor.selected.h)
        end
        mapEditor.selected = nil
    end
end

function mapEditor:setUI()
    local vstackchild = {}

    local inputPlayerName = Glove.Input(self.state, "playername", {
        width = 100
    })

    -- 名字输入
    local second = Glove.HStack({
        align = "start",
        spacing = 0
    }, {Glove.Text("输入name:", {
        color = colors.red
    }), inputPlayerName})

    table.insert(vstackchild, second)
    self.vstack = Glove.VStack({
        spacing = 30
    }, vstackchild -- Glove.Spacer()
    )
end

function mapEditor:mousemoved(x, y, dx, dy, istouch)
    local worldX, worldY = cam:toWorld( x, y )
    if mapEditor.selected and love.mouse.isDown(1) then
        local posx=floorToPixSize(worldX+mapEditor.dragOffset.x ) 
        local posy=floorToPixSize(worldY+mapEditor.dragOffset.y)
        mapEditor.selected:setPos(posx,posy)
    elseif love.mouse.isDown(3) then
        cam:setPosition(cam.x - dx, cam.y - dy)
    end
end

function mapEditor:wheelmoved(dx, dy)
    if mapEditor.selected then

    else
        if dy > 0 then

            ItemIndex = ItemIndex - 1
            if ItemIndex < 1 then
                ItemIndex = #itemTypes
            end
        elseif dy < 0 then
            ItemIndex = (ItemIndex % #itemTypes) + 1
        end
        print("ItemIndex : " .. ItemIndex)
        -- 切换生成item
    end
end

function mapEditor:keypressed(key)
    if mapEditor.selected then
        if key == "=" then
            mapEditor.selected.h = mapEditor.selected.h + pixSize * 2
        elseif key == "-" then
            mapEditor.selected.h = mapEditor.selected.h - pixSize * 2
        elseif key == "]" then
            mapEditor.selected.w = mapEditor.selected.w + pixSize * 2
        elseif key == "[" then
            mapEditor.selected.w = mapEditor.selected.w - pixSize * 2

        end
    end

    if key == "s" then
        -- 保存为 JSON（覆盖原文件或另存为）

        MapLoader.save(mapEditor.map, "res/maps/edited.json")
        print("地图已保存到 res/maps/edited.json")
    elseif key == "o" then
        print("oo",cam:getScale())
        cam:setScale(cam:getScale()-0.2)
    elseif key == "p" then
        print("pp",cam:getScale())
        cam:setScale(cam:getScale()+0.2)

    elseif key == "delete" then
        if mapEditor.selected then
            for i = #mapEditor.map.items, 1, -1 do
                if mapEditor.map.items[i] == mapEditor.selected then
                    table.remove(mapEditor.map.items, i)
                    mapEditor.selected = nil
                    break
                end
            end
        end

    end
end

function mapEditor:draw()


    -- 2. 所有块（半透明红色或自定义图片）
    for _, it in ipairs(mapEditor.map.items) do
        it:draw()
        love.graphics.setColor(1,0,0)
        love.graphics.rectangle(
          "line",
          it.x-it.w/2 , it.y-it.h,
          it.w ,it.h
        )
    end

    -- 3. 选中块的轮廓（黄色）
    if mapEditor.selected then
        love.graphics.setColor(1, 1, 0, 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", mapEditor.selected.x-mapEditor.selected.w/2, mapEditor.selected.y-mapEditor.selected.h, mapEditor.selected.w,
            mapEditor.selected.h)
        love.graphics.setColor(1, 1, 1, 1)
    end

end

function mapEditor:uidraw()
    -- 4. 简单提示文字
    love.graphics.setColor(1, 0, 0, 0.9)
    love.graphics.print("创建 : " .. itemTypes[ItemIndex], 10, 10)
    love.graphics.setColor(1, 1, 1)

    
    -- 4. 简单提示文字
    love.graphics.setColor(1, 0, 0, 0.9)
    love.graphics.print("左键：选中  右键：创建  滚轮：切换  S：保存  Delete：删除选中块", 10,
        love.graphics.getHeight() - 30)
        love.graphics.setColor(1, 1, 1, 1)
end

-- 结束生命周期等待下次初始化
function mapEditor:leave()

end

return mapEditor
