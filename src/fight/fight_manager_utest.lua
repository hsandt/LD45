require("engine/test/bustedhelper")
local fight_manager = require("fight/fight_manager")

local manager = require("engine/application/manager")

local wit_fighter_app = require("application/wit_fighter_app")
local character_info = require("content/character_info")
local fighter_info = require("content/fighter_info")
local floor_info = require("content/floor_info")
local quote_info = require("content/quote_info")
local dialogue_manager = require("dialogue/dialogue_manager")
local fighter = require("fight/fighter")
local fighter_progression = require("progression/fighter_progression")
local game_session = require("progression/game_session")
local gameplay_data = require("resources/gameplay_data")
local visual_data = require("resources/visual_data")
local character = require("story/character")

describe('fight_manager', function ()

  describe('static members', function ()

    it('type is :fight', function ()
      assert.are_equal(':fight', fight_manager.type)
    end)

    it('initially_active is false', function ()
      assert.is_false(fight_manager.initially_active)
    end)

  end)

  describe('_init', function ()

    setup(function ()
      spy.on(manager, "_init")
    end)

    teardown(function ()
      manager._init:revert()
    end)

    after_each(function ()
      manager._init:clear()
    end)

    it('should call base constructor', function ()
      local fm = fight_manager()

      local s = assert.spy(manager._init)
      s.was_called(1)
      s.was_called_with(match.ref(fm))
    end)

    it('should initialize other members', function ()
      local fm = fight_manager()

      assert.are_same({nil, {}, 0, nil},
        {fm.next_opponent, fm.fighters, fm.active_fighter_index, fm.won_last_fight})
    end)

  end)

  describe('(with instance)', function ()

    local app
    local fm
    local dm

    before_each(function ()
      app = wit_fighter_app()
      app:instantiate_and_register_managers()
      fm = app.managers[':fight']
      dm = app.managers[':dialogue']
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

    describe('pick_matching_random_npc_fighter_prog', function ()

      local fake_npc_fighter_prog = {}

      setup(function ()
        stub(fight_manager, "get_all_candidate_npc_fighter_prog", function (self, floor_number)
          if floor_number == 3 then
            return {{}, {}, fake_npc_fighter_prog}
          else
            return {{}}
          end
        end)
        stub(_G, "random_int_range_exc", function (range)
          return range - 1
        end)
      end)

      teardown(function ()
        fight_manager.get_all_candidate_npc_fighter_prog:revert()
        random_int_range_exc:revert()
      end)

      it('should pick a random npc info among the possible npc levels at the current floor', function ()
        app.game_session.floor_number = 3
        assert.are_equal(fake_npc_fighter_prog, fm:pick_matching_random_npc_fighter_prog())
      end)

    end)

    describe('get_all_candidate_npc_fighter_prog', function ()

      setup(function ()
        stub(gameplay_data, "get_floor_info", function (self, floor_number)
          -- hypothetical npc levels related to floor number
          return floor_info(floor_number, floor_number - 1, floor_number + 1)
        end)
        stub(game_session, "get_all_npc_fighter_progressions_with_level", function (self, level)
          -- we are going to return different npcs with the same ids, but we don't care about ids in this test anyway
          local fake_npc_fighter_prog1 = {level = level}
          local fake_npc_fighter_prog2 = {level = level}
          local fake_npc_fighter_prog3 = {level = level}
          return {fake_npc_fighter_prog1, fake_npc_fighter_prog2, fake_npc_fighter_prog3}
        end)
      end)

      teardown(function ()
        gameplay_data.get_floor_info:revert()
        game_session.get_all_npc_fighter_progressions_with_level:revert()
      end)

      it('should pick a random npc info among the possible npc levels at the current floor', function ()
        -- we pass floor number of 3, so npc levels should be 2 to 4
        -- we don't go into details but we should have 3 * 3 mock npc infos now, spread on 3 levels
        -- we just check that we have 9 of them
        assert.are_equal(9, #fm:get_all_candidate_npc_fighter_prog(3))
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

      after_each(function ()
        fight_manager.start_fight_with:clear()
      end)

      it('should call start_fight_with with the next opponent', function ()
        fm.next_opponent = fake_fighter_prog
        fm:start_fight_with_next_opponent()

        local s = assert.spy(fight_manager.start_fight_with)
        s.was_called(1)
        s.was_called_with(match.ref(fm), match.ref(fake_fighter_prog))
      end)

    end)

    describe('start_fight_with', function ()

      local mock_npc_fighter_prog = fighter_progression(character_types.ai, fighter_info(10, 2, 3, 3, {6, 7}, {}, {}))

      setup(function ()
        stub(fight_manager, "spawn_fighters")
        stub(fight_manager, "request_active_fighter_action")
      end)

      teardown(function ()
        fight_manager.spawn_fighters:revert()
        fight_manager.request_active_fighter_action:revert()
      end)

      after_each(function ()
        fight_manager.spawn_fighters:clear()
        fight_manager.request_active_fighter_action:clear()
      end)

      it('should load fighters for pc and opponent', function ()
        fm:start_fight_with(mock_npc_fighter_prog)

        local s = assert.spy(fight_manager.spawn_fighters)
        s.was_called(1)
        s.was_called_with(match.ref(fm), match.ref(app.game_session.pc_fighter_progression), match.ref(mock_npc_fighter_prog))
      end)

      it('should set active fighter index to opponent (2)', function ()
        fm:start_fight_with(mock_npc_fighter_prog)

        assert.are_equal(2, fm.active_fighter_index)
      end)


      it('should request next fighter action', function ()
        fm:start_fight_with(mock_npc_fighter_prog)

        local s = assert.spy(fight_manager.request_active_fighter_action)
        s.was_called(1)
        s.was_called_with(match.ref(fm))
      end)

    end)

    describe('stop_fight', function ()

      -- todo

    end)

    describe('spawn_fighters', function ()

      local mock_pc_character_info = character_info(0, "pc", 0)
      local mock_pc_fighter_info = fighter_info(99, 99, 12, 8, {}, {}, {})
      local mock_pc_fighter_prog = fighter_progression(character_types.human, mock_pc_fighter_info)
      local fake_pc_speaker = {"pc speaker"}
      local fake_pc_character = {character_info = mock_pc_character_info, speaker = fake_pc_speaker}

      local mock_npc_character_info = character_info(7, "npc", 7)
      local mock_npc_fighter_info = fighter_info(8, 8, 4, 5, {11, 27}, {12, 28}, {2, 4})
      local mock_npc_fighter_prog = fighter_progression(character_types.ai, mock_npc_fighter_info)
      local fake_npc_speaker = {"npc speaker"}
      local fake_npc_character = {character_info = mock_npc_character_info, speaker = fake_npc_speaker}

      local mock_pc_fighter  = fighter(fake_pc_character, mock_pc_fighter_prog)
      local mock_npc_fighter = fighter(fake_npc_character, mock_npc_fighter_prog)

      setup(function ()
        stub(fight_manager, "generate_pc_fighter", function (self, fighter_prog)
          -- ignore fighter_prog but it should be mock_pc_fighter_prog
          return mock_pc_fighter
        end)
        stub(fight_manager, "generate_npc_fighter", function (self, fighter_prog)
          -- ignore fighter_prog but it should be mock_npc_fighter_prog
          return mock_npc_fighter
        end)
      end)

      teardown(function ()
        fight_manager.generate_pc_fighter:revert()
        fight_manager.generate_npc_fighter:revert()
      end)

      after_each(function ()
        fight_manager.generate_pc_fighter:clear()
        fight_manager.generate_npc_fighter:clear()
      end)

      it('should spawn fighters for pc and opponent', function ()
        fm:spawn_fighters(mock_pc_fighter_prog, mock_npc_fighter_prog)

        -- spy of intermediate functions is not necessary if we check the final result
        --   but useful here to check self/arguments are correct, as we don't use them
        --   in the stubs
        local s = assert.spy(fight_manager.generate_pc_fighter)
        s.was_called(1)
        s.was_called_with(match.ref(fm), mock_pc_fighter_prog)

        s = assert.spy(fight_manager.generate_npc_fighter)
        s.was_called(1)
        s.was_called_with(match.ref(fm), mock_npc_fighter_prog)

        assert.are_equal(mock_pc_fighter, fm.fighters[1])
        assert.are_equal(mock_npc_fighter, fm.fighters[2])
      end)

    end)

    describe('despawn_fighters', function ()

      local fake_pc_speaker = {"pc speaker"}
      local fake_npc_speaker = {"npc speaker"}
      local fake_pc_character = {speaker = fake_pc_speaker, unregister_speaker = spy.new()}
      local fake_npc_character = {speaker = fake_npc_speaker, unregister_speaker = spy.new()}
      local fake_pc_fighter_prog  = {level = 1}
      local fake_npc_fighter_prog = {level = 2}
      local fake_pc_fighter  = {character = fake_pc_character, fighter_progression = fake_pc_fighter_prog}
      local fake_npc_fighter = {character = fake_npc_character, fighter_progression = fake_npc_fighter_prog}

      setup(function ()
        stub(fake_pc_character, "unregister_speaker")
        stub(fake_npc_character, "unregister_speaker")
      end)

      teardown(function ()
        fake_pc_character.unregister_speaker:revert()
        fake_npc_character.unregister_speaker:revert()
      end)

      before_each(function ()
        fm.fighters = {fake_pc_fighter, fake_npc_fighter}
      end)

      after_each(function ()
        fake_pc_character.unregister_speaker:clear()
        fake_npc_character.unregister_speaker:clear()
      end)

      it('should clear fighter table', function ()
        fm:despawn_fighters()

        assert.are_equal(0, #fm.fighters)
      end)

      it('should unregister speakers for pc and npc in dialogue manager', function ()
        fm:despawn_fighters(fake_pc_fighter_prog, fake_npc_fighter_prog)

        local s = assert.spy(fake_pc_character.unregister_speaker)
        s.was_called(1)
        s.was_called_with(fake_pc_character, match.ref(dm))

        local s = assert.spy(fake_npc_character.unregister_speaker)
        s.was_called(1)
        s.was_called_with(fake_npc_character, match.ref(dm))
      end)

    end)

    describe('(stub register_speaker)', function ()

      setup(function ()
        stub(character, "register_speaker")
      end)

      teardown(function ()
        character.register_speaker:revert()
      end)

      after_each(function ()
        character.register_speaker:clear()
      end)

      describe('generate_pc_fighter', function ()

        local mock_pc_fighter_prog = fighter_progression(character_types.human, fighter_info(99, 99, 12, 8, {}, {}, {}))

        it('should return a pc fighter with pc info', function ()
          local pc_fighter = fm:generate_pc_fighter(mock_pc_fighter_prog)

          assert.are_same(character(gameplay_data.pc_info, horizontal_dirs.right, visual_data.pc_sprite_pos), pc_fighter.character)
          assert.are_equal(mock_pc_fighter_prog, pc_fighter.fighter_progression)
          assert.are_same({mock_pc_fighter_prog.max_hp, nil}, {pc_fighter.hp, pc_fighter.last_quote})

        end)

        it('should register speaker for the created pc', function ()
          local pc_fighter = fm:generate_pc_fighter(mock_pc_fighter_prog)

          local s = assert.spy(character.register_speaker)
          s.was_called(1)
          s.was_called_with(match.ref(pc_fighter.character), match.ref(dm))
        end)

      end)

      describe('generate_npc_fighter', function ()

        local mock_npc_fighter_prog = fighter_progression(character_types.ai, fighter_info(10, 2, 3, 3, {6, 7}, {}, {}))

        it('should return a npc fighter with pc info', function ()
          local npc_fighter = fm:generate_npc_fighter(mock_npc_fighter_prog)

          assert.are_same(character(gameplay_data.npc_info_s[2], horizontal_dirs.left, visual_data.npc_sprite_pos), npc_fighter.character)
          assert.are_equal(mock_npc_fighter_prog, npc_fighter.fighter_progression)
          assert.are_same({mock_npc_fighter_prog.max_hp, nil}, {npc_fighter.hp, npc_fighter.last_quote})
        end)

        it('should register speaker for the created npc', function ()
          local npc_fighter = fm:generate_npc_fighter(mock_npc_fighter_prog)

          local s = assert.spy(character.register_speaker)
          s.was_called(1)
          s.was_called_with(match.ref(npc_fighter.character), match.ref(dm))
        end)

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
        local fake_human_fighter = {fighter_progression = {character_type = character_types.human}}
        fm:request_fighter_action(fake_human_fighter)

        local s = assert.spy(fight_manager.request_human_fighter_action)
        s.was_called(1)
        s.was_called_with(match.ref(fm), fake_human_fighter)
      end)

      it('should request action for ai fighter if fighter is ai', function ()
        local fake_ai_fighter = {fighter_progression = {character_type = character_types.ai}}
        fm:request_fighter_action(fake_ai_fighter)

        local s = assert.spy(fight_manager.request_ai_fighter_action)
        s.was_called(1)
        s.was_called_with(match.ref(fm), fake_ai_fighter)
      end)

    end)

    describe('request_human_fighter_action', function ()

      -- just put dummy info so we can get a proper fighter and stub fighter methods
      -- it's not necessary to have a real fighter, we could also just make a table
      --   but would have to stub in before_each (not setup) on the specific mock table
      --   rather than the fighter class
      local mock_human_fighter_info = fighter_info(0, 0, 1, 3, {}, {}, {})

      local mock_human_fighter_progression
      local mock_human_fighter

        -- set character_type just to pass the assertions
      local fake_attack_items = {"attack1", "attack2", "attack3"}
      local fake_reply_items = {[-1] = "dummy reply", [0] = "cancel reply", "reply1"}

      setup(function ()
        stub(fight_manager, "is_active_fighter_attacking", function (self)
          return true
        end)
        stub(fight_manager, "generate_quote_menu_items", function (self, human_fighter, quote_type, available_quote_ids)
          -- ignore human_fighter here, normally it's used to define the menu item callbacks
          local fake_menu_items = {}
          if quote_type == quote_types.attack then
            for quote_id in all(available_quote_ids) do
              add(fake_menu_items, fake_attack_items[quote_id])
            end
          else
            for quote_id in all(available_quote_ids) do
              add(fake_menu_items, fake_reply_items[quote_id])
            end
          end
          return fake_menu_items
        end)
        stub(dialogue_manager, "prompt_items")
      end)

      teardown(function ()
        fight_manager.is_active_fighter_attacking:revert()
        fight_manager.generate_quote_menu_items:revert()
        dialogue_manager.prompt_items:revert()
      end)

      before_each(function ()
        mock_human_fighter_progression = fighter_progression(character_types.human, mock_human_fighter_info)
        mock_human_fighter = fighter(mock_character, mock_human_fighter_progression)

        -- just to pass the assertions
        fm.active_fighter_index = 1
        fm.fighters = {mock_human_fighter}
      end)

      after_each(function ()
        fight_manager.is_active_fighter_attacking:clear()
        fight_manager.generate_quote_menu_items:clear()
        dialogue_manager.prompt_items:clear()
      end)

      describe('(when active fighter is attacking)', function ()

        setup(function ()
          stub(fight_manager, "is_active_fighter_attacking", function (self)
            return true
          end)
          stub(fight_manager, "request_next_fighter_action")
        end)

        teardown(function ()
          fight_manager.is_active_fighter_attacking:revert()
          fight_manager.request_next_fighter_action:revert()
        end)

        after_each(function ()
          fight_manager.is_active_fighter_attacking:clear()
          fight_manager.request_next_fighter_action:clear()
        end)

        describe('(when no attacks left)', function ()

          setup(function ()
            stub(fighter, "get_available_quote_ids", function (self, quote_type)
              -- we assume quote_type == quote_types.attack here
              return {}
            end)
          end)

          teardown(function ()
            fighter.get_available_quote_ids:revert()
          end)

          it('should not prompt at all and skip to opponent\'s turn', function ()
            fm:request_human_fighter_action(mock_human_fighter)

            local s = assert.spy(fight_manager.request_next_fighter_action)
            s.was_called(1)
            s.was_called_with(match.ref(fm))

            assert.spy(dialogue_manager.prompt_items).was_not_called()
          end)

        end)

        describe('(when some attacks left)', function ()

          setup(function ()
            stub(fighter, "get_available_quote_ids", function (self, quote_type)
              -- we assume quote_type == quote_types.attack here
              return {1, 2}
            end)
          end)

          teardown(function ()
            fighter.get_available_quote_ids:revert()
          end)

          it('should prompt generated attack items', function ()
            fm:request_human_fighter_action(mock_human_fighter)

            assert.spy(fight_manager.request_next_fighter_action).was_not_called()

            local s = assert.spy(dialogue_manager.prompt_items)
            s.was_called(1)
            s.was_called_with(match.ref(dm), {"attack1", "attack2"})
          end)

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

        describe('(when no replies left)', function ()

          setup(function ()
            stub(fighter, "get_available_quote_ids", function (self, quote_type)
              -- we assume quote_type == quote_types.reply here
              return {}
            end)
            stub(fight_manager, "request_next_fighter_action")
          end)

          teardown(function ()
            fighter.get_available_quote_ids:revert()
          end)

          it('should still prompt with a dummy reply', function ()
            fm:request_human_fighter_action(mock_human_fighter)

            local s = assert.spy(dialogue_manager.prompt_items)
            s.was_called(1)
            s.was_called_with(match.ref(dm), {"dummy reply"})
          end)

        end)

        describe('(when some replies left)', function ()

          setup(function ()
            stub(fighter, "get_available_quote_ids", function (self, quote_type)
              -- we assume quote_type == quote_types.reply here
              return {0, 1}
            end)
            stub(fight_manager, "request_next_fighter_action")
          end)

          teardown(function ()
            fighter.get_available_quote_ids:revert()
          end)

          it('should still prompt with a dummy reply', function ()
            fm:request_human_fighter_action(mock_human_fighter)

            local s = assert.spy(dialogue_manager.prompt_items)
            s.was_called(1)
            s.was_called_with(match.ref(dm), {"cancel reply", "reply1"})
          end)

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

    describe('say_quote', function ()

      -- todo

    end)

    describe('request_next_fighter_action', function ()

      -- todo

    end)

    describe('resolve_losing_attack', function ()

      -- todo

    end)

    describe('resolve_exchange', function ()

      -- todo

    end)

    describe('check_exchange_result', function ()

      -- todo

    end)

    describe('clear_exchange', function ()

      -- todo

    end)

    describe('hit_fighter', function ()

      -- todo

    end)

    describe('start_victory', function ()

      -- todo

    end)

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

  end)  -- (with instance)

end)
