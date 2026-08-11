# Abyss Shadows Rayfield UI

A polished Roblox Rayfield GUI loader and farming tool for `SoraPiece`.

## Structure

- `Main.lua` - entrypoint to initialize the Rayfield UI and scanner.
- `Modules/Constants.lua` - shared constants and UI options.
- `Modules/Utils.lua` - utility functions for HTTP and status visuals.
- `Modules/DataManager.lua` - runtime state and session metrics.
- `Modules/Scanner.lua` - scans NPCs and chests in `Workspace` and `ReplicatedStorage`.
- `Modules/Farming.lua` - farming logic with safe start/stop and target handling.
- `Modules/GuiBuilder.lua` - builds a modern Rayfield UI with tabs and controls.

## Usage

1. Put `AbyssShadows` together with `SoraPiece.lua` in the same Roblox game.
2. Run `Main.lua` from a LocalScript.
3. Use the Rayfield UI to start farming and inspect detected NPCs/chests.
## Recommended loader

`AbyssShadows` already contains a fallback loader in `AbyssShadows/Modules/Constants.lua`.
If you need a direct executor URL, use:

- `https://raw.githack.com/bobakerdraa-bot/SoraPieceV3/main/SoraPiece_link.lua`

If your executor supports CDNs, this is also a good fallback:

- `https://cdn.jsdelivr.net/gh/bobakerdraa-bot/SoraPieceV3@main/SoraPiece_link.lua`

If raw GitHub is blocked, `raw.githack.com` is the recommended first choice.

### Recommended executor loader

Use this one-liner in your executor:

```lua
loadstring(game:HttpGet("https://raw.githack.com/bobakerdraa-bot/SoraPieceV3/main/SoraPiece_link.lua", true))()
```
