--[[
Name: oUF_QuaicheGroup
Author: Quaiche
Description: Group/raid frames for my custom UI

Copyright 2008 Quaiche

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
--]]

local liboufq = LibStub:GetLibrary("LibOufQuaiche")

--- Configuration parameters
local group_left, group_top = 10, -25
local party_spacing = 2
local raid_spacing = 2
local raid_group_spacing = 8
local raid_width = 100

liboufq.UnitSpecific["party"] = function(settings, self)
	-- LFD Role Icon
	local lfdRole  = self.Health:CreateTexture(nil, "OVERLAY")
	lfdRole:SetHeight(16); lfdRole:SetWidth(16)
	lfdRole:SetPoint("CENTER", self, "RIGHT", 3)
	self.LFDRole = lfdRole

	-- Support for oUF_ReadyCheck
	local readycheck = self.Health:CreateTexture(nil, "OVERLAY")
	readycheck:SetHeight(12)
	readycheck:SetWidth(12)
	readycheck:SetPoint("CENTER", self, "TOPRIGHT", 0, 0)
	readycheck:Hide()
	self.ReadyCheck = readycheck

	-- Range fading on party and partypets
	if  not hide_decorations then
		self.Range = true
		self.inRangeAlpha = 1
		self.outsideRangeAlpha = .5
	end
end

--------------------------------------------------------------
-- Style registration

oUF:RegisterStyle("Quaiche_Party", setmetatable({
	["initial-width"] = 125,
	["initial-height"] = 25,
	["powerbar-height"] = 5,
}, {__call = liboufq.CommonUnitSetup}))

oUF:RegisterStyle("Quaiche_Raid", setmetatable({
	["initial-width"] = raid_width,
	["initial-height"] = 18,
	["powerbar-height"] = 2,
}, {__call = liboufq.CommonUnitSetup}))

oUF:RegisterStyle("Quaiche_MainTank", setmetatable({
	["initial-width"] = raid_width,
	["initial-height"] = 18,
	["powerbar-height"] = 2,
	["hide-decorations"] = true,
}, {__call = liboufq.CommonUnitSetup}))

--------------------------------------------------------------
-- Spawn frames

local raidGroupsHeaders = {}

-- Party header
oUF:SetActiveStyle("Quaiche_Party") 
local party = oUF:Spawn("header", "oUF_Party")
party:SetPoint("TOPLEFT", group_left, group_top)
party:SetManyAttributes(
	"showParty", true,
	"yOffset", -party_spacing,
	"template", "oUF_QuaichePartyPets"
)
party:Show()

-- Raid headers (groups 1-5 only)
oUF:SetActiveStyle("Quaiche_Raid")
local raid = {}
for i = 1, 5 do --NUM_RAID_GROUPS do
	local raidGroup = oUF:Spawn("header", "oUF_Raid" .. i)
	raidGroup:SetManyAttributes(
		"groupFilter", tostring(i),
		"showraid", true,
		"yOffset", -raid_spacing,
		"template", "oUF_QuaicheRaidPets"
	)

	if i == 1 then
		raidGroup:SetPoint("TOPLEFT", group_left, group_top)
	else
		raidGroup:SetPoint("TOPLEFT", raidGroupsHeaders[i-1], "BOTTOMLEFT", 0, -raid_group_spacing)
	end

	table.insert(raidGroupsHeaders, raidGroup)
	raidGroup:Show()
end

-- Maintank stuff w/ oRA3 support
oUF:SetActiveStyle("Quaiche_MainTank")
local maintanks = oUF:Spawn("header", "oUF_MainTanks")
maintanks:SetPoint("TOPLEFT", UIParent, "TOP", -150, group_top)
maintanks:SetManyAttributes(
	"yOffset", raid_spacing,
	"template", "oUF_QuaicheMainTank",
	"showRaid", true,
	"initial-unitWatch", true,
	"point", "BOTTOM",
	"sortDir", "DESC"
)

--------------------------------------------------------------
-- Event handler frame
local eventFrame = CreateFrame('Frame')
eventFrame:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)

-- oRA2 MainTank stuff
if oRA3 then
	function eventFrame:OnTanksUpdated(event, tanks) maintanks:SetAttribute("nameList", table.concat(tanks, ",")) end
	eventFrame:OnTanksUpdated(nil, oRA3:GetSortedTanks())
	oRA3.RegisterCallback(eventFrame, "OnTanksUpdated")
	maintanks:Show()
else
	maintanks:SetAttribute("groupFilter", "MAINTANK,MAINASSIST")
end

-- Check Party Visibility Helper function and event handlers
local function CheckPartyVisibility(self) 
	if(InCombatLockdown()) then
		self:RegisterEvent('PLAYER_REGEN_ENABLED') -- defer this until OOC
	else
		self:UnregisterEvent('PLAYER_REGEN_DISABLED') -- just in case
		if GetNumRaidMembers() > 0 then
			party:Hide()
		else
			party:Show()
		end
	end
end
eventFrame.PLAYER_LOGIN = CheckPartyVisibility
eventFrame.PARTY_LEADER_CHANGED = CheckPartyVisibility
eventFrame.PARTY_MEMBERS_CHANGED = CheckPartyVisibility
eventFrame.PLAYER_REGEN_ENABLED = CheckPartyVisibility
eventFrame.PLAYER_REGEN_DISABLED = CheckPartyVisibility
eventFrame.RAID_ROSTER_UPDATE = CheckPartyVisibility

-- Register all events
eventFrame:RegisterEvent('PLAYER_LOGIN')
eventFrame:RegisterEvent('RAID_ROSTER_UPDATE')
eventFrame:RegisterEvent('PARTY_LEADER_CHANGED')
eventFrame:RegisterEvent('PARTY_MEMBERS_CHANGED')

