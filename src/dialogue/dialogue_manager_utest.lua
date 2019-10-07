require("engine/test/bustedhelper")
local dialogue_manager = require("dialogue/dialogue_manager")

describe('dialogue_manager', function ()

  describe('_init', function ()
    it('should init a dialogue_manager', function ()
      local d = dialogue_manager()
      assert.is_not_nil(d)
    end)
  end)

  describe('start', function ()
    it('should not error', function ()
      local d = dialogue_manager()
      assert.has_no_errors(function ()
        d:start()
      end)
    end)
  end)

  describe('update', function ()
    it('should not error', function ()
      local d = dialogue_manager()
      assert.has_no_errors(function ()
        d:update()
      end)
    end)
  end)

  describe('render', function ()

    it('should not error', function ()
      local d = dialogue_manager()
      assert.has_no_errors(function ()
        d:render()
      end)
    end)

    it('(current text set) should not error', function ()
      local d = dialogue_manager()
      d.current_text = "hello"
        d:render()

      assert.has_no_errors(function ()
        d:render()
      end)
    end)

  end)

end)
