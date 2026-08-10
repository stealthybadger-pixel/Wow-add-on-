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
-- Uses the same 5-slot Tank/Healer/DPS/DPS/DPS shape as a real group.
-- Phase 2: each slot also demonstrates one of the 5 combat states
-- (Normal, Aggro, Dispellable, Out of range, Dead) requested for testing.
local TEST_ROSTER = {
	{ role = "TANK", healthPct = 0.55, aggro = true },
	{ role = "HEALER", healthPct = 1.00 },
	{ role = "DAMAGER", healthPct = 0.82, dispellable = true },
	{ role = "DAMAGER", healthPct = 0.38, outOfRange = true },
	{ role = "DAMAGER", healthPct = 0.00, dead = true },
}

-- Phase 2 combat-state visuals (05 - Roadmap.md Phase 2 / 02 - Unit Frame
-- Design.md sections 7-9). Border color communicates aggro/dispel; frame
-- alpha communicates range/death. Idle border matches the neutral Phase 1
-- edge color so nothing changes visually until a state is actually active.
local COLOR_BORDER_IDLE = { 0.12, 0.12, 0.12, 1 }
local COLOR_BORDER_AGGRO = { 0.85, 0.10, 0.10, 1 }
local COLOR_BORDER_DISPEL = { 0.95, 0.35, 0.75, 1 }
local ALPHA_NORMAL = 1
local ALPHA_OUT_OF_RANGE = 0.55
local ALPHA_DEAD = 0.35

-- Detox is the Mistweaver's only dispel spell, so identifying it isn't
-- "hard-coding a dispel-type set" - it's a fixed fact of this addon's
-- Mistweaver-only scope. Its unconditional baseline is Magic-type effects
-- (PHASE_0_FEASIBILITY.md section 4). The talent that extends this to also
-- cover Poison/Disease is detected live rather than assumed: rather than
-- guess an unverified talent spell ID, this reads Detox's own current
-- (talent-updated) tooltip text via C_Spell.GetSpellDescription and checks
-- whether it now mentions Poison/Disease. Falls back to Magic-only if the
-- API is unavailable or the description can't be read. Unverified against
-- a live client - see TESTING.md.
local DETOX_SPELL_ID = 218164

local function GetDispellableTypes()
	local types = { Magic = true }
	if C_Spell and C_Spell.GetSpellDescription then
		local ok, description = pcall(C_Spell.GetSpellDescription, DETOX_SPELL_ID)
		if ok and type(description) == "string" then
			if description:find("Poison") then
				types.Poison = true
			end
			if description:find("Disease") then
				types.Disease = true
			end
		end
	end
	return types
end

local function HasAggro(unit)
	local status = UnitThreatSituation(unit)
	return status ~= nil and status > 0
end

-- Scans the unit's harmful auras for one whose dispelType is currently
-- dispellable. Uses the classic UnitAura tuple return (rather than
-- C_UnitAuras.GetAuraDataByIndex's table) since its argument order/shape
-- has been stable for a very long time and is lower-risk to rely on
-- without a live client to verify field names against.
local function HasDispellableDebuff(unit, dispellable)
	local ok, result = pcall(function()
		for i = 1, 40 do
			local name, _, _, dispelType = UnitAura(unit, i, "HARMFUL")
			if not name then
				return false
			end
			if dispelType and dispellable[dispelType] then
				return true
			end
		end
		return false
	end)
	return ok and result or false
end

local function ComputeUnitCombatState(unit)
	local inRange, checkedRange = UnitInRange(unit)
	return {
		aggro = HasAggro(unit),
		dispellable = HasDispellableDebuff(unit, GetDispellableTypes()),
		dead = UnitIsDeadOrGhost(unit) and true or false,
		outOfRange = checkedRange and not inRange,
	}
end

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

-- Pink dispel outline takes priority over red aggro (02 - Unit Frame
-- Design.md section 8). Dead takes priority over out-of-range dimming,
-- since a dead unit is the more extreme/encompassing state.
local function RenderCombatState(slot, state)
	if state.dispellable then
		slot.frame:SetBackdropBorderColor(unpack(COLOR_BORDER_DISPEL))
	elseif state.aggro then
		slot.frame:SetBackdropBorderColor(unpack(COLOR_BORDER_AGGRO))
	else
		slot.frame:SetBackdropBorderColor(unpack(COLOR_BORDER_IDLE))
	end

	if state.dead then
		slot.frame:SetAlpha(ALPHA_DEAD)
	elseif state.outOfRange then
		slot.frame:SetAlpha(ALPHA_OUT_OF_RANGE)
	else
		slot.frame:SetAlpha(ALPHA_NORMAL)
	end
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
	RenderCombatState(slot, ComputeUnitCombatState(unit))
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
	RenderCombatState(slot, {
		aggro = entry.aggro or false,
		dispellable = entry.dispellable or false,
		dead = entry.dead or false,
		outOfRange = entry.outOfRange or false,
	})
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

-- Aggro/dispel changes only need the combat-state visuals recomputed, not
-- a full role/health re-render.
function ns.RefreshUnitCombatState(unit)
	if ns.testModeActive then
		return
	end
	for i = 1, MAX_SLOTS do
		if slots[i].unit == unit then
			RenderCombatState(slots[i], ComputeUnitCombatState(unit))
			return
		end
	end
end

-- Range and death have no reliable per-unit "changed" event, so this is
-- polled on a short timer (see InitializePartyFrame) rather than driven
-- purely by events, matching common addon practice for range checks.
function ns.RefreshAllCombatStates()
	if ns.testModeActive then
		return
	end
	for i = 1, MAX_SLOTS do
		local unit = slots[i].unit
		if unit then
			RenderCombatState(slots[i], ComputeUnitCombatState(unit))
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
	watcher:RegisterEvent("UNIT_AURA")
	-- Event names for per-unit threat changes; wrapped defensively since
	-- their exact availability on this client is unverified (see TESTING.md).
	-- An unknown event name errors on RegisterEvent, so pcall keeps a bad
	-- name from breaking the rest of initialization.
	pcall(watcher.RegisterEvent, watcher, "UNIT_THREAT_LIST_UPDATE")
	pcall(watcher.RegisterEvent, watcher, "UNIT_THREAT_SITUATION_UPDATE")
	watcher:SetScript("OnEvent", function(_, event, unit)
		if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
			ns.RefreshUnitHealth(unit)
		elseif event == "UNIT_AURA" or event == "UNIT_THREAT_LIST_UPDATE" or event == "UNIT_THREAT_SITUATION_UPDATE" then
			ns.RefreshUnitCombatState(unit)
		else
			ns.RefreshRoster()
		end
	end)

	-- Range/death have no reliable change event, so poll them periodically.
	if C_Timer and C_Timer.NewTicker then
		C_Timer.NewTicker(0.5, ns.RefreshAllCombatStates)
	end

	ns.RefreshRoster()
end
