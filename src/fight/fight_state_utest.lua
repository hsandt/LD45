require("test/bustedhelper_game")
local fight_state = require("fight/fight_state")

require("engine/application/constants")
local gamestate = require("engine/application/gamestate")

local wit_fighter_app = require("application/wit_fighter_app")
local dialogue_manager = require("dialogue/dialogue_manager")

describe('fight_state', function ()

  describe('static members', function ()

    it('type is :fight', function ()
      assert.are_equal(':fight', fight_state.type)
    end)

  end)

  describe('(with instance)', function ()

    local state

    before_each(function ()
      local app = wit_fighter_app()
      app:instantiate_and_register_managers()

      state = fight_state()
        -- no need to register gamestate properly, just add app member to pass tests
      state.app = app
    end)

    describe('on_enter', function ()
      -- todo
    end)

    describe('on_exit', function ()
      -- todo
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
          state:render()
        assert.has_no_errors(function ()
        end)
      end)
    end)

  end)  -- (with instance)

end)
