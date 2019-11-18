require("engine/core/class")
local animated_sprite = require("engine/render/animated_sprite")

local speaker_component = require("dialogue/speaker_component")
local visual_data = require("resources/visual_data")

-- character class for visual/speaking
-- unlike fighter, it doesn't have battle attributes

local character = new_class()

-- components
--   speaker: speaker_component
-- parameters
--   character_info: character_info    character info
--   sprite: animated_sprite           animated sprite
--   direction: horizontal_dirs        facing left or right?
--
--   rel_bubble_tail_pos: vector       position of bubble tail relative to foot position
--                                     (above head)
-- state
--   root_pos: vector                  position from which HUD and sprites are deduced
--                                       does not move during animations
--   sprite_pos: vector                sprite foot position
--                                       changes during animations

-- after constructing a character, you should call register_speaker
function character:_init(character_info, direction, pos)
  -- paremeters
  self.character_info = character_info
  local sprite_data_table = visual_data.anim_sprites.character[character_info.sprite_id]
  assert(sprite_data_table, "no anim sprite found for id: "..character_info.sprite_id)
  self.sprite = animated_sprite(sprite_data_table)
  self.sprite:play('idle')
  self.direction = direction

  -- components (inject entity)
  self.speaker = speaker_component(self)

  -- state
  self.root_pos = pos:copy()
  self.sprite_pos = pos:copy()
end

-- call after construction
function character:register_speaker(dialogue_mgr)
  dialogue_mgr:add_speaker(self.speaker)
end

-- call before removal of last reference (destruction via garbage collection)
function character:unregister_speaker(dialogue_mgr)
  dialogue_mgr:remove_speaker(self.speaker)
end

-- update

function character:update()
  self.sprite:update()
end

-- render

function character:draw()
  local flip_x = self.direction == horizontal_dirs.left
  self.sprite:render(self.sprite_pos, flip_x)
end

return character
