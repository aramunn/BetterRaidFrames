-------------------------------------------------------------------------------------------
-- Client Lua Script for BetterRaidFrames
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "bit32"

local BetterRaidFrames = {}

local ktCategoryToSettingKeyPrefix =
{
	ConfigColorsGeneral			= "strColorGeneral_",
	ConfigColorsEngineer		= "strColorEngineer_",
	ConfigColorsEsper			= "strColorEsper_",
	ConfigColorsMedic			= "strColorMedic_",
	ConfigColorsSpellslinger	= "strColorSpellslinger_",
	ConfigColorsStalker			= "strColorStalker_",
	ConfigColorsWarrior			= "strColorWarrior_",
}

local kBoostBuffs = {
	"Brutality Boost",
	"Finesse Boost",
	"Grit Boost",
	"Insight Boost",
	"Moxie Boost",
	"Tech Boost",
}

local kFoodBuffs = {
	"Stuffed!",
}

local ktClassIdToClassName =
{
	[GameLib.CodeEnumClass.Esper] 			= "Esper",
	[GameLib.CodeEnumClass.Medic] 			= "Medic",
	[GameLib.CodeEnumClass.Stalker] 		= "Stalker",
	[GameLib.CodeEnumClass.Warrior] 		= "Warrior",
	[GameLib.CodeEnumClass.Engineer] 		= "Engineer",
	[GameLib.CodeEnumClass.Spellslinger] 	= "Spellslinger",
}

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
	bShowIcon_Food		= false,
	bShowIcon_Boost		= false,
	bShowFocus			= false,
	bShowCategories		= true,
	bUseGroups			= false,
	bShowNames			= true,
	bAutoLock_Combat	= true,
	nNumColumns			= 1,
	nRowSize			= 1,
	bRole_DPS			= true,
	bRole_Healer		= false,
	bRole_Tank			= false,
	
	-- Custom settings via /brf options
	bShowHP_Full = false,
	bShowHP_K = false,
	bShowHP_Pct = false,
	bShowShield_K = false,
	bShowShield_Pct = false,
	bShowAbsorb_K = false,
	bTrackDebuffs = false,
	bShowShieldBar = true,
	bShowAbsorbBar = true,
	bMouseOverSelection = false,
	bRememberPrevTarget = false,
	bTransparency = false,
	bCheckRange = false,
	fMaxRange = 50,
	bDisableFrames = false,
	bConsistentIconOffset = false,
	
	-- Custom settings via /brf colors
	bClassSpecificBarColors = false,
	
	strColorGeneral_HPHealthy = "ff26a614",
	strColorGeneral_HPDebuff = "ff8b008b",
	strColorGeneral_Shield = "ff2574a9",
	strColorGeneral_Absorb = "ffca7819",
	
	strColorEngineer_HPHealthy = "ff26a614",
	strColorEngineer_HPDebuff = "ff8b008b",
	strColorEngineer_Shield = "ff2574a9",
	strColorEngineer_Absorb = "ffca7819",
	
	strColorEsper_HPHealthy = "ff26a614",
	strColorEsper_HPDebuff = "ff8b008b",
	strColorEsper_Shield = "ff2574a9",
	strColorEsper_Absorb = "ffca7819",
	
	strColorMedic_HPHealthy = "ff26a614",
	strColorMedic_HPDebuff = "ff8b008b",
	strColorMedic_Shield = "ff2574a9",
	strColorMedic_Absorb = "ffca7819",
	
	strColorSpellslinger_HPHealthy = "ff26a614",
	strColorSpellslinger_HPDebuff = "ff8b008b",
	strColorSpellslinger_Shield = "ff2574a9",
	strColorSpellslinger_Absorb = "ffca7819",
	
	strColorStalker_HPHealthy = "ff26a614",
	strColorStalker_HPDebuff = "ff8b008b",
	strColorStalker_Shield = "ff2574a9",
	strColorStalker_Absorb = "ffca7819",
	
	strColorWarrior_HPHealthy = "ff26a614",
	strColorWarrior_HPDebuff = "ff8b008b",
	strColorWarrior_Shield = "ff2574a9",
	strColorWarrior_Absorb = "ffca7819",
	
	-- /brf advanced
	fBarArtTimer = 0.2,
	fBoostFoodTimer = 1,
	fMainUpdateTimer = 0.2,
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

	local tSave =
	{

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

	self.settings = self:copyTable(tSavedData, self.settings)
end

function BetterRaidFrames:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("BetterRaidFrames.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
	Apollo.LoadSprites("BRF.xml")
	
	-- Configured our forms
	self.wndConfig = Apollo.LoadForm(self.xmlDoc, "ConfigForm", nil, self)
	self.wndConfig:Show(false)
	self.wndConfigColors = Apollo.LoadForm(self.xmlDoc, "ConfigColorsForm", nil, self)
	self.wndConfigColors:Show(false)
	
	self.wndTargetFrame = self.wndConfigColors:FindChild("TargetFrame")
	
	self.wndConfigColorsGeneral = Apollo.LoadForm(self.xmlDoc, "ConfigColorsGeneral", self.wndTargetFrame, self)
	self.wndConfigColorsEngineer = Apollo.LoadForm(self.xmlDoc, "ConfigColorsEngineer", self.wndTargetFrame, self)
	self.wndConfigColorsEsper = Apollo.LoadForm(self.xmlDoc, "ConfigColorsEsper", self.wndTargetFrame, self)
	self.wndConfigColorsMedic = Apollo.LoadForm(self.xmlDoc, "ConfigColorsMedic", self.wndTargetFrame, self)
	self.wndConfigColorsSpellslinger = Apollo.LoadForm(self.xmlDoc, "ConfigColorsSpellslinger", self.wndTargetFrame, self)
	self.wndConfigColorsStalker = Apollo.LoadForm(self.xmlDoc, "ConfigColorsStalker", self.wndTargetFrame, self)
	self.wndConfigColorsWarrior = Apollo.LoadForm(self.xmlDoc, "ConfigColorsWarrior", self.wndTargetFrame, self)
	
	self.wndConfigAdvanced = Apollo.LoadForm(self.xmlDoc, "ConfigAdvancedForm", nil, self)
	self.wndConfigAdvanced:Show(false)
	self.wndAdvancedTargetFrame = self.wndConfigAdvanced:FindChild("TargetFrame")
	self.wndConfigAdvancedGeneral = Apollo.LoadForm(self.xmlDoc, "ConfigAdvancedGeneral", self.wndAdvancedTargetFrame, self)
		
	-- Register handler for slash commands that open the configuration form
	Apollo.RegisterSlashCommand("brf", "OnSlashCmd", self)
	
	-- Register ICCommLib stuff.
	self.tNamedGroups = {}
	self.tMemberToGroup = {}
	
	self.settings = self.settings or {}
	self.settings.strMyGroup = self.settings.strMyGroup or "Raid"
	
	setmetatable(self.settings, DefaultSettings)
	
	if Apollo.GetAddon("VikingContextMenuPlayer") ~= nil then
	    self.contextMenuPlayer = Apollo.GetAddon("VikingContextMenuPlayer")
	else
	    self.contextMenuPlayer = Apollo.GetAddon("ContextMenuPlayer")
	end
    local oldRedrawAll = self.contextMenuPlayer.RedrawAll

    self.contextMenuPlayer.RedrawAll = function(context)
        if self.contextMenuPlayer.wndMain ~= nil then
            local wndButtonList = self.contextMenuPlayer.wndMain:FindChild("ButtonList")
            if wndButtonList ~= nil then
                local wndNew = wndButtonList:FindChildByUserData(tObject)
                if not wndNew then
                    wndNew = Apollo.LoadForm(self.contextMenuPlayer.xmlDoc, "BtnRegular", wndButtonList, self.contextMenuPlayer)
                    wndNew:SetData("Add to Focus Group")
                end
                wndNew:FindChild("BtnText"):SetText("Add to Focus Group")
            end
        end
        oldRedrawAll(context)
    end

    -- catch the event fired when the player clicks the context menu
    local oldProcessContextClick = self.contextMenuPlayer.ProcessContextClick
    self.contextMenuPlayer.ProcessContextClick = function(context, eButtonType)
        if eButtonType == "Add to Focus Group" then
			local idx = self:CharacterToIdx(self.contextMenuPlayer.strTarget)
			if not idx or not GroupLib.InRaid() then
				ChatSystemLib.PostOnChannel(2,"Error! You can only add people in your raid to the focus group.")
				return
			end
			Event_FireGenericEvent("GenericEvent_Raid_ToggleRaidTearOff", idx)
			self.tTearOffMemberIDs[idx] = true
        else
            oldProcessContextClick(context, eButtonType)
        end
    end

end

function BetterRaidFrames:OnDocumentReady()
	if self.xmlDoc == nil then
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
	--Apollo.RegisterEventHandler("VarChange_FrameCount", 					"OnRaidFrameBaseTimer", self)
	Apollo.RegisterTimerHandler("RaidUpdateTimer",							"OnRaidFrameBaseTimer", self)
	Apollo.CreateTimer("RaidUpdateTimer", 0.2, true)
	
	-- Handlers for food/boost icons
	Apollo.RegisterTimerHandler("BoostFoodUpdateTimer",						"OnBoostFoodUpdateTimer", self)
	Apollo.CreateTimer("BoostFoodUpdateTimer", 1.0, true)
	
	-- Handler for bar art update timer
	Apollo.RegisterTimerHandler("UpdateBarArtTimer",						"OnUpdateBarArtTimer", self)
	Apollo.CreateTimer("UpdateBarArtTimer", 0.2, true)
	
	Apollo.RegisterEventHandler("ChangeWorld", 								"OnChangeWorld", self)
	Apollo.RegisterTimerHandler("TrackSavedCharactersTimer",				"TrackSavedCharacters", self)
	
	-- Required for saving frame location across sessions
	Apollo.RegisterEventHandler("WindowManagementReady", 	"OnWindowManagementReady", self)
	
	-- Load TearOff addon
	self.BetterRaidFramesTearOff = Apollo.GetAddon("BetterRaidFramesTearOff")
	
	-- GeminiColor
	self.GeminiColor = Apollo.GetPackage("GeminiColor").tPackage
	
	-- Sets the party frame location once windows are ready.
	function BetterRaidFrames:OnWindowManagementReady()
		Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndMain, strName = "BetterRaidFrames" })
		self:LockFrameHelper(self.settings.bLockFrame)
		self:NumColumnsHelper()
		self:NumRowsHelper()
		self:UpdateBarArtTimer()
		self:UpdateBoostFoodTimer()
		self:UpdateMainUpdateTimer()
		if GroupLib.InRaid() and self.chanBrf ~= nil then
			self:SendSync()
		end
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
	self.wndRaidCustomizeFoodIcons = wndRaidOptions:FindChild("RaidCustomizeFoodIcons")
	self.wndRaidCustomizeBoostIcons = wndRaidOptions:FindChild("RaidCustomizeBoostIcons")
	self.wndRaidCustomizeManaBar = wndRaidOptions:FindChild("RaidCustomizeManaBar")
	self.wndRaidCustomizeCategories = wndRaidOptions:FindChild("RaidCustomizeCategories")
	self.wndRaidCustomizeGroups = wndRaidOptions:FindChild("RaidCustomizeGroupView")
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
	if self.settings.bShowIcon_Food ~= nil then
		self.wndRaidCustomizeFoodIcons:SetCheck(self.settings.bShowIcon_Food) end
	if self.settings.bShowIcon_Boost ~= nil then
		self.wndRaidCustomizeBoostIcons:SetCheck(self.settings.bShowIcon_Boost) end
	if self.settings.bShowFocus ~= nil then
		self.wndRaidCustomizeManaBar:SetCheck(self.settings.bShowFocus) end
	if self.settings.bShowCategories ~= nil then
		self.wndRaidCustomizeCategories:SetCheck(self.settings.bShowCategories) end
	if self.settings.bUseGroups ~= nil then
		self.wndRaidCustomizeGroups:SetCheck(self.settings.bUseGroups) end
	if self.settings.bShowNames ~= nil then
		self.wndRaidCustomizeShowNames:SetCheck(self.settings.bShowNames) end
	if self.settings.bAutoLock_Combat ~= nil then
		self.wndRaidCustomizeLockInCombat:SetCheck(self.settings.bAutoLock_Combat) end

	-- Settings related to /brf options settings frame
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
	if self.settings.bMouseOverSelection ~= nil then
		self.wndConfig:FindChild("Button_MouseOverSelection"):SetCheck(self.settings.bMouseOverSelection) end
	if self.settings.bRememberPrevTarget ~= nil then
		self.wndConfig:FindChild("Button_RememberPrevTarget"):SetCheck(self.settings.bRememberPrevTarget) end
	if self.settings.bTransparency ~= nil then
		self.wndConfig:FindChild("Button_SetTransparency"):SetCheck(self.settings.bTransparency) end
	if self.settings.bCheckRange ~= nil then
		self.wndConfig:FindChild("Button_CheckRange"):SetCheck(self.settings.bCheckRange) end
	if self.settings.fMaxRange ~= nil then
		self.wndConfig:FindChild("Label_MaxRangeDisplay"):SetText(string.format("%sm", math.floor(self.settings.fMaxRange)))
		self.wndConfig:FindChild("Slider_MaxRange"):SetValue(self.settings.fMaxRange)
	end
	if self.settings.bDisableFrames ~= nil then
		self.wndConfig:FindChild("Button_DisableFrames"):SetCheck(self.settings.bDisableFrames) end
	if self.settings.bConsistentIconOffset ~= nil then
		self.wndConfig:FindChild("Button_ConsistentIconOffset"):SetCheck(self.settings.bConsistentIconOffset) end

	-- Settings related to /brf colors settings frame
	if self.settings.bClassSpecificBarColors ~= nil then
		self.wndConfigColorsGeneral:FindChild("Label_GeneralSettingsOuter:Button_ClassSpecific"):SetCheck(self.settings.bClassSpecificBarColors) end
	
	if self.settings.strColorGeneral_HPHealthy ~= nil then
		self.wndConfigColorsGeneral:FindChild("Label_ColorSettingsOuter:HPHealthy:ColorWindow"):SetBGColor(self.settings.strColorGeneral_HPHealthy) end
	if self.settings.strColorGeneral_HPDebuff ~= nil then
		self.wndConfigColorsGeneral:FindChild("Label_ColorSettingsOuter:HPDebuff:ColorWindow"):SetBGColor(self.settings.strColorGeneral_HPDebuff) end
	if self.settings.strColorGeneral_Shield ~= nil then
		self.wndConfigColorsGeneral:FindChild("Label_ColorSettingsOuter:Shield:ColorWindow"):SetBGColor(self.settings.strColorGeneral_Shield) end
	if self.settings.strColorGeneral_Absorb ~= nil then
		self.wndConfigColorsGeneral:FindChild("Label_ColorSettingsOuter:Absorb:ColorWindow"):SetBGColor(self.settings.strColorGeneral_Absorb) end
		
	if self.settings.strColorEngineer_HPHealthy ~= nil then
		self.wndConfigColorsEngineer:FindChild("Label_ColorSettingsOuter:HPHealthy:ColorWindow"):SetBGColor(self.settings.strColorEngineer_HPHealthy) end
	if self.settings.strColorEngineer_HPDebuff ~= nil then
		self.wndConfigColorsEngineer:FindChild("Label_ColorSettingsOuter:HPDebuff:ColorWindow"):SetBGColor(self.settings.strColorEngineer_HPDebuff) end
	if self.settings.strColorEngineer_Shield ~= nil then
		self.wndConfigColorsEngineer:FindChild("Label_ColorSettingsOuter:Shield:ColorWindow"):SetBGColor(self.settings.strColorEngineer_Shield) end
	if self.settings.strColorEngineer_Absorb ~= nil then
		self.wndConfigColorsEngineer:FindChild("Label_ColorSettingsOuter:Absorb:ColorWindow"):SetBGColor(self.settings.strColorEngineer_Absorb) end
		
	if self.settings.strColorEsper_HPHealthy ~= nil then
		self.wndConfigColorsEsper:FindChild("Label_ColorSettingsOuter:HPHealthy:ColorWindow"):SetBGColor(self.settings.strColorEsper_HPHealthy) end
	if self.settings.strColorEsper_HPDebuff ~= nil then
		self.wndConfigColorsEsper:FindChild("Label_ColorSettingsOuter:HPDebuff:ColorWindow"):SetBGColor(self.settings.strColorEsper_HPDebuff) end
	if self.settings.strColorEsper_Shield ~= nil then
		self.wndConfigColorsEsper:FindChild("Label_ColorSettingsOuter:Shield:ColorWindow"):SetBGColor(self.settings.strColorEsper_Shield) end
	if self.settings.strColorEsper_Absorb ~= nil then
		self.wndConfigColorsEsper:FindChild("Label_ColorSettingsOuter:Absorb:ColorWindow"):SetBGColor(self.settings.strColorEsper_Absorb) end
		
	if self.settings.strColorMedic_HPHealthy ~= nil then
		self.wndConfigColorsMedic:FindChild("Label_ColorSettingsOuter:HPHealthy:ColorWindow"):SetBGColor(self.settings.strColorMedic_HPHealthy) end
	if self.settings.strColorMedic_HPDebuff ~= nil then
		self.wndConfigColorsMedic:FindChild("Label_ColorSettingsOuter:HPDebuff:ColorWindow"):SetBGColor(self.settings.strColorMedic_HPDebuff) end
	if self.settings.strColorMedic_Shield ~= nil then
		self.wndConfigColorsMedic:FindChild("Label_ColorSettingsOuter:Shield:ColorWindow"):SetBGColor(self.settings.strColorMedic_Shield) end
	if self.settings.strColorMedic_Absorb ~= nil then
		self.wndConfigColorsMedic:FindChild("Label_ColorSettingsOuter:Absorb:ColorWindow"):SetBGColor(self.settings.strColorMedic_Absorb) end
		
	if self.settings.strColorSpellslinger_HPHealthy ~= nil then
		self.wndConfigColorsSpellslinger:FindChild("Label_ColorSettingsOuter:HPHealthy:ColorWindow"):SetBGColor(self.settings.strColorSpellslinger_HPHealthy) end
	if self.settings.strColorSpellslinger_HPDebuff ~= nil then
		self.wndConfigColorsSpellslinger:FindChild("Label_ColorSettingsOuter:HPDebuff:ColorWindow"):SetBGColor(self.settings.strColorSpellslinger_HPDebuff) end
	if self.settings.strColorSpellslinger_Shield ~= nil then
		self.wndConfigColorsSpellslinger:FindChild("Label_ColorSettingsOuter:Shield:ColorWindow"):SetBGColor(self.settings.strColorSpellslinger_Shield) end
	if self.settings.strColorSpellslinger_Absorb ~= nil then
		self.wndConfigColorsSpellslinger:FindChild("Label_ColorSettingsOuter:Absorb:ColorWindow"):SetBGColor(self.settings.strColorSpellslinger_Absorb) end
		
	if self.settings.strColorStalker_HPHealthy ~= nil then
		self.wndConfigColorsStalker:FindChild("Label_ColorSettingsOuter:HPHealthy:ColorWindow"):SetBGColor(self.settings.strColorStalker_HPHealthy) end
	if self.settings.strColorStalker_HPDebuff ~= nil then
		self.wndConfigColorsStalker:FindChild("Label_ColorSettingsOuter:HPDebuff:ColorWindow"):SetBGColor(self.settings.strColorStalker_HPDebuff) end
	if self.settings.strColorStalker_Shield ~= nil then
		self.wndConfigColorsStalker:FindChild("Label_ColorSettingsOuter:Shield:ColorWindow"):SetBGColor(self.settings.strColorStalker_Shield) end
	if self.settings.strColorStalker_Absorb ~= nil then
		self.wndConfigColorsStalker:FindChild("Label_ColorSettingsOuter:Absorb:ColorWindow"):SetBGColor(self.settings.strColorStalker_Absorb) end
		
	if self.settings.strColorWarrior_HPHealthy ~= nil then
		self.wndConfigColorsWarrior:FindChild("Label_ColorSettingsOuter:HPHealthy:ColorWindow"):SetBGColor(self.settings.strColorWarrior_HPHealthy) end
	if self.settings.strColorWarrior_HPDebuff ~= nil then
		self.wndConfigColorsWarrior:FindChild("Label_ColorSettingsOuter:HPDebuff:ColorWindow"):SetBGColor(self.settings.strColorWarrior_HPDebuff) end
	if self.settings.strColorWarrior_Shield ~= nil then
		self.wndConfigColorsWarrior:FindChild("Label_ColorSettingsOuter:Shield:ColorWindow"):SetBGColor(self.settings.strColorWarrior_Shield) end
	if self.settings.strColorWarrior_Absorb ~= nil then
		self.wndConfigColorsWarrior:FindChild("Label_ColorSettingsOuter:Absorb:ColorWindow"):SetBGColor(self.settings.strColorWarrior_Absorb) end
		
	-- /brf advanced
	if self.settings.fBarArtTimer ~= nil then
		self.wndConfigAdvancedGeneral:FindChild("Label_AdvancedSettingsOuter:Label_BarArtTimerDisplay"):SetText(string.format("%ss", self.settings.fBarArtTimer))
		self.wndConfigAdvancedGeneral:FindChild("Label_AdvancedSettingsOuter:Window_RangeSliderBarArt:Slider_BarArtTimer"):SetValue(self.settings.fBarArtTimer * 10)
	end
	if self.settings.fBoostFoodTimer ~= nil then
		self.wndConfigAdvancedGeneral:FindChild("Label_AdvancedSettingsOuter:Label_BoostFoodTimerDisplay"):SetText(string.format("%ss", self.settings.fBoostFoodTimer))
		self.wndConfigAdvancedGeneral:FindChild("Label_AdvancedSettingsOuter:Window_RangeSliderBoostFood:Slider_BoostFoodTimer"):SetValue(self.settings.fBoostFoodTimer * 10)
	end
	if self.settings.fMainUpdateTimer ~= nil then
		self.wndConfigAdvancedGeneral:FindChild("Label_AdvancedSettingsOuter:Label_MainUpdateTimerDisplay"):SetText(string.format("%ss", self.settings.fMainUpdateTimer))
		self.wndConfigAdvancedGeneral:FindChild("Label_AdvancedSettingsOuter:Window_RangeSliderMainUpdate:Slider_MainUpdateTimer"):SetValue(self.settings.fMainUpdateTimer * 10)
	end
end



-- DEBUGGING. Remove before merging -Morf
function BetterRaidFrames:ShowVariables()
	self:CPrint("tMemberToGroup:")
	for k,v in pairs(self.tMemberToGroup) do
		self:CPrint("key: " .. k .. " value: " .. v)
	end
	self:CPrint("tNamedGroups:")
	for k,v in pairs(self.tNamedGroups) do
		self:CPrint("Key: " .. k .. " Members: " .. v)
	end
	self:CPrint("Group: " .. self.settings.strMyGroup)
	self:CPrint("Channel: " .. self.settings.strChannelName)
end

----------- Manage tNamedGroups and tMemberToGroup. -------

-- Used whenever UI is loaded and/or you join a raid.
-- We save our own previous group, but not everyone elses.
-- Their group will get updated anyway as we sync.
function BetterRaidFrames:SetDefaultGroup()
	if not GroupLib.InRaid() then return end
	
	local nMembers = GroupLib.GetMemberCount()
	self.tMemberToGroup = {}
	self.tNamedGroups = {["Raid"] = nMembers}
	
	--if self.settings.strMyGroup == "Raid" then
	--	self.tNamedGroups["Raid"] = self.tNamedGroups["Raid"] + 1
	--else
	--	self.tNamedGroups[self.settings.strMyGroup] = 1
	--end

	for idx = 1, nMembers do
		local tMemberData = GroupLib.GetGroupMember(idx)
		--if tMemberData.strCharacterName == self.kstrMyName then
		--	self.tMemberToGroup[idx] = self.settings.strMyGroup
		--else
		self.tMemberToGroup[idx] = "Raid"
		--end
	end
end
		
-- tNamedGroups is a table of ["GroupName"] -> MemberCount
-- tMemberToGroup is a table of Index -> GroupName
function BetterRaidFrames:AddPlayerToGroup(idx, strGroup)
	if self.chanBrf == nil then return end
	
	--self:CPrint("Adding player with idx " .. idx .. " to group " .. strGroup)
	self.tMemberToGroup[idx] = strGroup
	if self.tNamedGroups[strGroup] == nil then
		--self:CPrint("Group didn't exist before, creating.")
		self.tNamedGroups[strGroup] = 1
		return knDirtyGeneral
	else
		--self:CPrint("Group already existed. Counter now at " .. self.tNamedGroups[strGroup])
		self.tNamedGroups[strGroup] = self.tNamedGroups[strGroup] + 1
		return knDirtyMembers
	end
end

function BetterRaidFrames:RemovePlayerFromGroup(idx, strGroup)
	if self.chanBrf == nil then return end
	
	--self:CPrint("Removing player with idx " .. idx .. " from group " .. strGroup)
	self.tMemberToGroup[idx] = nil
	if self.tNamedGroups[strGroup] ~= nil then
		self.tNamedGroups[strGroup] = self.tNamedGroups[strGroup] - 1
		if self.tNamedGroups[strGroup] <= 0 then
			--self:CPrint("Group " .. strGroup .. " no longer has any players. Removing.")
			self.tNamedGroups[strGroup] = nil
			return knDirtyGeneral
		end
	end

	return knDirtyMembers
end

function BetterRaidFrames:SendBRFMessage(tMsg)
	if self.chanBrf == nil then return end
		
	--self:CPrint("Sending message.. Type:" .. tMsg.strMsgType .. " Char: " .. tMsg.strCharacterName)
	self.chanBrf:SendMessage(tMsg)
end

function BetterRaidFrames:OnBRFMessage(channel, tMsg)
	--self:CPrint("Received message... Type:" .. tMsg.strMsgType .. " Char:" .. tMsg.strCharacterName)
	-- Ignore when not in a raid, or invalid message type.
	if not GroupLib.InRaid() or tMsg.strMsgType == nil then
		--self:CPrint("Not in a raid.") 
		return 
	end

	-- Only parse if we have a character by that name in the raid.
	local nGroupMemberCount = GroupLib.GetMemberCount()
	local tMemberList = {}
	for idx = 1, nGroupMemberCount do
		local tMemberData = GroupLib.GetGroupMember(idx)
		if tMemberData.strCharacterName == tMsg.strCharacterName then
			--self:CPrint("Found matching character: " .. tMsg.strCharacterName)
			return self:ParseBRFMessage(tMsg, idx, tMemberData)
		end
	end
	Print("ERROR: Found no matching character (" .. tMsg.strCharacterName .. ")")
end

-- A BRFMessage is a table consisting of:
-- strCharacterName = The name of the unit
-- strMsgType = "UPDATE" or "SYNC"
-- A SYNC asks all other clients in the raid to tell you their group.
-- An UPDATE tells everyone else of a change. If it has a strTargetName its meant for a specific person.

-- SYNC's cause targetted UPDATE's to be sent back, which are an UPDATE that should only be
-- reacted to by a specific person. UPDATE's without the strTargetName field are supposed to apply to everyone
-- in the raid group.
function BetterRaidFrames:ParseBRFMessage(tMsg, idx, tMemberData)
	if tMsg.strMsgType == "SYNC" then
		return self:ParseSync(tMsg, idx, tMemberData)
	elseif tMsg.strMsgType == "UPDATE" then
		return self:ParseUpdate(tMsg, idx, tMemberData)
	end
end

function BetterRaidFrames:ParseSync(tMsg, idx, tMemberData)
	local msg = {}
	msg.strCharacterName = self.kstrMyName
	msg.strMsgType = "UPDATE"
	msg.strTargetName = tMsg.strCharacterName -- to specific person..
	msg.strGroup = self.settings.strMyGroup
	self:SendBRFMessage(msg)
	if msg.strCharacterName == msg.strTargetName then
		self:OnBRFMessage(self.chanBrf, msg)
	end
end

function BetterRaidFrames:ParseUpdate(tMsg, idx, tMemberData)
	if tMsg.strTargetName ~= nil and tMsg.strTargetName ~= self.kstrMyName then 
		return 
	end

	-- Sort of a hack. If its a sync reply its an UPDATE with a target,
	-- which means they've been put into 'Raid' by SetDefaultGroup(), which
	-- they may not actually be in! So lets remove them from it.
	if tMsg.strTargetName and tMsg.strGroup ~= "Raid" then
		tMsg.strGroupOld = "Raid"
	end

	if tMsg.strGroupOld ~= nil then
		--self:CPrint("Removing from old group " .. tMsg.strGroupOld)
		self:RemovePlayerFromGroup(idx, tMsg.strGroupOld)
	end
	
	--self:CPrint("Adding " .. idx .. " to group " .. tMsg.strGroup)
	self:AddPlayerToGroup(idx, tMsg.strGroup)
	
	-- In case leader changed my group.
	if tMemberData.strCharacterName == self.kstrMyName then
		self.settings.strMyGroup = tMsg.strGroup
	end
	
	self.nDirtyFlag = bit32.bor(self.nDirtyFlag, knDirtyGeneral)
end

function BetterRaidFrames:SendSync()
	if self.chanBrf == nil then return end

	local msg = {}
	msg.strCharacterName = self.kstrMyName
	msg.strMsgType = "SYNC"
	self:SendBRFMessage(msg)
	self:OnBRFMessage(self.chanBrf, msg)
end

function BetterRaidFrames:SendUpdate(strCharacterName, strGroup, strGroupOld)
	if self.chanBrf == nil then return end

	local msg = {}
	msg.strCharacterName = strCharacterName
	msg.strGroup = strGroup
	msg.strGroupOld = strGroupOld
	msg.strMsgType = "UPDATE"
	self:SendBRFMessage(msg)
	self:OnBRFMessage(self.chanBrf, msg)
end

function BetterRaidFrames:OnCharacterCreated()
	local unitPlayer = GameLib.GetPlayerUnit()
	self.kstrMyName = unitPlayer:GetName()
	self.unitTarget = GameLib.GetTargetUnit()
	if self.settings.strChannelName ~= nil then
		self:SetDefaultGroup()
		self:JoinBRFChannel(self.settings.strChannelName)
	end
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

	if self.settings.bDisableFrames then
		self.wndMain:Show(false)
	end
	
	if not self.wndMain:IsShown() and not self.settings.bDisableFrames then
		self:OnMasterLootUpdate()
		self.wndMain:Show(true)
	end
	if self.nDirtyFlag > knDirtyNone then
		if bit32.btest(self.nDirtyFlag, knDirtyGeneral) and not self.settings.bDisableFrames then -- Rebuild everything
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

		if bit32.btest(self.nDirtyFlag, knDirtyResize) and not self.settings.bDisableFrames then
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

function BetterRaidFrames:OnBoostFoodUpdateTimer()
	if self.settings.bDisableFrames or (not self.settings.bShowIcon_Food and not self.settings.bShowIcon_Boost) or not GroupLib.InRaid() then
		return
	end
	
	for idx, tRaidMember in pairs(self.arMemberIndexToWindow) do
		local wndFoodIcon = tRaidMember.wndRaidMemberFoodIcon
		local wndBoostIcon = tRaidMember.wndRaidMemberBoostIcon
	
		local tMemberData = GroupLib.GetGroupMember(idx)
		-- Can happen with a high main update timer and lower boost/food update timer
		if not tMemberData then
			return
		end
		local unitMember = GroupLib.GetUnitForGroupMember(idx)
		
		local bOutOfRange = tMemberData.nHealthMax == 0 or not unitMember
		local bDead = tMemberData.nHealth == 0 and tMemberData.nHealthMax ~= 0
		local bIsOffline = not tMemberData.bIsOnline
		
		local bValidMember = not bOutOfRange and not bDead and not bIsOffline
		
		local wndFoodIcon = tRaidMember.wndRaidMemberFoodIcon
		local wndBoostIcon = tRaidMember.wndRaidMemberBoostIcon
		
		if not bValidMember then
			wndFoodIcon:SetSprite("BRF:Food_Disab_G")
			wndBoostIcon:SetSprite("BRF:Boost_Disab_G")
		else
			local bHasFoodBuff = self:HasBuff(unitMember, kFoodBuffs)
			local bHasBoostBuff = self:HasBuff(unitMember, kBoostBuffs)
			if bHasFoodBuff then
				wndFoodIcon:SetSprite("BRF:Food_Active")
			else
				wndFoodIcon:SetSprite("BRF:Food_Disab_G")
			end
			if bHasBoostBuff then
				wndBoostIcon:SetSprite("BRF:Boost_Active")
			else
				wndBoostIcon:SetSprite("BRF:Boost_Disab_G")
			end
		end	
	end
end

function BetterRaidFrames:HasBuff(unitMember, tBuffs)
	if not unitMember then return false end
	local unitBuffs = unitMember:GetBuffs().arBeneficial
	if not unitBuffs then
		return false
	end
	
	for key, value in pairs(tBuffs) do
		for k, v in pairs(unitBuffs) do
			if v.splEffect:GetName() == value then
				return true
			end
		end
	end
	return false
end


-----------------------------------------------------------------------------------------------
-- Main Draw Methods
-----------------------------------------------------------------------------------------------

function BetterRaidFrames:OnChangeWorld()
	self.nDirtyFlag = bit32.bor(self.nDirtyFlag, knDirtyGeneral)
end

function BetterRaidFrames:OnGroup_Join()
	if not GroupLib.InRaid() then return end
	
	if self.settings.strChannelName ~= nil then
		self:SetDefaultGroup()
		self:SendSync()
	end
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
	if tChangedFlags.bRoleLocked or tChangedFlags.bTank or tChangedFlags.bHealer or tChangedFlags.bDPS or tChangedFlags.bCanInvite or tChangedFlags.bCanKick or tChangedFlags.bCanMark or tChangedFlags.bRaidAssist then
		self.nDirtyFlag = bit32.bor(self.nDirtyFlag, knDirtyGeneral)
	end
	if tChangedFlags.bHasSetReady or (tChangedFlags.bDisconnected and self.bReadyCheckActive) then
		self:OnReadyCheckMemberResponse(nMemberIdx)
	end
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

	if self.settings.bUseGroups then
		local cats = {}
		for key, strCurrCategory in pairs(self.tNamedGroups) do
			table.insert(cats, key)
			self:CPrint("BuildAllFrames: Category: " .. key)
		end
		tCategoriesToUse = cats
	end
	
	local nInvalidOrDeadMembers = 0
	local unitTarget = self.unitTarget
	local bFrameLocked = self.settings.bLockFrame or self.wndRaidLockFrameBtn:IsChecked()

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

		wndRaidCategoryBtn:Show(not bFrameLocked)
		if wndRaidCategoryName:GetText() == "" then
			wndRaidCategoryName:SetText(" " .. strCurrCategory)
		end

		if wndRaidCategoryBtn:IsEnabled() and not wndRaidCategoryBtn:IsChecked() then
			-- Dummy entry to make non-sparse, sortable table.
			tMemberList[0] = {-1, {["strCharacterName"] = "zzzzzzLast"}}
			-- Sort alphabetically in ascending order.
			local sort_func = function( a,b )
				return a[2].strCharacterName < b[2].strCharacterName
			end
			table.sort(tMemberList, sort_func)
			for idx, tCurrMemberList in pairs(tMemberList) do
				if tCurrMemberList[1] ~= -1 then -- Skip the dummy entry added before.
					self:UpdateMemberFrame(tCategory, tCurrMemberList, strCurrCategory)
				end
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
	
	-- Update transparency settings
	if self.settings.bTransparency then
		self.wndMain:SetSprite("")
	elseif self.settings.bLockFrame then
		self.wndMain:SetSprite("sprRaid_BaseNoArrow")
	elseif not self.settings.bLockFrame then
		self.wndMain:SetSprite("sprRaid_Base")
	end	
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
	if tMemberData and self:HelperVerifyMemberCategory(strCategory, tMemberData, nCodeIdx) then
		--self:CPrint("UpdateMemberFrame for: " .. tCurrMemberList[2].strCharacterName .. " into category: " .. strCategory)
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
		local unitMember
		if not self.settings.bDisableFrames then
		 	unitMember = GroupLib.GetUnitForGroupMember(idx)
		end
		
		if not self.settings.bDisableFrames then
			local bOutOfRange = tMemberData.nHealthMax == 0 or not unitMember
			local bDead = tMemberData.nHealth == 0 and tMemberData.nHealthMax ~= 0
			local bIsOnline = tMemberData.bIsOnline
			if not bOutOfRange and not bDead and bIsOnline then
				-- Change the HP Bar Color if required for debuff tracking
				local DebuffColorRequired = self:TrackDebuffsHelper(unitMember, tRaidMember)
				-- Update Bar Colors
				self:UpdateBarColors(tRaidMember, tMemberData, DebuffColorRequired)
		
				-- Update Text Overlays
				-- We're appending on the raid member name which is the default text overlay
				self:UpdateHPText(tMemberData.nHealth, tMemberData.nHealthMax, tRaidMember, tMemberData.strCharacterName)
				self:UpdateShieldText(tMemberData.nShield, tMemberData.nShieldMax, tRaidMember, bOutOfRange)
				self:UpdateAbsorbText(tMemberData.nAbsorption, tRaidMember, bOutOfRange)
			end
		end	
		
		-- Update opacity if out of range
		if not self.settings.bDisableFrames then
			self:CheckRangeHelper(tRaidMember, unitMember, tMemberData)
		end
		
		if not self.settings.bDisableFrames then
			-- HP and Shields
			if tMemberData then
				local bTargetThisMember = unitTarget and unitTarget == unitMember
				local bFrameLocked = self.wndRaidLockFrameBtn:IsChecked()
				wndMemberBtn:SetCheck(bTargetThisMember)
				self:DoHPAndShieldResizing(tRaidMember, tMemberData)
	
				-- Mana Bar
				local bShowManaBar = self.settings.bShowFocus and tMemberData.bHealer
				local wndManaBar = wndMemberBtn:FindChild("RaidMemberManaBar")
	
				if bShowManaBar and tMemberData.nMana and tMemberData.nMana > 0 then
					local nManaMax
					if tMemberData.nManaMax	<= 0 then
						nManaMax = 1000
					else
						nManaMax = tMemberData.nManaMax
					end
					wndManaBar:SetMax(nManaMax)
					wndManaBar:SetProgress(tMemberData.nMana)	
				end
				wndManaBar:Show(bShowManaBar and tMemberData.bIsOnline and not bDead and not bOutOfRange)			
			end
			
			-- Scaling
			self:ResizeBars(tRaidMember, bDead)
			
			if not tMemberData.bIsOnline or tMemberData.nHealthMax == 0 or tMemberData.nHealth == 0 then
				nInvalidOrDeadMembers = nInvalidOrDeadMembers + 1
			end
		end
	end
	if not self.settings.bDisableFrames then
		self.wndRaidTitle:SetText(String_GetWeaselString(Apollo.GetString("RaidFrame_MemberCount"), nGroupMemberCount - nInvalidOrDeadMembers, nGroupMemberCount))
	end
end

local kfnSortCategoryMembers = function(a, b)
	return a:GetData().nCodeIdx  < b:GetData().nCodeIdx
end

function BetterRaidFrames:UpdateOffsets()
	self.nRaidMemberWidth = (self.wndMain:GetWidth() - 22) / self.settings.nNumColumns

	-- Calculate this outside the loop, as its the same for entry (TODO REFACTOR)
	self.nLeftOffsetStartValue = 0

	if self.settings.bShowIcon_Class then
		self.nLeftOffsetStartValue = self.nLeftOffsetStartValue + 16 --wndRaidMember:FindChild("RaidMemberClassIcon"):GetWidth()
	end

	if self.bReadyCheckActive then
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
	if self.settings.bReadyCheckActive then
		-- GetWidth() is too much and leaves empty space.
		nLeftOffset = nLeftOffset + 3 --tRaidMember.wndRaidMemberReadyIcon:GetWidth()
	end
	
	if tRaidMember.wndRaidMemberFoodIcon:IsShown() then
		nLeftOffset = nLeftOffset + tRaidMember.wndRaidMemberFoodIcon:GetWidth()
	end
	
	if tRaidMember.wndRaidMemberBoostIcon:IsShown() then
		nLeftOffset = nLeftOffset + tRaidMember.wndRaidMemberFoodIcon:GetWidth()
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
	-- Happens when bar update timer is faster than the main updater and a new raid is joined.
	if not tMemberData or not tRaidMember then
		return
	end
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
			tRaidMember.wndCurrHealthBar:SetText("  "..tMemberData.strCharacterName.." (OoR)")
		else
			tRaidMember.wndCurrHealthBar:SetText(nil)
		end
	else
		wndMemberBtn:Enable(true)
		wndMemberBtn:ChangeArt("CRB_Raid:btnRaid_ThinHoloBlueBtn")
		tRaidMember.wndRaidMemberStatusIcon:SetSprite("")
		tRaidMember.wndHealthBar:SetSprite("CRB_Raid:sprRaid_ShieldEmptyBar")
		tRaidMember.wndMaxShieldBar:SetSprite("CRB_Raid:sprRaid_ShieldEmptyBar")
		tRaidMember.wndMaxAbsorbBar:SetSprite("CRB_Raid:sprRaid_AbsorbEmptyBar")
		tRaidMember.wndCurrHealthBar:SetFullSprite("BasicSprites:WhiteFill")
		tRaidMember.wndCurrShieldBar:SetFullSprite("BasicSprites:WhiteFill")
		tRaidMember.wndCurrAbsorbBar:SetFullSprite("BasicSprites:WhiteFill")
	end
end

function BetterRaidFrames:OnUpdateBarArtTimer()
	if self.settings.bDisableFrames or not GroupLib.InRaid() then return false end
	for idx, tRaidMember in pairs(self.arMemberIndexToWindow) do
		local unitMember = GroupLib.GetUnitForGroupMember(idx)
		local tMemberData = GroupLib.GetGroupMember(idx)
		self:UpdateBarArt(tMemberData, tRaidMember, unitMember)
	end
end

function BetterRaidFrames:UpdateSpecificMember(tRaidMember, nCodeIdx, tMemberData, nGroupMemberCount, bFrameLocked)
	if self.settings.bDisableFrames then
		return
	end
	if not tRaidMember or not tRaidMember.wnd or not tMemberData then
		return
	end
	local wndRaidMember = tRaidMember.wnd
	if not wndRaidMember or not wndRaidMember:IsValid() then
		return
	end
	
	local wndMemberBtn
	local unitTarget
	local bOutOfRange
	local bDead
	local unitMember
	local bShowClassIcon
	local wndClassIcon
	local bShowLeaderIcon
	local wndLeaderIcon
	local bShowRoleIcon
	local wndRoleIcon
	local bShowMarkIcon
	local wndMarkIcon
	
	-- Fix for flickering when icons in front of bars update
	-- Also for bar offsetting
	self:UpdateOffsets()
	self:ResizeMemberFrame(wndRaidMember)

	wndMemberBtn = tRaidMember.wndRaidMemberBtn
	unitTarget = self.unitTarget

	tRaidMember.wndHealthBar:Show(true)
	tRaidMember.wndMaxAbsorbBar:Show(tMemberData.nHealth > 0 and tMemberData.nHealthMax > 0)
	tRaidMember.wndMaxShieldBar:Show(tMemberData.nHealth > 0 and tMemberData.nShieldMax > 0)
	tRaidMember.wndCurrShieldBar:Show(tMemberData.nHealth > 0 and tMemberData.nShieldMax > 0)
	tRaidMember.wndRaidMemberMouseHack:SetData(tMemberData.nMemberIdx)

	bOutOfRange = tMemberData.nHealthMax == 0 or not unitMember
	bDead = tMemberData.nHealth == 0 and tMemberData.nHealthMax ~= 0
	unitMember = GroupLib.GetUnitForGroupMember(nCodeIdx) -- returns nil when out of range

	self:UpdateBarArt(tMemberData, tRaidMember, unitMember)
	
	local bIsOnline = tMemberData.bIsOnline
	if not bOutOfRange and not bDead and bIsOnline then
		-- Change the HP Bar Color if required for debuff tracking
		local DebuffColorRequired = self:TrackDebuffsHelper(unitMember, tRaidMember)
		-- Update Bar Colors
		self:UpdateBarColors(tRaidMember, tMemberData, DebuffColorRequired)
		
		-- Update Text Overlays
		-- We're appending on the raid member name which is the default text overlay
		self:UpdateHPText(tMemberData.nHealth, tMemberData.nHealthMax, tRaidMember, tMemberData.strCharacterName)
		self:UpdateShieldText(tMemberData.nShield, tMemberData.nShieldMax, tRaidMember, bOutOfRange)
		self:UpdateAbsorbText(tMemberData.nAbsorption, tRaidMember, bOutOfRange)
	end
	
	-- Update opacity if out of range
	self:CheckRangeHelper(tRaidMember, unitMember, tMemberData)
	
	bShowClassIcon = self.settings.bShowIcon_Class
	wndClassIcon = tRaidMember.wndRaidMemberClassIcon
	if bShowClassIcon then
		wndClassIcon:SetSprite(ktIdToClassSprite[tMemberData.eClassId])
		wndClassIcon:SetTooltip(Apollo.GetString(ktIdToClassTooltip[tMemberData.eClassId]))
	end
	wndClassIcon:Show(bShowClassIcon)

	local nLeaderIdx = 0
	bShowLeaderIcon = self.settings.bShowIcon_Leader
	wndLeaderIcon = tRaidMember.wndRaidMemberIsLeader
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
	wndLeaderIcon:Show(bShowLeaderIcon and (nLeaderIdx ~= 0 or self.settings.bConsistentIconOffset))

	local nRoleIdx = -1
	bShowRoleIcon = self.settings.bShowIcon_Role
	wndRoleIcon = tRaidMember.wndRaidMemberRoleIcon

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
	wndRoleIcon:Show(bShowRoleIcon and (nRoleIdx ~= -1 or self.settings.bConsistentIconOffset))

	local nMarkIdx = 0
	bShowMarkIcon = self.settings.bShowIcon_Mark
	wndMarkIcon = tRaidMember.wndRaidMemberMarkIcon
	if bShowMarkIcon then
		nMarkIdx = tMemberData.nMarkerId or 0
		wndMarkIcon:SetSprite(kstrRaidMarkerToSprite[nMarkIdx])
	end
	wndMarkIcon:Show(bShowMarkIcon and (nMarkIdx ~= 0 or self.settings.bConsistentIconOffset))
	
	-- Ready check
	local wndReadyCheckIcon = tRaidMember.wndRaidMemberReadyIcon
	if self.bReadyCheckActive then
		wndReadyCheckIcon:SetSprite(self:MemberToReadyCheckSprite(tMemberData))
	end
	wndReadyCheckIcon:Show(self.bReadyCheckActive)
	
	-- Food icon
	local wndFoodIcon = tRaidMember.wndRaidMemberFoodIcon
	bShowFoodIcon = self.settings.bShowIcon_Food
	if bShowFoodIcon then
		if self:HasBuff(unitMember, kFoodBuffs) then
			wndFoodIcon:SetSprite("BRF:Food_Active")
		else
			wndFoodIcon:SetSprite("BRF:Food_Disab_G")
		end
	end
	wndFoodIcon:Show(bShowFoodIcon)
	
	-- Boost icon
	local wndBoostIcon = tRaidMember.wndRaidMemberBoostIcon
	bShowBoostIcon = self.settings.bShowIcon_Boost
	if bShowBoostIcon then
		if self:HasBuff(unitMember, kBoostBuffs) then
			wndBoostIcon:SetSprite("BRF:Boost_Active")
		else
			wndBoostIcon:SetSprite("BRF:Boost_Disab_G")
		end
	end
	wndBoostIcon:Show(bShowBoostIcon)
	
	-- HP and Shields
	local unitPlayer = GameLib.GetPlayerUnit()
	if tMemberData then
		local bTargetThisMember = unitTarget and unitTarget == unitMember
		local bFrameLocked = self.wndRaidLockFrameBtn:IsChecked()
		wndMemberBtn:SetCheck(bTargetThisMember)
		
		self:ResizeMemberFrame(wndRaidMember) -- Fix for flickering when icons in front of bars update
		self:DoHPAndShieldResizing(tRaidMember, tMemberData)

		-- Scaling
		self:ResizeBars(tRaidMember, bDead)
	end
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
	self.wndRaidTitle:SetAnchorOffsets(bShowMasterLoot and 40 or 10, nTop, nRight, nBottom)

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
		local ReadyCheck = GroupLib.ReadyCheck(strMessage) -- Sanitized in code
		self.wndMain:FindChild("RaidConfigureBtn"):SetCheck(false)
		wndHandler:SetFocus() -- To remove out of edit box
		if not ReadyCheck then
			ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Party, "Unable to start a new ready check while there is still one pending.", "")
			return
		end
		self.bReadyCheckActive = true
	else
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Party, "Unable to start a new ready check while there is still one pending.", "")
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

	-- Table that holds ready check results
	self.tReadyCheckResults = self:GetReadyCheckMemberData()

	self.strReadyCheckInitiator = strName
	self.strReadyCheckMessage = strMessage
	self.fReadyCheckStartTime = os.clock()
	self.bReadyCheckActive = true
	self.nDirtyFlag = bit32.bor(self.nDirtyFlag, knDirtyMembers)

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
	self.bReadyCheckActive = false
	self.nDirtyFlag = bit32.bor(self.nDirtyFlag, knDirtyMembers)

	if self.wndReadyCheckPopup and self.wndReadyCheckPopup:IsValid() then
		self.wndReadyCheckPopup:Destroy()
	end

	local tMembersNotReady = {}
	local tMembersAway = {}
	local tMembersOffline = {}
	-- Shitty lua has no break loop/continue next item support
	for t, member in pairs(self.tReadyCheckResults) do
		local idx = self:CharacterToIdx(member.strCharacterName)
		local memberData
		local bIsOffline
		if idx then
			memberData = GroupLib.GetGroupMember(idx)
			if memberData then
				bIsOffline = not memberData.bIsOnline
			end
		end
			
		-- offline
		if memberData and bIsOffline then
			tMembersOffline[#tMembersOffline + 1] = member.strCharacterName
		end
		-- away
		if memberData and not bIsOffline and not member.bHasSetReady then
			tMembersAway[#tMembersAway + 1] = member.strCharacterName
		end
		-- not ready
		if memberData and not bIsOffline and member.bHasSetReady and not member.bIsReady then
			tMembersNotReady[#tMembersNotReady + 1] = member.strCharacterName
		end
	end
	
	local strMembersNotReady = table.concat(tMembersNotReady, ", ")
	local strMembersAway = table.concat(tMembersAway, ", ")
	local strMembersOffline = table.concat(tMembersOffline, ", ")
	
	-- Hide the ready check icons of all members
	for key, wndCategory in pairs(self.wndRaidCategoryContainer:GetChildren()) do
		for key2, wndMember in pairs(wndCategory:FindChild("RaidCategoryItems"):GetChildren()) do
			wndMember:FindChild("RaidMemberReadyIcon"):Show(false)
		end
	end
	
	self.tReadyCheckResults = nil
	self:ReadyCheckResetIconSprites()
	self:OnRaidFrameBaseTimer()
	self:ResizeAllFrames()
	
	if strMembersNotReady ~= "" then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Party, "The following members are Not Ready: "..strMembersNotReady, "")
	end
	
	if strMembersAway ~= "" then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Party, "The following members are Away: "..strMembersAway, "")
	end
	
	if strMembersOffline ~= "" then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Party, "The following members are Offline: "..strMembersOffline, "")
	end
	
	if strMembersNotReady == "" and strMembersAway == "" and strMembersOffline == "" then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Party, Apollo.GetString("RaidFrame_ReadyCheckSuccess"), "")
	end
end

function BetterRaidFrames:OnReadyCheckMemberResponse(idx)
	local tMemberData = GroupLib.GetGroupMember(idx)
	local bValidReadyCheckIdx = self.tReadyCheckResults and self.tReadyCheckResults[tMemberData.strCharacterName]
	if self.bReadyCheckActive and bValidReadyCheckIdx then
		local tRaidMember = self.arMemberIndexToWindow[idx]
		if not tRaidMember then
			-- Happens in very rare cases, unknown why, but reported by some people.
			return
		end
		local wndReadyCheckIcon = tRaidMember.wndRaidMemberReadyIcon
		if not tMemberData.bIsOnline then
			wndReadyCheckIcon:SetSprite("CRB_Raid:sprRaid_Icon_NotReadyDull")
			self.tReadyCheckResults[tMemberData.strCharacterName].bHasSetReady = false
			self.tReadyCheckResults[tMemberData.strCharacterName].bIsReady = false
		elseif tMemberData.bHasSetReady and tMemberData.bReady then
			wndReadyCheckIcon:SetSprite("CRB_Raid:sprRaid_Icon_ReadyCheckDull")
			self.tReadyCheckResults[tMemberData.strCharacterName].bHasSetReady = true
			self.tReadyCheckResults[tMemberData.strCharacterName].bIsReady = true
		elseif tMemberData.bHasSetReady and not tMemberData.bReady then
			wndReadyCheckIcon:SetSprite("CRB_Raid:sprRaid_Icon_NotReadyDull")
			self.tReadyCheckResults[tMemberData.strCharacterName].bHasSetReady = true
			self.tReadyCheckResults[tMemberData.strCharacterName].bIsReady = false
		end
	end
end

function BetterRaidFrames:ReadyCheckResetIconSprites()
	nGroupMemberCount = GroupLib.GetMemberCount()
	for nMemberIdx=0, nGroupMemberCount do
		local tRaidMember = self.arMemberIndexToWindow[nMemberIdx]
		if tRaidMember then
			local wndReadyCheckIcon = tRaidMember.wndRaidMemberReadyIcon
			wndReadyCheckIcon:SetSprite("CRB_Raid:sprRaid_Icon_NotReadyDull")
		end
	end		
end

function BetterRaidFrames:MemberToReadyCheckSprite(tMemberData)
	local member = self.tReadyCheckResults[tMemberData.strCharacterName]
	if not member then
		return "CRB_Raid:sprRaid_Icon_NotReadyDull"
	end
	
	if not tMemberData.bIsOnline then
		-- member is offline, set to not ready
		return "CRB_Raid:sprRaid_Icon_NotReadyDull"
	elseif not member.bHasSetReady then
		-- No ready/not ready selection made yet.
		return "CRB_Raid:sprRaid_Icon_NotReadyDull"
	elseif member.bHasSetReady and not member.bIsReady then
		-- Not ready
		return "CRB_Raid:sprRaid_Icon_NotReadyDull"
	elseif member.bHasSetReady and member.bIsReady then
		-- Ready, yay :)
		return "CRB_Raid:sprRaid_Icon_ReadyCheckDull"
	else
		-- Should not end up here, but just in case.
		return "CRB_Raid:sprRaid_Icon_NotReadyDull"
	end
end

function BetterRaidFrames:GetReadyCheckMemberData()
	local table = {}
	local nGroupMemberCount = GroupLib.GetMemberCount()
	for nMemberIdx=0, nGroupMemberCount do
		local tMemberData = GroupLib.GetGroupMember(nMemberIdx)
		if tMemberData ~= nil then
			table[tMemberData.strCharacterName] = {
				bHasSetReady = false,
				bIsReady = false,
				strCharacterName = tMemberData.strCharacterName,
			}
		end
	end
	return table
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

function BetterRaidFrames:OnRaidMemberBtnClick(wndHandler, wndControl, eMouseButton) -- RaidMemberMouseHack
	-- GOTCHA: Use MouseUp instead of ButtonCheck to avoid weird edgecase bugs
	if wndHandler ~= wndControl or not wndHandler or not wndHandler:GetData() then
		return
	end

	local unit = GroupLib.GetUnitForGroupMember(wndHandler:GetData())
	if unit and eMouseButton == 0 then
		GameLib.SetTargetUnit(unit)
		
		if self.settings.bRememberPrevTarget then
			self.PrevTarget = unit
		end
		
		self.nDirtyFlag = bit32.bor(self.nDirtyFlag, knDirtyResize)
	end
	
	if eMouseButton == 1 and unit then
		Event_FireGenericEvent("GenericEvent_NewContextMenuPlayerDetailed", wndHandler, unit:GetName(), unit)
	end
end

function BetterRaidFrames:OnRaidLockFrameBtnToggle(wndHandler, wndControl) -- RaidLockFrameBtn
	self.settings.bLockFrame = wndHandler:IsChecked()
	self:LockFrameHelper(self.settings.bLockFrame)
	self:BuildAllFrames()
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
				local strGroupName = self.tMemberToGroup[nMemberIdx]
				self:RemovePlayerFromGroup(nMemberIdx, strGroupName)
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
	
	if bLock and not self.settings.bTransparency then
		self.wndMain:SetSprite("sprRaid_BaseNoArrow")
	elseif not bLock and not self.settings.bTransparency then
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

function BetterRaidFrames:HelperVerifyMemberCategory(strCurrCategory, tMemberData, nMemberIdx)
	local bResult = true
	if self.settings.bUseGroups then
		bResult = strCurrCategory == self.tMemberToGroup[nMemberIdx]
	else
		if strCurrCategory == Apollo.GetString("RaidFrame_Tanks") then
			bResult =  tMemberData.bTank
		elseif strCurrCategory == Apollo.GetString("RaidFrame_Healers") then
			bResult = tMemberData.bHealer
		elseif strCurrCategory == Apollo.GetString("RaidFrame_DPS") then
			bResult = not tMemberData.bTank and not tMemberData.bHealer
		end
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
	
	-- Status variables
	local bDead = tMemberData.nHealth == 0 and tMemberData.nHealthMax ~= 0

	-- Bars
	local wndHealthBar = tRaidMember.wndHealthBar
	local wndMaxAbsorb = tRaidMember.wndMaxAbsorbBar
	local wndMaxShield = tRaidMember.wndMaxShieldBar
	local wndCurrShieldBar = tRaidMember.wndCurrShieldBar
	local wndCurrAbsorbBar = tRaidMember.wndCurrAbsorbBar
	local wndCurrHealthBar = tRaidMember.wndCurrHealthBar

	wndHealthBar:Show(true)
	wndMaxAbsorb:Show(not bDead and self.settings.bShowAbsorbBar)
	wndMaxShield:Show(not bDead and nShieldMax > 0 and self.settings.bShowShieldBar)
	wndCurrShieldBar:Show(not bDead and nShieldMax > 0 and self.settings.bShowShieldBar)
	
	if self.settings.bShowShieldBar then
		self:SetBarValue(wndCurrShieldBar, 0, nShieldCurr, nShieldMax)
	end
	if self.settings.bShowAbsorbBar then
		self:SetBarValue(wndCurrAbsorbBar, 0, nAbsorbCurr, nAbsorbMax)
	end
	self:SetBarValue(wndCurrHealthBar, 0, nHealthCurr, nHealthMax)
end

function BetterRaidFrames:ResizeBars(tRaidMember, bDead)
	local nWidth = tRaidMember.wndRaidMemberBtn:GetWidth() - 4
	local wndHealthBar = tRaidMember.wndHealthBar
	local wndMaxAbsorb = tRaidMember.wndMaxAbsorbBar
	local wndMaxShield = tRaidMember.wndMaxShieldBar
	local nLeft, nTop, nRight, nBottom = wndHealthBar:GetAnchorOffsets()
	
	-- Define offsets based on settings of which bars to show
	if self.settings.bShowShieldBar and self.settings.bShowAbsorbBar then
		wndHealthBar:SetAnchorOffsets(nLeft, nTop, nWidth * 0.67, nBottom)
		wndMaxShield:SetAnchorOffsets(nWidth * 0.67, nTop, nWidth * 0.85, nBottom)
		wndMaxAbsorb:SetAnchorOffsets(nWidth * 0.85, nTop, nWidth, nBottom)
	end
	
	if self.settings.bShowShieldBar and not self.settings.bShowAbsorbBar then
		wndHealthBar:SetAnchorOffsets(nLeft, nTop, nWidth * 0.75, nBottom)
		wndMaxShield:SetAnchorOffsets(nWidth * 0.75, nTop, nWidth, nBottom)
	end
	
	if not self.settings.bShowShieldBar and self.settings.bShowAbsorbBar then
		wndHealthBar:SetAnchorOffsets(nLeft, nTop, nWidth * 0.8, nBottom)
		wndMaxAbsorb:SetAnchorOffsets(nWidth * 0.8, nTop, nWidth, nBottom)
	end
	
	if not self.settings.bShowShieldBar and not self.settings.bShowAbsorbBar then
		wndHealthBar:SetAnchorOffsets(nLeft, nTop, nWidth, nBottom)
	end
end

function BetterRaidFrames:UpdateHPText(nHealthCurr, nHealthMax, tRaidMember, strCharacterName)
	local wnd = tRaidMember.wndCurrHealthBar
	-- No text needs to be drawn if all HP Text options are disabled
	if not self.settings.bShowHP_Full and not self.settings.bShowHP_K and not self.settings.bShowHP_Pct then
		-- Update text to be empty, otherwise it will be stuck at the old value
		if self.settings.bShowNames then
			wnd:SetText(" "..strCharacterName)
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
			wnd:SetText(" "..strCharacterName.." - "..nHealthCurr.."/"..nHealthMax)
		else
			wnd:SetText(" "..nHealthCurr.."/"..nHealthMax)
		end
		return
	end

	-- ShowHP_Full + Pct
	if self.settings.bShowHP_Full and not self.settings.bShowHP_K and self.settings.bShowHP_Pct then
		if self.settings.bShowNames then
			wnd:SetText(" "..strCharacterName.." - "..nHealthCurr.."/"..nHealthMax.." ("..strHealthPercentage..")")
		else
			wnd:SetText(" "..nHealthCurr.."/"..nHealthMax.." ("..strHealthPercentage..")")
		end
		return
	end

	-- Only ShowHP_K selected
	if not self.settings.bShowHP_Full and self.settings.bShowHP_K and not self.settings.bShowHP_Pct then
		if self.settings.bShowNames then
			wnd:SetText(" "..strCharacterName.." - "..strHealthCurrRounded.."/"..strHealthMaxRounded)
		else
			wnd:SetText(" "..strHealthCurrRounded.."/"..strHealthMaxRounded)
		end
		return
	end

	-- ShowHP_K + Pct
	if not self.settings.bShowHP_Full and self.settings.bShowHP_K and self.settings.bShowHP_Pct then
		if self.settings.bShowNames then
			wnd:SetText(" "..strCharacterName.." - "..strHealthCurrRounded.."/"..strHealthMaxRounded.." ("..strHealthPercentage..")")
		else
			wnd:SetText(" "..strHealthCurrRounded.."/"..strHealthMaxRounded.." ("..strHealthPercentage..")")
		end
		return
	end

	-- Only Pct selected
	if not self.settings.bShowHP_Full and not self.settings.bShowHP_K and self.settings.bShowHP_Pct then
		if self.settings.bShowNames then
			wnd:SetText(" "..strCharacterName.." - "..strHealthPercentage)
		else
			wnd:SetText(" "..strHealthPercentage)
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
	-- No text needs to be drawn if all Shield Text options are disabled
	if not self.settings.bShowShield_K and not self.settings.bShowShield_Pct then
		-- Update text to be empty, otherwise it will be stuck at the old value
		wnd:SetText(nil)
		return
	end
	
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
	-- No text needs to be drawn if all absorb text options are disabled
	if not self.settings.bShowAbsorb_K then
		wnd:SetText(nil)
		return
	end
	
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

	if self.settings.bShowAbsorb_K then
		wnd:SetText(strAbsorbCurrRounded)
		return
	end
end

function BetterRaidFrames:CheckRangeHelper(tRaidMember, unitMember, tMemberData)
	local opacity
	
	-- Use these variables to determine if opacity has to be set.
	-- We use custom sprites, and no opacity change when OoR, dead, or offline
	local bOutOfRange = tMemberData.nHealthMax == 0 or not unitMember
	local bDead = tMemberData.nHealth == 0 and tMemberData.nHealthMax ~= 0
	local bOffline = not tMemberData.bIsOnline
	
	if self.settings.bCheckRange and not bOutOfRange and not bDead and not bOffline then
		local player = GameLib.GetPlayerUnit()
		if player == nil then return end
		
		if unitMember ~= player and (unitMember == nil or not self:RangeCheck(unitMember, player, self.settings.fMaxRange)) then
			opacity = 0.4
		else
			opacity = 1
		end
	end
	tRaidMember.wndCurrHealthBar:SetOpacity(opacity)
	tRaidMember.wndCurrShieldBar:SetOpacity(opacity)
	tRaidMember.wndCurrAbsorbBar:SetOpacity(opacity)
end

function BetterRaidFrames:RangeCheck(unit1, unit2, range)
	local v1 = unit1:GetPosition()
	local v2 = unit2:GetPosition()
	
	local dx, dy, dz = v1.x - v2.x, v1.y - v2.y, v1.z - v2.z
	
	return dx*dx + dy*dy + dz*dz <= range*range
end

function BetterRaidFrames:TrackSavedCharacters()
	self.BetterRaidFramesTearOff:TrackSavedCharacters()
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

function BetterRaidFrames:TrackDebuffsHelper(unitMember, tRaidMember)
	local wnd = tRaidMember.wndCurrHealthBar

	-- Only continue if we are required to TrackDebuffs according to the settings
	if not self.settings.bTrackDebuffs then
		return false
	end

	local playerBuffs = unitMember:GetBuffs()
	local debuffs = playerBuffs['arHarmful']	
    	
	-- If player has no debuffs, change the color to normal in case it was changed before.
	if next(debuffs) == nil then
		return false
	end
	
	-- Loop through all debuffs. Change HP bar color if class of splEffect equals 38, which means it is dispellable
	for key, value in pairs(debuffs) do
		if value['splEffect']:GetClass() == 38 then
			return true
		end
	end

	-- Reset to normal sprite if there were debuffs but none of them were dispellable.
	-- This might happen in cases where a player had a dispellable debuff -and- a non-dispellable debuff on him
	return false
end

function BetterRaidFrames:UpdateBarColors(tRaidMember, tMemberData, DebuffColorRequired)
	local wndHP = tRaidMember.wndCurrHealthBar
	local wndShield = tRaidMember.wndCurrShieldBar
	local wndAbsorb = tRaidMember.wndCurrAbsorbBar
	
	local HPHealthyColor
	local HPDebuffColor
	local ShieldBarColor
	local AbsorbBarColor
	
	if self.settings.bClassSpecificBarColors then
		local strClassKey = "strColor"..ktClassIdToClassName[tMemberData.eClassId]
		HPHealthyColor = self.settings[strClassKey.."_HPHealthy"]
		HPDebuffColor = self.settings[strClassKey.."_HPDebuff"]
		ShieldBarColor = self.settings[strClassKey.."_Shield"]
		AbsorbBarColor = self.settings[strClassKey.."_Absorb"]
	else
		HPHealthyColor = self.settings.strColorGeneral_HPHealthy
		HPDebuffColor = self.settings.strColorGeneral_HPDebuff
		ShieldBarColor = self.settings.strColorGeneral_Shield
		AbsorbBarColor = self.settings.strColorGeneral_Absorb
	end

	if DebuffColorRequired then
		wndHP:SetBarColor(HPDebuffColor)
	else
		wndHP:SetBarColor(HPHealthyColor)
	end
	
	wndShield:SetBarColor(ShieldBarColor)
	wndAbsorb:SetBarColor(AbsorbBarColor)
end

function BetterRaidFrames:CharacterToIdx(strCharacterName)
	local nGroupMemberCount = GroupLib.GetMemberCount()
	for idx = 1, nGroupMemberCount do
		local unitPlayer = GroupLib.GetGroupMember(idx)
		if unitPlayer ~= nil then
			if strCharacterName == unitPlayer.strCharacterName then
				return idx
			end
		end
	end
end

function BetterRaidFrames:FactoryMemberWindow(wndParent, nCodeIdx)
	if self.cache == nil then
		self.cache = {}
	end
	
	local tbl = self.cache[nCodeIdx]
	
	if tbl == nil or not tbl.wnd:IsValid() then
		local wndNew = Apollo.LoadForm(self.xmlDoc, "RaidMember", wndParent, self)
		wndNew:SetName(nCodeIdx)

		tbl =
		{
			["nCodeIdx"] = nCodeIdx,
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
			wndRaidMemberClassIcon = wndNew:FindChild("RaidMemberClassIcon"),
			wndRaidMemberIsLeader = wndNew:FindChild("RaidMemberIsLeader"),
			wndRaidMemberRoleIcon = wndNew:FindChild("RaidMemberRoleIcon"),
			wndRaidMemberReadyIcon = wndNew:FindChild("RaidMemberReadyIcon"),
			wndRaidMemberMarkIcon = wndNew:FindChild("RaidMemberMarkIcon"),
			wndRaidMemberFoodIcon = wndNew:FindChild("RaidMemberFoodIcon"),
			wndRaidMemberBoostIcon = wndNew:FindChild("RaidMemberBoostIcon"),
		}
		wndNew:SetData(tbl)
		self.cache[nCodeIdx] = tbl

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
	self:CPrint("FactoryCategoryWindow: " .. strKey)
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
	self.nDirtyFlag = bit32.bor(self.nDirtyFlag, knDirtyMembers)
	self.settings.bShowIcon_Class = wndHandler:IsChecked()
	-- Fix for flickering when icons in front of bars update
	self:UpdateOffsets()
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
	self.settings.bShowCategories = wndHandler:IsChecked()
	if self.settings.bUseGroups then
		self.settings.bUseGroups = false
		self.wndRaidCustomizeGroups:SetCheck(false)
	end
	self.nDirtyFlag = bit32.bor(self.nDirtyFlag, knDirtyGeneral, knDirtyResize)
end

function BetterRaidFrames:OnRaidCustomizeNamesCheck( wndHandler, wndControl, eMouseButton )
	self.nDirtyFlag = bit32.bor(self.nDirtyFlag, knDirtyMembers)
	self.settings.bShowNames = wndHandler:IsChecked()
end

function BetterRaidFrames:OnRaidCustomizeCombatLock( wndHandler, wndControl, eMouseButton )
	self.settings.bAutoLock_Combat = wndHandler:IsChecked()
end

function BetterRaidFrames:OnRaidCustomizeFoodIconsCheck( wndHandler, wndControl, eMouseButton )
	self.nDirtyFlag = bit32.bor(self.nDirtyFlag, knDirtyMembers)
	self.settings.bShowIcon_Food = wndHandler:IsChecked()
	self:OnBoostFoodUpdateTimer()
end

function BetterRaidFrames:OnRaidCustomizeBoostIconsCheck( wndHandler, wndControl, eMouseButton )
	self.nDirtyFlag = bit32.bor(self.nDirtyFlag, knDirtyMembers)
	self.settings.bShowIcon_Boost = wndHandler:IsChecked()
	self:OnBoostFoodUpdateTimer()
end

function BetterRaidFrames:OnRaidCustomizeGroupCheck( wndHandler, wndControl, eMouseButton )
	self.settings.bUseGroups = wndHandler:IsChecked()
	if self.settings.bShowCategories then
		self.settings.bShowCategories = false
		self.wndRaidCustomizeCategories:SetCheck(false)
	end
	self.nDirtyFlag = bit32.bor(self.nDirtyFlag, knDirtyGeneral, knDirtyResize)
end

---------------------------------------------------------------------------------------------------
-- RaidMember Functions
---------------------------------------------------------------------------------------------------

function BetterRaidFrames:RaidMemberBtn_OnMouseEnter( wndHandler, wndControl, x, y )
	if not wndControl or not self.settings.bMouseOverSelection then
		return
	end
	
	if wndControl:GetName() == "RaidMemberMouseHack" then
		if self.settings.bRememberPrevTarget and not self.bOldTargetSet then
			self.PrevTarget = GameLib.GetTargetUnit()
			self.bOldTargetSet = true
		end

		local idx = wndControl:GetData()
		local unit = GroupLib.GetUnitForGroupMember(idx)
		if unit ~= nil then
			GameLib.SetTargetUnit(unit)
		end
	end
end

function BetterRaidFrames:RaidMemberBtn_OnMouseExit( wndHandler, wndControl, x, y )
	if not wndHandler or not wndControl or not self.settings.bMouseOverSelection or not self.settings.bRememberPrevTarget or not self.bOldTargetSet then
		return
	end
	if wndHandler == wndControl then
		GameLib.SetTargetUnit(self.PrevTarget)
		self.bOldTargetSet = false
	end
end

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
end

function BetterRaidFrames:Button_ShowAbsorbBar( wndHandler, wndControl, eMouseButton )
	self.settings.bShowAbsorbBar = wndControl:IsChecked()
end

function BetterRaidFrames:Button_MouseOverSelection( wndHandler, wndControl, eMouseButton )
	self.settings.bMouseOverSelection = wndControl:IsChecked()
	if not self.settings.bMouseOverSelection then
		self.wndConfig:FindChild("Button_RememberPrevTarget"):SetCheck(false)
		self.settings.bRememberPrevTarget = false
	end
end

function BetterRaidFrames:Button_RememberPrevTarget( wndHandler, wndControl, eMouseButton )
	self.settings.bRememberPrevTarget = wndControl:IsChecked()
	if not self.settings.bMouseOverSelection and self.settings.bRememberPrevTarget then
		self.wndConfig:FindChild("Button_MouseOverSelection"):SetCheck(true)
		self.settings.bMouseOverSelection = true
	end
end

function BetterRaidFrames:Button_SetTransparency( wndHandler, wndControl, eMouseButton )
	self.settings.bTransparency = wndControl:IsChecked()
	self:BuildAllFrames()
	self.BetterRaidFramesTearOff:BarTexturesHelper()
end


function BetterRaidFrames:Button_CheckRange( wndHandler, wndControl, eMouseButton )
	self.settings.bCheckRange = wndControl:IsChecked()
end

function BetterRaidFrames:Slider_MaxRange( wndHandler, wndControl, fNewValue, fOldValue )
	if math.floor(fNewValue) == math.floor(fOldValue) then return end
	self.wndConfig:FindChild("Label_MaxRangeDisplay"):SetText(string.format("%sm", math.floor(fNewValue)))
	self.settings.fMaxRange = math.floor(fNewValue)
end

function BetterRaidFrames:Button_DisableRaidFrames( wndHandler, wndControl, eMouseButton )
	self.settings.bDisableFrames = wndControl:IsChecked()
	if not self.settings.bDisableFrames then
		-- Call TrackSavedCharacters in the TearOff frame after the MainUpdateTimer ran (1 sec to be sure)
		Apollo.CreateTimer("TrackSavedCharactersTimer", 1, false)
		self.nDirtyFlag = bit32.bor(self.nDirtyFlag, knDirtyGeneral, knDirtyResize)
	end
end

function BetterRaidFrames:Button_ConsistentIconOffset( wndHandler, wndControl, eMouseButton )
	self.settings.bConsistentIconOffset = wndHandler:IsChecked()
	self.nDirtyFlag = bit32.bor(self.nDirtyFlag, knDirtyMembers)
end

function BetterRaidFrames:CPrint(str)
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Command, str, "")
end

function BetterRaidFrames:Tokenize(str)
	local idx = 1
	local out = {}
	for word in string.gmatch(str, "%S+") do
		out[idx] = word
		idx = idx + 1
	end
	return out
end

function BetterRaidFrames:OnSlashCmd(sCmd, sInput)
	local option = string.lower(sInput)
	local optionTokenized = self:Tokenize(sInput)
	if option == nil or option == "" then
		self:CPrint("Thanks for using BetterRaidFrames :)")
		self:CPrint("/brf options - Options Menu")
		self:CPrint("/brf colors - Customize Bar Colors")
		self:CPrint("/brf advanced - Advanced options, such as controlling timers")
		self:CPrint("/brf group <name> - In group-view mode, join group <name>")
		self:CPrint("/brf channel <name> - Use <name> to communicate with other BetterRaidFrames users in the raid")
	elseif option == "options" then
		self:OnConfigOn()
	elseif option == "colors" then
		self:OnConfigColorsOn()
	elseif option == "advanced" then
		self:OnConfigAdvancedOn()
	elseif string.lower(optionTokenized[1]) == "channel" then
		self:OnSetChannel(optionTokenized)
	elseif string.lower(optionTokenized[1]) == "group" then
		self:OnSetGroup(optionTokenized)
	end
end

function BetterRaidFrames:JoinBRFChannel(chan)
	self.chanBrf = ICCommLib.JoinChannel(chan, "OnBRFMessage", self)
	self:CPrint("Your BRF communication channel is now: " .. chan)
end

-- Command: /brf channel <name>
function BetterRaidFrames:OnSetChannel(tokens)
	if tokens[2] == nil then
		self:CPrint("Join which channel? Syntax: /brf channel <name>")
		return
	end
	local chanName = tokens[2]
	self.settings.strChannelName = chanName
	self:SetDefaultGroup()
	self:JoinBRFChannel(chanName)
	self:SendSync()
end

-- Command: /brf group <name>
-- Leader command: /brf group <name> <playername>
function BetterRaidFrames:OnSetGroup(tokens)
	local groupName = tokens[2]
	if tokens[2] == nil then
		self:CPrint("Join which group? Syntax: /brf group <name>")
		return
	end
	
	if tokens[3] ~= nil then
		if not GroupLib.InRaid() then
			self:CPrint("You must be in a raid to set someone elses group!")
			return
		end

		local playerName = string.lower(tokens[3])
		local nMembers = GroupLib.GetMemberCount()
		for idx = 1, nMembers do
			local tMemberData = GroupLib.GetGroupMember(idx)
			if tMemberData.strCharacterName == self.kstrMyName then
				if not tMemberData.bIsLeader and not tMemberData.bRaidAssistant then
					self:CPrint("You cannot set someone elses group unless you are a raid leader / assistant!")
					return
				end
			end
		end

		for idx = 1, nMembers do
			local tMemberData = GroupLib.GetGroupMember(idx)
			if string.lower(tMemberData.strCharacterName) == playerName then
				local oldGroup = self.tMemberToGroup[idx]
				return self:SendUpdate(tMemberData.strCharacterName, groupName, oldGroup)
			end
		end
		self:CPrint("Unable to find player by the name of " .. playerName)
	else
		if groupName == self.settings.strMyGroup then
			self:CPrint("You are already in that group.")
		end
		
		local oldGroup = self.settings.strMyGroup
		self.settings.strMyGroup = groupName
		self:CPrint("Your group is now set to: " .. groupName .. " (was " .. oldGroup .. ")")
		if GroupLib.InRaid() then
			self:CPrint("Updating...")
			self:SendUpdate(self.kstrMyName, groupName, oldGroup)
		end
	end
end

---------------------------------------------------------------------------------------------------
-- ConfigColorsForm Functions
---------------------------------------------------------------------------------------------------

function BetterRaidFrames:OnConfigColorsOn()
	self:RefreshSettings()
	self.wndConfigColors:Show(true)
end

function BetterRaidFrames:OnConfigColorsCloseButton( wndHandler, wndControl, eMouseButton )
	self.wndConfigColors:Show(false)
end

-- API for wndControl:IsChecked() updates too slowly so need separate uncheck handlers.. /sigh
function BetterRaidFrames:Button_ColorSettingsGeneralCheck( wndHandler, wndControl, eMouseButton )
	self.wndConfigColorsGeneral:Show(true)
end

function BetterRaidFrames:Button_ColorSettingsGeneralUncheck( wndHandler, wndControl, eMouseButton )
	self.wndConfigColorsGeneral:Show(false)
end

function BetterRaidFrames:Button_ColorSettingsEngineerCheck( wndHandler, wndControl, eMouseButton )
	self.wndConfigColorsEngineer:Show(true)
end

function BetterRaidFrames:Button_ColorSettingsEngineerUncheck( wndHandler, wndControl, eMouseButton )
	self.wndConfigColorsEngineer:Show(false)
end

function BetterRaidFrames:Button_ColorSettingsEsperCheck( wndHandler, wndControl, eMouseButton )
	self.wndConfigColorsEsper:Show(true)
end

function BetterRaidFrames:Button_ColorSettingsEsperUncheck( wndHandler, wndControl, eMouseButton )
	self.wndConfigColorsEsper:Show(false)
end

function BetterRaidFrames:Button_ColorSettingsMedicCheck( wndHandler, wndControl, eMouseButton )
	self.wndConfigColorsMedic:Show(true)
end

function BetterRaidFrames:Button_ColorSettingsMedicUncheck( wndHandler, wndControl, eMouseButton )
	self.wndConfigColorsMedic:Show(false)
end

function BetterRaidFrames:Button_ColorSettingsSpellslingerCheck( wndHandler, wndControl, eMouseButton )
	self.wndConfigColorsSpellslinger:Show(true)
end

function BetterRaidFrames:Button_ColorSettingsSpellslingerUncheck( wndHandler, wndControl, eMouseButton )
	self.wndConfigColorsSpellslinger:Show(false)
end

function BetterRaidFrames:Button_ColorSettingsStalkerCheck( wndHandler, wndControl, eMouseButton )
	self.wndConfigColorsStalker:Show(true)
end

function BetterRaidFrames:Button_ColorSettingsStalkerUncheck( wndHandler, wndControl, eMouseButton )
	self.wndConfigColorsStalker:Show(false)
end

function BetterRaidFrames:Button_ColorSettingsWarriorCheck( wndHandler, wndControl, eMouseButton )
	self.wndConfigColorsWarrior:Show(true)
end

function BetterRaidFrames:Button_ColorSettingsWarriorUncheck( wndHandler, wndControl, eMouseButton )
	self.wndConfigColorsWarrior:Show(false)
end

---------------------------------------------------------------------------------------------------
-- ConfigColorsGeneral Functions
---------------------------------------------------------------------------------------------------

function BetterRaidFrames:Button_ClassSpecificBarColors( wndHandler, wndControl, eMouseButton )
	self.settings.bClassSpecificBarColors = wndHandler:IsChecked()
end

function BetterRaidFrames:OnColorReset( wndHandler, wndControl, eMouseButton )
	if wndHandler ~= wndControl then return end
	local strCategory = wndControl:GetParent():GetParent():GetParent():GetName()
	local strIdentifier = wndControl:GetParent()
	local strCategorySettingKey = ktCategoryToSettingKeyPrefix[strCategory]..strIdentifier:GetName()
	strIdentifier:FindChild("ColorWindow"):SetBGColor(DefaultSettings[strCategorySettingKey])
	self.settings[strCategorySettingKey] = DefaultSettings[strCategorySettingKey]
end

function BetterRaidFrames:OnColorClick( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= wndControl or eMouseButton ~= GameLib.CodeEnumInputMouse.Left then return end
	local strCategory = wndControl:GetParent():GetParent():GetParent():GetName()
	local strIdentifier = wndControl:GetParent()
	local strCategorySettingKey = ktCategoryToSettingKeyPrefix[strCategory]..strIdentifier:GetName()
	self.GeminiColor:ShowColorPicker(self, {callback = "OnGeminiColor", bCustomColor = true, strInitialColor = self.settings[strCategorySettingKey]}, strCategory, strIdentifier, strCategorySettingKey)
end

function BetterRaidFrames:OnGeminiColor(strColor, strCategory, strIdentifier, strCategorySettingKey)
	strIdentifier:FindChild("ColorWindow"):SetBGColor(strColor)
	self.settings[strCategorySettingKey] = strColor
end

---------------------------------------------------------------------------------------------------
-- ConfigAdvancedForm Functions
---------------------------------------------------------------------------------------------------

function BetterRaidFrames:OnConfigAdvancedOn()
	self:RefreshSettings()
	self.wndConfigAdvanced:Show(true)
	self.wndConfigAdvanced:FindChild("Button_SettingsGeneral"):SetCheck(true)
	self.wndConfigAdvancedGeneral:Show(true)
end

function BetterRaidFrames:Button_AdvancedSettingsGeneralCheck( wndHandler, wndControl, eMouseButton )
	self.wndConfigAdvancedGeneral:Show(true)
end

---------------------------------------------------------------------------------------------------
-- ConfigAdvancedGeneral Functions
---------------------------------------------------------------------------------------------------

function BetterRaidFrames:Button_AdvancedSettingsGeneralUncheck( wndHandler, wndControl, eMouseButton )
	self.wndConfigAdvancedGeneral:Show(false)
end

function BetterRaidFrames:OnConfigAdvancedCloseButton( wndHandler, wndControl, eMouseButton )
	self.wndConfigAdvanced:Show(false)
end

function BetterRaidFrames:Slider_BarArtTimer( wndHandler, wndControl, fNewValue, fOldValue )
	if math.floor(fNewValue) == math.floor(fOldValue) then return end
	self.wndConfigAdvancedGeneral:FindChild("Label_AdvancedSettingsOuter:Label_BarArtTimerDisplay"):SetText(string.format("%ss", math.floor(fNewValue) / 10))
	self.settings.fBarArtTimer = math.floor(fNewValue) / 10
	self:UpdateBarArtTimer()
end

function BetterRaidFrames:OnBarArtTimerReset( wndHandler, wndControl, eMouseButton )
	self.settings.fBarArtTimer = DefaultSettings.fBarArtTimer
	self.wndConfigAdvancedGeneral:FindChild("Label_AdvancedSettingsOuter:Label_BarArtTimerDisplay"):SetText(string.format("%ss", self.settings.fBarArtTimer))
	self.wndConfigAdvancedGeneral:FindChild("Label_AdvancedSettingsOuter:Window_RangeSliderBarArt:Slider_BarArtTimer"):SetValue(self.settings.fBarArtTimer * 10)
	self:UpdateBarArtTimer()
end

function BetterRaidFrames:UpdateBarArtTimer()
	Apollo.StopTimer("UpdateBarArtTimer")
	Apollo.CreateTimer("UpdateBarArtTimer", self.settings.fBarArtTimer, true)
end

function BetterRaidFrames:Slider_BoostFoodTimer( wndHandler, wndControl, fNewValue, fOldValue )
	if math.floor(fNewValue) == math.floor(fOldValue) then return end
	self.wndConfigAdvancedGeneral:FindChild("Label_AdvancedSettingsOuter:Label_BoostFoodTimerDisplay"):SetText(string.format("%ss", math.floor(fNewValue) / 10))
	self.settings.fBoostFoodTimer = math.floor(fNewValue) / 10
	self:UpdateBoostFoodTimer()
end

function BetterRaidFrames:OnBoostFoodTimerReset( wndHandler, wndControl, eMouseButton )
	self.settings.fBoostFoodTimer = DefaultSettings.fBoostFoodTimer
	self.wndConfigAdvancedGeneral:FindChild("Label_AdvancedSettingsOuter:Label_BoostFoodTimerDisplay"):SetText(string.format("%ss", self.settings.fBoostFoodTimer))
	self.wndConfigAdvancedGeneral:FindChild("Label_AdvancedSettingsOuter:Window_RangeSliderBoostFood:Slider_BoostFoodTimer"):SetValue(self.settings.fBoostFoodTimer * 10)
	self:UpdateBoostFoodTimer()
end

function BetterRaidFrames:UpdateBoostFoodTimer()
	Apollo.StopTimer("BoostFoodUpdateTimer")
	Apollo.CreateTimer("BoostFoodUpdateTimer", self.settings.fBoostFoodTimer, true)
end

function BetterRaidFrames:Slider_MainUpdateTimer( wndHandler, wndControl, fNewValue, fOldValue )
	if math.floor(fNewValue) == math.floor(fOldValue) then return end
	self.wndConfigAdvancedGeneral:FindChild("Label_AdvancedSettingsOuter:Label_MainUpdateTimerDisplay"):SetText(string.format("%ss", math.floor(fNewValue) / 10))
	self.settings.fMainUpdateTimer = math.floor(fNewValue) / 10
	self:UpdateMainUpdateTimer()
end

function BetterRaidFrames:OnMainUpdateTimerReset( wndHandler, wndControl, eMouseButton )
	self.settings.fMainUpdateTimer = DefaultSettings.fMainUpdateTimer
	self.wndConfigAdvancedGeneral:FindChild("Label_AdvancedSettingsOuter:Label_MainUpdateTimerDisplay"):SetText(string.format("%ss", self.settings.fMainUpdateTimer))
	self.wndConfigAdvancedGeneral:FindChild("Label_AdvancedSettingsOuter:Window_RangeSliderMainUpdate:Slider_MainUpdateTimer"):SetValue(self.settings.fMainUpdateTimer * 10)
	self:UpdateMainUpdateTimer()
end

function BetterRaidFrames:UpdateMainUpdateTimer()
	Apollo.StopTimer("RaidUpdateTimer")
	Apollo.CreateTimer("RaidUpdateTimer", self.settings.fMainUpdateTimer, true)
end

local BetterRaidFramesInst = BetterRaidFrames:new()
BetterRaidFramesInst:Init()

