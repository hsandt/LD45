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
  self.npc = nil
end

function adventure_state:on_enter()
  local dm = self.app.managers[':dialogue']
  self.app.managers[':adventure'].active = true

  -- register components
  dm:add_speaker(self.pc.speaker)

  -- show bottom box immediately, otherwise we'll see that the lower stairs is not finished...
  dm.should_show_bottom_box = true

  -- start next adventure step
  self:start_step(self.app.managers[':adventure'].next_step)
end

function adventure_state:on_exit()
  local dm = self.app.managers[':dialogue']

  self.app.managers[':adventure'].active = false

  -- unregister components
  dm:remove_speaker(self.pc.speaker)
  if self.npc then
    dm:remove_speaker(self.npc.speaker)
    self.npc = nil
  end

  dm.should_show_bottom_box = false
end

function adventure_state:update()
end

function adventure_state:render()
  painter.draw_background()
  self.pc:draw()
  if self.npc then
    self.npc:draw()
  end
end

function adventure_state:spawn_npc(npc_id)
  local dm = self.app.managers[':dialogue']

  local npc_info = gameplay_data.npc_info_s[npc_id]
  self.npc = character(npc_info, horizontal_dirs.left, visual_data.npc_sprite_pos)
  self.npc:register_speaker(dm)
end

function adventure_state:despawn_npc()
  assert(self.npc)

  local dm = self.app.managers[':dialogue']

  self.npc:unregister_speaker(dm)
  self.npc = nil
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
  local dm = self.app.managers[':dialogue']
  local fm = self.app.managers[':fight']
  local pc_speaker = self.pc.speaker

  self.app:yield_delay_s(2)
  dm.current_bottom_text = '= main building of it company\n* browsing solutions * ='
  self.app:yield_delay_s(4)
  dm.current_bottom_text = nil
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

  local next_npc_fighter_prog = fm:pick_matching_random_npc_fighter_prog()

  -- show npc
  self:spawn_npc(next_npc_fighter_prog.fighter_info.character_info_id)
  local npc_speaker = self.npc.speaker

  self.app:yield_delay_s(1)

  npc_speaker:say_and_wait_for_input("well, well, well. see who's in here")
  pc_speaker:say_and_wait_for_input("not you again! i failed to get the ceo's support last time because of you!")
  npc_speaker:say_and_wait_for_input("not at all. you just messed up on your own.")
  pc_speaker:say_and_wait_for_input("enough! you're going down!")
  npc_speaker:say_and_wait_for_input("if you're so motivated, why not solve this with a wit fight?")
  npc_speaker:say_and_wait_for_input("we exchange verbal attacks and replies, and see who has the best comeback")
  pc_speaker:say_and_wait_for_input("er... okay.")

  -- start fight with npc
  fm.next_opponent = next_npc_fighter_prog
  flow:query_gamestate_type(':fight')
end

function adventure_state:_play_floor_loop()
  local fm = self.app.managers[':fight']
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

  -- clean existing npc
  self:despawn_npc()

  self.app:yield_delay_s(1)

  pc_speaker:say_and_wait_for_input("someone is coming!")
  self.app:yield_delay_s(0.5)

  local next_npc_fighter_prog = fm:pick_matching_random_npc_fighter_prog()

  -- show npc
  self:spawn_npc(next_npc_fighter_prog.fighter_info.character_info_id)
  local npc_speaker = self.npc.speaker

  self.app:yield_delay_s(0.5)

  npc_speaker:say_and_wait_for_input("en garde!")
  self.app:yield_delay_s(0.5)

  fm.next_opponent = next_npc_fighter_prog
  flow:query_gamestate_type(':fight')
end

return adventure_state
