require("engine/test/bustedhelper")
local adventure_state = require("story/adventure_state")

require("engine/application/constants")
local gamestate = require("engine/application/gamestate")

local wit_fighter_app = require("application/wit_fighter_app")
local dialogue_manager = require("dialogue/dialogue_manager")
local floor_info = require("content/floor_info")
local game_session = require("progression/game_session")
local gameplay_data = require("resources/gameplay_data")
local visual_data = require("resources/visual_data")
local character = require("story/character")

describe('adventure_state', function ()

  describe('static members', function ()

    it('type is :adventure', function ()
      assert.are_equal(':adventure', adventure_state.type)
    end)

  end)

  describe('_init', function ()

    setup(function ()
      spy.on(gamestate, "_init")
    end)

    teardown(function ()
      gamestate._init:revert()
    end)

    after_each(function ()
      gamestate._init:clear()
    end)

    it('should call base constructor', function ()
      local state = adventure_state()

      local s = assert.spy(gamestate._init)
      s.was_called(1)
      s.was_called_with(match.ref(state))
    end)

    it('should init an adventure state', function ()
      local state = adventure_state()
      assert.are_same(character(gameplay_data.pc_info, horizontal_dirs.right, visual_data.pc_sprite_pos), state.pc)
    end)

  end)

  describe('(with instance)', function ()

    local state

    before_each(function ()
      local app = wit_fighter_app()
      app:register_managers({dialogue_manager()})

      state = adventure_state()
      -- no need to register gamestate properly, just add app member to pass tests
      state.app = app
    end)

    describe('on_enter', function ()
      it('should not error', function ()
        assert.has_no_errors(function ()
          state:on_enter()
        end)
      end)
    end)

    describe('on_exit', function ()
      it('should not error', function ()
        assert.has_no_errors(function ()
          state:on_exit()
        end)
      end)
    end)

    describe('update', function ()
      it('should not error', function ()
        assert.has_no_errors(function ()
          state:update()
        end)
      end)
    end)

    describe('render', function ()
      it('should not error', function ()
        assert.has_no_errors(function ()
          state:render()
        end)
      end)
    end)

    -- play_intro is a coroutine, so better tested inside itest

    describe('pick_matching_random_npc_info', function ()

      local mock_npc_info = {}

      setup(function ()
        stub(adventure_state, "get_all_candidate_npc_info", function (self)
          return {{}, {}, mock_npc_info}
        end)
        stub(_G, "random_int_range_exc", function (range)
          return range - 1
        end)
      end)

      teardown(function ()
        state.get_all_candidate_npc_info:revert()
        random_int_range_exc:revert()
      end)

      it('should pick a random npc info among the possible npc levels at the current floor', function ()
        assert.are_equal(mock_npc_info, state:pick_matching_random_npc_info())
      end)

    end)

    describe('get_all_candidate_npc_info', function ()

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
        -- we set the current floor to 3, so npc levels should be 2 to 4
        state.floor_number = 3
        -- we don't go into details but we should have 3 * 3 mock npc infos now, spread on 3 levels
        -- we just check that we have 9 of them
        assert.are_equal(9, #state:get_all_candidate_npc_info())
      end)

    end)

  end)  -- (with instance)

end)
