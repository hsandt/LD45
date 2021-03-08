local string_case = require("engine/core/string_case")

local text_data = {}

text_data.skip_attack_string = string_case.to_big("Uh... I'll skip this one.")

-- deprecated strings just contain "?"
text_data.attack_strings = transform({
  --[[1]] "Already exhausted? You should really avoid staircases.",
  --[[2]]  "I hope your personality is not as flat as your fashion sense.",
  --[[3]]  "It took me a single day to find my job.",
  --[[4]]  "I can easily type 70 words per minute.",
  --[[5]]  "You couldn't write a sum formula in Excel.",
  --[[6]]  "Yesterday I completed all my tasks for the day under 3 hours.",
  --[[7]]  "Unlike you, all my neurons still work at full throttle after 6pm.",
  --[[8]]  "I'm so good at networking I doubled the number of my contacts in a single event.",
  --[[9]]  "?",
  --[[10]] "It took me only thirty minutes to build a website for my portfolio.",
  --[[11]] "?",
  --[[12]] "My devices are much more reliable than yours, they can easily last 10 years.",
  --[[13]] "Yesterday, I stayed focused six hours straight on my computer.",
  --[[14]] "I can find any book in my shelf without lifting a finger.",
  --[[15]] "I have so much charisma I'm getting paid just for being here.",
  --[[16]] "People like you can also get here now? They really lowered the bar.",
  --[[17]] "For my website, I set up a much better security system than yours.",
  --[[18]] "You couldn't install an app if I gave you a setup.exe.",
  --[[19]] "You should leave the hard stuff to pros with hands-on experience like me.",
  --[[20]] "?",
}, string_case.to_big)

text_data.losing_reply_string = string_case.to_big("Er...")

-- deprecated strings just contain "?"
text_data.reply_strings = transform({
  --[[ 1]] "At least, mine is working.",
  --[[ 2]] "?",
  --[[ 3]] "I knew we could count on you to make photocopies.",
  --[[ 4]] "I see you spent time with the coffee machine.",
  --[[ 5]] "Oh, I'm pretty sure you made *some* contributions toward this.",
  --[[ 6]] "You really can't stand physical exercise, can you?",
  --[[ 7]] "?",
  --[[ 8]] "I see you enjoyed your time on Discord.",
  --[[ 9]] "Oh, I don't doubt you can. Using some third-party plugin.",
  --[[10]] "Well, we don't all browse at 56kbps.",
  --[[11]] "Sounds easy when you've only got two of them.",
  --[[12]] "?",
  --[[13]] "?",
  --[[14]] "Too bad they don't mean anything to you.",
  --[[15]] "Too bad yours has so little content nobody ever cared about it.",
  --[[16]] "And I see your relatives gave you a leg-up, uh?",
  --[[17]] "?",
  --[[18]] "?",
  --[[19]] "Probably. I'm working on Linux.",
}, string_case.to_big)

return text_data
