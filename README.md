# Morrowind-TES3MP-0.8.1-plugins
My pack of Morrowind serverside Lua plugins for TES3MP 0.8.1

FailedAttemptExperience:
- Grants XP upon failed actions for Security, Armorer, Enchant, Alchemy, Persuasion*
- Grants XP on any successful barter with a merchant (including non-bargains)

Known issues:
- Bonus XP can overflow past 100 progress without triggering a skillup. XP granted from successful actions will trigger a skillup as expected.
- Persuasion XP is granted upon opening the Persuasion submenu (I couldn't find an event on any Persuasion action/Disposition change)