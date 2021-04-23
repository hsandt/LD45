require("test/bustedhelper_game")
local main_menu = require("menu/main_menu")

local gamestate = require("engine/application/gamestate")
local input = require("engine/input/input")
require("engine/render/color")
local text_helper = require("engine/ui/text_helper")

local text_menu = require("menu/text_menu")

describe('main_menu', function ()

  describe('init', function ()

    setup(function ()
      spy.on(gamestate, "init")
    end)

    teardown(function ()
      gamestate.init:revert()
    end)

    after_each(function ()
      gamestate.init:clear()
    end)

    it('should call base constructor', function ()
      local state = main_menu()

      local s = assert.spy(gamestate.init)
      s.was_called(1)
      s.was_called_with(match.ref(state))
    end)

    it('should set text menu to nil', function ()
      -- as long as there are no type/attribute checks in init, we don't need
      --  to actualy derive from gameapp for the dummy app
      local fake_app = {}
      local menu = main_menu(fake_app)

      assert.are_same(nil, menu.text_menu)
    end)

  end)

  describe('(with instance)', function ()

    local fake_app = {}
    local menu

    setup(function ()
      stub(text_menu, "show_items")
    end)

    teardown(function ()
      text_menu.show_items:revert()
    end)

    before_each(function ()
      menu = main_menu()
      menu.app = fake_app
    end)

    after_each(function ()
      text_menu.show_items:clear()
    end)

    describe('on_enter', function ()

      it('should create text menu with app', function ()
        menu:on_enter()

        assert.are_equal(fake_app, menu.text_menu.app)
        assert.are_same({alignments.horizontal_center, colors.white}, {menu.text_menu.alignment, menu.text_menu.text_color})
      end)

      it('should show text menu', function ()
        menu:on_enter()

        local s = assert.spy(text_menu.show_items)
        s.was_called(1)
        s.was_called_with(match.ref(menu.text_menu), match.ref(main_menu.items))
      end)

    end)

    describe('(with menu entered)', function ()

      before_each(function ()
        menu:on_enter()
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

        it('should draw text_menu', function ()
          menu:render()

          local s = assert.spy(text_menu.draw)
          s.was_called(1)
          -- no need to check where exactly it is printed
        end)

      end)

      describe('draw_title', function ()

        setup(function ()
          stub(text_helper, "print_centered")
        end)

        teardown(function ()
          text_helper.print_centered:revert()
        end)

        after_each(function ()
          text_helper.print_centered:clear()
        end)

        it('should print "wit fighter [version] by komehara" centered, in white', function ()
          menu:draw_title()

          local s = assert.spy(text_helper.print_centered)
          s.was_called(3)
          -- no need to check what exactly is printed
        end)

      end)

      describe('draw_instructions', function ()

        setup(function ()
          stub(text_helper, "print_centered")
          stub(api, "print")
        end)

        teardown(function ()
          text_helper.print_centered:revert()
          api.print:revert()
        end)

        after_each(function ()
          text_helper.print_centered:clear()
          api.print:clear()
        end)

        it('should print a few lines', function ()
          menu:draw_instructions()

          local s = assert.spy(text_helper.print_centered)
          s.was_called(2)

          local s = assert.spy(api.print)
          s.was_called(3)
          -- no need to check what exactly is printed
        end)

      end)

    end)  -- (with menu entered)

  end)  -- (with instance)

end)
