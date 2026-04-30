local GridManager = {
    grids = {},
}
systemManager:update_regester(function(dt)
    GridManager:update(dt)
end)
systemManager:camdraw_regester(function()
    GridManager:draw()
end)


function GridManager:addGrid(grid,x,y)
    if grid then
        if not self.grids[x] then
            self.grids[x] = {}
        end
        self.grids[x][y] = grid
    end
end

function GridManager:removeGrid(x,y)
    if self.grids[x] and self.grids[x][y] then
        self.grids[x][y] = nil
    end
end

function GridManager:removeAll()
    self.grids = {}
end

function GridManager:update(dt)
    -- 先正常更新
    for _, column in pairs(self.grids) do
        for _, grid in pairs(column) do
            if grid.update then
                grid:update(dt)
            end
        end
    end
end

function GridManager:draw()
    for _, column in pairs(self.grids) do
        for _, grid in pairs(column) do
            if grid.draw then
                grid:draw()
            end
        end
    end
end

return GridManager
