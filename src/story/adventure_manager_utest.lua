require("engine/test/bustedhelper")
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
      local adv = adventure_manager()

      local s = assert.spy(manager._init)
      s.was_called(1)
      s.was_called_with(match.ref(adv))
    end)

    it('should initialize other members', function ()
      local adv = adventure_manager()

      assert.are_same({""},
        {adv.step})
    end)

  end)

  describe('(with instance)', function ()

    local app
    local adv

    before_each(function ()
      app = adventureer_app()

      -- relies on gameapp.register_managers working
      app:register_managers({adv})
    end)

    describe('start', function ()
    end)

    describe('update', function ()
    end)

    describe('render', function ()
    end)

  end)

end)
