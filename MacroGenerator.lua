
local myname, Cork = ...
local MAX_ACCOUNT_MACROS, MAX_CHARACTER_MACROS = 36, 18

local function GetMacroID()
	for i=(MAX_ACCOUNT_MACROS+1),(MAX_ACCOUNT_MACROS+MAX_CHARACTER_MACROS) do if GetMacroInfo(i) == "Cork" then return i end end
end

function Cork.GenerateMacro()
	if InCombatLockdown() then return end

	local id = GetMacroID()
	if id then PickupMacro(id)
	elseif select(2, GetNumMacros()) < MAX_CHARACTER_MACROS then
		local body, ic, ooc
		local icon = "INV_MISC_QUESTIONMARK"
		local c = Cork.MYCLASS
		if c == "DEATHKNIGHT" then ooc = 3714 -- Path of Frost
		elseif c == "HUNTER"  then ooc = 5118 -- Aspect of Cheetah
		elseif c == "SHAMAN"  then ooc = 324 -- Lightning Shield
		elseif c == "WARLOCK" then ooc = 6201 -- Create Heartstone
		elseif c == "WARRIOR" then ooc = 6673 -- Battle Shout
		elseif c == "MONK"    then ooc = 115921 -- Legacy of the Emperor
		elseif c == "ROGUE"   then ooc = 2823 -- Deadly Poison
		elseif c == "DRUID"   then ic, ooc = 22812, 1126 -- Barskin, Mark of the Wild
		elseif c == "MAGE"    then ic, ooc = 30482, 1459 -- Molten Armor, Arcane Brilliance
		elseif c == "PALADIN" then ic, ooc = 20165, 19740 -- Seal of Insight, Blessing of Might
		elseif c == "PRIEST"  then ooc = 21562 -- Power Word: Fortitude
		end
		if ic and ooc then
			ic, ooc = GetSpellInfo(ic), GetSpellInfo(ooc)
			body = "#showtooltip [combat] "..ic.."; "..ooc.."\n/cast [combat] "..ic.."\n/stopmacro [combat]\n/click CorkFrame"
		elseif ooc then
			local ooc, _, texture = GetSpellInfo(ooc)
			texture = texture:upper():match("^INTERFACE\\ICONS\\(.+)")
			if texture then
				icon = texture
				body = "#showtooltip "..ooc.."\n/cast [nocombat] "..ooc.. "\n/click CorkFrame"
			else
				body = "/click CorkFrame"
			end
		else
			body = "/click CorkFrame"
		end
		local id = CreateMacro("Cork", icon, body, true)
		PickupMacro(id)
	end
end
