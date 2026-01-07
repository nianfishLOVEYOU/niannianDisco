local love = require "love"
local g = love.graphics

local mt = {
  __index = {
    draw = function(self, parentX, parentY)
      if self.x and self.y then
        local rotation = 0

        local imagew, imageh = self.image:getDimensions()
          g.draw(
            self.image,
            parentX + self.x,
            parentY + self.y,
            rotation,
            self.width/imagew,
            self.height/imageh
          )

        
      end
    end,

    getHeight = function(self)
      return self.height
    end,

    getWidth = function(self)
      return self.width
    end
  }
}

--[[
This widget displays an image.

The parameters are:

- filePath: path to the image file
- table of options

The supported options are:

- `height`: of the image (aspect ratio is preserved)
--]]
local function Image(filePath, options)
  local to = type(options)
  assert(to == "table" or to == "nil", "Image options must be a table.")

  local image = resourceManager.loadImage(filePath)

  local instance = options or {}
  instance.kind = "Image"
  instance.filePath = filePath
  instance.image = image
  local scale = options.scale or 1
  --如果没有填尺寸就默认
  local imagew, imageh = image:getDimensions()
  if not options.width or not options.height then
    instance.width =scale*imagew
    instance.height=scale*imageh
  end

  setmetatable(instance, mt)
  return instance
end

return Image
