local historyManager = {}

-- Maximum number of history records to keep
local MAX_HISTORY = 100

historyManager.stack = {}
historyManager.index = 0

-- Push a new history record
-- record must implement :undo() when popped
function historyManager:push(record)
    if not record then return end

    -- Trim any redo-able records ahead of current index
    if self.index < #self.stack then
        for i = #self.stack, self.index + 1, -1 do
            self.stack[i] = nil
        end
    end

    table.insert(self.stack, record)
    self.index = #self.stack

    -- Enforce maximum size
    if #self.stack > MAX_HISTORY then
        local removeCount = #self.stack - MAX_HISTORY
        for i = 1, removeCount do
            table.remove(self.stack, 1)
        end
        self.index = #self.stack
    end
end

-- Undo last record
function historyManager:undo()
    if self.index <= 0 then return end

    local record = self.stack[self.index]
    if record and record.undo then
        record:undo()
    end
    self.index = self.index - 1
end

-- Clear all history
function historyManager:clear()
    self.stack = {}
    self.index = 0
end

return historyManager
