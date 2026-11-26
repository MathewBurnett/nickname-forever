# Nickname Forever

## 1.0.0-beta2

- Fixed nameplates showing the real name after changing a nickname. EllesmereUI redraws a plate's name by writing back the current text, and the addon mistook that for the real name.
- Fixed a nickname that contains the player's name (e.g. "Little Siren") repeating on each redraw.
- `/nick debug` now lists the name texts on your target's nameplate and unit frames.

## 1.0.0-beta1

First public beta.

- Right-click any player (unit frames, party/raid frames, chat names, guild roster, friends list) and choose **Set Nickname**.
- Nicknames show on nameplates, in chat (including EllesmereUI Chat), on unit frames, in player tooltips, on damage meters (EllesmereUI, EnhanceQoL) and in the guild roster.
- Unit frame support: Blizzard, EllesmereUI (via the CustomNames bridge), ElvUI and Cell.
- Handles WoW Forever's two-part "First Surname" names.
- `/nick` window: grouped options, add by name, nickname list, and an info page with every slash command.
- Minimap button (on by default) and an entry in the AddOns menu next to the minimap.
- Optional "Nickname (Name)" style for chat and tooltips.

Known limits: Blizzard hides player names from addons in combat, instances, Mythic+ and PvP, so some names show unchanged there.
