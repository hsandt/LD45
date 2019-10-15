require("engine/test/bustedhelper")
local fight_manager = require("fight/fight_manager")

local wit_fighter_app = require("application/wit_fighter_app")
local fighter_info = require("content/fighter_info")
local quote_info = require("content/quote_info")
local dialogue_manager = require("dialogue/dialogue_manager")
local fighter_progression = require("progression/fighter_progression")
local gameplay_data = require("resources/gameplay_data")
local visual_data = require("resources/visual_data")
local character = require("story/character")

describe('fight_manager', function ()

  local app
  local fm

  before_each(function ()
    dm = dialogue_manager()
    fm = fight_manager()
    app = wit_fighter_app()
    -- relies on gameapp.register_managers working
    app:register_managers(dm, fm)
  end)

  describe('_init', function ()

    it('should init the fight manager with base constructor as inactive', function ()
      assert.is_false(fm.active)
    end)

    it('should initialize other members', function ()
      assert.are_same({nil, {}, 0},
        {fm.next_opponent, fm.fighters, fm.active_fighter_index})
    end)

  end)

  describe('start', function ()
  end)

  describe('update', function ()
  end)

  describe('render', function ()

    setup(function ()
      stub(fight_manager, "draw_fighters")
      stub(fight_manager, "draw_hud")
    end)

    teardown(function ()
      fight_manager.draw_fighters:revert()
      fight_manager.draw_hud:revert()
    end)

    it('should call draw fighters, hud', function ()
      fm:render()

      local s = assert.spy(fight_manager.draw_fighters)
      s.was_called(1)
      s.was_called_with(match.ref(fm))

      local s = assert.spy(fight_manager.draw_hud)
      s.was_called(1)
      s.was_called_with(match.ref(fm))
    end)

  end)

  describe('get_active_fighter_opponent', function ()

    local fake_fighter1 = {}
    local fake_fighter2 = {}

    setup(function ()
      stub(fight_manager, "get_active_fighter_index_opponent", function (self)
        return 2
      end)
    end)

    teardown(function ()
      fight_manager.get_active_fighter_index_opponent:revert()
    end)

    it('should return the fighter of index returned by get_active_fighter_index_opponent', function ()
      fm.fighters = {fake_fighter1, fake_fighter2}

      assert.are_equal(fake_fighter2, fm:get_active_fighter_opponent())
    end)

  end)

  describe('get_active_fighter_index_opponent', function ()

    it('1 => 2', function ()
      fm.active_fighter_index = 1

      assert.are_equal(2, fm:get_active_fighter_index_opponent())
    end)

    it('2 => 1', function ()
      fm.active_fighter_index = 2

      assert.are_equal(1, fm:get_active_fighter_index_opponent())
    end)

  end)

  describe('give_control_to_next_fighter', function ()

    it('set active fighter index from 1 to 2', function ()
      fm.active_fighter_index = 1
      fm:give_control_to_next_fighter()

      assert.are_equal(2, fm.active_fighter_index)
    end)

    it('set active fighter index from 2 to 1', function ()
      fm.active_fighter_index = 2
      fm:give_control_to_next_fighter()

      assert.are_equal(1, fm.active_fighter_index)
    end)

  end)

  describe('is_active_fighter_attacking', function ()

    describe('(when opponent has no last quote)', function ()

      setup(function ()
        stub(fight_manager, "get_active_fighter_opponent", function (self)
          return {last_quote = nil}
        end)
      end)

      teardown(function ()
        fight_manager.get_active_fighter_opponent:revert()
      end)

      it('should return true', function ()
        assert.is_true(fm:is_active_fighter_attacking())
      end)

    end)

    describe('(when opponent has last quote)', function ()

      setup(function ()
        stub(fight_manager, "get_active_fighter_opponent", function (self)
          return {last_quote = {}}
        end)
      end)

      teardown(function ()
        fight_manager.get_active_fighter_opponent:revert()
      end)

      it('should return false', function ()
        assert.is_false(fm:is_active_fighter_attacking())
      end)

    end)

  end)

  describe('start_fight_with_next_opponent', function ()

    local fake_fighter_prog = {}

    setup(function ()
      stub(fight_manager, "start_fight_with")
    end)

    teardown(function ()
      fight_manager.start_fight_with:revert()
    end)

    it('should call start_fight_with with the next opponent', function ()
      fight_manager.next_opponent = fake_fighter_prog
      fm:start_fight_with_next_opponent()

      local s = assert.spy(fight_manager.start_fight_with)
      s.was_called(1)
      s.was_called_with(match.ref(fm), match.ref(fake_fighter_prog))
    end)

  end)

  describe('start_fight_with', function ()

    local fake_fighter_prog = {}

    setup(function ()
      stub(fight_manager, "load_fighters")
      stub(fight_manager, "request_active_fighter_action")
    end)

    teardown(function ()
      fight_manager.load_fighters:revert()
      fight_manager.request_active_fighter_action:revert()
    end)

    after_each(function ()
      fight_manager.load_fighters:clear()
      fight_manager.request_active_fighter_action:clear()
    end)

    it('should load fighters for pc and opponent', function ()
      fm:start_fight_with(fake_fighter_prog)

      local s = assert.spy(fight_manager.load_fighters)
      s.was_called(1)
      s.was_called_with(match.ref(fm), match.ref(app.game_session.pc_fighter_progression), match.ref(fake_fighter_prog))
    end)

    it('should set active fighter index to opponent (2)', function ()
      fm:start_fight_with(fake_fighter_prog)

      assert.are_equal(2, fm.active_fighter_index)
    end)


    it('should request next fighter action', function ()
      fm:start_fight_with(fake_fighter_prog)

      local s = assert.spy(fight_manager.request_active_fighter_action)
      s.was_called(1)
      s.was_called_with(match.ref(fm))
    end)

  end)

  describe('load_fighters', function ()

    local fake_pc_speaker = {"pc speaker"}
    local fake_npc_speaker = {"npc speaker"}
    local fake_pc_character = {speaker = fake_pc_speaker}
    local fake_npc_character = {speaker = fake_npc_speaker}
    local fake_pc_fighter_prog  = {level = 1}
    local fake_npc_fighter_prog = {level = 2}
    local fake_pc_fighter  = {character = fake_pc_character, fighter_progression = fake_pc_fighter_prog}
    local fake_npc_fighter = {character = fake_npc_character, fighter_progression = fake_npc_fighter_prog}

    setup(function ()
      stub(fight_manager, "generate_pc_fighter", function (fighter_prog)
        -- ignore fighter_prog but it should be fake_pc_fighter_prog
        return fake_pc_fighter
      end)
      stub(fight_manager, "generate_npc_fighter", function (fighter_prog)
        -- ignore fighter_prog but it should be fake_npc_fighter_prog
        return fake_npc_fighter
      end)
      stub(dialogue_manager, "add_speaker")
    end)

    teardown(function ()
      fight_manager.generate_pc_fighter:revert()
      fight_manager.generate_npc_fighter:revert()
      dialogue_manager.add_speaker:revert()
    end)

    after_each(function ()
      fight_manager.generate_pc_fighter:clear()
      fight_manager.generate_npc_fighter:clear()
      dialogue_manager.add_speaker:clear()
    end)

    it('should load fighters for pc and opponent', function ()
      fm:load_fighters(fake_pc_fighter_prog, fake_npc_fighter_prog)

      assert.are_equal(fake_pc_fighter, fm.fighters[1])
      assert.are_equal(fake_npc_fighter, fm.fighters[2])
    end)

    it('should register speakers for pc and npc in dialogue manager', function ()
      fm:load_fighters(fake_pc_fighter_prog, fake_npc_fighter_prog)

      local s = assert.spy(dialogue_manager.add_speaker)
      s.was_called(2)
      s.was_called_with(match.ref(dm), fake_pc_speaker)
      s.was_called_with(match.ref(dm), fake_npc_speaker)
    end)

  end)

  describe('unload_fighters', function ()

    local fake_pc_speaker = {"pc speaker"}
    local fake_npc_speaker = {"npc speaker"}
    local fake_pc_character = {speaker = fake_pc_speaker}
    local fake_npc_character = {speaker = fake_npc_speaker}
    local fake_pc_fighter_prog  = {level = 1}
    local fake_npc_fighter_prog = {level = 2}
    local fake_pc_fighter  = {character = fake_pc_character, fighter_progression = fake_pc_fighter_prog}
    local fake_npc_fighter = {character = fake_npc_character, fighter_progression = fake_npc_fighter_prog}

    setup(function ()
      stub(dialogue_manager, "remove_speaker")
    end)

    teardown(function ()
      dialogue_manager.remove_speaker:revert()
    end)

    before_each(function ()
      fm.fighters = {fake_pc_fighter, fake_npc_fighter}
    end)

    after_each(function ()
      dialogue_manager.remove_speaker:clear()
    end)

    it('should clear fighter table', function ()
      fm:unload_fighters()

      assert.are_equal(0, #fm.fighters)
    end)

    it('should unregister speakers for pc and npc in dialogue manager', function ()
      fm:unload_fighters(fake_pc_fighter_prog, fake_npc_fighter_prog)

      local s = assert.spy(dialogue_manager.remove_speaker)
      s.was_called(2)
      s.was_called_with(match.ref(dm), fake_pc_speaker)
      s.was_called_with(match.ref(dm), fake_npc_speaker)
    end)

  end)

  describe('generate_pc_fighter', function ()

    -- local mock_fighter_info = fighter_info(8, "employee", 4, 5, {11, 27}, {12, 28}, {2, 4})
    -- local mock_fighter_progression = fighter_progression(character_types.ai, mock_fighter_info)
    local mock_pc_fighter_prog  = fighter_progression(character_types.human, fighter_info(99, 99, 12, 8, {}, {}, {}))
    -- local fake_npc_fighter_prog = {level = 2}

    it('should return a pc fighter with pc info', function ()
      local pc_fighter = fight_manager.generate_pc_fighter(mock_pc_fighter_prog)

      assert.are_same(character(gameplay_data.pc_info, horizontal_dirs.right, visual_data.pc_sprite_pos), pc_fighter.character)
      assert.are_equal(mock_pc_fighter_prog, pc_fighter.fighter_progression)
      assert.are_same({mock_pc_fighter_prog.max_hp, nil}, {pc_fighter.hp, pc_fighter.last_quote})
    end)

  end)

  describe('generate_npc_fighter', function ()

    local mock_npc_fighter_prog = fighter_progression(character_types.ai, fighter_info(10, 2, 3, 3, {6, 7}, {}, {}))

    it('should return a npc fighter with pc info', function ()
      local npc_fighter = fight_manager.generate_npc_fighter(mock_npc_fighter_prog)

      assert.are_same(character(gameplay_data.npc_info_s[2], horizontal_dirs.left, visual_data.npc_sprite_pos), npc_fighter.character)
      assert.are_equal(mock_npc_fighter_prog, npc_fighter.fighter_progression)
      assert.are_same({mock_npc_fighter_prog.max_hp, nil}, {npc_fighter.hp, npc_fighter.last_quote})
    end)

  end)

  describe('request_active_fighter_action', function ()

    setup(function ()
      stub(fight_manager, "request_fighter_action")
    end)

    teardown(function ()
      fight_manager.request_fighter_action:revert()
    end)

    after_each(function ()
      fight_manager.request_fighter_action:clear()
    end)

    it('should load fighters for pc and opponent', function ()
      local fake_fighter1 = {}
      local fake_fighter2 = {}
      fm.fighters = {fake_fighter1, fake_fighter2}
      fm.active_fighter_index = 1

      fm:request_active_fighter_action()

      local s = assert.spy(fight_manager.request_fighter_action)
      s.was_called(1)
      s.was_called_with(match.ref(fm), fake_fighter1)
    end)

  end)

  describe('request_fighter_action', function ()

    setup(function ()
      stub(fight_manager, "get_active_fighter_opponent", function (self)
        return mock_fighter
      end)
      stub(fight_manager, "request_human_fighter_action")
      stub(fight_manager, "request_ai_fighter_action")
    end)

    teardown(function ()
      fight_manager.get_active_fighter_opponent:revert()
      fight_manager.request_human_fighter_action:revert()
      fight_manager.request_ai_fighter_action:revert()
    end)

    after_each(function ()
      fight_manager.get_active_fighter_opponent:clear()
      fight_manager.request_human_fighter_action:clear()
      fight_manager.request_ai_fighter_action:clear()
    end)

    it('should request action for human fighter if fighter is human', function ()
      local fake_human_fighter = {character_type = character_types.human}
      fm:request_fighter_action(fake_human_fighter)

      local s = assert.spy(fight_manager.request_human_fighter_action)
      s.was_called(1)
      s.was_called_with(match.ref(fm), fake_human_fighter)
    end)

    it('should request action for ai fighter if fighter is ai', function ()
      local fake_ai_fighter = {character_type = character_types.ai}
      fm:request_fighter_action(fake_ai_fighter)

      local s = assert.spy(fight_manager.request_ai_fighter_action)
      s.was_called(1)
      s.was_called_with(match.ref(fm), fake_ai_fighter)
    end)

  end)

  describe('request_human_fighter_action', function ()

      -- set character_type just to pass the assertions
    local fake_fighter = {character_type = character_types.human}
    local fake_attack_items = {"attack"}
    local fake_reply_items = {"reply"}

    setup(function ()
      stub(fight_manager, "is_active_fighter_attacking", function (self)
        return true
      end)
      stub(fight_manager, "generate_quote_menu_items", function (self, fighter, quote_type)
        if quote_type == quote_types.attack then
          return fake_attack_items
        else
          return fake_reply_items
        end
      end)
      stub(fight_manager, "prompt_items")
    end)

    teardown(function ()
      fight_manager.is_active_fighter_attacking:revert()
      fight_manager.generate_quote_menu_items:revert()
      fight_manager.prompt_items:revert()
    end)

    before_each(function ()
      -- just to pass the assertions
      fm.active_fighter_index = 1
      fm.fighters = {fake_fighter}
    end)

    after_each(function ()
      fight_manager.is_active_fighter_attacking:clear()
      fight_manager.generate_quote_menu_items:clear()
      fight_manager.prompt_items:clear()
    end)

    describe('(when active fighter is attacking)', function ()

      setup(function ()
        stub(fight_manager, "is_active_fighter_attacking", function (self)
          return true
        end)
      end)

      teardown(function ()
        fight_manager.is_active_fighter_attacking:revert()
      end)

      it('should prompt generated attack items', function ()
        fm:request_human_fighter_action(fake_fighter)

        local s = assert.spy(fight_manager.prompt_items)
        s.was_called(1)
        s.was_called_with(match.ref(fm), match.ref(fake_attack_items))
      end)

    end)

    describe('(when active fighter is not attacking)', function ()

      setup(function ()
        stub(fight_manager, "is_active_fighter_attacking", function (self)
          return false
        end)
      end)

      teardown(function ()
        fight_manager.is_active_fighter_attacking:revert()
      end)

      it('should prompt generated attack items', function ()
        fm:request_human_fighter_action(fake_fighter)

        local s = assert.spy(fight_manager.prompt_items)
        s.was_called(1)
        s.was_called_with(match.ref(fm), match.ref(fake_reply_items))
      end)

    end)

  end)

  describe('generate_quote_menu_items', function ()

    -- todo

  end)

  describe('request_ai_fighter_action', function ()

    -- todo

  end)

  describe('start_wait_and_say_quote', function ()

    -- todo

  end)

  describe('wait_and_say_quote', function ()

    -- todo, but rather as itest since async function

  end)

  describe('say_quote', function ()

    -- todo

  end)

  -- local mock_character_info = character_info(2, "employee", 5)
  -- local pos = vector(20, 60)
  -- local mock_character = character(mock_character_info, horizontal_dirs.right, pos)
  -- local mock_fighter_info = fighter_info(8, "employee", 4, 5, {11, 27}, {12, 28}, {2, 4})

  -- local mock_fighter_progression
  -- local mock_fighter

  -- before_each(function ()
  --   mock_fighter_progression = fighter_progression(character_types.ai, mock_fighter_info)
  --   add(mock_fighter_progression.known_attack_ids, 35)
  --   add(mock_fighter_progression.known_reply_ids, 37)
  --   mock_fighter = fighter(mock_character, mock_fighter_progression)
  -- end)

  describe('draw_fighters', function ()

    local mock_fighter_info = fighter_info(7, "employee", 4, {11, 27})

    it('should not error', function ()
      assert.has_no_errors(function ()
        fm:draw_fighters()
      end)
    end)

    it('should not error with npc info set', function ()
      fm.fighter_info = mock_fighter_info

      assert.has_no_errors(function ()
        fm:draw_fighters()
      end)
    end)

  end)

  describe('draw_hud', function ()

    it('should not error', function ()
      assert.has_no_errors(function ()
        fm:draw_hud()
      end)
    end)

  end)

  describe('draw_floor_number', function ()

    it('should not error', function ()
      assert.has_no_errors(function ()
        fm:draw_floor_number()
      end)
    end)

  end)

  describe('draw_health_bars', function ()

    it('should not error', function ()
      assert.has_no_errors(function ()
        fm:draw_health_bars()
      end)
    end)

  end)

  describe('draw_npc_label', function ()

    local mock_fighter_info = fighter_info(7, "employee", 4, {11, 27})

    it('should not error', function ()
      assert.has_no_errors(function ()
        fm:draw_npc_label()
      end)
    end)

    it('should not error with npc info set', function ()
      fm.fighter_info = mock_fighter_info

      assert.has_no_errors(function ()
        fm:draw_npc_label()
      end)
    end)

  end)

end)
