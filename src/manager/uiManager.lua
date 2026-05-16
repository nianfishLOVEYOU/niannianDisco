--管理ui页面对象
local uiManager={
    uiTable={}
}
local uipath="src.ui." --以后自动require用

systemManager:update_regester(function (dt)
    uiManager:update(dt)
end)
systemManager:draw_regester(function ()
    uiManager:draw()
end)

systemManager:mouseLeased_regester(function (x,y,button)
    uiManager:onClickOver(x,y,button)
end)
systemManager:mouseMoved_regester(function (x,y,dx,dy)
    uiManager:mouseMoved(x,y,dx,dy)
end)
systemManager:mousepressed_regester(function (x,y,button)
    uiManager:onClick(x,y,button)
end)
systemManager:wheelMoved_regester(function (x,y)
    uiManager:wheelmoved(x,y)
end)

function uiManager:visiable(name,visiable)
    local ui =self:getUI(name)
    if(ui) then
        ui.options.visiable=visiable
    end
end

function uiManager:addUI(name,ui)
    if(not self:getUI(name)) then
        local instance={name =name ,ui= ui }
        table.insert(self.uiTable,instance)
        ui.z=#self.uiTable
        print("[add ui] ",name)
    else
        print("!  ui is have !",name)
        --replaceUI(name,ui)
    end
end


function uiManager:getUI(name)
    --print("uiManager:getUI",#self.uiTable)
    for i, v in ipairs(self.uiTable) do
        if v.name == name then
            return v.ui
        end
    end
    return nil
end


function uiManager:removeUI(name)
    local removeIndex=-1
    for i, v in ipairs(self.uiTable) do
        if v.name == name then
            removeIndex=i
        end
    end
    if removeIndex~=-1 then
        self.uiTable[removeIndex].ui:destroy()
        table.remove(self.uiTable,removeIndex)
        print("remove ui ",name)
    else
        print("uimanager no : ",name)
    end
end


function uiManager:refresh(name)
    for i, v in ipairs(self.uiTable) do
        if v.name == name and v.ui:getRealVisiable() then
            v.ui:refresh()
        end
    end
end

function uiManager:update(dt)
    for k, v in pairs(self.uiTable) do
        if v.ui.update and v.ui:getRealVisiable() then
            v.ui:update(dt)
        end
    end
end

function uiManager:draw()
    for i, v in ipairs(self.uiTable) do
        if v.ui:getRealVisiable() then
            v.ui:draw()
        end
    end
end

function uiManager:onClickOver(x,y,button)
    for i, v in ipairs(self.uiTable) do
        if v.ui:getRealVisiable() then
            v.ui:onClickOver(x,y,button)
        end
    end
end

function uiManager:onClick(x,y,button)
    for i, v in ipairs(self.uiTable) do
        if v.ui:getRealVisiable() then
            v.ui:onClick(x,y,button)
        end
    end
end

function uiManager:mouseMoved(x,y,dx,dy)
    for i, v in ipairs(self.uiTable) do
        if v.ui:getRealVisiable() then
            v.ui:mouseMoved(x,y,dx,dy)
        end
    end
end

function uiManager:wheelmoved(x,y)
    for i, v in ipairs(self.uiTable) do
        if v.ui:getRealVisiable() then
            v.ui:wheelmoved(x,y)
        end
    end
end






return uiManager