require("engine/test/bustedhelper")
local character = require("story/character")

require("engine/core/math")
local animated_sprite = require("engine/render/animated_sprite")

local character_info = require("content/character_info")
local speaker_component = require("dialogue/speaker_component")
local visual_data = require("resources/visual_data")

describe('character', function ()

  -- sprites character [8] must exist in visual_data
  local mock_character_info = character_info(2, "employee", 5)
  local pos = vector(20, 60)

  local c

  before_each(function ()
    c = character(mock_character_info, horizontal_dirs.right, pos)
  end)

  describe('_init', function ()
    it('should init a character', function ()
      assert.are_equal(mock_character_info, c.character_info)
      assert.are_equal(visual_data.anim_sprites.character[5], c.sprite.data_table)
      local rel_bubble_tail_pos = visual_data.rel_bubble_tail_pos_by_horizontal_dir[horizontal_dirs.right]
      assert.are_same({
          speaker_component(pos + rel_bubble_tail_pos),
          pos
        },
        {c.speaker, c.pos})
    end)
  end)

  describe('register_speaker', function ()

    local fake_dialogue_mgr = {}
    fake_dialogue_mgr.add_speaker = spy.new()

    it('should add speaker to passed dialogue manager', function ()
      c:register_speaker(fake_dialogue_mgr)

      local s = assert.spy(fake_dialogue_mgr.add_speaker)
      s.was_called(1)
      s.was_called_with(match.ref(fake_dialogue_mgr), match.ref(c.speaker))
    end)

  end)

  describe('unregister_speaker', function ()

    local fake_dialogue_mgr = {}
    fake_dialogue_mgr.remove_speaker = spy.new()

    it('should remove speaker from passed dialogue manager', function ()
      c:unregister_speaker(fake_dialogue_mgr)

      local s = assert.spy(fake_dialogue_mgr.remove_speaker)
      s.was_called(1)
      s.was_called_with(match.ref(fake_dialogue_mgr), match.ref(c.speaker))
    end)

  end)

  describe('draw', function ()

    setup(function ()
      stub(animated_sprite, "render")
    end)

    teardown(function ()
      animated_sprite.render:revert()
    end)

    after_each(function ()
      animated_sprite.render:clear()
    end)

    it('(facing left) should call render with current pos, flipped x', function ()
      c.pos = vector(5, 10)
      c.direction = horizontal_dirs.left

      c:draw()

      local s = assert.spy(animated_sprite.render)
      s.was_called(1)
      s.was_called_with(match.ref(c.sprite), vector(5, 10), true)
    end)

    it('(facing right) should call render with current pos, not flipped x', function ()
      c.pos = vector(5, 10)
      c.direction = horizontal_dirs.right

      c:draw()

      local s = assert.spy(animated_sprite.render)
      s.was_called(1)
      s.was_called_with(match.ref(c.sprite), vector(5, 10), false)
    end)

  end)

end)
