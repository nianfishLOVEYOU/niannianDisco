local function createMap()
    return {
        name="map-1",
        startPoint={
            x=100,
            y=100
        },
        gridSize=32, --网格大小，默认32像素
        size = {
            width=30, --地图水平格子数量
            height=30 --地图垂直格子数量
        },
        items={},
        grids={}, --地面网格，放置背景地板
        background="" --背景图片
    }
end

return createMap

