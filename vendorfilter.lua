local ADDON_NAME, SHARED = ...;
local _;
local Addon = unpack(SHARED);

local FilteredMerchantItems = nil;

local _BuyMerchantItem 			= _G.BuyMerchantItem;
local _PickupMerchantItem		= _G.PickupMerchantItem;
local _ShowMerchantSellCursor	= _G.ShowMerchantSellCursor;
local _GetMerchantItemCostInfo 	= _G.GetMerchantItemCostInfo;
local _GetMerchantItemCostItem 	= _G.GetMerchantItemCostItem;
local _GetMerchantItemInfo 		= _G.GetMerchantItemInfo;
local _GetMerchantItemLink 		= _G.GetMerchantItemLink;
local _GetMerchantItemMaxStack 	= _G.GetMerchantItemMaxStack;
local _GetMerchantNumItems 		= _G.GetMerchantNumItems;

local _GameTooltip_SetMerchantItem = GameTooltip.SetMerchantItem;
local _GameTooltip_SetMerchantCostItem = GameTooltip.SetMerchantCostItem;

GameTooltip.SetMerchantItem = function(self, index)
	-- print("GameTooltip.SetMerchantItem", index)
	
	if(not index) then return end
	
	if(FilteredMerchantItems[index]) then
		return _GameTooltip_SetMerchantItem(self, FilteredMerchantItems[index]);
	end
end

GameTooltip.SetMerchantCostItem = function(self, index, item)
	if(not index) then return end
	
	if(FilteredMerchantItems[index]) then
		return _GameTooltip_SetMerchantCostItem(self, FilteredMerchantItems[index], item);
	end
end

_G.BuyMerchantItem = function(index, amount)
	if(not index) then return end
	
	if(not FilteredMerchantItems[index]) then Addon:RefreshFilteredItems(); end
	return _BuyMerchantItem(FilteredMerchantItems[index], amount);
end

_G.PickupMerchantItem = function(index)
	if(not index) then
		_PickupMerchantItem(index);
	end
	
	if(not FilteredMerchantItems[index]) then Addon:RefreshFilteredItems(); end
	if(FilteredMerchantItems[index]) then
		return _PickupMerchantItem(FilteredMerchantItems[index]);
	else
		return _PickupMerchantItem(index);
	end
end

_G.ShowMerchantSellCursor = function(index)
	if(not index) then return end
	
	if(not FilteredMerchantItems[index]) then Addon:RefreshFilteredItems(); end
	if(FilteredMerchantItems[index]) then
		return _ShowMerchantSellCursor(FilteredMerchantItems[index]);
	end
end

_G.GetMerchantItemCostInfo = function(index)
	if(not index) then return end
	
	if(not FilteredMerchantItems[index]) then Addon:RefreshFilteredItems(); end
	return _GetMerchantItemCostInfo(FilteredMerchantItems[index]);
end

_G.GetMerchantItemCostItem = function(index, itemIndex)
	if(not index) then return end
	
	if(not FilteredMerchantItems[index]) then Addon:RefreshFilteredItems(); end
	return _GetMerchantItemCostItem(FilteredMerchantItems[index], itemIndex);
end

_G.GetMerchantItemInfo = function(index)
	-- index)
	
	if(not index) then return end
	
	if(not FilteredMerchantItems[index]) then Addon:RefreshFilteredItems(); end
	return _GetMerchantItemInfo(FilteredMerchantItems[index]);
end

_G.GetMerchantItemLink = function(index)
	if(not index) then return end
	
	if(not FilteredMerchantItems[index]) then Addon:RefreshFilteredItems(); end
	if(FilteredMerchantItems[index]) then
		return _GetMerchantItemLink(FilteredMerchantItems[index]);
	end
end

_G.GetMerchantItemMaxStack = function(index)
	if(not index) then return end
	
	if(not FilteredMerchantItems[index]) then Addon:RefreshFilteredItems(); end
	return _GetMerchantItemMaxStack(FilteredMerchantItems[index]);
end

_G.GetMerchantNumItems = function()
	if(not FilteredMerchantItems) then Addon:RefreshFilteredItems(); end
	return #FilteredMerchantItems;
end

local GOLD_PRICE_PATTERN = "(%d+)g";
local SILVER_PRICE_PATTERN = "(%d?%d)s";
local COPPER_PRICE_PATTERN = "(%d?%d)c";

function Addon:ParseGoldString(str)
	local money = str;
	
	local gold = strmatch(money, GOLD_PRICE_PATTERN);
	gold = gold and tonumber((gsub(gold, "%D", "")));
	
	local silver = strmatch(money, SILVER_PRICE_PATTERN);
	silver = silver and tonumber((gsub(silver, "%D", "")));
	
	local copper = strmatch(money, COPPER_PRICE_PATTERN);
	copper = copper and tonumber((gsub(copper, "%D", "")));
	
	if(not gold and not silver and not copper) then return nil; end
	
	local total = (gold or 0) * 10000 + 
				  math.min(99, silver or 0) * 100 +
				  math.min(99, copper or 0);
	
	return total, gold, silver, copper;
end

local GT_PATTERN = ">";
local GTE_PATTERN = ">=";
local LT_PATTERN = "<";
local LTE_PATTERN = "<=";

local MONEY_EQ_PATTERN = "(.+)g?s?c?";
local MONEY_GT_PATTERN  = GT_PATTERN .. MONEY_EQ_PATTERN;
local MONEY_GTE_PATTERN = GTE_PATTERN .. MONEY_EQ_PATTERN;
local MONEY_LT_PATTERN  = LT_PATTERN .. MONEY_EQ_PATTERN;
local MONEY_LTE_PATTERN = LTE_PATTERN .. MONEY_EQ_PATTERN;

local ILVL_EQ_PATTERN  = "i(%d+)";
local ILVL_GT_PATTERN  = GT_PATTERN .. ILVL_EQ_PATTERN;
local ILVL_GTE_PATTERN = GTE_PATTERN .. ILVL_EQ_PATTERN;
local ILVL_LT_PATTERN  = LT_PATTERN .. ILVL_EQ_PATTERN;
local ILVL_LTE_PATTERN = LTE_PATTERN .. ILVL_EQ_PATTERN;

local RLVL_EQ_PATTERN  = "r(%d+)";
local RLVL_GT_PATTERN  = GT_PATTERN .. RLVL_EQ_PATTERN;
local RLVL_GTE_PATTERN = GTE_PATTERN .. RLVL_EQ_PATTERN;
local RLVL_LT_PATTERN  = LT_PATTERN .. RLVL_EQ_PATTERN;
local RLVL_LTE_PATTERN = LTE_PATTERN .. RLVL_EQ_PATTERN;

local ITEMID_PATTERN  = "id(%d+)";

local COMPARISONS = {
	GT  = function(a, b) return a > b end,
	GTE = function(a, b) return a >= b end,
	LT  = function(a, b) return a < b end,
	LTE = function(a, b) return a <= b end,
	EQ  = function(a, b) return a == b end,
};

local VALUE_TYPE_ITEM_ID 	= 1;
local VALUE_TYPE_RLVL 		= 2;
local VALUE_TYPE_ILVL 		= 3;
local VALUE_TYPE_MONEY 		= 4;

local VALUE_FILTERS = {
	{ type = VALUE_TYPE_ITEM_ID, pattern = ITEMID_PATTERN, func = COMPARISONS.EQ },

	{ type = VALUE_TYPE_RLVL, pattern = RLVL_GTE_PATTERN, func = COMPARISONS.GTE },
	{ type = VALUE_TYPE_RLVL, pattern = RLVL_LTE_PATTERN, func = COMPARISONS.LTE },
	{ type = VALUE_TYPE_RLVL, pattern = RLVL_GT_PATTERN,  func = COMPARISONS.GT },
	{ type = VALUE_TYPE_RLVL, pattern = RLVL_LT_PATTERN,  func = COMPARISONS.LT },
	{ type = VALUE_TYPE_RLVL, pattern = RLVL_EQ_PATTERN,  func = COMPARISONS.EQ },
	
	{ type = VALUE_TYPE_ILVL, pattern = ILVL_GTE_PATTERN, func = COMPARISONS.GTE },
	{ type = VALUE_TYPE_ILVL, pattern = ILVL_LTE_PATTERN, func = COMPARISONS.LTE },
	{ type = VALUE_TYPE_ILVL, pattern = ILVL_GT_PATTERN,  func = COMPARISONS.GT },
	{ type = VALUE_TYPE_ILVL, pattern = ILVL_LT_PATTERN,  func = COMPARISONS.LT },
	{ type = VALUE_TYPE_ILVL, pattern = ILVL_EQ_PATTERN,  func = COMPARISONS.EQ },
	
	{ type = VALUE_TYPE_MONEY, pattern = MONEY_GTE_PATTERN, func = COMPARISONS.GTE },
	{ type = VALUE_TYPE_MONEY, pattern = MONEY_LTE_PATTERN, func = COMPARISONS.LTE },
	{ type = VALUE_TYPE_MONEY, pattern = MONEY_GT_PATTERN,  func = COMPARISONS.GT },
	{ type = VALUE_TYPE_MONEY, pattern = MONEY_LT_PATTERN,  func = COMPARISONS.LT },
	{ type = VALUE_TYPE_MONEY, pattern = MONEY_EQ_PATTERN,  func = COMPARISONS.EQ },
};

Addon.FilterText = "";
function Addon:FilterItem(index)
	if(Addon.FilterText == "") then return true end
	
	local itemLink = _GetMerchantItemLink(index);
	if(not itemLink) then return true end
	
	local itemName, texture, price, quantity, numAvailable, isUsable, extendedCost = _GetMerchantItemInfo(index);
	local _, _, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, _, itemEquipLoc = GetItemInfo(itemLink);
	
	local item_id = strmatch(itemLink, "item:(%d+)");
	item_id = item_id and tonumber(item_id) or "";
	
	local qualityText = string.lower(_G["ITEM_QUALITY" .. itemRarity .. "_DESC"]);
	local equipSlot = itemEquipLoc ~= "" and string.lower(_G[itemEquipLoc]) or nil;
	
	if(price == 0 and extendedCost) then
		price = nil;
	end
	
	local filter = true;
	
	local tokens = { strsplit(" ", Addon.FilterText) };
	for _, token in pairs(tokens) do
		local matchFound = false;
		local result = true;
		
		local totalCoppers = Addon:ParseGoldString(token);
		
		for _, comparison in ipairs(VALUE_FILTERS) do
			local value = strmatch(token, comparison.pattern);
			if(value ~= nil) then
				value = tonumber(value);
				
				if(comparison.type == VALUE_TYPE_ITEM_ID and value) then
					matchFound = true;
					result = comparison.func(item_id, value);
					
				elseif(comparison.type == VALUE_TYPE_RLVL and value) then
					matchFound = true;
					result = comparison.func(itemMinLevel, value);
					
				elseif(comparison.type == VALUE_TYPE_ILVL and value) then
					-- print(token, comparison.pattern, itemLevel, value);
					
					matchFound = true;
					result = comparison.func(itemLevel, value);
					
				elseif(comparison.type == VALUE_TYPE_MONEY and totalCoppers) then
					matchFound = true;
					if(price) then
						result = comparison.func(price, totalCoppers);
					else
						result = false;
					end
				end
			end
			
			if(matchFound) then break end
		end
		
		if(not matchFound) then
			result = strfind(string.lower(itemName), token) ~= nil;
			result = result or strfind(string.lower(itemType), token) ~= nil;
			result = result or strfind(string.lower(itemSubType), token) ~= nil;
			result = result or strfind(qualityText, token) ~= nil;
			if(equipSlot) then
				result = result or strfind(equipSlot, token) ~= nil;
			end
			
			if(extendedCost) then
				local numCostItems = _GetMerchantItemCostInfo(index);
				for costItemIndex = 1, numCostItems do
					local _, costItemValue, costItemLink, currencyName = _GetMerchantItemCostItem(index, costItemIndex);
					if(costItemLink) then
						-- local itemName = strmatch(costItemLink, "%[(.+)%]");
						-- if(itemName) then
							result = result or strfind(string.lower(costItemLink), token) ~= nil;
						-- end
					elseif(currencyName) then
						result = result or strfind(string.lower(currencyName), token) ~= nil;
					end
				end
			end
			
			filter = filter and result;
		end
		
		if(matchFound) then filter = filter and result; end
	end
	
	return filter;
end

function Addon:GetUnfilteredMerchantNumItems()
	return _GetMerchantNumItems();
end

function Addon:RefreshFilteredItems()
	FilteredMerchantItems = {};
	
	local merchantItems = Addon:GetUnfilteredMerchantNumItems();
	for index = 1, merchantItems do 
		if(Addon.FilterText == "" or Addon:FilterItem(index)) then
			tinsert(FilteredMerchantItems, index);
		end
	end
end

function Addon:UpdateMerchantItems()
	Addon:RefreshFilteredItems();
	MerchantFrame_Update();
end

function Addon:ResetFilter()
	Addon.FilterText = "";
	VendorerFilterEditBox:SetText("");
	SearchBoxTemplate_OnTextChanged(VendorerFilterEditBox);
	
	Addon:UpdateMerchantItems();
end

function Addon:ResetAllFilters()
	Addon.FilterText = "";
	FilteredMerchantItems = nil;
end

function Addon:RefreshFilter()
	Addon.FilterText = string.trim(string.lower(VendorerFilterEditBox:GetText()));
	MerchantFrame.page = 1;
	Addon:UpdateMerchantItems();
end

Addon.NoResultsLength = -1;
function Vendorer_OnSearchTextChanged(self)
	SearchBoxTemplate_OnTextChanged(self);
	
	local filterLength = strlen(VendorerFilterEditBox:GetText());
	Addon:RefreshFilter();
end

hooksecurefunc("MerchantFrame_SetFilter", function()
	Addon:UpdateMerchantItems();
end);

hooksecurefunc("MerchantFrame_Update", function()
	if(MerchantFrame.selectedTab == 1) then
		MerchantFrame_UpdateMerchantInfo();
		Addon:UpdateExtensionPanel();
		MerchantFrameLootFilter:SetPoint("TOPRIGHT", MerchantFrame, "TOPRIGHT", -35, -28);
		VendorerToggleExtensionFrameButtons:Show();
	else
		MerchantFrame_UpdateBuybackInfo();
		Addon:HideExtensionPanel();
		MerchantFrameLootFilter:SetPoint("TOPRIGHT", MerchantFrame, "TOPRIGHT", 0, -28);
		VendorerToggleExtensionFrameButtons:Hide();
	end
end);

hooksecurefunc("MerchantFrame_UpdateMerchantInfo", function()
	local numMerchantItems = GetMerchantNumItems();
	local realNumMerchantItems = _GetMerchantNumItems();
	local maxPages = math.ceil(numMerchantItems / MERCHANT_ITEMS_PER_PAGE);
	
	if(maxPages <= 1) then
		MerchantPageText:SetFormattedText("%d/%d items", numMerchantItems, realNumMerchantItems);
	else
		MerchantPageText:SetFormattedText("Page %d/%d  %d/%d items",
			MerchantFrame.page, maxPages, numMerchantItems, realNumMerchantItems);
	end
	
	MerchantPageText:Show();
end);

function VendorerFilterEditBox_OnEnter(self)
	self.hovering = true;
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:AddLine("Filter Merchant Items");
	GameTooltip:AddLine("Enter query to filter merchant goods.", 1, 1, 1);
	GameTooltip:Show();
end

function VendorerFilterEditBox_OnLeave(self)
	GameTooltip:Hide();
	self.hovering = false;
end

function VendorerFilterTipsButton_OnEnter()
	VendorerHintTooltip:ClearLines();
	
	VendorerHintTooltip:SetPoint("TOPLEFT", VendorerFilterTipsButton, "TOPRIGHT", -7, 22);
	VendorerHintTooltip:SetOwner(VendorerFilterTipsButton, "ANCHOR_PRESERVE");
	
	VendorerHintTooltip:AddLine("|cffffffffVendorer Filtering Tips|r");
	VendorerHintTooltip:AddLine(" ");
	VendorerHintTooltip:AddLine("You can search by item name, rarity, type, slot or|nrequired currency.");
	VendorerHintTooltip:AddLine(" ");
	VendorerHintTooltip:AddLine("In addition to that you can search by other criteria.");
	VendorerHintTooltip:AddLine(" ");
	VendorerHintTooltip:AddLine("|cffffffffBy Item ID|r");
	VendorerHintTooltip:AddLine("Prefix a number with letters |cffffffffid|r. For example |cffffffffid|cfff361946948|r."); 
	VendorerHintTooltip:AddLine(" ");
	VendorerHintTooltip:AddLine("|cffffffffBy Required Level|r");
	VendorerHintTooltip:AddLine("Prefix a number with the letter |cffffffffr|r. For example |cffffffffr|cfff3619492|r.");
	VendorerHintTooltip:AddLine(" ");
	VendorerHintTooltip:AddLine("|cffffffffBy Item Level|r");
	VendorerHintTooltip:AddLine("Prefix a number with the letter |cffffffffi|r. For example |cffffffffi|cfff36194200|r.");
	VendorerHintTooltip:AddLine(" ");
	VendorerHintTooltip:AddLine("|cffffffffBy Price|r");
	VendorerHintTooltip:AddLine("Enter a price value formatted like |cffffffff12|rg|cffffffff34|rs|cffffffff56|rc.");
	VendorerHintTooltip:AddLine(" ");
	VendorerHintTooltip:AddLine("|cffffffffSearching for Ranges of Values|r");
	VendorerHintTooltip:AddLine("Search values can be prefixed with |cffffffff>, >=, <|r and |cffffffff<=|r");
	VendorerHintTooltip:AddLine("to search for ranges of values.");
	VendorerHintTooltip:AddLine(" ");
	VendorerHintTooltip:AddLine("For example |cffffffff>=r|cfff3619490|r will find all items");
	VendorerHintTooltip:AddLine("that require level higher than or equal to 90.");
	VendorerHintTooltip:AddLine(" ");
	VendorerHintTooltip:AddLine("Another example |cffffffff>=|cfff36194250g|r |cffffffff<=|cfff36194500g|r will find all");
	VendorerHintTooltip:AddLine("items that cost between 250 and 500 gold.");
	
	VendorerHintTooltip:SetWidth(240);
	VendorerHintTooltip:Show();
end

function VendorerFilterTipsButton_OnLeave()
	VendorerHintTooltip:Hide();
end