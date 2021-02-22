require("test/bustedhelper_game")
local adventure_manager = require("story/adventure_manager")

local manager = require("engine/application/manager")

local wit_fighter_app = require("application/wit_fighter_app")

describe('adventure_manager', function ()

  describe('static members', function ()

    it('type is :adventure', function ()
      assert.are_equal(':adventure', adventure_manager.type)
    end)

    it('initially_active is false', function ()
      assert.is_false(adventure_manager.initially_active)
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
      local adv = adventure_manager()

      local s = assert.spy(manager.init)
      s.was_called(1)
      s.was_called_with(match.ref(adv))
    end)

    it('should initialize other members', function ()
      local adv = adventure_manager()

      assert.are_same({""},
        {adv.next_step})
    end)

  end)

  describe('(with instance)', function ()

    local app
    local adv

    before_each(function ()
      app = wit_fighter_app()

      -- relies on gameapp.register_managers working
      app:register_managers({adv})
    end)

    describe('start', function ()
    end)

    describe('update', function ()
    end)

  end)

end)
