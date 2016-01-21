local myname, Cork = ...
if Cork.MYCLASS ~= "HUNTER" then return end

local ae = LibStub("AceEvent-3.0")
local IconLine = Cork.IconLine

local EXOTIC_MUNITIONS_ID = 162534
local munitionids = {
	162537,
	162536,
	162539,
}

munitionnames, munitionicons = {}, {}
for i = 1, #munitionids do
	local id = munitionids[i]
	local name, _, icon = GetSpellInfo(id)
	munitionnames[id] = name
	munitionicons[name] = icon
end

local dataobj = Cork:GenerateAdvancedSelfBuffer("Exotic Munitions", munitionids)

dataobj.Test = function()
	if not Cork.dbpc["Exotic Munitions-enabled"] or (IsResting() and not Cork.db.debug) then
		return
	end
	for _, spellname in pairs(munitionnames) do
		if (UnitBuff("player", spellname)) then return end
	end
	local spell = Cork.dbpc["Exotic Munitions-spell"]
	local icon = munitionicons[spell]
	return IconLine(icon, spell)
end

ae.RegisterEvent(dataobj, "PLAYER_TALENT_UPDATE", function()
	if not IsPlayerSpell(EXOTIC_MUNITIONS_ID) then
		ae.UnregisterEvent(dataobj, "UNIT_AURA")
		dataobj.player = nil
	else
		ae.RegisterEvent(dataobj, "UNIT_AURA", function(event, name)
			if unit == "player" then
				dataobj.player = dataobj.Test()
			end
		end)
		dataobj.player = dataobj.Test()
	end
end)

-- Trap Launcher
local spellname, _, icon = GetSpellInfo(77769)
Cork:GenerateSelfBuffer(spellname, icon)
