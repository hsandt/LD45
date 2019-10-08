require("engine/test/bustedhelper")
local dialogue_manager = require("dialogue/dialogue_manager")

require("engine/application/constants")
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

    it('(current speaker and text set) should not error', function ()
      local d = dialogue_manager()
      d.current_speaker = speakers.pc
      d.current_text = "hello"

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

  describe('compute_bubble_bounds', function ()

    it('should return bubble bounds anchored bottom left for pc', function ()
      local anchor_bottom_left = visual_data.bubble_bottom_left_pc
      assert.are_same({anchor_bottom_left.x, anchor_bottom_left.y - (3*6+2), anchor_bottom_left.x + (19*4+2),
          anchor_bottom_left.y},
        {dialogue_manager.compute_bubble_bounds(speakers.pc, "hello world!\nmy name is girljpeg\nfourswords")})
    end)

    it('should return bubble bounds anchored bottom left for npc', function ()
    local anchor_bottom_right = visual_data.bubble_bottom_right_npc
      assert.are_same({anchor_bottom_right.x - (19*4+2), anchor_bottom_right.y - (3*6+2), anchor_bottom_right.x,
          anchor_bottom_right.y},
        {dialogue_manager.compute_bubble_bounds(speakers.npc, "hello world!\nmy name is girljpeg\nfourswords")})
    end)

  end)

  describe('say', function ()

    it('should set the current speaker and the current text', function ()
      local d = dialogue_manager()

      d:say(speakers.npc, "hello")

      assert.are_same({speakers.npc, "hello"}, {d.current_speaker, d.current_text})
    end)

  end)

end)
