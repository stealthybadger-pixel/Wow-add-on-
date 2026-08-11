local ADDON_NAME, ns = ...

-- Reference dimensions from 02 - Unit Frame Design.md section 2
-- (200-220px wide, ~50px tall family, before scale presets are applied).
local FRAME_WIDTH = 210
local FRAME_HEIGHT = 56
local FRAME_GAP = 6
local ROLE_COLUMN_WIDTH = 46
local ROLE_ICON_SIZE = 20
local HEALTH_BAR_HEIGHT = 5
local MAX_SLOTS = 5
local MAX_HOTS = 5
local HOT_ICON_SIZE = 11
local HOT_BAR_HEIGHT = 34

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

local function GetStaticSpellIcon(displaySpellId, fallbackIcon)
	if C_Spell and C_Spell.GetSpellInfo then
		local info = C_Spell.GetSpellInfo(displaySpellId)
		if info and info.iconID then
			return info.iconID
		end
	end
	if GetSpellTexture then
		local tex = GetSpellTexture(displaySpellId)
		if tex then
			return tex
		end
	end
	return fallbackIcon
end

-- Master HoT definitions organized by Class -> Spec Index
-- Decouples detection query IDs from official display spell IDs and static icons.
local MASTER_HOT_SPELLS = {
	MONK = {
		[2] = { -- Mistweaver Monk
			specName = "Mistweaver",
			spells = {
				{
					name = "Renewing Mist",
					displaySpellId = 119611,
					querySpellIds = { 119611, 274968 },
					fallbackIcon = 136074,
				},
				{
					name = "Enveloping Mist",
					displaySpellId = 124682,
					querySpellIds = { 124682 },
					fallbackIcon = 136035,
				},
				{
					name = "Soothing Mist",
					displaySpellId = 115175,
					querySpellIds = { 115175 },
					fallbackIcon = 136098,
				},
				{
					name = "Essence Font",
					displaySpellId = 191840,
					querySpellIds = { 191840, 191837 },
					fallbackIcon = 136054,
				},
				{
					name = "Enveloping Breath",
					displaySpellId = 325209,
					querySpellIds = { 325209 },
					fallbackIcon = 136035,
				},
				{
					name = "Life Cocoon",
					displaySpellId = 116849,
					querySpellIds = { 116849 },
					fallbackIcon = 136089,
				},
			},
		},
	},
	DRUID = {
		[4] = { -- Restoration Druid
			specName = "Restoration",
			spells = {
				{ name = "Rejuvenation", displaySpellId = 774, querySpellIds = { 774 }, fallbackIcon = 136081 },
				{ name = "Regrowth", displaySpellId = 8936, querySpellIds = { 8936 }, fallbackIcon = 136085 },
				{ name = "Lifebloom", displaySpellId = 33763, querySpellIds = { 33763 }, fallbackIcon = 136042 },
				{ name = "Wild Growth", displaySpellId = 48438, querySpellIds = { 48438 }, fallbackIcon = 136088 },
			},
		},
	},
	PRIEST = {
		[2] = { -- Holy Priest
			specName = "Holy",
			spells = {
				{ name = "Renew", displaySpellId = 139, querySpellIds = { 139 }, fallbackIcon = 135939 },
				{ name = "Prayer of Mending", displaySpellId = 41635, querySpellIds = { 41635 }, fallbackIcon = 135944 },
			},
		},
		[1] = { -- Discipline Priest
			specName = "Discipline",
			spells = {
				{ name = "Atonement", displaySpellId = 194384, querySpellIds = { 194384 }, fallbackIcon = 135980 },
			},
		},
	},
	PALADIN = {
		[1] = { -- Holy Paladin
			specName = "Holy",
			spells = {
				{ name = "Beacon of Light", displaySpellId = 53563, querySpellIds = { 53563 }, fallbackIcon = 135880 },
			},
		},
	},
	SHAMAN = {
		[3] = { -- Restoration Shaman
			specName = "Restoration",
			spells = {
				{ name = "Riptide", displaySpellId = 61295, querySpellIds = { 61295 }, fallbackIcon = 237566 },
				{ name = "Earth Shield", displaySpellId = 974, querySpellIds = { 974 }, fallbackIcon = 136089 },
			},
		},
	},
	EVOKER = {
		[2] = { -- Preservation Evoker
			specName = "Preservation",
			spells = {
				{ name = "Reversion", displaySpellId = 366155, querySpellIds = { 366155 }, fallbackIcon = 4622478 },
				{ name = "Dream Breath", displaySpellId = 355941, querySpellIds = { 355941 }, fallbackIcon = 4622452 },
			},
		},
	},
}

local activeTrackedHots = {}
local activeSpecTitle = "None / Unsupported"

local function GetActiveHotDefinitions()
	if not activeTrackedHots then
		return {}
	end
	return activeTrackedHots
end

function ns.UpdateActiveHoTSpells()
	activeTrackedHots = {}
	activeSpecTitle = "None / Unsupported"

	local _, className = UnitClass("player")
	local specIndex = GetSpecialization and GetSpecialization()

	if not className or not specIndex or specIndex == 0 then
		if ns.debugHots then
			print("|cff33ff99[MistPanel HoT]|r spec unavailable during initialization - using empty HoT list")
		end
		return
	end

	local specID, specName
	if GetSpecializationInfo then
		specID, specName = GetSpecializationInfo(specIndex)
	end

	if MASTER_HOT_SPELLS[className] and MASTER_HOT_SPELLS[className][specIndex] then
		local specData = MASTER_HOT_SPELLS[className][specIndex]
		activeSpecTitle = className .. " / " .. (specName or specData.specName)
		for _, spellData in ipairs(specData.spells) do
			local resolvedIcon = GetStaticSpellIcon(spellData.displaySpellId, spellData.fallbackIcon)
			table.insert(activeTrackedHots, {
				name = spellData.name,
				displaySpellId = spellData.displaySpellId,
				querySpellIds = spellData.querySpellIds,
				icon = resolvedIcon,
			})
		end
	end

	if ns.debugHots then
		print("|cff33ff99[MistPanel HoT]|r class=" .. tostring(className) .. " spec=" .. tostring(specName or specIndex) .. " active definitions=" .. tostring(#activeTrackedHots))
		for _, spellData in ipairs(activeTrackedHots) do
			local qList = table.concat(spellData.querySpellIds, ",")
			print(string.format("  - %s (displayID=%d, queryIDs=%s, icon=%s)",
				spellData.name, spellData.displaySpellId, qList, tostring(spellData.icon)))
		end
	end
end

-- Fixed colors for Phase 2 combat states
local COLOR_BORDER_DEFAULT = { 0.15, 0.15, 0.15, 0.9 }
local COLOR_BORDER_AGGRO   = { 1.00, 0.00, 0.00, 1.0 }
local COLOR_BORDER_DISPEL  = { 1.00, 0.20, 0.80, 1.0 } -- Pink / Magenta

-- Fixed simulated roster for "/mistpanel test" (developer test mode).
-- Extended to demonstrate My HoT visual layout (with EQ bars) and Targeted Danger prediction:
-- Slot 1: Tank with 2 active HoTs + Incoming Danger Cast (Shadow Bolt at 70% fill)
-- Slot 2: Healer with 1 active HoT
-- Slot 3: DPS 1 with 3 active HoTs + Pink Dispel + Incoming Danger Cast (Fireball at 90% fill)
-- Slot 4: DPS 2 with 0 HoTs
-- Slot 5: DPS 3 with 1 nearly-expired HoT
local TEST_ROSTER = {
	{
		role = "TANK", healthPct = 0.70, aggro = true, dispel = false, inRange = true, dead = false,
		hots = {
			{ spellId = 119611, icon = 136074, count = 1, duration = 20, expirationTime = 20 },
			{ spellId = 124682, icon = 136035, count = 1, duration = 6,  expirationTime = 4.2 },
		},
		danger = { icon = 136075, duration = 3.0, elapsed = 2.1 }
	},
	{
		role = "HEALER", healthPct = 1.00, aggro = false, dispel = false, inRange = true, dead = false,
		hots = {
			{ spellId = 119611, icon = 136074, count = 1, duration = 20, expirationTime = 18 },
		},
		danger = nil
	},
	{
		role = "DAMAGER", healthPct = 0.50, aggro = true, dispel = true, inRange = true, dead = false,
		hots = {
			{ spellId = 119611, icon = 136074, count = 2, duration = 20, expirationTime = 10 },
			{ spellId = 124682, icon = 136035, count = 1, duration = 6,  expirationTime = 2.4 },
			{ spellId = 191840, icon = 136054, count = 1, duration = 8,  expirationTime = 5.6 },
		},
		danger = { icon = 136075, duration = 3.0, elapsed = 2.7 }
	},
	{
		role = "DAMAGER", healthPct = 0.35, aggro = false, dispel = false, inRange = true, dead = false,
		hots = {},
		danger = nil
	},
	{
		role = "DAMAGER", healthPct = 0.10, aggro = false, dispel = false, inRange = true, dead = false,
		hots = {
			{ spellId = 119611, icon = 136074, count = 1, duration = 20, expirationTime = 2 },
		},
		danger = nil
	},
}

local container
local slots = {}
ns.testModeActive = false
ns.debugHots = false
ns.debugDanger = false
ns.hasActiveDangerCasts = false

-- Active tracked hostile casts keyed by casterGUID to prevent duplicate tracking
-- when the same physical mob is observable via multiple tokens (e.g., target & nameplate1).
local activeHostileCasts = {}

local function GetHostileCasterTokens()
	local tokens = { "boss1", "boss2", "boss3", "boss4", "boss5", "boss6", "boss7", "boss8", "target", "focus" }
	for i = 1, 40 do
		table.insert(tokens, "nameplate" .. i)
	end
	return tokens
end

local function IsHostileUnit(unit)
	if not unit or not UnitExists(unit) then return false end
	if UnitCanAttack("player", unit) or UnitIsEnemy("player", unit) then
		return true
	end
	local reaction = UnitReaction("player", unit)
	return reaction and reaction < 4
end

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
			if aura.dispelType and type(aura.dispelType) == "string" and dispellableTypes[aura.dispelType] then
				return true
			end
			index = index + 1
		end
	elseif UnitDebuff then
		local index = 1
		while true do
			local name, _, _, dispelType = UnitDebuff(unit, index)
			if not name then break end
			if dispelType and type(dispelType) == "string" and dispellableTypes[dispelType] then
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
	if not status or type(status) ~= "number" then return false end

	if ns.debugThreat then
		print(string.format("|cff33ff99[MistPanel Threat]|r unit=%s status=%d %s",
			tostring(unit), status, (status >= 2 and "|cffff0000[AGGRO]|r" or "[No Aggro]")))
	end

	-- In WoW Retail, UnitThreatSituation return values mean:
	-- nil / 0: No threat / low threat (not tanking or targeted)
	-- 1: High threat, but NOT targeted (about to pull aggro / DPS building threat)
	-- 2: Insecurely tanking (being targeted by mob, but another unit has higher threat)
	-- 3: Securely tanking (being targeted by mob and has highest threat)
	-- Meaningful aggro requiring visual emphasis corresponds to being targeted by mobs (status >= 2).
	return status >= 2
end

local function UnitIsInRange(unit)
	if not unit or not UnitExists(unit) then return false end
	-- Modern Retail WoW UnitInRange() returns secret booleans in tainted contexts.
	-- To ensure zero secret-value runtime errors, we safely return true for valid units.
	return true
end

local function UnitIsDead(unit)
	if not unit or not UnitExists(unit) then return false end
	return UnitIsDeadOrGhost(unit) or not UnitIsConnected(unit)
end

local function GetUnitPlayerHoTs(unit)
	local hots = {}
	if not unit or not UnitExists(unit) then return hots end

	-- Query player-cast aura directly using querySpellIds list and Blizzard's HELPFUL|PLAYER engine filter.
	local activeDefinitions = GetActiveHotDefinitions()
	for _, info in ipairs(activeDefinitions) do
		if #hots >= MAX_HOTS then break end

		local aura
		for _, qId in ipairs(info.querySpellIds) do
			if AuraUtil and AuraUtil.FindAuraBySpellID then
				aura = AuraUtil.FindAuraBySpellID(qId, unit, "HELPFUL|PLAYER")
			end

			if not aura and C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
				local index = 1
				while true do
					local a = C_UnitAuras.GetAuraDataByIndex(unit, index, "HELPFUL|PLAYER")
					if not a then break end
					local isMatch = false
					pcall(function()
						if a.spellId and a.spellId == qId then
							isMatch = true
						end
					end)
					if isMatch then
						aura = a
						break
					end
					index = index + 1
				end
			end

			if aura then break end
		end

		if ns.debugHots then
			print(string.format("|cff33ff99[MistPanel HoT]|r query %s (displayID %d) on %s -> %s",
				info.name, info.displaySpellId, tostring(unit), (aura and "|cff00ff00FOUND|r" or "not found")))
		end

		if aura then
			table.insert(hots, {
				spellId = info.displaySpellId,
				icon = info.icon,
				name = info.name,
				aura = aura,
			})
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
	local f = CreateFrame("Button", ADDON_NAME .. "Slot" .. index, container, "SecureUnitButtonTemplate,BackdropTemplate")
	f:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
	f:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
	})
	f:SetBackdropColor(0.04, 0.04, 0.04, 0.95)

	-- Secure click registration for Clique and default WoW targeting
	f:RegisterForClicks("AnyUp", "AnyDown")
	f:SetAttribute("*type1", "target")
	f:SetAttribute("*type2", "togglemenu")

	-- Register frame with Clique's third-party unit frame registry
	ClickCastFrames = ClickCastFrames or {}
	ClickCastFrames[f] = true
	if Clique and Clique.RegisterFrame then
		Clique:RegisterFrame(f)
	end

	-- Alt + Left Click drag to reposition the panel container out of combat
	f:HookScript("OnMouseDown", function(self, button)
		if button == "LeftButton" and IsAltKeyDown() and not InCombatLockdown() then
			container:StartMoving()
			container.isMoving = true
		end
	end)

	f:HookScript("OnMouseUp", function(self, button)
		if button == "LeftButton" and container.isMoving then
			container:StopMovingOrSizing()
			container.isMoving = false
			local point, _, relativePoint, x, y = container:GetPoint()
			ns.db.point = { point = point, relativePoint = relativePoint, x = x, y = y }
		end
	end)

	-- Soft outer glow layers rendered behind f
	local glowContainer = CreateFrame("Frame", nil, f)
	glowContainer:SetFrameLevel(math.max(0, f:GetFrameLevel() - 1))
	glowContainer:SetAllPoints(f)
	glowContainer:EnableMouse(false)

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
		layer:EnableMouse(false)
		glowLayers[i] = layer
	end

	-- Dedicated border overlay frame at a higher FrameLevel (f:GetFrameLevel() + 10)
	-- ensures the combat state outline is rendered above all interior slot content
	-- as a clean, uninterrupted outer border. Mouse interaction is disabled so clicks
	-- pass directly to the secure Button f underneath.
	local borderFrame = CreateFrame("Frame", nil, f, "BackdropTemplate")
	borderFrame:SetAllPoints(f)
	borderFrame:SetFrameLevel(f:GetFrameLevel() + 10)
	borderFrame:EnableMouse(false)
	borderFrame:SetBackdrop({
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = 1,
	})
	borderFrame:SetBackdropBorderColor(unpack(COLOR_BORDER_DEFAULT))

	-- Role Column (Left side - vertically centered role icon in 56px tall frame)
	local roleIcon = f:CreateTexture(nil, "ARTWORK")
	roleIcon:SetSize(ROLE_ICON_SIZE, ROLE_ICON_SIZE)
	roleIcon:SetPoint("CENTER", f, "TOPLEFT", ROLE_COLUMN_WIDTH / 2, -25)

	-- Subtle vertical divider separating role column from main area
	local divider = f:CreateTexture(nil, "ARTWORK")
	divider:SetPoint("TOPLEFT", f, "TOPLEFT", ROLE_COLUMN_WIDTH, -1)
	divider:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", ROLE_COLUMN_WIDTH, HEALTH_BAR_HEIGHT + 4)
	divider:SetWidth(1)
	divider:SetColorTexture(0.2, 0.2, 0.2, 0.6)

	-- Pre-created HoT icon frames pool with duration bar DIRECTLY ABOVE each 11x11 icon
	local hotIcons = {}
	local startX = ROLE_COLUMN_WIDTH + 6
	local iconGap = 4
	for i = 1, MAX_HOTS do
		local posX = startX + (i - 1) * (HOT_ICON_SIZE + iconGap)

		local durationBar = CreateFrame("StatusBar", nil, f)
		durationBar:SetSize(HOT_ICON_SIZE, 30) -- Shrunk by 2px to accommodate thin primary resource bar
		durationBar:SetPoint("TOPLEFT", f, "TOPLEFT", posX, -3)
		durationBar:SetOrientation("VERTICAL")
		durationBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
		durationBar:SetStatusBarColor(0.1, 0.9, 0.1)
		durationBar:EnableMouse(false)

		local durationBarBg = durationBar:CreateTexture(nil, "BACKGROUND")
		durationBarBg:SetAllPoints(durationBar)
		durationBarBg:SetColorTexture(0.04, 0.04, 0.04, 0.8)

		local iconFrame = CreateFrame("Frame", nil, f, "BackdropTemplate")
		iconFrame:SetSize(HOT_ICON_SIZE, HOT_ICON_SIZE)
		iconFrame:SetPoint("TOPLEFT", durationBar, "BOTTOMLEFT", 0, -1)
		iconFrame:EnableMouse(false)
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
		cd:EnableMouse(false)
		cd:Hide()

		local countText = iconFrame:CreateFontString(nil, "OVERLAY")
		countText:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", 0, 0)
		countText:SetFont(STANDARD_TEXT_FONT or "Fonts\\ARIALN.TTF", 7, "OUTLINE")
		countText:SetTextColor(1, 1, 1, 1)

		iconFrame.texture = tex
		iconFrame.cooldown = cd
		iconFrame.durationBar = durationBar
		iconFrame.durationBarBg = durationBarBg
		iconFrame.countText = countText

		iconFrame:Hide()
		durationBar:Hide()
		hotIcons[i] = iconFrame
	end

	-- Thin 3px primary resource bar anchored at bottom
	local powerBar = CreateFrame("StatusBar", nil, f)
	powerBar:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 1, 1)
	powerBar:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
	powerBar:SetHeight(3)
	powerBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
	powerBar:SetMinMaxValues(0, 1)
	powerBar:SetValue(1)
	powerBar:EnableMouse(false)

	local powerBarBg = powerBar:CreateTexture(nil, "BACKGROUND")
	powerBarBg:SetAllPoints(powerBar)
	powerBarBg:SetColorTexture(0.04, 0.04, 0.04, 0.8)

	-- 10px health bar anchored directly above powerBar
	local healthBar = CreateFrame("StatusBar", nil, f)
	healthBar:SetPoint("BOTTOMLEFT", powerBar, "TOPLEFT", 0, 1)
	healthBar:SetPoint("BOTTOMRIGHT", powerBar, "TOPRIGHT", 0, 1)
	healthBar:SetHeight(10)
	healthBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
	healthBar:SetMinMaxValues(0, 1)
	healthBar:SetValue(1)
	healthBar:EnableMouse(false)

	local healthBarBg = healthBar:CreateTexture(nil, "BACKGROUND")
	healthBarBg:SetAllPoints(healthBar)
	healthBarBg:SetColorTexture(0.08, 0.08, 0.08, 0.9)

	-- Cyan semi-transparent absorb/shield overlay bar rendered directly on healthBar
	local absorbBar = CreateFrame("StatusBar", nil, healthBar)
	absorbBar:SetAllPoints(healthBar)
	absorbBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
	absorbBar:SetStatusBarColor(0.2, 0.8, 1.0, 0.65)
	absorbBar:SetMinMaxValues(0, 1)
	absorbBar:SetValue(0)
	absorbBar:EnableMouse(false)
	absorbBar:Hide()

	-- Active self-defensive mitigation icon container (upper right main area)
	local defensiveFrame = CreateFrame("Frame", nil, f, "BackdropTemplate")
	defensiveFrame:SetSize(14, 14)
	defensiveFrame:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -4)
	defensiveFrame:EnableMouse(false)
	defensiveFrame:SetBackdrop({
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = 1,
	})
	defensiveFrame:SetBackdropBorderColor(1.0, 0.84, 0.0, 0.9) -- Subtle gold defensive border

	local defensiveIcon = defensiveFrame:CreateTexture(nil, "ARTWORK")
	defensiveIcon:SetAllPoints(defensiveFrame)
	defensiveIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	defensiveFrame:Hide()

	-- Incoming Danger Indicator Container (icon + horizontal cast bar) placed in central main area
	local dangerContainer = CreateFrame("Frame", nil, f)
	dangerContainer:SetSize(76, 16)
	dangerContainer:SetPoint("TOPLEFT", f, "TOPLEFT", ROLE_COLUMN_WIDTH + 80, -20)
	dangerContainer:EnableMouse(false)

	local dangerIcon = dangerContainer:CreateTexture(nil, "ARTWORK")
	dangerIcon:SetSize(14, 14)
	dangerIcon:SetPoint("LEFT", dangerContainer, "LEFT", 0, 0)
	dangerIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

	local dangerBar = CreateFrame("StatusBar", nil, dangerContainer, "BackdropTemplate")
	dangerBar:SetSize(58, 5)
	dangerBar:SetPoint("LEFT", dangerIcon, "RIGHT", 3, 0)
	dangerBar:SetOrientation("HORIZONTAL")
	dangerBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
	dangerBar:SetStatusBarColor(1.0, 0.4, 0.0, 1.0) -- Restrained Warning Orange/Red
	dangerBar:EnableMouse(false)
	dangerBar:SetBackdrop({
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = 1,
	})
	dangerBar:SetBackdropBorderColor(0.1, 0.1, 0.1, 0.8)

	local dangerBarBg = dangerBar:CreateTexture(nil, "BACKGROUND")
	dangerBarBg:SetAllPoints(dangerBar)
	dangerBarBg:SetColorTexture(0.04, 0.04, 0.04, 0.8)

	dangerContainer:Hide()

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
		powerBar = powerBar,
		powerBarBg = powerBarBg,
		absorbBar = absorbBar,
		defensiveFrame = defensiveFrame,
		defensiveIcon = defensiveIcon,
		dangerContainer = dangerContainer,
		dangerIcon = dangerIcon,
		dangerBar = dangerBar,
		dangerBarBg = dangerBarBg,
		unit = nil,
	}
end

local function CreateContainer()
	local c = CreateFrame("Frame", ADDON_NAME .. "Container", UIParent)
	c:SetSize(FRAME_WIDTH, (FRAME_HEIGHT * MAX_SLOTS) + (FRAME_GAP * (MAX_SLOTS - 1)))
	c:SetMovable(true)
	c:SetClampedToScreen(true)
	c:EnableMouse(false)

	c:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" and self.isMoving then
			self:StopMovingOrSizing()
			self.isMoving = false
			local point, _, relativePoint, x, y = self:GetPoint()
			ns.db.point = { point = point, relativePoint = relativePoint, x = x, y = y }
		end
	end)

	return c
end

local function ApplyPoint()
	local p = ns.db.point or { point = "TOPLEFT", relativePoint = "TOPLEFT", x = 20, y = -180 }
	container:ClearAllPoints()
	container:SetPoint(p.point or "TOPLEFT", UIParent, p.relativePoint or "TOPLEFT", p.x or 20, p.y or -180)
end

ns.pendingResetPos = false

function ns.ResetPosition()
	if InCombatLockdown() then
		ns.pendingResetPos = true
		print("|cff33ff99MistPanel|r: position reset will be applied after combat.")
		return
	end

	ns.pendingResetPos = false
	ns.db.point = { point = "TOPLEFT", relativePoint = "TOPLEFT", x = 20, y = -180 }
	if container then
		ApplyPoint()
	end
	print("|cff33ff99MistPanel|r: position reset to default left-side location.")
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
local function GetUnitRole(unit)
	if not unit or not UnitExists(unit) then return "NONE" end

	local role = UnitGroupRolesAssigned(unit)
	if role and role ~= "NONE" then
		return role
	end

	if UnitIsUnit(unit, "player") then
		if GetSpecialization and GetSpecializationRole then
			local spec = GetSpecialization()
			if spec then
				local specRole = GetSpecializationRole(spec)
				if specRole and specRole ~= "NONE" then
					return specRole
				end
			end
		end
	end

	return "NONE"
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
		local ra = ROLE_PRIORITY[GetUnitRole(a)] or ROLE_PRIORITY.NONE
		local rb = ROLE_PRIORITY[GetUnitRole(b)] or ROLE_PRIORITY.NONE
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
		local durationBar = iconFrame.durationBar
		local data = hots[i]
		if data then
			iconFrame.texture:SetTexture(data.icon)

			-- Always hide numeric duration text / radial sweeps
			if iconFrame.cooldown then
				iconFrame.cooldown:Hide()
			end

			-- Render vertical duration bar placed directly above the HoT icon (drains TOP -> BOTTOM)
			if ns.testModeActive then
				local dur = data.duration or 0
				local exp = data.expirationTime or 0
				local remaining = 0
				if exp <= dur then
					remaining = exp
				elseif exp > 0 and dur > 0 then
					remaining = math.max(0, exp - now)
				end

				if dur > 0 and remaining > 0 then
					durationBar:SetMinMaxValues(0, dur)
					durationBar:SetValue(remaining)
					durationBar:Show()
				else
					durationBar:Hide()
				end

				if data.count and data.count > 1 then
					iconFrame.countText:SetText(tostring(data.count))
					iconFrame.countText:Show()
				else
					iconFrame.countText:Hide()
				end
			else
				-- Live mode: Safely calculate vertical duration bar height via pcall
				local barSet = false
				if data.aura then
					pcall(function()
						local exp = data.aura.expirationTime
						local dur = data.aura.duration
						if exp and dur and dur > 0 and exp > 0 then
							local remaining = exp - now
							if remaining > 0 then
								durationBar:SetMinMaxValues(0, dur)
								durationBar:SetValue(math.max(0, math.min(dur, remaining)))
								durationBar:Show()
								barSet = true
							end
						end
					end)
				end
				if not barSet then
					durationBar:Hide()
				end

				-- Stack counts remain separate on BOTTOMRIGHT of icon
				local countSet = false
				if data.aura then
					pcall(function()
						local count = data.aura.applications or data.aura.count
						if count and count > 1 then
							iconFrame.countText:SetText(tostring(count))
							iconFrame.countText:Show()
							countSet = true
						end
					end)
				end
				if not countSet then
					iconFrame.countText:Hide()
				end
			end

			iconFrame:Show()
		else
			iconFrame:Hide()
			if durationBar then
				durationBar:Hide()
			end
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

local function UpdateClassBackground(slot, entryClass, isDead, inRange)
	local color = nil
	if ns.testModeActive and entryClass then
		color = RAID_CLASS_COLORS[entryClass]
	elseif slot.unit and UnitExists(slot.unit) then
		local _, classFileName = UnitClass(slot.unit)
		if classFileName then
			color = RAID_CLASS_COLORS[classFileName]
		end
	end

	if not color then
		color = { r = 0.2, g = 0.2, b = 0.2 }
	end

	-- Dark desaturated class tint (maintains UI widget readability)
	local r = color.r * 0.18 + 0.04
	local g = color.g * 0.18 + 0.04
	local b = color.b * 0.18 + 0.04
	local alpha = 0.92

	if isDead or not inRange then
		r = r * 0.4
		g = g * 0.4
		b = b * 0.4
	end

	slot.frame:SetBackdropColor(r, g, b, alpha)
end

local function UpdatePowerState(slot, entryPower)
	if not slot or not slot.powerBar then return end

	if ns.testModeActive and entryPower then
		slot.powerBar:SetMinMaxValues(0, entryPower.maxPower or 100)
		slot.powerBar:SetValue(entryPower.power or 0)
		local color = PowerBarColor[entryPower.powerType] or PowerBarColor[0]
		if color then
			slot.powerBar:SetStatusBarColor(color.r, color.g, color.b, 0.9)
		else
			slot.powerBar:SetStatusBarColor(0.0, 0.5, 1.0, 0.9)
		end
		slot.powerBar:Show()
		return
	end

	local unit = slot.unit
	if not unit or not UnitExists(unit) then
		slot.powerBar:Hide()
		return
	end

	local pType, pToken = UnitPowerType(unit)
	local curPower = UnitPower(unit, pType)
	local maxPower = UnitPowerMax(unit, pType)

	if maxPower and maxPower > 0 then
		slot.powerBar:SetMinMaxValues(0, maxPower)
		slot.powerBar:SetValue(curPower or 0)
		local color = PowerBarColor[pToken] or PowerBarColor[pType] or { r = 0.0, g = 0.5, b = 1.0 }
		slot.powerBar:SetStatusBarColor(color.r, color.g, color.b, 0.9)
		slot.powerBar:Show()
	else
		slot.powerBar:Hide()
	end
end

local function UpdateAbsorbState(slot, entryAbsorb)
	if not slot or not slot.absorbBar then return end

	if ns.testModeActive then
		if entryAbsorb and entryAbsorb > 0 then
			slot.absorbBar:SetMinMaxValues(0, 100)
			slot.absorbBar:SetValue(entryAbsorb)
			slot.absorbBar:Show()
		else
			slot.absorbBar:Hide()
		end
		return
	end

	local unit = slot.unit
	if not unit or not UnitExists(unit) or not UnitGetTotalAbsorbs then
		slot.absorbBar:Hide()
		return
	end

	local absorbs = UnitGetTotalAbsorbs(unit) or 0
	local maxHealth = UnitHealthMax(unit) or 1

	if absorbs > 0 and maxHealth > 0 then
		slot.absorbBar:SetMinMaxValues(0, maxHealth)
		slot.absorbBar:SetValue(absorbs)
		slot.absorbBar:Show()
	else
		slot.absorbBar:Hide()
	end
end

local function UpdateDefensiveState(slot, entryDefensive)
	if not slot or not slot.defensiveFrame then return end

	if ns.testModeActive then
		if entryDefensive and entryDefensive.icon then
			slot.defensiveIcon:SetTexture(entryDefensive.icon)
			slot.defensiveFrame:Show()
		else
			slot.defensiveFrame:Hide()
		end
		return
	end

	local unit = slot.unit
	if not unit or not UnitExists(unit) then
		slot.defensiveFrame:Hide()
		return
	end

	local foundIcon = nil
	if AuraUtil and AuraUtil.FindAura then
		AuraUtil.FindAura(function(name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId)
			if spellId and DEFENSIVE_AURA_IDS[spellId] then
				foundIcon = icon
				return true
			end
			return false
		end, unit, "HELPFUL")
	elseif C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
		for index = 1, 40 do
			local aura = C_UnitAuras.GetAuraDataByIndex(unit, index, "HELPFUL")
			if not aura then break end
			if aura.spellId and DEFENSIVE_AURA_IDS[aura.spellId] then
				foundIcon = aura.icon
				break
			end
		end
	end

	if foundIcon then
		slot.defensiveIcon:SetTexture(foundIcon)
		slot.defensiveFrame:Show()
	else
		slot.defensiveFrame:Hide()
	end
end

local function UpdateSlot(slot, unit)
	slot.unit = unit
	if not unit or not UnitExists(unit) then
		if not InCombatLockdown() then
			slot.frame:SetAttribute("unit", nil)
			slot.frame:Hide()
		end
		return
	end

	if not InCombatLockdown() then
		slot.frame:SetAttribute("unit", unit)
		slot.frame:Show()
	end

	RenderRoleIcon(slot, GetUnitRole(unit))

	-- Pass health and maxHealth directly to the C++ StatusBar widget methods.
	-- Modern Retail WoW unit health calls return secret values in tainted contexts,
	-- so we must not perform Lua arithmetic (/), comparisons (>), or percentage math on them.
	local maxHealth = UnitHealthMax(unit)
	local health = UnitHealth(unit)
	if maxHealth and health then
		slot.healthBar:SetMinMaxValues(0, maxHealth)
		slot.healthBar:SetValue(health)
	else
		slot.healthBar:SetMinMaxValues(0, 1)
		slot.healthBar:SetValue(1)
	end
	slot.healthBar:SetStatusBarColor(0.1, 0.9, 0.1)
	if slot.healthBarBg then
		slot.healthBarBg:SetColorTexture(0.08, 0.08, 0.08, 0.9)
	end

	RenderHotIcons(slot, GetUnitPlayerHoTs(unit))

	local isDead = UnitIsDead(unit)
	local inRange = isDead or UnitIsInRange(unit)
	local hasDispel = not isDead and UnitHasDispellableAura(unit)
	local hasAggro = not isDead and UnitHasAggro(unit)

	UpdateClassBackground(slot, nil, isDead, inRange)
	UpdatePowerState(slot, nil)
	UpdateAbsorbState(slot, nil)
	UpdateDefensiveState(slot, nil)

	RenderSlotState(slot, hasAggro, hasDispel, inRange, isDead)
end

-- Active tracked hostile casts keyed by safe unit token string (e.g. "boss1", "nameplate3")
-- rather than UnitGUID() which can be a secret string in tainted execution.
local activeHostileCasts = {}

local TOKEN_PRIORITY = {
	boss1 = 1, boss2 = 1, boss3 = 1, boss4 = 1, boss5 = 1, boss6 = 1, boss7 = 1, boss8 = 1,
	target = 2,
	focus = 3,
}

local function GetTokenPriority(unit)
	if unit and TOKEN_PRIORITY[unit] then
		return TOKEN_PRIORITY[unit]
	end
	return 4 -- Default priority for nameplates (nameplate1..40)
end

local function GetHostileCasterTokens()
	local tokens = { "boss1", "boss2", "boss3", "boss4", "boss5", "boss6", "boss7", "boss8", "target", "focus" }
	for i = 1, 40 do
		table.insert(tokens, "nameplate" .. i)
	end
	return tokens
end

local function IsHostileUnit(unit)
	if not unit or not UnitExists(unit) then return false end
	if UnitCanAttack("player", unit) or UnitIsEnemy("player", unit) then
		return true
	end
	local reaction = UnitReaction("player", unit)
	return reaction and reaction < 4
end

local function GetUnitCastOrChannelInfo(unit, event)
	if not unit then return nil end

	if event and (event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "UNIT_SPELLCAST_CHANNEL_UPDATE") then
		local name, text, texture = UnitChannelInfo(unit)
		if name ~= nil then
			return { texture = texture }
		end
		return nil
	end

	local name, text, texture = UnitCastingInfo(unit)
	if name ~= nil then
		return { texture = texture }
	end

	-- Fallback check for channeled spells if event was generic (e.g. UNIT_TARGET or NAME_PLATE_UNIT_ADDED)
	local cName, cText, cTexture = UnitChannelInfo(unit)
	if cName ~= nil then
		return { texture = cTexture }
	end

	return nil
end

local function GetHighestPriorityCastForSlot(slotUnit)
	if not slotUnit then return nil end
	local bestCast = nil
	local bestPriority = 999

	for unitToken, cast in pairs(activeHostileCasts) do
		if cast.matchedSlotUnit == slotUnit then
			local prio = GetTokenPriority(unitToken)
			if prio < bestPriority then
				bestPriority = prio
				bestCast = cast
			end
		end
	end
	return bestCast
end

function ns.RefreshDangerIndicators()
	if ns.testModeActive then return end

	-- Modern Retail WoW secret-value restriction:
	-- UnitIsUnit(hostileTarget, partyUnit) returns a secret boolean in tainted execution context.
	-- Lua branching on secret booleans is forbidden by the WoW engine to prevent automated targeted prediction.
	-- Therefore, live per-party-member slot prediction is safely disabled to prevent secret boolean crashes.
	for i = 1, MAX_SLOTS do
		local slot = slots[i]
		if slot and slot.dangerContainer then
			slot.dangerContainer:Hide()
		end
	end

	ns.hasActiveDangerCasts = false
end

local function UpdateHostileCastForUnit(unit, event)
	if not unit or not IsHostileUnit(unit) then return end

	local castInfo = GetUnitCastOrChannelInfo(unit, event)

	if not castInfo then
		if activeHostileCasts[unit] then
			activeHostileCasts[unit] = nil
			if ns.debugDanger then
				print(string.format("|cff33ff99[MistPanel Danger]|r cast ended on %s", tostring(unit)))
			end
			ns.RefreshDangerIndicators()
		end
		return
	end

	activeHostileCasts[unit] = {
		casterUnit = unit,
		icon = castInfo.texture,
	}

	if ns.debugDanger then
		print(string.format("|cff33ff99[MistPanel Danger]|r %s cast active (target relation restricted by Retail secret-value rules)", tostring(unit)))
	end

	ns.RefreshDangerIndicators()
end

local function ClearHostileCastForUnit(unit)
	if not unit then return end
	if activeHostileCasts[unit] then
		activeHostileCasts[unit] = nil
		if ns.debugDanger then
			print(string.format("|cff33ff99[MistPanel Danger]|r cleared cast on %s", tostring(unit)))
		end
		ns.RefreshDangerIndicators()
	end
end

local function AuditAllHostileCasters()
	local tokens = GetHostileCasterTokens()
	for _, token in ipairs(tokens) do
		if UnitExists(token) and IsHostileUnit(token) then
			UpdateHostileCastForUnit(token)
		else
			if activeHostileCasts[token] then
				activeHostileCasts[token] = nil
			end
		end
	end
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
	UpdateClassBackground(slot, entry.class, entry.dead, entry.inRange)
	UpdatePowerState(slot, entry)
	UpdateAbsorbState(slot, entry.absorb)
	UpdateDefensiveState(slot, entry.defensive)
	RenderSlotState(slot, entry.aggro, entry.dispel, entry.inRange, entry.dead)

	if entry.danger then
		slot.dangerIcon:SetTexture(entry.danger.icon or 136075)
		slot.dangerBar:SetMinMaxValues(0, entry.danger.duration or 1)
		slot.dangerBar:SetValue(entry.danger.elapsed or 0)
		slot.dangerContainer:Show()
	else
		slot.dangerContainer:Hide()
	end
end

ns.pendingRosterRefresh = false

function ns.RefreshRoster()
	if ns.testModeActive then
		return -- test mode owns rendering until toggled off
	end

	if InCombatLockdown() then
		ns.pendingRosterRefresh = true
		if ns.debugSecure then
			print("|cff33ff99[MistPanel Secure]|r InCombatLockdown active -> roster/attribute refresh deferred to PLAYER_REGEN_ENABLED")
		end
		-- Continue updating visual state for currently assigned slot units during combat
		for i = 1, MAX_SLOTS do
			if slots[i].unit then
				UpdateSlot(slots[i], slots[i].unit)
			end
		end
		return
	end

	ns.pendingRosterRefresh = false
	ns.UpdateActiveHoTSpells()
	local units = SortedRoster()
	for i = 1, MAX_SLOTS do
		UpdateSlot(slots[i], units[i])
	end
	container:SetShown(#units > 0)

	if ns.debugSecure then
		print(string.format("|cff33ff99[MistPanel Secure]|r inGroup=%s inRaid=%s count=%d",
			tostring(IsInGroup()), tostring(IsInRaid()), #units))
		if not IsInGroup() then
			print("  (Solo mode: panel hidden)")
		else
			for i = 1, MAX_SLOTS do
				local u = slots[i].unit
				local attrUnit = slots[i].frame:GetAttribute("unit")
				if u and UnitExists(u) then
					local name = UnitName(u) or "unknown"
					local role = GetUnitRole(u)
					print(string.format("  slot%d -> unit=%s -> attrUnit=%s -> %s -> %s", i, u, tostring(attrUnit), role, name))
				else
					print(string.format("  slot%d -> (hidden)", i))
				end
			end
		end
	end
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

ns.pendingBlizzardSuppression = false
ns.debugBlizzard = false

local AUDIT_FRAME_SPECS = {
	{ name = "PartyFrame", label = "PartyFrame (Modern EditMode Container)" },
	{ name = "PartyFrame.MemberFrame1", label = "PartyFrame.MemberFrame1" },
	{ name = "PartyFrame.MemberFrame2", label = "PartyFrame.MemberFrame2" },
	{ name = "PartyFrame.MemberFrame3", label = "PartyFrame.MemberFrame3" },
	{ name = "PartyFrame.MemberFrame4", label = "PartyFrame.MemberFrame4" },
	{ name = "CompactPartyFrame", label = "CompactPartyFrame (Legacy Compact Container)" },
	{ name = "CompactPartyFrameMember1", label = "CompactPartyFrameMember1" },
	{ name = "CompactPartyFrameMember2", label = "CompactPartyFrameMember2" },
	{ name = "CompactPartyFrameMember3", label = "CompactPartyFrameMember3" },
	{ name = "CompactPartyFrameMember4", label = "CompactPartyFrameMember4" },
	{ name = "CompactPartyFrameMember5", label = "CompactPartyFrameMember5" },
	{ name = "CompactRaidFrameContainer", label = "CompactRaidFrameContainer (Raid/Party Grid)" },
	{ name = "CompactRaidFrameManager", label = "CompactRaidFrameManager (Slide-out Manager)" },
	{ name = "CompactRaidFrame1", label = "CompactRaidFrame1 (Raid-Style Party Member 1)" },
	{ name = "CompactRaidFrame2", label = "CompactRaidFrame2 (Raid-Style Party Member 2)" },
	{ name = "CompactRaidFrame3", label = "CompactRaidFrame3 (Raid-Style Party Member 3)" },
	{ name = "CompactRaidFrame4", label = "CompactRaidFrame4 (Raid-Style Party Member 4)" },
	{ name = "CompactRaidFrame5", label = "CompactRaidFrame5 (Raid-Style Party Member 5)" },
	{ name = "PartyMemberFrame1", label = "PartyMemberFrame1 (Legacy Standard Frame 1)" },
	{ name = "PartyMemberFrame2", label = "PartyMemberFrame2 (Legacy Standard Frame 2)" },
	{ name = "PartyMemberFrame3", label = "PartyMemberFrame3 (Legacy Standard Frame 3)" },
	{ name = "PartyMemberFrame4", label = "PartyMemberFrame4 (Legacy Standard Frame 4)" },
	{ name = "PartyMemberBackground", label = "PartyMemberBackground" },
}

local function ResolveFrameObject(nameStr)
	if not nameStr then return nil end
	if nameStr:find("%.") then
		local parts = {}
		for p in nameStr:gmatch("[^%.]+") do
			table.insert(parts, p)
		end
		local obj = _G[parts[1]]
		for i = 2, #parts do
			if obj then
				obj = obj[parts[i]]
			end
		end
		return obj
	else
		return _G[nameStr]
	end
end

local function SuppressSingleFrame(frame)
	if not frame then return end
	pcall(function()
		if not InCombatLockdown() then
			frame:UnregisterAllEvents()
			frame:Hide()
			if HiddenFrame and frame ~= HiddenFrame then
				frame:SetParent(HiddenFrame)
			end
			RegisterStateDriver(frame, "visibility", "hide")
		end
	end)
end

local function UnsuppressSingleFrame(frame)
	if not frame then return end
	pcall(function()
		if not InCombatLockdown() then
			UnregisterStateDriver(frame, "visibility")
			if frame:GetParent() == HiddenFrame then
				frame:SetParent(UIParent)
			end
		end
	end)
end

function ns.ApplyBlizzardPartyFrameSuppression()
	if not ns.db.hideBlizzardPartyFrames then
		return
	end

	if InCombatLockdown() then
		ns.pendingBlizzardSuppression = true
		if ns.debugBlizzard then
			print("|cff33ff99[MistPanel Blizzard]|r InCombatLockdown active -> suppression deferred to PLAYER_REGEN_ENABLED")
		end
		return
	end

	ns.pendingBlizzardSuppression = false

	-- 1. Modern Retail PartyFrame & Dynamic FramePool Members
	if PartyFrame then
		SuppressSingleFrame(PartyFrame)
		if PartyFrame.PartyMemberFramePool then
			pcall(function()
				for child in PartyFrame.PartyMemberFramePool:EnumerateActive() do
					SuppressSingleFrame(child)
				end
			end)
		end
		for i = 1, 4 do
			local mf = PartyFrame["MemberFrame" .. i] or PartyFrame["PartyMemberFrame" .. i]
			if mf then SuppressSingleFrame(mf) end
		end
	end

	-- 2. CompactPartyFrame & CompactPartyFrameMember1..5
	if CompactPartyFrame then
		SuppressSingleFrame(CompactPartyFrame)
		for i = 1, 5 do
			local cpf = _G["CompactPartyFrameMember" .. i]
			if cpf then SuppressSingleFrame(cpf) end
		end
	end

	-- 3. CompactRaidFrameContainer, CompactRaidFrameManager & Raid Groups
	if CompactRaidFrameContainer then
		SuppressSingleFrame(CompactRaidFrameContainer)
	end
	if CompactRaidFrameManager then
		SuppressSingleFrame(CompactRaidFrameManager)
		if CompactRaidFrameManager_SetSetting then
			pcall(function()
				CompactRaidFrameManager_SetSetting("IsShown", "0")
			end)
		end
	end

	for g = 1, 8 do
		local grp = _G["CompactRaidGroup" .. g]
		if grp then SuppressSingleFrame(grp) end
		for m = 1, 5 do
			local member = _G["CompactRaidGroup" .. g .. "Member" .. m]
			if member then SuppressSingleFrame(member) end
		end
	end

	for i = 1, 5 do
		local crf = _G["CompactRaidFrame" .. i]
		if crf then SuppressSingleFrame(crf) end
	end

	-- 4. Legacy PartyMemberFrame1..4 & Background
	if PartyMemberBackground then
		SuppressSingleFrame(PartyMemberBackground)
	end
	for i = 1, 4 do
		local pmf = _G["PartyMemberFrame" .. i]
		if pmf then SuppressSingleFrame(pmf) end
	end

	if ns.debugBlizzard then
		local elvDetected = (_G["ElvUI"] or _G["ElvUF"]) and true or false
		print(string.format("|cff33ff99[MistPanel Blizzard]|r Advanced ElvUI-proven suppression applied. ElvUI detected=%s", tostring(elvDetected)))
	end
end

function ns.SetHideBlizzardPartyFrames(enabled)
	ns.db.hideBlizzardPartyFrames = enabled and true or false
	if ns.db.hideBlizzardPartyFrames then
		ns.ApplyBlizzardPartyFrameSuppression()
	else
		if not InCombatLockdown() then
			if PartyFrame then UnsuppressSingleFrame(PartyFrame) end
			if CompactPartyFrame then UnsuppressSingleFrame(CompactPartyFrame) end
			if CompactRaidFrameContainer then UnsuppressSingleFrame(CompactRaidFrameContainer) end
			if CompactRaidFrameManager then UnsuppressSingleFrame(CompactRaidFrameManager) end
			for i = 1, 5 do
				local crf = _G["CompactRaidFrame" .. i]
				if crf then UnsuppressSingleFrame(crf) end
				local cpf = _G["CompactPartyFrameMember" .. i]
				if cpf then UnsuppressSingleFrame(cpf) end
			end
			for i = 1, 4 do
				local pmf = _G["PartyMemberFrame" .. i]
				if pmf then UnsuppressSingleFrame(pmf) end
			end
		end
	end
end

function ns.PrintBlizzardDebug()
	print("|cff33ff99[MistPanel Blizzard]|r Deep Runtime Frame Audit:")
	print("  hideBlizzardPartyFrames setting: " .. tostring(ns.db.hideBlizzardPartyFrames))
	print("  InCombatLockdown: " .. tostring(InCombatLockdown()))
	local elvDetected = (_G["ElvUI"] or _G["ElvUF"]) and true or false
	print("  ElvUI detected: " .. tostring(elvDetected) .. (elvDetected and " (ElvUI owns custom ElvUF_Party unitframes)" or ""))

	for _, spec in ipairs(AUDIT_FRAME_SPECS) do
		local obj = ResolveFrameObject(spec.name)
		if obj then
			local shown = obj:IsShown() and "SHOWN" or "hidden"
			local visible = obj:IsVisible() and "|cffff0000[VISIBLE]|r" or "[not visible]"
			local alpha = obj:GetAlpha()
			local scale = obj:GetEffectiveScale()
			local prot = obj:IsProtected() and "protected" or "unprotected"
			local parent = obj:GetParent() and obj:GetParent():GetName() or "nil"
			local objType = obj:GetObjectType and obj:GetObjectType() or "Frame"
			print(string.format("  - %s (%s): %s %s (alpha=%.2f, scale=%.2f, %s, parent=%s)",
				spec.label, objType, shown, visible, alpha, scale, prot, parent))
		end
	end

	if PartyFrame and PartyFrame.PartyMemberFramePool then
		local count = 0
		pcall(function()
			for child in PartyFrame.PartyMemberFramePool:EnumerateActive() do
				count = count + 1
				local cName = child:GetName() or "AnonymousPoolFrame"
				local cShown = child:IsShown() and "SHOWN" or "hidden"
				local cVis = child:IsVisible() and "|cffff0000[VISIBLE]|r" or "[not visible]"
				local cParent = child:GetParent() and child:GetParent():GetName() or "nil"
				print(string.format("  - PartyFramePool Active Member %d (%s): %s %s (parent=%s)",
					count, cName, cShown, cVis, cParent))
			end
		end)
		print("  PartyFrame.PartyMemberFramePool active count: " .. tostring(count))
	end
end

function ns.PrintStatus()
	print("|cff33ff99MistPanel|r status:")
	print("  locked: " .. tostring(ns.db.locked))
	print("  scale: " .. tostring(ns.db.scale))
	print("  hideBlizzardPartyFrames: " .. tostring(ns.db.hideBlizzardPartyFrames))
	print("  in group (non-raid): " .. tostring(IsInGroup() and not IsInRaid()))
	print("  testMode: " .. tostring(ns.testModeActive))
	print("  debugHots: " .. tostring(ns.debugHots))
	print("  debugRoster: " .. tostring(ns.debugRoster))
	print("  debugThreat: " .. tostring(ns.debugThreat))
	print("  debugSecure: " .. tostring(ns.debugSecure))
	print("  debugDanger: " .. tostring(ns.debugDanger))
	print("  debugBlizzard: " .. tostring(ns.debugBlizzard))
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
	ns.ApplyBlizzardPartyFrameSuppression()

	-- Hook Blizzard's CompactUnitFrame update functions to ensure suppression stays active
	if CompactPartyFrame_UpdateVisibility and not ns.hookedCompactPartyFrame then
		ns.hookedCompactPartyFrame = true
		hooksecurefunc("CompactPartyFrame_UpdateVisibility", function()
			if ns.db.hideBlizzardPartyFrames and not InCombatLockdown() then
				ns.ApplyBlizzardPartyFrameSuppression()
			end
		end)
	end

	if CompactRaidFrameContainer_UpdateVisibility and not ns.hookedCompactRaidFrame then
		ns.hookedCompactRaidFrame = true
		hooksecurefunc("CompactRaidFrameContainer_UpdateVisibility", function()
			if ns.db.hideBlizzardPartyFrames and not InCombatLockdown() then
				ns.ApplyBlizzardPartyFrameSuppression()
			end
		end)
	end

	local watcher = CreateFrame("Frame")
	watcher:RegisterEvent("GROUP_ROSTER_UPDATE")
	watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
	watcher:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
	watcher:RegisterEvent("COMPACT_UNIT_FRAME_PROFILES_LOADED")
	watcher:RegisterEvent("PLAYER_ROLES_ASSIGNED")
	watcher:RegisterEvent("ROLE_CHANGED_INFORM")
	watcher:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
	watcher:RegisterEvent("UNIT_CONNECTION")
	watcher:RegisterEvent("UNIT_HEALTH")
	watcher:RegisterEvent("UNIT_MAXHEALTH")
	watcher:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
	watcher:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
	watcher:RegisterEvent("UNIT_AURA")
	watcher:RegisterEvent("UNIT_FLAGS")
	watcher:RegisterEvent("PLAYER_TALENT_UPDATE")

	-- Targeted Hostile Cast Prediction events
	watcher:RegisterEvent("UNIT_SPELLCAST_START")
	watcher:RegisterEvent("UNIT_SPELLCAST_STOP")
	watcher:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	watcher:RegisterEvent("UNIT_SPELLCAST_FAILED")
	watcher:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	watcher:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
	watcher:RegisterEvent("UNIT_TARGET")
	watcher:RegisterEvent("NAME_PLATE_UNIT_ADDED")
	watcher:RegisterEvent("NAME_PLATE_UNIT_REMOVED")

	watcher:SetScript("OnEvent", function(_, event, unit)
		if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_TARGET" or event == "NAME_PLATE_UNIT_ADDED" then
			UpdateHostileCastForUnit(unit)
		elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "NAME_PLATE_UNIT_REMOVED" then
			ClearHostileCastForUnit(unit)
		elseif event == "PLAYER_REGEN_ENABLED" then
			if ns.pendingResetPos then
				ns.ResetPosition()
			end
			if ns.pendingBlizzardSuppression then
				ns.ApplyBlizzardPartyFrameSuppression()
			end
			activeHostileCasts = {}
			ns.RefreshDangerIndicators()
			if ns.pendingRosterRefresh then
				ns.RefreshRoster()
			end
		elseif event == "PLAYER_ENTERING_WORLD" or event == "GROUP_ROSTER_UPDATE" or event == "EDIT_MODE_LAYOUTS_UPDATED" or event == "COMPACT_UNIT_FRAME_PROFILES_LOADED" then
			ns.ApplyBlizzardPartyFrameSuppression()
			ns.RefreshRoster()
		elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" or event == "UNIT_THREAT_SITUATION_UPDATE" or event == "UNIT_AURA" or event == "UNIT_FLAGS" then
			ns.RefreshUnitState(unit)
		elseif event == "UNIT_THREAT_LIST_UPDATE" then
			for i = 1, MAX_SLOTS do
				if slots[i].unit then
					ns.RefreshUnitState(slots[i].unit)
				end
			end
		else
			ns.RefreshRoster()
		end
	end)

	-- Light OnUpdate ticker (0.2s) with smooth danger progress animation
	local timer = 0
	local dangerTimer = 0
	watcher:SetScript("OnUpdate", function(_, elapsed)
		if ns.testModeActive then return end

		if ns.hasActiveDangerCasts then
			dangerTimer = dangerTimer + elapsed
			if dangerTimer >= 0.04 then
				dangerTimer = 0
				ns.RefreshDangerIndicators()
			end
		end

		timer = timer + elapsed
		if timer >= 0.2 then
			timer = 0
			AuditAllHostileCasters()
			for i = 1, MAX_SLOTS do
				if slots[i].unit then
					ns.RefreshUnitState(slots[i].unit)
				end
			end
		end
	end)

	ns.RefreshRoster()
end

function ns.RunPredictTest()
	print("|cff33ff99[MistPanel PredictTest]|r Running isolated secret boolean C++ pass-through investigation...")
	local testFrame = CreateFrame("Frame")

	-- 1. Test UnitIsUnit secret boolean pass-through into Frame:SetShown()
	local unitIsUnitVal = UnitIsUnit("targettarget", "player")
	local setShownOk, setShownErr = pcall(function()
		testFrame:SetShown(unitIsUnitVal)
	end)

	print(string.format("  Test 1: Frame:SetShown(UnitIsUnit('targettarget','player')) -> %s",
		(setShownOk and "|cff00ff00PASSED|r (SetShown accepted value)" or "|cffff0000FAILED|r (" .. tostring(setShownErr) .. ")")))

	-- 2. Test UnitIsUnit secret boolean pass-through into Frame:SetAlpha()
	local setAlphaOk, setAlphaErr = pcall(function()
		testFrame:SetAlpha(unitIsUnitVal and 1 or 0)
	end)

	print(string.format("  Test 2: Frame:SetAlpha(unitIsUnitVal) -> %s",
		(setAlphaOk and "|cff00ff00PASSED|r" or "|cffff0000FAILED|r (" .. tostring(setAlphaErr) .. ")")))

	print("|cff33ff99[MistPanel PredictTest]|r Investigation complete.")
end
