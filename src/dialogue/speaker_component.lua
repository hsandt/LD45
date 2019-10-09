require("engine/core/class")

-- speaker component, allows any object to register to the dialogue manager
--   and say text in a bubble

local speaker_component = new_class()

-- parameters
--   bubble_tail_pos: vector        position of bubble tail
-- state
--   current_text: (string|nil)     current text said
--   wait_for_input: bool           if true and current text is set,
--                                    next confirm input will stop saying
function speaker_component:_init(bubble_tail_pos)
  self.bubble_tail_pos = bubble_tail_pos
  self.current_text = nil
  self.wait_for_input = false
end

-- set current text and wait_for_input flag
-- only dialogue manager can reset the flag, stopping text at the same time
-- you must check the flag in a loop in a coroutine calling `say`
function speaker_component:say(text, wait_for_input)
  if wait_for_input == nil then
    wait_for_input = false
  end

  self.current_text = text
  self.wait_for_input = wait_for_input
end

-- helper to combine say and wait_for_input flag checking loop
-- call inside coroutine only
function speaker_component:say_and_wait_for_input(text)
  self:say(text, true)

  while self.wait_for_input do
    yield()
  end
end

function speaker_component:stop()
  self.current_text = nil
  self.wait_for_input = false
end

return speaker_component
