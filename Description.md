# BuddyFlash — Never Miss a Friend's Login Again

BuddyFlash makes sure you always know when your friends are online. Get instant screen flashes, animated banners with custom avatars, and personalized alert sounds the moment your Battle.net or character friends log in.

## Why BuddyFlash?

Other friend notification addons give you a chat message or a tiny toast. BuddyFlash goes further:

| Feature | BuddyFlash | FriendAlerts | Battle.net Friend Alert | SocialToasts |
|---------|:----------:|:------------:|:-----------------------:|:------------:|
| Screen flash effect | ✅ | ❌ | ❌ | ❌ |
| Animated banner popup | ✅ | ❌ | ❌ | ✅ |
| **Custom avatar images** | ✅ | ❌ | ❌ | ❌ |
| **Custom sound files** | ✅ | ❌ | ❌ | ❌ |
| Per-friend sounds | ✅ | ❌ | ❌ | ❌ |
| Auto-whisper on login | ✅ | ❌ | ❌ | ❌ |
| Login history log | ✅ | ❌ | ❌ | ❌ |
| Last seen tracker | ✅ | ❌ | ❌ | ❌ |
| BattleTag alt tracking | ✅ | ❌ | ❌ | ❌ |
| Full settings GUI | ✅ | ❌ | ❌ | ✅ |

**The killer feature:** You can use your own images and your own sounds. Put a photo of your guildmate as their avatar. Use a funny sound clip when your raid leader logs in. No other addon lets you do this.

## ✨ Key Features

- **Screen Flash** — Full-screen color flash when tracked friends log in. Customizable flash color.
- **Animated Banner** — Beautiful popup notification showing friend name, character, realm, and their custom avatar.
- **Custom Avatars** — Assign your own images to each friend. Use real photos, memes, class icons, anything.
- **Custom Sounds** — Add your own .ogg sound files. Use voice clips, memes, music, anything you want.
- **Per-Friend Sounds** — Different alert for each friend. Know who logged in without looking at the screen.
- **Auto-Whisper** — Automatically send a custom message when specific friends log in. Great for raid leaders.
- **Login History** — Complete log of friend logins and logouts with timestamps.
- **Last Seen** — Check when any friend was last online.
- **Known Alts** — Track which characters belong to each BattleTag.
- **BattleTag Support** — Assign avatars, sounds, and whispers by BattleTag (covers all their characters automatically).
- **Full Settings GUI** — Complete options panel with sliders, dropdowns, and previews via `/bf options`.
- **Right-Click Menu** — Invite, inspect, whisper, or target friends directly from the notification banner.

## 📋 Commands

```
/bf                          Show all commands
/bf options                  Open settings GUI
/bf toggle                   Show/hide floating friends list
/bf flash                    Toggle screen flash on/off
/bf sound                    Toggle sound alerts
/bf sound <number>           Set default alert sound
/bf avatar <name> <file>     Assign avatar image to a friend
/bf whisper <name> <msg>     Set auto-whisper message
/bf friendsound <name> <num> Set per-friend sound
/bf history [count]          Show login history
/bf lastseen <name>          When was a friend last online?
/bf alts <BattleTag>         Show known alts
```

## 📦 Installation

1. Download BuddyFlash.zip
2. Extract into `World of Warcraft/_retail_/Interface/AddOns/`
3. Type `/reload` in-game
4. Type `/bf options` to configure

Compatible with WoW: Midnight (12.x). Works with all classes and races.

---

## 🎨 Customize Avatars and Sounds

This is what makes BuddyFlash unique. You can create your own avatar images and alert sounds for each friend. Here's exactly how to do it.

### Custom Avatars — Step by Step

BuddyFlash displays a small portrait image next to your friend's name when they log in. You can replace the default icon with any image you want — a real photo, a drawing, a meme, a class icon, anything.

**What you need:** A `.tga` image file (WoW's native image format).

**How to create a .tga avatar:**

1. **Start with any image** — JPG, PNG, screenshot, photo, anything.
2. **Resize to 64x64 pixels** (or 128x128 for higher quality). It must be square.
   - **Free online tool:** Go to [ezgif.com/resize](https://ezgif.com/resize), upload your image, set width and height to 64, click Resize.
   - **Photoshop/GIMP:** Image → Image Size → 64x64 → Save As TGA.
   - **Paint.net (free, Windows):** Image → Resize → 64x64 → Save As → TGA.
3. **Save as `.tga` format:**
   - If your tool can't save TGA, use [convertio.co](https://convertio.co/png-tga/) to convert PNG → TGA for free.
   - **Important:** The file MUST be `.tga` or `.blp` format. WoW cannot load `.jpg` or `.png` directly.
4. **Name your file** — Use simple names without spaces: `john.tga`, `raidlead.tga`, `healer.tga`
5. **Copy the file** into your addon folder:
   ```
   World of Warcraft/_retail_/Interface/AddOns/BuddyFlash/Avatars/
   ```
6. **Assign it in-game:**
   ```
   /bf avatar FriendName john
   ```
   Or assign by BattleTag (covers all their characters):
   ```
   /bf avatar Nickname#1234 john
   ```
7. **Reload UI:** Type `/reload` for the new avatar to take effect.

**Avatar slots included:**
- `default.tga` — Shows for all friends who don't have a custom avatar assigned
- `av0.tga` through `av9.tga` — 10 pre-made slots you can replace with your own images

**Tips:**
- Square images look best (64x64 or 128x128)
- Keep file sizes small (under 100KB) for fast loading
- Use descriptive filenames so you remember who is who
- You can have as many avatar files as you want — just add more `.tga` files to the Avatars folder

---

### Custom Sounds — Step by Step

Every friend can have their own unique login sound. You can use voice clips, meme sounds, music snippets, or anything you want.

**What you need:** An `.ogg` sound file (WoW's supported audio format).

**How to create a custom .ogg sound:**

1. **Start with any audio** — MP3, WAV, voice recording, YouTube clip, anything.
2. **Convert to .ogg format:**
   - **Free online tool:** Go to [convertio.co/mp3-ogg](https://convertio.co/mp3-ogg/) — upload your file, convert, download.
   - **Audacity (free, all platforms):** Open file → File → Export → Export as OGG. [audacityteam.org](https://www.audacityteam.org/)
   - **FFmpeg (command line):** `ffmpeg -i input.mp3 output.ogg`
3. **Keep it short** — 1-3 seconds is ideal for a notification sound. Trim long files.
   - **Audacity:** Select the portion you want → Edit → Remove Special → Trim Audio → Export as OGG.
   - **Online trimmer:** [mp3cut.net](https://mp3cut.net/) works with any audio format.
4. **Name your file** — Must be `sound0.ogg` through `sound9.ogg` (10 custom sound slots).
5. **Copy the file** into your addon folder:
   ```
   World of Warcraft/_retail_/Interface/AddOns/BuddyFlash/Sounds/
   ```
6. **Select it in-game:**
   - Open `/bf options` and pick your custom sound from the dropdown, OR
   - Use the command: `/bf sound 11` (custom sounds start at index 11)
7. **Set per-friend sounds:**
   ```
   /bf friendsound FriendName 11
   /bf friendsound Nickname#1234 12
   ```
   Each number corresponds to a sound slot.

**Sound slots:**
- Slots 1-10: Built-in WoW sounds (Friend Login, Raid Warning, Ready Check, Murloc, PvP Flag, Level Up, Loot Legendary, Quest Complete, Tell Message, Map Ping)
- Slots 11-20: Your custom sounds (`sound0.ogg` through `sound9.ogg`)

**Fun ideas for custom sounds:**
- Record yourself saying "Hey [friend's name]!"
- Use a funny meme sound effect
- Use your guild's voice chat catchphrase
- Use a dramatic movie quote for your raid leader
- Use a gentle chime for friends, loud alarm for the guild master

---

### File Structure Summary

```
World of Warcraft/_retail_/Interface/AddOns/BuddyFlash/
├── BuddyFlash.toc
├── BuddyFlash.lua
├── Options.lua
├── AvatarManifest.lua
├── Avatars/
│   ├── default.tga        ← Default avatar (replace with your own)
│   ├── av0.tga            ← Custom avatar slot 0
│   ├── av1.tga            ← Custom avatar slot 1
│   ├── ...                ← Add as many .tga files as you want
│   └── raidlead.tga       ← Example: custom avatar for your raid leader
└── Sounds/
    ├── sound0.ogg         ← Custom sound slot 0
    ├── sound1.ogg         ← Custom sound slot 1
    └── ...                ← Up to sound9.ogg
```

**That's it!** You now have a fully personalized friend notification system. Every friend gets their own face and their own sound. No other WoW addon offers this level of customization.
