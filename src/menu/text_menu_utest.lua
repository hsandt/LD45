require("engine/test/bustedhelper")
local text_menu = require("menu/text_menu")

local flow = require("engine/application/flow")
local input = require("engine/input/input")
require("engine/render/color")
local ui = require("engine/ui/ui")

local menu_item = require("menu/menu_item")

describe('text_menu', function ()

  describe('init', function ()

    it('should set passed items and alignment, and set selection index to 1', function ()
      local menu = text_menu({menu_item("credits", ':credits')}, alignments.left)

      assert.are_same({{menu_item("credits", ':credits')}, alignments.left, 1},
        {menu.items, menu.alignment, menu.selection_index})
    end)

  end)

  describe('(with instance)', function ()

    local menu
    local callback1 = function () end
    local callback2 = spy.new(function () end)

    before_each(function ()
      menu = text_menu({
        menu_item("in-game", callback1),
        menu_item("credits", callback2)
      }, alignments.left)
    end)

    describe('update', function ()

      setup(function ()
        stub(text_menu, "select_previous")
        stub(text_menu, "select_next")
        stub(text_menu, "confirm_selection")
      end)

      teardown(function ()
        text_menu.select_previous:revert()
        text_menu.select_next:revert()
        text_menu.confirm_selection:revert()
      end)

      after_each(function ()
        input.players_btn_states[0][button_ids.up] = btn_states.released
        input.players_btn_states[0][button_ids.down] = btn_states.released
        input.players_btn_states[0][button_ids.x] = btn_states.released

        text_menu.select_previous:clear()
        text_menu.select_next:clear()
        text_menu.confirm_selection:clear()
      end)

      it('(when input up is down) it should move cursor up', function ()
        input.players_btn_states[0][button_ids.up] = btn_states.just_pressed

        menu:update()

        local s = assert.spy(text_menu.select_previous)
        s.was_called(1)
        s.was_called_with(match.ref(menu))
      end)

      it('(when input down is down) it should move cursor down', function ()
        input.players_btn_states[0][button_ids.down] = btn_states.just_pressed

        menu:update()

        local s = assert.spy(text_menu.select_next)
        s.was_called(1)
        s.was_called_with(match.ref(menu))
      end)

      it('(when input o is down) it should confirm selection', function ()
        input.players_btn_states[0][button_ids.o] = btn_states.just_pressed

        menu:update()

        local s = assert.spy(text_menu.confirm_selection)
        s.was_called(1)
        s.was_called_with(match.ref(menu))
      end)

    end)

    describe('(when selection index is 1)', function ()

      describe('select_previous', function ()

        it('should not change selection index due to clamping', function ()
          menu:select_previous()
          assert.are_equal(1, menu.selection_index)
        end)

      end)

      describe('select_next', function ()

        it('should increment selection index', function ()
          menu:select_next()
          assert.are_equal(2, menu.selection_index)
        end)

      end)

    end)

    describe('(when selection index is max (2))', function ()

      before_each(function ()
        menu.selection_index = 2
      end)

      describe('select_previous', function ()

        it('should decrement selection index', function ()
          menu:select_previous()
          assert.are_equal(1, menu.selection_index)
        end)

      end)

      describe('select_next', function ()

        it('should not change selection index due to clamping', function ()
          menu:select_next()
          assert.are_equal(2, menu.selection_index)
        end)

      end)

      describe('confirm_selection', function ()

        after_each(function ()
          callback2:clear()
        end)

        it('should enter the credits state', function ()
          menu:confirm_selection()

          local s = assert.spy(callback2)
          s.was_called(1)
        end)

      end)

    end)

    describe('draw', function ()

      setup(function ()
        stub(ui, "print_aligned")
      end)

      teardown(function ()
        ui.print_aligned:revert()
      end)

      after_each(function ()
        ui.print_aligned:clear()
      end)

      it('should print the item labels from a given top, passed alignment, on lines of 6px height, with current selection prepended by ">" for left alignment', function ()
        menu.selection_index = 2  -- credits

        menu:draw(60, 48)

        local s = assert.spy(ui.print_aligned)
        s.was_called(2)
        -- non-selected item is offset to the right
        s.was_called_with("in-game", 68, 48, alignments.left, colors.white)
        s.was_called_with("> credits", 60, 54, alignments.left, colors.white)
      end)

      it('should print the item labels from a given top, passed alignment, on lines of 6px height, with current selection surrounded by "> <" for centered alignment', function ()
        menu.alignment = alignments.center
        menu.selection_index = 2  -- credits

        menu:draw(60, 48)

        local s = assert.spy(ui.print_aligned)
        s.was_called(2)
        s.was_called_with("in-game", 60, 48, alignments.center, colors.white)
        s.was_called_with("> credits <", 60, 54, alignments.center, colors.white)
      end)

    end)

  end)  -- (with instance)

end)
