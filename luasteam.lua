-- Local no-op stub for the Steamworks module so SNKRX can run without
-- Steam on Linux (the real luasteam.so is Windows-only). Added for testing.
local steam = {}

steam.init = function() end
steam.shutdown = function() end
steam.runCallbacks = function() end

steam.friends = {
	setRichPresence = function() end,
}

steam.userStats = {
	requestCurrentStats = function() end,
	storeStats = function() end,
	resetAllStats = function() end,
	setAchievement = function() end,
}

return steam
