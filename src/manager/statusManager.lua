local statusManager = {
    status = "",
    statusEntity = nil
}

local statusTable = {}

statusTable["editor"] = require "src.status.editor"
statusTable["menu"] = require "src.status.menu"
statusTable["game"] = require "src.status.game"

-- event需要一个status变量
function statusManager:statusEventRegister(event)
    eventManager.on("event_statusChange", event)
end

function statusManager:statusChange(status)
    if status ~= self.status and statusTable[status] then
        self.status = status
        if self.statusEntity then
            self.statusEntity.leave()
        end
        self.statusEntity = statusTable[status]
        self.statusEntity:init()
        eventManager.emit("event_statusChange", status)
    else
        print("error same status : ", status)
        return
    end
end

function statusManager:update(dt)
    if self.statusEntity then
        self.statusEntity:update(dt)
    end
end

return statusManager
