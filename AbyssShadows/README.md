# Abyss Shadows Rayfield UI

A polished Roblox Rayfield GUI loader and farming tool for `AbyssShadows`.

## Structure

- `Main.lua` - entrypoint to initialize the Rayfield UI and scanner.
- `Modules/Constants.lua` - shared constants and UI options.
- `Modules/Utils.lua` - utility functions for HTTP and status visuals.
- `Modules/DataManager.lua` - runtime state and session metrics.
- `Modules/Scanner.lua` - scans NPCs and chests in `Workspace` and `ReplicatedStorage`.
- `Modules/Farming.lua` - farming logic with safe start/stop and target handling.
- `Modules/GuiBuilder.lua` - builds a modern Rayfield UI with tabs and controls.

## Usage

1. Place the `AbyssShadows` folder into your Roblox game's `StarterPlayerScripts`, `StarterGui`, or `ReplicatedStorage`.
2. Run `Main.lua` as a LocalScript inside the `AbyssShadows` folder.
3. Use the Rayfield UI to start farming and inspect detected NPCs, chests, and gems.

## Notes

- `AbyssShadows` includes internal Rayfield fallback URLs in `AbyssShadows/Modules/Constants.lua`.
- You can load the full project directly with the following pinned one-liner:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/bobakerdraa-bot/SoraPieceV3/35d00e7b3c7e8c56d8f2d9b3f3a9a4f6d6b7c8e9/SoraPiece_link.lua", true))()
```

- Ensure HTTP access is enabled in your executor so the loader can fetch the files.
