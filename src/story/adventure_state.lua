local gamestate = require("engine/application/gamestate")

local flow = require("engine/application/flow")

local painter = require("render/painter")
local gameplay_data = require("resources/gameplay_data")

local adventure_state = derived_class(gamestate)

adventure_state.type = ':adventure'

function adventure_state:_init()
  gamestate._init(self)
end

function adventure_state:on_enter()
  local am = self.app.managers[':adventure']
  local dm = self.app.managers[':dialogue']

  am.active = true

  -- show bottom box immediately, otherwise we'll see that the lower stairs is not finished...
  dm.should_show_bottom_box = true

  self:start_sequence()
end

function adventure_state:on_exit()
  local am = self.app.managers[':adventure']
  local dm = self.app.managers[':dialogue']

  am.active = false

  dm.should_show_bottom_box = false
end

function adventure_state:update()
end

function adventure_state:render()
  painter.draw_background()

end

function adventure_state:start_sequence()
  self.app:start_coroutine(self._async_sequence, self)
end

function adventure_state:_async_sequence()
  local am = self.app.managers[':adventure']

  -- tutorial if any
  local play_method_name = '_async_tutorial'..self.app.game_session.fight_count
  if self[play_method_name] then
    self[play_method_name](self)
  end

  -- next step
  local play_method_name = '_async_'..am.next_step
  assert(self[play_method_name], "adventure_state has no method named: "..play_method_name)
  self[play_method_name](self)
end

-- tutorial methods: they all start with '_async_tutorial'
--   and we add a suffix equal to the fight count (so we may skip some values)

function adventure_state:_async_tutorial1()
  printh("tuto1")
  local am = self.app.managers[':adventure']
  local dm = self.app.managers[':dialogue']
  local fm = self.app.managers[':fight']
  local pc_speaker = am.pc.speaker

  self.app:yield_delay_s(1)
  pc_speaker:say_and_wait_for_input("ok, that was harsh.")
  pc_speaker:say_and_wait_for_input("i should write down the attacks i've just received so i can reuse them")
  pc_speaker:say_and_wait_for_input("an attack may lose its effect once said, so i shouldn't reuse the same twice in the same fight")
  pc_speaker:say_and_wait_for_input("ok, i'm done.")
  self.app:yield_delay_s(1)
end

function adventure_state:_async_tutorial2()
  printh("tuto2")
end

function adventure_state:_async_tutorial3()
  printh("tuto3")
end

-- step methods: they all start with '_async_'
--   and we add a suffix equal to a next_step name

function adventure_state:_async_intro()
  local am = self.app.managers[':adventure']
  local dm = self.app.managers[':dialogue']
  local fm = self.app.managers[':fight']
  local pc_speaker = am.pc.speaker

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

  local next_npc_fighter_prog = self.app.game_session.npc_fighter_progressions[13]

  -- show npc
  am:spawn_npc(next_npc_fighter_prog.fighter_info.character_info_id)
  local npc_speaker = am.npc.speaker

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

-- floor loop: must be played after at least 1 fight
function adventure_state:_async_floor_loop()
  local am = self.app.managers[':adventure']
  local fm = self.app.managers[':fight']
  local pc_speaker = am.pc.speaker

  -- plug special events after losing/winning vs npc (by id)
  -- only done if there was actually a fight with an opponent before
  if fm.next_opponent then
    local after_fight_method_name = '_after_fight_with_npc'..fm.next_opponent.fighter_info.id
    if self[after_fight_method_name] then
      self[after_fight_method_name](self)
    end

    -- check if player lost or won previous fight
    local floor_number = self.app.game_session.floor_number
    if self.app.managers[':fight'].won_last_fight then
      pc_speaker:say_and_wait_for_input("fine, let's go to the next floor now.")
      self.app:yield_delay_s(1)

      -- player won, allow access to next floor
      -- for now, auto go up 1 floor
      self.app.game_session.floor_number = min(floor_number + 1, 10)
      log("go to next floor: "..self.app.game_session.floor_number, "flow")
    else
      pc_speaker:say_and_wait_for_input("guess after my loss, i should go down one floor now.")
      self.app:yield_delay_s(1)

      -- player lost, prevent access to next floor
      -- for now, auto go down 1 floor
      self.app.game_session.floor_number = max(1, floor_number - 1)
      log("go to previous floor: "..self.app.game_session.floor_number, "flow")
    end

    -- clean existing npc
    am:despawn_npc()

    self.app:yield_delay_s(0.5)
  end

  pc_speaker:say_and_wait_for_input("someone is coming!")
  self.app:yield_delay_s(0.5)

  local next_npc_fighter_prog = fm:pick_matching_random_npc_fighter_prog()

  -- show npc
  am:spawn_npc(next_npc_fighter_prog.fighter_info.character_info_id)
  local npc_speaker = am.npc.speaker

  self.app:yield_delay_s(0.5)

  npc_speaker:say_and_wait_for_input("en garde!")
  self.app:yield_delay_s(0.5)

  fm.next_opponent = next_npc_fighter_prog
  flow:query_gamestate_type(':fight')
end

-- after fight with rossmann
function adventure_state:_after_fight_with_npc13()
  local fm = self.app.managers[':fight']

  -- rossmann had only level 1 attacks to avoid pc learning strong attacks too fast,
  --   but for next encounter, let rossmann learn the level 2 attacks he should have
  for attack_id in all(gameplay_data.rossmann_lv2_attack_ids) do
    add(fm.next_opponent.known_attack_ids, attack_id)
  end
end

return adventure_state
