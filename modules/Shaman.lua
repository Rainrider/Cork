
local myname, Cork = ...
if Cork.MYCLASS ~= "SHAMAN" then return end


-- Self-shields
Cork:GenerateAdvancedSelfBuffer("Shields", {324, 52127, 974})


-- Earth Shield
local spellname, _, icon = GetSpellInfo(974)
Cork:GenerateLastBuffedBuffer(spellname, icon)
