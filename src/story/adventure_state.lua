require("engine/application/constants")
local gamestate = require("engine/application/gamestate")

local flow = require("engine/application/flow")

local menu_item = require("menu/menu_item")
local game_session = require("progression/game_session")
local painter = require("render/painter")
local audio_data = require("resources/audio_data")
local gameplay_data = require("resources/gameplay_data")
local visual_data = require("resources/visual_data")

local adventure_state = new_class(gamestate)

adventure_state.type = ':adventure'

function adventure_state:_init()
  gamestate._init(self)

  self.forced_next_floor_number = nil
  self.should_finish_game = false

  -- render param (precomputed on game start)
  self.max_nb_lines = screen_height + ceil(screen_width / visual_data.fade_line_step_width) - 1

  -- render state
  self.fade_out_nb_lines = 0
  self.fade_in_nb_lines = 0
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
  local am = self.app.managers[':adventure']

  painter.draw_background(self.app.game_session.floor_number)
  painter.draw_floor_number(self.app.game_session.floor_number)

  -- prefer drawing characters from adventure_state:render than adventure_manager:render,
  --   as flow/gamestate is rendered before managers, and dialogue manager should render bubbles
  --   on top of characters (we could also register adventure manager before dialogue manager,
  --   but we prefer avoiding relying on exact script execution order)
  am:draw_characters()
end

function adventure_state:render_post()
  self:render_fade()
end

function adventure_state:render_fade()
  if self.fade_out_nb_lines > 0 then
    -- draw all the fade lines from the top-left corner to the current frontier,
    --   so we iterate again from 1
    for i = 0, self.fade_out_nb_lines - 1 do
      -- the most efficient is to only draw the part inside the screen
      -- but then we need to distinguish 2 phases: drawing from the left side (i = 0..screen_height)
      --   and drawing from the bottom side (i=screen_height..max_nb_lines)
      -- for now we don't know if it's worth the optimization, so just draw a giant line covering the screen
      --   from side to side
      -- also, we go a bit too far over the right edge when fade_line_step_width >= 2,
      --   just because it's safer to compute products than dividing when we want perfect pixel steps
      -- (128 is divisible by 2 so for 2, we could have (0, i, screen_width, i - screen_width / 2)
      line(0, i, visual_data.fade_line_step_width * screen_width, i - screen_width, colors.black)
    end
  elseif self.fade_in_nb_lines > 0 then
    for i = self.max_nb_lines - self.fade_in_nb_lines, self.max_nb_lines - 1 do
      line(0, i, visual_data.fade_line_step_width * screen_width, i - screen_width, colors.black)
    end
  end
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
  dm:show_bottom_text_and_wait_for_input('10:04\n\nheadquarters of it company\n"virtual frameworks" - 5f')
  self.app:yield_delay_s(1)
  pc_speaker:think_and_wait_for_input("ok, let's sum up")
  pc_speaker:think_and_wait_for_input("1. i need funding to organize a hackathon")
  pc_speaker:think_and_wait_for_input("2. my sister is the ceo of this company and could be my sponsor")
  pc_speaker:think_and_wait_for_input("3. i contacted her and we should meet on 6f, so just upstairs")
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
    self.app.game_session = game_session()
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
  local dm = self.app.managers[':dialogue']
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
    self:async_fade_out()

    -- unlock and assign forced floor, then consume immediately
    gs:unlock_floor(self.forced_next_floor_number)
    gs:go_to_floor(self.forced_next_floor_number)
    self.forced_next_floor_number = nil
    log("go to forced floor: "..gs.floor_number, 'adventure')

    -- remove existing npc last (after fade-out), as he was blocking you
    am:despawn_npc()

    self:async_fade_in()
  else
    -- check if player lost or won previous fight
    local floor_number = gs.floor_number
    if fm.won_last_fight then
      -- remove existing npc first, as he lost
      am:despawn_npc()

      -- some floors "level up" the pc by increasing his max hp, so check that
      self:async_check_max_hp_increase(floor_number)

      -- player won, allow access to next floor
      pc_speaker:say_and_wait_for_input("okay, should i continue?")

      local next_floor = min(floor_number + 1, #gameplay_data.floors)

      -- whatever the player chooses, unlock the next floor now
      -- otherwise, if the next floor is a checkpoint (zone start),
      --   the player may decide to warp to a lower checkpoint,
      --   and the checkpoint he/she was about to continue to
      --   will not be recorded so he/she will have to win again to get there
      gs:unlock_floor(next_floor)
      self:async_prompt_go_to_floor(next_floor, "go up to")
      log("go to next floor: "..gs.floor_number, 'adventure')
    else
      -- player lost, prevent access to next floor
      pc_speaker:say_and_wait_for_input("i can't go up with my defeat... what do i do?")

      local next_floor
      if floor_number > 1 then
        next_floor = floor_number - 1
        default_verb = "go down to"
      else
        next_floor = 1
        default_verb = "retry at"
      end
      gs:unlock_floor(next_floor)
      self:async_prompt_go_to_floor(next_floor, default_verb)
      log("go to previous floor: "..gs.floor_number, 'adventure')
    end
  end
end

function adventure_state:async_prompt_go_to_floor(next_floor, default_verb)
  local gs = self.app.game_session
  local am = self.app.managers[':adventure']
  local dm = self.app.managers[':dialogue']

  local chosen_floor_number = nil

  -- first item is always to continue to next floor
  local items = {
    menu_item(default_verb.." "..next_floor.."f", function ()
      chosen_floor_number = next_floor
    end)
  }

  -- then, if zone starts aka checkpoints have been reached and are in a different zone than
  --   the next floor, add them as other choices
  -- start with highest levels first
  for zone = #gameplay_data.zone_start_floors, 1, -1 do
    local checkpoint_floor_number = gameplay_data.zone_start_floors[zone]
    if checkpoint_floor_number <= gs.max_unlocked_floor then
      local next_zone = gameplay_data:get_zone(next_floor)
      if next_zone ~= zone then
        local verb_str = checkpoint_floor_number == gs.floor_number and "retry at" or "warp to"
        local item = menu_item(verb_str.." "..checkpoint_floor_number.."f", function ()
          chosen_floor_number = checkpoint_floor_number
        end)
        add(items, item)
      end
    end
  end

  dm:prompt_items(items)

  -- async wait for confirming a choice
  while not chosen_floor_number do
    yield()
  end

  self:async_fade_out()

  -- remove existing npc last (after fade-out) if still here, as he was blocking you
  -- this only happens after losing
  am:try_despawn_npc()

  gs:go_to_floor(chosen_floor_number)

  self:async_fade_in()
end

function adventure_state:async_fade_out()
  -- draw diagonal black lines (slightly horizontal)
  --   one by one from the top-left corner of the screen
  -- remember that this coroutine is played every frame after the rest is rendered,
  --   so you need to redraw all the lines so far each time

  -- compute number of lines needed to cover the screen
  -- basically, we need to spawn a line from each pixel on the left side, so over screen_height
  -- then we need to spawn a line from the bottom line, but thanks to them being inclined
  --   we can divide the number by the number of horizontal steps per vertical step
  -- we ceil to be sure to cover completely the distance
  -- finally, we remove 1 as the corner overlaps both the left and the bottom side
  for nb_lines = 1, self.max_nb_lines, visual_data.fade_speed do
    self.fade_out_nb_lines = nb_lines
    yield()
  end
  -- in case the iteration does not fall exactly on the max value
  -- we need to set it manually so the screen is fully covered
  self.fade_out_nb_lines = self.max_nb_lines
end

function adventure_state:async_fade_in()
  -- clean the previous fade-out to be sure the we don't reverse to black screen
  -- after the fade-in
  self.fade_out_nb_lines = 0

  -- reverse operation, draw only the last lines (near bottom-right corner)
  for nb_lines = self.max_nb_lines, 0, - visual_data.fade_speed do
    self.fade_in_nb_lines = nb_lines
    yield()
  end
  -- in case the iteration does not fall exactly on 0
  -- we need to set it manually so the screen is fully covered
  self.fade_in_nb_lines = 0
end

function adventure_state:async_check_max_hp_increase(floor_number)
  local gs = self.app.game_session

  local min_max_hp = gameplay_data.max_hp_after_win_by_floor_number[floor_number]
  if min_max_hp and gs.pc_fighter_progression.max_hp < min_max_hp then
    self:async_increase_pc_max_hp(gs.pc_fighter_progression, min_max_hp)
  end
end

function adventure_state:async_increase_pc_max_hp(pc_fighter_prog, new_max_hp)
  local dm = self.app.managers[':dialogue']

  assert(pc_fighter_prog.max_hp < new_max_hp)
  pc_fighter_prog.max_hp = new_max_hp
  log("pc max hp increase to "..new_max_hp, 'progression')

  dm.current_bottom_text = 'player character stamina increases to '..new_max_hp..'!'
  self.app:yield_delay_s(2)
  dm.current_bottom_text = nil
  self.app:yield_delay_s(1)
end

-- tutorial sequence methods
-- they all start with `async_tutorial_`
--   and take 1 param self: adventure_state (those functions are like method,
--   except we must pass `self` manually as 1st param due to dynamic access of functions)

local function async_tutorial_learn_attacks(self)
  local gs = self.app.game_session
  local am = self.app.managers[':adventure']
  local pc_speaker = am.pc.speaker

  self.app:yield_delay_s(1)
  pc_speaker:say_and_wait_for_input("damn, here i start over from the first floor.")
  self.app:yield_delay_s(0.5)
  pc_speaker:say_and_wait_for_input("i need to go back there, but first i should think about how to beat those guys.")
  pc_speaker:say_and_wait_for_input("i'll write down the attacks i've just received so i can reuse them.")
  self.app:yield_delay_s(1)
  pc_speaker:say_and_wait_for_input("ok, i'm done.")
  pc_speaker:say_and_wait_for_input("i'll only be able to reuse my opponents' attacks and replies on the next fight, though.")
  self.app:yield_delay_s(1)
  pc_speaker:say_and_wait_for_input("in any case, my first defeat made me stronger.")

  -- increase player stamina to 3 after tutorial (with safety check to avoid decreasing max hp when
  --   debugging and teleporting the player to some floor from start)
  -- usually we don't affect change gameplay values in tutorial, but here
  --   it's convenient to do it here; just make sure that if you let the player
  --   skip tutorials, you still call this block as part of the aftermath
  local new_max_hp = gameplay_data.max_hp_after_first_tutorial
  if gs.pc_fighter_progression.max_hp < new_max_hp then
    self:async_increase_pc_max_hp(gs.pc_fighter_progression, new_max_hp)
  end

  pc_speaker:say_and_wait_for_input("okay, time to go!")
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

local function async_tutorial_quote_consumption(self)
  local am = self.app.managers[':adventure']
  local pc_speaker = am.pc.speaker

  self.app:yield_delay_s(1)
  pc_speaker:say_and_wait_for_input("using the same attack twice in a fight is lame, so we don't do that.")
  pc_speaker:say_and_wait_for_input("it seems i can't reuse the same reply twice either.")
  pc_speaker:say_and_wait_for_input("i can reuse an attack used by an opponent, though")
  pc_speaker:say_and_wait_for_input("so what's next?")
  self.app:yield_delay_s(1)
end

-- after [key] fights, we show tutorial with sequence method [value]
adventure_state.async_tutorials = {
  [1] = async_tutorial_learn_attacks,
  [2] = async_tutorial_quote_consumption,
  [4] = async_tutorial_reply_power,
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
    pc_speaker:say_and_wait_for_input("i got delayed by your fellow workers.")
    self.app:yield_delay_s(0.5)
    npc_speaker:say_and_wait_for_input("anyway.")
    npc_speaker:say_and_wait_for_input("so, how come an indie event resorts to asking funds to a corporation like mine?")
    self.app:yield_delay_s(0.5)
    pc_speaker:say_and_wait_for_input("...")
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
    dm.current_bottom_text = 'game end'
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
    log("after tutorial, rossmann learned A: "..dump_sequence(gameplay_data.rossmann_lv2_attack_ids))

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
