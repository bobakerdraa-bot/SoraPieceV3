-- Constants.lua
-- Shared constants and utilities for Abyss Shadows.

local Constants = {}

Constants.RayfieldUrl = "https://sirius.menu/rayfield"
Constants.RayfieldUrls = {
    "https://sirius.menu/rayfield",
    "https://raw.githubusercontent.com/sirius1138/Rayfield/main/source.lua",
    "https://cdn.jsdelivr.net/gh/sirius1138/Rayfield@main/source.lua",
}

Constants.Defaults = {
    AutoFarm = false,
    AutoChests = false,
    AutoGems = false,
    FarmArea = "Nearest",
    AttackRange = 25,
    TargetPriority = "Closest",
    ChestRange = 30,
    GemRange = 28,
}

Constants.TargetPriorities = {"Closest", "Lowest Health", "Highest Health", "Bosses First", "Random"}

return Constants
