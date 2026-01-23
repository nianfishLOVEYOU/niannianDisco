local Component = require "src.component.component"
local playerManager = require "src.manager.playerManager"

local HatAction = Component:extend()

function HatAction:init(opts)
	opts = opts or {}
	self.name = opts.name or "hatAction"
	self.type = "hatAction"
	self.pickRange = opts.pickRange or 64
	self.wearOffset = opts.wearOffset or { x = 0, y = -20 }
	self._origOnClick = nil
end

function HatAction:onAttach(item)
	-- called when component attached to an item in the world
	-- wrap item's onClick to handle pick/drop
	if not item then return end
	self.item = item
	self._origOnClick = item.onClick
	local comp = self
	item.onClick = function(ix, iy, button)
		comp:handleClick(ix, iy, button)
		if comp._origOnClick then
			comp._origOnClick(item, ix, iy, button)
		end
	end
end

function HatAction:onDetach(item)
	if not item then return end
	if self._origOnClick then
		item.onClick = self._origOnClick
		self._origOnClick = nil
	end
	self.item = nil
end

function HatAction:handleClick(x, y, button)
	-- left click pick/drop
	if button and button ~= 1 then return end
	local item = self.item
	if not item then return end

	local player = playerManager.player
	if not player then return end

	local ix, iy = item:getPos()
	local px, py = player.x, player.y
	local dx = ix - px
	local dy = iy - py
	local dist2 = dx*dx + dy*dy
	if item.parent and item.parent == player then
		-- currently worn: drop it near player
		self:drop(player)
	else
		-- try pick if within range
		if dist2 <= (self.pickRange * self.pickRange) then
			self:wear(player)
		end
	end
end

function HatAction:wear(player)
	if not self.item or not player then return end
	-- attach item as child of player
	if player.addChild then
		player:addChild(self.item)
		-- position relative to head
		local ox = self.wearOffset.x
		local oy = self.wearOffset.y
		self.item.localX = ox
		self.item.localY = oy
		self.item:localPosRefresh()
	else
		-- fallback: set owner and position
		self.item.owner = player
	end
end

function HatAction:drop(player)
	if not self.item then return end
	-- remove from parent if parent is player
	if self.item.parent and self.item.parent == player then
		self.item.parent:removeChild(self.item)
	end
	-- place in front of player
	local dropX = player.x + (player.w or 0) * 0.5
	local dropY = player.y
	self.item:setPos(dropX, dropY)
end

function HatAction:update(dt)
	-- keep item follow player head when worn
	if not self.item then return end
	local parent = self.item.parent
	if parent and parent.type == "player" then
		-- maintain local offset
		self.item:localPosRefresh()
	end
end

return HatAction

