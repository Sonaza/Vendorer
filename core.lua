------------------------------------------------------------
-- Vendorer by Sonaza (https://sonaza.com)
-- Licensed under MIT License
-- See attached license text in file LICENSE
------------------------------------------------------------

local ADDON_NAME = ...;
local Addon = LibStub("AceAddon-3.0"):NewAddon(select(2, ...), ADDON_NAME, "AceEvent-3.0");
_G["Vendorer"] = Addon;

local AceDB = LibStub("AceDB-3.0");
local _;

-- Get some localized strings
local LOCALIZED_CLOTH         = GetItemSubClassInfo(4, 1);
local LOCALIZED_LEATHER       = GetItemSubClassInfo(4, 2);
local LOCALIZED_MAIL          = GetItemSubClassInfo(4, 3);
local LOCALIZED_PLATE         = GetItemSubClassInfo(4, 4);
local LOCALIZED_ARMOR         = GetItemClassInfo(4);
local LOCALIZED_COSMETIC      = GetItemSubClassInfo(4, 5);
local LOCALIZED_MISCELLANEOUS = GetItemClassInfo(15);
local LOCALIZED_RECIPE        = GetItemClassInfo(9);

VENDORER_IGNORE_ITEMS_BUTTON_TEXT = "Ignore Items";
VENDORER_ADD_JUNK_BUTTON_TEXT = "Add Junk Items";
VENDORER_SETTINGS_BUTTON_TEXT = "|TInterface\\Scenarios\\ScenarioIcon-Interact:14:14:0:0|t Settings";

VENDORER_SELL_JUNK_ITEMS_TEXT = "Sell Junk";
VENDORER_SELL_UNUSABLE_ITEMS_TEXT = "Sell Unusable";
VENDORER_SELL_JUNK_ITEMS_TEXT2 = "Sell / Destroy Junk";
VENDORER_SELL_UNUSABLE_ITEMS_TEXT2 = "Sell / Destroy Unusable";

VENDORER_BIG_DRAG_ITEM_HERE_TEXT = "|cffffd200Drag item here to|nadd it to the list|r";

VENDORER_AUTO_SELL_JUNK_TITLE_TEXT = "Auto sell junk";
VENDORER_AUTO_SELL_JUNK_HINT_TEXT = "|cffffffffToggle automatic selling of junk when visiting vendors. Auto sell will not destroy any items.";

VENDORER_AUTO_REPAIR_TITLE_TEXT = "Auto repair";
VENDORER_AUTO_REPAIR_HINT_TEXT = "|cffffffffRepair all gear automatically if possible.";

VENDORER_USE_SMART_REPAIR_TITLE_TEXT = "Use smart repair";
VENDORER_USE_SMART_REPAIR_HINT_TEXT = "|cffffffffWhen doing automatic repair allow Vendorer to try and spend full guild repair allowance first.|n|n|cff00c6ffNote:|cffffffff this option only applies to auto repair!|n|nProbably not recommended if you have unlimited repair funds.";

VENDORER_CONTRACT_BUTTON_TITLE_TEXT = "Collapse Frame";
VENDORER_EXPAND_BUTTON_TITLE_TEXT = "Expand Frame";

-- New filters are marked with |TInterface\\OptionsFrame\\UI-OptionsFrame-NewFeatureIcon:12:12:0:0:|t
VENDORER_FILTERING_BUTTON_TUTORIAL_TEXT = "You can click here to quickly filter items.|n|nHover to see filtering tips.";

local CLASS_ARMOR_TYPES = {
	WARRIOR     = LOCALIZED_PLATE,
	PALADIN     = LOCALIZED_PLATE,
	DEATHKNIGHT = LOCALIZED_PLATE,
	HUNTER      = LOCALIZED_MAIL,
	SHAMAN      = LOCALIZED_MAIL,
	MONK        = LOCALIZED_LEATHER,
	DRUID       = LOCALIZED_LEATHER,
	ROGUE       = LOCALIZED_LEATHER,
	DEMONHUNTER = LOCALIZED_LEATHER,
	MAGE        = LOCALIZED_CLOTH,
	WARLOCK     = LOCALIZED_CLOTH,
	PRIEST      = LOCALIZED_CLOTH,
	EVOKER      = LOCALIZED_MAIL,
};

local ARMOR_TYPE_LEVEL = {
	[LOCALIZED_CLOTH]   = 1,
	[LOCALIZED_LEATHER] = 2,
	[LOCALIZED_MAIL]    = 3,
	[LOCALIZED_PLATE]   = 4,
};

local ARMOR_SLOTS = {
	["INVTYPE_HEAD"] = true,
	["INVTYPE_SHOULDER"] = true,
	["INVTYPE_CHEST"] = true,
	["INVTYPE_ROBE"] = true,
	["INVTYPE_WAIST"] = true,
	["INVTYPE_LEGS"] = true,
	["INVTYPE_FEET"] = true,
	["INVTYPE_WRIST"] = true,
	["INVTYPE_HAND"] = true,
};

local STAT_SLOTS = {
	["INVTYPE_2HWEAPON"]       = true,
	["INVTYPE_CHEST"]          = true,
	["INVTYPE_CLOAK"]          = true,
	["INVTYPE_FEET"]           = true,
	["INVTYPE_FINGER"]         = true,
	["INVTYPE_HAND"]           = true,
	["INVTYPE_HEAD"]           = true,
	["INVTYPE_HOLDABLE"]       = true,
	["INVTYPE_LEGS"]           = true,
	["INVTYPE_NECK"]           = true,
	["INVTYPE_RANGED"]         = true,
	["INVTYPE_RANGEDRIGHT"]    = true,
	["INVTYPE_RELIC"]          = true,
	["INVTYPE_ROBE"]           = true,
	["INVTYPE_SHIELD"]         = true,
	["INVTYPE_SHOULDER"]       = true,
	["INVTYPE_THROWN"]         = true,
	["INVTYPE_TRINKET"]        = true,
	["INVTYPE_WAIST"]          = true,
	["INVTYPE_WEAPON"]         = true,
	["INVTYPE_WEAPONMAINHAND"] = true,
	["INVTYPE_WEAPONOFFHAND"]  = true,
	["INVTYPE_WRIST"]          = true,
};

local ITEMIGNORE_DELETED        = 0;
local ITEMIGNORE_DEFAULT_IGNORE = 1;
local ITEMIGNORE_USER_IGNORE    = 2;

local DEFAULT_IGNORE_LIST_ITEMS = {
	[33820]  = ITEMIGNORE_DEFAULT_IGNORE, -- Weather-Beaten Fishing Hat
	[2901]   = ITEMIGNORE_DEFAULT_IGNORE, -- Mining Pick
	[44731]  = ITEMIGNORE_DEFAULT_IGNORE, -- Bouquet of Ebon Roses
	[19970]  = ITEMIGNORE_DEFAULT_IGNORE, -- Arcanite Fishing Pole
	[116913] = ITEMIGNORE_DEFAULT_IGNORE, -- Peon's Mining Pick
	[116916] = ITEMIGNORE_DEFAULT_IGNORE, -- Gorepetal's Gentle Grasp
	[84661]  = ITEMIGNORE_DEFAULT_IGNORE, -- Dragon Fishing Pole
	[103678] = ITEMIGNORE_DEFAULT_IGNORE, -- Time-Lost Artifact
	[86566]  = ITEMIGNORE_DEFAULT_IGNORE, -- Forager's Gloves
	[63207]  = ITEMIGNORE_DEFAULT_IGNORE, -- Wrap of Unity
	[63353]  = ITEMIGNORE_DEFAULT_IGNORE, -- Shroud of Cooperation
	[63206]  = ITEMIGNORE_DEFAULT_IGNORE, -- Wrap of Unity
	[65274]  = ITEMIGNORE_DEFAULT_IGNORE, -- Cloak of Coordination
	[129158] = ITEMIGNORE_DEFAULT_IGNORE, -- Starlight Rosedust
};

local PATCHED_IGNORE_LIST_ITEMS = {
	[129158] = true, -- Starlight Rosedust
};
local PATCHED_IGNORE_LIST_REVISION = 1;

StaticPopupDialogs["VENDORER_CONFIRM_SELL_UNUSABLES"] = {
	text = "Are you sure you want to sell unusable items? You can still buy them back after.%s",
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		Addon:ConfirmSellUnusables();
	end,
	OnShow = function()
		if (StaticPopup_Visible("VENDORER_CONFIRM_DESTROY_JUNK")) then
			StaticPopup_Hide("VENDORER_CONFIRM_DESTROY_JUNK");
		end
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
};

StaticPopupDialogs["VENDORER_CONFIRM_DESTROY_JUNK"] = {
	text = "|cffff1111Warning! Confirming this action will also destroy|n%d item%s and the items destroyed cannot be restored.|r|n|nAre you sure you want to continue?",
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		Addon:ConfirmSellJunk();
	end,
	OnShow = function()
		if (StaticPopup_Visible("VENDORER_CONFIRM_SELL_UNUSABLES")) then
			StaticPopup_Hide("VENDORER_CONFIRM_SELL_UNUSABLES");
		end
	end,
	timeout = 0,
	whileDead = 1,
	showAlert = 1,
	hideOnEscape = 1,
};

StaticPopupDialogs["VENDORER_CONFIRM_CLEAR_IGNORE_LIST"] = {
	text = "Are you sure you want wipe the ignore list? This action cannot be undone.",
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		if (not Addon.db.char.UsingPersonalIgnoreList) then
			Addon.db.global.ItemIgnoreList = DEFAULT_IGNORE_LIST_ITEMS;
		else
			Addon.db.char.ItemIgnoreList = DEFAULT_IGNORE_LIST_ITEMS;
		end
		Addon:AddMessage("Ignore list wiped (restored to defaults).");
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
};

StaticPopupDialogs["VENDORER_CONFIRM_CLEAR_JUNKSELL_LIST"] = {
	text = "Are you sure you want wipe the junk sell list? This action cannot be undone.",
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		if (not Addon.db.char.UsingPersonalJunkList) then
			Addon.db.global.ItemJunkList = {};
		else
			Addon.db.char.ItemJunkList = {};
		end
		Addon:AddMessage("Junk list wiped.");
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
};

StaticPopupDialogs["VENDORER_FILTERING_PERFORMANCE_ALERT"] = {
	text = "Vendorer tooltip text filtering may be causing significant framerate drops. While a powerful tool, disabling it may improve the game performance.|n|nDo you wish to disable it?",
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		Addon.db.global.UseTooltipSearch = false;
		Addon:RefreshFilter();
		Addon:AddMessage("Tooltip filtering disabled.");
	end,
	OnCancel = function(self)
		-- Disable alert for rest of the session
		VendorerFramerateWatcher:SetScript("OnUpdate", nil);
	end,
	timeout = 0,
	hideOnEscape = 1,
};

Addon.MerchantWindowOpeningTime = 0;
Addon.UpdatedFilteringTime = 0;
function VendorerFramerateWatcher_OnUpdate(self, elapsed)
	if (not Addon.db.global.UseTooltipSearch) then return end

	-- Merchant window opening may lag a bit so don't display popup for that
	if ((GetTime() - Addon.MerchantWindowOpeningTime) < 2.5) then return end

	self.elapsed = (self.elapsed or 0) + elapsed;
	if (self.elapsed < 0.5) then return end
	self.elapsed = 0;

	local framerate = GetFramerate();
	if (self.averageFPS) then
		local diff = framerate - self.averageFPS;
		self.averageFPS = self.averageFPS * 0.7 + framerate * 0.3;

		if (not MerchantFrame:IsVisible()) then return end

		if ((GetTime() - Addon.UpdatedFilteringTime) < 5.0) then
			if (diff < 0 and math.abs(diff) >= self.averageFPS * 0.3 and framerate <= 11) then
				if (not StaticPopup_Visible("VENDORER_FILTERING_PERFORMANCE_ALERT")) then
					StaticPopup_Show("VENDORER_FILTERING_PERFORMANCE_ALERT");
				end
			end
		end
	else
		self.averageFPS = framerate;
	end
end

function Addon:IsArmorItemSlot(itemslot)
	return ARMOR_SLOTS[itemslot];
end

function Addon:IsStatItemSlot(itemslot)
	return STAT_SLOTS[itemslot];
end

local PLAYER_CLASS_READABLE, PLAYER_CLASS = UnitClass("player");
PLAYER_CLASS_READABLE = string.format("|c%s%s|r", RAID_CLASS_COLORS[PLAYER_CLASS].colorStr, PLAYER_CLASS_READABLE);
local PLAYER_RACE_READABLE = UnitRace("player");

VENDORER_EXTENSION_NONE   = 1;
VENDORER_EXTENSION_NARROW = 2;
VENDORER_EXTENSION_WIDE   = 3;

function Addon:OnInitialize()
	local defaults = {
		char = {
			UsingPersonalIgnoreList = false,
			ItemIgnoreList = nil,

			UsingPersonalJunkList = false,
			ItemJunkList = nil,
		},
		global = {
			MerchantFrameExtension = VENDORER_EXTENSION_NARROW,
			AutoSellJunk = false,
			PaintArmorTypes = true,

			PaintKnownItems = true,
			PaintColor = {
				r = 0.6,
				g = 0.0,
				b = 0.0,
			},

			ShowTooltipInfo = true,

			UseImprovedStackSplit = true,
			UseSafePurchase = false,

			UseTooltipSearch = true,

			AutoRepair = false,
			SmartAutoRepair = true,

			ItemIgnoreList = DEFAULT_IGNORE_LIST_ITEMS,
			ItemJunkList = {},

			DestroyUnsellables = false,

			ShowTransmogAsterisk = true,

			ExpandTutorialShown = false,
			FilteringButtonAlertShown = false,

			VerboseChat = true,

			MerchantAutoSellIgnore = {
				[100995] = true, -- Auto-Hammer
				[153365] = true, -- Honeyback Hivemother
			},
		},
	};

	self.db = AceDB:New("VendorerDB", defaults);

	Addon:ConvertIgnoreLists();
	Addon:PatchIgnoreList();

	if (type(self.db.global.MerchantFrameExtended) == "boolean") then
		if (self.db.global.MerchantFrameExtended) then
			self.db.global.MerchantFrameExtension = VENDORER_EXTENSION_NARROW;
		else
			self.db.global.MerchantFrameExtension = VENDORER_EXTENSION_NONE;
		end
		self.db.global.MerchantFrameExtended = nil;
	end
end

function Addon:OnEnable()
	if (not VendorerItemListsFrame) then
		error("You have updated the addon but only reloaded the interface. Please restart the game.", 1);
	end

	self:RegisterEvent("MERCHANT_SHOW");
	self:RegisterEvent("MERCHANT_CLOSED");
	self:RegisterEvent("MERCHANT_UPDATE");
	self:RegisterEvent("CURSOR_CHANGED");
	self:RegisterEvent("UPDATE_INVENTORY_DURABILITY");
	self:RegisterEvent("TRANSMOG_COLLECTION_UPDATED");

	Addon.PlayerMoney = GetMoney();

	Addon:RestoreSavedSettings();

	hooksecurefunc(C_Container, "PickupContainerItem", function()
		if (not CursorHasItem()) then return end

		Addon:ToggleCursorHighlights(true);
		Addon:RegisterEvent("ITEM_UNLOCKED");
	end);

	Addon:MakeFrameMovable();

	Addon:RegisterTooltip(GameTooltip);
	Addon:RegisterTooltip(ItemRefTooltip);
end

function Addon:RegisterTooltip(tooltip)
	local modified = false;

	tooltip:HookScript('OnTooltipCleared', function(self)
		modified = false;
	end)

	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(self)
		if (modified) then return end
		modified = true;

		if (self and self.GetItem) then
			local name, link = self:GetItem();
			if (link and GetItemInfo(link)) then
				Addon:AddTooltipInfo(self, link);
			end
		end
	end);
end

function Addon:AddTooltipInfo(tooltip, link)
	if (not Addon.db.global.ShowTooltipInfo) then return end

	local itemID = Addon:GetItemID(link);

	local junkList, isJunkListPersonal = Addon:GetCurrentItemJunkList();
	local ignoreList, isIgnoreListPersonal = Addon:GetCurrentItemIgnoreList();

	if (junkList[itemID] and not ignoreList[itemID]) then
		tooltip:AddDoubleLine("|cffe8608fVendorer|r",
			string.format("|cffe8608fMarked as junk (%s list)|r", isJunkListPersonal and "personal" or "global"));
	elseif (junkList[itemID] and ignoreList[itemID]) then
		tooltip:AddDoubleLine("|cffe8608fVendorer|r",
			string.format("|cffe8608fMarked as junk but ignored (%s list)|r", isJunkListPersonal and "personal" or "global"));
	end

	if (not junkList[itemID] and ignoreList[itemID]) then
		tooltip:AddDoubleLine("|cffe8608fVendorer|r",
			string.format("|cffe8608fIgnored (%s list)|r", isIgnoreListPersonal and "personal" or "global"));
	end

	tooltip:Show();
end

function Addon:MakeFrameMovable()
	MerchantFrame:SetMovable(true);
	MerchantFrame:SetScript("OnMouseDown", function(self, button)
		if (button == "LeftButton") then
			self:StartMoving();
		end
	end);
	MerchantFrame:SetScript("OnMouseUp", function(self)
		self:StopMovingOrSizing();
	end);
end

local MESSAGE_PATTERN = "|cffe8608fVendorer|r %s";
function Addon:AddMessage(pattern, ...)
	DEFAULT_CHAT_FRAME:AddMessage(MESSAGE_PATTERN:format(string.format(pattern, ...)), 1, 1, 1);
end

function Addon:AddShortMessage(pattern, ...)
	DEFAULT_CHAT_FRAME:AddMessage(string.format(pattern, ...), 1, 1, 1);
end

function Addon:Announce(str)
	Addon:AddMessage(str);

	-- Parrot is ded, also not even officially supported feature of this addon :D
	-- if(Parrot) then
	-- 	Parrot:ShowMessage(str, "Errors", false);
	-- end
end

function Addon:RestoreSavedSettings()
	Addon:UpdateExtensionToggleButton();
	VendorerAutoSellJunkButton:SetChecked(self.db.global.AutoSellJunk);
	VendorerAutoRepairButton:SetChecked(self.db.global.AutoRepair);
	VendorerAutoSmartRepairButton:SetChecked(self.db.global.SmartAutoRepair);

	if (not self.db.global.DestroyUnsellables) then
		VendorerSellJunkButton:SetText(_G["VENDORER_SELL_JUNK_ITEMS_TEXT"]);
		VendorerSellUnusablesButton:SetText(_G["VENDORER_SELL_UNUSABLE_ITEMS_TEXT"]);
	else
		VendorerSellJunkButton:SetText(_G["VENDORER_SELL_JUNK_ITEMS_TEXT2"]);
		VendorerSellUnusablesButton:SetText(_G["VENDORER_SELL_UNUSABLE_ITEMS_TEXT2"]);
	end
end

function Addon:ToggleCursorHighlights(toggle)
	if (toggle) then
		VendorerIgnoreItemsButtonHighlight:Show();
		VendorerJunkItemsButtonHighlight:Show();
		VendorerItemListsDragReceiver:Show();
	else
		VendorerIgnoreItemsButtonHighlight:Hide();
		VendorerJunkItemsButtonHighlight:Hide();
		VendorerItemListsDragReceiver:Hide();
	end
end

function Addon:ITEM_UNLOCKED()
	if (CursorHasItem()) then return end
	Addon:ToggleCursorHighlights(false);
	Addon:UnregisterEvent("ITEM_UNLOCKED");
end

function Addon:CURSOR_CHANGED()
	if (CursorHasItem()) then return end
	Addon:ToggleCursorHighlights(false);
end

function Addon:MERCHANT_UPDATE()
	if (MerchantFrame.selectedTab == 1) then
		Addon:UpdateMerchantItems();
	end
end

function Addon:EnhanceMerchantFrame()
	local extension = Addon:GetCurrentExtension();

	local offset = 0;
	if (extension ~= VENDORER_EXTENSION_NONE) then
		offset = 164;
	end

	MerchantPageText:SetWidth(164);
	MerchantPageText:ClearAllPoints();
	MerchantPageText:SetPoint("BOTTOM", MerchantFrame, "BOTTOM", -offset / 2 + 3, 90);
	MerchantPageText:SetJustifyH("CENTER");

	MerchantNextPageButton:ClearAllPoints();
	MerchantNextPageButton:SetPoint("RIGHT", MerchantFrame, "BOTTOMRIGHT", -offset - 6, 96);
	MerchantNextPageButton:SetFrameLevel(MerchantFrame:GetFrameLevel() + 2);

	MerchantExtraCurrencyInset:ClearAllPoints();
	MerchantExtraCurrencyInset:SetPoint("BOTTOMRIGHT", MerchantFrame, "BOTTOMRIGHT", -169, 4);
	MerchantExtraCurrencyInset:SetPoint("TOPLEFT", MerchantFrame, "BOTTOMRIGHT", -169 - 163, 27);

	MerchantExtraCurrencyBg:ClearAllPoints();
	MerchantExtraCurrencyBg:SetPoint("BOTTOMRIGHT", MerchantFrame, "BOTTOMRIGHT", -169 - 3, 6);
	MerchantExtraCurrencyBg:SetPoint("TOPLEFT", MerchantFrame, "BOTTOMRIGHT", -169 - 163, 25);
end

function Addon:UpdateExtensionToggleButton()
	if (Addon.db.global.MerchantFrameExtension == VENDORER_EXTENSION_NONE) then
		VendorerToggleExtensionFrameButtonContract:Disable();
	else
		VendorerToggleExtensionFrameButtonContract:Enable();
	end

	if (Addon.db.global.MerchantFrameExtension == VENDORER_EXTENSION_WIDE) then
		VendorerToggleExtensionFrameButtonExpand:Disable();
	else
		VendorerToggleExtensionFrameButtonExpand:Enable();
	end

	Addon:UpdateExtensionPanel();
end

function Addon:UpdateExtensionPanel()
	if (Addon.db.global.MerchantFrameExtension ~= VENDORER_EXTENSION_NONE) then
		Addon:ShowExtensionPanel();
	else
		Addon:HideExtensionPanel();
	end

	Addon:EnhanceMerchantFrame();

	if (VendorerItemListsFrame:IsVisible()) then
		VendorerItemListsFrame_Reanchor();
	end
end

function Addon:GetCurrentExtension()
	local extension = Addon.db.global.MerchantFrameExtension;
	local numItems = Addon:GetUnfilteredMerchantNumItems();

	if (numItems <= 10 and extension == VENDORER_EXTENSION_WIDE) then
		extension = VENDORER_EXTENSION_NARROW;
	end

	return extension;
end

function Addon:SetMerchantItemsPerPage(items)
	MERCHANT_ITEMS_PER_PAGE = items or 10;

	local merchantIsOpen = MerchantFrame:IsVisible();
	if (merchantIsOpen) then
		local maxPages = math.ceil(Addon:GetUnfilteredMerchantNumItems() / MERCHANT_ITEMS_PER_PAGE);
		if (MerchantFrame.page > maxPages) then MerchantFrame.page = maxPages end
		if (MerchantFrame.page < 1) then MerchantFrame.page = 1 end

		if (MerchantFrame.selectedTab == 1) then
			MerchantFrame_UpdateMerchantInfo();
		end
	end
end

function Addon:ShowExtensionPanel()
	local extension = Addon:GetCurrentExtension();

	if (extension == VENDORER_EXTENSION_WIDE) then
		MerchantFrame:SetWidth(834);
		Addon:SetMerchantItemsPerPage(20);

		VendorerExtraMerchantItems:Show();

		VendorerMerchantFrameExtension:Show();
		VendorerMerchantFrameExtensionNarrow:Hide();
		VendorerMerchantFrameExtensionWide:Show();
	elseif (extension == VENDORER_EXTENSION_NARROW) then
		MerchantFrame:SetWidth(500);
		Addon:SetMerchantItemsPerPage(10);

		VendorerExtraMerchantItems:Hide();

		VendorerMerchantFrameExtension:Show();
		VendorerMerchantFrameExtensionNarrow:Show();
		VendorerMerchantFrameExtensionWide:Hide();
	end

	VendorerExtensionFrameItems:Show();
end

function Addon:HideExtensionPanel()
	MerchantFrame:SetWidth(336);
	Addon:SetMerchantItemsPerPage(10);

	VendorerExtraMerchantItems:Hide();

	VendorerMerchantFrameExtension:Hide();

	VendorerExtensionFrameItems:Hide();
end

function VendorerToggleExtensionFrameButton_OnClick(self, button)
	local id = self:GetID();
	if (id == 1) then
		Addon.db.global.MerchantFrameExtension = Addon.db.global.MerchantFrameExtension - 1;
	elseif (id == 2) then
		Addon.db.global.MerchantFrameExtension = Addon.db.global.MerchantFrameExtension + 1;
	end

	if (Addon.db.global.MerchantFrameExtension < 1) then Addon.db.global.MerchantFrameExtension = 1; end
	if (Addon.db.global.MerchantFrameExtension > 3) then Addon.db.global.MerchantFrameExtension = 3; end

	Addon:UpdateExtensionToggleButton();
end

function VendorerToggleExtensionFrameButton_OnEnter(self)
	if (self.tooltipTitle) then
		GameTooltip:ClearAllPoints();
		GameTooltip:SetOwner(VendorerToggleExtensionFrameButtonExpand, "ANCHOR_PRESERVE");
		GameTooltip:SetPoint("LEFT", VendorerToggleExtensionFrameButtonExpand, "RIGHT", 0, 0);

		local titleText = _G[self.tooltipTitle] or self.tooltipTitle;
		GameTooltip:AddLine(titleText, nil, nil, nil, true);

		if (self.tooltipText) then
			local tooltipText = _G[self.tooltipText] or self.tooltipText;
			GameTooltip:AddLine(tooltipText, nil, nil, nil, true);
		end

		GameTooltip:Show();
	end
end

function VendorerCheckButtonTemplate_OnLoad(self)
	local text = _G[self:GetName() .. "Text"];
	if (text) then
		text:SetText(self:GetText());

		if (self == VendorerArmorPaintRedButton) then
			text:SetText("Highlight " .. Addon:GetClassArmorType());
		end

		text:SetFontObject("VendorerCheckButtonFont");
	end
end

function VendorerCheckButtonTemplate_OnEnter(self)
	if (self.tooltipTitle and self.tooltipText) then
		GameTooltip:ClearAllPoints();
		GameTooltip:SetOwner(self, "ANCHOR_PRESERVE");
		GameTooltip:SetPoint("LEFT", self, "RIGHT", 130, 0);

		local titleText = _G[self.tooltipTitle] or self.tooltipTitle;
		local tooltipText = _G[self.tooltipText] or self.tooltipText;

		GameTooltip:AddLine(titleText, nil, nil, nil, true);
		GameTooltip:AddLine(tooltipText, nil, nil, nil, true);

		GameTooltip:Show();
	end
end

function VendorerCheckButtonTemplate_OnClick(self, button)
	local buttonName = self:GetName();
	local func = _G[buttonName .. "_OnClick"];
	if (func and type(func) == "function") then
		func(_G[buttonName], button);
	else
		error(("Missing callback for %s"):format(buttonName), 1);
	end
end

function Addon:ConvertIgnoreList(targetList)
	if (not targetList) then return end

	for itemID, status in pairs(targetList) do
		if (DEFAULT_IGNORE_LIST_ITEMS[itemID]) then
			targetList[itemID] = ITEMIGNORE_DEFAULT_IGNORE;
		else
			targetList[itemID] = ITEMIGNORE_USER_IGNORE;
		end
	end
end

function Addon:ConvertIgnoreLists()
	if (not self.db.char.ItemIgnoreListConverted) then
		self.db.char.ItemIgnoreListConverted = true;
		Addon:ConvertIgnoreList(Addon.db.char.ItemIgnoreList);
	end

	if (not self.db.global.ItemIgnoreListConverted) then
		self.db.global.ItemIgnoreListConverted = true;
		Addon:ConvertIgnoreList(Addon.db.global.ItemIgnoreList);
	end
end

function Addon:PatchIgnoreListItems(targetList)
	if (not targetList) then return end

	for itemID, status in pairs(PATCHED_IGNORE_LIST_ITEMS) do
		if (status == true and not targetList[itemID]) then
			targetList[itemID] = ITEMIGNORE_DEFAULT_IGNORE;
		elseif (status == false and targetList[itemID]) then
			targetList[itemID] = ITEMIGNORE_DEFAULT_DELETED;
		end
	end
end

function Addon:PatchIgnoreList()
	-- Patch character list since it is not updated automagically, only update items once
	if (not self.db.char.ItemIgnoreRevision or self.db.char.ItemIgnoreRevision < PATCHED_IGNORE_LIST_REVISION) then
		self.db.char.ItemIgnoreRevision = PATCHED_IGNORE_LIST_REVISION;
		Addon:PatchIgnoreListItems(Addon.db.char.ItemIgnoreList);
	end
	-- if(not self.db.global.ItemIgnoreRevision or self.db.global.ItemIgnoreRevision < PATCHED_IGNORE_LIST_REVISION) then
	-- 	self.db.global.ItemIgnoreRevision = PATCHED_IGNORE_LIST_REVISION;
	-- 	Addon:PatchIgnoreListItems(Addon.db.global.ItemIgnoreList);
	-- end
end

function Addon:IsItemIgnored(itemID)
	local ignoreList = Addon:GetCurrentItemIgnoreList();
	return ignoreList[itemID] and ignoreList[itemID] > 0;
end

function Addon:IsItemJunked(itemID)
	local junkList = Addon:GetCurrentItemJunkList();
	return junkList[itemID];
end

function Addon:ScanContainers(filter)
	if (not filter) then return {} end

	local foundItems = {};

	for bagIndex = 0, NUM_BAG_SLOTS do
		local numSlots = C_Container.GetContainerNumSlots(bagIndex);
		if (numSlots > 0) then
			for slotIndex = 1, numSlots do
				local link = C_Container.GetContainerItemLink(bagIndex, slotIndex);
				local itemID = link and Addon:GetItemID(link) or 0;
				if (link and not Addon:IsItemIgnored(itemID)) then
					local result, data = filter(bagIndex, slotIndex);
					if (result) then
						tinsert(foundItems, {
							bag = bagIndex,
							slot = slotIndex,
							data = data,
						});
					end
				end
			end
		end
	end

	return foundItems;
end

local function FilterJunkItems(bagIndex, slotIndex)
	if (not bagIndex or not slotIndex) then return false end

	local bagInfo = C_Container.GetContainerItemInfo(bagIndex, slotIndex);
	if (bagInfo.hyperlink) then
		local itemName, _, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount,
		itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(bagInfo.hyperlink);

		if (not itemName) then return false end

		local itemID = Addon:GetItemID(bagInfo.hyperlink);
		local itemIsJunked = Addon:IsItemJunked(itemID);

		local shouldSell = itemSellPrice > 0 and (bagInfo.quality == 0 or itemIsJunked);
		local shouldDestroy = Addon.db.global.DestroyUnsellables and itemSellPrice == 0 and
			(bagInfo.quality == 0 or itemIsJunked);

		local reasonText;
		if (shouldDestroy) then
			if (itemIsJunked) then
				reasonText = "Marked as junk";
			elseif (itemSellPrice == 0) then
				reasonText = "No sell value";
			end

			reasonText = string.format("%s |cffff1111(will be destroyed)|r", reasonText);
		end

		return shouldSell or shouldDestroy, {
			itemLink      = bagInfo.hyperlink,
			itemSellPrice = itemSellPrice * bagInfo.stackCount,
			reasonText    = reasonText,
			shouldDestroy = shouldDestroy,
		};
	end

	return false;
end

local BT_BIND_ON_PICKUP  = 1;
local BT_BIND_ON_EQUIP   = 2;
local BT_BIND_ON_ACCOUNT = 3;
local BT_BIND_ON_USE     = 4;
local BT_QUEST_ITEM      = 5;
local BT_UNKNOWN         = -1;

function Addon:ScanBindType(text)
	if (text) then
		if (text == ITEM_BIND_ON_PICKUP) then return BT_BIND_ON_PICKUP end
		if (text == ITEM_BIND_ON_EQUIP) then return BT_BIND_ON_EQUIP end
		if (text == ITEM_BIND_TO_ACCOUNT) then return BT_BIND_ON_ACCOUNT end
		if (text == ITEM_BIND_TO_BNETACCOUNT) then return BT_BIND_ON_ACCOUNT end
		if (text == ITEM_BIND_ON_USE) then return BT_BIND_ON_USE end
		if (text == ITEM_BIND_QUEST) then return BT_QUEST_ITEM end
	end

	return nil;
end

function Addon:IsRedText(text)
	if (text and text:GetText()) then
		local r, g, b = text:GetTextColor();
		if (r >= 0.98 and g <= 0.16 and b <= 0.16) then return true end
	end

	return false;
end

local NOT_USABLE_CLASS_TYPE = 1;
local NOT_USABLE_TYPE       = 2;
local NOT_USABLE_CLASS      = 3;
local NOT_USABLE_RACE       = 4;

local ITEM_CLASSES_PATTERN = gsub(ITEM_CLASSES_ALLOWED, "%%s", "(.+)")
local ITEM_RACES_PATTERN = gsub(ITEM_RACES_ALLOWED, "%%s", "(.+)")

function Addon:GetClassArmorType()
	return CLASS_ARMOR_TYPES[PLAYER_CLASS];
end

function Addon:IsValidClassArmorType(armortype)
	return Addon:GetClassArmorType() == armortype;
end

local cachedItemInfo = {};
function Addon:GetItemTooltipInfo(item)
	if (not item) then return end

	local _, itemLink, itemRarity, _, _, itemType, itemSubType, _, itemEquipLoc;

	if (Addon:IsCurrencyItem(item)) then
		itemLink = item;
	else
		_, itemLink, itemRarity, _, _, itemType, itemSubType, _, itemEquipLoc = GetItemInfo(item);
	end
	if (not itemLink) then return end

	if (cachedItemInfo[itemLink]) then
		return unpack(cachedItemInfo[itemLink]);
	end

	local bindType, isUsable, isClassArmorType, notUsableReason;
	local isUnique = false;

	if (IsEquippableItem(itemLink) and Addon:IsArmorItemSlot(itemEquipLoc)) then
		if (
			itemSubType == LOCALIZED_COSMETIC or itemSubType == LOCALIZED_MISCELLANEOUS or
				Addon:IsValidClassArmorType(itemSubType)) then
			isClassArmorType = true;
		else
			isClassArmorType = false;
		end
	end

	isUsable = true;

	local tooltipItemSlot, tooltipItemType;
	tooltipItemSlot = itemEquipLoc ~= "" and _G[itemEquipLoc] or nil;

	if (isClassArmorType == false) then
		notUsableReason = NOT_USABLE_CLASS_TYPE;
		isUsable = false;
	end

	VendorerTooltip:SetOwner(UIParent, "ANCHOR_NONE");
	if (Addon:IsCurrencyItem(itemLink)) then
		local currencyID = Addon:GetCurrencyInfo(itemLink);
		VendorerTooltip:SetCurrencyByID(currencyID);
	else
		VendorerTooltip:SetHyperlink(itemLink);
	end
	local numLines = VendorerTooltip:NumLines();

	for line = 2, numLines do
		local wasUsable = isUsable;

		local left = _G["VendorerTooltipTextLeft" .. line];
		local right = _G["VendorerTooltipTextRight" .. line];

		if (not bindType) then
			bindType = Addon:ScanBindType(left:GetText());
		end

		if (IsEquippableItem(itemLink)) then
			if (left:GetText() == itemType and Addon:IsRedText(left)) then
				if (isUsable and not notUsableReason) then notUsableReason = NOT_USABLE_TYPE end
				isUsable = false;
			end

			if (right and (right:GetText() == itemSubType or line <= 6)) then
				if (Addon:IsRedText(right)) then
					if (isUsable and not notUsableReason) then notUsableReason = NOT_USABLE_TYPE end
					isUsable = false;
				end

				if (not tooltipItemType) then
					tooltipItemType = right:GetText();
				end
			end

			local equipSlotName = itemEquipLoc ~= "" and _G[itemEquipLoc] or "";
			if (left:GetText() == equipSlotName and Addon:IsRedText(left)) then
				if (isUsable and not notUsableReason) then notUsableReason = NOT_USABLE_TYPE end
				isUsable = false;
			end
		end

		if (strmatch(left:GetText(), ITEM_CLASSES_PATTERN)) then
			isUsable = isUsable and not Addon:IsRedText(left);
			if (wasUsable and not isUsable) then notUsableReason = NOT_USABLE_CLASS end
		end

		if (strmatch(left:GetText(), ITEM_RACES_PATTERN)) then
			isUsable = isUsable and not Addon:IsRedText(left);
			if (wasUsable and not isUsable) then notUsableReason = NOT_USABLE_RACE end
		end

		if (left:GetText() == ITEM_UNIQUE) then
			isUnique = true;
		end
	end

	if (not tooltipItemType and IsEquippableItem(itemLink)) then
		tooltipItemType = itemSubType;
	end

	if (not bindType) then bindType = BT_UNKNOWN end
	if (isUsable == nil) then isUsable = true; end

	cachedItemInfo[itemLink] = { bindType, isUsable, isClassArmorType, notUsableReason, tooltipItemSlot, tooltipItemType,
		itemSubType, isUnique };
	return bindType, isUsable, isClassArmorType, notUsableReason, tooltipItemSlot, tooltipItemType, itemSubType, isUnique;
end

local function FilterUnusableItems(bagIndex, slotIndex)
	if (not bagIndex or not slotIndex) then return false end

	local bagInfo = C_Container.GetContainerItemInfo(bagIndex, slotIndex);
	if (bagInfo.hyperlink) then
		local itemName, _, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount,
		itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(bagInfo.hyperlink);
		local itemID = Addon:GetItemID(bagInfo.hyperlink);

		if (not itemName) then return false end
		if (itemType == LOCALIZED_RECIPE) then return false end
		if (itemRarity > 4 or (itemSellPrice == 0 and not Addon.db.global.DestroyUnsellables)) then return false end

		local bindType, isUsable, isClassArmorType, notUsableReason, tooltipItemSlot, tooltipItemType, itemSubType = Addon:
			GetItemTooltipInfo(bagInfo.hyperlink);

		local shouldDestroy = Addon.db.global.DestroyUnsellables and itemSellPrice == 0 and not isUsable;

		-- If it's not soulbound then call quits here
		if (bindType ~= BT_BIND_ON_PICKUP) then return false end

		local reasonText = "";
		if (notUsableReason == NOT_USABLE_TYPE) then
			reasonText = string.format("%s (%s)", tooltipItemSlot, tooltipItemType);

		elseif (notUsableReason == NOT_USABLE_CLASS) then
			reasonText = string.format("Unusable by %s", PLAYER_CLASS_READABLE);

		elseif (notUsableReason == NOT_USABLE_RACE) then
			reasonText = string.format("Unusable by %s", PLAYER_RACE_READABLE);

		elseif (notUsableReason == NOT_USABLE_CLASS_TYPE) then
			local classArmorType = Addon:GetClassArmorType();
			reasonText = string.format("%s (%s)  %s uses %s Armor", tooltipItemSlot, tooltipItemType, PLAYER_CLASS_READABLE,
				classArmorType);

		elseif (itemSellPrice == 0) then
			reasonText = "No sell value";
		end

		if (shouldDestroy) then
			reasonText = string.format("%s |cffff1111(will be destroyed)|r", reasonText);
		end

		if (isClassArmorType == nil) then isClassArmorType = true end

		return not isUsable or not isClassArmorType or shouldDestroy, {
			itemLink      = bagInfo.hyperlink,
			itemSellPrice = itemSellPrice * bagInfo.stackCount,
			reasonText    = strtrim(reasonText),
			shouldDestroy = shouldDestroy,
		};
	end

	return false;
end

function Addon:GetItemID(itemLink)
	if (not itemLink) then return end

	local itemID = strmatch(itemLink, "item:(%d+)");
	return itemID and tonumber(itemID) or nil;
end

function Addon:AddCursorItemToIgnoreList()
	local cursor, _, itemLink = GetCursorInfo();
	if (cursor == "item" and itemLink) then
		Addon:AddItemToIgnoreList(itemLink);
		ClearCursor();
	end

	if (not VendorerItemListsFrame:IsVisible()) then
		VendorerIgnoreItemsButton_OnEnter(VendorerIgnoreItemsButton);
	end
end

function Addon:GetCurrentItemIgnoreList()
	local list = Addon.db.global.ItemIgnoreList;
	if (Addon.db.char.UsingPersonalIgnoreList) then
		list = Addon.db.char.ItemIgnoreList;
	end

	return list, Addon.db.char.UsingPersonalIgnoreList;
end

function Addon:DeleteItemFromIgnoreList(ignoreList, itemID)
	if (DEFAULT_IGNORE_LIST_ITEMS[itemID]) then
		ignoreList[itemID] = ITEMIGNORE_DELETED;
	else
		ignoreList[itemID] = nil;
	end
end

function Addon:AddItemToIgnoreList(itemLink)
	if (not itemLink) then return end
	local itemID = Addon:GetItemID(itemLink);

	local junkList, isJunkListPersonal = Addon:GetCurrentItemJunkList();
	local ignoreList, isIgnoreListPersonal = Addon:GetCurrentItemIgnoreList();

	if (isJunkListPersonal == isIgnoreListPersonal and junkList[itemID]) then
		junkList[itemID] = nil;
		Addon:AddMessage("%s removed from junk sell list.", itemLink, isJunkListPersonal and "personal" or "global");
	end

	if (not Addon:IsItemIgnored(itemID)) then
		ignoreList[itemID] = ITEMIGNORE_USER_IGNORE;
		Addon:AddMessage("%s added to %s ignore list.", itemLink, isIgnoreListPersonal and "personal" or "global");
	else
		Addon:DeleteItemFromIgnoreList(ignoreList, itemID);
		Addon:AddMessage("%s removed from %s ignore list.", itemLink, isIgnoreListPersonal and "personal" or "global");
	end

	if (
		not isJunkListPersonal and isJunkListPersonal ~= isIgnoreListPersonal and junkList[itemID] and
			Addon:IsItemIgnored(itemID)) then
		Addon:AddMessage("The item remains on the global junk list but will not be sold.");
	end

	Addon:UpdateVendorerItemLists();
end

function Addon:AddCursorItemToJunkList()
	local cursor, _, itemLink = GetCursorInfo();
	if (cursor == "item" and itemLink) then
		Addon:AddItemToJunkList(itemLink);
		ClearCursor();
	end

	if (not VendorerItemListsFrame:IsVisible()) then
		VendorerJunkItemsButton_OnEnter(VendorerJunkItemsButton);
	end
end

function Addon:GetCurrentItemJunkList()
	local list = Addon.db.global.ItemJunkList;
	if (Addon.db.char.UsingPersonalJunkList) then
		list = Addon.db.char.ItemJunkList;
	end

	return list, Addon.db.char.UsingPersonalJunkList;
end

function Addon:AddItemToJunkList(itemLink)
	if (not itemLink) then return end
	local itemID = Addon:GetItemID(itemLink);

	local junkList, isJunkListPersonal = Addon:GetCurrentItemJunkList();
	local ignoreList, isIgnoreListPersonal = Addon:GetCurrentItemIgnoreList();

	if (isJunkListPersonal == isIgnoreListPersonal and Addon:IsItemIgnored(itemID)) then
		Addon:DeleteItemFromIgnoreList(ignoreList, itemID);
		Addon:AddMessage("%s removed from %s ignore list.", itemLink, isIgnoreListPersonal and "personal" or "global");
	end

	if (not junkList[itemID]) then
		junkList[itemID] = true;
		Addon:AddMessage("%s added to %s junk sell list.", itemLink, isJunkListPersonal and "personal" or "global");
	else
		junkList[itemID] = nil;
		Addon:AddMessage("%s removed from %s junk sell list.", itemLink, isJunkListPersonal and "personal" or "global");
	end

	if (isJunkListPersonal ~= isIgnoreListPersonal and Addon:IsItemIgnored(itemID) and junkList[itemID]) then
		Addon:AddMessage("The item remains on the %s ignore list and will not be sold.",
			isIgnoreListPersonal and "personal" or "global");
	end

	Addon:UpdateVendorerItemLists();
end

function VendorerIgnoreItemsButton_OnEnter(self)
	GameTooltip:ClearAllPoints();
	GameTooltip:SetOwner(self, "ANCHOR_PRESERVE");
	GameTooltip:SetPoint("TOPLEFT", self, "RIGHT", 0, 70);

	GameTooltip:AddLine("Ignoring Items from Auto Sell");
	GameTooltip:AddLine("|cffffffffYou can drag items here from inventory|nto add or remove them from the ignore list.");
	GameTooltip:AddLine(" ");
	GameTooltip:AddLine("|cffffffffIgnored items will not be automatically sold.");

	GameTooltip:AddLine(" ");
	if (not Addon.db.char.UsingPersonalIgnoreList) then
		GameTooltip:AddLine("|cffffd200Using global ignore list.|r");
	else
		GameTooltip:AddLine("|cffffd200Using personal ignore list.|r");
	end

	GameTooltip:AddLine(" ");
	GameTooltip:AddLine("|cff00ff00Left-click  |cffffffffView items on the list");

	local ignoreList, isIgnoreListPersonal = Addon:GetCurrentItemIgnoreList();
	local numIgnoredItems = 0;
	for itemID, _ in pairs(ignoreList) do
		numIgnoredItems = numIgnoredItems + 1;
	end

	if (numIgnoredItems > 0) then
		GameTooltip:AddLine("|cff00ff00Shift Right-click  |cffffffffWipe the ignore list");
		GameTooltip:AddLine(" ");
		GameTooltip:AddLine(string.format("%d Ignored Items", numIgnoredItems));
	end

	self.text:SetFontObject("VendorerButtonFontHighlight");

	GameTooltip:Show();

	if (IsMouseButtonDown("LeftButton")) then
		self:SetScript("OnUpdate", function(self)
			if (not IsMouseButtonDown("LeftButton")) then
				Addon:AddCursorItemToIgnoreList();
				self:SetScript("OnUpdate", nil);
			end
		end);
	end
end

function VendorerIgnoreItemsButton_OnLeave(self)
	self.text:SetFontObject("VendorerButtonFont");
	GameTooltip:Hide();
	self:SetScript("OnUpdate", nil);
end

function Addon:OpenIgnoredItemsListsFrame()
	GameTooltip:Hide();
	VendorerItemListsFrameDescription:SetText("These items will not be sold.");

	local usedListDescription;
	if (not self.db.char.UsingPersonalIgnoreList) then
		usedListDescription = "|cff00ff00Using global ignore list|r";
	else
		usedListDescription = "|cff00ff00Using personal ignore list|r";
	end
	VendorerItemListsFrameListDescription:SetText(usedListDescription);

	VendorerItemListsFrame.addItemFunction = Addon.AddCursorItemToIgnoreList;

	local ignoreList = Addon:GetCurrentItemIgnoreList();
	Addon:OpenVendorerItemListsFrame(1, "Vendorer Ignored Items", ignoreList);
end

function VendorerIgnoreItemsButton_OnClick(self, button)
	if (button == "LeftButton") then
		if (not GetCursorInfo()) then
			Addon:OpenIgnoredItemsListsFrame();
		else
			Addon:AddCursorItemToIgnoreList();
		end
	elseif (button == "RightButton" and IsShiftKeyDown()) then
		if (not GetCursorInfo()) then
			for link, _ in pairs(Addon:GetCurrentItemIgnoreList()) do
				StaticPopup_Show("VENDORER_CONFIRM_CLEAR_IGNORE_LIST");
				return;
			end
		else
			ClearCursor();
		end
	end
end

function Addon:OpenJunkItemsListsFrame()
	GameTooltip:Hide();
	VendorerItemListsFrameDescription:SetText("These items are always sold.");

	local usedListDescription;
	if (not self.db.char.UsingPersonalJunkList) then
		usedListDescription = "|cff00ff00Using global junk list|r";
	else
		usedListDescription = "|cff00ff00Using personal junk list|r";
	end
	VendorerItemListsFrameListDescription:SetText(usedListDescription);

	VendorerItemListsFrame.addItemFunction = Addon.AddCursorItemToJunkList;

	local junkList = Addon:GetCurrentItemJunkList();
	Addon:OpenVendorerItemListsFrame(2, "Vendorer Junk Items", junkList);
end

function VendorerJunkItemsButton_OnClick(self, button)
	if (button == "LeftButton") then
		if (not GetCursorInfo()) then
			Addon:OpenJunkItemsListsFrame();
		else
			Addon:AddCursorItemToJunkList();
		end
	elseif (button == "RightButton" and IsShiftKeyDown()) then
		if (not GetCursorInfo()) then
			for link, _ in pairs(Addon:GetCurrentItemJunkList()) do
				StaticPopup_Show("VENDORER_CONFIRM_CLEAR_JUNKSELL_LIST");
				return;
			end
		else
			ClearCursor();
		end
	end
end

function VendorerJunkItemsButton_OnEnter(self)
	GameTooltip:ClearAllPoints();
	GameTooltip:SetOwner(self, "ANCHOR_PRESERVE");
	GameTooltip:SetPoint("TOPLEFT", self, "RIGHT", 0, 70);

	GameTooltip:AddLine("Add Junk Items to Junk List");
	GameTooltip:AddLine("|cffffffffYou can drag items you don't want here from your inventory|nto add or remove them from the junk sell list.");
	GameTooltip:AddLine(" ");
	GameTooltip:AddLine("|cffffffffItems marked as junk will be sold.");

	GameTooltip:AddLine(" ");
	if (not Addon.db.char.UsingPersonalJunkList) then
		GameTooltip:AddLine("|cffffd200Using global junk list.|r");
	else
		GameTooltip:AddLine("|cffffd200Using personal junk list.|r");
	end

	GameTooltip:AddLine(" ");
	GameTooltip:AddLine("|cff00ff00Left-click  |cffffffffView items on the list");

	local junkList = Addon:GetCurrentItemJunkList();
	local numJunkItems = 0;
	for itemID, _ in pairs(junkList) do
		numJunkItems = numJunkItems + 1;
	end

	if (numJunkItems > 0) then
		GameTooltip:AddLine("|cff00ff00Shift Right-click |cffffffffWipe the junk list");
		GameTooltip:AddLine(" ");
		GameTooltip:AddLine(string.format("%d Junk Items", numJunkItems));
	end

	self.text:SetFontObject("VendorerButtonFontHighlight");

	GameTooltip:Show();

	if (IsMouseButtonDown("LeftButton")) then
		self:SetScript("OnUpdate", function(self)
			if (not IsMouseButtonDown("LeftButton")) then
				Addon:AddCursorItemToJunkList();
				self:SetScript("OnUpdate", nil);
			end
		end);
	end
end

function VendorerJunkItemsButton_OnLeave(self)
	self.text:SetFontObject("VendorerButtonFont");
	GameTooltip:Hide();
	self:SetScript("OnUpdate", nil);
end

----------------------------------------------------------------------

local MerchantErrorAccumulator = {};

function Addon:UI_ERROR_MESSAGE(event, messageType, message)
	if (message == ERR_VENDOR_DOESNT_BUY) then
		Addon.MerchantSellError = true;

		if (Addon.MerchantNpcId ~= nil) then
			-- First check if merchant is already ignored
			if (Addon.db.global.MerchantAutoSellIgnore[Addon.MerchantNpcId] == nil) then
				--local numMerchantErrors = (MerchantErrorAccumulator[Addon.MerchantNpcId] or 0) + 1;
				--MerchantErrorAccumulator[Addon.MerchantNpcId] = numMerchantErrors;

				--if (numMerchantErrors >= 2) then
				Addon:AddMessage("This merchant doesn't seem to buy items. Added to auto sell ignore list.");
				Addon:AddMessage("You can remove the ignore by holding CTRL and clicking the Sell Junk button if it wasn't intended.");
				Addon.db.global.MerchantAutoSellIgnore[Addon.MerchantNpcId] = true;
				--end
			end
		end
	end
end

function Addon:TryHookUIErrors()
	if (not Addon.HookedUIErrors) then
		Addon:RegisterEvent("UI_ERROR_MESSAGE");
		Addon.HookedUIErrors = true;
	end
end

function Addon:GetNpcIdFromGUID(guid)
	if (guid == nil or type(guid) ~= "string") then
		return nil;
	end

	--Creature-0-3102-0-155-100995-00000D1C2E
	local _, _, _, _, _, npcId = strsplit("-", guid);
	return tonumber(npcId);
end

function Addon:ConfirmSellJunk(skip_limit, dont_destroy)
	Addon:TryHookUIErrors();

	local maxSell = 12;
	local items = Addon:ScanContainers(FilterJunkItems);
	if (#items == 0) then return end

	local itemsToSell = {};

	local itemsDestroyed = 0;
	for index, slotInfo in ipairs(items) do
		if (slotInfo.data.shouldDestroy and not dont_destroy) then
			local bagInfo = C_Container.GetContainerItemInfo(slotInfo.bag, slotInfo.slot);
			local itemMessage = string.format("Destroying %s", bagInfo.hyperlink);
			if (itemCount > 1) then
				itemMessage = string.format("%s x%d", itemMessage, bagInfo.stackCount);
			end

			if (Addon.db.global.VerboseChat) then
				Addon:AddMessage(itemMessage);
			end

			ClearCursor();
			C_Container.PickupContainerItem(slotInfo.bag, slotInfo.slot);
			DeleteCursorItem();

			itemsDestroyed = itemsDestroyed + 1;
		elseif (not slotInfo.data.shouldDestroy) then
			tinsert(itemsToSell, slotInfo);
		end
	end

	if (itemsDestroyed > 0 and Addon.db.global.VerboseChat) then
		Addon:AddMessage("All unsellable junk items destroyed!");
	end

	local skipped = false;

	Addon.MerchantNpcId = Addon:GetNpcIdFromGUID(UnitGUID("NPC"));
	Addon.MerchantSellError = false;

	--if (Addon.MerchantNpcId ~= nil) then
	--	if (Addon.db.global.MerchantAutoSellIgnore[Addon.MerchantNpcId] ~= nil) then
	--		Addon:AddMessage("This merchant doesn't buy items.");
	--		return;
	--	end
	--end

	local itemsSold = 0;
	for index, slotInfo in ipairs(itemsToSell) do
		local bagInfo = C_Container.GetContainerItemInfo(slotInfo.bag, slotInfo.slot);

		local itemMessage = string.format("Selling %s", bagInfo.hyperlink);
		if (bagInfo.stackCount > 1) then
			itemMessage = string.format("%s x%d", itemMessage, bagInfo.stackCount);
		end

		if (Addon.db.global.VerboseChat) then
			Addon:AddMessage(itemMessage);
		end

		C_Container.UseContainerItem(slotInfo.bag, slotInfo.slot);

		if (Addon.MerchantSellError) then
			Addon:AddMessage("This merchant doesn't buy items.");
			break;
		end

		itemsSold = itemsSold + 1;

		if (not skip_limit and index == maxSell and index ~= #items) then
			Addon:AddMessage("Sold %d items (%d more to sell)", index, #items - index);
			skipped = true;
			break;
		end
	end

	if (Addon.MerchantSellError) then
		Addon:AddMessage("The sell operation was aborted.");
		return;
	end

	if ((skip_limit or not skipped) and itemsSold > 0 and Addon.db.global.VerboseChat) then
		Addon:AddMessage("All junk items sold!");
	end

	C_Timer.After(4, function()
		Addon.MerchantSellError = false;
		Addon.MerchantNpcId = nil;
	end);
end

function Addon:ConfirmSellUnusables()
	Addon:TryHookUIErrors();

	local maxSell = 12;
	local items = Addon:ScanContainers(FilterUnusableItems);
	if (#items == 0) then return end

	local itemsToSell = {};

	local itemsDestroyed = 0;
	for index, slotInfo in ipairs(items) do
		if (slotInfo.data.shouldDestroy) then
			local bagInfo = C_Container.GetContainerItemInfo(slotInfo.bag, slotInfo.slot);
			local itemMessage = string.format("Destroying %s", bagInfo.hyperlink);
			if (bagInfo.stackCount > 1) then
				itemMessage = string.format("%s x%d", itemMessage, bagInfo.stackCount);
			end

			if (Addon.db.global.VerboseChat) then
				Addon:AddMessage(itemMessage);
			end

			ClearCursor();
			C_Container.PickupContainerItem(slotInfo.bag, slotInfo.slot);
			DeleteCursorItem();

			itemsDestroyed = itemsDestroyed + 1;
		else
			tinsert(itemsToSell, slotInfo);
		end
	end

	if (itemsDestroyed > 0 and Addon.db.global.VerboseChat) then
		Addon:AddMessage("All unsellable unusable items destroyed!");
	end

	local skipped = false;

	Addon.MerchantNpcId = Addon:GetNpcIdFromGUID(UnitGUID("NPC"));
	Addon.MerchantSellError = false;

	--if (Addon.MerchantNpcId ~= nil) then
	--	if (Addon.db.global.MerchantAutoSellIgnore[Addon.MerchantNpcId] ~= nil) then
	--		Addon:AddMessage("This merchant doesn't buy items.");
	--		return;
	--	end
	--end

	local itemsSold = 0;
	for index, slotInfo in ipairs(itemsToSell) do
		local bagInfo = C_Container.GetContainerItemInfo(slotInfo.bag, slotInfo.slot);
		local itemMessage = string.format("Selling %s", bagInfo.hyperlink);
		if (bagInfo.stackCount > 1) then
			itemMessage = string.format("%s x%d", itemMessage, bagInfo.stackCount);
		end

		if (Addon.db.global.VerboseChat) then
			Addon:AddMessage(itemMessage);
		end

		C_Container.UseContainerItem(slotInfo.bag, slotInfo.slot);

		if (Addon.MerchantSellError) then
			Addon:AddMessage("This merchant doesn't buy items.");
			break;
		end

		itemsSold = itemsSold + 1;

		if (index == maxSell and index ~= #items) then
			Addon:AddMessage("Sold %d items (%d more to sell)", index, #items - index);
			skipped = true;
			break;
		end
	end

	if (Addon.MerchantSellError) then
		Addon:AddMessage("The sell operation was aborted.");
		return;
	end

	if (not skipped and itemsSold > 0 and Addon.db.global.VerboseChat) then
		Addon:AddMessage("All unusable items sold!");
	end

	C_Timer.After(4, function()
		Addon.MerchantSellError = false;
		Addon.MerchantNpcId = nil;
	end);
end

function Addon:BAG_UPDATE_DELAYED()
	if (not Addon.UpdateTooltip) then
		Addon:UnregisterEvent("BAG_UPDATE_DELAYED");
		return
	end

	if (Addon.UpdateTooltip == 1) then
		VendorerSellJunkButton_OnEnter(VendorerSellJunkButton)
	elseif (Addon.UpdateTooltip == 2) then
		VendorerSellUnusablesButton_OnEnter(VendorerSellUnusablesButton)
	end
end

function VendorerSellButton_OnLeave(self)
	Addon.UpdateTooltip = nil;
	Addon:UnregisterEvent("BAG_UPDATE_DELAYED");
	GameTooltip:Hide();
end

function VendorerSellJunkButton_OnEnter(self)
	local items = Addon:ScanContainers(FilterJunkItems);
	local sellPrice = 0;
	local numItemsToDestroy = 0;
	for _, slotInfo in ipairs(items) do
		sellPrice = sellPrice + slotInfo.data.itemSellPrice;
		if (slotInfo.data.shouldDestroy) then
			numItemsToDestroy = numItemsToDestroy + 1;
		end
	end

	GameTooltip:ClearAllPoints();
	GameTooltip:SetOwner(self, "ANCHOR_PRESERVE");
	GameTooltip:SetPoint("BOTTOMLEFT", self, "RIGHT", 0, -15);

	GameTooltip:AddLine("Sell Junk");
	GameTooltip:AddLine("|cffffffffSell all poor quality items or items marked as junk.");
	GameTooltip:AddLine(" ");
	if (Addon.db.global.DestroyUnsellables) then
		if (numItemsToDestroy > 0) then
			GameTooltip:AddLine(string.format("|cffff1111%d unsellable junk item%s will be destroyed.|r", numItemsToDestroy,
				numItemsToDestroy == 1 and "" or "s"));
		else
			GameTooltip:AddLine("|cffffa800No unsellable junk item to destroy.|r");
		end
		GameTooltip:AddLine(" ");
	end
	GameTooltip:AddDoubleLine("Estimated Income",
		string.format("|cffffffff%d items  %s  ", #items, GetCoinTextureString(sellPrice)));

	if (#items > 0) then
		local hasTitle = false;
		for index, slotInfo in ipairs(items) do
			if (slotInfo.data.shouldDestroy) then
				if (not hasTitle) then
					GameTooltip:AddLine(" ");
					GameTooltip:AddDoubleLine("Items", "Reason");
					hasTitle = true;
				end

				local itemName, _, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount,
				itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(slotInfo.data.itemLink);

				GameTooltip:AddDoubleLine(slotInfo.data.itemLink, string.format("%s", slotInfo.data.reasonText or "--"), 1, 1, 1, 1,
					1, 1);
			end
		end
	end

	local npcId = Addon:GetNpcIdFromGUID(UnitGUID("NPC"));
	if (Addon.db.global.MerchantAutoSellIgnore[npcId] ~= nil) then
		GameTooltip:AddLine(" ");
		GameTooltip:AddLine("|cffff5656This merchant is currently being ignored for auto sell.|r You can remove the ignore by holding CTRL and clicking this button if it wasn't intended."
			, 1, 1, 1, true);
	end

	GameTooltip:Show();

	Addon.UpdateTooltip = 1;
	Addon:RegisterEvent("BAG_UPDATE_DELAYED");
end

function VendorerSellJunkButton_OnClick(self, button)
	if (IsControlKeyDown()) then
		local npcId = Addon:GetNpcIdFromGUID(UnitGUID("NPC"));
		if (Addon.db.global.MerchantAutoSellIgnore[npcId] ~= nil) then
			Addon:AddMessage("This merchant has been removed from auto sell ignore list.");
			Addon.db.global.MerchantAutoSellIgnore[npcId] = nil;

			VendorerSellButton_OnLeave(self);
			VendorerSellJunkButton_OnEnter(self);
		end
	end

	if (not Addon.db.global.DestroyUnsellables) then
		Addon:ConfirmSellJunk();
		return;
	end

	local items = Addon:ScanContainers(FilterJunkItems);
	if (#items == 0) then return end

	local itemsToDestroy = 0;

	if (Addon.db.global.DestroyUnsellables) then
		for index, slotinfo in ipairs(items) do
			if (slotinfo.data.shouldDestroy) then
				itemsToDestroy = itemsToDestroy + 1;
			end
		end
	end

	if (itemsToDestroy > 0) then
		StaticPopup_Show("VENDORER_CONFIRM_DESTROY_JUNK", itemsToDestroy, itemsToDestroy == 1 and "" or "s");
	else
		Addon:ConfirmSellJunk();
	end
end

function VendorerSellUnusablesButton_OnEnter(self, button)
	local items = Addon:ScanContainers(FilterUnusableItems);
	local sellPrice = 0;
	local numItemsToDestroy = 0;
	for _, slotInfo in ipairs(items) do
		sellPrice = sellPrice + slotInfo.data.itemSellPrice;
		if (slotInfo.data.shouldDestroy) then
			numItemsToDestroy = numItemsToDestroy + 1;
		end
	end

	GameTooltip:ClearAllPoints();
	GameTooltip:SetOwner(self, "ANCHOR_PRESERVE");
	GameTooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 0, 70);

	GameTooltip:AddLine("Sell Unusables");
	GameTooltip:AddLine("|cffffffffSell all soulbound equipment and tokens that you cannot use.");
	GameTooltip:AddLine(" ");
	if (Addon.db.global.DestroyUnsellables) then
		if (numItemsToDestroy > 0) then
			GameTooltip:AddLine(string.format("|cffff1111%d unsellable unusable item%s will be destroyed.|r", numItemsToDestroy,
				numItemsToDestroy == 1 and "" or "s"));
		else
			GameTooltip:AddLine("|cffffa800No unsellable unusable items to destroy.|r");
		end
		GameTooltip:AddLine(" ");
	end
	GameTooltip:AddDoubleLine("Estimated Income",
		string.format("|cffffffff%d items  %s  ", #items, GetCoinTextureString(sellPrice)));

	if (#items > 0) then
		GameTooltip:AddLine(" ");
		GameTooltip:AddDoubleLine("Items", "Reason");

		local itemsToSell = {};

		for index, slotInfo in ipairs(items) do
			if (slotInfo.data.shouldDestroy) then
				local itemName, _, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount,
				itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(slotInfo.data.itemLink);

				GameTooltip:AddDoubleLine(slotInfo.data.itemLink, string.format("%s", slotInfo.data.reasonText or "--"), 1, 1, 1, 1,
					1, 1);
			else
				tinsert(itemsToSell, slotInfo);
			end
		end

		for index, slotInfo in ipairs(itemsToSell) do
			local itemName, _, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount,
			itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(slotInfo.data.itemLink);

			GameTooltip:AddDoubleLine(slotInfo.data.itemLink, string.format("%s", slotInfo.data.reasonText or "--"), 1, 1, 1, 1, 1
				, 1);

			if (index == 12 and #itemsToSell > 12) then
				GameTooltip:AddLine(" ");
				GameTooltip:AddLine("Items after this sold on next click");
			end
		end
	end

	GameTooltip:Show();

	Addon.UpdateTooltip = 2;
	Addon:RegisterEvent("BAG_UPDATE_DELAYED");
end

function VendorerSellUnusablesButton_OnClick(self, button)
	local items = Addon:ScanContainers(FilterUnusableItems);
	if (#items == 0) then return end

	local itemsToDestroy = 0;

	if (Addon.db.global.DestroyUnsellables) then
		for index, slotinfo in ipairs(items) do
			if (slotinfo.data.shouldDestroy) then
				itemsToDestroy = itemsToDestroy + 1;
			end
		end
	end

	local destroyWarning = "";
	if (itemsToDestroy > 0) then
		destroyWarning = string.format("|n|n|cffff1111Warning! Confirming this action will also destroy %d item%s and the items destroyed cannot be restored."
			, itemsToDestroy, itemsToDestroy == 1 and "" or "s");
	end

	StaticPopupDialogs["VENDORER_CONFIRM_SELL_UNUSABLES"].showAlert = (itemsToDestroy > 0 and 1 or 0);

	StaticPopup_Show("VENDORER_CONFIRM_SELL_UNUSABLES", destroyWarning);
end

function VendorerAutoSellJunkButton_OnClick(self)
	Addon.db.global.AutoSellJunk = self:GetChecked();
end

function VendorerAutoRepairButton_OnClick(self)
	Addon.db.global.AutoRepair = self:GetChecked();
end

function VendorerAutoSmartRepairButton_OnClick(self)
	Addon.db.global.SmartAutoRepair = self:GetChecked();
end

function Addon:MERCHANT_SHOW()
	Addon.MerchantSellError = false;
	Addon.MerchantNpcId = nil;

	Addon:ResetFilteredItems();
	Addon:ResetFilter();
	Addon.PlayerMoney = GetMoney();

	if (self.db.global.AutoSellJunk) then
		local npcId = Addon:GetNpcIdFromGUID(UnitGUID("NPC"));
		if (self.db.global.MerchantAutoSellIgnore[npcId] == nil) then
			Addon:ConfirmSellJunk(true, true);
		else
			Addon:AddMessage("This merchant doesn't buy items, cannot perform auto sell.");
		end
	end

	if (self.db.global.AutoRepair) then
		Addon:DoAutoRepair(false);
	end

	if (not Addon.db.global.FilteringButtonAlertShown) then
		VendorerFilteringButtonAlert:Show();
	end

	Addon.MerchantWindowOpeningTime = GetTime();
end

function VendorerFilteringButtonAlertCloseButton_OnClick()
	Addon.db.global.FilteringButtonAlertShown = true;
end

function Addon:MERCHANT_CLOSED()
	Addon.MerchantSellError = false;
	Addon.MerchantNpcId = nil;

	Addon:ResetFilteredItems();

	if (StaticPopup_Visible("VENDORER_CONFIRM_SELL_UNUSABLES")) then
		StaticPopup_Hide("VENDORER_CONFIRM_SELL_UNUSABLES");
	end

	if (StaticPopup_Visible("VENDORER_CONFIRM_DESTROY_JUNK")) then
		StaticPopup_Hide("VENDORER_CONFIRM_DESTROY_JUNK");
	end

	local diff = tonumber(GetMoney() - Addon.PlayerMoney);
	local moneystring = GetCoinTextureString(math.abs(diff));

	if (diff > 0) then
		Addon:Announce("|cff73ce2fGained|r " .. moneystring);
	elseif (diff < 0) then
		Addon:Announce("|cfff0543eLost|r " .. moneystring);
	end

	Addon.PlayerMoney = GetMoney();

	Addon:ResetAllFilters();

	HideUIPanel(VendorerItemListsFrame);

	if (VendorerStackSplitFrame:IsPurchasing()) then
		VendorerStackSplitFrame:CancelPurchase();
		Addon:AddMessage("Pending bulk purchase canceled due to merchant window being closed.");
	end
	VendorerStackSplitFrame:Cancel();
end

function Addon:TRANSMOG_COLLECTION_UPDATED()
	if (MerchantFrame:IsVisible()) then
		if (Addon.FilterText ~= "") then
			Addon:RefreshFilter(true);
		elseif (Addon.db.global.ShowTransmogAsterisk) then
			MerchantFrame_UpdateMerchantInfo();
		end
	end
end

hooksecurefunc("MerchantFrame_UpdateMerchantInfo", function() Addon:UpdateMerchantInfo() end);
hooksecurefunc("MerchantFrame_UpdateBuybackInfo", function() Addon:UpdateBuybackInfo() end);

function Addon:IsCurrencyItem(itemlink)
	return strmatch(itemlink, "Hcurrency") ~= nil;
end

function Addon:UpdateMerchantInfo()
	local numMerchantItems = GetMerchantNumItems();
	local realNumMerchantItems = Addon:GetUnfilteredMerchantNumItems();
	local maxPages = math.ceil(numMerchantItems / MERCHANT_ITEMS_PER_PAGE);

	if (maxPages <= 1) then
		MerchantPageText:SetFormattedText(
			"%d/%d items", numMerchantItems, realNumMerchantItems
		);
	else
		MerchantPageText:SetFormattedText(
			"Page %d/%d  %d/%d items", MerchantFrame.page, maxPages, numMerchantItems, realNumMerchantItems
		);
	end
	MerchantPageText:Show();

	local extension = Addon:GetCurrentExtension();
	if (extension == VENDORER_EXTENSION_WIDE) then
		MerchantItem11:ClearAllPoints();
		MerchantItem11:SetPoint("TOPLEFT", MerchantItem2, "TOPRIGHT", 12, 0);
		MerchantItem11:Show();
		MerchantItem12:Show();
	else
		MerchantItem11:ClearAllPoints();
		MerchantItem11:SetPoint("TOPLEFT", MerchantItem9, "BOTTOMLEFT", 0, -15);
		MerchantItem11:Hide();
		MerchantItem12:Hide();
	end

	if (numMerchantItems > 0) then
		for i = 1, MERCHANT_ITEMS_PER_PAGE, 1 do
			local index = ((MerchantFrame.page - 1) * MERCHANT_ITEMS_PER_PAGE) + i;
			local itemButton = _G["MerchantItem" .. i .. "ItemButton"];
			local merchantButton = _G["MerchantItem" .. i];

			local rarityBorder = _G["VendorerMerchantItem" .. i .. "Rarity"];
			if (rarityBorder) then
				rarityBorder:Hide();
				rarityBorder.transmogrifyAsterisk:Hide();
			end

			if (not itemButton.rarityBorder) then
				itemButton.rarityBorder = rarityBorder;

				itemButton:HookScript("OnEnter", function(self)
					self.rarityBorder.highlight:Show();
				end)

				itemButton:HookScript("OnLeave", function(self)
					self.rarityBorder.highlight:Hide();
				end);
			end

			if (index <= numMerchantItems) then
				local itemLink = GetMerchantItemLink(index);
				if (itemLink) then
					local _, _, _, _, _, _, isUsable = GetMerchantItemInfo(index);
					local _, _, rarity, _, _, itemType, itemSubType, _, itemEquipLoc = GetItemInfo(itemLink);

					if (rarityBorder) then
						if (rarity and rarity >= 1) then
							local r, g, b = GetItemQualityColor(rarity);
							local a = 0.9;
							if (rarity == 1) then a = 0.75 end
							rarityBorder.border:SetVertexColor(r, g, b, a);
							rarityBorder.highlight:SetVertexColor(r, g, b);
							rarityBorder:Show();
						elseif (Addon:IsCurrencyItem(itemLink)) then
							local rarity = select(9, Addon:GetCurrencyInfo(itemLink));
							if not rarity then
								local temp = select(2, Addon:GetCurrencyInfo(itemLink));
								rarity = temp.quality;
							end
							local r, g, b = GetItemQualityColor(rarity);
							local a = 0.9;
							if (rarity == 1) then a = 0.75 end
							rarityBorder.border:SetVertexColor(r, g, b, a);
							rarityBorder.highlight:SetVertexColor(r, g, b);
							rarityBorder:Show();
						end
					end

					-- Optional dependency for transmogs
					if (Addon.db.global.ShowTransmogAsterisk and CanIMogIt) then
						local isTransmogable, isKnown, anotherCharacter = Addon:GetKnownTransmogInfo(itemLink);

						if (isTransmogable) then
							if (not isKnown) then
								rarityBorder.transmogrifyAsterisk:Show();

								if (not anotherCharacter) then
									rarityBorder.transmogrifyAsterisk.iconSelf:Show();
									rarityBorder.transmogrifyAsterisk.iconOther:Hide();
								else
									rarityBorder.transmogrifyAsterisk.iconOther:Show();
									rarityBorder.transmogrifyAsterisk.iconSelf:Hide();
								end
							end
						end

						local cimiIcon = _G["CIMIOverlayFrame_MerchantItem" .. i .. "ItemButton"];
						if (cimiIcon) then
							cimiIcon:Hide();
						end
					elseif (CanIMogIt) then
						local cimiIcon = _G["CIMIOverlayFrame_MerchantItem" .. i .. "ItemButton"];
						if (cimiIcon) then
							cimiIcon:Show();
						end
					end

					local shouldColorize = false;
					local color = { 0.6, 0.0, 0.0 };

					if (Addon.db.global.PaintArmorTypes) then
						if (isUsable and itemType == LOCALIZED_ARMOR and Addon:IsArmorItemSlot(itemEquipLoc)) then
							if (itemSubType ~= LOCALIZED_COSMETIC and not Addon:IsValidClassArmorType(itemSubType)) then
								shouldColorize = true;
							end
						end
					end

					if (Addon.db.global.PaintKnownItems and Addon:IsItemKnown(itemLink)) then
						shouldColorize = true;
						color = {
							Addon.db.global.PaintColor.r,
							Addon.db.global.PaintColor.g,
							Addon.db.global.PaintColor.b
						};
					end

					if (shouldColorize) then
						local r, g, b = unpack(color);
						SetItemButtonNameFrameVertexColor(merchantButton, r, g, b);
						SetItemButtonSlotVertexColor(merchantButton, r, g, b);
						SetItemButtonTextureVertexColor(itemButton, r, g, b);
						SetItemButtonNormalTextureVertexColor(itemButton, r, g, b);
					end
				end
			end
		end
	end

	-------------------------------

	local buyBackItemButton = _G["MerchantBuyBackItemItemButton"];
	local buyBackRarityBorder = _G["VendorerMerchantBuyBackItemRarity"];
	if (buyBackRarityBorder) then
		buyBackRarityBorder:Hide();

		if (not buyBackItemButton.rarityBorder) then
			buyBackItemButton.rarityBorder = buyBackRarityBorder;

			buyBackItemButton:HookScript("OnEnter", function(self)
				self.rarityBorder.highlight:Show();
			end)

			buyBackItemButton:HookScript("OnLeave", function(self)
				self.rarityBorder.highlight:Hide();
			end);
		end

		local buybackitem = GetBuybackItemLink(GetNumBuybackItems());
		if (buybackitem) then
			local _, _, rarity, _, reqLevel, itemType, itemSubType, _, itemEquipLoc = GetItemInfo(buybackitem);

			if (rarity and rarity >= 1) then
				local r, g, b = GetItemQualityColor(rarity);
				local a = 0.9;
				if (rarity == 1) then a = 0.75 end
				buyBackRarityBorder.border:SetVertexColor(r, g, b, a);
				buyBackRarityBorder.highlight:SetVertexColor(r, g, b);
				buyBackRarityBorder:Show();
			end
		end
	end
end

function Addon:UpdateBuybackInfo()
	MerchantItem11:ClearAllPoints();
	MerchantItem11:SetPoint("TOPLEFT", MerchantItem9, "BOTTOMLEFT", 0, -15);

	local numBuybackItems = GetNumBuybackItems();
	local itemButton, buybackButton;
	local buybackName, buybackTexture, buybackPrice, buybackQuantity, buybackNumAvailable, buybackIsUsable;
	for i = 1, BUYBACK_ITEMS_PER_PAGE do
		local itemButton = _G["MerchantItem" .. i .. "ItemButton"];

		local rarityBorder = _G["VendorerMerchantItem" .. i .. "Rarity"];
		if (rarityBorder) then
			rarityBorder:Hide();
			rarityBorder.transmogrifyAsterisk:Hide();
		end

		if (not itemButton.rarityBorder) then
			itemButton.rarityBorder = rarityBorder;

			itemButton:HookScript("OnEnter", function(self)
				self.rarityBorder.highlight:Show();
			end)

			itemButton:HookScript("OnLeave", function(self)
				self.rarityBorder.highlight:Hide();
			end);
		end

		local link = GetBuybackItemInfo(i);
		if (link) then
			local _, _, rarity = GetItemInfo(link);
			if (rarity and rarity >= 1) then
				local r, g, b = GetItemQualityColor(rarity);
				local a = 0.9;
				if (rarity == 1) then a = 0.75 end
				rarityBorder.border:SetVertexColor(r, g, b, a);
				rarityBorder.highlight:SetVertexColor(r, g, b);
				rarityBorder:Show();
			end
		end
	end
end
