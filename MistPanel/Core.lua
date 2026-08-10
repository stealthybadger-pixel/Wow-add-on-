local ADDON_NAME, ns = ...

ns.ADDON_NAME = ADDON_NAME

-- Phase 1 defaults. "point" has no on-screen default value baked into the
-- spec, so the block starts centered above the action bars until the user
-- drags it (Unlock mode) to a preferred spot.
local DEFAULTS = {
	locked = true,
	scale = "MEDIUM",
	hideBlizzardPartyFrames = true,
	point = { point = "CENTER", relativePoint = "CENTER", x = 0, y = 200 },
}

local function CopyDefaults(dst, src)
	for k, v in pairs(src) do
		if type(v) == "table" then
			if type(dst[k]) ~= "table" then
				dst[k] = {}
			end
			CopyDefaults(dst[k], v)
		elseif dst[k] == nil then
			dst[k] = v
		end
	end
	return dst
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(_, event, arg1)
	if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
		MistPanelDB = CopyDefaults(MistPanelDB or {}, DEFAULTS)
		ns.db = MistPanelDB
	elseif event == "PLAYER_LOGIN" then
		ns.InitializePartyFrame()
	end
end)

-- Phase 1 has no settings UI or slash command yet (both are scoped to
-- Phase 5). This is a minimal, temporary command surface that exists only
-- so Phase 1's scale/lock/drag/auto-hide mechanics can be exercised and
-- verified in-game before the real configuration UI exists. It is expected
-- to be superseded, not extended, in Phase 5.
SLASH_MISTPANEL1 = "/mistpanel"
SlashCmdList["MISTPANEL"] = function(msg)
	local cmd, rest = strtrim(msg or ""):match("^(%S*)%s*(.-)$")
	cmd = (cmd or ""):lower()
	rest = (rest or ""):lower()

	if cmd == "lock" then
		ns.SetLocked(true)
		print("|cff33ff99MistPanel|r: frame locked.")
	elseif cmd == "unlock" then
		ns.SetLocked(false)
		print("|cff33ff99MistPanel|r: frame unlocked - drag to reposition.")
	elseif cmd == "scale" then
		if rest == "small" or rest == "medium" or rest == "large" then
			ns.SetScale(rest:upper())
			print("|cff33ff99MistPanel|r: scale set to " .. rest .. ".")
		else
			print("|cff33ff99MistPanel|r: usage /mistpanel scale small|medium|large")
		end
	elseif cmd == "blizzframes" then
		if rest == "on" or rest == "off" then
			ns.SetHideBlizzardPartyFrames(rest == "on")
			print("|cff33ff99MistPanel|r: Blizzard party frame auto-hide " .. (rest == "on" and "enabled" or "disabled") .. ".")
		else
			print("|cff33ff99MistPanel|r: usage /mistpanel blizzframes on|off")
		end
	elseif cmd == "status" then
		ns.PrintStatus()
	else
		print("|cff33ff99MistPanel|r Phase 1 test commands:")
		print("  /mistpanel lock | unlock")
		print("  /mistpanel scale small|medium|large")
		print("  /mistpanel blizzframes on|off")
		print("  /mistpanel status")
	end
end
