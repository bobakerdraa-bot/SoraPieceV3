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
- You do not need an external loader file; run `Main.lua` directly from the `AbyssShadows` folder.
- Ensure HTTP access is enabled in your executor so the Rayfield UI library can be downloaded.
