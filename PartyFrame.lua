local ADDON_NAME, ns = ...

-- Reference dimensions from 02 - Unit Frame Design.md section 2
-- (200-220px wide, ~50px tall family, before scale presets are applied).
local FRAME_WIDTH = 210
local FRAME_HEIGHT = 50
local FRAME_GAP = 4
local HEALTH_BAR_HEIGHT = 4
local MAX_SLOTS = 5

local SCALE_VALUES = {
	SMALL = 0.8,
	MEDIUM = 1.0,
	LARGE = 1.2,
}

-- Tank -> Healer/user -> DPS -> DPS -> DPS (05 - Roadmap.md, Phase 1).
local ROLE_PRIORITY = {
	TANK = 1,
	HEALER = 2,
	DAMAGER = 3,
	NONE = 4,
}

local ROLE_ICON_TEXTURE = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES"

-- Maps role strings to Blizzard's current small role-icon atlas - the same
-- atlas the live default party/raid frames use for their role icons.
local ROLE_ATLAS = {
	TANK = "roleicon-tiny-tank",
	HEALER = "roleicon-tiny-healer",
	DAMAGER = "roleicon-tiny-dps",
}

-- Fixed simulated roster for "/mistpanel test" (developer test mode).
-- Uses the same 5-slot Tank/Healer/DPS/DPS/DPS shape as a real group, with
-- varied health percentages so the health-line behaviour across the full
-- green-to-red range can be inspected without a live party.
local TEST_ROSTER = {
	{ role = "TANK", healthPct = 0.55 },
	{ role = "HEALER", healthPct = 1.00 },
	{ role = "DAMAGER", healthPct = 0.82 },
	{ role = "DAMAGER", healthPct = 0.38 },
	{ role = "DAMAGER", healthPct = 0.12 },
}

local container
local slots = {}
ns.testModeActive = false

local function GetHealthColor(pct)
	pct = math.max(0, math.min(1, pct or 0))
	return 1 - pct, pct, 0
end

local function CreateSlot(index)
	local f = CreateFrame("Frame", ADDON_NAME .. "Slot" .. index, container, "BackdropTemplate")
	f:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
	f:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = 1,
	})
	f:SetBackdropColor(0.03, 0.03, 0.03, 0.9)
	f:SetBackdropBorderColor(0.12, 0.12, 0.12, 1)

	local roleIcon = f:CreateTexture(nil, "ARTWORK")
	roleIcon:SetSize(16, 16)
	roleIcon:SetPoint("LEFT", f, "LEFT", 4, 0)
	roleIcon:SetTexture(ROLE_ICON_TEXTURE)

	-- Thin bottom health line: full-width at full health, retreats right to
	-- left as damage is taken. A left-anchored StatusBar does this natively.
	local healthBar = CreateFrame("StatusBar", nil, f)
	healthBar:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
	healthBar:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
	healthBar:SetHeight(HEALTH_BAR_HEIGHT)
	healthBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
	healthBar:SetMinMaxValues(0, 1)
	healthBar:SetValue(1)

	f:Hide()

	return {
		frame = f,
		roleIcon = roleIcon,
		healthBar = healthBar,
		unit = nil,
	}
end

local function CreateContainer()
	local c = CreateFrame("Frame", ADDON_NAME .. "Container", UIParent)
	c:SetSize(FRAME_WIDTH, (FRAME_HEIGHT * MAX_SLOTS) + (FRAME_GAP * (MAX_SLOTS - 1)))
	c:SetMovable(true)
	c:SetClampedToScreen(true)
	c:EnableMouse(false)
	c:RegisterForDrag("LeftButton")
	c:SetScript("OnDragStart", function(self)
		if not ns.db.locked then
			self:StartMoving()
		end
	end)
	c:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local point, _, relativePoint, x, y = self:GetPoint()
		ns.db.point = { point = point, relativePoint = relativePoint, x = x, y = y }
	end)
	return c
end

local function ApplyPoint()
	local p = ns.db.point
	container:ClearAllPoints()
	container:SetPoint(p.point, UIParent, p.relativePoint, p.x, p.y)
end

local function LayoutSlots()
	for i = 1, MAX_SLOTS do
		local slot = slots[i]
		slot.frame:ClearAllPoints()
		if i == 1 then
			slot.frame:SetPoint("TOP", container, "TOP", 0, 0)
		else
			slot.frame:SetPoint("TOP", slots[i - 1].frame, "BOTTOM", 0, -FRAME_GAP)
		end
	end
end

-- Player + whichever party1-4 tokens currently exist. Empty outside a
-- (non-raid) group, which is what drives "hide when solo" / "no raid mode".
local function GetGroupUnits()
	local units = {}
	if not IsInGroup() or IsInRaid() then
		return units
	end
	table.insert(units, "player")
	for i = 1, 4 do
		local unit = "party" .. i
		if UnitExists(unit) then
			table.insert(units, unit)
		end
	end
	return units
end

local function SortedRoster()
	local units = GetGroupUnits()
	local originalIndex = {}
	for i, u in ipairs(units) do
		originalIndex[u] = i
	end
	table.sort(units, function(a, b)
		local ra = ROLE_PRIORITY[UnitGroupRolesAssigned(a)] or ROLE_PRIORITY.NONE
		local rb = ROLE_PRIORITY[UnitGroupRolesAssigned(b)] or ROLE_PRIORITY.NONE
		if ra ~= rb then
			return ra < rb
		end
		return originalIndex[a] < originalIndex[b]
	end)
	return units
end

-- Shared rendering: real party slots and the simulated test-mode slots both
-- funnel through these two functions, so both use identical dimensions,
-- spacing, role indicators, scale and positioning - only the data differs.
-- Tries the current role-icon atlas first, falls back to the older
-- texcoord-on-texture technique, and only hides the icon if neither works.
local function RenderRoleIcon(slot, role)
	local atlas = ROLE_ATLAS[role]
	if atlas and slot.roleIcon.SetAtlas then
		slot.roleIcon:SetAtlas(atlas)
		slot.roleIcon:Show()
		return
	end
	if GetTexCoordsForRoleSmallCircle then
		local l, r, t, b = GetTexCoordsForRoleSmallCircle(role)
		if l then
			slot.roleIcon:SetTexture(ROLE_ICON_TEXTURE)
			slot.roleIcon:SetTexCoord(l, r, t, b)
			slot.roleIcon:Show()
			return
		end
	end
	slot.roleIcon:Hide()
end

local function RenderHealthFraction(slot, frac)
	frac = math.max(0, math.min(1, frac or 0))
	slot.healthBar:SetMinMaxValues(0, 1)
	slot.healthBar:SetValue(frac)
	slot.healthBar:SetStatusBarColor(GetHealthColor(frac))
end

local function UpdateSlot(slot, unit)
	slot.unit = unit
	if not unit then
		slot.frame:Hide()
		return
	end
	slot.frame:Show()
	RenderRoleIcon(slot, UnitGroupRolesAssigned(unit))
	local maxHealth = UnitHealthMax(unit)
	local health = UnitHealth(unit)
	local frac = (maxHealth and maxHealth > 0) and (health / maxHealth) or 0
	RenderHealthFraction(slot, frac)
end

local function UpdateTestSlot(slot, entry)
	slot.unit = nil -- not a real unit token; keeps live UNIT_HEALTH events from touching it
	if not entry then
		slot.frame:Hide()
		return
	end
	slot.frame:Show()
	RenderRoleIcon(slot, entry.role)
	RenderHealthFraction(slot, entry.healthPct)
end

function ns.RefreshRoster()
	if ns.testModeActive then
		return -- test mode owns rendering until toggled off
	end
	local units = SortedRoster()
	for i = 1, MAX_SLOTS do
		UpdateSlot(slots[i], units[i])
	end
	container:SetShown(#units > 0)
end

function ns.RefreshUnitHealth(unit)
	if ns.testModeActive then
		return
	end
	for i = 1, MAX_SLOTS do
		if slots[i].unit == unit then
			UpdateSlot(slots[i], unit)
			return
		end
	end
end

-- "/mistpanel test": simulated 5-player roster using the exact same slot
-- frames/container as live play, so it can be inspected and iterated on
-- while solo. Overrides hide-when-solo while active; live roster/health
-- events are ignored until test mode is toggled back off.
function ns.SetTestMode(enabled)
	ns.testModeActive = enabled and true or false
	if ns.testModeActive then
		for i = 1, MAX_SLOTS do
			UpdateTestSlot(slots[i], TEST_ROSTER[i])
		end
		container:Show()
	else
		ns.RefreshRoster()
	end
end

function ns.SetLocked(locked)
	ns.db.locked = locked and true or false
	container:EnableMouse(not ns.db.locked)
end

function ns.SetScale(scaleKey)
	local value = SCALE_VALUES[scaleKey]
	if not value then
		return
	end
	ns.db.scale = scaleKey
	container:SetScale(value)
end

-- Blizzard party frame auto-hide, driven through the secure visibility
-- driver system rather than a direct Show/Hide override, per
-- PHASE_0_FEASIBILITY.md section 10 (avoids combat-lockdown taint).
-- The CompactPartyFrame global and this exact behavior are unverified
-- against a live client - see PHASE_1_IMPLEMENTATION.md / TESTING.md.
function ns.SetHideBlizzardPartyFrames(enabled)
	ns.db.hideBlizzardPartyFrames = enabled and true or false
	if not CompactPartyFrame then
		return
	end
	if ns.db.hideBlizzardPartyFrames then
		RegisterStateDriver(CompactPartyFrame, "visibility", "hide")
	else
		UnregisterStateDriver(CompactPartyFrame, "visibility")
		if CompactPartyFrame_UpdateVisibility then
			CompactPartyFrame_UpdateVisibility()
		end
	end
end

function ns.PrintStatus()
	print("|cff33ff99MistPanel|r status:")
	print("  locked: " .. tostring(ns.db.locked))
	print("  scale: " .. tostring(ns.db.scale))
	print("  hideBlizzardPartyFrames: " .. tostring(ns.db.hideBlizzardPartyFrames))
	print("  in group (non-raid): " .. tostring(IsInGroup() and not IsInRaid()))
	print("  testMode: " .. tostring(ns.testModeActive))
end

function ns.InitializePartyFrame()
	container = CreateContainer()
	for i = 1, MAX_SLOTS do
		slots[i] = CreateSlot(i)
	end
	LayoutSlots()
	ApplyPoint()
	ns.SetLocked(ns.db.locked)
	ns.SetScale(ns.db.scale)
	ns.SetHideBlizzardPartyFrames(ns.db.hideBlizzardPartyFrames)

	local watcher = CreateFrame("Frame")
	watcher:RegisterEvent("GROUP_ROSTER_UPDATE")
	watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
	watcher:RegisterEvent("PLAYER_ROLES_ASSIGNED")
	watcher:RegisterEvent("UNIT_HEALTH")
	watcher:RegisterEvent("UNIT_MAXHEALTH")
	watcher:SetScript("OnEvent", function(_, event, unit)
		if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
			ns.RefreshUnitHealth(unit)
		else
			ns.RefreshRoster()
		end
	end)

	ns.RefreshRoster()
end
