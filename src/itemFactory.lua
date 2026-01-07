--item工厂
local ItemFactory={}

function ItemFactory:createItem(itemType)
    
    local item=nil

    if itemType == "tree" then
        
    elseif itemType == "ball" then
        
    elseif itemType == "" then
        print("try creat item __ !")
    end

    if item then
        local id = globleManager:guid()
        item:setId(id)
        itemManager:addItem(id,item)
    end 
    
end

return ItemFactory