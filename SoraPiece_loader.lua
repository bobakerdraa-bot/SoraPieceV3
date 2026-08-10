-- Loader: fetches the main SoraPiece script from the repo and runs it
local url = "https://raw.githubusercontent.com/bobakerdraa-bot/SoraPieceV2/main/SoraPiece.lua"
local ok, res = pcall(function()
    return loadstring(game:HttpGet(url, true))()
end)
if not ok then
    warn("[SoraPiece_loader] failed to load remote script:", res)
end
