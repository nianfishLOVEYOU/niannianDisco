local colors = require "glove/colors"
local love = require "love"
local widget = require "glove.widgets.widget"

local g = love.graphics
local lk = love.keyboard
local padding = 4
--输入变量
local inputCursor

local Input = widget:extend()

-- inputTable：控制的输入对象需要包含到
function Input:init(x, y, w, h, text, onInput)
  local font = g.getFont()
  self.font = font

  self.type = "Input"

  self.text = text
  self.onInput = onInput
  if self.onInput then
    self.onInput(self.text)
  end

  self:setSize(w, h)
end

function Input:draw()
  local over = self:isOver(love.mouse.getPosition())
  
  g.setColor(0,0,0)
  g.rectangle("fill", self.x, self.y, self.w, self.h)
  g.setColor(over and Glove.hoverColor or self.color)
  g.rectangle("line", self.x, self.y, self.w, self.h)

  -- Get current value.
  local value = self.text or ""

  -- Find substring of value that fits in width.
  local font = self.font
  -- 最大文字宽度
  local limit = self.w - padding * 2
  local i = 1
  local substr
  local substrWidth
  -- 计算当前文字的宽度
  while true do
    substr = value:sub(i, #value)
    substrWidth = font:getWidth(substr)
    if substrWidth <= limit then break end
    i = i + 1
  end
  -- local truncated = i > 1

  local x = self.x + padding
  local y = self.y + padding

  g.setColor(self.color)
  g.setFont(font)
  g.print(substr, x, y)

  local printCursor=love.timer.getTime()%2>1

  --显示输入光标
  if Glove.isFocused(self) and printCursor then
    if inputCursor then
      -- Draw vertical cursor line.
      local height = font:getHeight()
      local cursorPosition = math.min(inputCursor - i + 1, #substr)
      local cursorX = x + font:getWidth(substr:sub(1, cursorPosition))
      g.line(cursorX, y, cursorX, y + height)
    end
  end
  
end

--输入框被点击
function Input:onClick(clickX, clickY, button)
  Glove.setFocus(self)
  print("select input")
  -- Enable keyboard.
  -- TODO: Is this needed? Maybe only on mobile devices.

  local value = self.text or ""
  inputCursor = #value
end

function Input:setText(text)
  self.text = text
end

function Input:getFontSize()
  local labelWidth = self.font:getWidth(self.text) + padding * 2
  local labelHeight = self.font:getHeight() + padding * 2
  return labelWidth, labelHeight
end

function Input:keypressed(keyPressed)
  local c = inputCursor

  local value = self.text or ""

  if keyPressed == "backspace" then
    if c > 0 then
      self.text = value:sub(1, c - 1) .. value:sub(c + 1, #value)
      inputCursor = c - 1
    end
  elseif keyPressed == "left" then
    if c > 0 then inputCursor = c - 1 end
  elseif keyPressed == "right" then
    if c < #value then inputCursor = c + 1 end
  else
    if keyPressed == "space" then keyPressed = " " end

    -- Only process printable ASCII characters.
    if #keyPressed == 1 then
      local head = c == 0 and "" or value:sub(1, c)
      local tail = value:sub(c + 1, #value)
      local shift = lk.isDown("lshift") or lk.isDown("rshift")
      local char = shift and keyPressed:upper() or keyPressed
      self.text = head .. char .. tail
      inputCursor = c + 1
    end
    --输入函数
    if self.onInput then
      self.onInput(self.text)
    end
  end
end

return Input
