require("engine/test/bustedhelper")
local main_menu = require("menu/main_menu")

local input = require("engine/input/input")
require("engine/render/color")
local ui = require("engine/ui/ui")

local text_menu = require("menu/text_menu")

describe('main_menu', function ()

  describe('init', function ()
    it('should set text menu to a new text menu with given items', function ()
      -- as long as there are no type/attribute checks in _init, we don't need
      --  to actualy derive from gameapp for the dummy app
      local dummy_app = {}
      local menu = main_menu(dummy_app)

      assert.are_equal(main_menu._items, menu._items)
    end)
  end)

  describe('(with instance)', function ()

    local dummy_app = {}
    local menu

    before_each(function ()
      menu = main_menu(dummy_app)
    end)

    describe('update', function ()

      setup(function ()
        stub(text_menu, "update")
      end)

      teardown(function ()
        text_menu.update:revert()
      end)

      it('should update text_menu', function ()
        menu:update()

        local s = assert.spy(text_menu.update)
        s.was_called(1)
        s.was_called_with(match.ref(menu.text_menu))
      end)

    end)

    describe('render', function ()

      setup(function ()
        stub(main_menu, "draw_title")
        stub(main_menu, "draw_instructions")
        -- stub text_menu.draw completely to avoid altering the count of ui.print_centered calls
        stub(text_menu, "draw")
      end)

      teardown(function ()
        main_menu.draw_title:revert()
        main_menu.draw_instructions:revert()
        text_menu.draw:revert()
      end)

      after_each(function ()
        main_menu.draw_title:clear()
        main_menu.draw_instructions:clear()
        text_menu.draw:clear()
      end)

      it('should draw title', function ()
        menu:render()

        local s = assert.spy(main_menu.draw_title)
        s.was_called(1)
        s.was_called_with(match.ref(menu))
      end)

      it('should draw instructions', function ()
        menu:render()

        local s = assert.spy(main_menu.draw_instructions)
        s.was_called(1)
        s.was_called_with(match.ref(menu))
      end)

      it('should draw text_menu 4 lines below title + author, in the middle of screen width', function ()
        menu:render()

        local s = assert.spy(text_menu.draw)
        s.was_called(1)
        s.was_called_with(match.ref(menu.text_menu), 64, 56 + 4 * 6)
      end)

    end)

    describe('draw_title', function ()

      setup(function ()
        stub(ui, "print_centered")
      end)

      teardown(function ()
        ui.print_centered:revert()
      end)

      after_each(function ()
        ui.print_centered:clear()
      end)

      it('should print "wit fighter by komehara" centered, in white', function ()
        menu:draw_title()

        local s = assert.spy(ui.print_centered)
        s.was_called(2)
        s.was_called_with("wit fighter", 64, 48, colors.white)
        s.was_called_with("by komehara", 64, 56, colors.white)
      end)

    end)

    describe('draw_instructions', function ()

      setup(function ()
        stub(api, "print")
      end)

      teardown(function ()
        api.print:revert()
      end)

      after_each(function ()
        api.print:clear()
      end)

      it('should print a few lines', function ()
        menu:draw_instructions()

        local s = assert.spy(api.print)
        s.was_called(5)
        -- no need to check what exactly is printed
      end)

    end)

  end)  -- (with instance)

end)
