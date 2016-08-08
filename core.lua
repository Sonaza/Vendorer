------------------------------------------------------------
-- Vendorer by Sonaza
-- All rights reserved
-- http://sonaza.com
------------------------------------------------------------

local ADDON_NAME = ...;
local Addon = LibStub("AceAddon-3.0"):NewAddon(select(2, ...), ADDON_NAME, "AceEvent-3.0");
_G["Vendorer"] = Addon;

local AceDB = LibStub("AceDB-3.0");
local _;

-- Get some localized strings
local LOCALIZED_CLOTH           = GetItemSubClassInfo(4, 1);
local LOCALIZED_LEATHER         = GetItemSubClassInfo(4, 2);
local LOCALIZED_MAIL            = GetItemSubClassInfo(4, 3);
local LOCALIZED_PLATE           = GetItemSubClassInfo(4, 4);
local LOCALIZED_ARMOR           = GetItemClassInfo(4);
local LOCALIZED_COSMETIC        = GetItemSubClassInfo(4, 5);
local LOCALIZED_MISCELLANEOUS   = GetItemClassInfo(15);

VENDORER_IGNORE_ITEMS_BUTTON_TEXT = "Ignore Items";
VENDORER_ADD_JUNK_BUTTON_TEXT = "Add Junk Items";
VENDORER_SETTINGS_BUTTON_TEXT = "|TInterface\\Scenarios\\ScenarioIcon-Interact:14:14:0:0|t Settings";

VENDORER_SELL_JUNK_ITEMS_TEXT = "Sell Junk Items";
VENDORER_SELL_UNUSABLE_ITEMS_TEXT = "Sell Unusables";

VENDORER_BIG_DRAG_ITEM_HERE_TEXT = "|cffffd200Drag item here to|nadd it to the list|r";

VENDORER_AUTO_SELL_JUNK_TITLE_TEXT = "Auto Sell Junk";
VENDORER_AUTO_SELL_JUNK_HINT_TEXT = "|cffffffffToggle automatic selling of junk when visiting vendors.";

VENDORER_AUTO_REPAIR_TITLE_TEXT = "Auto Repair";
VENDORER_AUTO_REPAIR_HINT_TEXT = "|cffffffffRepair all gear automatically if possible.";

VENDORER_USE_SMART_REPAIR_TITLE_TEXT = "Use Smart Repair";
VENDORER_USE_SMART_REPAIR_HINT_TEXT = "|cffffffffWhen doing automatic repair allow Vendorer to try and spend full guild repair allowance first.|n|n|cff00c6ffNote:|cffffffff this option only applies to auto repair!|n|nProbably not recommended if you have unlimited repair funds.";

VENDORER_CONTRACT_BUTTON_TITLE_TEXT = "Collapse Frame";
VENDORER_EXPAND_BUTTON_TITLE_TEXT = "Expand Frame";

VENDORER_EXPANSION_TUTORIAL_TEXT = "You can now switch between default, narrow and wide frame.";
VENDORER_FILTERING_BUTTON_TUTORIAL_TEXT = "You can now click here to quickly filter items.|n|nHover to see filtering tips. New filters are marked with |TInterface\\OptionsFrame\\UI-OptionsFrame-NewFeatureIcon:12:12:0:0:|t";

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
	["INVTYPE_2HWEAPON"]		= true,
	["INVTYPE_CHEST"]			= true,
	["INVTYPE_CLOAK"]			= true,
	["INVTYPE_FEET"]			= true,
	["INVTYPE_FINGER"]			= true,
	["INVTYPE_HAND"]			= true,
	["INVTYPE_HEAD"]			= true,
	["INVTYPE_HOLDABLE"]		= true,
	["INVTYPE_LEGS"]			= true,
	["INVTYPE_NECK"]			= true,
	["INVTYPE_RANGED"]			= true,
	["INVTYPE_RANGEDRIGHT"]		= true,
	["INVTYPE_RELIC"]			= true,
	["INVTYPE_ROBE"]			= true,
	["INVTYPE_SHIELD"]			= true,
	["INVTYPE_SHOULDER"]		= true,
	["INVTYPE_THROWN"]			= true,
	["INVTYPE_TRINKET"]			= true,
	["INVTYPE_WAIST"]			= true,
	["INVTYPE_WEAPON"]			= true,
	["INVTYPE_WEAPONMAINHAND"]	= true,
	["INVTYPE_WEAPONOFFHAND"]	= true,
	["INVTYPE_WRIST"]			= true,
};

local DEFAULT_IGNORE_LIST_ITEMS = {
	[33820]     = true, -- Weather-Beaten Fishing Hat
	[2901]      = true, -- Mining Pick
	[44731]     = true, -- Bouquet of Ebon Roses
	[19970]     = true, -- Arcanite Fishing Pole
	[116913]    = true, -- Peon's Mining Pick
	[116916]    = true, -- Gorepetal's Gentle Grasp
	[84661]     = true, -- Dragon Fishing Pole
	[103678]    = true, -- Time-Lost Artifact
	[86566]     = true, -- Forager's Gloves
	[63207]     = true, -- Wrap of Unity
	[63353]     = true, -- Shroud of Cooperation
	[63206]     = true, -- Wrap of Unity
	[65274]     = true, -- Cloak of Coordination
};

StaticPopupDialogs["VENDORER_CONFIRM_SELL_UNUSABLES"] = {
	text = "Are you sure you want to sell unusable items? You can still buy them back after.",
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		Addon:ConfirmSellUnusables();
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
};

StaticPopupDialogs["VENDORER_CONFIRM_CLEAR_IGNORE_LIST"] = {
	text = "Are you sure you want wipe the ignore list? This action cannot be undone.",
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		Addon.db.global.ItemIgnoreList = DEFAULT_IGNORE_LIST_ITEMS;
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
		Addon.db.global.ItemJunkList = {};
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
	if(not Addon.db.global.UseTooltipSearch) then return end
	
	-- Merchant window opening may lag a bit so don't display popup for that
	if((GetTime() - Addon.MerchantWindowOpeningTime) < 2.5) then return end
	
	self.elapsed = (self.elapsed or 0) + elapsed;
	if(self.elapsed < 0.5) then return end
	self.elapsed = 0;
	
	local framerate = GetFramerate();
	if(self.averageFPS) then
		local diff = framerate - self.averageFPS;
		self.averageFPS = self.averageFPS * 0.7 + framerate * 0.3;
		
		if(not MerchantFrame:IsVisible()) then return end
		
		if((GetTime() - Addon.UpdatedFilteringTime) < 5.0) then
			if(diff < 0 and math.abs(diff) >= self.averageFPS * 0.3 and framerate <= 11) then
				if(not StaticPopup_Visible("VENDORER_FILTERING_PERFORMANCE_ALERT")) then
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

VENDORER_EXTENSION_NONE     = 1;
VENDORER_EXTENSION_NARROW   = 2;
VENDORER_EXTENSION_WIDE     = 3;

function Addon:OnInitialize()
	local defaults = {
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
			
			UseImprovedStackSplit = true,
			UseSafePurchase = false,
			
			UseTooltipSearch = true,
			
			AutoRepair = false,
			SmartAutoRepair = true,
			
			ItemIgnoreList = DEFAULT_IGNORE_LIST_ITEMS,
			ItemJunkList = {},
			
			ShowTransmogAsterisk = true,
			
			ExpandTutorialShown = false,
			FilteringButtonAlertShown = false,
		},
	};
	
	self.db = AceDB:New("VendorerDB", defaults);
	
	if(type(self.db.global.MerchantFrameExtended) == "boolean") then
		if(self.db.global.MerchantFrameExtended) then
			self.db.global.MerchantFrameExtension = VENDORER_EXTENSION_NARROW;
		else
			self.db.global.MerchantFrameExtension = VENDORER_EXTENSION_NONE;
		end
		self.db.global.MerchantFrameExtended = nil;
	end
end

function Addon:OnEnable()
	if(not VendorerItemListsFrame) then
		error("You have updated the addon but only reloaded the interface. Please restart the game.", 1);
	end
	
	self:RegisterEvent("MERCHANT_SHOW");
	self:RegisterEvent("MERCHANT_CLOSED");
	self:RegisterEvent("MERCHANT_UPDATE");
	self:RegisterEvent("CURSOR_UPDATE");
	self:RegisterEvent("UPDATE_INVENTORY_DURABILITY");
	self:RegisterEvent("TRANSMOG_COLLECTION_UPDATED");
	
	Addon.PlayerMoney = GetMoney();
	
	Addon:RestoreSavedSettings();

	hooksecurefunc("PickupContainerItem", function()
		if(not CursorHasItem()) then return end
		
		Addon:ToggleCursorHighlights(true);
		Addon:RegisterEvent("ITEM_UNLOCKED");
	end);
	
	VendorerExtensionTutorialFrame:HookScript("OnHide", function()
		Addon.db.global.ExpandTutorialShown = true;
	end);
	
	if(not Addon.db.global.ExpandTutorialShown) then
		VendorerExtensionTutorialFrame:Show();
	end
	
	Addon:MakeFrameMovable();
end

function Addon:MakeFrameMovable()
	MerchantFrame:SetMovable(true);
	MerchantFrame:SetScript("OnMouseDown", function(self)
		self:StartMoving();
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
end

function Addon:ToggleCursorHighlights(toggle)
	if(toggle) then
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
	if(CursorHasItem()) then return end
	Addon:ToggleCursorHighlights(false);
	Addon:UnregisterEvent("ITEM_UNLOCKED");
end

function Addon:CURSOR_UPDATE()
	if(CursorHasItem()) then return end
	Addon:ToggleCursorHighlights(false);
end

function Addon:MERCHANT_UPDATE()
	if(MerchantFrame.selectedTab == 1) then
		Addon:UpdateMerchantItems();
	end
end

function Addon:EnhanceMerchantFrame()
	local extension = Addon:GetCurrentExtension();
	
	local offset = 0;
	if(extension ~= VENDORER_EXTENSION_NONE) then
		offset = 164;
	end
	
	MerchantPageText:SetWidth(164);
	MerchantPageText:ClearAllPoints();
	MerchantPageText:SetPoint("BOTTOM", MerchantFrame, "BOTTOM", -offset / 2 + 3, 90);
	MerchantPageText:SetJustifyH("CENTER");
	
	MerchantNextPageButton:ClearAllPoints();
	MerchantNextPageButton:SetPoint("RIGHT", MerchantFrame, "BOTTOMRIGHT", -offset - 6, 96);
	MerchantNextPageButton:SetFrameLevel(MerchantFrame:GetFrameLevel()+2);
	
	MerchantExtraCurrencyInset:ClearAllPoints();
	MerchantExtraCurrencyInset:SetPoint("BOTTOMRIGHT", MerchantFrame, "BOTTOMRIGHT", -169, 4);
	MerchantExtraCurrencyInset:SetPoint("TOPLEFT", MerchantFrame, "BOTTOMRIGHT", -169-163, 27);
	
	MerchantExtraCurrencyBg:ClearAllPoints();
	MerchantExtraCurrencyBg:SetPoint("BOTTOMRIGHT", MerchantFrame, "BOTTOMRIGHT", -169-3, 6);
	MerchantExtraCurrencyBg:SetPoint("TOPLEFT", MerchantFrame, "BOTTOMRIGHT", -169-163, 25);
end

function Addon:UpdateExtensionToggleButton()
	if(Addon.db.global.MerchantFrameExtension == VENDORER_EXTENSION_NONE) then
		VendorerToggleExtensionFrameButtonContract:Disable();
	else
		VendorerToggleExtensionFrameButtonContract:Enable();
	end
	
	if(Addon.db.global.MerchantFrameExtension == VENDORER_EXTENSION_WIDE) then
		VendorerToggleExtensionFrameButtonExpand:Disable();
	else
		VendorerToggleExtensionFrameButtonExpand:Enable();
	end
	
	Addon:UpdateExtensionPanel();
end

function Addon:UpdateExtensionPanel()
	if(Addon.db.global.MerchantFrameExtension ~= VENDORER_EXTENSION_NONE) then
		Addon:ShowExtensionPanel();
	else
		Addon:HideExtensionPanel();
	end
	
	Addon:EnhanceMerchantFrame();
	
	if(VendorerItemListsFrame:IsVisible()) then
		VendorerItemListsFrame_Reanchor();
	end
end

function Addon:GetCurrentExtension()
	local extension = Addon.db.global.MerchantFrameExtension;
	local numItems = Addon:GetUnfilteredMerchantNumItems();
	
	if(numItems <= 10 and extension == VENDORER_EXTENSION_WIDE) then
		extension = VENDORER_EXTENSION_NARROW;
	end
	
	return extension;
end

function Addon:SetMerchantItemsPerPage(items)
	MERCHANT_ITEMS_PER_PAGE = items or 10;
	
	local merchantIsOpen = MerchantFrame:IsVisible();
	if(merchantIsOpen) then
		if(MerchantFrame.page < 1) then MerchantFrame.page = 1 end
		local maxPages = math.ceil(Addon:GetUnfilteredMerchantNumItems() / MERCHANT_ITEMS_PER_PAGE);
		if(MerchantFrame.page > maxPages) then MerchantFrame.page = maxPages end
		
		if(MerchantFrame.selectedTab == 1) then
			MerchantFrame_UpdateMerchantInfo();
		end
	end
end

function Addon:ShowExtensionPanel()
	local extension = Addon:GetCurrentExtension();
	
	if(extension == VENDORER_EXTENSION_WIDE) then
		MerchantFrame:SetWidth(834);
		Addon:SetMerchantItemsPerPage(20);
		
		VendorerExtraMerchantItems:Show();
		
		VendorerMerchantFrameExtension:Show();
		VendorerMerchantFrameExtensionNarrow:Hide();
		VendorerMerchantFrameExtensionWide:Show();
	elseif(extension == VENDORER_EXTENSION_NARROW) then
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
	if(id == 1) then
		Addon.db.global.MerchantFrameExtension = Addon.db.global.MerchantFrameExtension - 1;
	elseif(id == 2) then
		Addon.db.global.MerchantFrameExtension = Addon.db.global.MerchantFrameExtension + 1;
	end
	
	if(Addon.db.global.MerchantFrameExtension < 1) then Addon.db.global.MerchantFrameExtension = 1; end
	if(Addon.db.global.MerchantFrameExtension > 3) then Addon.db.global.MerchantFrameExtension = 3; end
	
	Addon:UpdateExtensionToggleButton();
end

function VendorerToggleExtensionFrameButton_OnEnter(self)
	if(self.tooltipTitle) then
		GameTooltip:ClearAllPoints();
		GameTooltip:SetOwner(VendorerToggleExtensionFrameButtonExpand, "ANCHOR_PRESERVE");
		GameTooltip:SetPoint("LEFT", VendorerToggleExtensionFrameButtonExpand, "RIGHT", 0, 0);
		
		local titleText = _G[self.tooltipTitle] or self.tooltipTitle;
		GameTooltip:AddLine(titleText, nil, nil, nil, true);
		
		if(self.tooltipText) then
			local tooltipText = _G[self.tooltipText] or self.tooltipText;
			GameTooltip:AddLine(tooltipText, nil, nil, nil, true);
		end
		
		GameTooltip:Show();
	end
end

function VendorerCheckButtonTemplate_OnLoad(self)
	local text = _G[self:GetName() .. "Text"];
	if(text) then
		text:SetText(self:GetText());
		
		if(self == VendorerArmorPaintRedButton) then
			text:SetText("Highlight " .. Addon:GetClassArmorType());
		end
		
		text:SetFontObject("VendorerMenuFont");
	end
end

function VendorerCheckButtonTemplate_OnEnter(self)
	if(self.tooltipTitle and self.tooltipText) then
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
	if(func and type(func) == "function") then
		func(_G[buttonName], button);
	else
		error(("Missing callback for %s"):format(buttonName), 1);
	end
end

function Addon:ScanContainers(filter)
	if(not filter) then return {} end
	
	local foundItems = {};
	
	for bagIndex = 0, 4 do
		local numSlots = GetContainerNumSlots(bagIndex);
		if(numSlots > 0) then
			for slotIndex = 1, numSlots do
				local link = GetContainerItemLink(bagIndex, slotIndex);
				local item_id = link and Addon:GetItemID(link) or 0;
				if(link and not self.db.global.ItemIgnoreList[item_id]) then
					local result, data = filter(bagIndex, slotIndex);
					if(result) then
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
	if(not bagIndex or not slotIndex) then return false end
	
	local texture, itemCount, locked, quality, readable, lootable, itemLink, isFiltered = GetContainerItemInfo(bagIndex, slotIndex);
	if(itemLink) then
		local itemName, _, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount,
			itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(itemLink);
			
		if(not itemName) then return false end
		local item_id = Addon:GetItemID(itemLink);
		
		return itemName and (quality == 0 or Addon.db.global.ItemJunkList[item_id]) and itemSellPrice > 0, {
			itemLink = itemLink,
			itemSellPrice = itemSellPrice * itemCount,
		};
	end
	
	return false;
end

local BT_BIND_ON_PICKUP		= 1;
local BT_BIND_ON_EQUIP		= 2;
local BT_BIND_ON_ACCOUNT	= 3;
local BT_BIND_ON_USE		= 4;
local BT_QUEST_ITEM			= 5;
local BT_UNKNOWN			= -1;

function Addon:ScanBindType(text)
	if(text) then
		if(text == ITEM_BIND_ON_PICKUP) 		then return BT_BIND_ON_PICKUP end
		if(text == ITEM_BIND_ON_EQUIP) 			then return BT_BIND_ON_EQUIP end
		if(text == ITEM_BIND_TO_ACCOUNT) 		then return BT_BIND_ON_ACCOUNT end
		if(text == ITEM_BIND_TO_BNETACCOUNT) 	then return BT_BIND_ON_ACCOUNT end
		if(text == ITEM_BIND_ON_USE) 			then return BT_BIND_ON_USE end
		if(text == ITEM_BIND_QUEST) 			then return BT_QUEST_ITEM end
	end
	
	return nil;
end

function Addon:IsRedText(text)
	if(text and text:GetText()) then
		local r, g, b = text:GetTextColor();
		if(r >= 0.98 and g <= 0.16 and b <= 0.16) then return true end
	end
	
	return false;
end

local NOT_USABLE_CLASS_TYPE = 1;
local NOT_USABLE_TYPE 		= 2;
local NOT_USABLE_CLASS 		= 3;
local NOT_USABLE_RACE 		= 4;

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
	if(not item) then return end
	
	local _, itemLink, itemRarity, _, _, itemType, itemSubType, _, itemEquipLoc = GetItemInfo(item);
		
	if(cachedItemInfo[itemLink]) then
		return unpack(cachedItemInfo[itemLink]);
	end
	
	local bindType, isUsable, isClassArmorType, notUsableReason;
	local isUnique = false;
	
	if(IsEquippableItem(itemLink) and Addon:IsArmorItemSlot(itemEquipLoc)) then
		if(itemSubType == LOCALIZED_COSMETIC or itemSubType == LOCALIZED_MISCELLANEOUS or Addon:IsValidClassArmorType(itemSubType)) then
			isClassArmorType = true;
		else
			isClassArmorType = false;
		end
	end
	
	isUsable = true;
	
	local tooltipItemSlot, tooltipItemType;
	tooltipItemSlot = itemEquipLoc ~= "" and _G[itemEquipLoc] or nil;
	
	if(isClassArmorType == false) then
		notUsableReason = NOT_USABLE_CLASS_TYPE;
		isUsable = false;
	end
	
	VendorerTooltip:SetOwner(UIParent, "ANCHOR_NONE");
	VendorerTooltip:SetHyperlink(itemLink);
	local numLines = VendorerTooltip:NumLines();
	
	for line = 2, numLines do
		local wasUsable = isUsable;
		
		local left = _G["VendorerTooltipTextLeft" .. line];
		local right = _G["VendorerTooltipTextRight" .. line];
		
		if(not bindType) then
			bindType = Addon:ScanBindType(left:GetText());
		end
		
		if(IsEquippableItem(itemLink)) then
			if(left:GetText() == itemType and Addon:IsRedText(left)) then
				if(isUsable and not notUsableReason) then notUsableReason = NOT_USABLE_TYPE end
				isUsable = false;
			end
			
			if(right and (right:GetText() == itemSubType or line <= 6)) then
				if(Addon:IsRedText(right)) then
					if(isUsable and not notUsableReason) then notUsableReason = NOT_USABLE_TYPE end
					isUsable = false;
				end
				
				if(not tooltipItemType) then
					tooltipItemType = right:GetText();
				end
			end
			
			local equipSlotName = itemEquipLoc ~= "" and _G[itemEquipLoc] or "";
			if(left:GetText() == equipSlotName and Addon:IsRedText(left)) then
				if(isUsable and not notUsableReason) then notUsableReason = NOT_USABLE_TYPE end
				isUsable = false;
			end
		end
		
		if(strmatch(left:GetText(), ITEM_CLASSES_PATTERN)) then
			isUsable = isUsable and not Addon:IsRedText(left);
			if(wasUsable and not isUsable) then notUsableReason = NOT_USABLE_CLASS end
		end
		
		if(strmatch(left:GetText(), ITEM_RACES_PATTERN)) then
			isUsable = isUsable and not Addon:IsRedText(left);
			if(wasUsable and not isUsable) then notUsableReason = NOT_USABLE_RACE end
		end
		
		if(left:GetText() == ITEM_UNIQUE) then
			isUnique = true;
		end
	end
	
	if(not tooltipItemType and IsEquippableItem(itemLink)) then
		tooltipItemType = itemSubType;
	end
	
	if(not bindType) then bindType = BT_UNKNOWN end
	if(isUsable == nil) then isUsable = true; end
	
	cachedItemInfo[itemLink] = { bindType, isUsable, isClassArmorType, notUsableReason, tooltipItemSlot, tooltipItemType, itemSubType, isUnique };
	return bindType, isUsable, isClassArmorType, notUsableReason, tooltipItemSlot, tooltipItemType, itemSubType, isUnique;
end

local function FilterUnusableItems(bagIndex, slotIndex)
	if(not bagIndex or not slotIndex) then return false end
	
	local texture, itemCount, locked, quality, readable, lootable, itemLink, isFiltered = GetContainerItemInfo(bagIndex, slotIndex);
	if(itemLink) then
		local itemName, _, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount,
			itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(itemLink);
		
		if(not itemName) then return false end
		if(itemType == "Recipe") then return false end
		if(itemRarity > 4 or itemSellPrice == 0) then return false end
		
		local bindType, isUsable, isClassArmorType, notUsableReason, tooltipItemSlot, tooltipItemType, itemSubType = Addon:GetItemTooltipInfo(itemLink);
		
		local reasonText;
		if(notUsableReason == NOT_USABLE_TYPE) then
		 	reasonText = string.format("%s (%s)", tooltipItemSlot, tooltipItemType);
		 	
		elseif(notUsableReason == NOT_USABLE_CLASS) then
			reasonText = string.format("Unusable by %s", PLAYER_CLASS_READABLE);
			
		elseif(notUsableReason == NOT_USABLE_RACE) then
			reasonText = string.format("Unusable by %s", PLAYER_RACE_READABLE);
			
		elseif(notUsableReason == NOT_USABLE_CLASS_TYPE) then
			local classArmorType = Addon:GetClassArmorType();
			reasonText = string.format("%s (%s)  %s uses %s Armor", tooltipItemSlot, tooltipItemType, PLAYER_CLASS_READABLE, classArmorType);
		end
		
		if(isClassArmorType == nil) then isClassArmorType = true end
		
		return bindType == BT_BIND_ON_PICKUP and (not isUsable or not isClassArmorType), {
			itemLink = itemLink,
			itemSellPrice = itemSellPrice * itemCount,
			reasonText = reasonText,
		};
	end
	
	return false;
end

function Addon:GetItemID(itemLink)
	if(not itemLink) then return end
	
	local itemID = strmatch(itemLink, "item:(%d+)");
	return itemID and tonumber(itemID) or nil;
end

function Addon:AddCursorItemToIgnoreList()
	local cursor, _, itemLink = GetCursorInfo();
	if(cursor == "item" and itemLink) then
		Addon:AddItemToIgnoreList(itemLink);
		ClearCursor();
	end
	
	if(not VendorerItemListsFrame:IsVisible()) then
		VendorerIgnoreItemsButton_OnEnter(VendorerIgnoreItemsButton);
	end
end

function Addon:AddItemToIgnoreList(itemLink)
	if(not itemLink) then return end
	local itemID = Addon:GetItemID(itemLink);
	
	if(Addon.db.global.ItemJunkList[itemID]) then
		Addon.db.global.ItemJunkList[itemID] = nil;
		Addon:AddMessage(string.format("%s removed from junk sell list.", itemLink));
	end
	
	if(not Addon.db.global.ItemIgnoreList[itemID]) then
		Addon.db.global.ItemIgnoreList[itemID] = true;
		Addon:AddMessage(string.format("%s added to ignore list.", itemLink));
	else
		Addon.db.global.ItemIgnoreList[itemID] = nil;
		Addon:AddMessage(string.format("%s removed from ignore list.", itemLink));
	end
	
	Addon:UpdateVendorerItemLists();
end

function Addon:AddCursorItemToJunkList()
	local cursor, _, itemLink = GetCursorInfo();
	if(cursor == "item" and itemLink) then
		Addon:AddItemToJunkList(itemLink);
		ClearCursor();
	end
	
	if(not VendorerItemListsFrame:IsVisible()) then
		VendorerJunkItemsButton_OnEnter(VendorerJunkItemsButton);
	end
end

function Addon:AddItemToJunkList(itemLink)
	if(not itemLink) then return end
	local itemID = Addon:GetItemID(itemLink);
	
	if(Addon.db.global.ItemIgnoreList[itemID]) then
		Addon.db.global.ItemIgnoreList[itemID] = nil;
		Addon:AddMessage(string.format("%s removed from ignore list.", itemLink));
	end
	
	if(not Addon.db.global.ItemJunkList[itemID]) then
		Addon.db.global.ItemJunkList[itemID] = true;
		Addon:AddMessage(string.format("%s added to junk sell list.", itemLink));
	else
		Addon.db.global.ItemJunkList[itemID] = nil;
		Addon:AddMessage(string.format("%s removed from junk sell list.", itemLink));
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
	
	local items = {};
	for itemID, _ in pairs(Addon.db.global.ItemIgnoreList) do
		local _, link = GetItemInfo(itemID);
		tinsert(items, link);
	end
	
	GameTooltip:AddLine(" ");
	GameTooltip:AddLine("|cff00ff00Left-click  |cffffffffView items on the list");
	
	local numIgnoredItems = #items;
	if(numIgnoredItems > 0) then
		GameTooltip:AddLine("|cff00ff00Shift Right-click  |cffffffffWipe the ignore list");
		GameTooltip:AddLine(" ");
		GameTooltip:AddLine(string.format("%d Ignored Items", numIgnoredItems));
	end
	
	self.text:SetFontObject("VendorerButtonFontHighlight");
	
	GameTooltip:Show();
	
	if(IsMouseButtonDown("LeftButton")) then
		self:SetScript("OnUpdate", function(self)
			if(not IsMouseButtonDown("LeftButton")) then
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
	VendorerItemListsFrame.addItemFunction = Addon.AddCursorItemToIgnoreList;
	Addon:OpenVendorerItemListsFrame("Vendorer Ignored Items", Addon.db.global.ItemIgnoreList);
end

function VendorerIgnoreItemsButton_OnClick(self, button)
	if(button == "LeftButton") then
		if(not GetCursorInfo()) then
			Addon:OpenIgnoredItemsListsFrame();
		else
			Addon:AddCursorItemToIgnoreList();
		end
	elseif(button == "RightButton" and IsShiftKeyDown()) then
		if(not GetCursorInfo()) then
			for link, _ in pairs(Addon.db.global.ItemIgnoreList) do
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
	Addon:OpenVendorerItemListsFrame("Vendorer Junk Items", Addon.db.global.ItemJunkList);
	VendorerItemListsFrameDescription:SetText("These items are always sold.");
	VendorerItemListsFrame.addItemFunction = Addon.AddCursorItemToJunkList;
end

function VendorerJunkItemsButton_OnClick(self, button)
	if(button == "LeftButton") then
		if(not GetCursorInfo()) then
			Addon:OpenJunkItemsListsFrame();
		else
			Addon:AddCursorItemToJunkList();
		end
	elseif(button == "RightButton" and IsShiftKeyDown()) then
		if(not GetCursorInfo()) then
			for link, _ in pairs(Addon.db.global.ItemJunkList) do
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
	
	local items = {};
	for itemID, _ in pairs(Addon.db.global.ItemJunkList) do
		local _, link = GetItemInfo(itemID);
		tinsert(items, link);
	end
	
	GameTooltip:AddLine(" ");
	GameTooltip:AddLine("|cff00ff00Left-click  |cffffffffView items on the list");
	
	local numIgnoredItems = #items;
	if(numIgnoredItems > 0) then
		GameTooltip:AddLine("|cff00ff00Shift Right-click |cffffffffWipe the junk list");
		GameTooltip:AddLine(" ");
		GameTooltip:AddLine(string.format("%d Junk Items", numIgnoredItems));
	end
	
	self.text:SetFontObject("VendorerButtonFont");
	
	GameTooltip:Show();
	
	if(IsMouseButtonDown("LeftButton")) then
		self:SetScript("OnUpdate", function(self)
			if(not IsMouseButtonDown("LeftButton")) then
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

function Addon:SellJunk(skip_limit)
	local maxSell = 12;
	local items = Addon:ScanContainers(FilterJunkItems);
	if(#items == 0) then return end
	
	local skipped = false;
	
	for index, slotinfo in pairs(items) do
		local texture, itemCount, locked, quality, readable, lootable, itemLink = GetContainerItemInfo(slotinfo.bag, slotinfo.slot);
		local itemMessage = string.format("Selling %s", itemLink);
		if(itemCount > 1) then
			itemMessage = string.format("%s x%d", itemMessage, itemCount);
		end
		
		Addon:AddMessage(itemMessage);
		
		UseContainerItem(slotinfo.bag, slotinfo.slot);
		
		if(not skip_limit and index == maxSell and index ~= #items) then
			Addon:AddMessage(string.format("Sold %d items (%d more to sell)", index, #items - index));
			skipped = true;
			break;
		end
	end
	
	if(skip_limit or not skipped) then
		Addon:AddMessage("All junk items sold!");
	end
end

function Addon:ConfirmSellUnusables()
	local maxSell = 12;
	local items = Addon:ScanContainers(FilterUnusableItems);
	if(#items == 0) then return end
	
	for index, slotinfo in pairs(items) do
		local texture, itemCount, locked, quality, readable, lootable, itemLink = GetContainerItemInfo(slotinfo.bag, slotinfo.slot);
		local itemMessage = string.format("Selling %s", itemLink);
		if(itemCount > 1) then
			itemMessage = string.format("%s x%d", itemMessage, itemCount);
		end
		
		Addon:AddMessage(itemMessage);
		
		UseContainerItem(slotinfo.bag, slotinfo.slot);
		if(index == maxSell and index ~= #items) then
			Addon:AddMessage(string.format("Sold %d items (%d more to sell)", index, #items - index));
			skipped = true;
			break;
		end
	end
	
	if(not skipped) then
		Addon:AddMessage("All unusable items sold!");
	end
end

function Addon:BAG_UPDATE_DELAYED()
	if(not Addon.UpdateTooltip) then
		Addon:UnregisterEvent("BAG_UPDATE_DELAYED");
		return
	end
	
	if(Addon.UpdateTooltip == 1) then
		VendorerSellJunkButton_OnEnter(VendorerSellJunkButton)
	elseif(Addon.UpdateTooltip == 2) then
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
	for _, slotInfo in pairs(items) do
		sellPrice = sellPrice + slotInfo.data.itemSellPrice;
	end
	
	GameTooltip:ClearAllPoints();
	GameTooltip:SetOwner(self, "ANCHOR_PRESERVE");
	GameTooltip:SetPoint("BOTTOMLEFT", self, "RIGHT", 0, -15);
	
	GameTooltip:AddLine("Sell Junk");
	GameTooltip:AddLine("|cffffffffSell all poor quality items.");
	GameTooltip:AddLine(" ");
	GameTooltip:AddDoubleLine("Estimated Income", string.format("|cffffffff%d items  %s  ", #items, GetCoinTextureString(sellPrice)));
	GameTooltip:Show();
	
	Addon.UpdateTooltip = 1;
	Addon:RegisterEvent("BAG_UPDATE_DELAYED");
end

function VendorerSellJunkButton_OnClick(self, button)
	Addon:SellJunk();
end

function VendorerSellUnusablesButton_OnEnter(self, button)
	local items = Addon:ScanContainers(FilterUnusableItems);
	local sellPrice = 0;
	for _, slotInfo in pairs(items) do
		sellPrice = sellPrice + slotInfo.data.itemSellPrice;
	end
	
	GameTooltip:ClearAllPoints();
	GameTooltip:SetOwner(self, "ANCHOR_PRESERVE");
	GameTooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 0, 70);
	
	GameTooltip:AddLine("Sell Unusables");
	GameTooltip:AddLine("|cffffffffSell all soulbound equipment and tokens that you cannot use.");
	GameTooltip:AddLine(" ");
	GameTooltip:AddDoubleLine("Estimated Income", string.format("|cffffffff%d items  %s  ", #items, GetCoinTextureString(sellPrice)));
	
	if(#items > 0) then
		GameTooltip:AddLine(" ");
		GameTooltip:AddDoubleLine("Items", "Reason");
		
		for index, slotInfo in pairs(items) do
			local itemName, _, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount,
				itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(slotInfo.data.itemLink);
			
			local equipSlotName = itemEquipLoc ~= "" and _G[itemEquipLoc] or "";
			GameTooltip:AddDoubleLine(slotInfo.data.itemLink, string.format("%s", slotInfo.data.reasonText or "--"), 1, 1, 1, 1, 1, 1);
			
			if(index == 12 and #items > 12) then
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
	if(#items == 0) then return end
	
	StaticPopup_Show("VENDORER_CONFIRM_SELL_UNUSABLES");
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
	Addon:ResetFilter()
	Addon.PlayerMoney = GetMoney();
	
	if(self.db.global.AutoSellJunk) then
		Addon:SellJunk(true);
	end
	
	if(self.db.global.AutoRepair) then
		Addon:DoAutoRepair(false);
	end
	
	if(not Addon.db.global.FilteringButtonAlertShown) then
		VendorerFilteringButtonAlert:Show();
	end
	
	Addon.MerchantWindowOpeningTime = GetTime();
end

function VendorerFilteringButtonAlertCloseButton_OnClick()
	Addon.db.global.FilteringButtonAlertShown = true;
end

function Addon:MERCHANT_CLOSED()
	local diff = tonumber(GetMoney() - Addon.PlayerMoney);
	local moneystring = GetCoinTextureString(math.abs(diff));
	
	if(diff > 0) then
		Addon:Announce("|cff73ce2fGained|r " .. moneystring);
	elseif(diff < 0) then
		Addon:Announce("|cfff0543eLost|r " .. moneystring);
	end
	
	Addon.PlayerMoney = GetMoney();
	
	Addon:ResetAllFilters();
	
	HideUIPanel(VendorerItemListsFrame);
	
	if(VendorerStackSplitFrame:IsPurchasing()) then
		VendorerStackSplitFrame:CancelPurchase();
		Addon:AddMessage("Pending bulk purchase canceled due to merchant window being closed.");
	end
	VendorerStackSplitFrame:Cancel();
end

function Addon:TRANSMOG_COLLECTION_UPDATED()
	if(MerchantFrame:IsVisible()) then
		if(Addon.FilterText ~= "") then
			Addon:RefreshFilter(true);
		elseif(Addon.db.global.ShowTransmogAsterisk) then
			MerchantFrame_UpdateMerchantInfo();
		end
	end
end

hooksecurefunc("MerchantFrame_UpdateMerchantInfo", function() Addon:UpdateMerchantInfo() end);
hooksecurefunc("MerchantFrame_UpdateBuybackInfo", function() Addon:UpdateBuybackInfo() end);

function Addon:UpdateMerchantInfo()
	local numMerchantItems = GetMerchantNumItems();
	local realNumMerchantItems = Addon:GetUnfilteredMerchantNumItems();
	local maxPages = math.ceil(numMerchantItems / MERCHANT_ITEMS_PER_PAGE);
	
	if(maxPages <= 1) then
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
	if(extension == VENDORER_EXTENSION_WIDE) then
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
	
	for i=1, MERCHANT_ITEMS_PER_PAGE, 1 do
		local index = ((MerchantFrame.page - 1) * MERCHANT_ITEMS_PER_PAGE) + i;
		local itemButton = _G["MerchantItem"..i.."ItemButton"];
		local merchantButton = _G["MerchantItem"..i];
		
		local rarityBorder = _G["VendorerMerchantItem"..i.."Rarity"];
		if(rarityBorder) then
			rarityBorder:Hide();
			rarityBorder.transmogrifyAsterisk:Hide();
		end
		
		if(not itemButton.rarityBorder) then
			itemButton.rarityBorder = rarityBorder;
			
			itemButton:HookScript("OnEnter", function(self)
				self.rarityBorder.highlight:Show();
			end)
			
			itemButton:HookScript("OnLeave", function(self)
				self.rarityBorder.highlight:Hide();
			end);
		end
		
		if(index <= numMerchantItems) then
			local itemLink = GetMerchantItemLink(index);
			if(itemLink) then
				local _, _, _, _, _, isUsable = GetMerchantItemInfo(index);
				local _, _, rarity, _, _, itemType, itemSubType, _, itemEquipLoc = GetItemInfo(itemLink);
				
				if(rarityBorder and rarity and rarity >= 1) then
					local r, g, b = GetItemQualityColor(rarity);
					local a = 0.9;
					if(rarity == 1) then a = 0.75 end
					rarityBorder.border:SetVertexColor(r, g, b, a);
					rarityBorder.highlight:SetVertexColor(r, g, b);
					rarityBorder:Show();
				end
				
				-- Optional dependency for transmogs
				if(Addon.db.global.ShowTransmogAsterisk and CanIMogIt) then
					local isTransmogable, isKnown, anotherCharacter = Addon:GetKnownTransmogInfo(itemLink);
					
					if(isTransmogable) then
						if(not isKnown) then
							rarityBorder.transmogrifyAsterisk:Show();
							
							if(not anotherCharacter) then
								rarityBorder.transmogrifyAsterisk.iconSelf:Show();
								rarityBorder.transmogrifyAsterisk.iconOther:Hide();
							else
								rarityBorder.transmogrifyAsterisk.iconOther:Show();
								rarityBorder.transmogrifyAsterisk.iconSelf:Hide();
							end
						end
					end
				end
				
				local shouldColorize = false;
				local color = { 0.6, 0.0, 0.0 };
				
				if(Addon.db.global.PaintArmorTypes) then
					if(isUsable and itemType == LOCALIZED_ARMOR and Addon:IsArmorItemSlot(itemEquipLoc)) then
						if(itemSubType ~= LOCALIZED_COSMETIC and not Addon:IsValidClassArmorType(itemSubType)) then
							shouldColorize = true;
						end
					end
				end
				
				if(Addon.db.global.PaintKnownItems and Addon:IsItemKnown(itemLink)) then
					shouldColorize = true;
					color = {
						Addon.db.global.PaintColor.r,
						Addon.db.global.PaintColor.g,
						Addon.db.global.PaintColor.b
					};
				end
				
				if(shouldColorize) then
					local r, g, b = unpack(color);
					SetItemButtonNameFrameVertexColor(merchantButton, r, g, b);
					SetItemButtonSlotVertexColor(merchantButton, r, g, b);
					SetItemButtonTextureVertexColor(itemButton, r, g, b);
					SetItemButtonNormalTextureVertexColor(itemButton, r, g, b);
				end
			end
		end
	end
	
	-------------------------------
	
	local buyBackItemButton = _G["MerchantBuyBackItemItemButton"];
	local buyBackRarityBorder = _G["VendorerMerchantBuyBackItemRarity"];
	if(buyBackRarityBorder) then
		buyBackRarityBorder:Hide();
		
		if(not buyBackItemButton.rarityBorder) then
			buyBackItemButton.rarityBorder = buyBackRarityBorder;
			
			buyBackItemButton:HookScript("OnEnter", function(self)
				self.rarityBorder.highlight:Show();
			end)
			
			buyBackItemButton:HookScript("OnLeave", function(self)
				self.rarityBorder.highlight:Hide();
			end);
		end
		
		local buybackitem = GetBuybackItemLink(GetNumBuybackItems());
		if(buybackitem) then
			local _, _, rarity, _, reqLevel, itemType, itemSubType, _, itemEquipLoc = GetItemInfo(buybackitem);
			
			if(rarity and rarity >= 1) then
				local r, g, b = GetItemQualityColor(rarity);
				local a = 0.9;
				if(rarity == 1) then a = 0.75 end
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
	for i=1, BUYBACK_ITEMS_PER_PAGE do
		local itemButton = _G["MerchantItem"..i.."ItemButton"];
		
		local rarityBorder = _G["VendorerMerchantItem"..i.."Rarity"];
		if(rarityBorder) then
			rarityBorder:Hide();
			rarityBorder.transmogrifyAsterisk:Hide();
		end
		
		if(not itemButton.rarityBorder) then
			itemButton.rarityBorder = rarityBorder;
			
			itemButton:HookScript("OnEnter", function(self)
				self.rarityBorder.highlight:Show();
			end)
			
			itemButton:HookScript("OnLeave", function(self)
				self.rarityBorder.highlight:Hide();
			end);
		end
		
		local link = GetBuybackItemInfo(i);
		if(link) then
			local _, _, rarity = GetItemInfo(link);
			if(rarity and rarity >= 1) then
				local r, g, b = GetItemQualityColor(rarity);
				local a = 0.9;
				if(rarity == 1) then a = 0.75 end
				rarityBorder.border:SetVertexColor(r, g, b, a);
				rarityBorder.highlight:SetVertexColor(r, g, b);
				rarityBorder:Show();
			end
		end
	end
end
