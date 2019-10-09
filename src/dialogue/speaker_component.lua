require("engine/core/class")

-- speaker component, allows any object to register to the dialogue manager
--   and say text in a bubble

local speaker_component = new_class()

-- parameters
--   bubble_tail_pos: vector        position of bubble tail
-- state
--   current_text: string           current text said
function speaker_component:_init(bubble_tail_pos)
  self.bubble_tail_pos = bubble_tail_pos
  self.current_text = nil
end

function speaker_component:say(text)
  self.current_text = text
end

function speaker_component:stop()
  self.current_text = nil
end

return speaker_component
