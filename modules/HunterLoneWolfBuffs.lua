
local myname, Cork = ...
if Cork.MYCLASS ~= "HUNTER" then return end

local IconLine = Cork.IconLine
local ldb, ae = LibStub:GetLibrary("LibDataBroker-1.1"), LibStub("AceEvent-3.0")

local LONE_WOLF_ID = 155228
local LONE_WOLF = GetSpellInfo(155228)

-- The index matches the one of GetRaidBuffTrayAuraInfo
local buffs = {
	[1] = 160206, -- Stats => Lone Wolf: Power of the Primates
	[2] = 160199, -- Stamina => Lone Wolf: Fortitude of the Bear
	-- [3] = 19506, -- Attack Power => Trueshot Aura
	[4] = 160203, -- Haste => Lone Wolf: Haste of the Hyena
	[5] = 160205, -- Spell Power => Lone Wolf: Wisdom of the Serpent
	[6] = 160200, -- Critial => Lone Wolf: Ferocity of the Raptor
	[7] = 160198, -- Mastery => Lone Wolf: Grace of the Cat
	[8] = 172968, -- Multistrike => Lone Wolf: Quickness of the Dragonhawk
	[9] = 172967, -- Versatility => Lone Wolf: Versatility of the Ravager
}

local slots, icons = {}, {}
for slot, id in pairs(buffs) do
	local name, _, icon = GetSpellInfo(id)
	slots[name] = slot
	icons[name] = icon
end

Cork.defaultspc["Lone-Wolf-spell"] = next(slots)

local dataobj = ldb:NewDataObject("Cork Lone Wolf", {
	type = "cork",
	corktype = "buff",
})

function dataobj:Init()
	Cork.defaultspc["Lone-Wolf-enabled"] = IsPlayerSpell(LONE_WOLF_ID)
end

function dataobj:Test()
	if not Cork.dbpc["Lone-Wolf-enabled"] or (IsResting() and not Cork.db.debug) or not UnitBuff("player", LONE_WOLF) then
		return
	end
	local preferred = Cork.dbpc["Lone-Wolf-spell"]
	local buffmask = GetRaidBuffInfo()
	local score, selected = -1
	for spell, slot in pairs(slots) do
		local name = GetRaidBuffTrayAuraInfo(slot)
		if not name then
			local newScore = 0
			if spell == preferred then
				newScore = 2
			elseif bit.band(buffmask, bit.lshift(1, slot)) == 0 then
				newScore = 1
			end
			if score < newScore then
				selected, score = spell, newScore
			end
		elseif name == spell and UnitBuff("player", spell, nil, "PLAYER") then
			return
		end
	end
	return selected
end

local spell
function dataobj:Scan()
	spell = self:Test()
	self.player = spell and IconLine(icons[spell], spell) or nil
end

function dataobj:CorkIt(frame)
	if self.player then return frame:SetManyAttributes("type1", "spell", "spell", spell) end
end

ae.RegisterEvent("Cork Lone Wolf", "UNIT_AURA", function(event, unit)
	if unit == "player" then dataobj:Scan() end
end)
ae.RegisterEvent(dataobj, "PLAYER_UPDATE_RESTING", "Scan")

----------------------
--      Config      --
----------------------

local frame = CreateFrame("Frame", nil, Cork.config)
frame:SetWidth(1)
frame:SetHeight(1)
dataobj.configframe = frame
frame:Hide()

frame:SetScript("OnShow", function()
	local EDGEGAP, ROWHEIGHT, ROWGAP, GAP = 16, 18, 2, 4
	local buffbuttons = {}

	local function OnClick(self)
		Cork.dbpc["Lone-Wolf-spell"] = self.buff
		for buff,butt in pairs(buffbuttons) do butt:SetChecked(butt == self) end
		dataobj:Scan()
	end

	local function OnEnter(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetHyperlink(GetSpellLink(self.buff))
	end
	local function OnLeave() GameTooltip:Hide() end


	local lasticon
	for buff, slot in pairs(slots) do

		local butt = CreateFrame("CheckButton", nil, frame)
		butt:SetWidth(ROWHEIGHT) butt:SetHeight(ROWHEIGHT)

		local tex = butt:CreateTexture(nil, "BACKGROUND")
		tex:SetAllPoints()
		tex:SetTexture(icons[buff])
		tex:SetTexCoord(4/48, 44/48, 4/48, 44/48)
		butt.icon = tex

		butt:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
		butt:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
		butt:SetCheckedTexture("Interface\\Buttons\\CheckButtonHilight")

		if lasticon then lasticon:SetPoint("RIGHT", butt, "LEFT", -ROWGAP, 0) end

		butt.buff = buff
		butt:SetScript("OnClick", OnClick)
		butt:SetScript("OnEnter", OnEnter)
		butt:SetScript("OnLeave", OnLeave)
		butt:SetMotionScriptsWhileDisabled(true)

		buffbuttons[buff], lasticon = butt, butt
	end
	lasticon:SetPoint("RIGHT", 0, 0)

	local function Update(self)
		local enable = IsPlayerSpell(LONE_WOLF_ID)

		for buff,butt in pairs(buffbuttons) do
			butt:SetChecked(Cork.dbpc["Lone-Wolf-spell"] == buff)
			if enable then
				butt:Enable()
				butt.icon:SetVertexColor(1.0, 1.0, 1.0)
			else
				butt:Disable()
				butt.icon:SetVertexColor(0.4, 0.4, 0.4)
			end
		end
	end

	frame:SetScript("OnShow", Update)
	Update(frame)
end)
