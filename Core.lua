
BINDING_HEADER_CORKFU = "FuBar - CorkFu"
BINDING_NAME_CORKFU_CORKFIRST = "Put a cork in it!"

------------------------------
--      Are you local?      --
------------------------------

local AceOO = AceLibrary("AceOO-2.0")
local selern = SpecialEventsEmbed:GetInstance("Learn Spell 1")
local compost = AceLibrary("Compost-2.0")
local dewdrop = AceLibrary("Dewdrop-2.0")
local tablet = AceLibrary("Tablet-2.0")
local tektech = TekTechEmbed:GetInstance("1")
local babble = BabbleLib:GetInstance("Class 1.1")

local groupthresh = 3
local templates, menus, menus3 = {}
local defaulticon, questionmark = "Interface\\Icons\\INV_Drink_11", "Interface\\Icons\\INV_Misc_QuestionMark"
local xpath = "Interface\\AddOns\\FuBar_CorkFu\\X.tga"
local sortbyname = function(a,b) return a and b and a:ToString() < b:ToString() end
local classes = {"DRUID", "HUNTER", "MAGE", "PALADIN", "PRIEST", "ROGUE", "SHAMAN", "WARLOCK", "WARRIOR"}
local loc = {
	nofilter = "No Filter",
	disabled = "Disabled",
	headerunit = "Unit ",
	headerparty = "Party ",
	targetplayer = "Target Player",
	targetnpc = "Target NPC",
	unit = "Unit",
	class = "Class",
	party = "Party",
	everyone = "Everyone",
	rescanall = "Rescan All",
}
local raidunitnum, partyids = {}, {player = "Self", pet = "Pet"}
for i=1,40 do raidunitnum["raid"..i] = i end
for i=1,4 do
	partyids["party"..i] = "Party"
	partyids["party"..i.."pet"] = "Party Pet"
end


-------------------------------------
--      Namespace Declaration      --
-------------------------------------

FuBar_CorkFu = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0", "AceConsole-2.0", "AceDB-2.0", "FuBarPlugin-2.0", "AceModuleCore-2.0")
FuBar_CorkFu:SetModuleMixins("AceEvent-2.0")
FuBar_CorkFu.loc = loc
FuBar_CorkFu.hasIcon = defaulticon
FuBar_CorkFu.clickableTooltip = true
FuBar_CorkFu.tooltipHiddenWhenEmpty = true
FuBar_CorkFu:RegisterDB("CorkFuDB")
FuBar_CorkFu:RegisterDefaults("char", {new = 0, total = 0})
FuBar_CorkFu:RegisterDefaults("profile", {
	playsounds = true,
	showminimap = false,
	chatalerts = true,
	showtext = true,
	showcount = true,
})


---------------------------
--      Ace Methods      --
---------------------------

function FuBar_CorkFu:OnInitialize()
--~~ 	self.var.modules = {}

	local interface = AceOO.Interface{
		GetIcon = "function",
		ItemValid = "function",
		UnitValid = "function",
		PutACorkInIt = "function",
		target = "string",
		OnTooltipUpdate = "function",
		GetTopItem = "function",
	}
	for name,module in self:IterateModules() do
		if not module.tagged then module.tagged = {} end

		assert(AceOO.inherits(module, interface), "Module "..name.." is not compatible")

		self:RegisterDefaults(name, "profile", module.defaultDB or {})
		module.db = self:AcquireDBNamespace(name)
	end

	menus = {self.Menu1, self.Menu2, self.Menu3, self.Menu4}
	menus3 = {
		Everyone          = self.Menu3Everyone,
		Unit              = self.Menu3Unit,
		Class             = self.Menu3Class,
		Party             = self.Menu3Party,
		["Target Player"] = self.Menu3Everyone,
		["Target NPC"]    = self.Menu3Everyone,
	}
end


function FuBar_CorkFu:OnEnable()
	selern:RegisterEvent(self, "SPECIAL_LEARNED_SPELL")
	self:RegisterBucketEvent("CorkFu_Update", 0.25, "Update")
end


function FuBar_CorkFu:OnDisable()
	self:UnregisterAllEvents()
	selern:UnregisterAllEvents(self)
end


--------------------------------
--      Module Prototype      --
--------------------------------

function FuBar_CorkFu.modulePrototype:ToggleFilter(unit, profile)
	assert(unit, "No unit passed")

	local v = self.db[profile or "profile"]["Filter ".. unit]
	if v == 1 then self.db[profile or "profile"]["Filter "..unit] = -1
	elseif v == -1 then self.db[profile or "profile"]["Filter "..unit] = nil
	else self.db[profile or "profile"]["Filter "..unit] = 1 end
	self:TriggerEvent("CorkFu_Update")
end


function FuBar_CorkFu.modulePrototype:SetFilter(unit, value, profile)
	assert(unit, "No unit passed")

	self.db[profile or "profile"]["Filter "..unit] = value
	self:TriggerEvent("CorkFu_Update")
end


function FuBar_CorkFu.modulePrototype:UnitIsFiltered(unit, profile)
	assert(unit, "No unit passed")
	assert(unit == "player" or UnitExists(unit), self:ToString().." - ".. unit.." does not exist")

	if self.target == "Self" then
		return UnitName(unit) ~= UnitName("player") or self.db[profile or "profile"]["Filter Everyone"] == -1
	end

	local istarget = unit == "target"
	local ispc = UnitIsPlayer(unit) and not UnitInParty(unit) and not UnitInRaid(unit)

	local pc = istarget and ispc and self.db[profile or "profile"]["Filter Target Player"]
	if pc then return pc == -1 end

	local npc = istarget and not ispc and self.db[profile or "profile"]["Filter Target NPC"]
	if npc then return npc == -1 end

	local byname = self.db[profile or "profile"]["Filter Unit "..UnitName(unit)]
	if byname then return byname == -1 end

	local _,class = UnitClass(unit)
	local byclass = class and self.db[profile or "profile"]["Filter Class ".. class]
	if byclass then return byclass == -1 end

	local i, g, byparty
	if GetNumRaidMembers() > 0 then _, _, i = string.find(unit, "raid(%d+)") end
	if i then _, _, g = GetRaidRosterInfo(tonumber(i)) end
	if g then byparty = self.db[profile or "profile"]["Filter Party "..g] end
	if byparty then return byparty == -1 end

	local everyone = self.db[profile or "profile"]["Filter Everyone"]
	if everyone then return everyone == -1 end
end


function FuBar_CorkFu:ToggleFilter(module, unit)
	module:ToggleFilter(unit)
end


function FuBar_CorkFu:SetFilter(module, unit, value)
	module:SetFilter(unit, value)
end


function FuBar_CorkFu:UnitIsFiltered(module, unit)
	module:UnitIsFiltered(unit)
end


---------------------------------
--      Template Handlers      --
---------------------------------

function FuBar_CorkFu:RegisterTemplate(name, template)
	assert(not templates[name], "Template already exists")
	templates[name] = template
end


function FuBar_CorkFu:GetTemplate(name)
	assert(templates[name], "Template doesn't exist")
	return templates[name]
end


------------------------------
--      Event Handlers      --
------------------------------

function FuBar_CorkFu:SPECIAL_LEARNED_SPELL(spell, rank)
	self:TriggerEvent("CorkFu_Rescan", spell)
	self:Update()
end


-----------------------------
--      FuBar Methods      --
-----------------------------

function FuBar_CorkFu:OnClick()
	self:CorkFirst()
end


function FuBar_CorkFu:OnTextUpdate()
	local icon, text = self:GetTopText()
	self:SetText(text or "CorkFu")
	self:SetIcon(icon or defaulticon)
end


function FuBar_CorkFu:OnTooltipUpdate()
	for _,i in self:IterateModules() do i:OnTooltipUpdate() end
end


function FuBar_CorkFu:OnMenuRequest(level, value, inTooltip, value1, value2, value3, value4)
	if inTooltip then return end

	local m, module = menus[level]
	if level > 1 then
		module = level == 2 and value or level == 3 and value1 or level == 4 and value2 or level == 5 and value3 or level == 6 and value4
	end

	if self:IsModule(module) and module.OnMenuRequest then
		module:OnMenuRequest(level, value, inTooltip, value1, value2, value3, value4)
	elseif m then m(self, level, value, inTooltip, value1, value2, value3, value4) end
end


----------------------------
--      Menu Methods      --
----------------------------

function FuBar_CorkFu:Menu1(level, value, inTooltip, value1, value2, value3, value4)
	local sortlist = compost:Acquire()
	for _,i in self:IterateModules() do table.insert(sortlist, i) end
	table.sort(sortlist, sortbyname)

	for _,v in ipairs(sortlist) do
		if v.Menu then v:Menu(level, value, inTooltip, value1, value2, value3, value4)
		elseif v:ItemValid() then
			if v.target == "Self" and not v.spells then
				local val = v.db.profile["Filter Everyone"]
				local x
				if val == nil then x = -1 end
				dewdrop:AddLine("text", v:ToString() or "No name???", "func", self.SetFilter, "arg1", self, "arg2", v,
					"arg3", "Everyone", "arg4", x, "checked", val, "checkIcon", xpath)
			else dewdrop:AddLine("text", v:ToString() or "No name???", "hasArrow", true, "value", v) end
		end
	end

	dewdrop:AddLine()
	dewdrop:AddLine("text", loc.rescanall, "func", self.RescanAll, "arg1", self)

	compost:Reclaim(sortlist)
end


function FuBar_CorkFu:Menu2(level, value, inTooltip, value1, value2, value3, value4)
	assert(self:IsModule(value), "Invalid Module")
	if value.Menu then
		value:Menu(level, value, inTooltip, value1, value2, value3, value4)
		return
	end

	if value.spells and value.target == "Self" then
		self:MenuSpells(value, "Everyone")
	elseif value.spells then
		local everyone = value.db.profile["Filter Everyone"]
		local pc = value.db.profile["Filter Target Player"]
		local npc = value.db.profile["Filter Target NPC"]

		dewdrop:AddLine("text", loc.targetplayer, "value", "Target Player", "hasArrow", true)
		dewdrop:AddLine("text", loc.targetnpc, "value", "Target NPC", "hasArrow", true)
		dewdrop:AddLine("text", loc.unit, "value", "Unit", "hasArrow", true)
		dewdrop:AddLine("text", loc.class, "value", "Class", "hasArrow", true)
		dewdrop:AddLine("text", loc.party, "value", "Party", "hasArrow", true)
		dewdrop:AddLine("text", loc.everyone, "value", "Everyone", "hasArrow", true)
	else
		local everyone = value.db.profile["Filter Everyone"]
		local pc = value.db.profile["Filter Target Player"]
		local npc = value.db.profile["Filter Target NPC"]

		dewdrop:AddLine("text", loc.targetplayer, "func", self.ToggleFilter, "arg1", self, "arg2", value,
			"arg3", "Target Player", "checked", pc, pc == -1 and "checkIcon", pc == -1 and xpath)
		dewdrop:AddLine("text", loc.targetnpc, "func", self.ToggleFilter, "arg1", self, "arg2", value,
			"arg3", "Target NPC", "checked", npc, npc == -1 and "checkIcon", npc == -1 and xpath)
		dewdrop:AddLine("text", loc.unit, "value", "Unit", "hasArrow", true)
		dewdrop:AddLine("text", loc.class, "value", "Class", "hasArrow", true)
		dewdrop:AddLine("text", loc.party, "value", "Party", "hasArrow", true)
		dewdrop:AddLine("text", loc.everyone, "func", self.ToggleFilter, "arg1", self, "arg2", value,
			"arg3", "Everyone", "checked", everyone, everyone == -1 and "checkIcon", everyone == -1 and xpath)
	end
end


function FuBar_CorkFu:Menu3(level, value, inTooltip, value1, value2, value3, value4)
	if value1.Menu then
		value1:Menu(level, value, inTooltip, value1, value2, value3, value4)
		return
	elseif menus3[value] then menus3[value](self, level, value, inTooltip, value1, value2, value3, value4) end
end


function FuBar_CorkFu:Menu3Everyone(level, value, inTooltip, value1, value2, value3, value4)
	self:MenuSpells(value1, value)
end


function FuBar_CorkFu:Menu3Party(level, value, inTooltip, value1, value2, value3, value4)
	for i=1,8 do
		if value1.spells then
			dewdrop:AddLine("text", loc.headerparty..i, "value", "Party "..i, "hasArrow", true)
		else
			local p = value1.db.profile["Filter Party "..i]

			dewdrop:AddLine("text", loc.headerparty..i, "func", self.ToggleFilter, "arg1", self, "arg2", value1,
				"arg3", "Party "..i, "checked", p, p == -1 and "checkIcon", p == -1 and xpath)
		end
	end
end


local function GetName(unit) local n,r = UnitName(unit) return n..((r and "of "..r) or "") end
function FuBar_CorkFu:Menu3Unit(level, value, inTooltip, value1, value2, value3, value4)
	local sortlist = compost:Acquire()
	local pmem, rmem = GetNumPartyMembers(), GetNumRaidMembers()
	if rmem > 0 then
		for i=1,rmem do
			table.insert(sortlist, GetName("raid"..i))
			local pet = string.format("raid%dpet", i)
			if UnitExists(pet) then table.insert(sortlist, GetName(pet)) end
		end
	elseif pmem > 0 then
		table.insert(sortlist, GetName("player"))
		if UnitExists("pet") then table.insert(sortlist, GetName("pet")) end
		for i=1,pmem do
			table.insert(sortlist, GetName("party"..i))
			local pet = string.format("party%dpet", i)
			if UnitExists(pet) then table.insert(sortlist, GetName(pet)) end
		end
	else
		table.insert(sortlist, GetName("player"))
		if UnitExists("pet") then table.insert(sortlist, GetName("pet")) end
	end

	table.sort(sortlist)

	for i,v in ipairs(sortlist) do
		if value1.spells then
			dewdrop:AddLine("text", v, "value", "Unit "..v, "hasArrow", true)
		else
			local p = value1.db.profile["Filter Unit "..v]

			dewdrop:AddLine("text", v, "func", self.ToggleFilter, "arg1", self, "arg2", value1,
				"arg3", "Unit "..v, "checked", p, p == -1 and "checkIcon", p == -1 and xpath)
		end
	end

	compost:Reclaim(sortlist)
end


function FuBar_CorkFu:Menu3Class(level, value, inTooltip, value1, value2, value3, value4)
	for _,v in pairs(classes) do
		local class = babble:GetLocalized(v)
		local clstxt = string.format("|cff%s%s|r", babble:GetHexColor(class), class)
		if value1.spells then
			dewdrop:AddLine("text", clstxt, "value", "Class "..v, "hasArrow", true)
		else
			local p = value1.db.profile["Filter Class "..v]

			dewdrop:AddLine("text", clstxt, "func", self.ToggleFilter, "arg1", self, "arg2", value1,
				"arg3", "Class "..v, "checked", p, p == -1 and "checkIcon", p == -1 and xpath)
		end
	end
end


function FuBar_CorkFu:Menu4(level, value, inTooltip, value1, value2, value3, value4)
	self:MenuSpells(value2, value)
end


function FuBar_CorkFu:MenuSpells(module, unit)
	assert(module, "No module passed")
	assert(unit, "No unit passed")

	local def = module.defaultspell
	local val = module.db.profile["Filter ".. unit] or (module.target == "Self" and def)
	local sortlist = compost:Acquire()
	for i in pairs(module.spells) do
		if tektech:SpellKnown(i) then table.insert(sortlist, i) end
	end
	table.sort(sortlist)

	if module.target ~= "Self" then
		dewdrop:AddLine("text", loc.nofilter, "func", self.SetFilter, "isRadio", true, "checked", not val, "arg1", self,
			"arg2", module, "arg3", unit)
	end
	dewdrop:AddLine("text", loc.disabled, "func", self.SetFilter, "isRadio", true, "checked", val == -1, "arg1", self,
		"arg2", module, "arg3", unit, "arg4", -1)
	for _,v in ipairs(sortlist) do
		local setval = (module.target == "Self" and (v ~= def and v)) or (module.target ~= "Self" and v)
		dewdrop:AddLine("text", v, "func", self.SetFilter, "isRadio", true, "checked", val == v,
			"arg1", self, "arg2", module, "arg3", unit, setval and "arg4", setval)
	end

	compost:Reclaim(sortlist)
end


------------------------------
--      Helper Methods      --
------------------------------

function FuBar_CorkFu:CorkFirst()
	if Detox and Detox:Clean() then return true end

	for name,module in self:IterateModules() do
		if module:ItemValid() and module:PutACorkInIt() then return end
	end
end


function FuBar_CorkFu:GetTopText()
	for name,module in self:IterateModules() do
		if module:ItemValid() then
			local icon, text = module:GetTopItem()
			if icon then return module:GetTopItem() end
		end
	end
end


function FuBar_CorkFu:RescanAll()
	self:TriggerEvent("CorkFu_Rescan", "All")
	self:Update()
end
