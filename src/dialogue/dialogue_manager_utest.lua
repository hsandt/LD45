require("engine/test/bustedhelper")
local dialogue_manager = require("dialogue/dialogue_manager")

require("engine/application/constants")
local input = require("engine/input/input")

local speaker_component = require("dialogue/speaker_component")
local visual_data = require("resources/visual_data")

describe('dialogue_manager', function ()

  describe('(with instance d)', function ()

    local d

    before_each(function ()
      d = dialogue_manager()
    end)

    describe('_init', function ()
      it('should init a dialogue_manager', function ()
        assert.is_not_nil(d)
      end)
    end)

    describe('start', function ()
      it('should not error', function ()
        assert.has_no_errors(function ()
          d:start()
        end)
      end)
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
        local s1 = speaker_component(vector(1, 0))
        local s2 = speaker_component(vector(2, 0))
        d.speakers = {s1, s2}

        d:update()

        local s = assert.spy(dialogue_manager.update_speaker)
        s.was_called(2)
        s.was_called_with(match.ref(d), match.ref(s1))
        s.was_called_with(match.ref(d), match.ref(s2))
      end)

    end)

    describe('render', function ()

      setup(function ()
        stub(dialogue_manager, "render_speaker")
      end)

      teardown(function ()
        dialogue_manager.render_speaker:revert()
      end)

      after_each(function ()
        input:init()

        dialogue_manager.render_speaker:clear()
      end)

      it('(no speakers) should do nothing', function ()
        d:update()

        local s = assert.spy(dialogue_manager.render_speaker)
        s.was_not_called()
      end)

      it('(2 speakers) should update speakers', function ()
        local s1 = speaker_component(vector(1, 0))
        local s2 = speaker_component(vector(2, 0))
        d.speakers = {s1, s2}

        d:render()

        local s = assert.spy(dialogue_manager.render_speaker)
        s.was_called(2)
        s.was_called_with(match.ref(d), match.ref(s1))
        s.was_called_with(match.ref(d), match.ref(s2))
      end)

      it('(should show bottom box) should not error', function ()
        d.should_show_bottom_box = true
        assert.has_no_errors(function ()
          d:render()
        end)
      end)

      it('(some active speaker) should not error', function ()

        local s = speaker_component(vector(1, 0))
        s.current_text = "hello"
        d.speakers = {s}

        assert.has_no_errors(function ()
          d:render()
        end)
      end)

      it('(current bottom text set) should not error', function ()
        d.current_bottom_text = "hello"

        assert.has_no_errors(function ()
          d:render()
        end)
      end)

    end)

    describe('add_speaker', function ()

      it('should add a speaker component to the speakers', function ()

        local s1 = speaker_component(vector(1, 0))
        local s2 = speaker_component(vector(2, 0))
        d:add_speaker(s1)
        d:add_speaker(s2)

        assert.are_same({s1, s2}, d.speakers)
      end)

    end)

    describe('update_speaker', function ()

      setup(function ()
        stub(speaker_component, "stop")
      end)

      teardown(function ()
        speaker_component.stop:revert()
      end)

      after_each(function ()
        input:init()

        speaker_component.stop:clear()
      end)

      it('(some speaker waiting for input, but no confirm) should not stop speaker', function ()
        local speaker = speaker_component(vector(1, 0))
        speaker.current_text = "hello"
        speaker.wait_for_input = true

        d:update()

        local s = assert.spy(speaker_component.stop)
        s.was_not_called()
      end)

      it('(some speaker waiting for input  and confirm input) should stop speaker', function ()
        local speaker = speaker_component(vector(1, 0))
        speaker.current_text = "hello"
        speaker.wait_for_input = true
        input.players_btn_states[0][button_ids.o] = btn_states.just_pressed

        -- normally d.speakers = {speaker} but we can test by passing directly s
        d:update_speaker(speaker)

        local s = assert.spy(speaker_component.stop)
        s.was_called(1)
        s.was_called_with(match.ref(speaker))
      end)

    end)

    describe('render_speaker', function ()

      it('should not error', function ()
        local speaker = speaker_component(vector(1, 0))

        assert.has_no_errors(function ()
          d:render_speaker(speaker)
        end)
      end)

      it('(speaker has current text) should not error', function ()
        local speaker = speaker_component(vector(1, 0))
        speaker.current_text = "hello"

        assert.has_no_errors(function ()
          d:render_speaker(speaker)
        end)
      end)

    end)

  end)  -- (with instance d)

  describe('compute_bubble_bounds', function ()

    it('(anchor far from both edges enough) should return bubble bounds', function ()
      -- longest line has 12 characters
      assert.are_same({30-(12*4+2)/2, 18, 30+(12*4+2)/2, 26},
        {dialogue_manager.compute_bubble_bounds("hello world!", vector(30, 30))})
    end)

    it('(anchor close to left) should return bubble bounds clamped on left', function ()
      -- longest line has 19 characters
      assert.are_same({4, 6, 4+(19*4+2), 26},
        {dialogue_manager.compute_bubble_bounds("hello world!\nmy name is girljpeg\nfourswords", vector(10, 30))})
    end)

    it('(anchor close to right) should return bubble bounds clamped on right', function ()
      -- longest line has 19 characters
      assert.are_same({124-(19*4+2), 6, 124, 26},
        {dialogue_manager.compute_bubble_bounds("hello world!\nmy name is girljpeg\nfourswords", vector(100, 30))})
    end)

    it('(text is too long for anything, anchor on left side) should return bubble bounds clamped on both sides', function ()
      -- longest line has 30 characters... too many to fit, it's really just to cover the weird cases
      assert.are_same({4, 18, 124, 26},
        {dialogue_manager.compute_bubble_bounds("123456789012345678901234567890", vector(20, 30))})
    end)

    it('(text is too long for anything, anchor on right side) should return bubble bounds clamped on both sides', function ()
      -- longest line has 30 characters... too many to fit, it's really just to cover the weird cases
      assert.are_same({4, 18, 124, 26},
        {dialogue_manager.compute_bubble_bounds("123456789012345678901234567890", vector(100, 30))})
    end)

  end)

end)
