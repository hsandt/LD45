require("engine/test/bustedhelper")
local adventure = require("story/adventure")

require("engine/application/constants")

local wit_fight_app = require("application/wit_fight_app")
local dialogue_manager = require("dialogue/dialogue_manager")

describe('adventure', function ()

  local state

  before_each(function ()
    local app = wit_fight_app()
    app:register_managers(dialogue_manager())
    state = adventure(app)
  end)

  describe('_init', function ()
    it('should init a adventure', function ()
      assert.is_not_nil(state)
    end)
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

end)
