-- Constants.lua
-- Shared constants and utilities for Abyss Shadows.

local Constants = {}

Constants.Metadata = {
    Name = "Abyss_Shadow",
    Version = "1.0.0",
    GameName = "Sora Piece",
    PlaceId = 91356007281562,
    UpdateSource = {
        URL = "https://raw.githubusercontent.com/bobakerdraa-bot/SoraPieceV3/main/AbyssShadows/version.txt",
        Required = false,
    },
}

Constants.Dependencies = {
    Rayfield = {
        Name = "Rayfield",
        URL = "https://sirius.menu/rayfield",
        FallbackUrls = {
            "https://raw.githubusercontent.com/sirius1138/Rayfield/main/source.lua",
            "https://cdn.jsdelivr.net/gh/sirius1138/Rayfield@main/source.lua",
        },
        Required = true,
        Fallback = true,
    },
}

Constants.RayfieldUrl = Constants.Dependencies.Rayfield.URL
Constants.RayfieldUrls = { Constants.RayfieldUrl, table.unpack(Constants.Dependencies.Rayfield.FallbackUrls) }

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
