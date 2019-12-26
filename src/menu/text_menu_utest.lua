require("engine/test/bustedhelper")
local text_menu = require("menu/text_menu")

local flow = require("engine/application/flow")
local input = require("engine/input/input")
require("engine/render/color")
local sprite_data = require("engine/render/sprite_data")
local ui = require("engine/ui/ui")

local menu_item = require("menu/menu_item")
local visual_data = require("resources/visual_data")

describe('text_menu', function ()

  local fake_app = {}

  describe('init', function ()

    it('should set passed items, alignment and color, and set selection index to 0', function ()
      local menu = text_menu(fake_app, 5, alignments.left, colors.red, vector(12, 2))

      assert.are_equal(fake_app, menu.app)
      assert.are_same({5, alignments.left, colors.red, vector(12, 2), {}, false, 0},
        {menu.items_count_per_page, menu.alignment, menu.text_color, menu.prev_page_arrow_offset, menu.items, menu.active, menu.selection_index})
    end)

    it('should set default arrow offset to (0, 0)', function ()
      local menu = text_menu(fake_app, 5, alignments.left, colors.red)

      assert.are_equal(vector(0, 0), menu.prev_page_arrow_offset)
    end)

  end)

  describe('(with instance, 2 items per page)', function ()

    local callback1 = function () end
    local callback2 = spy.new(function () end)
    local callback3 = spy.new(function () end)
    local callback4 = spy.new(function () end)

    local mock_items = {
      menu_item("in-game", callback1),
      menu_item("credits", callback2, callback3)
    }

    local mock_items_multipage = {
      menu_item("in-game", callback1),
      menu_item("credits", callback2, callback3),
      menu_item("extra1", callback4),
      menu_item("extra2", callback4),
      menu_item("extra3", callback4)
    }

    local menu

    before_each(function ()
      menu = text_menu(fake_app, 2, alignments.left, colors.red, vector(20, -4))
    end)

    describe('show_items', function ()

      setup(function ()
        spy.on(text_menu, "try_select_callback")
        end)

      teardown(function ()
        text_menu.try_select_callback:revert()
        end)

      after_each(function ()
        text_menu.try_select_callback:clear()
      end)

      it('should error with empty items', function ()
        assert.has_error(function ()
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

      it('should set selection index to 1', function ()
        menu:show_items(mock_items)

        assert.are_equal(1, menu.selection_index)
      end)

      it('should call try_select_callback', function ()
        menu:show_items(mock_items)

        local s = assert.spy(text_menu.try_select_callback)
        s.was_called(1)
        s.was_called_with(match.ref(menu), 1)
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

      describe('try_select_callback', function ()

        it('should not call any select callback if there is none at passed item index', function ()
          local s = assert.has_no_errors(function ()
            menu:try_select_callback(1)
          end)
        end)

        it('should call select callback if there is one at passed item index', function ()
          menu:try_select_callback(2)

          local s = assert.spy(callback3)
          s.was_called(1)
          s.was_called_with(match.ref(fake_app))
        end)

      end)

      describe('confirm_selection', function ()

        setup(function ()
          stub(text_menu, "on_confirm_selection")
        end)

        teardown(function ()
          text_menu.on_confirm_selection:revert()
        end)

        after_each(function ()
          text_menu.on_confirm_selection:clear()
        end)

        it('should deactivate the menu (keeping items)', function ()
          menu:confirm_selection()

          assert.is_false(menu.active)
        end)

        it('should call on_confirm_selection', function ()

          menu:confirm_selection()

          local s = assert.spy(text_menu.on_confirm_selection)
          s.was_called(1)
          s.was_called_with(match.ref(menu))
        end)

      end)

      describe('(when selection index is 1)', function ()

        describe('(stubbing on_selection_changed)', function ()

          setup(function ()
            stub(text_menu, "try_select_callback")
            stub(text_menu, "on_selection_changed")
          end)

          teardown(function ()
            text_menu.try_select_callback:revert()
            text_menu.on_selection_changed:revert()
          end)

          -- before_each and not after_each as show_items in before_each above
          --   calls try_select_callback once already
          -- (on_selection_changed is not called there, so could be in after_each)
          before_each(function ()
            text_menu.try_select_callback:clear()
            text_menu.on_selection_changed:clear()
          end)

          describe('change_selection', function ()

            it('should set selection if new index', function ()
              menu:change_selection(2)
              assert.are_equal(2, menu.selection_index)
            end)

            it('should not call try_select_callback if no index change', function ()
              menu:change_selection(1)

              local s = assert.spy(text_menu.try_select_callback)
              s.was_not_called()
            end)

            it('should call try_select_callback if index change', function ()
              menu:change_selection(2)

              local s = assert.spy(text_menu.try_select_callback)
              s.was_called(1)
              s.was_called_with(match.ref(menu), 2)
            end)

            it('should not call on_selection_changed if no index change', function ()
              menu:change_selection(1)

              local s = assert.spy(text_menu.on_selection_changed)
              s.was_not_called()
            end)

            it('should call on_selection_changed if index change', function ()
              menu:change_selection(2)

              local s = assert.spy(text_menu.on_selection_changed)
              s.was_called(1)
              s.was_called_with(match.ref(menu))
            end)

          end)

          describe('(spying change_selection)', function ()

            setup(function ()
              spy.on(text_menu, "change_selection")
            end)

            teardown(function ()
              text_menu.change_selection:revert()
            end)

            after_each(function ()
              text_menu.change_selection:clear()
            end)

            describe('select_previous', function ()

              it('should not call change_selection due to clamping', function ()
                menu:select_previous()

                local s = assert.spy(text_menu.change_selection)
                s.was_not_called()
              end)

            end)

            describe('select_next', function ()

              it('should call change_selection', function ()
                menu:select_next()

                local s = assert.spy(text_menu.change_selection)
                s.was_called(1)
                s.was_called_with(match.ref(menu), 2)
              end)

            end)

          end)

        end)

      end)

      describe('(when selection index is max (2))', function ()

        before_each(function ()
          menu.selection_index = 2
        end)

        describe('(stubbing on_selection_changed)', function ()

          setup(function ()
            stub(text_menu, "on_selection_changed")
          end)

          teardown(function ()
            text_menu.on_selection_changed:revert()
          end)

          -- before_each and not after_each as show_items in before_each above
          --   calls on_selection_changed once already
          before_each(function ()
            text_menu.on_selection_changed:clear()
          end)

          describe('(spying change_selection)', function ()

            setup(function ()
              spy.on(text_menu, "change_selection")
            end)

            teardown(function ()
              text_menu.change_selection:revert()
            end)

            after_each(function ()
              text_menu.change_selection:clear()
            end)

            describe('select_previous', function ()

              it('should call change_selection', function ()
                menu:select_previous()

                local s = assert.spy(text_menu.change_selection)
                s.was_called(1)
                s.was_called_with(match.ref(menu), 1)
              end)

            end)

            describe('select_next', function ()

              it('should not call change_selection due to clamping', function ()
                menu:select_next()

                local s = assert.spy(text_menu.change_selection)
                s.was_not_called(1)
              end)

            end)

          end)

        end)

        describe('confirm_selection', function ()

          after_each(function ()
            callback2:clear()
          end)

          it('should call confirm callback', function ()
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
        stub(sprite_data, "render")
      end)

      teardown(function ()
        ui.print_aligned:revert()
        sprite_data.render:revert()
      end)

      after_each(function ()
        ui.print_aligned:clear()
        sprite_data.render:clear()
      end)

      describe('(inactive)', function ()

        it('it should do nothing', function ()
          menu:draw(77, 99)

          assert.spy(ui.print_aligned).was_not_called()
        end)

      end)

      describe('(showing 2 items, below max items per page)', function ()

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

        it('should print the item labels from a given top, passed alignment, on lines of 6px height, with current selection surrounded by "> <" for horizontally centered alignment', function ()
          menu.alignment = alignments.horizontal_center
          menu.selection_index = 2  -- credits

          menu:draw(60, 48)

          local s = assert.spy(ui.print_aligned)
          s.was_called(2)
          s.was_called_with("in-game", 60, 48, alignments.horizontal_center, colors.red)
          s.was_called_with("> credits <", 60, 54, alignments.horizontal_center, colors.red)
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

        it('should not print any previous/next page arrow', function ()
          menu:draw(60, 48)

          local s = assert.spy(sprite_data.render)
          s.was_not_called()
        end)

      end)  -- (showing 2 items, below max items per page)

      describe('(showing 5 items, so 2 pages + 1 item)', function ()

        before_each(function ()
          menu:show_items(mock_items_multipage)
        end)

        it('(selection falls on page 1) should print item labels for page 1', function ()
          menu.selection_index = 2  -- credits

          menu:draw(60, 48)

          local s = assert.spy(ui.print_aligned)
          s.was_called(2)
          -- non-selected item is offset to the right
          s.was_called_with("in-game", 68, 48, alignments.left, colors.red)
          s.was_called_with("> credits", 60, 54, alignments.left, colors.red)
        end)

        it('(selection falls on page 2) should print item labels for page 2', function ()
          menu.selection_index = 3  -- extra1

          menu:draw(60, 48)

          local s = assert.spy(ui.print_aligned)
          s.was_called(2)
          s.was_called_with("> extra1", 60, 48, alignments.left, colors.red)
          -- non-selected item is offset to the right
          s.was_called_with("extra2", 68, 54, alignments.left, colors.red)
        end)

        it('(selection falls on page 3) should print item labels for page 2', function ()
          menu.selection_index = 5  -- extra3

          menu:draw(60, 48)

          local s = assert.spy(ui.print_aligned)
          s.was_called(1)
          s.was_called_with("> extra3", 60, 48, alignments.left, colors.red)
        end)

        it('(selection falls on page 1/3) should draw next page arrow (previous arrow y-flipped)', function ()
          menu.selection_index = 1

          menu:draw(60, 48)

          local s = assert.spy(sprite_data.render)
          s.was_called(1)
          -- 60 + offset 20 = 80
          -- 48 + 2 lines * char height 6 - offset -4 = 64
          s.was_called_with(match.ref(visual_data.sprites.previous_arrow),
            vector(80, 65), false, true)
        end)

        it('(selection falls on page 2/3) should draw previous and next page arrow', function ()
          menu.selection_index = 4

          menu:draw(60, 48)

          local s = assert.spy(sprite_data.render)
          s.was_called(2)
          -- 60 + offset 20 = 80
          -- 48 - margin 2 - offset 4 = 42
          s.was_called_with(match.ref(visual_data.sprites.previous_arrow),
            vector(80, 42))
          s.was_called_with(match.ref(visual_data.sprites.previous_arrow),
            vector(80, 65), false, true)
        end)

        it('(selection falls on page 3/3) should draw previous page arrow', function ()
          menu.selection_index = 5  -- extra3

          menu:draw(60, 48)

          local s = assert.spy(sprite_data.render)
          s.was_called(1)
          s.was_called_with(match.ref(visual_data.sprites.previous_arrow),
            vector(80, 42))
        end)

      end)  -- (showing 5 items, so 2 pages + 1 item)

    end)  -- draw

  end)  -- (with instance)

end)
