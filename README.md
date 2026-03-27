# BuddyFlash

**Screen flash, animated banners & custom sound alerts when your WoW friends log in.**

BuddyFlash is a World of Warcraft addon for Midnight (12.x) that alerts you instantly when your Battle.net or character friends come online or go offline. Never miss a friend's login again.

## Features

- **Screen Flash** - Full-screen color flash when tracked friends log in (configurable color)
- **Animated Banner** - Popup notification with friend name, character info, and custom avatar
- **Custom Avatars** - Assign personal images (`.tga`/`.blp`) to each friend or BattleTag
- **10+ Alert Sounds** - Choose from built-in sounds or add your own `.ogg` files
- **Per-Friend Sounds** - Different sound for each friend
- **Auto-Whisper** - Automatically whisper a message when specific friends log in
- **Login History** - Track when friends logged in/out with timestamps
- **Last Seen** - Check when a friend was last online
- **Known Alts** - Track which characters belong to each BattleTag
- **Full Settings GUI** - `/bf options` opens a complete configuration panel
- **BattleTag Support** - Assign avatars/sounds by BattleTag (covers all characters)
- **Right-Click Menu** - Invite, inspect, whisper, or target from the friends list

## Commands

| Command | Description |
|---------|-------------|
| `/bf` or `/bf help` | Show all commands |
| `/bf options` | Open settings GUI |
| `/bf toggle` | Show/hide floating friends list |
| `/bf flash` | Toggle screen flash on/off |
| `/bf sound` | Toggle sound alerts |
| `/bf sounds` | List all available sounds |
| `/bf sound <number>` | Set default alert sound |
| `/bf avatar <name> <file>` | Assign avatar image to a friend |
| `/bf whisper <name> <message>` | Set auto-whisper for a friend |
| `/bf friendsound <name> <num>` | Set per-friend alert sound |
| `/bf history [count]` | Show login history |
| `/bf lastseen <name>` | Check when a friend was last online |
| `/bf alts <BattleTag>` | Show known alts for a BattleTag |

Also works with `/fa` for backward compatibility.

## Installation

1. Download the latest release from [GitHub Releases](https://github.com/nenadjokic/BuddyFlash/releases) or [CurseForge](https://www.curseforge.com/wow/addons/buddyflash)
2. Extract `BuddyFlash/` into your `World of Warcraft/_retail_/Interface/AddOns/` folder
3. Type `/reload` in-game, then `/bf options` to configure

## Custom Avatars

Place `.tga` or `.blp` image files in `BuddyFlash/Avatars/`:
- `default.tga` - Default avatar for all friends
- `av0.tga` through `av9.tga` - Custom avatar slots

Assign with: `/bf avatar FriendName av0`

## Custom Sounds

Place `.ogg` sound files in `BuddyFlash/Sounds/`:
- `sound0.ogg` through `sound9.ogg`

They appear in the sound list automatically.

## Support

- [GitHub Issues](https://github.com/nenadjokic/BuddyFlash/issues)
- [Buy Me a Coffee](https://buymeacoffee.com/nenadjokic)
