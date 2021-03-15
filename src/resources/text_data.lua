local string_case = require("engine/core/string_case")

-- only used during offline serialization and offline print_data.lua
local text_data = {}

-- deprecated strings just contain "?"
text_data.strings = transform({

  -- # all attack strings

  --[[string_id/attack_id]]
  --[[ 1/-1]] "Uh... I'll skip this one.",
  --[[ 2/ 1]]"Already exhausted? You should really avoid staircases.",
  --[[ 3/ 2]]  "I hope your personality is not as flat as your fashion sense.",
  --[[ 4/ 3]]  "It took me a single day to find my job.",
  --[[ 5/ 4]]  "I can easily type 70 words per minute.",
  --[[ 6/ 5]]  "You couldn't write a sum formula in Excel.",
  --[[ 7/ 6]]  "Yesterday I completed all my tasks for the day under 3 hours.",
  --[[ 8/ 7]]  "Unlike you, all my neurons still work at full throttle after 6pm.",
  --[[ 9/ 8]]  "I'm so good at networking I doubled the number of my contacts in a single event.",
  --[[10/ex-9]]  "?",
  --[[11/10]] "It took me only thirty minutes to build a website for my portfolio.",
  --[[12/ex-11]] "?",
  --[[13/12]] "My devices are much more reliable than yours, they can easily last 10 years.",
  --[[14/13]] "Yesterday, I stayed focused six hours straight on my computer.",
  --[[15/14]] "I can find any book in my shelf without lifting a finger.",
  --[[16/15]] "I have so much charisma I'm getting paid just for being here.",
  --[[17/16]] "People like you can also get here now? They really lowered the bar.",
  --[[18/17]] "For my website, I set up a much better security system than yours.",
  --[[19/18]] "You couldn't install an app if I gave you a setup.exe.",
  --[[20/19]] "You should leave the hard stuff to pros with hands-on experience like me.",
  --[[21/ex-20]] "?",

  -- # all reply strings

  --[[string_id/reply_id]]
  --[[22/-1]] "Er...",
  --[[23/ 0]] "Sorry, I didn't catch this one.",
  --[[24/ 1]] "At least, mine is working.",
  --[[25/ex-2]] "?",
  --[[26/ 3]] "I knew we could count on you to make photocopies.",
  --[[27/ 4]] "I see you spent time with the coffee machine.",
  --[[28/ 5]] "Oh, I'm pretty sure you made *some* contributions toward this.",
  --[[29/ 6]] "You really can't stand physical exercise, can you?",
  --[[30/ex-7]] "?",
  --[[31/ 8]] "I see you enjoyed your time on Discord.",
  --[[32/ 9]] "Oh, I don't doubt you can. Using some third-party plugin.",
  --[[33/10]] "Well, we don't all browse at 56kbps.",
  --[[34/11]] "Sounds easy when you've only got two of them.",
  --[[35/ex-12]] "?",
  --[[36/ex-13]] "?",
  --[[37/14]] "Too bad they don't mean anything to you.",
  --[[38/15]] "Too bad yours has so little content nobody ever cared about it.",
  --[[39/16]] "And I see your relatives gave you a leg-up, uh?",
  --[[40/ex-17]] "?",
  --[[41/ex-18]] "?",
  --[[42/19]] "Probably. I'm working on Linux.",

}, string_case.to_big)

function text_data:get_string(localized_string_id)
  -- 0 means deprecated, we distinguish it from NOT FOUND
  if localized_string_id == 0 then
    return "DEPRECATED"
  else
    local localized_string = self.strings[localized_string_id]
    return localized_string or "NOT FOUND"
  end
end

return text_data
