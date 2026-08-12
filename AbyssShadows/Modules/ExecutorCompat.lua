-- Minimal safe ExecutorCompat for initial diagnostics
-- Returns a simple table without calling executor-specific APIs at load time

local ExecutorCompat = {
    ExecutorName = "Unknown",
    IsSupported = false,
    Capabilities = {},
}

-- Safe, non-failing diagnostics printed if available
pcall(function()
    print("[COMPAT] Module loaded")
    print("[COMPAT] Executor: " .. tostring(ExecutorCompat.ExecutorName))
    print("[COMPAT] Module READY")
end)

return ExecutorCompat
