-- Constants.lua
-- Shared constants and utilities for Abyss Shadows.

local Constants = {}

Constants.ScriptUrls = {
    "https://raw.githack.com/bobakerdraa-bot/SoraPieceV3/main/SoraPiece.lua",
    "https://cdn.jsdelivr.net/gh/bobakerdraa-bot/SoraPieceV3@main/SoraPiece.lua",
    "https://raw.githubusercontent.com/bobakerdraa-bot/SoraPieceV3/main/SoraPiece.lua",
}
Constants.RayfieldUrl = "https://sirius.menu/rayfield"

Constants.Defaults = {
    AutoFarm = false,
    AutoCollect = false,
    AutoReturn = false,
    AutoChests = false,
    AutoGems = false,
    AttackRange = 25,
    TargetPriority = "Closest",
    ChestRange = 30,
    GemRange = 28,
    LoggingEnabled = false,
}

Constants.TargetPriorities = {"Closest", "Lowest Health", "Highest Health", "Bosses First", "Random"}
Constants.FarmAreas = {"Nearest", "Arena", "Forest", "Dungeon", "Custom"}
Constants.NpcOptions = {"Any", "Nearest", "Strongest", "Weakest"}

return Constants
