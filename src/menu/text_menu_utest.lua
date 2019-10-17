require("engine/test/bustedhelper")
local text_menu = require("menu/text_menu")

local flow = require("engine/application/flow")
local input = require("engine/input/input")
require("engine/render/color")
local ui = require("engine/ui/ui")

local menu_item = require("menu/menu_item")

describe('text_menu', function ()

  local fake_app = {}

  describe('init', function ()

    it('should set passed items, alignment and color, and set selection index to 0', function ()
      local menu = text_menu(fake_app, alignments.left, colors.red)

      assert.are_equal(fake_app, menu.app)
      assert.are_same({alignments.left, colors.red, {}, false, 0},
        {menu.alignment, menu.text_color, menu.items, menu.active, menu.selection_index})
    end)

  end)

  describe('(with instance)', function ()

    local callback1 = function () end
    local callback2 = spy.new(function () end)

    local mock_items = {
      menu_item("in-game", callback1),
      menu_item("credits", callback2)
    }

    local menu

    before_each(function ()
      menu = text_menu(fake_app, alignments.left, colors.red)
    end)

    describe('show_items', function ()

      it('should error with empty items', function ()
        assert.has_errors(function ()
            menu.show_items({})
        end)
      end)

      it('should activate the menu', function ()
        menu:show_items(mock_items)

        assert.is_true(menu.active)
      end)

      it('should fill items with deep copy of items', function ()
        menu:show_items(mock_items)

        assert.are_same(mock_items, menu.items)
        assert.are_not_equal(mock_items, menu.items)
        assert.is_false(rawequal(mock_items[1], menu.items[1]))
        assert.is_false(rawequal(mock_items[2], menu.items[2]))
      end)

      it('should init the selection index', function ()
        menu:show_items(mock_items)

        assert.are_equal(1, menu.selection_index)
      end)

    end)

    describe('clear', function ()

      before_each(function ()
        -- rely on show_items being correct
        menu:show_items(mock_items)
      end)

      it('should deactivate the menu', function ()
        menu:clear(mock_items)

        assert.is_false(menu.active)
      end)

      it('should empty items', function ()
        menu:clear(mock_items)

        assert.are_equal(0, #menu.items)
      end)

      it('should clear the selection index', function ()
        menu:clear(mock_items)

        assert.are_equal(0, menu.selection_index)
      end)

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

      describe('(inactive)', function ()

        it('(when various inputs are down) it should still do nothing', function ()
          input.players_btn_states[0][button_ids.up] = btn_states.just_pressed
          input.players_btn_states[0][button_ids.down] = btn_states.just_pressed
          input.players_btn_states[0][button_ids.o] = btn_states.just_pressed

          menu:update()

          assert.spy(text_menu.select_previous).was_not_called()
          assert.spy(text_menu.select_next).was_not_called()
          assert.spy(text_menu.confirm_selection).was_not_called()
        end)

      end)

      describe('(active)', function ()

        before_each(function ()
          menu:show_items(mock_items)
        end)

        it('(when input up is just pressed) it should move cursor up', function ()
          input.players_btn_states[0][button_ids.up] = btn_states.just_pressed

          menu:update()

          local s = assert.spy(text_menu.select_previous)
          s.was_called(1)
          s.was_called_with(match.ref(menu))
        end)

        it('(when input down is just pressed) it should move cursor down', function ()
          input.players_btn_states[0][button_ids.down] = btn_states.just_pressed

          menu:update()

          local s = assert.spy(text_menu.select_next)
          s.was_called(1)
          s.was_called_with(match.ref(menu))
        end)

        it('(when input o is just pressed) it should confirm selection', function ()
          input.players_btn_states[0][button_ids.o] = btn_states.just_pressed

          menu:update()

          local s = assert.spy(text_menu.confirm_selection)
          s.was_called(1)
          s.was_called_with(match.ref(menu))
        end)

      end)

    end)  -- update

    describe('(showing 2 items)', function ()

      before_each(function ()
        menu:show_items(mock_items)
      end)

      describe('confirm_selection', function ()

        it('should deactivate the menu (keeping items)', function ()
          menu:confirm_selection()

          assert.is_false(menu.active)
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
            s.was_called_with(match.ref(fake_app))
          end)

        end)

      end)

    end)  -- (showing 2 items)

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

      describe('(inactive)', function ()

        it('it should do nothing', function ()
          menu:draw(77, 99)

          assert.spy(ui.print_aligned).was_not_called()
        end)

      end)

      describe('(showing 2 items)', function ()

        before_each(function ()
          menu:show_items(mock_items)
        end)

        it('should print the item labels from a given top, passed alignment, on lines of 6px height, with current selection prepended by ">" for left alignment', function ()
          menu.selection_index = 2  -- credits

          menu:draw(60, 48)

          local s = assert.spy(ui.print_aligned)
          s.was_called(2)
          -- non-selected item is offset to the right
          s.was_called_with("in-game", 68, 48, alignments.left, colors.red)
          s.was_called_with("> credits", 60, 54, alignments.left, colors.red)
        end)

        it('should print the item labels from a given top, passed alignment, on lines of 6px height, with current selection surrounded by "> <" for centered alignment', function ()
          menu.alignment = alignments.center
          menu.selection_index = 2  -- credits

          menu:draw(60, 48)

          local s = assert.spy(ui.print_aligned)
          s.was_called(2)
          s.was_called_with("in-game", 60, 48, alignments.center, colors.red)
          s.was_called_with("> credits <", 60, 54, alignments.center, colors.red)
        end)

      end)  -- (showing 2 items)

    end)  -- draw

  end)  -- (with instance)

end)
