local gamestate = require("engine/application/gamestate")

local flow = require("engine/application/flow")

local painter = require("render/painter")
local audio_data = require("resources/audio_data")
local gameplay_data = require("resources/gameplay_data")

local adventure_state = new_class(gamestate)

adventure_state.type = ':adventure'

-- after [key] fights, we show tutorial [value]
local fight_count_to_tutorial_map = {
  [1] = 1,
  [3] = 2,
  [6] = 3
}

function adventure_state:_init()
  gamestate._init(self)

  self.should_finish_game = false
end

function adventure_state:on_enter()
  local am = self.app.managers[':adventure']
  local dm = self.app.managers[':dialogue']

  am.active = true

  -- show bottom box immediately, otherwise we'll see that the lower stairs is not finished...
  dm.should_show_bottom_box = true

  -- audio: start bgm
  music(audio_data.bgm.thinking)

  self:start_sequence()
end

function adventure_state:on_exit()
  local am = self.app.managers[':adventure']
  local dm = self.app.managers[':dialogue']

  am.active = false

  dm.should_show_bottom_box = false

  music(-1)
end

function adventure_state:update()
end

function adventure_state:render()
  painter.draw_background(self.app.game_session.floor_number)
end

function adventure_state:start_sequence()
  self.app:start_coroutine(self._async_sequence, self)
end

function adventure_state:_async_sequence()
  local am = self.app.managers[':adventure']
  local fm = self.app.managers[':fight']

  -- next step
  local play_method_name = '_async_step_'..am.next_step
  assert(self[play_method_name], "adventure_state has no method named: "..play_method_name)
  self[play_method_name](self)
end

-- step sequence methods
-- they all start with '_async_step_'

function adventure_state:_async_step_intro()
  local am = self.app.managers[':adventure']
  local dm = self.app.managers[':dialogue']
  local pc_speaker = am.pc.speaker

  self.app:yield_delay_s(0.5)
  dm.current_bottom_text = '= main building of it company\n* browsing solutions * ='
  self.app:yield_delay_s(2)
  dm.current_bottom_text = nil
  self.app:yield_delay_s(1)
  pc_speaker:think_and_wait_for_input("ok, let's sum up")
  pc_speaker:think_and_wait_for_input("1. i need funding to organize a hackathon")
  pc_speaker:think_and_wait_for_input("2. my sister is the ceo of this company and could be my sponsor")
  pc_speaker:think_and_wait_for_input("3. she's working at the 20th floor")
  pc_speaker:think_and_wait_for_input("4. i don't want be to seen, so i'm avoiding the elevator, but those stairs seem endless")
  pc_speaker:think_and_wait_for_input("seems good so far. what could go wrong?")
  self.app:yield_delay_s(1)

  pc_speaker:think_and_wait_for_input("wait, someone is coming!")
  self.app:yield_delay_s(0.5)

  local next_npc_fighter_prog = self.app.game_session.npc_fighter_progressions[gameplay_data.rossmann_id]
  self:async_encounter_npc(next_npc_fighter_prog)
end

function adventure_state:_async_step_floor_loop()
  local am = self.app.managers[':adventure']
  local fm = self.app.managers[':fight']
  local pc_speaker = am.pc.speaker

  -- if we have just exited a fight, play the aftermath sequence
  if fm.next_opponent then
    self:async_fight_aftermath()
  end

  if self.should_finish_game then
    -- we should also despawn pc, but currently it's spawned on adventure_manager:start
    -- so to be really symmetrical, we need to create methods for in-game start/stop
    --   to be called when actually starting game from menu, and finishing game session
    --   to come back to main menu (maybe put them in game session or some game session manager)
    -- then call spawn_npc on game session start, despawn_pc on game session end
    am:despawn_npc()

    -- back to main menu
    flow:query_gamestate_type(':main_menu')
    return
  end

  -- after-fight tutorial if any
  local tutorial_number = fight_count_to_tutorial_map[self.app.game_session.fight_count]
  if tutorial_number then
    local play_method_name = '_async_tutorial'..tutorial_number
    assert(self[play_method_name], "adventure_state has no method named: "..play_method_name)
    self[play_method_name](self)
  end

  pc_speaker:say_and_wait_for_input("someone is coming!")
  self.app:yield_delay_s(0.5)

  local next_npc_fighter_prog = fm:pick_matching_random_npc_fighter_prog()
  self:async_encounter_npc(next_npc_fighter_prog)
end

function adventure_state:async_encounter_npc(npc_fighter_prog)
  local am = self.app.managers[':adventure']
  local fm = self.app.managers[':fight']
  local pc_speaker = am.pc.speaker

  music(audio_data.bgm.encounter)

  -- show npc
  am:spawn_npc(npc_fighter_prog.fighter_info.character_info_id)
  local npc_speaker = am.npc.speaker

  -- before fight sequence
  local before_fight_method_name = '_async_before_fight_with_npc'..npc_fighter_prog.fighter_info.id
  if self[before_fight_method_name] then
    self[before_fight_method_name](self)
  else
    npc_speaker:say_and_wait_for_input("en garde!")
  end

  -- audio: stop bgm
  music(-1)

  -- start fight
  fm.next_opponent = npc_fighter_prog
  flow:query_gamestate_type(':fight')
end

function adventure_state:async_fight_aftermath()
  local am = self.app.managers[':adventure']
  local fm = self.app.managers[':fight']
  local pc_speaker = am.pc.speaker
  local npc_speaker = am.npc.speaker

  assert(fm.next_opponent, "no previous opponent, cannot play aftermath")

  local npc_id = fm.next_opponent.fighter_info.id

  -- after fight sequence, specific to each npc
  local after_fight_method_name = '_async_after_fight_with_npc'..npc_id
  if self[after_fight_method_name] then
    self[after_fight_method_name](self)
    if self.should_finish_game then
      -- avoid any extra events until we leave the game properly
      return
    end
  else
    if fm.won_last_fight then
      npc_speaker:say_and_wait_for_input("urg...")
    else
      npc_speaker:say_and_wait_for_input("ha! you won't go past me!")
    end
  end

  -- remember pc met that npc so you don't always play the same special dialogues twice
  self.app.game_session:register_met_npc(npc_id)

  -- check if player lost or won previous fight
  local floor_number = self.app.game_session.floor_number
  if fm.won_last_fight then
    -- remove existing npc first
    am:despawn_npc()

    -- player won, allow access to next floor
    -- for now, auto go up 1 floor
    pc_speaker:say_and_wait_for_input("fine, let's go to the next floor now.")

    self.app.game_session.floor_number = min(floor_number + 1, #gameplay_data.floors)
    log("go to next floor: "..self.app.game_session.floor_number, "flow")
  else
    -- player lost, prevent access to next floor
    -- for now, auto go down 1 floor
    pc_speaker:say_and_wait_for_input("guess after my loss, i should go down one floor now.")

    self.app.game_session.floor_number = max(1, floor_number - 1)
    log("go to previous floor: "..self.app.game_session.floor_number, "flow")

    -- remove existing npc last, as he was blocking you (even after fade-out)
    am:despawn_npc()
  end
end

-- tutorial sequence methods
-- they all start with '_async_tutorial'

function adventure_state:_async_tutorial1()
  local am = self.app.managers[':adventure']
  local pc_speaker = am.pc.speaker

  self.app:yield_delay_s(1)
  pc_speaker:say_and_wait_for_input("ok, that was harsh.")
  pc_speaker:say_and_wait_for_input("i should write down the attacks i've just received so i can reuse them")
  pc_speaker:say_and_wait_for_input("an attack may lose its effect once said, so i shouldn't reuse the same twice in the same fight")
  self.app:yield_delay_s(1)
  pc_speaker:say_and_wait_for_input("ok, i'm done.")
  self.app:yield_delay_s(1)
end

function adventure_state:_async_tutorial2()
  local am = self.app.managers[':adventure']
  local pc_speaker = am.pc.speaker

  self.app:yield_delay_s(1)
  pc_speaker:say_and_wait_for_input("looks like some replies work better than others.")
  pc_speaker:say_and_wait_for_input('normal replies are "ok"')
  pc_speaker:say_and_wait_for_input('good replies are "smart"')
  pc_speaker:say_and_wait_for_input('very good replies are "witty"')
  pc_speaker:say_and_wait_for_input("the better the reply, the higher the damage. useful.")
  pc_speaker:say_and_wait_for_input("let's go now.")
  self.app:yield_delay_s(1)
end

function adventure_state:_async_tutorial3()
  local am = self.app.managers[':adventure']
  local pc_speaker = am.pc.speaker

  self.app:yield_delay_s(1)
  pc_speaker:say_and_wait_for_input("i feel like my opponents are also learning my quotes.")
  pc_speaker:say_and_wait_for_input("besides, if they randomly find a good reply they will probably reuse them later.")
  pc_speaker:say_and_wait_for_input("i should be careful when exposing my opponents to new quotes.")
  pc_speaker:say_and_wait_for_input("that said, newbies are probably not good enough to learn advanced quotes.")
  pc_speaker:say_and_wait_for_input("fine, let's go on.")
  self.app:yield_delay_s(1)
end

-- before/after fight sequence methods
-- they all start with '_async_before/after_fight_with_npc'

-- before fight with ceo
function adventure_state:_async_before_fight_with_npc12()
  local am = self.app.managers[':adventure']
  local pc_speaker = am.pc.speaker
  local npc_speaker = am.npc.speaker

  if not self.app.game_session:has_met_npc(12) then
    npc_speaker:say_and_wait_for_input("you took your time.")
    npc_speaker:say_and_wait_for_input("i was about to leave.")
    pc_speaker:say_and_wait_for_input("this time, i won't leave without your sponsorship!")
    npc_speaker:say_and_wait_for_input("why do you so much want the support of a corporation for an independent event?")
    self.app:yield_delay_s(0.5)
    pc_speaker:say_and_wait_for_input("we need funds.")
    self.app:yield_delay_s(0.5)
    npc_speaker:say_and_wait_for_input("you'll need better words than that to convince me.")
    pc_speaker:say_and_wait_for_input("that's perfect, i've got exactly what you're asking for.")
  else
    npc_speaker:say_and_wait_for_input("i'm glad you learned so well from me. you need persistence to succeed.")
    self.app:yield_delay_s(1)
    npc_speaker:say_and_wait_for_input("but sometimes, it's just not enough.")
  end
end

-- after fight with ceo
function adventure_state:_async_after_fight_with_npc12()
  local am = self.app.managers[':adventure']
  local dm = self.app.managers[':dialogue']
  local fm = self.app.managers[':fight']
  local pc_speaker = am.pc.speaker
  local npc_speaker = am.npc.speaker

  if fm.won_last_fight then
    npc_speaker:say_and_wait_for_input("huh... you got better wits than last time.")
    pc_speaker:say_and_wait_for_input("no, yours are just rotten.")
    npc_speaker:say_and_wait_for_input("ok, ok, enough replies for today. we will sponsor your event.")
    npc_speaker:say_and_wait_for_input("i'll send someone to oversee the details with you tomorrow.")
    self.app:yield_delay_s(0.5)
    pc_speaker:say_and_wait_for_input("er... thanks.")
    self.app:yield_delay_s(0.5)
    npc_speaker:say_and_wait_for_input("you can go, now.")
    self.app:yield_delay_s(0.5)
    pc_speaker:say_and_wait_for_input("ah, ok.")
    self.app:yield_delay_s(0.5)
    -- todo: pc turning toward the camera
    pc_speaker:say_and_wait_for_input("what a day. i hope it was worth it.")

    self.app:yield_delay_s(0.5)
    dm.current_bottom_text = 'GAME END'
    self.app:yield_delay_s(2)
    dm.current_bottom_text = nil

    -- GAME END
    self.should_finish_game = true
  else
    npc_speaker:say_and_wait_for_input("that's all? you're wasting my time.")
    self.app:yield_delay_s(0.5)
  end
end

-- before fight with rossmann
function adventure_state:_async_before_fight_with_npc13()
  local am = self.app.managers[':adventure']
  local pc_speaker = am.pc.speaker
  local npc_speaker = am.npc.speaker

  if not self.app.game_session:has_met_npc(13) then
    npc_speaker:say_and_wait_for_input("well, well, well. see who's in here")
    pc_speaker:say_and_wait_for_input("not you again! i failed to get the ceo's support last time because of you!")
    npc_speaker:say_and_wait_for_input("not at all. you just messed up on your own.")
    pc_speaker:say_and_wait_for_input("enough! you're going down!")
    npc_speaker:say_and_wait_for_input("if you're so motivated, why not solve this with a wit fight?")
    npc_speaker:say_and_wait_for_input("we exchange verbal attacks and replies, and see who has the best comeback")
    pc_speaker:say_and_wait_for_input("er... okay.")
  else
    pc_speaker:say_and_wait_for_input("you again...")
    npc_speaker:say_and_wait_for_input("ready for a re-match!")
  end

end

-- after fight with rossmann
function adventure_state:_async_after_fight_with_npc13()
  local am = self.app.managers[':adventure']
  local fm = self.app.managers[':fight']
  local pc_speaker = am.pc.speaker
  local npc_speaker = am.npc.speaker

  if not self.app.game_session:has_met_npc(13) then
    -- rossmann had only level 1 attacks to avoid pc learning strong attacks too fast,
    --   but for next encounter, let rossmann learn the level 2 attacks he should have
    for attack_id in all(gameplay_data.rossmann_lv2_attack_ids) do
      add(fm.next_opponent.known_attack_ids, attack_id)
    end
  end

  if fm.won_last_fight then
    npc_speaker:say_and_wait_for_input("can't believe i lost to a brat...")
    pc_speaker:say_and_wait_for_input("ehe")
  else
    npc_speaker:say_and_wait_for_input("just as i expected.")
    pc_speaker:say_and_wait_for_input("damn!")
  end
end

return adventure_state
