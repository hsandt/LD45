require("engine/core/class")

local speaker_component = require("dialogue/speaker_component")

-- character class
-- unlike fighter, it doesn't have battle attributes

local visual_data = require("resources/visual_data")

local character = new_class()

-- components
--   speaker: speaker_component
-- parameters
--   sprite: sprite_data               sprite to render
--   rel_bubble_tail_pos: vector       position of bubble tail relative to foot position
--                                     (above head)
-- state
--   pos: vector                       foot position on screen. only changes during animations
function character:_init(sprite, pos, rel_bubble_tail_pos)
  self.sprite = sprite
  self.speaker = speaker_component(pos + rel_bubble_tail_pos)
  self.pos = pos
end

-- render

function character:draw()
  self.sprite:render(self.pos)
end

return character
