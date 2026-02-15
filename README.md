# OBS Random Stinger Transition Script

A Lua script for OBS Studio that automatically randomizes stinger transition videos with intelligent rotation and per-video transition point support.

The established option for this (https://github.com/FineWolf/obs-scripts/tree/master/RandomStingerVideo) is buggy and occasionally loads new stingers before the current selection is finished playing. This script fixes that issue and adds new functionality.

## Features

- **Smart Rotation** - Ensures every stinger plays once before repeating
- **Per-Video Transition Points** - Automatically reads transition timing from filenames
- **Selective Application** - Choose which specific stinger transition to randomize

## Installation

1. Download `RandomStingerCustom.lua` (Right click <a href="https://github.com/dotXCVI/OBS-Random-Stinger-Transition/blob/main/RandomStingerCustom.lua" rel="nofollow">this link</a> → Save Link As...)
2. In OBS Studio, go to **Tools → Scripts**
3. Click the **+** button and select the script file
4. Configure the settings (see below)

## Setup

### 1. Set Up Your Stingers

Create a folder somewhere on your PC to hold your stingers.

Include the transition point (in milliseconds) in your filename using the format `_XXXms`:
```
explosion_500ms.webm
swoosh_750ms.mp4
glitch_300ms.webm
cyberpunk_1200ms.mp4
```

The number before `ms` tells OBS when to cut between scenes during the transition.

**Examples:**
- `stinger_500ms.webm` → Transition point at 500ms
- `custom_750ms.mp4` → Transition point at 750ms
- `transition300ms.webm` → Transition point at 300ms (underscore optional)

If no timing is found in the filename, the script defaults to 500ms.

### 2. Create a Stinger Transition

If you don't already have one:

1. In OBS, go to your **Scene Transitions** dock
2. Click **+** and add a **Stinger** transition
3. Name it (e.g., "Random")

### 3. Configure the Script

In the OBS Scripts window:

1. **Stinger Video Folder** - Select the folder containing your stinger videos
2. **Target Stinger Transition** - Choose which Stinger transition to apply random videos to
3. Click **Refresh Video List** to scan for videos

## How It Works

1. The script loads all stinger videos from your specified folder
2. When you switch scenes using your target transition, it plays the current stinger
3. After the transition completes, the script queues the next random stinger
4. Videos are selected randomly from those that haven't been played yet
5. Once all stingers have played, the rotation resets automatically

## Controls

- **Refresh Video List** - Re-scan the folder for new stinger videos
- **Reset Rotation** - Mark all stingers as unplayed and start fresh

## Logging

The script logs detailed information to the OBS log file:

- Which videos are found and their transition points
- Which stinger is selected for each transition
- How many unplayed stingers remain
- Rotation resets

Access logs via **View → Log Files → Current Log**

## Requirements

- OBS Studio 28.0 or later
- Stinger transition videos with timing in filenames

## Credits

Created for the OBS community by KyleXCVI who wanted more dynamic transitions.

## License

MIT License - Feel free to modify and distribute
