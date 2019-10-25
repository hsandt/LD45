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
  self.app.managers[':adventure'].active = true

  -- register components
  self.app.managers[':dialogue']:add_speaker(self.pc.speaker)

  -- show bottom box immediately, otherwise we'll see that the lower stairs is not finished...
  self.app.managers[':dialogue'].should_show_bottom_box = true

  -- start next adventure step
  self:start_step(self.app.managers[':adventure'].next_step)
end

function adventure_state:on_exit()
  self.app.managers[':adventure'].active = false

  self.app.managers[':dialogue']:remove_speaker(self.pc.speaker)
  self.app.managers[':dialogue'].should_show_bottom_box = false
end

function adventure_state:update()
end

function adventure_state:render()
  painter.draw_background()
  self.pc:draw()
end

function adventure_state:start_step(next_step)
  -- build async method name to start as coroutine
  local play_method_name = '_play_'..next_step
  assert(self[play_method_name], "adventure_state has no method named: "..play_method_name)
  self.app:start_coroutine(self[play_method_name], self)
end

-- step methods: they all start with '_play_'
--   and we add a suffix equal to a next_step name

function adventure_state:_play_intro()
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
  self.app:yield_delay_s(1)

  pc_speaker:say_and_wait_for_input("wait, someone is coming!")
  self.app:yield_delay_s(0.5)

  self.app.managers[':fight']:set_next_opponent_to_matching_random_npc()
  flow:query_gamestate_type(':fight')
end

function adventure_state:_play_floor_loop()
  local pc_speaker = self.pc.speaker

  -- check if player lost or won previous fight
  local floor_number = self.app.game_session.floor_number
  if self.app.managers[':fight'].won_last_fight then
    pc_speaker:say_and_wait_for_input("great! i can go to the next floor")
    self.app:yield_delay_s(1)

    -- player won, allow access to next floor
    -- for now, auto go up 1 floor
    self.app.game_session.floor_number = min(floor_number + 1, 10)
    log("go to next floor: "..self.app.game_session.floor_number, "flow")
  else
    pc_speaker:say_and_wait_for_input("ah, too bad. i should go down one floor.")
    self.app:yield_delay_s(1)

    -- player lost, prevent access to next floor
    -- for now, auto go down 1 floor
    self.app.game_session.floor_number = max(1, floor_number - 1)
    log("go to previous floor: "..self.app.game_session.floor_number, "flow")
  end

  self.app:yield_delay_s(1)

  pc_speaker:say_and_wait_for_input("someone is coming!")
  self.app:yield_delay_s(0.5)

  self.app.managers[':fight']:set_next_opponent_to_matching_random_npc()
  flow:query_gamestate_type(':fight')
end

return adventure_state
