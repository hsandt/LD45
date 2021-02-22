require("test/bustedhelper_game")
local fight_manager = require("fight/fight_manager")

local manager = require("engine/application/manager")
local animated_sprite = require("engine/render/animated_sprite")

local wit_fighter_app = require("application/wit_fighter_app")
local character_info = require("content/character_info")
local fighter_info = require("content/fighter_info")
local quote_info = require("content/quote_info")
local dialogue_manager = require("dialogue/dialogue_manager")
local fighter = require("fight/fighter")
local fighter_progression = require("progression/fighter_progression")
local game_session = require("progression/game_session")
local audio_data = require("resources/audio_data")
local gameplay_data = require("resources/gameplay_data")
local visual_data = require("resources/visual_data")
local adventure_manager = require("story/adventure_manager")
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

  describe('init', function ()

    setup(function ()
      spy.on(manager, "init")
    end)

    teardown(function ()
      manager.init:revert()
    end)

    after_each(function ()
      manager.init:clear()
    end)

    it('should call base constructor', function ()
      local fm = fight_manager()

      local s = assert.spy(manager.init)
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
    local am
    local fm
    local dm

    before_each(function ()
      app = wit_fighter_app()
      app:instantiate_and_register_managers()
      am = app.managers[':adventure']
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
        stub(animated_sprite, "render")
        stub(fight_manager, "draw_hud")
      end)

      teardown(function ()
        fight_manager.draw_fighters:revert()
        animated_sprite.render:revert()
        fight_manager.draw_hud:revert()
      end)

      it('should call draw fighters, hud', function ()
        fm.hit_fx_pos = vector(10, 10)

        fm:render()

        s = assert.spy(animated_sprite.render)
        s.was_called(1)
        s.was_called_with(match.ref(fm.hit_fx), vector(10, 10))

        s = assert.spy(fight_manager.draw_hud)
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

      local fake_fighter1
      local fake_fighter2

      before_each(function ()
        fake_fighter1 = {has_just_skipped = false}
        fake_fighter2 = {has_just_skipped = false}
        fm.fighters = {fake_fighter1, fake_fighter2}
      end)

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

      it('clear has_just_skipped flag on the new active fighter', function ()
        fm.active_fighter_index = 2
        fake_fighter1.has_just_skipped = true

        fm:give_control_to_next_fighter()

        assert.is_false(fake_fighter1.has_just_skipped)
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
        stub(game_session, "get_all_candidate_npc_fighter_prog", function (self)
          if self.floor_number == 3 then
            return {{}, {}, fake_npc_fighter_prog}
          else
            return {}
          end
        end)
        stub(_G, "random_int_range_exc", function (range)
          return range - 1
        end)
      end)

      teardown(function ()
        game_session.get_all_candidate_npc_fighter_prog:revert()
        random_int_range_exc:revert()
      end)

      it('should pick a random npc info among the possible npc levels at the current floor', function ()
        app.game_session.floor_number = 3
        assert.are_equal(fake_npc_fighter_prog, fm:pick_matching_random_npc_fighter_prog())
      end)

      it('should assert if no candidate npc found at the current floor', function ()
        app.game_session.floor_number = 4
        assert.has_error(function ()
          fm:pick_matching_random_npc_fighter_prog()
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

      local mock_npc_fighter_prog = fighter_progression(character_types.npc, fighter_info(10, 2, 3, 3, {6, 7}, {}, {}))

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

      describe('(stubbing music)', function ()

        setup(function ()
          stub(_G, "music")
        end)

        teardown(function ()
          music:revert()
        end)

        after_each(function ()
          music:clear()
        end)

        describe('on_selection_changed', function ()

          it('should play fight normal bgm', function ()
            fm:start_fight_with(mock_npc_fighter_prog)

            local s = assert.spy(music)
            s.was_called(1)
            s.was_called_with(audio_data.bgm.fight_normal)
          end)

        end)

      end)

    end)

    describe('stop_fight', function ()

      -- todo

    end)

    describe('(mock pc and npc info/character/fighter/prog)', function ()

      local mock_pc_character_info = character_info(0, "pc", 0)
      local mock_pc_fighter_info = fighter_info(0, 0, 1, 2, {}, {}, {})

      -- depends slightly on visual data: spriteindex must not be greater than number of sprites
      local mock_npc_character_info = character_info(3, "npc", 3)
      local mock_npc_fighter_info = fighter_info(3, 3, 4, 5, {11, 27}, {12, 28})

      local mock_pc_character
      local mock_npc_character
      local mock_pc_fighter_prog
      local mock_npc_fighter_prog
      local mock_pc_fighter
      local mock_npc_fighter

      before_each(function ()
        mock_pc_character = character(mock_pc_character_info, horizontal_dirs.right, visual_data.pc_sprite_pos)
        mock_pc_fighter_prog = fighter_progression(character_types.pc, mock_pc_fighter_info)
        mock_pc_fighter = fighter(mock_pc_character, mock_pc_fighter_prog)

        mock_npc_character = character(mock_npc_character_info, horizontal_dirs.left, visual_data.npc_sprite_pos)
        mock_npc_fighter_prog = fighter_progression(character_types.npc, mock_npc_fighter_info)
        mock_npc_fighter = fighter(mock_npc_character, mock_pc_fighter_prog)
      end)

      describe('spawn_fighters', function ()

        setup(function ()
          stub(fight_manager, "generate_pc_fighter", function (self, fighter_prog)
            -- ignore fighter_prog but it should be mock_pc_fighter_prog
            return mock_pc_fighter
          end)
          stub(fight_manager, "generate_npc_fighter", function (self, fighter_prog)
            -- ignore fighter_prog but it should be mock_npc_fighter_prog
            return mock_npc_fighter
          end)
          stub(character, "register_speaker")
        end)

        teardown(function ()
          fight_manager.generate_pc_fighter:revert()
          fight_manager.generate_npc_fighter:revert()
          character.register_speaker:revert()
        end)

        after_each(function ()
          fight_manager.generate_pc_fighter:clear()
          fight_manager.generate_npc_fighter:clear()
          character.register_speaker:clear()
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

      describe('generate_pc_fighter', function ()

        describe('(adventure manager has not spawned pc)', function ()

          setup(function ()
            stub(adventure_manager, "spawn_pc", function (self)
              self.pc = mock_pc_character
              -- no need to simulate register speaker
            end)
          end)

          teardown(function ()
            adventure_manager.spawn_pc:revert()
          end)

          it('should let adventure manager create pc and return a pc fighter with pc info', function ()
            local pc_fighter = fm:generate_pc_fighter(mock_pc_fighter_prog)

            -- we don't check that spawn_pc has been called
            -- instead, we just check that the result is the same as
            --   when adventure manager already created the mock character

            assert.are_equal(mock_pc_character, pc_fighter.character)
            assert.are_equal(mock_pc_fighter_prog, pc_fighter.fighter_progression)
          end)

        end)

        describe('(adventure manager already spawned pc)', function ()

          before_each(function ()
            am.pc = mock_pc_character
          end)

          it('should return a pc fighter with pc info', function ()
            local pc_fighter = fm:generate_pc_fighter(mock_pc_fighter_prog)

            assert.are_equal(mock_pc_character, pc_fighter.character)
            assert.are_equal(mock_pc_fighter_prog, pc_fighter.fighter_progression)
          end)

        end)

      end)

      describe('generate_npc_fighter', function ()

        describe('(adventure manager has not spawned npc)', function ()

          setup(function ()
            stub(adventure_manager, "spawn_npc", function (self, npc_id)
              -- we got only one mock npc, id = 7, so we don't check npc_id
              --   and just assume it is 7 here
              self.npc = mock_npc_character
              -- no need to simulate register speaker
            end)
          end)

          teardown(function ()
            adventure_manager.spawn_npc:revert()
          end)

          it('should let adventure manager create pc and return a pc fighter with pc info', function ()
            local npc_fighter = fm:generate_npc_fighter(mock_npc_fighter_prog)

            -- we don't check that spawn_npc has been called
            -- instead, we just check that the result is the same as
            --   when adventure manager already created the mock character

            assert.are_equal(mock_npc_character, npc_fighter.character)
            assert.are_equal(mock_npc_fighter_prog, npc_fighter.fighter_progression)
          end)

        end)

        describe('(adventure manager already spawned npc)', function ()

          before_each(function ()
            am.npc = mock_npc_character
          end)

          it('should return a npc fighter with pc info', function ()
            local npc_fighter = fm:generate_npc_fighter(mock_npc_fighter_prog)

            assert.are_equal(mock_npc_character, npc_fighter.character)
            assert.are_equal(mock_npc_fighter_prog, npc_fighter.fighter_progression)
          end)

        end)

      end)

      describe('despawn_fighters', function ()

        setup(function ()
          stub(character, "unregister_speaker")
        end)

        teardown(function ()
          character.unregister_speaker:revert()
        end)

        before_each(function ()
          fm.fighters = {mock_pc_fighter, mock_npc_fighter}
        end)

        after_each(function ()
          character.unregister_speaker:clear()
        end)

        it('should clear fighter table', function ()
          fm:despawn_fighters()

          assert.are_equal(0, #fm.fighters)
        end)

      end)

    end)  -- (mock pc and npc info/character/fighter/prog)

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
        stub(fight_manager, "request_human_fighter_action")
        stub(fight_manager, "request_ai_fighter_action")
      end)

      teardown(function ()
        fight_manager.request_human_fighter_action:revert()
        fight_manager.request_ai_fighter_action:revert()
      end)

      after_each(function ()
        fight_manager.request_human_fighter_action:clear()
        fight_manager.request_ai_fighter_action:clear()
      end)

      it('should request action for human fighter if fighter is human', function ()
        local fake_human_fighter = {fighter_progression = {character_type = character_types.pc}}
        fm:request_fighter_action(fake_human_fighter)

        local s = assert.spy(fight_manager.request_human_fighter_action)
        s.was_called(1)
        s.was_called_with(match.ref(fm), fake_human_fighter)
      end)

      it('should request action for ai fighter if fighter is ai', function ()
        local fake_ai_fighter = {fighter_progression = {character_type = character_types.npc}}
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
      local mock_pc_character_info = character_info(0, "pc", 0)
      local mock_pc_fighter_info = fighter_info(0, 0, 1, 3, {}, {}, {})

      local mock_npc_character_info = character_info(3, "npc", 3)
      local mock_npc_fighter_info = fighter_info(3, 3, 4, 5, {11, 27}, {12, 28})

      local mock_pc_character
      local mock_npc_character
      local mock_pc_fighter_prog
      local mock_npc_fighter_prog
      local mock_pc_fighter
      local mock_npc_fighter

        -- set character_type just to pass the assertions
      local fake_attack_items = {[-1] = "skip", "attack1", "attack2", "attack3"}
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

        stub(fight_manager, "auto_pick_quote", function (self, fighter, quote_type)
          if quote_type == quote_types.attack then
            return fake_attack_items[2]
          else
            return fake_reply_items[1]
          end
        end)
        stub(fight_manager, "wait_and_do")
      end)

      teardown(function ()
        fight_manager.is_active_fighter_attacking:revert()
        fight_manager.generate_quote_menu_items:revert()
        dialogue_manager.prompt_items:revert()

        fight_manager.auto_pick_quote:revert()
        fight_manager.wait_and_do:revert()
      end)

      before_each(function ()
        -- mock character doesn't exist

        mock_pc_character = character(mock_pc_character_info, horizontal_dirs.right, visual_data.pc_sprite_pos)
        mock_pc_fighter_prog = fighter_progression(character_types.pc, mock_pc_fighter_info)
        mock_pc_fighter = fighter(mock_pc_character, mock_pc_fighter_prog)

        mock_npc_character = character(mock_npc_character_info, horizontal_dirs.left, visual_data.npc_sprite_pos)
        mock_npc_fighter_prog = fighter_progression(character_types.npc, mock_npc_fighter_info)
        mock_npc_fighter = fighter(mock_npc_character, mock_npc_fighter_prog)

        -- just to pass the assertions
        fm.active_fighter_index = 1
        fm.fighters = {mock_pc_fighter, mock_npc_fighter}
      end)

      after_each(function ()
        fight_manager.is_active_fighter_attacking:clear()
        fight_manager.generate_quote_menu_items:clear()
        dialogue_manager.prompt_items:clear()

        fight_manager.auto_pick_quote:clear()
        fight_manager.wait_and_do:clear()
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

          it('should still prompt with skip attack', function ()
            fm:request_human_fighter_action(mock_pc_fighter)

            local s = assert.spy(dialogue_manager.prompt_items)
            s.was_called(1)
            s.was_called_with(match.ref(dm), {"skip"})
          end)


          it('should still prompt with skip attack (even when opponent has just skipped)', function ()
            mock_npc_fighter.has_just_skipped = true
            fm:request_human_fighter_action(mock_pc_fighter)

            local s = assert.spy(dialogue_manager.prompt_items)
            s.was_called(1)
            s.was_called_with(match.ref(dm), {"skip"})
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

          it('should prompt generated attack items with skip', function ()
            fm:request_human_fighter_action(mock_pc_fighter)

            assert.spy(fight_manager.request_next_fighter_action).was_not_called()

            local s = assert.spy(dialogue_manager.prompt_items)
            s.was_called(1)
            s.was_called_with(match.ref(dm), {"attack1", "attack2", "skip"})
          end)

          it('(when opponent thas just skipped) should prompt generated attack items without skip', function ()
            mock_npc_fighter.has_just_skipped = true
            fm:request_human_fighter_action(mock_pc_fighter)

            assert.spy(fight_manager.request_next_fighter_action).was_not_called()

            local s = assert.spy(dialogue_manager.prompt_items)
            s.was_called(1)
            s.was_called_with(match.ref(dm), {"attack1", "attack2"})
          end)

          describe('(when under ai control', function ()

            before_each(function ()
              mock_pc_fighter.fighter_progression.control_type = control_types.ai
            end)

            it('should prompt generated attack items', function ()
              fm:request_human_fighter_action(mock_pc_fighter)

              assert.spy(fight_manager.request_next_fighter_action).was_not_called()

              local s = assert.spy(dialogue_manager.prompt_items)
              s.was_not_called()

              local s = assert.spy(fight_manager.wait_and_do)
              s.was_called(1)
              s.was_called_with(match.ref(fm), visual_data.ai_say_quote_delay, fight_manager.say_quote,
                fm, mock_pc_fighter, fake_attack_items[2])
            end)

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
          end)

          teardown(function ()
            fighter.get_available_quote_ids:revert()
          end)

          it('should still prompt with a dummy reply', function ()
            fm:request_human_fighter_action(mock_pc_fighter)

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
            fm:request_human_fighter_action(mock_pc_fighter)

            local s = assert.spy(dialogue_manager.prompt_items)
            s.was_called(1)
            s.was_called_with(match.ref(dm), {"cancel reply", "reply1"})
          end)

          describe('(when under ai control', function ()

            before_each(function ()
              mock_pc_fighter.fighter_progression.control_type = control_types.ai
            end)

            it('should prompt generated attack items', function ()
              fm:request_human_fighter_action(mock_pc_fighter)

              assert.spy(fight_manager.request_next_fighter_action).was_not_called()

              local s = assert.spy(dialogue_manager.prompt_items)
              s.was_not_called()

              local s = assert.spy(fight_manager.wait_and_do)
              s.was_called(1)
              s.was_called_with(match.ref(fm), visual_data.ai_say_quote_delay, fight_manager.say_quote,
                fm, mock_pc_fighter, fake_reply_items[1])
            end)

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

      -- todo

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
