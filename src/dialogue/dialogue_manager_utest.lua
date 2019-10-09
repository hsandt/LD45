require("engine/test/bustedhelper")
local dialogue_manager = require("dialogue/dialogue_manager")

require("engine/application/constants")

local speaker_component = require("dialogue/speaker_component")
local visual_data = require("resources/visual_data")

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

    it('(should show bottom box) should not error', function ()
      local d = dialogue_manager()
      d.should_show_bottom_box = true
      assert.has_no_errors(function ()
        d:render()
      end)
    end)

    it('(some active speaker) should not error', function ()
      local d = dialogue_manager()

      local s = speaker_component(vector(1, 0))
      s.current_text = "hello"
      d.speakers = {s}
        d:render()

      assert.has_no_errors(function ()
        d:render()
      end)
    end)

    it('(current bottom text set) should not error', function ()
      local d = dialogue_manager()
      d.current_bottom_text = "hello"

      assert.has_no_errors(function ()
        d:render()
      end)
    end)

  end)

  describe('add_speaker', function ()

    it('should add a speaker component to the speakers', function ()
      local d = dialogue_manager()

      local s1 = speaker_component(vector(1, 0))
      local s2 = speaker_component(vector(2, 0))
      d:add_speaker(s1)
      d:add_speaker(s2)

      assert.are_same({s1, s2}, d.speakers)
    end)

  end)

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
