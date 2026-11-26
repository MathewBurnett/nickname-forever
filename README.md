# Nickname Forever

Give any player a nickname. Right-click them, choose **Set Nickname...**, and from then on the nickname shows wherever their name normally would: nameplates, chat, unit frames, tooltips, damage meters and the guild roster.

The nickname is only seen by you, and other players are not affected. Nicknames are saved per account, so every character you play sees the same list.

Built for **WoW Forever**, including its two-part "First Surname" character names. It also works on the Retail client.

---

## Where nicknames show up

| Place | Notes |
|---|---|
| **Nameplates** | Blizzard nameplates and addon plates built on them (EllesmereUI, ElvUI). |
| **Chat** | Player names in every chat window, including EllesmereUI Chat. Messages already on screen update when you add or change a nickname. |
| **Unit frames** | Blizzard player, target, focus, target-of-target, party and raid frames. Also EllesmereUI, ElvUI and Cell. |
| **Tooltips** | The name line when you mouse over a player. Titles and class colour are kept, e.g. `Sergeant Zug (Zugzug Doug)`. Works with ElvUI tooltips. |
| **Damage meters** | EllesmereUI Damage Meters and EnhanceQoL Damage Meter. |
| **Guild roster** | The guild member list in the Communities / Guild window. |

### Addon support

- **EllesmereUI**: unit frames read nicknames directly. Turn on **Show Nicknames** in EllesmereUI's Unit Frames settings. EllesmereUI Chat, Nameplates and Damage Meters work with no setup.
- **ElvUI**: unit frames, nameplates and tooltips work with no setup, and you don't need to change any tag or text format.
- **Cell**: your nicknames take priority over Cell's own. Cell's own nickname list still covers everyone you haven't nicknamed.
- **Other addons that support CustomNames**: Nickname Forever includes a small CustomNames-compatible bridge, so any addon that reads nicknames through CustomNames (for example the CustomNames_ElvUI or CustomNames_Grid2 plugins) sees your nicknames.

---

## Usage

### Setting a nickname

1. Right-click a player. This works on their unit frame, a party or raid frame, their name in chat, the guild roster or your friends list.
2. In the **Nickname Forever** section of the menu, choose **Set Nickname...**.
3. Type the nickname and press **Save**, or press Enter.

To change or remove it later, right-click them again and choose **Edit Nickname** or **Remove Nickname**.

### The nickname window

Type `/nick`, click the **minimap button**, or pick **Nickname Forever** from the AddOns menu next to the minimap to open the list of everyone you've nicknamed. From here you can:

- **Add by name**: type a character's name (on Forever, `First Surname`) and a nickname, then press **Add**. The **Target** button fills in your current target.
- **Edit** or **remove** (X) any entry.
- Scroll the list with the mouse wheel.
- Turn each feature on or off with the checkboxes (see [Options](#options)).

The window can also be opened from **Esc → Options → AddOns → Nickname Forever**.

---

## Commands

`/nick`, `/nickname` and `/nicknames` all do the same thing.

| Command | What it does |
|---|---|
| `/nick` | Open or close the nickname window. |
| `/nick target <nickname>` | Nickname your current target. Leave the nickname blank to clear it. Short form: `/nick t`. |
| `/nick set <First Surname> = <nickname>` | Nickname a player by name. For one-word names you can skip the `=`: `/nick set Bob Bobby`. |
| `/nick remove <First Surname>` | Remove a nickname. `clear` and `del` also work. |
| `/nick list` | Print every nickname to chat. |
| `/nick minimap` | Show or hide the minimap button. |
| `/nick debug` | Print diagnostic information (see [Troubleshooting](#troubleshooting)). |

These are also listed in-game on the info page: click the **i** at the top right of the `/nick` window.

On Retail, where names are not two-part, use `Name` or `Name-Realm` instead of `First Surname`.

---

## Options

All options are checkboxes in the `/nick` window, in three groups, and are saved per account.

**Show nicknames in**

| Option | Default | What it controls |
|---|---|---|
| Chat | On | Nicknames in chat. |
| Nameplates | On | Nicknames on nameplates. |
| Unit frames | On | Blizzard, ElvUI and Cell unit frames. EllesmereUI frames are controlled by EllesmereUI's own **Show Nicknames** setting. |
| Tooltips | On | Nicknames in player tooltips. |
| Damage meters | On | EllesmereUI and EnhanceQoL damage meters. |
| Guild roster | On | The guild member list. |

**Name style**

| Option | Default | What it controls |
|---|---|---|
| Chat: "Nickname (Name)" | Off | Show `Nickname (Name)` in chat instead of just the nickname. |
| Tooltip: "Nickname (Name)" | On | Show `Nickname (Name)` in tooltips instead of just the nickname. |

**Interface**

| Option | Default | What it controls |
|---|---|---|
| Right-click menu | On | The Nickname Forever section in player right-click menus. |
| Minimap button | On | The minimap button. Drag it to move it around the minimap. |

---

## Good to know

- **In combat, and in instances, Mythic+ and PvP, some names stay real.** Blizzard hides player names from addons there, so no addon can change them. Affected names (damage meter bars, some chat lines, some frames and tooltips) show the real name and switch back to the nickname once Blizzard makes the name visible again. For damage meters that's when the meter redraws after combat.
- **Names on meters and in the guild roster are matched by text.** If two of your nicknamed characters share a first name and a meter only shows first names, neither is swapped, because it can't tell which one is meant. Full names always work.
- **The first couple of seconds of chat after logging in** may show real names while chat windows are being set up.
- **It's safe for Blizzard's UI.** Nickname Forever never replaces Blizzard's code. It only watches for text to be drawn and changes the text afterwards, so it doesn't cause "action blocked" errors.

---

## Installation

The download contains **two folders**. Both go in your AddOns folder:

```
World of Warcraft\_forever_\Interface\AddOns\NicknameForever
World of Warcraft\_forever_\Interface\AddOns\CustomNames
```

(On Retail use `_retail_` instead of `_forever_`.)

- **NicknameForever** is the addon itself.
- **CustomNames** is a small bridge that lets EllesmereUI and other CustomNames-aware addons read your nicknames. It does nothing without Nickname Forever.

**If you already have the standalone CustomNames addon installed,** it uses the same folder name, so keep only one. The bridge included here is all Nickname Forever needs.

---

## Troubleshooting

If a nickname isn't showing somewhere:

1. Make sure the matching checkbox is ticked in `/nick`. For EllesmereUI frames, also check **Show Nicknames** in EllesmereUI Unit Frames.
2. Check you're out of combat (see [Good to know](#good-to-know)).
3. Type `/reload`.
4. Still not working? Run `/nick debug` and include its output in your bug report. It shows:
   - how your target's name was read
   - whether the CustomNames bridge loaded
   - what the chat hook saw
   - whether Cell and ElvUI frames were found
   - memory and CPU use

### Performance

Nickname Forever only does work when the game or another addon draws a name, and each swap takes microseconds. Light background checks look for new chat windows, damage meter bars and guild roster rows. Memory use is typically a few hundred KB at most. `/nick debug` prints the addon's actual memory and CPU use.


## Feedback and issues

Found a bug or have an idea? Please [raise an issue on GitHub](https://github.com/MathewBurnett/nickname-forever/issues).

When reporting a bug, include the output of `/nick debug` and what you were doing at the time.

The info page (the **i** button at the top right of the `/nick` window) also lists every slash command.

---

## For addon authors

Other addons can read and write nicknames.

**Via the `Nicknames` global:**

```lua
Nicknames:Get("Proto Col")            -- nickname or nil
Nicknames:GetForUnit("target")        -- nickname or nil
Nicknames:Set("Proto Col", nil, "Boss")  -- nil / "" as the nickname removes it
Nicknames:SetForUnit("target", "Boss")
for key, entry in Nicknames:Iterate() do print(entry.name, entry.nick) end

Nicknames.RegisterCallback("MyAddon", "NICKNAME_CHANGED", function(event, key, nick, oldNick, display) end)
```

**Via CustomNames** (through the included bridge):

```lua
local CN = LibStub("CustomNames")
CN.UnitName("target")
CN.Get("Proto Col")
CN.RegisterCallback("MyAddon", "Name_Update", function(...) end)  -- also Name_Added, Name_Removed
```

---

## License

[MIT](LICENSE) © 2026 Mathew Burnett
