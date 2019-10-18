local gamestate = require("engine/application/gamestate")

local flow = require("engine/application/flow")

local painter = require("render/painter")
local gameplay_data = require("resources/gameplay_data")
local visual_data = require("resources/visual_data")
local character = require("story/character")

local adventure_state = derived_class(gamestate)

adventure_state.type = ':adventure'

function adventure_state:_init()
  gamestate._init(self)

  self.pc = character(gameplay_data.pc_info, horizontal_dirs.right, visual_data.pc_sprite_pos)
end

function adventure_state:on_enter()
  -- register components
  self.app.managers[':dialogue']:add_speaker(self.pc.speaker)

  -- show bottom box immediately, otherwise we'll see that the lower stairs is not finished...
  self.app.managers[':dialogue'].should_show_bottom_box = true

  self.app:start_coroutine(self.play_intro, self)
end

function adventure_state:on_exit()
  self.app.managers[':dialogue']:remove_speaker(self.pc.speaker)
  self.app.managers[':dialogue'].should_show_bottom_box = false
end

function adventure_state:update()
end

function adventure_state:render()
  painter.draw_background()
  self.pc:draw()
end

function adventure_state:play_intro()
  local dm = self.app.managers[':dialogue']
  local pc_speaker = self.pc.speaker

  self.app:yield_delay_s(2)
  self.app.managers[':dialogue'].current_bottom_text = '= main building of it company\n* browsing solutions * ='
  self.app:yield_delay_s(4)
  self.app.managers[':dialogue'].current_bottom_text = nil
  self.app:yield_delay_s(2)
  pc_speaker:say_and_wait_for_input("ok, let's sum up")
  pc_speaker:say_and_wait_for_input("1. i need funding to organize a hackathon")
  pc_speaker:say_and_wait_for_input("2. my sister is the ceo of this company and could be my sponsor")
  pc_speaker:say_and_wait_for_input("3. she's working at the 20th floor")
  pc_speaker:say_and_wait_for_input("4. i don't want be to seen, so i'm avoiding the elevator, but those stairs seem endless")
  pc_speaker:say_and_wait_for_input("seems good so far. what could go wrong?")

  self.app.managers[':fight']:set_next_opponent_to_matching_random_npc()
  flow:query_gamestate_type(':fight')
end

return adventure_state
