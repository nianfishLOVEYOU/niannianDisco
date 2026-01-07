local ItemManager={
    items={}
}

systemManager:update_regester(function (dt)
    ItemManager:update(dt)
end)
systemManager:camdraw_regester(function ()
    ItemManager:draw()
end)

function ItemManager:addItem(item)
    if item then
        table.insert(self.items,item)
    else
        print("id:"..id.." item exsit !")
    end
end

function ItemManager:removeItem(id)
    local index=0
    for i, v in ipairs(self.items) do
        if v.id==id then
            index=i
        end
    end
    table.remove(self.items,index)
end

function ItemManager:removeAll()
    for i =#self.items , 1, -1 do
        self.items[i]:destroy()
        table.remove(self.items,i)
    end
end

function ItemManager:update(dt)
    for k, v in pairs(self.items) do
        if v.update then
            v:update(dt)
        end
    end
end

function ItemManager:draw()
    for i, v in ipairs(self.items) do
        if v.draw then
            v:draw()
        end
    end
end

return ItemManager