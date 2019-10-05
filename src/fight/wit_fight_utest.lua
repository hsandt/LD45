require("engine/test/bustedhelper")
local wit_fight = require("fight/wit_fight")

describe('wit_fight', function ()

  local state

  before_each(function ()
    state = wit_fight()
  end)

  describe('init', function ()

  end)

  describe('on_enter', function ()

  end)

  describe('update', function ()

  end)

  describe('render', function ()

    setup(function ()
      stub(wit_fight, "draw_background")
      stub(wit_fight, "draw_characters")
      stub(wit_fight, "draw_hud")
    end)

    teardown(function ()
      wit_fight.draw_background:revert()
      wit_fight.draw_characters:revert()
      wit_fight.draw_hud:revert()
    end)

    after_each(function ()
      wit_fight.draw_background:clear()
      wit_fight.draw_characters:clear()
      wit_fight.draw_hud:clear()
    end)

    it('should call draw background, characters, hud', function ()
      state:render()

      local s = assert.spy(wit_fight.draw_background)
      s.was_called(1)
      s.was_called_with(match.ref(state))

      local s = assert.spy(wit_fight.draw_characters)
      s.was_called(1)
      s.was_called_with(match.ref(state))

      local s = assert.spy(wit_fight.draw_hud)
      s.was_called(1)
      s.was_called_with(match.ref(state))
    end)

  end)

  describe('draw_background', function ()
    it('should not error', function ()
      assert.has_no_errors(function ()
        state:draw_background()
      end)
    end)
  end)

  describe('draw_characters', function ()
    it('should not error', function ()
      assert.has_no_errors(function ()
        state:draw_characters()
      end)
    end)
  end)

  describe('draw_hud', function ()
    it('should not error', function ()
      assert.has_no_errors(function ()
        state:draw_hud()
      end)
    end)
  end)

end)
