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

mouseManager:mouseLeased_regester(function (x,y,button)
    uiManager:mouseLeased(x,y,button)
end)
mouseManager:mouseMoved_regester(function (x,y,dx,dy)
    uiManager:mouseMoved(x,y,dx,dy)
end)
mouseManager:mousepressed_regester(function (x,y,button)
    uiManager:mousePressed(x,y,button)
end)
mouseManager:wheelMoved_regester(function (x,y)
    uiManager:wheelmoved(x,y)
end)

function uiManager:visiable(name,visiable)
    local ui =self:getUI(name)
    if(ui) then
        ui.options.visiable=visiable
    end
end

function uiManager:addUI(name,ui,options)
    if(not self:getUI(name)) then
        local options=options or {}
        options.visiable= true
        local instance={name =name ,ui= ui,options=options }
        ui:init()
        table.insert(self.uiTable,instance)
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
    else
        print("uimanager no : ",name)
    end
end


function uiManager:refresh(name)
    for i, v in ipairs(self.uiTable) do
        if v.name == name then
            v.ui:refresh()
        end
    end
end

function uiManager:update(dt)
    for k, v in pairs(self.uiTable) do
        if v.ui.update then
            v.ui:update(dt)
        end
    end
end

function uiManager:draw()
    for i, v in ipairs(self.uiTable) do
        if v.options.visiable then
            --print(v.name)
            v.ui:draw()
        end
    end
end

function uiManager:mouseLeased(x,y,button)
    for i, v in ipairs(self.uiTable) do
        if v.options.visiable then
            --print(v.name)
            v.ui:mouseLeased(x,y,button)
        end
    end
end

function uiManager:mousePressed(x,y,button)
    for i, v in ipairs(self.uiTable) do
        if v.options.visiable then
            --print(v.name)
            v.ui:mousePressed(x,y,button)
        end
    end
end

function uiManager:mouseMoved(x,y,dx,dy)
    for i, v in ipairs(self.uiTable) do
        if v.options.visiable then
            --print(v.name)
            v.ui:mouseMoved(x,y,dx,dy)
        end
    end
end

function uiManager:wheelmoved(x,y)
    for i, v in ipairs(self.uiTable) do
        if v.options.visiable then
            --print(v.name)
            v.ui:wheelmoved(x,y)
        end
    end
end






return uiManager