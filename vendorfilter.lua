------------------------------------------------------------
-- Vendorer by Sonaza
-- All rights reserved
-- http://sonaza.com
------------------------------------------------------------

local ADDON_NAME, Addon = ...;
local _;

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
	if(not index) then return end
	
	if(FilteredMerchantItems[index]) then
		local value = _GameTooltip_SetMerchantItem(self, FilteredMerchantItems[index]);
		if(Addon.db.global.UseImprovedStackSplit) then
			local _, _, _, stack = _GetMerchantItemInfo(FilteredMerchantItems[index]);
			if(stack <= 1) then
				GameTooltip:AddLine(ITEM_VENDOR_STACK_BUY, 0, 1, 0);
			end
		end
		return value;
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

local ITEM_LINK_TYPE_ITEM        = 0x1;
local ITEM_LINK_TYPE_CURRENCY    = 0x2;
local ITEM_LINK_TYPE_BATTLEPET   = 0x3;
local ITEM_LINK_TYPE_UNKNOWN     = 0xF;

local ITEM_LINK_TYPES = {
	["item"]        = ITEM_LINK_TYPE_ITEM,
	["currency"]    = ITEM_LINK_TYPE_CURRENCY,
	["battlepet"]   = ITEM_LINK_TYPE_BATTLEPET,
	[0]             = ITEM_LINK_TYPE_UNKNOWN,
}

function Addon:GetItemLinkInfo(itemLink)
	if(not itemLink) then return end
	local itemType, itemID = itemLink:match("|H(.-):(%d+)");
	return ITEM_LINK_TYPES[itemType or 0] or ITEM_LINK_TYPE_UNKNOWN, tonumber(itemID), itemType;
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

local cachedStrings = {};
function Addon:MakeTooltipString(itemLink)
	if(not itemLink) then return "" end
	if(cachedStrings[itemLink]) then return cachedStrings[itemLink] end
	
	VendorerTooltip:Hide();
	VendorerTooltip:SetOwner(UIParent, "ANCHOR_NONE", 99999, 0);
	VendorerTooltip:SetHyperlink(itemLink);
	local numLines = VendorerTooltip:NumLines();
	
	local string = "";
	
	for line = 2, numLines do
		local left = _G["VendorerTooltipTextLeft" .. line];
		local right = _G["VendorerTooltipTextRight" .. line];
		
		if(left and left:GetText()) then
			string = string .. " " .. strtrim(left:GetText());
		end
		
		if(right and right:GetText()) then
			string = string .. " " .. strtrim(right:GetText());
		end
	end
	
	cachedStrings[itemLink] = strtrim(string.lower(string));
	return cachedStrings[itemLink];
end

function Addon:GenerateTokens(text)
	local tokens = {};
	
	local openQuote = false;
	for _, token in pairs({ strsplit(" ", text) }) do
		local isNegated = (string.sub(token, 1, 1) == "-" or string.sub(token, 1, 1) == "!");
		local token = isNegated and string.sub(token, 2) or token;
		
		if(not openQuote and string.match(token, "%b\"\"")) then
			tinsert(tokens, {
				negated = isNegated,
				token = string.sub(token, 2, -2),
			});
		elseif(not openQuote and string.sub(token, 1, 1) == "\"") then
			openQuote = true;
			tinsert(tokens, {
				negated = isNegated,
				token = string.sub(token, 2),
			});
		elseif(openQuote and string.sub(token, -1) == "\"") then
			openQuote = false;
			tokens[#tokens].token = tokens[#tokens].token .. " " .. string.sub(token, 0, -2);
		elseif(openQuote) then
			tokens[#tokens].token = tokens[#tokens].token .. " " .. token;
		else
			tinsert(tokens, {
				negated = isNegated,
				token = token,
			});
		end
	end
	
	return tokens;
end

Addon.FilterText = "";
function Addon:FilterItem(index)
	if(Addon.FilterText == "") then return true end
	
	local itemLink = _GetMerchantItemLink(index);
	if(not itemLink) then return true end
	
	local itemLinkTypeID, itemID, itemLinkType = Addon:GetItemLinkInfo(itemLink);
	
	local itemName, texture, price, quantity, numAvailable, isUsable, extendedCost = _GetMerchantItemInfo(index);
	local equippable = IsEquippableItem(itemLink);
	
	local _, _, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, _, itemEquipLoc = GetItemInfo(itemLink);
	
	local qualityText = string.lower(_G["ITEM_QUALITY" .. (itemRarity or 1) .. "_DESC"]);
	
	local equipSlot = nil;
	if(itemEquipLoc and itemEquipLoc ~= "") then
		equipSlot = string.lower(_G[itemEquipLoc]);
	end
	
	if(price == 0 and extendedCost) then
		price = nil;
	end
	
	local filter = true;
	
	local tokens = Addon:GenerateTokens(Addon.FilterText);
	for _, tokenData in pairs(tokens) do
		-- Escape the search token so it doesn't do regex queries
		local token = string.gsub(tokenData.token, "[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1");
		
		local matchFound = false;
		local result = false;
		
		-- Magic words, check them first so there is no false matches
		result = result or (token == "usable" and isUsable);
		result = result or (token == "unusable" and not isUsable);
		result = result or (token == "equippable" and equippable);
		result = result or (token == "unequippable" and not equippable);
		result = result or (token == "available" and numAvailable ~= 0);
		
		if(not result) then
			local known = Addon:IsItemKnown(itemLink);
			result = result or (token == "known" and known);
			result = result or (token == "unknown" and not known);
		end
		
		if(not result) then
			local totalCoppers = Addon:ParseGoldString(token);
			for _, comparison in ipairs(VALUE_FILTERS) do
				local value = strmatch(token, comparison.pattern);
				if(value ~= nil) then
					value = tonumber(value);
					
					if(comparison.type == VALUE_TYPE_ITEM_ID and value and itemID) then
						matchFound = true;
						result = comparison.func(itemID, value);
						
					elseif(comparison.type == VALUE_TYPE_RLVL and value and itemMinLevel) then
						matchFound = true;
						result = comparison.func(itemMinLevel, value);
						
					elseif(comparison.type == VALUE_TYPE_ILVL and value and itemLevel) then
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
				result = result or strfind(qualityText, token) ~= nil;
				
				result = result or (itemLinkType and strfind(string.lower(itemLinkType), token) ~= nil);
				
				result = result or (itemType and strfind(string.lower(itemType), token) ~= nil);
				result = result or (itemSubType and strfind(string.lower(itemSubType), token) ~= nil);
				result = result or (equipSlot and strfind(equipSlot, token) ~= nil);
				
				if(not result and extendedCost) then
					local numCostItems = _GetMerchantItemCostInfo(index);
					for costItemIndex = 1, numCostItems do
						local _, costItemValue, costItemLink, currencyName = _GetMerchantItemCostItem(index, costItemIndex);
						if(costItemLink) then
							result = result or strfind(string.lower(costItemLink), token) ~= nil;
						elseif(currencyName) then
							result = result or strfind(string.lower(currencyName), token) ~= nil;
						end
					end
				end
				
				-- Tooltip search only if nothing has been matched yet
				if(not result and Addon.db.global.UseTooltipSearch) then
					local tooltipString = Addon:MakeTooltipString(itemLink);
					result = strfind(string.lower(tooltipString), token) ~= nil;
				end
			end
		end
		
		if(not tokenData.negated) then
			filter = filter and result;
		else
			filter = filter and not result;
		end
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

function Vendorer_OnSearchTextChanged(self)
	Addon.UpdatedFilteringTime = GetTime();
	
	SearchBoxTemplate_OnTextChanged(self);
	Addon:RefreshFilter();
end

function Addon:RefreshFilter()
	if(VendorerStackSplitFrame:IsPurchasing()) then
		VendorerStackSplitFrame:CancelPurchase();
		Addon:AddMessage("Pending bulk purchase canceled due to filtering change.");
	end
	
	Addon.FilterText = string.trim(string.lower(VendorerFilterEditBox:GetText()));
	MerchantFrame.page = 1;
	Addon:UpdateMerchantItems();
end

hooksecurefunc("MerchantFrame_SetFilter", function()
	if(VendorerStackSplitFrame:IsPurchasing()) then
		VendorerStackSplitFrame:CancelPurchase();
		Addon:AddMessage("Pending bulk purchase canceled due to filtering change.");
	end
	
	Addon:UpdateMerchantItems();
end);

hooksecurefunc("MerchantFrame_Update", function()
	if(MerchantFrame.selectedTab == 1) then
		Addon:UpdateExtensionPanel();
		MerchantFrameLootFilter:SetPoint("TOPRIGHT", MerchantFrame, "TOPRIGHT", -35, -28);
		VendorerToggleExtensionFrameButtons:Show();
	else
		MerchantFrame_UpdateBuybackInfo();
		Addon:HideExtensionPanel();
		MerchantFrameLootFilter:SetPoint("TOPRIGHT", MerchantFrame, "TOPRIGHT", 0, -28);
		VendorerToggleExtensionFrameButtons:Hide();
		VendorerStackSplitFrame:Cancel();
	end
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

local NEW_FEATURE_ICON = "|TInterface\\OptionsFrame\\UI-OptionsFrame-NewFeatureIcon:12:12:0:0:|t";
function VendorerFilterTipsButton_OnEnter()
	VendorerHintTooltip:ClearLines();
	
	VendorerHintTooltip:SetPoint("TOPLEFT", VendorerFilterTipsButton, "TOPRIGHT", -7, 50);
	VendorerHintTooltip:SetOwner(VendorerFilterTipsButton, "ANCHOR_PRESERVE");
	
	VendorerHintTooltip:AddLine("|cffffffffVendorer Filtering Tips|r");
	VendorerHintTooltip:AddLine(" ");
	if(Addon.db.global.UseTooltipSearch) then
		VendorerHintTooltip:AddLine("You can search by item name, rarity, type, slot, required currency or " .. NEW_FEATURE_ICON .. "tooltip text.", nil, nil, nil, true);
	else
		VendorerHintTooltip:AddLine("You can search by item name, rarity, type, slot or required currency. Searching by " .. NEW_FEATURE_ICON .. "tooltip text is currently disabled.", nil, nil, nil, true);
	end
	VendorerHintTooltip:AddLine(" ");
	VendorerHintTooltip:AddLine(NEW_FEATURE_ICON .. "You can also search for phrases by putting the words in quotes. The results will only include items with the words in the same order as the ones inside the quotes.", nil, nil, nil, true);
	VendorerHintTooltip:AddLine(" ");
	VendorerHintTooltip:AddLine(NEW_FEATURE_ICON .. "Any and all filters can also be negated by prefixing the query word or phrase with |cffffffff! (an exclamation mark)|r.", nil, nil, nil, true);
	VendorerHintTooltip:AddLine(" ");
	VendorerHintTooltip:AddLine("In addition to that you can search by other criteria.");
	VendorerHintTooltip:AddLine(" ");
	VendorerHintTooltip:AddLine(NEW_FEATURE_ICON .. "|cffffffffMagic words|r");
	VendorerHintTooltip:AddLine("Predefined magic words: |cffffffffusable, unusable, equippable, unequippable, known, unknown, available|r.", nil, nil, nil, true);
	VendorerHintTooltip:AddLine(" ");
	VendorerHintTooltip:AddLine("|cffffffffBy Item ID|r");
	VendorerHintTooltip:AddLine("Prefix a number with letters |cffffffffid|r. For example |cffffffffid|cfff361946948|r.", nil, nil, nil, true); 
	VendorerHintTooltip:AddLine(" ");
	VendorerHintTooltip:AddLine("|cffffffffBy Required Level|r");
	VendorerHintTooltip:AddLine("Prefix a number with the letter |cffffffffr|r. For example |cffffffffr|cfff3619492|r.", nil, nil, nil, true);
	VendorerHintTooltip:AddLine(" ");
	VendorerHintTooltip:AddLine("|cffffffffBy Item Level|r");
	VendorerHintTooltip:AddLine("Prefix a number with the letter |cffffffffi|r. For example |cffffffffi|cfff36194200|r.", nil, nil, nil, true);
	VendorerHintTooltip:AddLine(" ");
	VendorerHintTooltip:AddLine("|cffffffffBy Price|r");
	VendorerHintTooltip:AddLine("Enter a price value formatted like |cffffffff12|rg|cffffffff34|rs|cffffffff56|rc.", nil, nil, nil, true);
	VendorerHintTooltip:AddLine(" ");
	VendorerHintTooltip:AddLine("|cffffffffSearching for Ranges of Values|r");
	VendorerHintTooltip:AddLine("Search values can be prefixed with |cffffffff>, >=, <|r and |cffffffff<=|r to search for ranges of values.", nil, nil, nil, true);
	VendorerHintTooltip:AddLine(" ");
	VendorerHintTooltip:AddLine("For example |cffffffff>=r|cfff3619490|r will find all items that require level higher than or equal to 90.", nil, nil, nil, true);
	VendorerHintTooltip:AddLine(" ");
	VendorerHintTooltip:AddLine("Another example |cffffffff>=|cfff36194250g|r |cffffffff<=|cfff36194500g|r will find all items that cost between 250 and 500 gold.", nil, nil, nil, true);
	
	VendorerHintTooltip:SetMinimumWidth(250);
	VendorerHintTooltip:SetWidth(250);
	VendorerHintTooltip:SetScale(0.9);
	VendorerHintTooltip:Show();
end

function VendorerFilterTipsButton_OnLeave()
	VendorerHintTooltip:Hide();
end
