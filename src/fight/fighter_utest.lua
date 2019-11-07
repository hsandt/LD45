require("engine/test/bustedhelper")
local fighter = require("fight/fighter")

local character_info = require("content/character_info")
local fighter_info = require("content/fighter_info")
local quote_info = require("content/quote_info")  -- for quote_types
local quote_match_info = require("content/quote_match_info")
local speaker_component = require("dialogue/speaker_component")
local fighter_progression = require("progression/fighter_progression")
local gameplay_data = require("resources/gameplay_data")
local character = require("story/character")

describe('fighter', function ()

  local mock_character_info = character_info(2, "employee", 5)
  local pos = vector(20, 60)
  local mock_character = character(mock_character_info, horizontal_dirs.right, pos)
  local mock_fighter_info = fighter_info(3, 3, 2, 5, {1, 3}, {2, 4}, {2, 4})

  local mock_fighter_progression
  local f

  before_each(function ()
    mock_fighter_progression = fighter_progression(character_types.npc, mock_fighter_info)
    add(mock_fighter_progression.known_attack_ids, 5)
    add(mock_fighter_progression.known_reply_ids, 7)
    f = fighter(mock_character, mock_fighter_progression)
  end)

  describe('_init', function ()

    it('should init a fighter with character and progression refs', function ()
      assert.are_equal(mock_character, f.character)
      assert.are_equal(mock_progression_info, f.progression_info)
    end)

    it('should init a fighter', function ()
      assert.are_same({5, nil, {}, {}, {1, 3, 5}, {2, 4, 7}},
        {f.hp, f.last_quote, f.received_attack_id_count_map, f.received_reply_id_count_map,
        f.available_attack_ids, f.available_reply_ids})
    end)

  end)

  describe('_tostring', function ()
    it('fighter(...) => "fighter(\"name\", hp={self.hp})"', function ()
      f.hp = 3
      assert.are_equal("[fighter(\"employee\", hp=3)]", f:_tostring())
    end)
  end)

  describe('get_name', function ()
    it('should return the name from the character info', function ()
      assert.are_equal("employee", f:get_name())
    end)
  end)

  -- logic

  describe('get_available_quote_ids', function ()
    it('should return sequence of all known attack ids with quote_types.attack (for now)', function ()
      del(f.available_attack_ids, 1)
      assert.are_same({3, 5}, f:get_available_quote_ids(quote_types.attack))
    end)
    it('should return sequence of all known reply ids with quote_types.reply (for now)', function ()
      del(f.available_reply_ids, 7)
      assert.are_same({2, 4}, f:get_available_quote_ids(quote_types.reply))
    end)
  end)

  describe('auto_pick_attack', function ()

    setup(function ()
      stub(_G, "pick_random", function (seq)
        -- always return last element for this test
        assert(#seq > 0)
        return seq[#seq]
      end)
    end)

    teardown(function ()
      pick_random:revert()
    end)

    after_each(function ()
      pick_random:clear()
    end)

    it('should return a random available attack using pick_random', function ()
      -- f.available_attack_ids is {1, 3, 5}
      assert.are_equal(gameplay_data.attacks[5], f:auto_pick_attack())
    end)

    it('should return a losing attack when no attack is available', function ()
      f.available_attack_ids = {}
      assert.are_equal(gameplay_data.attacks[-1], f:auto_pick_attack())
    end)

    it('should assert if no attack is available for human fighter', function ()
      f.available_attack_ids = {}
      f.fighter_progression.character_type = character_types.pc
      assert.has_error(function ()
        f:auto_pick_attack()
      end)
    end)

  end)

   describe('auto_pick_reply', function ()

    setup(function ()
      stub(_G, "pick_random", function (seq)
        -- always return last element for this test
        assert(#seq > 0)
        return seq[#seq]
      end)
    end)

    teardown(function ()
      pick_random:revert()
    end)

    after_each(function ()
      pick_random:clear()
    end)

    -- soon: return matching reply with highest power
    it('should return a matching reply', function ()
      -- this test dependson gameplay data for quote matches
      -- we use quote match 2: 1 -> 7 (power 2)
      -- f knows matches 2 and 4, so should be able to reply with 7
      -- just add 13 at the end of the reply ids so we are sure
      --   that 7 is not picked just because it's last
      f.available_reply_ids = {2, 4, 7, 13}
      assert.are_equal(gameplay_data.replies[7], f:auto_pick_reply(1))
    end)

    it('should return a random available reply using pick_random when no matching reply is known', function ()
      -- f doesn't know any matching reply for 10, so will return random one, stubbed to last
      f.available_reply_ids = {2, 4, 7, 13}
      assert.are_equal(gameplay_data.replies[13], f:auto_pick_reply(10))
    end)

    it('should return a losing reply when no reply is available', function ()
      f.available_reply_ids = {}
      assert.are_equal(gameplay_data.replies[-1], f:auto_pick_reply(1))
    end)

  end)

  describe('say_quote', function ()

    setup(function ()
      stub(speaker_component, "say")
    end)

    teardown(function ()
      speaker_component.say:revert()
    end)

    after_each(function ()
      speaker_component.say:clear()
    end)

    it('should call say on character speaker component', function ()
      local q = quote_info(3, quote_types.attack, 1, "attack 3")

      f:say_quote(q)

      local s = assert.spy(speaker_component.say)
      s.was_called(1)
      s.was_called_with(match.ref(f.character.speaker), "attack 3", false, true)
    end)

    it('should set last quote to passed quote', function ()
      local q = quote_info(3, quote_types.attack, 1, "attack 3")

      f:say_quote(q)

      assert.are_equal(q, f.last_quote)
    end)

    it('should remove an attack id from the sequence of available attack ids', function ()
      local q = quote_info(3, quote_types.attack, 2, "attack 3")

      f:say_quote(q)

      assert.are_same({1, 5}, f.available_attack_ids)
    end)

    it('should preserve available attack/reply if saying a reply', function ()
      local q = quote_info(3, quote_types.reply, 2, "reply 3")
      local q = quote_info(4, quote_types.reply, 2, "reply 4")

      f:say_quote(q)

      assert.are_same({1, 3, 5}, f.available_attack_ids)
      assert.are_same({2, 4, 7}, f.available_reply_ids)
    end)

  end)

  describe('take_damage', function ()

    it('should reduce the fighter hp', function ()
      f:take_damage(1)
      assert.are_equal(4, f.hp)
    end)

    it('should clamp the reduced hp at 0', function ()
      f:take_damage(200)
      assert.are_equal(0, f.hp)
    end)

  end)

  describe('is_alive', function ()

    it('should return true if hp > 0', function ()
      f.hp = 1
      assert.is_true(f:is_alive())
    end)

    it('should return true if hp <= 0', function ()
      f.hp = 0
      assert.is_false(f:is_alive())
    end)

  end)

  describe('on_receive_quote', function ()

    it('should not increment count for known quote', function ()
      f.fighter_progression.known_attack_ids = {3}
      f:on_receive_quote(quote_info(3, quote_types.attack, 1, "attack 3"))
      assert.are_same({}, f.received_attack_id_count_map)
    end)

    it('should not increment count for losing quote', function ()
      f.fighter_progression.known_attack_ids = {}
      f:on_receive_quote(quote_info(-1, quote_types.attack, 0, "losing attack"))
      assert.are_same({}, f.received_attack_id_count_map)
    end)

    it('should not increment count for quotes at 1+ levels above fighter level', function ()
      f.fighter_progression.known_attack_ids = {}
      -- level 3 attack vs fighter level 2
      f:on_receive_quote(quote_info(7, quote_types.attack, 3, "attack 7"))
      assert.are_same({}, f.received_attack_id_count_map)
    end)

    it('should initialize reception count of new learnable attack to 1', function ()
      -- level 2 quote can be learned
      f:on_receive_quote(quote_info(6, quote_types.attack, 2, "attack 6"))
      assert.are_same({[6] = 1}, f.received_attack_id_count_map)
    end)

    it('should initialize reception count of new learnable reply to 1', function ()
      f:on_receive_quote(quote_info(8, quote_types.reply, 1, "reply 8"))
      assert.are_same({[8] = 1}, f.received_reply_id_count_map)
    end)

    it('should increment reception count of received attack by 1', function ()
      f.received_attack_id_count_map[8] = 10
      f:on_receive_quote(quote_info(8, quote_types.attack, 1, "attack 8"))
      assert.are_same({[8] = 11}, f.received_attack_id_count_map)
    end)

    it('should increment reception count of received reply by 1', function ()
      f.received_reply_id_count_map[8] = 10
      f:on_receive_quote(quote_info(8, quote_types.reply, 1, "reply 8"))
      assert.are_same({[8] = 11}, f.received_reply_id_count_map)
    end)

  end)

  describe('on_witness_quote_match', function ()

    setup(function ()
      stub(fighter_progression, "try_learn_quote_match")
    end)

    teardown(function ()
      fighter_progression.try_learn_quote_match:revert()
    end)

    it('should let fighter progression try to learn quote by id', function ()
      f.fighter_progression.known_quote_match_ids = {3}
      f:on_witness_quote_match(quote_match_info(11,  6,  3, 3))

      local s = assert.spy(fighter_progression.try_learn_quote_match)
      s.was_called(1)
      s.was_called_with(match.ref(f.fighter_progression), 11)
    end)

  end)

  describe('update_learned_quotes', function ()

    setup(function ()
      stub(fighter_progression, "transfer_received_attack_id_count_map")
      stub(fighter_progression, "transfer_received_reply_id_count_map")
    end)

    teardown(function ()
      fighter_progression.transfer_received_attack_id_count_map:revert()
      fighter_progression.transfer_received_reply_id_count_map:revert()
    end)

    after_each(function ()
      fighter_progression.transfer_received_attack_id_count_map:clear()
      fighter_progression.transfer_received_reply_id_count_map:clear()
    end)

    it('should call transfer_received_attack_id_count_map with self.received_attack_id_count_map', function ()
      f:update_learned_quotes()

      local s = assert.spy(fighter_progression.transfer_received_attack_id_count_map)
      s.was_called(1)
      s.was_called_with(match.ref(f.fighter_progression), match.ref(f.received_attack_id_count_map))
    end)

    it('should call transfer_received_reply_id_count_map with self.received_reply_id_count_map', function ()
      f:update_learned_quotes()

      local s = assert.spy(fighter_progression.transfer_received_reply_id_count_map)
      s.was_called(1)
      s.was_called_with(match.ref(f.fighter_progression), match.ref(f.received_reply_id_count_map))
    end)

  end)

  describe('update', function ()

    setup(function ()
      stub(character, "update")
    end)

    teardown(function ()
      character.update:revert()
    end)

    after_each(function ()
      character.update:clear()
    end)

    it('should call animated sprite update', function ()
      f:update()

      local s = assert.spy(character.update)
      s.was_called(1)
      s.was_called_with(match.ref(f.character))
    end)

  end)

  -- render

  describe('draw', function ()

    setup(function ()
      stub(character, "draw")
    end)

    teardown(function ()
      character.draw:revert()
    end)

    after_each(function ()
      character.draw:clear()
    end)

    it('should call animated sprite draw', function ()
      f:draw()

      local s = assert.spy(character.draw)
      s.was_called(1)
      s.was_called_with(match.ref(f.character))
    end)

  end)

end)
