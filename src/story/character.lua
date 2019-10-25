require("engine/core/class")

local speaker_component = require("dialogue/speaker_component")
local visual_data = require("resources/visual_data")

-- character class for visual/speaking
-- unlike fighter, it doesn't have battle attributes

local character = new_class()

-- components
--   speaker: speaker_component
-- parameters
--   character_info: character_info    character info
--   sprite: sprite_data               sprite to render
--   direction: horizontal_dirs        facing left or right?
--
--   rel_bubble_tail_pos: vector       position of bubble tail relative to foot position
--                                     (above head)
-- state
--   pos: vector                       foot position on screen. only changes during animations

-- after constructing a character, you should call register_speaker
function character:_init(character_info, direction, pos)
  -- paremeters
  self.character_info = character_info
  -- cache sprite data ref
  self.sprite = visual_data.sprites.character[character_info.sprite_id]
  self.direction = direction

  -- components (inject relative position directly as currently,
  --   a component cannot check the owning entity pos)
  local rel_bubble_tail_pos = visual_data.rel_bubble_tail_pos_by_horizontal_dir[direction]
  self.speaker = speaker_component(pos + rel_bubble_tail_pos)

  -- state
  self.pos = pos
end

-- call after construction
function character:register_speaker(dialogue_mgr)
  dialogue_mgr:add_speaker(self.speaker)
end

-- call before removal of last reference (destruction via garbage collection)
function character:unregister_speaker(dialogue_mgr)
  dialogue_mgr:remove_speaker(self.speaker)
end

-- render

function character:draw()
  self.sprite:render(self.pos)
end

return character
