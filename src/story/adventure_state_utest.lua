require("engine/test/bustedhelper")
local adventure_state = require("story/adventure_state")

require("engine/application/constants")
local gamestate = require("engine/application/gamestate")

local wit_fighter_app = require("application/wit_fighter_app")
local dialogue_manager = require("dialogue/dialogue_manager")
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
      assert.is_not_nil(state)
    end)

  end)

  describe('(with instance)', function ()

    local state

    before_each(function ()
      local app = wit_fighter_app()
      app:instantiate_and_register_managers()

      state = adventure_state()
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
      -- todo
    end)

    describe('render', function ()
      -- todo
    end)

  end)  -- (with instance)

end)
