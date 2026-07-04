# Morrowind-TES3MP-0.8.1-plugins
My pack of Morrowind serverside Lua plugins for TES3MP 0.8.1

FailedAttemptExperience:
- Grants XP upon failed actions for Security, Armorer, Enchant, Alchemy, Persuasion*
- Grants XP on any successful barter with a merchant (including non-bargains)
Config options:
`skillGrantEnabled`: Enable/disable for certain skills.
`progressGrant`: XP values to grant upon failed actions. This is not 1-1 with the ingame 0/100 progress meter, as far as I know.
`debugChatGains`: Enable chat debug messages.

Known issues:
- Bonus XP can overflow past 100 progress without triggering a skillup. XP granted from successful actions will trigger a skillup as expected.
- Persuasion XP is granted upon opening the Persuasion submenu (I couldn't find an event on any Persuasion action/Disposition change)