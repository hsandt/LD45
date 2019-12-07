require("engine/core/class")

local manager = require("engine/application/manager")

local gameplay_data = require("resources/gameplay_data")
local visual_data = require("resources/visual_data")
local character = require("story/character")

-- Manages the adventure state, and also tutorials
local adventure_manager = new_class(manager)

adventure_manager.type = ':adventure'
adventure_manager.initially_active = false

--[[
Dynamic parameters (fixed for a given adventure segment, i.e. until adventure state is exited)
  next_step     string           name of the current adventure step ("intro", "floor loop", etc.)
  pc            character        player character (never disposed of)
  npc           character        current npc you're about to fight

State
--]]
function adventure_manager:_init()
  manager._init(self)

  self.next_step = ""
  self.pc = nil
  self.npc = nil
end

function adventure_manager:start()  -- override
  self:spawn_pc()
end

function adventure_manager:update()  -- override
end

function adventure_manager:draw_characters()
  self.pc:draw()
  if self.npc then
    self.npc:draw()
  end
end

function adventure_manager:spawn_pc()
  local dm = self.app.managers[':dialogue']

  self.pc = character(gameplay_data.pc_info, horizontal_dirs.right, visual_data.pc_sprite_pos)
  self.pc:register_speaker(dm)
end

function adventure_manager:spawn_npc(npc_id)
  local dm = self.app.managers[':dialogue']

  local npc_info = gameplay_data.npc_info_s[npc_id]
  self.npc = character(npc_info, horizontal_dirs.left, visual_data.npc_sprite_pos)
  self.npc:register_speaker(dm)
end

-- currently unused, as pc *always* exists
function adventure_manager:despawn_pc()
  assert(self.pc)

  local dm = self.app.managers[':dialogue']

  self.pc:unregister_speaker(dm)
  self.pc = nil
end

function adventure_manager:try_despawn_npc()
  if self.npc then
    self:despawn_npc()
  end
end

function adventure_manager:despawn_npc()
  assert(self.npc, "cannot despawn_npc if no npc is present")

  local dm = self.app.managers[':dialogue']

  self.npc:unregister_speaker(dm)
  self.npc = nil
end

return adventure_manager
