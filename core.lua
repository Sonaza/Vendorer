local ADDON_NAME, SHARED = ...;

local _G = getfenv(0);

local LibStub = LibStub;
local Addon = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceEvent-3.0");
local AceDB = LibStub("AceDB-3.0");
_G[ADDON_NAME] = Addon;
_G["Vendorer"] = Addon;
SHARED[1] = Addon;

local CLASS_ARMOR_TYPES = {
	WARRIOR     = "Plate",
	PALADIN     = "Plate",
	DEATHKNIGHT = "Plate",
	HUNTER      = "Mail",
	SHAMAN      = "Mail",
	MONK        = "Leather",
	DRUID       = "Leather",
	ROGUE       = "Leather",
	DEMONHUNTER = "Leather",
	MAGE        = "Cloth",
	WARLOCK     = "Cloth",
	PRIEST      = "Cloth",
};

local ARMOR_TYPE_LEVEL = {
	["Cloth"]	= 1,
	["Leather"]	= 2,
	["Mail"]	= 3,
	["Plate"]	= 4,
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

StaticPopupDialogs["VENDORER_CONFIRM_SELL_UNUSABLES"] = {
	text = "Are you sure you want to sell unusable items? You can still buyback them after.",
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
		Addon.db.global.ItemIgnoreList = {};
		Addon:AddMessage("Ignore list wiped.");
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

local MESSAGE_PATTERN = "|cffe8608fVendorer|r %s";
function Addon:AddMessage(pattern, ...)
	DEFAULT_CHAT_FRAME:AddMessage(MESSAGE_PATTERN:format(string.format(pattern, ...)));
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

function Addon:OnInitialize()
	local defaults = {
		global = {
			MerchantFrameExtended = true,
			AutoSellJunk = false,
			PaintArmorTypes = true,
			
			AutoRepair = false,
			SmartAutoRepair = true,
			
			ItemIgnoreList = {},
			ItemJunkList = {},
		},
	};
	
	self.db = AceDB:New("VendorerDB", defaults);
	
end

function Addon:RestoreSavedSettings()
	Addon:UpdateExtensionToggleButton();
	VendorerAutoSellJunkButton:SetChecked(self.db.global.AutoSellJunk);
	VendorerArmorPaintRedButton:SetChecked(self.db.global.PaintArmorTypes);
	
	VendorerAutoRepairButton:SetChecked(self.db.global.AutoRepair);
	VendorerAutoSmartRepairButton:SetChecked(self.db.global.SmartAutoRepair);
end

function Addon:OnEnable()
	Addon:RegisterEvent("MERCHANT_SHOW");
	Addon:RegisterEvent("MERCHANT_CLOSED");
	Addon:RegisterEvent("CURSOR_UPDATE");
	Addon:RegisterEvent("UPDATE_INVENTORY_DURABILITY");
	
	Addon.PlayerMoney = GetMoney();
	
	Addon:EnhanceMerchantFrame();
	
	Addon:RestoreSavedSettings();

	hooksecurefunc("PickupContainerItem", function()
		VendorerIgnoreItemsButtonHighlight:Show();
		VendorerAddItemsButtonHighlight:Show();
	end);
end

function Addon:CURSOR_UPDATE()
	if(GetCursorInfo() ~= "item") then
		VendorerIgnoreItemsButtonHighlight:Hide();
		VendorerAddItemsButtonHighlight:Hide();
	end
end

function Addon:EnhanceMerchantFrame()
	MerchantNextPageButton:ClearAllPoints();
	MerchantNextPageButton:SetPoint("LEFT", MerchantPrevPageButton, "RIGHT", 94, 0);
	
	MerchantPageText:SetWidth(164);
	MerchantPageText:ClearAllPoints();
	MerchantPageText:SetPoint("LEFT", MerchantNextPageButton, "RIGHT", 0, 0);
	MerchantPageText:SetJustifyH("CENTER");
	
	MerchantExtraCurrencyInset:ClearAllPoints();
	MerchantExtraCurrencyInset:SetPoint("BOTTOMRIGHT", MerchantFrame, "BOTTOMRIGHT", -169, 4);
	MerchantExtraCurrencyInset:SetPoint("TOPLEFT", MerchantFrame, "BOTTOMRIGHT", -169-163, 27);
	
	MerchantExtraCurrencyBg:ClearAllPoints();
	MerchantExtraCurrencyBg:SetPoint("BOTTOMRIGHT", MerchantFrame, "BOTTOMRIGHT", -169-3, 6);
	MerchantExtraCurrencyBg:SetPoint("TOPLEFT", MerchantFrame, "BOTTOMRIGHT", -169-163, 25);
end

function Addon:UpdateExtensionToggleButton()
	if(Addon.db.global.MerchantFrameExtended) then
		VendorerToggleExtensionFrameButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
		VendorerToggleExtensionFrameButton:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
		Addon:ShowExtensionPanel();
	else
		VendorerToggleExtensionFrameButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
		VendorerToggleExtensionFrameButton:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
		Addon:HideExtensionPanel();
	end
end

function Addon:ShowExtensionPanel()
	MerchantFrame:SetWidth(500);
	VendorerMerchantFrameExtension:Show();
	VendorerExtensionFrameItems:Show();
end

function Addon:HideExtensionPanel()
	MerchantFrame:SetWidth(336);
	VendorerMerchantFrameExtension:Hide();
	VendorerExtensionFrameItems:Hide();
end

function VendorerToggleExtensionFrameButton_OnClick(self, button)
	Addon.db.global.MerchantFrameExtended = not Addon.db.global.MerchantFrameExtended;
	Addon:UpdateExtensionToggleButton();
end

function VendorerCheckButtonTemplate_OnLoad(self)
	local text = _G[self:GetName() .. "Text"];
	if(text) then
		text:SetText(self:GetText());
		text:SetFontObject("VendorerButtonFont");
	end
end

function VendorerCheckButtonTemplate_OnEnter(self)
	if(self.tooltip) then
		GameTooltip:ClearAllPoints();
		GameTooltip:SetOwner(self, "ANCHOR_PRESERVE");
		GameTooltip:SetPoint("LEFT", self, "RIGHT", 130, 0);
		
		if(type(self.tooltip) == "string") then
			GameTooltip:AddLine(self.tooltip, nil, nil, nil, true);
			
		elseif(type(self.tooltip) == "table") then
			for _, line in pairs(self.tooltip) do
				GameTooltip:AddLine(line, nil, nil, nil, true);
			end
			
		elseif(type(self.tooltip) == "function") then
			self.tooltip();
		end
		
		GameTooltip:Show();
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

function Addon:GetItemTooltipInfo(item)
	if(not item) then return end
	
	local bindType, isUsable, isClassArmorType, notUsableReason;
	
	local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount,
		itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(item);
		
	VendorerTooltip:SetOwner(UIParent, "ANCHOR_NONE");
	VendorerTooltip:SetHyperlink(itemLink);
	
	if(IsEquippableItem(itemLink) and Addon:IsArmorItemSlot(itemEquipLoc)) then
		if(itemSubType == "Cosmetic" or itemSubType == "Miscellaneous" or Addon:IsValidClassArmorType(itemSubType)) then
			isClassArmorType = true;
		else
			isClassArmorType = false;
		end
		
	end
	
	local numLines = VendorerTooltip:NumLines();
	
	isUsable = true;
	
	local tooltipItemSlot, tooltipItemType;
	tooltipItemSlot = itemEquipLoc ~= "" and _G[itemEquipLoc] or nil;
	
	if(isClassArmorType == false) then
		notUsableReason = NOT_USABLE_CLASS_TYPE;
		isUsable = false;
	end
	
	for row = 2, numLines do
		local wasUsable = isUsable;
		
		local left = _G["VendorerTooltipTextLeft" .. row];
		local right = _G["VendorerTooltipTextRight" .. row];
		
		if(not bindType) then
			bindType = Addon:ScanBindType(left:GetText());
		end
		
		if(IsEquippableItem(itemLink)) then
			if(left:GetText() == itemType and Addon:IsRedText(left)) then
				if(isUsable and not notUsableReason) then notUsableReason = NOT_USABLE_TYPE end
				isUsable = false;
			end
			
			if(right and (right:GetText() == itemSubType or row <= 6)) then
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
	end
	
	if(not tooltipItemType and IsEquippableItem(itemLink)) then
		tooltipItemType = itemSubType;
	end
	
	if(not bindType) then bindType = BT_UNKNOWN end
	if(isUsable == nil) then isUsable = true; end
	
	return bindType, isUsable, isClassArmorType, notUsableReason, tooltipItemSlot, tooltipItemType, itemSubType;
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

function VendorerIgnoreItemsButton_OnEnter(self)
	GameTooltip:ClearAllPoints();
	GameTooltip:SetOwner(self, "ANCHOR_PRESERVE");
	GameTooltip:SetPoint("TOPLEFT", self, "RIGHT", 0, 70);
	
	GameTooltip:AddLine("Ignoring Items from Auto Sell");
	GameTooltip:AddLine("|cffffffffYou can drag items here from inventory|nto add or remove them from the ignore list.");
	GameTooltip:AddLine(" ");
	GameTooltip:AddLine("|cffffffffIgnored items will not be automatically sold.");
	
	local ignored = {};
	for itemID, _ in pairs(Addon.db.global.ItemIgnoreList) do
		local _, link = GetItemInfo(itemID);
		tinsert(ignored, link);
	end
	
	local numIgnoredItems = #ignored;
	if(numIgnoredItems > 0) then
		GameTooltip:AddLine(" ");
		GameTooltip:AddLine("|cffffcc00Shift Right-Click |cffffffffWipe the ignore list");
		GameTooltip:AddLine(" ");
		GameTooltip:AddLine(string.format("%d Ignored Items", numIgnoredItems));
		
		for index, link in pairs(ignored) do
			GameTooltip:AddLine(link);
			
			if(index >= 15 and numIgnoredItems > 15) then
				GameTooltip:AddLine(string.format("+ %d more", numIgnoredItems-15));
				break;
			end
		end
	end
	
	self.text:SetFontObject("VendorerButtonFontHighlight");
	
	GameTooltip:Show();
	
	if(IsMouseButtonDown("LeftButton")) then
		self:SetScript("OnUpdate", function(self)
			if(not IsMouseButtonDown("LeftButton")) then
				VendorerIgnoreItemsButton_IgnoreItem(self);
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

function VendorerIgnoreItemsButton_OnClick(self, button)
	if(button == "LeftButton") then
		VendorerIgnoreItemsButton_IgnoreItem(self);
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

function Addon:GetItemID(itemLink)
	if(not itemLink) then return end
	
	local item_id = strmatch(itemLink, "item:(%d+)");
	return item_id and tonumber(item_id) or nil;
end

function VendorerIgnoreItemsButton_IgnoreItem(self)
	local cursor, _, itemLink = GetCursorInfo();
	if(cursor == "item" and itemLink) then
		local item_id = Addon:GetItemID(itemLink);
		
		if(not Addon.db.global.ItemIgnoreList[item_id]) then
			Addon.db.global.ItemIgnoreList[item_id] = true;
			Addon:AddMessage(string.format("%s added to ignore list.", itemLink));
		else
			Addon.db.global.ItemIgnoreList[item_id] = nil;
			Addon:AddMessage(string.format("%s removed from ignore list.", itemLink));
		end
		ClearCursor();
	end
	
	VendorerIgnoreItemsButton_OnEnter(VendorerIgnoreItemsButton);
end

function VendorerAddItemsButton_OnEnter(self)
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
	
	local numIgnoredItems = #items;
	if(numIgnoredItems > 0) then
		GameTooltip:AddLine(" ");
		GameTooltip:AddLine("|cffffcc00Shift Right-Click |cffffffffWipe the junk sell list");
		GameTooltip:AddLine(" ");
		GameTooltip:AddLine(string.format("%d Junk Items", numIgnoredItems));
		
		for index, link in pairs(items) do
			GameTooltip:AddLine(link);
			
			if(index >= 15 and numIgnoredItems > 15) then
				GameTooltip:AddLine(string.format("+ %d more", numIgnoredItems-15));
				break;
			end
		end
	end
	
	self.text:SetFontObject("VendorerButtonFontHighlight");
	
	GameTooltip:Show();
	
	if(IsMouseButtonDown("LeftButton")) then
		self:SetScript("OnUpdate", function(self)
			if(not IsMouseButtonDown("LeftButton")) then
				VendorerAddItemsButton_AddItem(self);
				self:SetScript("OnUpdate", nil);
			end
		end);
	end
end

function VendorerAddItemsButton_OnLeave(self)
	self.text:SetFontObject("VendorerButtonFont");
	
	GameTooltip:Hide();
	self:SetScript("OnUpdate", nil);
end

function VendorerAddItemsButton_OnClick(self, button)
	if(button == "LeftButton") then
		VendorerAddItemsButton_AddItem(self);
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

function VendorerAddItemsButton_AddItem(self)
	local cursor, _, itemLink = GetCursorInfo();
	if(cursor == "item" and itemLink) then
		local item_id = Addon:GetItemID(itemLink);
		
		if(not Addon.db.global.ItemJunkList[item_id]) then
			Addon.db.global.ItemJunkList[item_id] = true;
			Addon:AddMessage(string.format("%s added to junk sell list.", itemLink));
		else
			Addon.db.global.ItemJunkList[item_id] = nil;
			Addon:AddMessage(string.format("%s removed from junk sell list.", itemLink));
		end
		ClearCursor();
	end
	
	VendorerAddItemsButton_OnEnter(VendorerAddItemsButton);
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

-----------------------------

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

-----------------------------

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

function VendorerArmorPaintRedButton_OnClick(self)
	Addon.db.global.PaintArmorTypes = self:GetChecked();
	MerchantFrame_UpdateMerchantInfo();
end

function VendorerAutoRepairButton_OnClick(self)
	Addon.db.global.AutoRepair = self:GetChecked();
	-- if(Addon.db.global.AutoRepair) then
	-- 	Addon:DoAutoRepair();
	-- end
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
end

function Addon:UPDATE_INVENTORY_DURABILITY()
	local repairAllCost, canRepair = GetRepairAllCost();
	if(not canRepair) then
		SetDesaturation(VendorerSmartRepairButtonIcon, true);
		VendorerSmartRepairButton:Disable();
	else
		SetDesaturation(VendorerSmartRepairButtonIcon, false);
		VendorerSmartRepairButton:Enable();
	end
end

hooksecurefunc("MerchantFrame_UpdateRepairButtons", function()
	if(CanMerchantRepair() and CanGuildBankRepair()) then
		MerchantRepairAllButton:SetPoint("BOTTOMRIGHT", MerchantFrame, "BOTTOMLEFT", 83, 29)
		VendorerSmartRepairButton:Show();
		
		local repairAllCost, canRepair = GetRepairAllCost();
		if(not canRepair) then
			SetDesaturation(VendorerSmartRepairButtonIcon, true);
			VendorerSmartRepairButton:Disable();
		else
			SetDesaturation(VendorerSmartRepairButtonIcon, false);
			VendorerSmartRepairButton:Enable();
		end
	else
		VendorerSmartRepairButton:Hide();
	end
end);

function VendorerSmartRepairButton_OnEnter(self)
	local playerMoney, guildMoney = Addon:GetAutoRepairCost(true);
	
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:AddLine("Smart Repair Items");
	GameTooltip:AddLine("Repair items by maximizing the guild bank repairs.", 1, 1, 1);
	GameTooltip:AddLine(" ");
	
	if(guildMoney > 0) then
		GameTooltip:AddLine("The Guild Bank Covers");
		SetTooltipMoney(GameTooltip, guildMoney, "GUILD_REPAIR");
	end
	
	if(playerMoney > 0) then
		GameTooltip:AddLine("You Cover");
		SetTooltipMoney(GameTooltip, playerMoney, "GUILD_REPAIR");
	end
	
	if(playerMoney == 0 and guildMoney == 0) then
		GameTooltip:AddLine(" ");
		GameTooltip:AddLine("All of your items have full durability.");
	end
	
	GameTooltip:AddLine(" ");
	local amount = GetGuildBankWithdrawMoney();
	local guildBankMoney = GetGuildBankMoney();
	if ( amount == -1 ) then
		-- Guild leader shows full guild bank amount
		amount = guildBankMoney;
	else
		amount = min(amount, guildBankMoney);
	end
	GameTooltip:AddLine(GUILDBANK_REPAIR, nil, nil, nil, true);
	SetTooltipMoney(GameTooltip, amount, "GUILD_REPAIR");
	
	GameTooltip:Show();
end

function VendorerSmartRepairButton_OnLeave(self)
	GameTooltip:Hide();
end

function VendorerSmartRepairButton_OnClick(self)
	Addon:DoAutoRepair(true);
	
	GameTooltip:Hide();
	VendorerSmartRepairButton_OnEnter(self);
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
end

hooksecurefunc("MerchantFrame_UpdateMerchantInfo", function()
	if(not Addon.db.global.PaintArmorTypes) then return end
	
	local numMerchantItems = GetMerchantNumItems();
	
	for i=1, MERCHANT_ITEMS_PER_PAGE, 1 do
		local index = (((MerchantFrame.page - 1) * MERCHANT_ITEMS_PER_PAGE) + i);
		local itemButton = _G["MerchantItem"..i.."ItemButton"];
		local merchantButton = _G["MerchantItem"..i];
		
		local rarityBorder = _G["VendorerMerchantItem"..i.."Rarity"];
		if(rarityBorder) then
			rarityBorder:Hide();
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
			local link = GetMerchantItemLink(index);
			if(link) then
				local _, _, _, _, _, isUsable = GetMerchantItemInfo(index);
				local _, _, rarity, _, reqLevel, itemType, itemSubType, _, itemEquipLoc = GetItemInfo(link);
				
				if(rarity and rarity >= 1) then
					local r, g, b = GetItemQualityColor(rarity);
					local a = 0.9;
					if(rarity == 1) then a = 0.75 end
					rarityBorder.border:SetVertexColor(r, g, b, a);
					rarityBorder.highlight:SetVertexColor(r, g, b);
					rarityBorder:Show();
				end
				
				if(isUsable and itemType == "Armor" and Addon:IsArmorItemSlot(itemEquipLoc)) then
					if(itemSubType ~="Cosmetic" and not Addon:IsValidClassArmorType(itemSubType)) then
						SetItemButtonNameFrameVertexColor(merchantButton, 0.5, 0, 0);
						SetItemButtonSlotVertexColor(merchantButton, 0.5, 0, 0);
						SetItemButtonTextureVertexColor(itemButton, 0.5, 0, 0);
						SetItemButtonNormalTextureVertexColor(itemButton, 0.5, 0, 0);
					end
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
end);

hooksecurefunc("MerchantFrame_UpdateBuybackInfo", function()
	local numBuybackItems = GetNumBuybackItems();
	local itemButton, buybackButton;
	local buybackName, buybackTexture, buybackPrice, buybackQuantity, buybackNumAvailable, buybackIsUsable;
	for i=1, BUYBACK_ITEMS_PER_PAGE do
		local itemButton = _G["MerchantItem"..i.."ItemButton"];
		
		local rarityBorder = _G["VendorerMerchantItem"..i.."Rarity"];
		if(rarityBorder) then
			rarityBorder:Hide();
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
end);

function Addon:Announce(str)
	Addon:AddMessage(str);
	
	if(Parrot) then
		Parrot:ShowMessage(str, "Errors", false);
	end
end