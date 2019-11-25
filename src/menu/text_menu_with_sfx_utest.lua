require("engine/test/bustedhelper")
local text_menu = require("menu/text_menu")
local text_menu_with_sfx = require("menu/text_menu_with_sfx")

local menu_item = require("menu/menu_item")
local audio_data = require("resources/audio_data")

describe('text_menu_with_sfx', function ()

  local fake_app = {}

  describe('(with instance, stubbing sfx)', function ()

    local menu

    setup(function ()
      stub(_G, "sfx")
    end)

    teardown(function ()
      sfx:revert()
    end)

    before_each(function ()
      menu = text_menu_with_sfx(fake_app, 2, alignments.left, colors.red)
    end)

    after_each(function ()
      sfx:clear()
    end)

    describe('on_selection_changed', function ()

      it('should play selection sfx', function ()
        text_menu_with_sfx.on_selection_changed()

        local s = assert.spy(sfx)
        s.was_called(1)
        s.was_called_with(audio_data.sfx.menu_select)
      end)

    end)

    describe('on_confirm_selection', function ()

      it('should play selection sfx', function ()
        text_menu_with_sfx.on_confirm_selection()

        local s = assert.spy(sfx)
        s.was_called(1)
        s.was_called_with(audio_data.sfx.menu_confirm)
      end)

    end)

  end)  -- (with instance)

end)
