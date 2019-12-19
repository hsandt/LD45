require("engine/test/bustedhelper")
local dialogue_manager = require("dialogue/dialogue_manager")

require("engine/application/constants")
local manager = require("engine/application/manager")
local input = require("engine/input/input")
local animated_sprite = require("engine/render/animated_sprite")

local character_info = require("content/character_info")
local speaker_component = require("dialogue/speaker_component")
local text_menu = require("menu/text_menu")
local visual_data = require("resources/visual_data")
local character = require("story/character")

describe('dialogue_manager', function ()

  local mock_character_info1 = character_info(1, "employee1", 5)
  local mock_character_info2 = character_info(2, "employee2", 6)

  local c1
  local c2
  local s1
  local s2

  before_each(function ()
    c1 = character(mock_character_info1, horizontal_dirs.right, vector(20, 60))
    c2 = character(mock_character_info2, horizontal_dirs.right, vector(20, 60))
    s1 = speaker_component(c1)
    s2 = speaker_component(c2)
  end)

  describe('static members', function ()

    it('type is :dialogue', function ()
      assert.are_equal(':dialogue', dialogue_manager.type)
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
      local d = dialogue_manager()

      local s = assert.spy(manager._init)
      s.was_called(1)
      s.was_called_with(match.ref(d))
    end)

    it('should init a dialogue_manager', function ()
      local d = dialogue_manager()

      assert.are_same({nil, {}, false, nil},
        {d.text_menu, d.speakers, d.should_show_bottom_box, d.current_bottom_text})
    end)

  end)

  describe('(with instance d)', function ()

    local fake_app = {}

    local d

    before_each(function ()
      d = dialogue_manager()
      d.app = fake_app
    end)

    describe('start', function ()
      it('should create text menu with app', function ()
        d:start()

        assert.are_equal(fake_app, d.text_menu.app)
        assert.are_same({alignments.left, colors.dark_blue}, {d.text_menu.alignment, d.text_menu.text_color})
      end)
    end)

    describe('(with d started)', function ()

      before_each(function ()
        d:start()
      end)

      describe('update', function ()

        setup(function ()
          stub(dialogue_manager, "update_speaker")
        end)

        teardown(function ()
          dialogue_manager.update_speaker:revert()
        end)

        after_each(function ()
          input:init()

          dialogue_manager.update_speaker:clear()
        end)

        it('(no speakers) should do nothing', function ()
          d:update()

          local s = assert.spy(dialogue_manager.update_speaker)
          s.was_not_called()
        end)

        it('(2 speakers) should update speakers', function ()
          d.speakers = {s1, s2}

          d:update()

          local s = assert.spy(dialogue_manager.update_speaker)
          s.was_called(2)
          s.was_called_with(match.ref(s1))
          s.was_called_with(match.ref(s2))
        end)

      end)

      describe('render', function ()

        setup(function ()
          stub(dialogue_manager, "render_speaker")
          stub(dialogue_manager, "draw_bottom_box")
          stub(text_menu, "draw")
          stub(dialogue_manager, "draw_bottom_text")
        end)

        teardown(function ()
          dialogue_manager.render_speaker:revert()
          dialogue_manager.draw_bottom_box:revert()
          text_menu.draw:revert()
          dialogue_manager.draw_bottom_text:revert()
        end)

        after_each(function ()
          input:init()

          dialogue_manager.render_speaker:clear()
          dialogue_manager.draw_bottom_box:clear()
          text_menu.draw:clear()
          dialogue_manager.draw_bottom_text:clear()
        end)

        it('(no speakers) should do nothing', function ()
          d:update()

          local s = assert.spy(dialogue_manager.render_speaker)
          s.was_not_called()
        end)

        it('(2 speakers) should update speakers', function ()
          d.speakers = {s1, s2}

          d:render()

          local s = assert.spy(dialogue_manager.render_speaker)
          s.was_called(2)
          s.was_called_with(match.ref(s1))
          s.was_called_with(match.ref(s2))
        end)

        it('(should show bottom box) should draw bottom box', function ()
          d.should_show_bottom_box = true

          d:render()

          local s = assert.spy(dialogue_manager.draw_bottom_box)
          s.was_called(1)
          s.was_called_with(match.ref(d))
        end)

        it('(text menu active) draw text menu', function ()
          d.text_menu.active = true
          d.current_bottom_text = "hello"

          d:render()

          local s = assert.spy(text_menu.draw)
          s.was_called(1)
          s.was_called_with(match.ref(d.text_menu), 2, 91)
        end)

        it('(text menu active and current bottom text set) draw text menu in priority', function ()
          d.text_menu.active = true
          d.current_bottom_text = "hello"

          d:render()

          local s = assert.spy(text_menu.draw)
          s.was_called(1)
          s.was_called_with(match.ref(d.text_menu), 2, 91)
        end)

        it('(current bottom text set) should not error', function ()
          d.current_bottom_text = "hello"

          d:render()

          local s = assert.spy(dialogue_manager.draw_bottom_text)
          s.was_called(1)
          s.was_called_with(match.ref(d))
        end)

        it('(text menu inactive and current bottom text not set) should not draw any', function ()
          d:render()

          assert.spy(text_menu.draw).was_not_called()
          assert.spy(dialogue_manager.draw_bottom_text).was_not_called()
        end)

      end)

      describe('add_speaker', function ()

        it('should add a speaker component to the speakers', function ()
          d:add_speaker(s1)
          d:add_speaker(s2)

          assert.are_same({s1, s2}, d.speakers)
        end)

      end)

      describe('remove_speaker', function ()

        it('should remove a speaker component to the speakers', function ()
          d.speakers = {s1, s2}

          d:remove_speaker(s1)
          d:remove_speaker(s2)

          assert.are_same({}, d.speakers)
        end)

      end)

      describe('prompt_items', function ()

        setup(function ()
          stub(text_menu, "show_items")
        end)

        teardown(function ()
          text_menu.show_items:revert()
        end)

        after_each(function ()
          text_menu.show_items:clear()
        end)

        it('should show items in text menu component', function ()
          local fake_items = {}  -- dummy menu item sequence
          d:prompt_items(fake_items)

          local s = assert.spy(text_menu.show_items)
          s.was_called(1)
          s.was_called_with(match.ref(d.text_menu), match.ref(fake_items))
        end)

      end)

    end)  -- (with d started)

  end)  -- (with instance d)

  -- static

  describe('update_speaker', function ()

    setup(function ()
      stub(speaker_component, "stop")
      stub(animated_sprite, "update")
    end)

    teardown(function ()
      speaker_component.stop:revert()
      animated_sprite.update:revert()
    end)

    after_each(function ()
      input:init()

      speaker_component.stop:clear()
      animated_sprite.update:clear()
    end)

    it('(some speaker waiting for input, but no confirm input) should not stop speaker and update continue hint sprite', function ()
      s1.wait_for_input = true

      dialogue_manager.update_speaker(s1)

      local s = assert.spy(speaker_component.stop)
      s.was_not_called()

      s = assert.spy(animated_sprite.update)
      s.was_called()
      s.was_called_with(match.ref(s1.continue_hint_sprite))
    end)

    it('(some speaker waiting for input and confirm input) should stop speaker', function ()
      s1.wait_for_input = true
      input.players_btn_states[0][button_ids.o] = btn_states.just_pressed

      -- normally d.speakers = {speaker} but we can test by passing directly s1
      dialogue_manager.update_speaker(s1)

      local s = assert.spy(speaker_component.stop)
      s.was_called(1)
      s.was_called_with(match.ref(s1))

      s = assert.spy(animated_sprite.update)
      s.was_not_called()
    end)

    it('(some speaker not waiting for input) should not stop speaker nor update continue hint sprite', function ()
      s1.wait_for_input = false

      -- normally d.speakers = {speaker} but we can test by passing directly s1
      dialogue_manager.update_speaker(s1)

      local s = assert.spy(speaker_component.stop)
      s.was_not_called()

      s = assert.spy(animated_sprite.update)
      s.was_not_called()
    end)

  end)

  describe('render_speaker', function ()

    setup(function ()
      stub(dialogue_manager, "draw_bubble_with_text")
    end)

    teardown(function ()
      dialogue_manager.draw_bubble_with_text:revert()
    end)

    after_each(function ()
      dialogue_manager.draw_bubble_with_text:clear()
    end)

    it('(no current text) should do nothing', function ()
      s1.current_text = nil

      dialogue_manager.render_speaker(s1)

      local s = assert.spy(dialogue_manager.draw_bubble_with_text)
      s.was_not_called()
    end)

    it('(some current text) should call draw_bubble_with_text', function ()
      s1.current_text = "hello"

      dialogue_manager.render_speaker(s1)

      local s = assert.spy(dialogue_manager.draw_bubble_with_text)
      s.was_called(1)
    end)

  end)

  describe('compute_bubble_bounds', function ()

    -- we test for speech only, expecting thought to work as it's only a change of data

    it('(anchor far from both edges enough) should return bubble bounds', function ()
      -- longest line has 12 characters
      assert.are_same({30-(12*4+2)/2, 19, 30+(12*4+2)/2, 27},
        {dialogue_manager.compute_bubble_bounds(bubble_types.speech, "hello world!", vector(30, 30))})
    end)

    it('(anchor close to left) should return bubble bounds clamped on left', function ()
      -- longest line has 19 characters
      assert.are_same({4, 7, 4+(19*4+2), 27},
        {dialogue_manager.compute_bubble_bounds(bubble_types.speech, "hello world!\nmy name is girljpeg\nfourswords", vector(10, 30))})
    end)

    it('(anchor close to right) should return bubble bounds clamped on right', function ()
      -- longest line has 19 characters
      assert.are_same({124-(19*4+2), 7, 124, 27},
        {dialogue_manager.compute_bubble_bounds(bubble_types.speech, "hello world!\nmy name is girljpeg\nfourswords", vector(100, 30))})
    end)

    it('(text is too long for anything, anchor on left side) should return bubble bounds clamped on both sides', function ()
      -- longest line has 30 characters... too many to fit, it's really just to cover the weird cases
      assert.are_same({4, 19, 124, 27},
        {dialogue_manager.compute_bubble_bounds(bubble_types.speech, "123456789012345678901234567890", vector(20, 30))})
    end)

    it('(text is too long for anything, anchor on right side) should return bubble bounds clamped on both sides', function ()
      -- longest line has 30 characters... too many to fit, it's really just to cover the weird cases
      assert.are_same({4, 19, 124, 27},
        {dialogue_manager.compute_bubble_bounds(bubble_types.speech, "123456789012345678901234567890", vector(100, 30))})
    end)

  end)

end)
