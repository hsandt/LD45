require("engine/core/class")

local visual_data = require("resources/visual_data")

bubble_types = {
  speech  = 1,
  thought = 2
}

-- speaker component, allows any object to register to the dialogue manager
--   and say text in a bubble

local speaker_component = new_class()

--[[
Owner
  entity: character             character owning this component

State
  bubble_type: bubble_types     type of current text, if any
  current_text: string|nil      current text said/thought
  wait_for_input: bool          if true and current text is set,
                                next confirm input will stop saying
  higher_text: bool             if true, bubble should be shown higher
--]]
function speaker_component:_init(entity)
  self.entity = entity

  self.bubble_type = bubble_types.speech
  self.current_text = nil
  self.wait_for_input = false
  self.higher_text = false
end

function speaker_component:get_final_bubble_tail_pos()
  -- compute offset for bubble type and character direction
  local bubble_tail_offset = visual_data.bubble_tail_offset_right_by_bubble_type[self.bubble_type]:copy()
  if self.entity.direction == horizontal_dirs.left then
    bubble_tail_offset:mirror_x()
  end

  -- apply offset to character position
  local bubble_tail_pos = self.entity.root_pos + bubble_tail_offset

  -- apply extra vertical offset for old dialogue line
  if self.higher_text then
    bubble_tail_pos = bubble_tail_pos + vector(0, visual_data.first_speaker_tail_offset_y)
  end

  return bubble_tail_pos
end

-- helper
function speaker_component:say(text, wait_for_input, higher_text)
  self:show_bubble(bubble_types.speech, text, wait_for_input, higher_text)
end

-- helper
function speaker_component:think(text, wait_for_input, higher_text)
  self:show_bubble(bubble_types.thought, text, wait_for_input, higher_text)
end

-- Set current text and wait_for_input flag
-- Only dialogue manager can reset the flag, stopping text at the same time.
-- You must check the flag in a loop in a coroutine calling `say`.
-- higher_text defaults to false so adventure characters' bubbles always
--   show at the normal height.
function speaker_component:show_bubble(bubble_type, text, wait_for_input, higher_text)
  if wait_for_input == nil then
    wait_for_input = false
  end
  if higher_text == nil then
    higher_text = false
  end

  self.bubble_type = bubble_type
  self.current_text = text
  self.wait_for_input = wait_for_input
  self.higher_text = higher_text
end

-- helper to combine say and wait_for_input flag checking loop
-- call inside coroutine only
function speaker_component:say_and_wait_for_input(text)
  self:say(text, true)

  while self.wait_for_input do
    yield()
  end
end

-- same for thought bubble
function speaker_component:think_and_wait_for_input(text)
  self:think(text, true)

  while self.wait_for_input do
    yield()
  end
end

function speaker_component:stop()
  self.current_text = nil
  self.wait_for_input = false
  self.higher_text = false
end

return speaker_component
