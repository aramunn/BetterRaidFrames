-------------------------------------------------------------------------------------------
-- Client Lua Script for BetterRaidFrames
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "bit32"

local BetterRaidFrames = {}

-- TODO: This should be enums (string comparison already fails on esper)
local ktIdToClassSprite =
{
	[GameLib.CodeEnumClass.Esper] 			= "Icon_Windows_UI_CRB_Esper",
	[GameLib.CodeEnumClass.Medic] 			= "Icon_Windows_UI_CRB_Medic",
	[GameLib.CodeEnumClass.Stalker] 		= "Icon_Windows_UI_CRB_Stalker",
	[GameLib.CodeEnumClass.Warrior] 		= "Icon_Windows_UI_CRB_Warrior",
	[GameLib.CodeEnumClass.Engineer] 		= "Icon_Windows_UI_CRB_Engineer",
	[GameLib.CodeEnumClass.Spellslinger] 	= "Icon_Windows_UI_CRB_Spellslinger",
}

local ktIdToClassTooltip =
{
	[GameLib.CodeEnumClass.Esper] 			= "CRB_Esper",
	[GameLib.CodeEnumClass.Medic] 			= "CRB_Medic",
	[GameLib.CodeEnumClass.Stalker] 		= "ClassStalker",
	[GameLib.CodeEnumClass.Warrior] 		= "CRB_Warrior",
	[GameLib.CodeEnumClass.Engineer] 		= "CRB_Engineer",
	[GameLib.CodeEnumClass.Spellslinger] 	= "CRB_Spellslinger",
}

local ktIdToRoleSprite =  -- -1 is valid
{
	[-1] = "",
	[MatchingGame.Roles.Tank] 	= "sprRaid_Icon_RoleTank",
	[MatchingGame.Roles.Healer] = "sprRaid_Icon_RoleHealer",
	[MatchingGame.Roles.DPS] 	= "sprRaid_Icon_RoleDPS",
}

local ktIdToRoleTooltip =
{
	[-1] = "",
	[MatchingGame.Roles.Tank] 	= "Matching_Role_Tank",
	[MatchingGame.Roles.Healer] = "Matching_Role_Healer",
	[MatchingGame.Roles.DPS] 	= "Matching_Role_Dps",
}

local ktIdToLeaderSprite =  -- 0 is valid
{
	[0] = "",
	[1] = "CRB_Raid:sprRaid_Icon_Leader",
	[2] = "CRB_Raid:sprRaid_Icon_TankLeader",
	[3] = "CRB_Raid:sprRaid_Icon_AssistLeader",
	[4] = "CRB_Raid:sprRaid_Icon_2ndLeader",
}

local ktIdToLeaderTooltip =
{
	[0] = "",
	[1] = "RaidFrame_RaidLeader",
	[2] = "RaidFrame_MainTank",
	[3] = "RaidFrame_CombatAssist",
	[4] = "RaidFrame_RaidAssist",
}

local kstrRaidMarkerToSprite =
{
	"Icon_Windows_UI_CRB_Marker_Bomb",
	"Icon_Windows_UI_CRB_Marker_Ghost",
	"Icon_Windows_UI_CRB_Marker_Mask",
	"Icon_Windows_UI_CRB_Marker_Octopus",
	"Icon_Windows_UI_CRB_Marker_Pig",
	"Icon_Windows_UI_CRB_Marker_Chicken",
	"Icon_Windows_UI_CRB_Marker_Toaster",
	"Icon_Windows_UI_CRB_Marker_UFO",
}

local ktLootModeToString =
{
	[GroupLib.LootRule.Master] 			= "Group_MasterLoot",
	[GroupLib.LootRule.RoundRobin] 		= "Group_RoundRobin",
	[GroupLib.LootRule.FreeForAll] 		= "Group_FFA",
	[GroupLib.LootRule.NeedBeforeGreed] = "Group_NeedVsGreed",
}

local ktRoleNames =
{
	[-1] = "",
	[MatchingGame.Roles.Tank] = Apollo.GetString("RaidFrame_Tanks"),
	[MatchingGame.Roles.Healer] = Apollo.GetString("RaidFrame_Healers"),
	[MatchingGame.Roles.DPS] = Apollo.GetString("RaidFrame_DPS"),
}


local ktItemQualityToStr =
{
	[Item.CodeEnumItemQuality.Inferior] 		= Apollo.GetString("CRB_Inferior"),
	[Item.CodeEnumItemQuality.Average] 			= Apollo.GetString("CRB_Average"),
	[Item.CodeEnumItemQuality.Good] 			= Apollo.GetString("CRB_Good"),
	[Item.CodeEnumItemQuality.Excellent] 		= Apollo.GetString("CRB_Excellent"),
	[Item.CodeEnumItemQuality.Superb] 			= Apollo.GetString("CRB_Superb"),
	[Item.CodeEnumItemQuality.Legendary] 		= Apollo.GetString("CRB_Legendary"),
	[Item.CodeEnumItemQuality.Artifact]	 		= Apollo.GetString("CRB_Artifact")
}

local ktRowSizeIndexToPixels =
{
	[1] = 21, -- Previously 19
	[2] = 28,
	[3] = 33,
	[4] = 38,
	[5] = 42,
}

local ktGeneralCategories = {Apollo.GetString("RaidFrame_Members")}
local ktRoleCategoriesToUse = {Apollo.GetString("RaidFrame_Tanks"), Apollo.GetString("RaidFrame_Healers"), Apollo.GetString("RaidFrame_DPS")}

local knReadyCheckTimeout = 60 -- in seconds

local knSaveVersion = 3

local knDirtyNone = 0
local knDirtyLootRules = bit32.lshift(1, 0)
local knDirtyMembers = bit32.lshift(1, 1)
local knDirtyGeneral = bit32.lshift(1, 2)
local knDirtyResize = bit32.lshift(1, 3)

local DefaultSettings = {
	-- Built in settings
	bLockFrame			= false,
	bShowIcon_Leader 	= true,
	bShowIcon_Role		= false,
	bShowIcon_Class		= false,
	bShowIcon_Mark		= false,
	bShowFocus			= false,
	bShowCategories		= true,
	bShowNames			= true,
	bAutoLock_Combat	= true,
	nNumColumns			= 1,
	nRowSize			= 1,
	bRole_DPS			= true,
	bRole_Healer		= false,
	bRole_Tank			= false,
	
	-- Custom settings via /brf
	bShowHP_Full = false,
	bShowHP_K = false,
	bShowHP_Pct = false,
	bShowShield_K = false,
	bShowShield_Pct = false,
	bShowAbsorb_K = false,
	bTrackDebuffs = false,
	bShowShieldBar = true,
	bShowAbsorbBar = true,
}

DefaultSettings.__index = DefaultSettings	

function BetterRaidFrames:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

	o.arWindowMap = {}
	o.arMemberIndexToWindow = {}
	o.nDirtyFlag = 0

    return o
end

function BetterRaidFrames:Init()
    Apollo.RegisterAddon(self)
end

function BetterRaidFrames:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end

	local bHasReadyCheck = false
	if self.wndReadyCheckPopup and self.wndReadyCheckPopup:IsValid() then
		bHasReadyCheck = self.wndReadyCheckPopup:IsShown()
	end

	local tSave =
	{
		bReadyCheckShown 		= bHasReadyCheck,
		fReadyCheckStartTime 	= self.fReadyCheckStartTime,
		strReadyCheckInitiator	= self.strReadyCheckInitiator,
		strReadyCheckMessage	= self.strReadyCheckMessage,
		nReadyCheckResponses 	= self.nNumReadyCheckResponses,
		nSaveVersion 			= knSaveVersion,
	}
	
	self:copyTable(self.settings, tSave)

	return tSave
end

function BetterRaidFrames:OnRestore(eType, tSavedData)
	self.tSavedData = tSavedData
	if not tSavedData or tSavedData.nSaveVersion ~= knSaveVersion then
		return
	end


	local fDelta = tSavedData.fReadyCheckStartTime and os.clock() - tSavedData.fReadyCheckStartTime or knReadyCheckTimeout
	if fDelta < knReadyCheckTimeout then
		self.nNumReadyCheckResponses = 0
		self.fReadyCheckStartTime = tSavedData.fReadyCheckStartTime

		if tSavedData.bReadyCheckShown then
			if self.nNumReadyCheckResponses >= tSavedData.nReadyCheckResponses then

				self.strReadyCheckInitiator = tSavedData.strReadyCheckInitiator
				self.strReadyCheckMessage = tSavedData.strReadyCheckMessage
			end
		end
		Apollo.CreateTimer("ReadyCheckTimeout", math.ceil(knReadyCheckTimeout - fDelta), false)
	end
	
	self.settings = self:copyTable(tSavedData, self.settings)
end

function BetterRaidFrames:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("BetterRaidFrames.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
	
	-- Configured our forms
	self.wndConfig = Apollo.LoadForm(self.xmlDoc, "ConfigForm", nil, self)
	self.wndConfig:Show(false)
	
	-- Register handler for slash commands that open the configuration form
	Apollo.RegisterSlashCommand("brf", "OnConfigOn", self)
	
	self.settings = self.settings or {}
	setmetatable(self.settings, DefaultSettings)
end

function BetterRaidFrames:OnDocumentReady()
	if  self.xmlDoc == nil then
		return
	end
	Apollo.RegisterEventHandler("CharacterCreated", 						"OnCharacterCreated", self)
	Apollo.RegisterEventHandler("Group_Updated", 							"OnGroup_Updated", self)
	Apollo.RegisterEventHandler("Group_Join", 								"OnGroup_Join", self)
	Apollo.RegisterEventHandler("Group_Left", 								"OnGroup_Left", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", 						"OnEnteredCombat", self)
	Apollo.RegisterEventHandler("GenericEvent_Raid_ToggleRaidUnTear", 		"OnRaidUnTearOff", self)
	Apollo.RegisterEventHandler("GenericEvent_Raid_UncheckMasterLoot", 		"OnUncheckMasterLoot", self)
	Apollo.RegisterEventHandler("GenericEvent_Raid_UncheckLeaderOptions", 	"OnUncheckLeaderOptions", self)

	Apollo.RegisterEventHandler("Group_Add",								"OnGroup_Add", self)
	Apollo.RegisterEventHandler("Group_Remove",								"OnGroup_Remove", self) -- Kicked, or someone else leaves (yourself leaving is Group_Leave)
	Apollo.RegisterEventHandler("Group_ReadyCheck",							"OnGroup_ReadyCheck", self)
	Apollo.RegisterEventHandler("Group_MemberFlagsChanged",					"OnGroup_MemberFlagsChanged", self)
	Apollo.RegisterEventHandler("Group_FlagsChanged",						"OnGroup_FlagsChanged", self)
	Apollo.RegisterEventHandler("Group_LootRulesChanged",					"OnGroup_LootRulesChanged", self)
	Apollo.RegisterEventHandler("TargetUnitChanged", 						"OnTargetUnitChanged", self)
	Apollo.RegisterEventHandler("MasterLootUpdate",							"OnMasterLootUpdate", 	self)

	Apollo.RegisterTimerHandler("ReadyCheckTimeout", 						"OnReadyCheckTimeout", self)
	Apollo.RegisterEventHandler("VarChange_FrameCount", 					"OnRaidFrameBaseTimer", self)
	Apollo.RegisterEventHandler("ChangeWorld", 								"OnChangeWorld", self)
	
	-- Required for saving frame location across sessions
	Apollo.RegisterEventHandler("WindowManagementReady", 	"OnWindowManagementReady", self)
	
	-- Sets the party frame location once windows are ready.
	function BetterRaidFrames:OnWindowManagementReady()
		Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndMain, strName = "BetterRaidFrames" })
		self:LockFrameHelper(self.settings.bLockFrame)
		self:NumColumnsHelper()
		self:NumRowsHelper()
	end

	self.wndMain = Apollo.LoadForm(self.xmlDoc, "BetterRaidFramesForm", "FixedHudStratum", self)
    self.wndMain:FindChild("RaidConfigureBtn"):AttachWindow(self.wndMain:FindChild("RaidOptions"))

	self.wndRaidCategoryContainer = self.wndMain:FindChild("RaidCategoryContainer")
	self.wndRaidTitle = self.wndMain:FindChild("RaidTitle")
	self.wndRaidWrongInstance = self.wndMain:FindChild("RaidWrongInstance")
	self.wndRaidMasterLootIconOnly = self.wndMain:FindChild("RaidMasterLootIconOnly")
	self.wndRaidLeaderOptionsBtn = self.wndMain:FindChild("RaidLeaderOptionsBtn")
	self.wndRaidMasterLootBtn = self.wndMain:FindChild("RaidMasterLootBtn")
	self.wndGroupBagBtn = self.wndMain:FindChild("GroupBagBtn")
	self.wndRaidLockFrameBtn = self.wndMain:FindChild("RaidLockFrameBtn")

	local wndRaidOptions = self.wndMain:FindChild("RaidOptions:SelfConfigRaidCustomizeOptions")
	self.wndRaidCustomizeClassIcons = wndRaidOptions:FindChild("RaidCustomizeClassIcons")
	self.wndRaidCustomizeShowNames = wndRaidOptions:FindChild("RaidCustomizeShowNames")
	self.wndRaidCustomizeLeaderIcons = wndRaidOptions:FindChild("RaidCustomizeLeaderIcons")
	self.wndRaidCustomizeRoleIcons = wndRaidOptions:FindChild("RaidCustomizeRoleIcons")
	self.wndRaidCustomizeMarkIcons = wndRaidOptions:FindChild("RaidCustomizeMarkIcons")
	self.wndRaidCustomizeManaBar = wndRaidOptions:FindChild("RaidCustomizeManaBar")
	self.wndRaidCustomizeCategories = wndRaidOptions:FindChild("RaidCustomizeCategories")
	self.wndRaidCustomizeClassIcons = wndRaidOptions:FindChild("RaidCustomizeClassIcons")
	self.wndRaidCustomizeLockInCombat = wndRaidOptions:FindChild("RaidCustomizeLockInCombat")
	self.wndRaidCustomizeNumColAdd = wndRaidOptions:FindChild("RaidCustomizeNumColAdd")
	self.wndRaidCustomizeNumColSub = self.wndMain:FindChild("RaidCustomizeNumColSub")
	self.wndRaidCustomizeNumColValue = self.wndMain:FindChild("RaidCustomizeNumColValue")
	self.wndRaidCustomizeRowSizeSub = self.wndMain:FindChild("RaidCustomizeRowSizeSub")
	self.wndRaidCustomizeRowSizeAdd = self.wndMain:FindChild("RaidCustomizeRowSizeAdd")
	self.wndRaidCustomizeRowSizeValue = self.wndMain:FindChild("RaidCustomizeRowSizeValue")

	self.wndMain:Show(false)

	self.kstrMyName 				= ""
	self.tTearOffMemberIDs 			= {}

	if self.strReadyCheckInitiator and self.strReadyCheckMessage then
		local strMessage = String_GetWeaselString(Apollo.GetString("RaidFrame_ReadyCheckStarted"), self.strReadyCheckInitiator) .. "\n" .. self.strReadyCheckMessage
		self.wndReadyCheckPopup = Apollo.LoadForm(self.xmlDoc, "RaidReadyCheck", nil, self)
		self.wndReadyCheckPopup:SetData(wndReadyCheckPopup)
		self.wndReadyCheckPopup:FindChild("ReadyCheckNoBtn"):SetData(wndReadyCheckPopup)
		self.wndReadyCheckPopup:FindChild("ReadyCheckYesBtn"):SetData(wndReadyCheckPopup)
		self.wndReadyCheckPopup:FindChild("ReadyCheckCloseBtn"):SetData(wndReadyCheckPopup)
		self.wndReadyCheckPopup:FindChild("ReadyCheckMessage"):SetText(strMessage)
	else
		self.wndReadyCheckPopup 	= nil
	end

	self.bSwapToTwoColsOnce 		= false
	self.bTimerRunning 				= false
	self.nNumReadyCheckResponses 	= -1 -- -1 means no check, 0 and higher means there is a check
	self.nPrevMemberCount			= 0

	self:UpdateOffsets()

	local wndMeasure = Apollo.LoadForm(self.xmlDoc, "RaidCategory", nil, self)
	self.knWndCategoryHeight = wndMeasure:GetHeight()
	wndMeasure:Destroy()

	self.knWndMainHeight = self.wndMain:GetHeight()

	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer then
		self:OnCharacterCreated()
	end
	
	-- Refresh settings visually
	self:RefreshSettings()
end

function BetterRaidFrames:copyTable(from, to)
	if not from then return end
    to = to or {}
	for k,v in pairs(from) do
		to[k] = v
	end
    return to
end

function BetterRaidFrames:RefreshSettings()
	-- Settings related to the default customize options
	if self.settings.bShowIcon_Leader ~= nil then
		self.wndRaidCustomizeLeaderIcons:SetCheck(self.settings.bShowIcon_Leader) end
	if self.settings.bShowIcon_Role ~= nil then
		self.wndRaidCustomizeRoleIcons:SetCheck(self.settings.bShowIcon_Role) end
	if self.settings.bShowIcon_Class ~= nil then
		self.wndRaidCustomizeClassIcons:SetCheck(self.settings.bShowIcon_Class) end
	if self.settings.bShowIcon_Mark ~= nil then
		self.wndRaidCustomizeMarkIcons:SetCheck(self.settings.bShowIcon_Mark) end
	if self.settings.bShowFocus ~= nil then
		self.wndRaidCustomizeManaBar:SetCheck(self.settings.bShowFocus) end
	if self.settings.bShowCategories ~= nil then
		self.wndRaidCustomizeCategories:SetCheck(self.settings.bShowCategories) end
	if self.settings.bShowNames ~= nil then
		self.wndRaidCustomizeShowNames:SetCheck(self.settings.bShowNames) end
	if self.settings.bAutoLock_Combat ~= nil then
		self.wndRaidCustomizeLockInCombat:SetCheck(self.settings.bAutoLock_Combat) end

	-- Settings related to /brf settings frame
	if self.settings.bShowHP_Full ~= nil then
		self.wndConfig:FindChild("Button_ShowHP_Full"):SetCheck(self.settings.bShowHP_Full) end
	if self.settings.bShowHP_K ~= nil then
		self.wndConfig:FindChild("Button_ShowHP_K"):SetCheck(self.settings.bShowHP_K) end
	if self.settings.bShowHP_Pct ~= nil then
		self.wndConfig:FindChild("Button_ShowHP_Pct"):SetCheck(self.settings.bShowHP_Pct) end
	if self.settings.bShowShield_K ~= nil then
		self.wndConfig:FindChild("Button_ShowShield_K"):SetCheck(self.settings.bShowShield_K) end
	if self.settings.bShowShield_Pct ~= nil then
		self.wndConfig:FindChild("Button_ShowShield_Pct"):SetCheck(self.settings.bShowShield_Pct) end
	if self.settings.bShowAbsorb_K ~= nil then
		self.wndConfig:FindChild("Button_ShowAbsorb_K"):SetCheck(self.settings.bShowAbsorb_K) end
	if self.settings.bTrackDebuffs ~= nil then
		self.wndConfig:FindChild("Button_TrackDebuffs"):SetCheck(self.settings.bTrackDebuffs) end
	if self.settings.bShowShieldBar ~= nil then
		self.wndConfig:FindChild("Button_ShowShieldBar"):SetCheck(self.settings.bShowShieldBar) end
	if self.settings.bShowAbsorbBar ~= nil then
		self.wndConfig:FindChild("Button_ShowAbsorbBar"):SetCheck(self.settings.bShowAbsorbBar) end
end

function BetterRaidFrames:OnCharacterCreated()
	local unitPlayer = GameLib.GetPlayerUnit()
	self.kstrMyName = unitPlayer:GetName()
	self.unitTarget = GameLib.GetTargetUnit()

	self:BuildAllFrames()
	self:ResizeAllFrames()
end

function BetterRaidFrames:OnRaidFrameBaseTimer()
	if not GroupLib.InRaid() then
		if self.wndMain and self.wndMain:IsValid() and self.wndMain:IsShown() then
			self.wndMain:Show(false)
		end
		return
	end

	if not self.wndMain:IsShown() then
		self:OnMasterLootUpdate()
		self.wndMain:Show(true)
	end
	if self.nDirtyFlag > knDirtyNone then
		if bit32.btest(self.nDirtyFlag, knDirtyGeneral) then -- Rebuild everything
			self:BuildAllFrames()
			self.nDirtyFlag = bit32.bor(self.nDirtyFlag, knDirtyResize)
		elseif bit32.btest(self.nDirtyFlag, knDirtyMembers) then -- Fully update all members
			for idx, tRaidMember in pairs(self.arMemberIndexToWindow) do
				self:UpdateSpecificMember(tRaidMember, idx, GroupLib.GetGroupMember(idx), self.nPrevMemberCount, bFrameLocked)
			end
		else -- Fast update all members
			self:UpdateAllMembers()
		end

		if bit32.btest(self.nDirtyFlag, knDirtyLootRules) then
			self:UpdateLootRules()
		end

		if bit32.btest(self.nDirtyFlag, knDirtyResize) then
			self:ResizeAllFrames()
			if self.settings.nNumColumns then -- This is terrible
				self:ResizeAllFrames()
			end
		end
	else -- Fast update all members
		self:UpdateAllMembers()
	end

	self.nDirtyFlag = knDirtyNone
end

-----------------------------------------------------------------------------------------------
-- Main Draw Methods
-----------------------------------------------------------------------------------------------

function BetterRaidFrames:OnChangeWorld()
	self.nDirtyFlag = bit32.bor(self.nDirtyFlag, knDirtyGeneral)
end

function BetterRaidFrames:OnGroup_Join()
	if not GroupLib.InRaid() then return end
	self.nDirtyFlag = bit32.bor(self.nDirtyFlag, knDirtyGeneral)
end

function BetterRaidFrames:OnGroup_Add(strName)
	if not GroupLib.InRaid() then return end
	self.nDirtyFlag = bit32.bor(self.nDirtyFlag, knDirtyGeneral)
end

function BetterRaidFrames:OnGroup_Remove()
	if not GroupLib.InRaid() then return end

	self:DestroyMemberWindows(self.nPrevMemberCount)
	self.nPrevMemberCount = self.nPrevMemberCount - 1

	self.nDirtyFlag = bit32.bor(self.nDirtyFlag, knDirtyMembers, knDirtyResize, knDirtyGeneral)
end

function BetterRaidFrames:OnGroup_Left()
	if not GroupLib.InRaid() then return end

	self:DestroyMemberWindows(self.nPrevMemberCount)
	self.nPrevMemberCount = self.nPrevMemberCount - 1

	self.nDirtyFlag = bit32.bor(self.nDirtyFlag, knDirtyMembers, knDirtyResize)
end

function BetterRaidFrames:OnGroup_Updated()
	if not GroupLib.InRaid() then return end
end

function BetterRaidFrames:OnGroup_MemberFlagsChanged(nMemberIdx, bFromPromotion, tChangedFlags)
	if not GroupLib.InRaid() then return end
	self.nDirtyFlag = bit32.bor(self.nDirtyFlag, knDirtyGeneral)
end

function BetterRaidFrames:OnGroup_LootRulesChanged()
	if not GroupLib.InRaid() then return end
	self.nDirtyFlag = bit32.bor(self.nDirtyFlag, knDirtyLootRules)
end

function BetterRaidFrames:OnGroup_FlagsChanged()
	if not GroupLib.InRaid() then return end
	self.nDirtyFlag = bit32.bor(self.nDirtyFlag, knDirtyGeneral)
end

function BetterRaidFrames:BuildAllFrames()
	local nGroupMemberCount = GroupLib.GetMemberCount()
	if nGroupMemberCount == 0 then
		self:OnLeaveBtn()
		return
	elseif not self.bSwapToTwoColsOnce and nGroupMemberCount > 20 then
		self.bSwapToTwoColsOnce = true
		--self:OnRaidCustomizeNumColAdd(self.wndRaidCustomizeNumColAdd, self.wndRaidCustomizeNumColAdd) -- TODO HACK
	end

	if nGroupMemberCount ~= self.nPrevMemberCount then
		if nGroupMemberCount < self.nPrevMemberCount then
			for nRemoveMemberIdx=nGroupMemberCount+1, self.nPrevMemberCount do
				self:DestroyMemberWindows(nRemoveMemberIdx)
			end
		end
		self.nPrevMemberCount = nGroupMemberCount
	end

	local tMemberList = {}
	for idx = 1, nGroupMemberCount do
		tMemberList[idx] = {idx, GroupLib.GetGroupMember(idx)}
	end

	local tCategoriesToUse = ktGeneralCategories
	if self.settings.bShowCategories then
		tCategoriesToUse = ktRoleCategoriesToUse
	end

	if self.nNumReadyCheckResponses >= 0 then
		self.nNumReadyCheckResponses = 0 -- Will get added up in UpdateSpecificMember
	end

	local nInvalidOrDeadMembers = 0
	local unitTarget = self.unitTarget
	local bFrameLocked = self.wndRaidLockFrameBtn:IsChecked()

	for idx, tCurrMemberList in pairs(tMemberList) do
		local tMemberData = tCurrMemberList[2]
		if not tMemberData.bIsOnline or tMemberData.nHealthMax == 0 or tMemberData.nHealth == 0 then
			nInvalidOrDeadMembers = nInvalidOrDeadMembers + 1
		end
	end

	self.wndRaidCategoryContainer:DestroyChildren()
	for key, strCurrCategory in pairs(tCategoriesToUse) do
		local tCategory = self:FactoryCategoryWindow(self.wndRaidCategoryContainer, strCurrCategory)
		local wndCategory = tCategory.wnd
		local wndRaidCategoryBtn = tCategory.wndRaidCategoryBtn
		local wndRaidCategoryName = tCategory.wndRaidCategoryName
		local wndRaidCategoryItems = tCategory.wndRaidCategoryItems

		wndRaidCategoryBtn:Show(not self.wndRaidLockFrameBtn:IsChecked())
		if wndRaidCategoryName:GetText() == "" then
			wndRaidCategoryName:SetText(" " .. strCurrCategory)
		end

		if wndRaidCategoryBtn:IsEnabled() and not wndRaidCategoryBtn:IsChecked() then
			for idx, tCurrMemberList in pairs(tMemberList) do
				self:UpdateMemberFrame(tCategory, tCurrMemberList, strCurrCategory)
			end
		end

		if wndRaidCategoryBtn:IsEnabled() then
			wndCategory:Show(wndRaidCategoryBtn:IsChecked() or next(wndRaidCategoryItems:GetChildren()) ~= nil)
		else
			wndCategory:Show(true)
		end
	end
	self.wndRaidTitle:SetText(String_GetWeaselString(Apollo.GetString("RaidFrame_MemberCount"), nGroupMemberCount - nInvalidOrDeadMembers, nGroupMemberCount))

	local bInInstanceSync = GroupLib.CanGotoGroupInstance()
	self.wndRaidTitle:Show(not bInInstanceSync)
	self.wndRaidWrongInstance:Show(bInInstanceSync)
end

function BetterRaidFrames:UpdateLootRules()
	local tLootRules = GroupLib.GetLootRules()
	local strThresholdQuality = ktItemQualityToStr[tLootRules.eThresholdQuality]
	local strTooltip = string.format("<P Font=\"CRB_InterfaceSmall_O\">%s</P><P Font=\"CRB_InterfaceSmall_O\">%s</P><P Font=\"CRB_InterfaceSmall_O\">%s</P>",
						Apollo.GetString("RaidFrame_LootRules"),
						String_GetWeaselString(Apollo.GetString("RaidFrame_UnderThreshold"), strThresholdQuality, Apollo.GetString(ktLootModeToString[tLootRules.eNormalRule])),
						String_GetWeaselString(Apollo.GetString("RaidFrame_ThresholdAndAbove"), strThresholdQuality, Apollo.GetString(ktLootModeToString[tLootRules.eThresholdRule])))
	self.wndRaidMasterLootIconOnly:SetTooltip(strTooltip)
end

function BetterRaidFrames:UpdateMemberFrame(tCategory, tCurrMemberList, strCategory)
	local wndCategory = tCategory.wnd
	local wndRaidCategoryItems = tCategory.wndRaidCategoryItems

	local nCodeIdx = tCurrMemberList[1] -- Since actual lua index can change
	local tMemberData = tCurrMemberList[2]
	if tMemberData and self:HelperVerifyMemberCategory(strCategory, tMemberData) then
		local tRaidMember = self:FactoryMemberWindow(wndRaidCategoryItems, nCodeIdx)
		self:UpdateSpecificMember(tRaidMember, nCodeIdx, tMemberData, nGroupMemberCount, bFrameLocked)
		self.arMemberIndexToWindow[nCodeIdx] = tRaidMember
		-- Me, Self Config at top right
		if tMemberData.strCharacterName == self.kstrMyName then -- TODO better comparison
			self:UpdateRaidOptions(nCodeIdx, tMemberData)
			self.wndRaidLeaderOptionsBtn:Show(tMemberData.bIsLeader or tMemberData.bRaidAssistant)
			self.wndRaidMasterLootIconOnly:Show(not tMemberData.bIsLeader)
			self.wndRaidMasterLootBtn:Show(tMemberData.bIsLeader)
			self:SetClassRole(tMemberData)
		end
	end
end

function BetterRaidFrames:UpdateAllMembers()
	local nGroupMemberCount = GroupLib.GetMemberCount()
	local nInvalidOrDeadMembers = 0

	local unitTarget = GameLib.GetTargetUnit()
	local unitPlayer = GameLib.GetPlayerUnit()
	for idx, tRaidMember in pairs(self.arMemberIndexToWindow) do
		local wndMemberBtn = tRaidMember.wndRaidMemberBtn
		local tMemberData = GroupLib.GetGroupMember(idx)
		local unitMember = GroupLib.GetUnitForGroupMember(idx)

		-- Update bar art if dead -> no longer dead
		self:UpdateBarArt(tMemberData, tRaidMember, unitMember)
		
		-- HP and Shields
		if tMemberData then
			local bTargetThisMember = unitTarget and unitTarget == unitMember
			local bFrameLocked = self.wndRaidLockFrameBtn:IsChecked()
			wndMemberBtn:SetCheck(bTargetThisMember)
			tRaidMember.wndRaidTearOffBtn:Show(bTargetThisMember and not bFrameLocked and not self.tTearOffMemberIDs[nCodeIdx] and not unitPlayer:IsInCombat())
			self:DoHPAndShieldResizing(tRaidMember, tMemberData)

			-- Mana Bar
			local bShowManaBar = self.settings.bShowFocus
			local wndManaBar = wndMemberBtn:FindChild("RaidMemberManaBar")
			if bShowManaBar and tMemberData.nManaMax and tMemberData.nManaMax > 0 then			
				wndManaBar:SetMax(tMemberData.nManaMax)
				wndManaBar:SetProgress(tMemberData.nMana)			
			end
			wndManaBar:Show(bShowManaBar and tMemberData.bIsOnline and not bDead and not bOutOfRange and unitCurr:GetHealth() > 0 and unitCurr:GetMaxHealth() > 0)			
		end
		
		-- Scaling
		self:ResizeBars(tRaidMember)
		
		if not tMemberData.bIsOnline or tMemberData.nHealthMax == 0 or tMemberData.nHealth == 0 then
			nInvalidOrDeadMembers = nInvalidOrDeadMembers + 1
		end
	end

	self.wndRaidTitle:SetText(String_GetWeaselString(Apollo.GetString("RaidFrame_MemberCount"), nGroupMemberCount - nInvalidOrDeadMembers, nGroupMemberCount))
end

local kfnSortCategoryMembers = function(a, b)
	return a:GetData().strKey < b:GetData().strKey
end

function BetterRaidFrames:UpdateOffsets()
	self.nRaidMemberWidth = (self.wndMain:GetWidth() - 22) / self.settings.nNumColumns

	-- Calculate this outside the loop, as its the same for entry (TODO REFACTOR)
	self.nLeftOffsetStartValue = 0

	if self.settings.bShowIcon_Class then
		self.nLeftOffsetStartValue = self.nLeftOffsetStartValue + 16 --wndRaidMember:FindChild("RaidMemberClassIcon"):GetWidth()
	end

	if self.nNumReadyCheckResponses >= 0 then
		self.nLeftOffsetStartValue = self.nLeftOffsetStartValue + 16 --wndRaidMember:FindChild("RaidMemberReadyIcon"):GetWidth()
	end
end

function BetterRaidFrames:ResizeAllFrames()
	self:UpdateOffsets()

	local nLeft, nTop, nRight, nBottom
	for key, wndCategory in pairs(self.wndRaidCategoryContainer:GetChildren()) do
		local tCategory = wndCategory:GetData()
		local wndRaidCategoryItems = tCategory.wndRaidCategoryItems
		for key2, wndRaidMember in pairs(wndRaidCategoryItems:GetChildren()) do
			self:ResizeMemberFrame(wndRaidMember)
		end

		wndRaidCategoryItems:ArrangeChildrenTiles(0, kfnSortCategoryMembers)
		nLeft, nTop, nRight, nBottom = wndCategory:GetAnchorOffsets()
		local nChildrenHeight = 0
		if wndRaidCategoryItems:IsShown() then
			nChildrenHeight = math.ceil(#wndRaidCategoryItems:GetChildren() / self.settings.nNumColumns) * ktRowSizeIndexToPixels[self.settings.nRowSize]
		end
		wndCategory:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nChildrenHeight + self.knWndCategoryHeight)
	end

	-- Lock Max Height
	nLeft, nTop, nRight, nBottom = self.wndMain:GetAnchorOffsets()
	self.wndMain:SetAnchorOffsets(nLeft, nTop, nRight, nTop + math.max(self.wndRaidCategoryContainer:ArrangeChildrenVert(0) + 58, self.knWndMainHeight))
	self.wndMain:SetSizingMinimum(175, self.wndMain:GetHeight())
	self.wndMain:SetSizingMaximum(1000, self.wndMain:GetHeight())
end

function BetterRaidFrames:ResizeMemberFrame(wndRaidMember)
	local tRaidMember = wndRaidMember:GetData()
	local nLeft, nTop, nRight, nBottom = wndRaidMember:GetAnchorOffsets()
	wndRaidMember:SetAnchorOffsets(nLeft, nTop, nLeft + self.nRaidMemberWidth, nTop + ktRowSizeIndexToPixels[self.settings.nRowSize])
	wndRaidMember:ArrangeChildrenHorz(0)

	-- Button Offsets (from tear off button)
	local nLeftOffset = self.nLeftOffsetStartValue
	if tRaidMember.wndRaidMemberIsLeader:IsShown() then
		nLeftOffset = nLeftOffset + tRaidMember.wndRaidMemberIsLeader:GetWidth()
	end
	if tRaidMember.wndRaidMemberRoleIcon:IsShown() then
		nLeftOffset = nLeftOffset + tRaidMember.wndRaidMemberRoleIcon:GetWidth()
	end
	if tRaidMember.wndRaidMemberMarkIcon:IsShown() then
		nLeftOffset = nLeftOffset + tRaidMember.wndRaidMemberMarkIcon:GetWidth()
	end
	if tRaidMember.wndRaidTearOffBtn:IsShown() then
		nLeftOffset = nLeftOffset + tRaidMember.wndRaidTearOffBtn:GetWidth()
	end

	-- Resize Button
	local wndRaidMemberBtn = tRaidMember.wndRaidMemberBtn
	nLeft,nTop,nRight,nBottom = wndRaidMemberBtn:GetAnchorOffsets()
	wndRaidMemberBtn:SetAnchorOffsets(nLeft, nTop, nLeft + self.nRaidMemberWidth - nLeftOffset, nTop + ktRowSizeIndexToPixels[self.settings.nRowSize] + 9)
end

function BetterRaidFrames:UpdateRaidOptions(nCodeIdx, tMemberData)
	local wndRaidOptions = self.wndMain:FindChild("RaidOptions")
	local wndRaidOptionsToggles = self.wndMain:FindChild("RaidOptions:SelfConfigSetAsLabel")

	wndRaidOptionsToggles:FindChild("SelfConfigSetAsDPS"):SetData(nCodeIdx)
	wndRaidOptionsToggles:FindChild("SelfConfigSetAsDPS"):SetCheck(tMemberData.bDPS)

	wndRaidOptionsToggles:FindChild("SelfConfigSetAsHealer"):SetData(nCodeIdx)
	wndRaidOptionsToggles:FindChild("SelfConfigSetAsHealer"):SetCheck(tMemberData.bHealer)

	wndRaidOptionsToggles:FindChild("SelfConfigSetAsNormTank"):SetData(nCodeIdx)
	wndRaidOptionsToggles:FindChild("SelfConfigSetAsNormTank"):SetCheck(tMemberData.bTank)

	wndRaidOptionsToggles:Show(not tMemberData.bRoleLocked)
	wndRaidOptions:FindChild("SelfConfigReadyCheckLabel"):Show(tMemberData.bIsLeader or tMemberData.bMainTank or tMemberData.bMainAssist or tMemberData.bRaidAssistant)

	local nLeft, nTop, nRight, nBottom = wndRaidOptions:GetAnchorOffsets()
	wndRaidOptions:SetAnchorOffsets(nLeft, nTop, nRight, nTop + wndRaidOptions:ArrangeChildrenVert(0))
end

function BetterRaidFrames:UpdateBarArt(tMemberData, tRaidMember, unitMember)
	local wndMemberBtn = tRaidMember.wndRaidMemberBtn

	local bOutOfRange = tMemberData.nHealthMax == 0 or not unitMember
	local bDead = tMemberData.nHealth == 0 and tMemberData.nHealthMax ~= 0
	
	if not tMemberData.bIsOnline then
		wndMemberBtn:Enable(false)
		wndMemberBtn:ChangeArt("CRB_Raid:btnRaid_ThinHoloRedBtn")
		tRaidMember.wndRaidMemberStatusIcon:SetSprite("CRB_Raid:sprRaid_Icon_Disconnect")
		tRaidMember.wndHealthBar:SetSprite("")
		tRaidMember.wndCurrHealthBar:SetFullSprite("")
		tRaidMember.wndMaxShieldBar:SetSprite("")
		tRaidMember.wndMaxAbsorbBar:SetSprite("")
		tRaidMember.wndCurrShieldBar:SetFullSprite("")
		tRaidMember.wndCurrAbsorbBar:SetFullSprite("")

		if self.settings.bShowNames then
			tRaidMember.wndCurrHealthBar:SetText(String_GetWeaselString(Apollo.GetString("Group_OfflineMember"), tMemberData.strCharacterName))
		else
			tRaidMember.wndCurrHealthBar:SetText(nil)
		end
	elseif bDead then
		wndMemberBtn:Enable(true)
		wndMemberBtn:ChangeArt("CRB_Raid:btnRaid_ThinHoloRedBtn")
		tRaidMember.wndRaidMemberStatusIcon:SetSprite("")
		tRaidMember.wndHealthBar:SetSprite("")

		if self.settings.bShowNames then
			tRaidMember.wndCurrHealthBar:SetText(String_GetWeaselString(Apollo.GetString("Group_DeadMember"), tMemberData.strCharacterName))
		else
			tRaidMember.wndCurrHealthBar:SetText(nil)
		end
	elseif bOutOfRange then
		wndMemberBtn:Enable(false)
		wndMemberBtn:ChangeArt("CRB_Raid:btnRaid_ThinHoloBlueBtn")
		tRaidMember.wndRaidMemberStatusIcon:SetSprite("CRB_Raid:sprRaid_Icon_OutOfRange")
		tRaidMember.wndHealthBar:SetSprite("")
		tRaidMember.wndCurrHealthBar:SetFullSprite("")
		tRaidMember.wndMaxShieldBar:SetSprite("")
		tRaidMember.wndMaxAbsorbBar:SetSprite("")
		tRaidMember.wndCurrShieldBar:SetFullSprite("")
		tRaidMember.wndCurrAbsorbBar:SetFullSprite("")
		
		if self.settings.bShowNames then
			tRaidMember.wndCurrHealthBar:SetText(String_GetWeaselString(Apollo.GetString("Group_OutOfRange"), tMemberData.strCharacterName))
		else
			tRaidMember.wndCurrHealthBar:SetText(nil)
		end
	else
		wndMemberBtn:Enable(true)
		wndMemberBtn:ChangeArt("CRB_Raid:btnRaid_ThinHoloBlueBtn")
		tRaidMember.wndRaidMemberStatusIcon:SetSprite("")
		tRaidMember.wndHealthBar:SetSprite("CRB_Raid:sprRaid_ShieldEmptyBar")
		tRaidMember.wndCurrHealthBar:SetFullSprite("BasicSprites:WhiteFill")
		tRaidMember.wndCurrShieldBar:SetFullSprite("BasicSprites:WhiteFill")
		tRaidMember.wndCurrAbsorbBar:SetFullSprite("BasicSprites:WhiteFill")

		-- Update Text Overlays
		-- We're appending on the raid member name which is the default text overlay
		self:UpdateHPText(tMemberData.nHealth, tMemberData.nHealthMax, tRaidMember, tMemberData.strCharacterName)
	end
	self:UpdateShieldText(tMemberData.nShield, tMemberData.nShieldMax, tRaidMember, bOutOfRange)
	self:UpdateAbsorbText(tMemberData.nAbsorption, tRaidMember, bOutOfRange)
end

function BetterRaidFrames:UpdateSpecificMember(tRaidMember, nCodeIdx, tMemberData, nGroupMemberCount, bFrameLocked)
	if not tRaidMember or not tRaidMember.wnd then
		return
	end
	local wndRaidMember = tRaidMember.wnd
	if not wndRaidMember or not wndRaidMember:IsValid() then
		return
	end
	
	-- Fix for flickering when icons in front of bars update
	self:UpdateOffsets()
	self:ResizeMemberFrame(wndRaidMember)

	local wndMemberBtn = tRaidMember.wndRaidMemberBtn
	local unitTarget = self.unitTarget

	tRaidMember.wndHealthBar:Show(true)
	tRaidMember.wndMaxAbsorbBar:Show(false)
	tRaidMember.wndMaxShieldBar:Show(false)
	tRaidMember.wndCurrShieldBar:Show(false)
	tRaidMember.wndRaidMemberMouseHack:SetData(tMemberData.nMemberIdx)

	tRaidMember.wndRaidTearOffBtn:SetData(nCodeIdx)

	local bOutOfRange = tMemberData.nHealthMax == 0
	local bDead = tMemberData.nHealth == 0 and tMemberData.nHealthMax ~= 0
	local unitMember = GroupLib.GetUnitForGroupMember(idx) -- returns nil when out of range

	self:UpdateBarArt(tMemberData, tRaidMember, unitMember)
	
	local bShowClassIcon = self.settings.bShowIcon_Class
	local wndClassIcon = tRaidMember.wndRaidMemberClassIcon
	if bShowClassIcon then
		wndClassIcon:SetSprite(ktIdToClassSprite[tMemberData.eClassId])
		wndClassIcon:SetTooltip(Apollo.GetString(ktIdToClassTooltip[tMemberData.eClassId]))
	end
	wndClassIcon:Show(bShowClassIcon)

	local nLeaderIdx = 0
	local bShowLeaderIcon = self.settings.bShowIcon_Leader
	local wndLeaderIcon = tRaidMember.wndRaidMemberIsLeader
	if bShowLeaderIcon then
		if tMemberData.bIsLeader then
			nLeaderIdx = 1
		elseif tMemberData.bMainTank then
			nLeaderIdx = 2
		elseif tMemberData.bMainAssist then
			nLeaderIdx = 3
		elseif tMemberData.bRaidAssistant then
			nLeaderIdx = 4
		end
		wndLeaderIcon:SetSprite(ktIdToLeaderSprite[nLeaderIdx])
		wndLeaderIcon:SetTooltip(Apollo.GetString(ktIdToLeaderTooltip[nLeaderIdx]))
	end
	wndLeaderIcon:Show(bShowLeaderIcon and nLeaderIdx ~= 0)

	local nRoleIdx = -1
	local bShowRoleIcon = self.settings.bShowIcon_Role
	local wndRoleIcon = tRaidMember.wndRaidMemberRoleIcon

	if bShowRoleIcon then
		if tMemberData.bDPS then
			nRoleIdx = MatchingGame.Roles.DPS
		elseif tMemberData.bHealer then
			nRoleIdx = MatchingGame.Roles.Healer
		elseif tMemberData.bTank then
			nRoleIdx = MatchingGame.Roles.Tank
		end
		local tPixieInfo = wndRoleIcon:GetPixieInfo(1)
		if tPixieInfo then
			tPixieInfo.strSprite = ktIdToRoleSprite[nRoleIdx]
			wndRoleIcon:UpdatePixie(1, tPixieInfo)
		end
		--wndRoleIcon:SetSprite(ktIdToRoleSprite[nRoleIdx])
		wndRoleIcon:SetTooltip(Apollo.GetString(ktIdToRoleTooltip[nRoleIdx]))
	end
	wndRoleIcon:Show(bShowRoleIcon and nRoleIdx ~= -1)

	local nMarkIdx = 0
	local bShowMarkIcon = self.settings.bShowIcon_Mark
	local wndMarkIcon = tRaidMember.wndRaidMemberMarkIcon
	if bShowMarkIcon then
		nMarkIdx = tMemberData.nMarkerId or 0
		wndMarkIcon:SetSprite(kstrRaidMarkerToSprite[nMarkIdx])
	end
	wndMarkIcon:Show(bShowMarkIcon and nMarkIdx ~= 0)

	-- Ready Check
	if self.nNumReadyCheckResponses >= 0 then
		local wndReadyCheckIcon = tRaidMember.wndRaidMemberReadyIcon
		if tMemberData.bHasSetReady and tMemberData.bReady then
			self.nNumReadyCheckResponses = self.nNumReadyCheckResponses + 1
			wndReadyCheckIcon:SetText(Apollo.GetString("RaidFrame_Ready"))
			wndReadyCheckIcon:SetSprite("CRB_Raid:sprRaid_Icon_ReadyCheckDull")
		elseif tMemberData.bHasSetReady and not tMemberData.bReady then
			self.nNumReadyCheckResponses = self.nNumReadyCheckResponses + 1
			wndReadyCheckIcon:SetText("")
			wndReadyCheckIcon:SetSprite("CRB_Raid:sprRaid_Icon_NotReadyDull")
		else
			wndReadyCheckIcon:SetText("")
			wndReadyCheckIcon:SetSprite("")
		end
		wndReadyCheckIcon:Show(true)
		--wndRaidMember:BringChildToTop(wndReadyCheckIcon)

		if self.nNumReadyCheckResponses == nGroupMemberCount then
			self:OnReadyCheckTimeout()
		end
	end

	-- HP and Shields
	local unitPlayer = GameLib.GetPlayerUnit()
	if tMemberData then
		local bTargetThisMember = unitTarget and unitTarget == unitMember
		local bFrameLocked = self.wndRaidLockFrameBtn:IsChecked()
		wndMemberBtn:SetCheck(bTargetThisMember)
		tRaidMember.wndRaidTearOffBtn:Show(bTargetThisMember and not bFrameLocked and not self.tTearOffMemberIDs[nCodeIdx] and not unitPlayer:IsInCombat())
		
		self:ResizeMemberFrame(wndRaidMember) -- Fix for flickering when icons in front of bars update
		self:DoHPAndShieldResizing(tRaidMember, tMemberData)

		-- Mana Bar
		local bShowManaBar = self.settings.bShowFocus
		local wndManaBar = wndMemberBtn:FindChild("RaidMemberManaBar")
		if bShowManaBar and tMemberData.nManaMax and tMemberData.nManaMax > 0 then			
			wndManaBar:SetMax(tMemberData.nManaMax)
			wndManaBar:SetProgress(tMemberData.nMana)			
		end
		wndManaBar:Show(bShowManaBar and tMemberData.bIsOnline and not bDead and not bOutOfRange and unitCurr:GetHealth() > 0 and unitCurr:GetMaxHealth() > 0)
		
		-- Scaling
		self:ResizeBars(tRaidMember)
	end
	self:ResizeMemberFrame(wndRaidMember)
end

function BetterRaidFrames:OnTargetUnitChanged(unitOwner)
	local unitOldTarget = self.unitTarget
	self.unitTarget = unitOwner

	if not GroupLib.InRaid() then return end

	local nGroupMemberCount = GroupLib.GetMemberCount()
	for nMemberIdx=0,nGroupMemberCount do
		if unitOldTarget ~= nil and unitOldTarget == GroupLib.GetUnitForGroupMember(nMemberIdx) then
			local tRaidMember = self.arMemberIndexToWindow[nMemberIdx]
			local tMemberData = GroupLib.GetGroupMember(nMemberIdx)
			self:UpdateSpecificMember(tRaidMember, nMemberIdx, tMemberData, nGroupMemberCount)

			if self.unitTarget == nil then break end
		end
		if self.unitTarget ~= nil and self.unitTarget == GroupLib.GetUnitForGroupMember(nMemberIdx) then
			local tRaidMember = self.arMemberIndexToWindow[nMemberIdx]
			local tMemberData = GroupLib.GetGroupMember(nMemberIdx)
			self:UpdateSpecificMember(tRaidMember, nMemberIdx, tMemberData, nGroupMemberCount)

			if unitOldTarget == nil then break end
		end
	end

end

-----------------------------------------------------------------------------------------------
-- UI
-----------------------------------------------------------------------------------------------

function BetterRaidFrames:OnRaidCategoryBtnToggle(wndHandler, wndControl) -- RaidCategoryBtn
	-- Only allow showing while in combat - not hiding. To prevent accidental misclicks.
	local unitPlayer = GameLib.GetPlayerUnit()
	local tCategory = wndHandler:GetParent():GetData()
	tCategory.wndRaidCategoryItems:Show(not tCategory.wndRaidCategoryItems:IsShown() and not unitPlayer:IsInCombat())
	wndHandler:SetCheck(not tCategory.wndRaidCategoryItems:IsShown())
	self.nDirtyFlag = bit32.bor(self.nDirtyFlag, knDirtyResize)
	if unitPlayer:IsInCombat() then
		tCategory.wndRaidCategoryItems:Show(true)
		wndHandler:SetCheck(false)
	end
end

function BetterRaidFrames:OnRaidLeaderOptionsToggle(wndHandler, wndControl) -- RaidLeaderOptionsBtn
	Event_FireGenericEvent("GenericEvent_Raid_ToggleMasterLoot", false)
	Event_FireGenericEvent("GenericEvent_Raid_ToggleLeaderOptions", wndHandler:IsChecked())
end

function BetterRaidFrames:OnRaidMasterLootToggle(wndHandler, wndControl) -- RaidMasterLootBtn
	Event_FireGenericEvent("GenericEvent_Raid_ToggleMasterLoot", wndHandler:IsChecked())
	Event_FireGenericEvent("GenericEvent_Raid_ToggleLeaderOptions", false)
end

function BetterRaidFrames:OnRaidConfigureToggle(wndHandler, wndControl) -- RaidConfigureBtn
	if wndHandler:IsChecked() then
		Event_FireGenericEvent("GenericEvent_Raid_ToggleMasterLoot", false)
		Event_FireGenericEvent("GenericEvent_Raid_ToggleLeaderOptions", false)
		self:RefreshSettings()
	end
end

function BetterRaidFrames:OnRaidTearOffBtn(wndHandler, wndControl) -- RaidTearOffBtn
	Event_FireGenericEvent("GenericEvent_Raid_ToggleRaidTearOff", wndHandler:GetData())
	self.tTearOffMemberIDs[wndHandler:GetData()] = true
end

function BetterRaidFrames:OnRaidUnTearOff(wndArg) -- GenericEvent_Raid_ToggleRaidUnTear
	self.tTearOffMemberIDs[wndArg] = nil
end

function BetterRaidFrames:OnLeaveBtn(wndHandler, wndControl)
	self:OnUncheckLeaderOptions()
	self:OnUncheckMasterLoot()
	GroupLib.LeaveGroup()
end

function BetterRaidFrames:OnRaidLeaveShowPrompt(wndHandler, wndControl)
	if self.wndMain and self.wndMain:IsValid() and self.wndMain:FindChild("RaidConfigureBtn") then
		self.wndMain:FindChild("RaidConfigureBtn"):SetCheck(false)
	end
	self:OnUncheckLeaderOptions()
	self:OnUncheckMasterLoot()
	Apollo.LoadForm(self.xmlDoc, "RaidLeaveYesNo", nil, self)
end

function BetterRaidFrames:OnRaidLeaveYes(wndHandler, wndControl)
	wndHandler:GetParent():Destroy()
	self:OnLeaveBtn()
end

function BetterRaidFrames:OnRaidLeaveNo(wndHandler, wndControl)
	wndHandler:GetParent():Destroy()
end

function BetterRaidFrames:OnUncheckLeaderOptions()
	if self.wndMain and self.wndMain:IsValid() then
		self.wndRaidLeaderOptionsBtn:SetCheck(false)
	end
end

function BetterRaidFrames:OnUncheckMasterLoot()
	if self.wndMain and self.wndMain:IsValid() then
		self.wndRaidMasterLootBtn:SetCheck(false)
	end
end

function BetterRaidFrames:OnGroupBagBtn()
	Event_FireGenericEvent("GenericEvent_ToggleGroupBag")
end

function BetterRaidFrames:OnMasterLootUpdate()
	local tMasterLoot = GameLib.GetMasterLoot()
	local bShowMasterLoot = tMasterLoot and #tMasterLoot > 0
	local nLeft, nTop, nRight, nBottom = self.wndRaidTitle:GetAnchorOffsets()
	self.wndRaidTitle:SetAnchorOffsets(bShowMasterLoot and 40 or 12, nTop, nRight, nBottom)

	self.wndGroupBagBtn:Show(bShowMasterLoot)
end

function BetterRaidFrames:OnRaidWrongInstance()
	GroupLib.GotoGroupInstance()
end

-----------------------------------------------------------------------------------------------
-- Ready Check
-----------------------------------------------------------------------------------------------

function BetterRaidFrames:OnStartReadyCheckBtn(wndHandler, wndControl) -- StartReadyCheckBtn
	if not self.bReadyCheckActive then
		local strMessage = self.wndMain:FindChild("RaidOptions:SelfConfigReadyCheckLabel:ReadyCheckMessageBG:ReadyCheckMessageEditBox"):GetText()
		if string.len(strMessage) <= 0 then
			strMessage = Apollo.GetString("RaidFrame_AreYouReady")
		end

		GroupLib.ReadyCheck(strMessage) -- Sanitized in code
		self.wndMain:FindChild("RaidConfigureBtn"):SetCheck(false)
		wndHandler:SetFocus() -- To remove out of edit box
		self.bReadyCheckActive = true
	end
end

function BetterRaidFrames:OnGroup_ReadyCheck(nMemberIdx, strMessage)
	local tMember = GroupLib.GetGroupMember(nMemberIdx)
	local strName = Apollo.GetString("RaidFrame_TheRaid")
	if tMember then
		strName = tMember.strCharacterName
	end

	if self.wndReadyCheckPopup and self.wndReadyCheckPopup:IsValid() then
		self.wndReadyCheckPopup:Destroy()
	end

	self.wndReadyCheckPopup = Apollo.LoadForm(self.xmlDoc, "RaidReadyCheck", nil, self)
	self.wndReadyCheckPopup:SetData(wndReadyCheckPopup)
	self.wndReadyCheckPopup:FindChild("ReadyCheckNoBtn"):SetData(wndReadyCheckPopup)
	self.wndReadyCheckPopup:FindChild("ReadyCheckYesBtn"):SetData(wndReadyCheckPopup)
	self.wndReadyCheckPopup:FindChild("ReadyCheckCloseBtn"):SetData(wndReadyCheckPopup)
	self.wndReadyCheckPopup:FindChild("ReadyCheckMessage"):SetText(String_GetWeaselString(Apollo.GetString("RaidFrame_ReadyCheckStarted"), strName) .. "\n" .. strMessage)

	self.nNumReadyCheckResponses = 0

	self.strReadyCheckInitiator = strName
	self.strReadyCheckMessage = strMessage
	self.fReadyCheckStartTime = os.clock()
	self.bReadyCheckActive = true

	Apollo.CreateTimer("ReadyCheckTimeout", knReadyCheckTimeout, false)
end

function BetterRaidFrames:OnReadyCheckResponse(wndHandler, wndControl)
	if wndHandler == wndControl then
		GroupLib.SetReady(wndHandler:GetName() == "ReadyCheckYesBtn") -- TODO Quick Hack
	end

	if self.wndReadyCheckPopup and self.wndReadyCheckPopup:IsValid() then
		self.wndReadyCheckPopup:Destroy()
	end
end

function BetterRaidFrames:OnReadyCheckTimeout()
	self.nNumReadyCheckResponses = -1

	if self.wndReadyCheckPopup and self.wndReadyCheckPopup:IsValid() then
		self.wndReadyCheckPopup:Destroy()
	end

	local strMembersNotReady = ""
	for key, wndCategory in pairs(self.wndRaidCategoryContainer:GetChildren()) do
		for key2, wndMember in pairs(wndCategory:FindChild("RaidCategoryItems"):GetChildren()) do
			if wndMember:FindChild("RaidMemberReadyIcon") and wndMember:FindChild("RaidMemberReadyIcon"):IsValid() then
				if wndMember:FindChild("RaidMemberReadyIcon"):GetText() ~= Apollo.GetString("RaidFrame_Ready") then
					if strMembersNotReady == "" then
						strMembersNotReady = wndMember:FindChild("RaidMemberName"):GetText()
					else
						strMembersNotReady = String_GetWeaselString(Apollo.GetString("RaidFrame_NotReadyList"), strMembersNotReady, wndMember:FindChild("RaidMemberName"):GetText())
					end
				end
				--wndMember:FindChild("RaidMemberReadyIcon"):Destroy()
				wndMember:FindChild("RaidMemberReadyIcon"):Show(false)
			elseif strMembersNotReady == "" then
				strMembersNotReady = wndMember:FindChild("RaidMemberName"):GetText()
			else
				strMembersNotReady = String_GetWeaselString(Apollo.GetString("RaidFrame_NotReadyList"), strMembersNotReady, wndMember:FindChild("RaidMemberName"):GetText())
			end
		end
	end

	self:OnRaidFrameBaseTimer()

	if strMembersNotReady == "" then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Party, Apollo.GetString("RaidFrame_ReadyCheckSuccess"), "")
	else
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Party, String_GetWeaselString(Apollo.GetString("RaidFrame_ReadyCheckFail"), strMembersNotReady), "")
	end

	self.bReadyCheckActive = false
	
	self:ResizeAllFrames()
end

-----------------------------------------------------------------------------------------------
-- Self Config and Customization
-----------------------------------------------------------------------------------------------

function BetterRaidFrames:OnConfigSetAsDPSToggle(wndHandler, wndControl)
	GroupLib.SetRoleDPS(wndHandler:GetData(), wndHandler:IsChecked()) -- Will fire event Group_MemberFlagsChanged
	self.settings.bRole_DPS = wndControl:IsChecked()
	self.settings.bRole_Healer = false
	self.settings.bRole_Tank = false
end

function BetterRaidFrames:OnConfigSetAsTankToggle(wndHandler, wndControl)
	GroupLib.SetRoleTank(wndHandler:GetData(), wndHandler:IsChecked()) -- Will fire event Group_MemberFlagsChanged
	self.settings.bRole_DPS = false
	self.settings.bRole_Healer = false
	self.settings.bRole_Tank = wndControl:IsChecked()
end

function BetterRaidFrames:OnConfigSetAsHealerToggle(wndHandler, wndControl)
	GroupLib.SetRoleHealer(wndHandler:GetData(), wndHandler:IsChecked()) -- Will fire event Group_MemberFlagsChanged
	self.settings.bRole_DPS = false
	self.settings.bRole_Healer = wndControl:IsChecked()
	self.settings.bRole_Tank = false
end

function BetterRaidFrames:OnRaidMemberBtnClick(wndHandler, wndControl) -- RaidMemberMouseHack
	-- GOTCHA: Use MouseUp instead of ButtonCheck to avoid weird edgecase bugs
	if wndHandler ~= wndControl or not wndHandler or not wndHandler:GetData() then
		return
	end

	local unit = GroupLib.GetUnitForGroupMember(wndHandler:GetData())
	if unit then
		GameLib.SetTargetUnit(unit)
		self.nDirtyFlag = bit32.bor(self.nDirtyFlag, knDirtyResize)
	end
end

function BetterRaidFrames:OnRaidLockFrameBtnToggle(wndHandler, wndControl) -- RaidLockFrameBtn
	self.settings.bLockFrame = wndHandler:IsChecked()
	self:LockFrameHelper(self.settings.bLockFrame)
end

function BetterRaidFrames:OnRaidCustomizeNumColAdd(wndHandler, wndControl) -- RaidCustomizeNumColAdd, and once from bSwapToTwoColsOnce
	self.settings.nNumColumns = self.settings.nNumColumns + 1
	self:NumColumnsHelper()
end

function BetterRaidFrames:OnRaidCustomizeNumColSub(wndHandler, wndControl) -- RaidCustomizeNumColSub
	self.settings.nNumColumns = self.settings.nNumColumns - 1
	self:NumColumnsHelper()
end

function BetterRaidFrames:OnRaidCustomizeRowSizeAdd(wndHandler, wndControl) -- RaidCustomizeRowSizeAdd
	self.settings.nRowSize = self.settings.nRowSize + 1
	self:NumRowsHelper()
end

function BetterRaidFrames:OnRaidCustomizeRowSizeSub(wndHandler, wndControl) -- RaidCustomizeRowSizeSub
	self.settings.nRowSize = self.settings.nRowSize - 1
	self:NumRowsHelper()
end

function BetterRaidFrames:DestroyAndRedrawAllFromUI(wndHandler, wndControl) -- RaidCustomizeRoleIcons
	self:OnDestroyAndRedrawAll()
end

function BetterRaidFrames:OnDestroyAndRedrawAll() -- DestroyAndRedrawAllFromUI
	if self.wndMain and self.wndMain:IsValid() then
		self.wndRaidCategoryContainer:DestroyChildren()
		self:OnRaidFrameBaseTimer()
		self:OnRaidFrameBaseTimer() -- TODO HACK to immediate redraw
	end
end

function BetterRaidFrames:DestroyMemberWindows(nMemberIdx)
	local tCategoriesToUse = {Apollo.GetString("RaidFrame_Members")}
	if self.settings.bShowCategories then
		tCategoriesToUse = {Apollo.GetString("RaidFrame_Tanks"), Apollo.GetString("RaidFrame_Healers"), Apollo.GetString("RaidFrame_DPS")}
	end

	for key, strCurrCategory in pairs(tCategoriesToUse) do
		local wndCategory = self.wndRaidCategoryContainer:FindChild(strCurrCategory)
		if wndCategory ~= nil then
			local wndMember = wndCategory:FindChild(nMemberIdx)
			if wndMember ~= nil then
				self.arMemberIndexToWindow[nMemberIdx] = nil
				wndMember:Destroy()
			end
		end
	end
end

function BetterRaidFrames:OnRaidWindowSizeChanged(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	self.nDirtyFlag = bit32.bor(self.nDirtyFlag, knDirtyResize)
end

-----------------------------------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------------------------------

function BetterRaidFrames:SetClassRole(tMemberData)
	-- Stupid if needed here since you can't pass false as a second parameter to SetRole without getting errors
	if self.settings.bRole_DPS and not tMemberData.bDPS then
		GroupLib.SetRoleDPS(1, self.settings.bRole_DPS)
	elseif self.settings.bRole_Tank and not tMemberData.bTank then
		GroupLib.SetRoleTank(1, self.settings.bRole_Tank)
	elseif self.settings.bRole_Healer and not tMemberData.bHealer then
		GroupLib.SetRoleHealer(1, self.settings.bRole_Healer)
	end
end

function BetterRaidFrames:LockFrameHelper(bLock)
	self.wndMain:SetStyle("Sizable", not bLock)
	self.wndMain:SetStyle("Moveable", not bLock)
	self.wndRaidLockFrameBtn:SetCheck(bLock)
	if bLock then
		self.wndMain:SetSprite("sprRaid_BaseNoArrow")
	else
		self.wndMain:SetSprite("sprRaid_Base")
	end
end

function BetterRaidFrames:NumColumnsHelper()
	if self.settings.nNumColumns >= 5 then
		self.settings.nNumColumns = 5
		self.wndRaidCustomizeNumColAdd:Enable(false)
	else
		self.wndRaidCustomizeNumColAdd:Enable(true)
	end

	if self.settings.nNumColumns <= 1 then
		self.settings.nNumColumns = 1
		self.wndRaidCustomizeNumColSub:Enable(false)
	else
		self.wndRaidCustomizeNumColSub:Enable(true)
	end
	
	self.wndRaidCustomizeNumColValue:SetText(self.settings.nNumColumns)
	
	self.nDirtyFlag = bit32.bor(self.nDirtyFlag, knDirtyResize)
end

function BetterRaidFrames:NumRowsHelper()
	if self.settings.nRowSize >= 5 then
		self.settings.nRowSize = 5
		self.wndRaidCustomizeRowSizeAdd:Enable(false)
	else
		self.wndRaidCustomizeRowSizeAdd:Enable(true)
	end
	
	if self.settings.nRowSize <= 1 then
		self.settings.nRowSize = 1
		self.wndRaidCustomizeRowSizeSub:Enable(false)
	else
		self.wndRaidCustomizeRowSizeSub:Enable(true)
	end

	self.wndRaidCustomizeRowSizeValue:SetText(self.settings.nRowSize)
	
	self.nDirtyFlag = bit32.bor(self.nDirtyFlag, knDirtyResize)
end

function BetterRaidFrames:OnEnteredCombat(unit, bInCombat)
	if self.settings.bLockFrame then
		return
	end
	if self.wndMain and self.wndMain:IsValid() and self.wndMain:IsVisible() and unit == GameLib.GetPlayerUnit() and self.settings.bAutoLock_Combat then
		self.wndRaidLockFrameBtn:SetCheck(bInCombat)
		self:LockFrameHelper(bInCombat)
	end
end

function BetterRaidFrames:HelperVerifyMemberCategory(strCurrCategory, tMemberData)
	local bResult = true
	if strCurrCategory == Apollo.GetString("RaidFrame_Tanks") then
		bResult =  tMemberData.bTank
	elseif strCurrCategory == Apollo.GetString("RaidFrame_Healers") then
		bResult = tMemberData.bHealer
	elseif strCurrCategory == Apollo.GetString("RaidFrame_DPS") then
		bResult = not tMemberData.bTank and not tMemberData.bHealer
	end
	return bResult
end

function BetterRaidFrames:DoHPAndShieldResizing(tRaidMember, tMemberData)
	if not tMemberData then
		return
	end
	
	local wndMemberBtn = tRaidMember.wndRaidMemberBtn

	local nHealthCurr = tMemberData.nHealth
	local nHealthMax = tMemberData.nHealthMax
	local nShieldCurr = tMemberData.nShield
	local nShieldMax = tMemberData.nShieldMax
	local nAbsorbCurr = 0
	local nAbsorbMax = tMemberData.nAbsorptionMax
	if nAbsorbMax > 0 then
		nAbsorbCurr = tMemberData.nAbsorption -- Since it doesn't clear when the buff drops off
	end
	local nTotalMax = nHealthMax + nShieldMax + nAbsorbMax

	-- Bars
	local wndHealthBar = tRaidMember.wndHealthBar
	local wndMaxAbsorb = tRaidMember.wndMaxAbsorbBar
	local wndMaxShield = tRaidMember.wndMaxShieldBar
	wndHealthBar:Show(true)
	wndMaxAbsorb:Show(nHealthCurr > 0 and nAbsorbMax > 0)
	wndMaxShield:Show(nHealthCurr > 0 and nShieldMax > 0)

	local wndCurrShieldBar = tRaidMember.wndCurrShieldBar
	wndCurrShieldBar:Show(nHealthCurr > 0 and nShieldMax > 0)
	self:SetBarValue(wndCurrShieldBar, 0, nShieldCurr, nShieldMax)

	local wndCurrAbsorbBar = tRaidMember.wndCurrAbsorbBar
	self:SetBarValue(wndCurrAbsorbBar, 0, nAbsorbCurr, nAbsorbMax)

	local wndCurrHealthBar = tRaidMember.wndCurrHealthBar
	self:SetBarValue(wndCurrHealthBar, 0, nHealthCurr, nHealthMax)
end

function BetterRaidFrames:ResizeBars(tRaidMember)
	local nWidth = tRaidMember.wndRaidMemberBtn:GetWidth() - 4
	local wndHealthBar = tRaidMember.wndHealthBar
	local wndMaxAbsorb = tRaidMember.wndMaxAbsorbBar
	local wndMaxShield = tRaidMember.wndMaxShieldBar
	local nLeft, nTop, nRight, nBottom = wndHealthBar:GetAnchorOffsets()
	
	wndHealthBar:SetAnchorOffsets(nLeft, nTop, nWidth * 0.67, nBottom)
	wndMaxShield:SetAnchorOffsets(nWidth * 0.67, nTop, nWidth * 0.85, nBottom)
	wndMaxAbsorb:SetAnchorOffsets(nWidth * 0.85, nTop, nWidth, nBottom)
end

function BetterRaidFrames:UpdateHPText(nHealthCurr, nHealthMax, tRaidMember, strCharacterName)
	local wnd = tRaidMember.wndCurrHealthBar
	-- No text needs to be drawn if all HP Text options are disabled
	if not self.settings.bShowHP_Full and not self.settings.bShowHP_K and not self.settings.bShowHP_Pct then
		-- Update text to be empty, otherwise it will be stuck at the old value
		if self.settings.bShowNames then
			wnd:SetText(strCharacterName)
		else
			wnd:SetText(nil)
		end
		return
	end
	
	local strHealthPercentage = self:RoundPercentage(nHealthCurr, nHealthMax)
	local strHealthCurrRounded
	local strHealthMaxRounded

	if nHealthCurr < 1000 then
		strHealthCurrRounded = nHealthCurr
	else
		strHealthCurrRounded = self:RoundNumber(nHealthCurr)
	end

	if nHealthMax < 1000 then
		strHealthMaxRounded = nHealthMax
	else
		strHealthMaxRounded = self:RoundNumber(nHealthMax)
	end

	-- Only ShowHP_Full selected
	if self.settings.bShowHP_Full and not self.settings.bShowHP_K and not self.settings.bShowHP_Pct then
		if self.settings.bShowNames then
			wnd:SetText(strCharacterName.." - "..nHealthCurr.."/"..nHealthMax)
		else
			wnd:SetText(nHealthCurr.."/"..nHealthMax)
		end
		return
	end

	-- ShowHP_Full + Pct
	if self.settings.bShowHP_Full and not self.settings.bShowHP_K and self.settings.bShowHP_Pct then
		if self.settings.bShowNames then
			wnd:SetText(strCharacterName.." - "..nHealthCurr.."/"..nHealthMax.." ("..strHealthPercentage..")")
		else
			wnd:SetText(nHealthCurr.."/"..nHealthMax.." ("..strHealthPercentage..")")
		end
		return
	end

	-- Only ShowHP_K selected
	if not self.settings.bShowHP_Full and self.settings.bShowHP_K and not self.settings.bShowHP_Pct then
		if self.settings.bShowNames then
			wnd:SetText(strCharacterName.." - "..strHealthCurrRounded.."/"..strHealthMaxRounded)
		else
			wnd:SetText(strHealthCurrRounded.."/"..strHealthMaxRounded)
		end
		return
	end

	-- ShowHP_K + Pct
	if not self.settings.bShowHP_Full and self.settings.bShowHP_K and self.settings.bShowHP_Pct then
		if self.settings.bShowNames then
			wnd:SetText(strCharacterName.." - "..strHealthCurrRounded.."/"..strHealthMaxRounded.." ("..strHealthPercentage..")")
		else
			wnd:SetText(strHealthCurrRounded.."/"..strHealthMaxRounded.." ("..strHealthPercentage..")")
		end
		return
	end

	-- Only Pct selected
	if not self.settings.bShowHP_Full and not self.settings.bShowHP_K and self.settings.bShowHP_Pct then
		if self.settings.bShowNames then
			wnd:SetText(strCharacterName.." - "..strHealthPercentage)
		else
			wnd:SetText(strHealthPercentage)
		end
		return
	end
end

function BetterRaidFrames:UpdateShieldText(nShieldCurr, nShieldMax, tRaidMember, bOutOfRange)
	-- Only update text if we are showing the shield bar
	if not self.settings.bShowShieldBar then
		return
	end
	
	local wnd = tRaidMember.wndCurrShieldBar
	
	if bOutOfRange then
		wnd:SetText(nil)
		return
	end
	
	local strShieldPercentage = self:RoundPercentage(nShieldCurr, nShieldMax)
	local strShieldCurrRounded

	if nShieldCurr > 0 then
		if nShieldCurr < 1000 then
			strShieldCurrRounded = nShieldCurr
		else
			strShieldCurrRounded = self:RoundNumber(nShieldCurr)
		end
	else
		strShieldCurrRounded = "" -- empty string to remove text when there is no shield
	end

	-- No text needs to be drawn if all Shield Text options are disabled
	if not self.settings.bShowShield_K and not self.settings.bShowShield_Pct then
		-- Update text to be empty, otherwise it will be stuck at the old value
		wnd:SetText(nil)
		return
	end

	-- Only Pct selected
	if not self.settings.bShowShield_K and self.settings.bShowShield_Pct then
		wnd:SetText(strShieldPercentage)
		return
	end

	-- Only ShowShield_K selected
	if self.settings.bShowShield_K and not self.settings.bShowShield_Pct then
		wnd:SetText(strShieldCurrRounded)
		return
	end
end

function BetterRaidFrames:UpdateAbsorbText(nAbsorbCurr, tRaidMember, bOutOfRange)
	-- Only update text if we are showing the shield bar
	if not self.settings.bShowAbsorbBar then
		return
	end
	
	local wnd = tRaidMember.wndCurrAbsorbBar
	
	if bOutOfRange then
		wnd:SetText(nil)
		return
	end

	local strAbsorbCurrRounded

	if nAbsorbCurr > 0 then
		if nAbsorbCurr < 1000 then
			strAbsorbCurrRounded = nAbsorbCurr
		else
			strAbsorbCurrRounded = self:RoundNumber(nAbsorbCurr)
		end
	else
		strAbsorbCurrRounded = "" -- empty string to remove text when there is no absorb
	end

	-- No text needs to be drawn if all absorb text options are disabled
	if not self.settings.bShowAbsorb_K then
		wnd:SetText(nil)
		return
	end

	if self.settings.bShowAbsorb_K then
		wnd:SetText(strAbsorbCurrRounded)
		return
	end
end

function BetterRaidFrames:RoundNumber(n)
	local hundreds = math.floor(n / 100) % 10
	if hundreds == 0 then
		return ('%.0fK'):format(math.floor(n/1000))
	else
		return ('%.0f.%.0fK'):format(math.floor(n/1000), hundreds)
	end
end

function BetterRaidFrames:RoundPercentage(n, total)
	local hundreds = math.floor(n / total) % 10
	if hundreds == 0 then
		return ('%.1f%%'):format(n/total * 100)
	else
		return ('%.0f%%'):format(math.floor(n/total) * 100)
	end
end

function BetterRaidFrames:SetBarValue(wndBar, fMin, fValue, fMax)
	wndBar:SetMax(fMax)
	wndBar:SetFloor(fMin)
	wndBar:SetProgress(fValue)
end

function BetterRaidFrames:FactoryMemberWindow(wndParent, strKey)
	if self.cache == nil then
		self.cache = {}
	end

	local tbl = self.cache[strKey]
	if tbl == nil or not tbl.wnd:IsValid() then
		local wndNew = Apollo.LoadForm(self.xmlDoc, "RaidMember", wndParent, self)
		wndNew:SetName(strKey)

		tbl =
		{
			["strKey"] = strKey,
			wnd = wndNew,
			wndHealthBar = wndNew:FindChild("RaidMemberBtn:HealthBar"),
			wndCurrHealthBar = wndNew:FindChild("RaidMemberBtn:HealthBar:CurrHealthBar"),
			wndMaxAbsorbBar = wndNew:FindChild("RaidMemberBtn:MaxAbsorbBar"),
			wndCurrAbsorbBar = wndNew:FindChild("RaidMemberBtn:MaxAbsorbBar:CurrAbsorbBar"),
			wndMaxShieldBar = wndNew:FindChild("RaidMemberBtn:MaxShieldBar"),
			wndCurrShieldBar = wndNew:FindChild("RaidMemberBtn:MaxShieldBar:CurrShieldBar"),
			wndRaidMemberBtn = wndNew:FindChild("RaidMemberBtn"),
			wndRaidMemberMouseHack = wndNew:FindChild("RaidMemberBtn:RaidMemberMouseHack"),
			wndRaidMemberStatusIcon = wndNew:FindChild("RaidMemberBtn:RaidMemberStatusIcon"),
			wndRaidTearOffBtn = wndNew:FindChild("RaidTearOffBtn"),
			wndRaidMemberClassIcon = wndNew:FindChild("RaidMemberClassIcon"),
			wndRaidMemberIsLeader = wndNew:FindChild("RaidMemberIsLeader"),
			wndRaidMemberRoleIcon = wndNew:FindChild("RaidMemberRoleIcon"),
			wndRaidMemberReadyIcon = wndNew:FindChild("RaidMemberReadyIcon"),
			wndRaidMemberMarkIcon = wndNew:FindChild("RaidMemberMarkIcon"),
		}
		wndNew:SetData(tbl)
		self.cache[strKey] = tbl

		for strCacheKey, wndCached in pairs(self.cache) do
			if not self.cache[strCacheKey].wnd:IsValid() then
				self.cache[strCacheKey] = nil
			end
		end

		self.nDirtyFlag = bit32.bor(self.nDirtyFlag, knDirtyResize)
	end

	return tbl
end

function BetterRaidFrames:FactoryCategoryWindow(wndParent, strKey)
	if self.cache == nil then
		self.cache = {}
	end

	local tbl = self.cache[strKey]
	if tbl == nil or not tbl.wnd:IsValid() then
		local wndNew = Apollo.LoadForm(self.xmlDoc, "RaidCategory", wndParent, self)
		wndNew:SetName(strKey)

		tbl =
		{
			wnd = wndNew,
			wndRaidCategoryBtn = wndNew:FindChild("RaidCategoryBtn"),
			wndRaidCategoryName = wndNew:FindChild("RaidCategoryName"),
			wndRaidCategoryItems = wndNew:FindChild("RaidCategoryItems"),
		}
		wndNew:SetData(tbl)
		self.cache[strKey] = tbl

		for strCacheKey, wndCached in pairs(self.cache) do
			if not self.cache[strCacheKey].wnd:IsValid() then
				self.cache[strCacheKey] = nil
			end
		end

		self.nDirtyFlag = bit32.bor(self.nDirtyFlag, knDirtyResize)
	end

	return tbl
end

---------------------------------------------------------------------------------------------------
-- BetterRaidFramesForm Functions
---------------------------------------------------------------------------------------------------

function BetterRaidFrames:OnRaidCustomizeLeaderIconsCheck( wndHandler, wndControl, eMouseButton )
	self.nDirtyFlag = bit32.bor(self.nDirtyFlag, knDirtyMembers)
	self.settings.bShowIcon_Leader = wndHandler:IsChecked()
end

function BetterRaidFrames:OnRaidCustomizeRoleIconsCheck( wndHandler, wndControl, eMouseButton )
	self.nDirtyFlag = bit32.bor(self.nDirtyFlag, knDirtyMembers)
	self.settings.bShowIcon_Role = wndHandler:IsChecked()
end

function BetterRaidFrames:OnRaidCustomizeClassIconsCheck(wndHandler, wndControl, eMouseButton)
	self.nDirtyFlag = bit32.bor(self.nDirtyFlag, knDirtyMembers, knDirtyResize)
	self.settings.bShowIcon_Class = wndHandler:IsChecked()
end

function BetterRaidFrames:OnRaidCustomizeMarkIconsCheck( wndHandler, wndControl, eMouseButton )
	self.nDirtyFlag = bit32.bor(self.nDirtyFlag, knDirtyMembers)
	self.settings.bShowIcon_Mark = wndHandler:IsChecked()
end

function BetterRaidFrames:OnRaidCustomizeFocusBarCheck( wndHandler, wndControl, eMouseButton )
	self.nDirtyFlag = bit32.bor(self.nDirtyFlag, knDirtyMembers)
	self.settings.bShowFocus = wndHandler:IsChecked()
end

function BetterRaidFrames:OnRaidCustomizeCategoryCheck(wndHandler, wndControl, eMouseButton)
	self.nDirtyFlag = bit32.bor(self.nDirtyFlag, knDirtyGeneral, knDirtyResize)
	self.settings.bShowCategories = wndHandler:IsChecked()
end

function BetterRaidFrames:OnRaidCustomizeNamesCheck( wndHandler, wndControl, eMouseButton )
	self.nDirtyFlag = bit32.bor(self.nDirtyFlag, knDirtyMembers)
	self.settings.bShowNames = wndHandler:IsChecked()
end

function BetterRaidFrames:OnRaidCustomizeCombatLock( wndHandler, wndControl, eMouseButton )
	self.settings.bAutoLock_Combat = wndHandler:IsChecked()
end

---------------------------------------------------------------------------------------------------
-- RaidMember Functions
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- ConfigForm Functions
---------------------------------------------------------------------------------------------------

function BetterRaidFrames:OnConfigOn()
	self.wndConfig:Show(true)
	self:RefreshSettings()
end

function BetterRaidFrames:OnCloseButton( wndHandler, wndControl, eMouseButton )
	self.wndConfig:Show(false)
end

function BetterRaidFrames:Button_ShowHP_Full( wndHandler, wndControl, eMouseButton )
	self.settings.bShowHP_Full = wndControl:IsChecked()
	if self.wndConfig:FindChild("Button_ShowHP_K"):IsChecked() and wndControl:IsChecked() then
		self.settings.bShowHP_K = false
		self.wndConfig:FindChild("Button_ShowHP_K"):SetCheck(false)
	end
end

function BetterRaidFrames:Button_ShowHP_K( wndHandler, wndControl, eMouseButton )
	self.settings.bShowHP_K = wndControl:IsChecked()
	if self.wndConfig:FindChild("Button_ShowHP_Full"):IsChecked() and wndControl:IsChecked() then
		self.settings.bShowHP_Full = false
		self.wndConfig:FindChild("Button_ShowHP_Full"):SetCheck(false)
	end
end

function BetterRaidFrames:Button_ShowHP_Pct( wndHandler, wndControl, eMouseButton )
	self.settings.bShowHP_Pct = wndControl:IsChecked()
end

function BetterRaidFrames:Button_ShowShield_K( wndHandler, wndControl, eMouseButton )
	self.settings.bShowShield_K = wndControl:IsChecked()
	if self.wndConfig:FindChild("Button_ShowShield_Pct"):IsChecked() and wndControl:IsChecked() then
		self.settings.bShowShield_Pct = false
		self.wndConfig:FindChild("Button_ShowShield_Pct"):SetCheck(false)
	end
end

function BetterRaidFrames:Button_ShowShield_Pct( wndHandler, wndControl, eMouseButton )
	self.settings.bShowShield_Pct = wndControl:IsChecked()
	if self.wndConfig:FindChild("Button_ShowShield_K"):IsChecked() and wndControl:IsChecked() then
		self.settings.bShowShield_K = false
		self.wndConfig:FindChild("Button_ShowShield_K"):SetCheck(false)
	end
end

function BetterRaidFrames:Button_ShowAbsorb_K( wndHandler, wndControl, eMouseButton )
	self.settings.bShowAbsorb_K = wndControl:IsChecked()
end

function BetterRaidFrames:Button_TrackDebuffs( wndHandler, wndControl, eMouseButton )
	self.settings.bTrackDebuffs = wndControl:IsChecked()
end

function BetterRaidFrames:Button_ShowShieldBar( wndHandler, wndControl, eMouseButton )
	self.settings.bShowShieldBar = wndControl:IsChecked()
	-- TODO add call to function that resizes our bars appropriately depending on settings of which bars to show.
end

function BetterRaidFrames:Button_ShowAbsorbBar( wndHandler, wndControl, eMouseButton )
	self.settings.bShowAbsorbBar = wndControl:IsChecked()
	-- TODO add call to function that resizes our bars appropriately depending on settings of which bars to show.
end


local BetterRaidFramesInst = BetterRaidFrames:new()
BetterRaidFramesInst:Init()
