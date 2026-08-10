local ADDON_NAME, ns = ...

-- Reference dimensions from 02 - Unit Frame Design.md section 2
-- (200-220px wide, ~50px tall family, before scale presets are applied).
local FRAME_WIDTH = 210
local FRAME_HEIGHT = 48
local FRAME_GAP = 6
local ROLE_COLUMN_WIDTH = 46
local ROLE_ICON_SIZE = 20
local HEALTH_BAR_HEIGHT = 5
local MAX_SLOTS = 5
local MAX_HOTS = 5
local HOT_ICON_SIZE = 20

local SCALE_VALUES = {
	SMALL = 0.8,
	MEDIUM = 1.0,
	LARGE = 1.2,
}

-- Tank -> Healer/user -> DPS -> DPS -> DPS (05 - Roadmap.md).
local ROLE_PRIORITY = {
	TANK = 1,
	HEALER = 2,
	DAMAGER = 3,
	NONE = 4,
}

local ROLE_ICON_TEXTURE = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES"

local ROLE_ATLAS_MAP = {
	TANK = "roleicon-tiny-tank",
	HEALER = "roleicon-tiny-healer",
	DAMAGER = "roleicon-tiny-dps",
}

-- Explicit spell ID lookup for player-cast healing-over-time effects
local MY_HOT_SPELLS = {
	-- Mistweaver Monk
	[119611] = true, -- Renewing Mist
	[124682] = true, -- Enveloping Mist
	[115175] = true, -- Soothing Mist
	[191840] = true, -- Essence Font
	[325209] = true, -- Enveloping Breath
	[406254] = true, -- Celestial Harmony

	-- Restoration Druid
	[774]    = true, -- Rejuvenation
	[8936]   = true, -- Regrowth
	[33763]  = true, -- Lifebloom
	[48438]  = true, -- Wild Growth
	[155777] = true, -- Germination
	[207386] = true, -- Spring Blossoms
	[391888] = true, -- Adaptive Swarm

	-- Holy / Discipline Priest
	[139]    = true, -- Renew
	[77489]  = true, -- Echo of Light
	[41635]  = true, -- Prayer of Mending
	[194384] = true, -- Atonement

	-- Holy Paladin
	[200025] = true, -- Bestow Faith
	[53563]  = true, -- Beacon of Light
	[156910] = true, -- Beacon of Faith

	-- Restoration Shaman
	[61295]  = true, -- Riptide
	[5394]   = true, -- Healing Stream Totem
	[974]    = true, -- Earth Shield

	-- Preservation Evoker
	[366155] = true, -- Reversion
	[364343] = true, -- Echo
	[355941] = true, -- Dream Breath
	[373267] = true, -- Lifebind
}

-- Fixed colors for Phase 2 combat states
local COLOR_BORDER_DEFAULT = { 0.15, 0.15, 0.15, 0.9 }
local COLOR_BORDER_AGGRO   = { 1.00, 0.00, 0.00, 1.0 }
local COLOR_BORDER_DISPEL  = { 1.00, 0.20, 0.80, 1.0 } -- Pink / Magenta

-- Fixed simulated roster for "/mistpanel test" (developer test mode).
-- Extended to demonstrate My HoT visual layout (icons, cooldown sweeps, stack counts):
-- Slot 1: Tank with 2 active HoTs (Renewing Mist, Enveloping Mist)
-- Slot 2: Healer with 1 active HoT (Renewing Mist)
-- Slot 3: DPS 1 with 3 active HoTs (Renewing Mist stacked x2, Enveloping Mist, Essence Font) + Pink Dispel
-- Slot 4: DPS 2 with 0 HoTs
-- Slot 5: DPS 3 with 1 nearly-expired HoT
local TEST_ROSTER = {
	{
		role = "TANK", healthPct = 0.70, aggro = true, dispel = false, inRange = true, dead = false,
		hots = {
			{ spellId = 119611, icon = 136074, count = 1, duration = 20, expirationTime = 14 },
			{ spellId = 124682, icon = 136035, count = 1, duration = 6,  expirationTime = 4 },
		}
	},
	{
		role = "HEALER", healthPct = 1.00, aggro = false, dispel = false, inRange = true, dead = false,
		hots = {
			{ spellId = 119611, icon = 136074, count = 1, duration = 20, expirationTime = 18 },
		}
	},
	{
		role = "DAMAGER", healthPct = 0.50, aggro = true, dispel = true, inRange = true, dead = false,
		hots = {
			{ spellId = 119611, icon = 136074, count = 2, duration = 20, expirationTime = 10 },
			{ spellId = 124682, icon = 136035, count = 1, duration = 6,  expirationTime = 3 },
			{ spellId = 191840, icon = 136054, count = 1, duration = 8,  expirationTime = 5 },
		}
	},
	{
		role = "DAMAGER", healthPct = 0.35, aggro = false, dispel = false, inRange = true, dead = false,
		hots = {}
	},
	{
		role = "DAMAGER", healthPct = 0.10, aggro = false, dispel = false, inRange = true, dead = false,
		hots = {
			{ spellId = 119611, icon = 136074, count = 1, duration = 20, expirationTime = 1 },
		}
	},
}

local container
local slots = {}
ns.testModeActive = false

-- Dispel detection helper reflecting current runtime Mistweaver talent capability.
-- Detox is base for Mistweaver (Magic). Improved Detox adds Poison and Disease.
function ns.GetDispellableTypes()
	local dispellable = {}
	local detoxKnown = false
	local detoxIDs = { 115450 }
	for _, id in ipairs(detoxIDs) do
		if (C_SpellBook and C_SpellBook.IsSpellKnown and C_SpellBook.IsSpellKnown(id))
			or (IsPlayerSpell and IsPlayerSpell(id))
			or (IsSpellKnown and IsSpellKnown(id))
			or (select(2, UnitClass("player")) == "MONK" and GetSpecialization and GetSpecialization() == 2) then
			detoxKnown = true
			break
		end
	end

	if detoxKnown then
		dispellable["Magic"] = true
	end

	local impDetoxIDs = { 388874 }
	for _, id in ipairs(impDetoxIDs) do
		if (C_SpellBook and C_SpellBook.IsSpellKnown and C_SpellBook.IsSpellKnown(id))
			or (IsPlayerSpell and IsPlayerSpell(id))
			or (IsSpellKnown and IsSpellKnown(id)) then
			dispellable["Poison"] = true
			dispellable["Disease"] = true
			break
		end
	end

	return dispellable
end

local function UnitHasDispellableAura(unit)
	if not unit or not UnitExists(unit) then return false end
	local dispellableTypes = ns.GetDispellableTypes()
	if not next(dispellableTypes) then return false end

	if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
		local index = 1
		while true do
			local aura = C_UnitAuras.GetAuraDataByIndex(unit, index, "HARMFUL")
			if not aura then break end
			if aura.dispelType and dispellableTypes[aura.dispelType] then
				return true
			end
			index = index + 1
		end
	elseif UnitDebuff then
		local index = 1
		while true do
			local name, _, _, dispelType = UnitDebuff(unit, index)
			if not name then break end
			if dispelType and dispellableTypes[dispelType] then
				return true
			end
			index = index + 1
		end
	end
	return false
end

local function UnitHasAggro(unit)
	if not unit or not UnitExists(unit) then return false end
	local status = UnitThreatSituation(unit)
	return status and status > 0
end

local function UnitIsInRange(unit)
	if not unit or not UnitExists(unit) then return false end
	if UnitIsUnit(unit, "player") then return true end
	local inRange, checkedRange = UnitInRange(unit)
	if checkedRange then
		return inRange
	end
	return inRange ~= false
end

local function UnitIsDead(unit)
	if not unit or not UnitExists(unit) then return false end
	return UnitIsDeadOrGhost(unit) or not UnitIsConnected(unit)
end

local function GetUnitPlayerHoTs(unit)
	local hots = {}
	if not unit or not UnitExists(unit) then return hots end

	if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
		local index = 1
		while #hots < MAX_HOTS do
			local aura = C_UnitAuras.GetAuraDataByIndex(unit, index, "HELPFUL")
			if not aura then break end
			if (aura.isFromPlayer or aura.sourceUnit == "player") and aura.spellId and MY_HOT_SPELLS[aura.spellId] then
				table.insert(hots, {
					spellId = aura.spellId,
					icon = aura.icon,
					count = aura.applications or aura.count or 0,
					duration = aura.duration or 0,
					expirationTime = aura.expirationTime or 0,
				})
			end
			index = index + 1
		end
	elseif UnitBuff then
		local index = 1
		while #hots < MAX_HOTS do
			local name, icon, count, _, duration, expirationTime, caster, _, _, spellId = UnitBuff(unit, index)
			if not name then break end
			if (caster == "player") and spellId and MY_HOT_SPELLS[spellId] then
				table.insert(hots, {
					spellId = spellId,
					icon = icon,
					count = count or 0,
					duration = duration or 0,
					expirationTime = expirationTime or 0,
				})
			end
			index = index + 1
		end
	end

	return hots
end

local function GetHealthColor(pct)
	pct = math.max(0, math.min(1, pct or 0))
	if pct > 0.5 then
		return (1 - pct) * 2, 1.0, 0.0
	else
		return 1.0, pct * 2, 0.0
	end
end

local function SetSlotGlow(slot, r, g, b, baseAlpha)
	if not slot.glowLayers then return end
	baseAlpha = baseAlpha or 1.0
	local alphas = { 0.40, 0.24, 0.12, 0.05 }
	for idx, layer in ipairs(slot.glowLayers) do
		layer:SetBackdropBorderColor(r, g, b, alphas[idx] * baseAlpha)
	end
end

local function CreateSlot(index)
	local f = CreateFrame("Frame", ADDON_NAME .. "Slot" .. index, container, "BackdropTemplate")
	f:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
	f:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
	})
	f:SetBackdropColor(0.04, 0.04, 0.04, 0.95)

	-- Soft outer glow layers rendered behind f
	local glowContainer = CreateFrame("Frame", nil, f)
	glowContainer:SetFrameLevel(math.max(0, f:GetFrameLevel() - 1))
	glowContainer:SetAllPoints(f)

	local glowLayers = {}
	local glowOffsets = { 1, 2, 3, 4 }
	for i, offset in ipairs(glowOffsets) do
		local layer = CreateFrame("Frame", nil, glowContainer, "BackdropTemplate")
		layer:SetPoint("TOPLEFT", f, "TOPLEFT", -offset, offset)
		layer:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", offset, -offset)
		layer:SetBackdrop({
			edgeFile = "Interface\\Buttons\\WHITE8x8",
			edgeSize = 1,
		})
		layer:SetBackdropBorderColor(0, 0, 0, 0)
		glowLayers[i] = layer
	end

	-- Dedicated border overlay frame at a higher FrameLevel (f:GetFrameLevel() + 10)
	-- ensures the combat state outline is rendered above all interior slot content
	-- as a clean, uninterrupted outer border.
	local borderFrame = CreateFrame("Frame", nil, f, "BackdropTemplate")
	borderFrame:SetAllPoints(f)
	borderFrame:SetFrameLevel(f:GetFrameLevel() + 10)
	borderFrame:EnableMouse(false)
	borderFrame:SetBackdrop({
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = 1,
	})
	borderFrame:SetBackdropBorderColor(unpack(COLOR_BORDER_DEFAULT))

	-- Role Column (Left side - vertically centered role icon)
	local roleIcon = f:CreateTexture(nil, "ARTWORK")
	roleIcon:SetSize(ROLE_ICON_SIZE, ROLE_ICON_SIZE)
	roleIcon:SetPoint("CENTER", f, "TOPLEFT", ROLE_COLUMN_WIDTH / 2, -21)

	-- Subtle vertical divider separating role column from main area
	local divider = f:CreateTexture(nil, "ARTWORK")
	divider:SetPoint("TOPLEFT", f, "TOPLEFT", ROLE_COLUMN_WIDTH, -1)
	divider:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", ROLE_COLUMN_WIDTH, HEALTH_BAR_HEIGHT + 1)
	divider:SetWidth(1)
	divider:SetColorTexture(0.2, 0.2, 0.2, 0.6)

	-- Pre-created HoT icon frames pool in the main central area
	local hotIcons = {}
	local startX = ROLE_COLUMN_WIDTH + 6
	local iconGap = 4
	for i = 1, MAX_HOTS do
		local iconFrame = CreateFrame("Frame", nil, f, "BackdropTemplate")
		iconFrame:SetSize(HOT_ICON_SIZE, HOT_ICON_SIZE)
		iconFrame:SetPoint("TOPLEFT", f, "TOPLEFT", startX + (i - 1) * (HOT_ICON_SIZE + iconGap), -10)
		iconFrame:SetBackdrop({
			edgeFile = "Interface\\Buttons\\WHITE8x8",
			edgeSize = 1,
		})
		iconFrame:SetBackdropBorderColor(0.1, 0.1, 0.1, 0.8)

		local tex = iconFrame:CreateTexture(nil, "ARTWORK")
		tex:SetAllPoints(iconFrame)
		tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

		local cd = CreateFrame("Cooldown", nil, iconFrame, "CooldownFrameTemplate")
		cd:SetAllPoints(iconFrame)
		cd:SetReverse(true)
		cd:SetDrawEdge(false)
		cd:SetSwipeColor(0, 0, 0, 0.7)

		local countText = iconFrame:CreateFontString(nil, "OVERLAY")
		countText:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", 0, 0)
		countText:SetFont(STANDARD_TEXT_FONT or "Fonts\\ARIALN.TTF", 9, "OUTLINE")
		countText:SetTextColor(1, 1, 1, 1)

		iconFrame.texture = tex
		iconFrame.cooldown = cd
		iconFrame.countText = countText

		iconFrame:Hide()
		hotIcons[i] = iconFrame
	end

	-- Thin bottom health line
	local healthBar = CreateFrame("StatusBar", nil, f)
	healthBar:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 1, 1)
	healthBar:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
	healthBar:SetHeight(HEALTH_BAR_HEIGHT)
	healthBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
	healthBar:SetMinMaxValues(0, 1)
	healthBar:SetValue(1)

	local healthBarBg = healthBar:CreateTexture(nil, "BACKGROUND")
	healthBarBg:SetAllPoints(healthBar)
	healthBarBg:SetColorTexture(0.08, 0.08, 0.08, 0.9)

	f:Hide()

	return {
		frame = f,
		borderFrame = borderFrame,
		glowLayers = glowLayers,
		roleIcon = roleIcon,
		divider = divider,
		hotIcons = hotIcons,
		healthBar = healthBar,
		healthBarBg = healthBarBg,
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
-- funnel through these functions.
local function RenderRoleIcon(slot, role)
	if not role or role == "NONE" then
		slot.roleIcon:Hide()
		return
	end

	local atlas = ROLE_ATLAS_MAP[role]
	if atlas and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas) then
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

local function RenderHotIcons(slot, hots)
	hots = hots or {}
	local now = GetTime()
	for i = 1, MAX_HOTS do
		local iconFrame = slot.hotIcons[i]
		local data = hots[i]
		if data then
			iconFrame.texture:SetTexture(data.icon)

			local dur = data.duration or 0
			local exp = data.expirationTime or 0
			local start = 0
			if ns.testModeActive and exp < 100 then
				start = now - math.max(0, dur - exp)
			elseif exp > 0 and dur > 0 then
				start = exp - dur
			end

			if dur > 0 and start > 0 then
				iconFrame.cooldown:SetCooldown(start, dur)
				iconFrame.cooldown:Show()
			else
				iconFrame.cooldown:Hide()
			end

			if data.count and data.count > 1 then
				iconFrame.countText:SetText(tostring(data.count))
				iconFrame.countText:Show()
			else
				iconFrame.countText:Hide()
			end

			iconFrame:Show()
		else
			iconFrame:Hide()
		end
	end
end

local function RenderHealthFraction(slot, frac)
	frac = math.max(0, math.min(1, frac or 0))
	slot.healthBar:SetMinMaxValues(0, 1)
	slot.healthBar:SetValue(frac)
	local r, g, b = GetHealthColor(frac)
	slot.healthBar:SetStatusBarColor(r, g, b)
	if slot.healthBarBg then
		slot.healthBarBg:SetColorTexture(r * 0.25, g * 0.25, b * 0.25, 0.9)
	end
end

local function RenderSlotState(slot, hasAggro, hasDispel, inRange, isDead)
	-- Border outline: Dispel (pink) takes priority over Aggro (red)
	if hasDispel then
		slot.borderFrame:SetBackdropBorderColor(unpack(COLOR_BORDER_DISPEL))
		SetSlotGlow(slot, COLOR_BORDER_DISPEL[1], COLOR_BORDER_DISPEL[2], COLOR_BORDER_DISPEL[3], 1.0)
	elseif hasAggro then
		slot.borderFrame:SetBackdropBorderColor(unpack(COLOR_BORDER_AGGRO))
		SetSlotGlow(slot, COLOR_BORDER_AGGRO[1], COLOR_BORDER_AGGRO[2], COLOR_BORDER_AGGRO[3], 1.0)
	else
		slot.borderFrame:SetBackdropBorderColor(unpack(COLOR_BORDER_DEFAULT))
		SetSlotGlow(slot, 0.0, 0.0, 0.0, 0.5)
	end

	-- Frame dimming & desaturation for out-of-range or dead state
	if isDead then
		slot.frame:SetAlpha(0.35)
		slot.roleIcon:SetDesaturated(true)
		slot.healthBar:SetAlpha(0.35)
	elseif not inRange then
		slot.frame:SetAlpha(0.45)
		slot.roleIcon:SetDesaturated(true)
		slot.healthBar:SetAlpha(0.45)
	else
		slot.frame:SetAlpha(1.0)
		slot.roleIcon:SetDesaturated(false)
		slot.healthBar:SetAlpha(1.0)
	end
end

local function UpdateSlot(slot, unit)
	slot.unit = unit
	if not unit or not UnitExists(unit) then
		slot.frame:Hide()
		return
	end
	slot.frame:Show()
	RenderRoleIcon(slot, UnitGroupRolesAssigned(unit))
	local maxHealth = UnitHealthMax(unit)
	local health = UnitHealth(unit)
	local frac = (maxHealth and maxHealth > 0) and (health / maxHealth) or 0
	RenderHealthFraction(slot, frac)
	RenderHotIcons(slot, GetUnitPlayerHoTs(unit))

	local isDead = UnitIsDead(unit)
	local inRange = isDead or UnitIsInRange(unit)
	local hasDispel = not isDead and UnitHasDispellableAura(unit)
	local hasAggro = not isDead and UnitHasAggro(unit)

	RenderSlotState(slot, hasAggro, hasDispel, inRange, isDead)
end

local function UpdateTestSlot(slot, entry)
	slot.unit = nil -- not a real unit token; keeps live events from touching it
	if not entry then
		slot.frame:Hide()
		return
	end
	slot.frame:Show()
	RenderRoleIcon(slot, entry.role)
	RenderHealthFraction(slot, entry.healthPct)
	RenderHotIcons(slot, entry.hots)
	RenderSlotState(slot, entry.aggro, entry.dispel, entry.inRange, entry.dead)
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

function ns.RefreshUnitState(unit)
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
-- frames/container as live play. Extended in Phase 2 to demonstrate:
-- 1. Aggro (Red outline)
-- 2. Normal
-- 3. Dispellable (Pink outline, overriding aggro)
-- 4. Out of range (Dimmed / desaturated)
-- 5. Dead (Heavy dim / grey state)
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
	watcher:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
	watcher:RegisterEvent("UNIT_AURA")
	watcher:RegisterEvent("UNIT_FLAGS")
	watcher:RegisterEvent("SPELLS_CHANGED")
	watcher:RegisterEvent("PLAYER_TALENT_UPDATE")

	watcher:SetScript("OnEvent", function(_, event, unit)
		if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" or event == "UNIT_THREAT_SITUATION_UPDATE" or event == "UNIT_AURA" or event == "UNIT_FLAGS" then
			ns.RefreshUnitState(unit)
		else
			ns.RefreshRoster()
		end
	end)

	-- Light OnUpdate ticker (0.2s) to keep range status responsive live
	local timer = 0
	watcher:SetScript("OnUpdate", function(_, elapsed)
		if ns.testModeActive then return end
		timer = timer + elapsed
		if timer >= 0.2 then
			timer = 0
			for i = 1, MAX_SLOTS do
				if slots[i].unit then
					ns.RefreshUnitState(slots[i].unit)
				end
			end
		end
	end)

	ns.RefreshRoster()
end
