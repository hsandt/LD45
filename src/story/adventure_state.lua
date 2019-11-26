local gamestate = require("engine/application/gamestate")

local flow = require("engine/application/flow")

local painter = require("render/painter")
local audio_data = require("resources/audio_data")
local gameplay_data = require("resources/gameplay_data")

local adventure_state = new_class(gamestate)

adventure_state.type = ':adventure'

function adventure_state:_init()
  gamestate._init(self)

  self.forced_next_floor_number = nil
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

  -- clear adventure manager (except persistent pc)
  if am.npc then
    am:despawn_npc()
  end
  am.active = false

  -- clear dialogue manager (except unregister speaker, which is done in despawn_npc,
  --   although not pc since it is preserved)
  dm.should_show_bottom_box = false
  dm.current_bottom_text = nil

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

  local next_npc_fighter_prog = self.app.game_session.npc_fighter_progressions[gameplay_data.rossmann_fighter_id]
  self:async_encounter_npc(next_npc_fighter_prog)
end

function adventure_state:_async_step_floor_loop()
  local gs = self.app.game_session
  local am = self.app.managers[':adventure']
  local fm = self.app.managers[':fight']
  local pc_speaker = am.pc.speaker

  -- if we have just exited a fight, play the aftermath sequence
  if gs.last_opponent then
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

    -- clear current progression completely, to avoid starting a new game already at the end
    -- for now, there is no notion of persistency (like "best score" stuff), so we clear everything
    app.game_session = game_session()
    return
  end

  -- after-fight tutorial if any
  local async_tutorial_method = adventure_state.async_tutorials[gs.fight_count]
  if async_tutorial_method then
    async_tutorial_method(self)
  end

  if gs.floor_number < #gameplay_data.floors then
    -- non ceo room only
    pc_speaker:say_and_wait_for_input("someone is coming!")
  end

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

  local npc_fighter_id = npc_fighter_prog.fighter_info.id

  -- before fight sequence
  local async_before_fight_method = adventure_state.async_before_fight_with_npcs[npc_fighter_prog.fighter_info.id]
  if async_before_fight_method then
    async_before_fight_method(self, npc_fighter_id)
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
  local gs = self.app.game_session
  local am = self.app.managers[':adventure']
  local fm = self.app.managers[':fight']
  local pc_speaker = am.pc.speaker
  local npc_speaker = am.npc.speaker

  assert(gs.last_opponent, "no previous opponent, cannot play aftermath")

  local npc_fighter_id = gs.last_opponent.fighter_info.id

  -- after fight sequence, specific to each npc
  local async_after_fight_method = adventure_state.async_after_fight_with_npcs[npc_fighter_id]
  if async_after_fight_method then
    async_after_fight_method(self, npc_fighter_id)
  else
    if fm.won_last_fight then
      npc_speaker:say_and_wait_for_input("urg...")
    else
      npc_speaker:say_and_wait_for_input("ha! you won't go past me!")
    end
  end

  -- remember pc met that npc so you don't always play the same special dialogues twice
  gs:register_met_npc(npc_fighter_id)

  if self.should_finish_game then
    -- avoid any extra events until we leave the game properly
    -- despawn npc, stop music, etc. will be done in adventure_state:on_exit
    return
  end

  if self.forced_next_floor_number then
    -- assign forced floor and consume immediately
    gs.floor_number = self.forced_next_floor_number
    self.forced_next_floor_number = nil

    log("go to forced floor: "..gs.floor_number, 'adventure')

    -- remove existing npc last (after fade-out), as he was blocking you
    am:despawn_npc()
  else
    -- check if player lost or won previous fight
    local floor_number = gs.floor_number
    if fm.won_last_fight then
      -- remove existing npc first, as he lost
      am:despawn_npc()

      -- player won, allow access to next floor
      -- for now, auto go up 1 floor
      pc_speaker:say_and_wait_for_input("fine, let's go to the next floor now.")

      gs.floor_number = min(floor_number + 1, #gameplay_data.floors)
      log("go to next floor: "..gs.floor_number, 'adventure')
    else
      -- player lost, prevent access to next floor
      -- for now, auto go down 1 floor
      pc_speaker:say_and_wait_for_input("guess after my loss, i should go down one floor now.")

      gs.floor_number = max(1, floor_number - 1)
      log("go to previous floor: "..gs.floor_number, 'adventure')

    -- remove existing npc last (after fade-out), as he was blocking you
      am:despawn_npc()
    end
  end
end

-- tutorial sequence methods
-- they all start with `async_tutorial_`
--   and take 1 param self: adventure_state (those functions are like method,
--   except we must pass `self` manually as 1st param due to dynamic access of functions)

local function async_tutorial_learn_attacks(self)
  local am = self.app.managers[':adventure']
  local pc_speaker = am.pc.speaker

  self.app:yield_delay_s(1)
  pc_speaker:say_and_wait_for_input("damn, here i start over from the first floor.")
  self.app:yield_delay_s(0.5)
  pc_speaker:say_and_wait_for_input("i need to go back there, but first i should think about how to beat those guys.")
  pc_speaker:say_and_wait_for_input("i'll write down the attacks i've just received so i can reuse them.")
  pc_speaker:say_and_wait_for_input("an attack may lose its effect once said, so i shouldn't reuse the same twice in the same fight.")
  self.app:yield_delay_s(1)
  pc_speaker:say_and_wait_for_input("ok, i'm done.")
  self.app:yield_delay_s(1)
end

local function async_tutorial_reply_power(self)
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

local function async_tutorial_npc_learning(self)
  local am = self.app.managers[':adventure']
  local pc_speaker = am.pc.speaker

  self.app:yield_delay_s(1)
  pc_speaker:say_and_wait_for_input("i feel like my opponents are also learning my quotes.")
  pc_speaker:say_and_wait_for_input("besides, if they randomly find a good reply they will probably reuse them later.")
  pc_speaker:say_and_wait_for_input("i should be careful when exposing my opponents to new quotes.")
  pc_speaker:say_and_wait_for_input("that said, newbies are probably not good enough to learn selfanced quotes.")
  pc_speaker:say_and_wait_for_input("fine, let's go on.")
  self.app:yield_delay_s(1)
end

-- after [key] fights, we show tutorial with sequence method [value]
adventure_state.async_tutorials = {
  [1] = async_tutorial_learn_attacks,
  [2] = async_tutorial_reply_power,
  [3] = async_tutorial_npc_learning,
}

-- before/after fight sequence methods
-- they all start with `async_tutorial_`
--   and take 1 param self: adventure_state (those functions are like method,
--   except we must pass `self` manually as 1st param due to dynamic access of functions)
--   + 1 param npc_fighter_id (of course we can deduce that from the context, it is just passed
--   for convenience)

local function async_before_fight_with_ceo(self, npc_fighter_id)
  local am = self.app.managers[':adventure']
  local pc_speaker = am.pc.speaker
  local npc_speaker = am.npc.speaker

  if not self.app.game_session:has_met_npc(npc_fighter_id) then
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

local function async_after_fight_with_ceo(self, npc_fighter_id)
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

local function async_before_fight_with_rossmann(self, npc_fighter_id)
  local am = self.app.managers[':adventure']
  local pc_speaker = am.pc.speaker
  local npc_speaker = am.npc.speaker

  if not self.app.game_session:has_met_npc(npc_fighter_id) then
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
local function async_after_fight_with_rossmann(self, npc_fighter_id)
  local gs = self.app.game_session
  local am = self.app.managers[':adventure']
  local fm = self.app.managers[':fight']
  local pc_speaker = am.pc.speaker
  local npc_speaker = am.npc.speaker

  if not gs:has_met_npc(npc_fighter_id) then
    -- rossmann had only level 1 attacks to avoid pc learning strong attacks too fast,
    --   but for next encounter, let rossmann learn the level 2 attacks he should have
    for attack_id in all(gameplay_data.rossmann_lv2_attack_ids) do
      add(gs.last_opponent.known_attack_ids, attack_id)
    end

    pc_speaker:say_and_wait_for_input("damn...")
    npc_speaker:say_and_wait_for_input("so, still want to see the boss? she's just upstairs, after all.")
    pc_speaker:say_and_wait_for_input("...")
    npc_speaker:say_and_wait_for_input("i guess you finally understood the difference of power.")
    npc_speaker:say_and_wait_for_input("if you still hope to defeat us, you'd better start from the bottom of the hierarchy.")
    npc_speaker:say_and_wait_for_input("see you, then!")

    -- yup, we don't check if pc won last fight because he's not supposed to,
    -- as in famous pre-story RPG fights. so if you cheat, you'll still have to go down!
    self.forced_next_floor_number = 1

    -- no further dialogues
    return
  end

  if fm.won_last_fight then
    npc_speaker:say_and_wait_for_input("can't believe i lost to a brat...")
    pc_speaker:say_and_wait_for_input("ehe")
  else
    npc_speaker:say_and_wait_for_input("just as i expected.")
    pc_speaker:say_and_wait_for_input("damn!")
  end
end

adventure_state.async_before_fight_with_npcs = {
  [gameplay_data.rossmann_fighter_id] = async_before_fight_with_rossmann,
  [gameplay_data.ceo_fighter_id] = async_before_fight_with_ceo,
}

adventure_state.async_after_fight_with_npcs = {
  [gameplay_data.rossmann_fighter_id] = async_after_fight_with_rossmann,
  [gameplay_data.ceo_fighter_id] = async_after_fight_with_ceo,
}

return adventure_state
