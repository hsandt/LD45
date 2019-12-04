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

  local mock_pc_info = character_info(0, "you", 0)
  local mock_npc_info = character_info(2, "employee", 2)
  local pos = vector(20, 60)
  local mock_pc = character(mock_pc_info, horizontal_dirs.right, pos)
  local mock_npc = character(mock_npc_info, horizontal_dirs.left, pos)
  -- normally pc has level 10 to learn anything instantly, but since we deactivated
  -- AI learning, we can nly test the feature on pc, so we set some mid-level to check
  -- that progressive learning works correctly; but in practice, it's just instant
  local mock_pc_fighter_info = fighter_info(0, 0, 2, 3, {1, 3}, {2, 4})
  local mock_npc_fighter_info = fighter_info(3, 3, 2, 5, {1, 3}, {2, 4})

  local mock_pc_fighter_progression
  local mock_npc_fighter_progression
  local pcf
  local f

  before_each(function ()
    mock_pc_fighter_progression = fighter_progression(character_types.pc, mock_pc_fighter_info)
    add(mock_pc_fighter_progression.known_attack_ids, 5)
    add(mock_pc_fighter_progression.known_reply_ids, 7)

    mock_npc_fighter_progression = fighter_progression(character_types.npc, mock_npc_fighter_info)
    add(mock_npc_fighter_progression.known_attack_ids, 5)
    add(mock_npc_fighter_progression.known_reply_ids, 7)

    pcf = fighter(mock_pc, mock_pc_fighter_progression)
    f = fighter(mock_npc, mock_npc_fighter_progression)
  end)

  describe('_init', function ()

    it('should init a fighter with character and progression refs', function ()
      assert.are_equal(mock_npc, f.character)
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
      stub(gameplay_data, "get_quote_match_with_id", function (self, attack_id, reply_id)
        if attack_id == 1 and reply_id == 2 then
          return quote_match_info(100, 1, 2, 99)
        elseif attack_id == 3 and reply_id == 4 then
          return quote_match_info(100, 3, 4, 99)
        elseif attack_id == 5 and reply_id == 7 then
          return quote_match_info(100, 5, 7, 99)
        else
          return nil
        end
      end)
    end)

    teardown(function ()
      pick_random:revert()
      gameplay_data.get_quote_match_with_id:revert()
    end)

    after_each(function ()
      pick_random:clear()
      gameplay_data.get_quote_match_with_id:clear()
    end)

    it('(npc) should return a random available attack using pick_random', function ()
      -- f.available_attack_ids is {1, 3, 5}
      assert.are_equal(gameplay_data.attacks[5], f:auto_pick_attack())
    end)

    it('(npc) should assert when no attack is available', function ()
      f.available_attack_ids = {}
      assert.has_error(function ()
        f:auto_pick_attack()
      end)
    end)

    it('(pc, knows all replies) should return a random available attack using pick_random', function ()
      -- pcf.available_attack_ids is {1, 3, 5}
      -- pcf.fighter_progression.known_reply_ids is {2, 4, 7}
      -- we stubbed get_quote_match_with_id so that A1 => R2, A3 => R4, A5 => R7
      --   so in the current situation, pc knows all replies to his own attacks
      --   therefore he just picks random (stubbed to last)
      assert.are_equal(gameplay_data.attacks[5], pcf:auto_pick_attack())
    end)

    it('(pc, misses replies) should return a random attack among those with no known replies', function ()
      -- pcf.available_attack_ids is {1, 3, 5}
      pcf.fighter_progression.known_reply_ids = {7}
      -- so A1 and A3 have no known replies, pick randomly one (stubbed to last)
      assert.are_equal(gameplay_data.attacks[3], pcf:auto_pick_attack())
    end)

    it('(pc) should assert if no attack is available', function ()
      pcf.available_attack_ids = {}
      assert.has_error(function ()
        pcf:auto_pick_attack()
      end)
    end)

  end)

   describe('auto_pick_reply', function ()

    local original_npc_random_reply_fallback = gameplay_data.npc_random_reply_fallback

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

    it('should return a random matching reply', function ()
      -- ! test is gameplay_data-dependent for quote matches !
      -- attack 1 can be replied with replies 6, 14 or 16, but f only knows R6
      -- just add 13 at the end of the reply ids so we are sure
      --   that 6 is not picked just because it's last
      f.available_reply_ids = {2, 4, 6, 13}
      assert.are_equal(gameplay_data.replies[6], f:auto_pick_reply(1))
    end)

    it('should assert if no reply is available', function ()
      f.available_reply_ids = {}
      assert.has_error(function ()
        f:auto_pick_reply(1)
      end)
    end)

    describe('(npc_random_reply_fallback: true)', function ()

      before_each(function ()
        gameplay_data.npc_random_reply_fallback = true
      end)

      after_each(function ()
        gameplay_data.npc_random_reply_fallback = original_npc_random_reply_fallback
      end)

      it('should return a losing reply when no matching reply is known', function ()
        -- ! test is gameplay_data-dependent for quote matches !
        -- f doesn't know any matching reply for 10 (neither R1, R5, R9, R15),
        -- so will return random one, stubbed to last
        f.available_reply_ids = {2, 4, 7, 13}
        assert.are_equal(gameplay_data.replies[13], f:auto_pick_reply(10))
      end)

    end)

    describe('(npc_random_reply_fallback: false)', function ()

      before_each(function ()
        gameplay_data.npc_random_reply_fallback = false
      end)

      after_each(function ()
        gameplay_data.npc_random_reply_fallback = original_npc_random_reply_fallback
      end)

      it('should return a losing reply when no matching reply is known', function ()
        -- ! test is gameplay_data-dependent for quote matches !
        -- f doesn't know any matching reply for 10 (neither R5, R9, R15),
        -- so will return losing one (-1)
        f.available_reply_ids = {2, 4, 7, 13}
        assert.are_equal(gameplay_data.replies[-1], f:auto_pick_reply(10))
      end)

    end)

  end)

  describe('preview_quote', function ()

    setup(function ()
      stub(speaker_component, "think")
    end)

    teardown(function ()
      speaker_component.think:revert()
    end)

    after_each(function ()
      speaker_component.think:clear()
    end)

    it('should call think on character speaker component', function ()
      local q = quote_info(3, quote_types.attack, 1, "attack 3")

      f:preview_quote(q)

      local s = assert.spy(speaker_component.think)
      s.was_called(1)
      s.was_called_with(match.ref(f.character.speaker), "attack 3", false, true)
    end)

  end)

  describe('say_quote', function ()

    local original_consume_reply = gameplay_data.consume_reply

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

    describe('(consume_reply: true)', function ()

      before_each(function ()
        gameplay_data.consume_reply = true
      end)

      after_each(function ()
        gameplay_data.consume_reply = original_consume_reply
      end)

      it('should remove an attack id from the sequence of available attack ids', function ()
        local q = quote_info(4, quote_types.reply, 2, "reply 4")

        f:say_quote(q)

        assert.are_same({2, 7}, f.available_reply_ids)
      end)

    end)

    describe('(consume_reply: false)', function ()

        before_each(function ()
          gameplay_data.consume_reply = false
        end)

        after_each(function ()
          gameplay_data.consume_reply = original_consume_reply
        end)

      it('should preserve available reply if saying a reply', function ()
        local q = quote_info(4, quote_types.reply, 2, "reply 4")

        f:say_quote(q)

        assert.are_same({2, 4, 7}, f.available_reply_ids)
      end)

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

    it('npc should never increment count for even new quotes', function ()
      -- level 2 quote can be learned
      f:on_receive_quote(quote_info(6, quote_types.attack, 2, "attack 6"))
      assert.are_same({}, f.received_attack_id_count_map)
    end)

    it('pc should not increment count for known quote', function ()
      pcf.fighter_progression.known_attack_ids = {3}
      pcf:on_receive_quote(quote_info(3, quote_types.attack, 1, "attack 3"))
      assert.are_same({}, pcf.received_attack_id_count_map)
    end)

    it('pc should not increment count for losing quote', function ()
      pcf.fighter_progression.known_attack_ids = {}
      pcf:on_receive_quote(quote_info(-1, quote_types.attack, 0, "losing attack"))
      assert.are_same({}, pcf.received_attack_id_count_map)
    end)

    it('pc should not increment count for quotes at 1+ levels above fighter level', function ()
      pcf.fighter_progression.known_attack_ids = {}
      -- level 3 attack vs fighter level 2
      pcf:on_receive_quote(quote_info(7, quote_types.attack, 3, "attack 7"))
      assert.are_same({}, pcf.received_attack_id_count_map)
    end)

    it('should initialize reception count of new learnable attack to 1', function ()
      -- level 2 quote can be learned
      pcf:on_receive_quote(quote_info(6, quote_types.attack, 2, "attack 6"))
      assert.are_same({[6] = 1}, pcf.received_attack_id_count_map)
    end)

    it('should initialize reception count of new learnable reply to 1', function ()
      pcf:on_receive_quote(quote_info(8, quote_types.reply, 1, "reply 8"))
      assert.are_same({[8] = 1}, pcf.received_reply_id_count_map)
    end)

    it('should increment reception count of received attack by 1', function ()
      pcf.received_attack_id_count_map[8] = 10
      pcf:on_receive_quote(quote_info(8, quote_types.attack, 1, "attack 8"))
      assert.are_same({[8] = 11}, pcf.received_attack_id_count_map)
    end)

    it('should increment reception count of received reply by 1', function ()
      pcf.received_reply_id_count_map[8] = 10
      pcf:on_receive_quote(quote_info(8, quote_types.reply, 1, "reply 8"))
      assert.are_same({[8] = 11}, pcf.received_reply_id_count_map)
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
      f:on_witness_quote_match(quote_match_info(11, 6, 3, 3))

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
      stub(fighter, "draw_health_bar")
      stub(fighter, "draw_name_label")
    end)

    teardown(function ()
      character.draw:revert()
      fighter.draw_health_bar:revert()
      fighter.draw_name_label:revert()
    end)

    after_each(function ()
      character.draw:clear()
      fighter.draw_health_bar:clear()
      fighter.draw_name_label:clear()
    end)

    it('should call animated sprite draw', function ()
      f:draw()

      local s = assert.spy(character.draw)
      s.was_called(1)
      s.was_called_with(match.ref(f.character))

      s = assert.spy(fighter.draw_health_bar)
      s.was_called(1)
      s.was_called_with(match.ref(f))

      s = assert.spy(fighter.draw_name_label)
      s.was_called(1)
      s.was_called_with(match.ref(f))
    end)

  end)

end)
