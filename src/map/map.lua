local Map={
    name="map-1",
    startPoint={
        x=100,
        y=100
    },
    gridSize=100, --网格大小，默认32像素
    size = {
        width=50, --地图宽度，单位像素
        height=50 --地图高度，单位像素
    },
    items={},
    grids={}, --地面网格，放置背景地板
    background="" --背景图片
}


return Map

