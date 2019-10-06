require("engine/test/bustedhelper")
local wit_fight = require("fight/wit_fight")

local ui = require("engine/ui/ui")

local floor_info = require("content/floor_info")
local npc_info = require("content/npc_info")
local quote_info = require("content/quote_info")
local text_menu = require("menu/text_menu")
local gameplay_data = require("resources/gameplay_data")

describe('wit_fight', function ()

  local state

  before_each(function ()
    state = wit_fight()
  end)

  describe('init', function ()

    it('should create an empty quote menu component, aligned left', function ()
      assert.is_not_nil(text_menu, state.quote_menu)
      assert.are_same({{}, alignments.left}, {state.quote_menu.items, state.quote_menu.alignment})
    end)

    it('should initialize other members', function ()
      assert.are_same({1, nil, nil, nil}, {state.floor_number, state.npc_info, state.pc_quote, state.npc_quote})
    end)

  end)

  describe('on_enter', function ()

    setup(function ()
      stub(wit_fight, "start_fight_with_random_npc")
    end)

    teardown(function ()
      wit_fight.start_fight_with_random_npc:revert()
    end)

    after_each(function ()
      wit_fight.start_fight_with_random_npc:clear()
    end)

    it('should call start_fight_with_random_npc', function ()
      state:on_enter()

      local s = assert.spy(wit_fight.start_fight_with_random_npc)
      s.was_called(1)
      s.was_called_with(match.ref(state))
    end)

  end)

  describe('update', function ()

    setup(function ()
      stub(text_menu, "update")
    end)

    teardown(function ()
      text_menu.update:revert()
    end)

    after_each(function ()
      text_menu.update:clear()
    end)

    it('should update the quote menu', function ()
      state:update()

      local s = assert.spy(text_menu.update)
      s.was_called(1)
      s.was_called_with(match.ref(state.quote_menu))
    end)

  end)

  describe('render', function ()

    setup(function ()
      stub(wit_fight, "draw_background")
      stub(wit_fight, "draw_characters")
      stub(wit_fight, "draw_hud")
    end)

    teardown(function ()
      wit_fight.draw_background:revert()
      wit_fight.draw_characters:revert()
      wit_fight.draw_hud:revert()
    end)

    after_each(function ()
      wit_fight.draw_background:clear()
      wit_fight.draw_characters:clear()
      wit_fight.draw_hud:clear()
    end)

    it('should call draw background, characters, hud', function ()
      state:render()

      local s = assert.spy(wit_fight.draw_background)
      s.was_called(1)
      s.was_called_with(match.ref(state))

      local s = assert.spy(wit_fight.draw_characters)
      s.was_called(1)
      s.was_called_with(match.ref(state))

      local s = assert.spy(wit_fight.draw_hud)
      s.was_called(1)
      s.was_called_with(match.ref(state))
    end)

  end)

  describe('start_fight_with_random_npc', function ()

    local mock_npc_info = npc_info(8, "employee", 4, {11, 27})

    setup(function ()
      stub(wit_fight, "pick_non_recent_random_npc_info", function (self)
        return mock_npc_info
      end)
      stub(wit_fight, "start_fight_with")
    end)

    teardown(function ()
      wit_fight.pick_non_recent_random_npc_info:revert()
      wit_fight.start_fight_with:revert()
    end)

    after_each(function ()
      wit_fight.pick_non_recent_random_npc_info:clear()
      wit_fight.start_fight_with:clear()
    end)

    it('should call start_fight_with with random npc id', function ()
      state:start_fight_with_random_npc()

      local s = assert.spy(wit_fight.start_fight_with)
      s.was_called(1)
      s.was_called_with(match.ref(state), mock_npc_info)
    end)

  end)

  describe('pick_non_recent_random_npc_info', function ()

    local mock_npc_info = npc_info(8, "employee", 4, {11, 27})

    setup(function ()
      stub(wit_fight, "get_candidate_npc_info_sequence", function (self)
        return {{}, {}, mock_npc_info}
      end)
      stub(_G, "random_int_range_exc", function (range)
        return range - 1
      end)
    end)

    teardown(function ()
      wit_fight.get_candidate_npc_info_sequence:revert()
      random_int_range_exc:revert()
    end)

    it('should pick a random npc info among the possible npc levels at the current floor', function ()
      assert.are_equal(mock_npc_info, state:pick_non_recent_random_npc_info())
    end)

  end)

  describe('get_candidate_npc_info_sequence', function ()

    setup(function ()
      stub(gameplay_data, "get_floor_info", function (self, floor_number)
        -- hypothetical npc levels related to floor number
        return floor_info(floor_number, floor_number - 1, floor_number + 1)
      end)
      stub(gameplay_data, "get_npc_info_table_with_level", function (self, level)
        -- we are going to return different npcs with the same ids, but we don't care about ids in this test anyway
        return {npc_info(1, "mock1", level, {}), npc_info(2, "mock2", level, {}), npc_info(3, "mock3", level, {})}
      end)
    end)

    teardown(function ()
      gameplay_data.get_floor_info:revert()
      gameplay_data.get_npc_info_table_with_level:revert()
    end)

    it('should pick a random npc info among the possible npc levels at the current floor', function ()
      -- we set the current floor to 3, so npc levels should be 2 to 4
      state.floor_number = 3
      -- we don't go into details but we should have 3 * 3 mock npc infos now, spread on 3 levels
      -- we just check that we have 9 of them
      assert.are_equal(9, #state:get_candidate_npc_info_sequence())
    end)

  end)

  describe('start_fight_with', function ()

    local mock_npc_info = npc_info(8, "employee", 4, {11, 27})

    setup(function ()
    end)

    teardown(function ()
    end)

    after_each(function ()
    end)

    it('should set the current npc info', function ()
      state:start_fight_with(mock_npc_info)

      assert.are_equal(mock_npc_info, state.npc_info)
    end)

  end)

  describe('pc_say_quote', function ()

    local mock_quote_info = quote_info(7, 4, quote_types.reply, "mock quote")

    setup(function ()
    end)

    teardown(function ()
    end)

    after_each(function ()
    end)

    it('should set the pc quote and reset the npc quote', function ()
      state.npc_quote = mock_quote_info

      state:pc_say_quote(mock_quote_info)

      assert.are_equal(mock_quote_info, state.pc_quote)
      assert.is_nil(state.npc_quote)
    end)

  end)

  describe('npc_say_quote', function ()

    local mock_quote_info = quote_info(7, 4, quote_types.reply, "mock quote")

    setup(function ()
    end)

    teardown(function ()
    end)

    after_each(function ()
    end)

    it('should set the npc quote and reset the pc quote', function ()
      state.pc_quote = mock_quote_info

      state:npc_say_quote(mock_quote_info)

      assert.are_equal(mock_quote_info, state.npc_quote)
      assert.is_nil(state.pc_quote)
    end)

  end)

  describe('draw_background', function ()
    it('should not error', function ()
      assert.has_no_errors(function ()
        state:draw_background()
      end)
    end)
  end)

  describe('draw_characters', function ()

    local mock_npc_info = npc_info(7, "employee", 4, {11, 27})

    it('should not error', function ()
      assert.has_no_errors(function ()
        state:draw_characters()
      end)
    end)

    it('should not error with npc info set', function ()
      state.npc_info = mock_npc_info

      assert.has_no_errors(function ()
        state:draw_characters()
      end)
    end)

  end)

  describe('draw_hud', function ()

    it('should not error', function ()
      assert.has_no_errors(function ()
        state:draw_hud()
      end)
    end)

  end)

  describe('draw_floor_number', function ()

    it('should not error', function ()
      assert.has_no_errors(function ()
        state:draw_floor_number()
      end)
    end)

  end)

  describe('draw_quote_bubble', function ()

    local mock_quote_info = quote_info(7, 4, quote_types.reply, "mock quote")

    it('should not error', function ()
      assert.has_no_errors(function ()
        state:draw_hud()
      end)
    end)

    it('should not error with pc quote set', function ()
      state.pc_quote = mock_quote_info

      assert.has_no_errors(function ()
        state:draw_quote_bubble()
      end)
    end)

    it('should not error with npc quote set', function ()
      state.npc_quote = mock_quote_info

      assert.has_no_errors(function ()
        state:draw_quote_bubble()
      end)
    end)

  end)

  describe('draw_health_bars', function ()

    it('should not error', function ()
      assert.has_no_errors(function ()
        state:draw_health_bars()
      end)
    end)

  end)

  describe('draw_bottom_box', function ()

    it('should not error', function ()
      assert.has_no_errors(function ()
        state:draw_bottom_box()
      end)
    end)

  end)

  describe('draw_npc_label', function ()

    local mock_npc_info = npc_info(7, "employee", 4, {11, 27})

    it('should not error', function ()
      assert.has_no_errors(function ()
        state:draw_npc_label()
      end)
    end)

    it('should not error with npc info set', function ()
      state.npc_info = mock_npc_info

      assert.has_no_errors(function ()
        state:draw_npc_label()
      end)
    end)

  end)

end)
