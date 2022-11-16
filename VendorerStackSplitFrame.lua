------------------------------------------------------------
-- Vendorer by Sonaza (https://sonaza.com)
-- Licensed under MIT License
-- See attached license text in file LICENSE
------------------------------------------------------------

local ADDON_NAME, Addon = ...;
local _;

local MAX_STACK_SIZE = 1000000;

-- Apparently some currencies can't be used to buy anything other than the specified stack size
local CURRENCY_CANT_SPLIT = {
	[1220] = true, -- Order Resources
};

local cachedCurrencies = nil;
local function CacheCurrencies()
	if (cachedCurrencies) then return end
	cachedCurrencies = {};

	-- Super dirty indexing for currencies
	for currencyIndex = 1, 20000 do
		local info = C_CurrencyInfo.GetCurrencyInfo(currencyIndex);
		if (info and strlen(info.name) > 0) then
			cachedCurrencies[info.name] = currencyIndex;
		end
	end
end

VendorerStackSplitMixin = {
	split = 1,
};

StaticPopupDialogs["VENDORER_CONFIRM_PURCHASE_TOKEN_ITEM"] = {
	text = CONFIRM_PURCHASE_TOKEN_ITEM,
	button1 = YES,
	button2 = NO,
	OnAccept = function()
		VendorerStackSplitFrame:DoPurchase();
	end,
	OnCancel = function()
		VendorerStackSplitFrame.waiting:Hide();
	end,
	OnShow = function()
		VendorerStackSplitFrame.okayButton:Disable();
	end,
	OnHide = function()
		VendorerStackSplitFrame.okayButton:Enable();
	end,
	timeout = 0,
	hideOnEscape = 1,
	hasItemFrame = 1,
}

StaticPopupDialogs["VENDORER_CONFIRM_PURCHASE_NONREFUNDABLE_ITEM"] = {
	text = CONFIRM_PURCHASE_NONREFUNDABLE_ITEM,
	button1 = YES,
	button2 = NO,
	OnAccept = function()
		VendorerStackSplitFrame:DoPurchase();
	end,
	OnCancel = function()
		VendorerStackSplitFrame.waiting:Hide();
	end,
	OnShow = function()
		VendorerStackSplitFrame.okayButton:Disable();
	end,
	OnHide = function()
		VendorerStackSplitFrame.okayButton:Enable();
	end,
	timeout = 0,
	hideOnEscape = 1,
	hasItemFrame = 1,
}

StaticPopupDialogs["VENDORER_CONFIRM_HIGH_COST_ITEM"] = {
	text = CONFIRM_HIGH_COST_ITEM,
	button1 = YES,
	button2 = NO,
	OnAccept = function()
		VendorerStackSplitFrame:DoPurchase();
	end,
	OnCancel = function()
		VendorerStackSplitFrame.waiting:Hide();
	end,
	OnShow = function(self)
		MoneyFrame_Update(self.moneyFrame, MerchantFrame.price * MerchantFrame.count);
		VendorerStackSplitFrame.okayButton:Disable();
	end,
	OnHide = function()
		VendorerStackSplitFrame.okayButton:Enable();
	end,
	timeout = 0,
	hideOnEscape = 1,
	hasMoneyFrame = 1,
	hasItemFrame = 1,
};

function VendorerStackSplitMixin:OnHide()
	self.itemButton.hasStackSplit = 0;

	if (self.dialog and self.dialog:IsVisible()) then
		self.dialog:Hide();
	end
	self.dialog = nil;

	self.waiting:Hide();
end

function VendorerStackSplitMixin:Decrement()
	if (self.purchasing) then return end
	self.split = math.max(self.minSplit, self.split - self.minSplit);
	self:Update();
end

function VendorerStackSplitMixin:Increment()
	if (self.purchasing) then return end
	self.split = math.min(self.maxPurchase, self.split + self.minSplit);
	self:Update();
end

function VendorerStackSplitMixin:Update()
	self.split = math.max(self.minSplit, math.min(self.maxPurchase, self.split));

	if (self.split == self.minSplit) then
		self.leftButton:Disable();
	else
		self.leftButton:Enable();
	end

	if (self.split == self.maxPurchase) then
		self.rightButton:Disable();
	else
		self.rightButton:Enable();
	end

	if (self.canAfford == 1) then
		self.setMax:Disable();
	else
		self.setMax:Enable();
	end

	local numItems = self.split;
	if (self.maxStack > 1) then
		self.splitNumber:SetText(("%s |cff777777/ %d|r"):format(BreakUpLargeNumbers(numItems), self.maxStack));
	else
		self.splitNumber:SetText(BreakUpLargeNumbers(numItems));
	end

	self.totalCost:SetText(self:GetTotalPriceString());
end

local ICON_PATTERN = "|T%s:12:12:0:0|t";
function VendorerStackSplitMixin:GetTotalPriceString(index, quantity)
	index = index or self.merchantItemIndex;
	quantity = quantity or self.split;

	local text = "";

	local _, _, price, stackCount, _, _, _, extendedCost = GetMerchantItemInfo(index);
	if (price and price > 0) then
		local totalPrice = math.ceil((price / stackCount) * quantity);
		text = ("%s %s "):format(text, GetCoinTextureString(totalPrice, 12));
	end

	if (extendedCost) then
		local currencyCount = GetMerchantItemCostInfo(index);
		for currencyIndex = 1, currencyCount do
			local itemTexture, requiredCurrency = GetMerchantItemCostItem(index, currencyIndex);
			local totalPrice = (requiredCurrency / stackCount) * quantity;
			text = ("%s %s%s"):format(text, BreakUpLargeNumbers(totalPrice), ICON_PATTERN:format(itemTexture));
		end
	end

	return strtrim(text);
end

function VendorerStackSplitMixin:Okay()
	if (self.purchasing) then return end

	self.waiting:Show();

	if (self.itemButton.extendedCost) then
		self:ConfirmExtendedItemCost(self.itemButton, self.split);
	elseif (self.itemButton.showNonrefundablePrompt) then
		self:ConfirmExtendedItemCost(self.itemButton, self.split);
	elseif (self.split > 0) then
		if (self.split > self.maxStack) then
			self:ConfirmHighCostItem(self.itemButton, self.split);
		else
			BuyMerchantItem(self.merchantItemIndex, self.split);
			self:Cancel();
		end
	end
end

function VendorerStackSplitMixin:ConfirmExtendedItemCost(itemButton, numToPurchase)
	local stackCount = itemButton.count or 1;
	numToPurchase = numToPurchase or stackCount;

	local index = itemButton:GetID();
	local buyingMultipleStacks = numToPurchase > self.maxStack;

	if (GetMerchantItemCostInfo(index) == 0 and not itemButton.showNonrefundablePrompt) then
		if (buyingMultipleStacks) then
			self:ConfirmHighCostItem(itemButton, numToPurchase);
		else
			BuyMerchantItem(itemButton:GetID(), numToPurchase);
		end
		return;
	end

	self.purchaseInfo = {
		remaining = numToPurchase,
		itemIndex = index,
		stackSize = self.maxStack,
	};
	MerchantFrame.itemIndex = index;
	MerchantFrame.count = numToPurchase;

	local itemsString = self:GetTotalPriceString(index, numToPurchase);

	local itemName;
	local itemQuality = 1;
	local _;
	local r, g, b = 1, 1, 1;
	local specs = {};
	if (itemButton.link) then
		itemName, _, itemQuality = GetItemInfo(itemButton.link);
	end

	if (itemName) then
		--It's an item
		r, g, b = GetItemQualityColor(itemQuality);
		specs = GetItemSpecInfo(itemButton.link, specs);
	else
		--Not an item. Could be currency or something. Just use what's on the button.
		itemName = itemButton.name;
		r, g, b = GetItemQualityColor(1);
	end

	local specText;
	if (specs and #specs > 0) then
		local specName, specIcon;
		specText = "\n\n";
		for i = 1, #specs do
			_, specName, _, specIcon = GetSpecializationInfoByID(specs[i], UnitSex("player"));
			specText = specText .. " |T" .. specIcon .. ":0:0:0:-1|t " .. NORMAL_FONT_COLOR_CODE ..
				specName .. FONT_COLOR_CODE_CLOSE;
			if (i < #specs) then
				specText = specText .. PLAYER_LIST_DELIMITER
			end
		end
	else
		specText = "";
	end

	local itemInfo = {
		["texture"] = itemButton.texture, ["name"] = itemName, ["color"] = { r, g, b, 1 },
		["link"] = itemButton.link, ["index"] = index, ["count"] = numToPurchase
	};

	if (itemButton.showNonrefundablePrompt) then
		self.dialog = StaticPopup_Show("VENDORER_CONFIRM_PURCHASE_NONREFUNDABLE_ITEM", itemsString, specText, itemInfo);
	else
		self.dialog = StaticPopup_Show("VENDORER_CONFIRM_PURCHASE_TOKEN_ITEM", itemsString, specText, itemInfo);
	end
end

function VendorerStackSplitMixin:ConfirmHighCostItem(itemButton, quantity)
	local stackCount = itemButton.count or 1;

	quantity = (quantity or 1);
	local index = itemButton:GetID();
	local itemName, _, quality = GetItemInfo(itemButton.link);

	local r, g, b = GetItemQualityColor(quality);

	self.purchaseInfo = {
		remaining = quantity,
		itemIndex = index,
		stackSize = self.maxStack,
	};
	MerchantFrame.itemIndex = index;
	MerchantFrame.count = quantity;
	MerchantFrame.price = itemButton.price / stackCount;

	self.dialog = StaticPopup_Show("VENDORER_CONFIRM_HIGH_COST_ITEM",
		itemButton.link, nil,
		{
			["texture"] = itemButton.texture, ["name"] = itemName, ["color"] = { r, g, b, 1 },
			["link"] = itemButton.link, ["index"] = index, ["count"] = quantity
		}
	);
end

function VendorerStackSplitMixin:DoPurchase()
	if (self.purchasing) then return end
	if (not self.purchaseInfo) then
		error("Purchase info is missing", 2);
	end

	if (self.purchaseInfo.remaining > 0) then
		self.purchasing = true;
		self.purchaseIterations = 0;

		self:SetScript("OnChar", nil);
		self:SetScript("OnKeyDown", nil);

		self:RegisterEvent("BAG_UPDATE_DELAYED");
		self:RegisterEvent("CURRENCY_DISPLAY_UPDATE");
		local remaining = self:PurchaseNext();
	else
		self:Cancel();
	end
end

function VendorerStackSplitMixin:PurchaseNext()
	if (not self.purchasing) then return -1 end

	-- Number of stacks safe to purchase at a time (without causing "item is busy" errors)
	local maximumStacksToPurchase = 10;
	if (Addon.db.global.UseSafePurchase) then
		maximumStacksToPurchase = 1;
	end

	local remaining = math.min(self.purchaseInfo.remaining, maximumStacksToPurchase * self.purchaseInfo.stackSize);
	while (remaining > 0) do
		local quantity = math.min(remaining, self.purchaseInfo.stackSize);
		BuyMerchantItem(self.merchantItemIndex, quantity);

		remaining = remaining - quantity;
		self.purchaseInfo.remaining = self.purchaseInfo.remaining - quantity;
	end

	self.purchaseIterations = self.purchaseIterations + 1;

	return self.purchaseInfo.remaining;
end

function VendorerStackSplitMixin:IsPurchasing()
	return self.purchasing;
end

function VendorerStackSplitMixin:CancelPurchase()
	self.waiting:Hide();
	self.purchasing = false;
	self.purchaseInfo = nil;
	self:UnregisterEvent("BAG_UPDATE_DELAYED");
	self:UnregisterEvent("CURRENCY_DISPLAY_UPDATE");
	self:Cancel();
end

function VendorerStackSplitMixin:OnEvent(event, ...)
	if (self.purchaseInfo.remaining > 0) then
		local remaining = self:PurchaseNext();

		if (remaining <= 0) then
			self:CancelPurchase();

			if (self.purchaseIterations > 1) then
				C_Timer.After(0.5, function()
					Addon:AddMessage("Purchase finished.");
				end);
			end
		end
	else
		self:CancelPurchase();
	end
end

function VendorerStackSplitMixin:Cancel()
	self.waiting:Hide();
	self:Hide();
end

hooksecurefunc("MerchantPrevPageButton_OnClick", function() VendorerStackSplitFrame:Cancel() end);
hooksecurefunc("MerchantNextPageButton_OnClick", function() VendorerStackSplitFrame:Cancel() end);

function VendorerStackSplitFrameStackButton_OnClick(self, button)
	local threshold = VendorerStackSplitFrame.maxStack;
	if (IsControlKeyDown()) then
		threshold = math.floor(threshold * 0.25);
	end
	VendorerStackSplitFrame:Stack(button, threshold);
end

function VendorerStackSplitMixin:Stack(button_or_delta, threshold)
	if (self.purchasing) then return end

	threshold = math.max(1, math.min(self.maxStack, threshold or self.maxStack));

	if (button_or_delta == "LeftButton" or button_or_delta == 1) then
		self.split = math.ceil((self.split + self.minSplit) / threshold) * threshold;
	elseif (button_or_delta == "RightButton" or button_or_delta == -1) then
		self.split = math.floor((self.split - self.minSplit) / threshold) * threshold;
	end

	self:Update();
end

function VendorerStackSplitFrameStackButton_OnEnter(self)
	GameTooltip:SetOwner(VendorerStackSplitFrame, "ANCHOR_NONE");
	GameTooltip:SetPoint("TOPLEFT", VendorerStackSplitFrame, "TOPRIGHT", 5, 0);

	GameTooltip:AddLine("Stack");
	GameTooltip:AddLine("Increases or decreases current number of items a full stack at a time.", 1, 1, 1, true);
	GameTooltip:AddLine(" ");
	GameTooltip:AddLine("You can also do the same by holding down shift and using the mouse wheel. Holding down control instead uses quarter stack increments."
		, 1, 1, 1, true);
	GameTooltip:AddLine(" ");
	GameTooltip:AddLine("|cff00ff00Left-click|r  Increase by a full stack", 1, 1, 1, true);
	GameTooltip:AddLine("|cff00ff00Right-click|r  Decrease by a full stack", 1, 1, 1, true);
	GameTooltip:AddLine("|cff00ff00Hold Ctrl with either|r  By a quarter stack instead", 1, 1, 1, true);

	GameTooltip:Show();
end

function VendorerStackSplitMixin:SetMax(button)
	if (self.purchasing) then return end

	if (button == "LeftButton") then
		self.split = self.maxPurchase;
		if (IsControlKeyDown()) then
			self.split = math.floor(self.maxPurchase * 0.5);
		end
	elseif (button == "RightButton") then
		self.split = 1;
	end

	self:Update();
end

function VendorerStackSplitFrameSetMaxButton_OnEnter(self)
	GameTooltip:SetOwner(VendorerStackSplitFrame, "ANCHOR_NONE");
	GameTooltip:SetPoint("TOPLEFT", VendorerStackSplitFrame, "TOPRIGHT", 5, 0);

	local frame = VendorerStackSplitFrame;

	GameTooltip:AddLine("Set Max");
	GameTooltip:AddLine("Quickly set the number of items to the maximum you can fit, afford or are available.", 1, 1, 1,
		true);
	GameTooltip:AddLine(" ");
	if (frame.maxPurchase ~= MAX_STACK_SIZE) then
		if (frame.maxPurchase == frame.canFitItems) then
			GameTooltip:AddLine(("You can currently fit at most |cffffd200%s|r stacks or |cffffd200%s|r items."):format(frame.canFitStacks
				, BreakUpLargeNumbers(frame.canFitItems)), 1, 1, 1, true);
		elseif (frame.maxPurchase == frame.canAfford) then
			GameTooltip:AddLine(("You can currently afford at most |cffffd200%s|r items."):format(BreakUpLargeNumbers(frame.canAfford))
				, 1, 1, 1, true);
		elseif (frame.maxPurchase == frame.numCanBuyMore) then
			GameTooltip:AddLine(("You can currently hold at most |cffffd200%s|r items more."):format(BreakUpLargeNumbers(frame.numCanBuyMore))
				, 1, 1, 1, true);
		elseif (frame.maxPurchase == frame.numAvailable) then
			GameTooltip:AddLine(("There is up to |cffffd200%s|r items available."):format(BreakUpLargeNumbers(frame.numAvailable))
				, 1, 1, 1, true);
		end
		GameTooltip:AddLine(" ");
	end
	GameTooltip:AddLine("|cff00ff00Left-click|r  Set to maximum", 1, 1, 1, true);
	GameTooltip:AddLine("|cff00ff00Ctrl Left-click|r  Set to half", 1, 1, 1, true);
	GameTooltip:AddLine("|cff00ff00Right-click|r  Set to minimum", 1, 1, 1, true);

	GameTooltip:Show();
end

function VendorerStackSplitMixin:OnMouseWheel(delta)
	if (self.purchasing) then return end

	if (IsShiftKeyDown()) then
		self:Stack(delta);
	elseif (IsControlKeyDown()) then
		self:Stack(delta, self.maxStack * 0.25);
	else
		self.split = self.split + delta * self.minSplit;
		self:Update();
	end
end

function Addon:GetProperItemCount(item)
	if (not item) then return 0 end

	local _, itemLink = GetItemInfo(item);
	local itemCount = GetItemCount(itemLink);

	local numSlots = C_Container.GetContainerNumSlots(REAGENTBANK_CONTAINER);
	for slotIndex = 1, numSlots do
		local containerInfo = C_Container.GetContainerItemInfo(REAGENTBANK_CONTAINER, slotIndex);

		if (not containerInfo) then return itemCount; end

		if (itemLink and containerInfo.hyperlink == itemLink) then
			itemCount = itemCount + containerInfo.stackCount;
		end
	end

	return itemCount;
end

function VendorerStackSplitMixin:Open(merchantItemIndex, parent, anchor)
	if (self.purchasing) then return end

	self:SetScript("OnChar", self.OnChar);
	self:SetScript("OnKeyDown", self.OnKeyDown);

	CacheCurrencies();

	self.merchantItemIndex = merchantItemIndex;
	self.split = 1;

	local maxStack = GetMerchantItemMaxStack(merchantItemIndex);
	local _, _, price, stackCount, numAvailable, isPurchasable, _, extendedCost = GetMerchantItemInfo(merchantItemIndex);
	if (not isPurchasable) then return end

	local itemLink = GetMerchantItemLink(merchantItemIndex);

	self.minSplit = Addon:GetMinimumSplitSize(merchantItemIndex);
	self.split = stackCount or 1;

	if (numAvailable < 0) then numAvailable = MAX_STACK_SIZE end

	local isUnique = select(8, Addon:GetItemTooltipInfo(itemLink));
	if (isUnique) then return end

	local _, canAfford = Addon:CanAffordMerchantItem(merchantItemIndex, false);
	if (canAfford == 0) then return end

	self.numCanBuyMore = MAX_STACK_SIZE;

	local itemlink = GetMerchantItemLink(merchantItemIndex);
	if (Addon:IsCurrencyItem(itemlink)) then
		local _, info = Addon:GetCurrencyInfo(itemlink);
		if (info and info.maxQuantity > 0) then
			self.numCanBuyMore = info.maxQuantity - info.quantity;
		end
		if (info and info.maxWeeklyQuantity > 0) then
			self.numCanBuyMore = math.min(self.numCanBuyMore, info.maxWeeklyQuantity - info.quantityEarnedThisWeek);
		end
	end

	parent.hasStackSplit = 1;

	self.purchaseInfo = nil;

	self.itemButton   = parent;
	self.canAfford    = canAfford;
	self.maxStack     = maxStack;
	self.canFitStacks = Addon:GetFreeBagSlotsForItem(itemLink);
	self.canFitItems  = self.canFitStacks * maxStack;
	self.numAvailable = numAvailable;
	self.maxPurchase  = math.min(canAfford, self.canFitItems, numAvailable, self.numCanBuyMore, MAX_STACK_SIZE);
	self.maxPurchase  = self.maxPurchase - (self.maxPurchase % self.minSplit);
	self.typing       = false;

	self.hasExtendedCost = extendedCost;

	self:Update();

	self.okayButton:Enable();

	self:ClearAllPoints();
	self:SetPoint("BOTTOMLEFT", parent, "TOPLEFT", 0, 0);
	self:Show();
end

local _MerchantItemButton_OnModifiedClick = MerchantItemButton_OnModifiedClick;
function MerchantItemButton_OnModifiedClick(self, button)
	if (Addon.db.global.UseImprovedStackSplit) then
		local merchantItemIndex = self:GetID();
		if (MerchantFrame.selectedTab == 1) then
			-- Is merchant frame
			if (HandleModifiedItemClick(GetMerchantItemLink(merchantItemIndex))) then
				return;
			end
			if (IsModifiedClick("SPLITSTACK")) then
				local maxStack = GetMerchantItemMaxStack(merchantItemIndex);
				local _, _, price, stackCount, _, _, _, extendedCost = GetMerchantItemInfo(merchantItemIndex);

				VendorerStackSplitFrame:Open(merchantItemIndex, self);
				return;
			end
		else
			HandleModifiedItemClick(GetBuybackItemLink(merchantItemIndex));
		end
	else
		_MerchantItemButton_OnModifiedClick(self, button);
	end
end

function VendorerStackSplitMixin:OnChar(text)
	if (self.purchasing) then return end
	if (text < "0" or text > "9") then return end

	if (not self.typing) then
		self.typing = true;
		self.split = 0;
	end

	local split = (self.split * 10) + tonumber(text);
	if (split <= self.maxPurchase) then
		self.split = split;
	end

	self:Update();
end

function VendorerStackSplitMixin:OnKeyDown(key)
	if (key == "BACKSPACE" or key == "DELETE") then
		if (not self.typing or self.split == 1) then
			return;
		end

		self.split = floor(self.split / 10);
		if (self.split <= 1) then
			self.split = 1;
			self.typing = false;
		end
	elseif (key == "ENTER") then
		self:Okay();
	elseif (GetBindingFromClick(key) == "TOGGLEGAMEMENU") then
		self:Cancel();
	elseif (key == "LEFT" or key == "DOWN") then
		self:Decrement();
	elseif (key == "RIGHT" or key == "UP") then
		self:Increment();
	elseif (key == "PRINTSCREEN") then
		Screenshot();
	end

	self:Update();
end

function Addon:GetFreeBagSlotsForItem(item)
	if (not item) then return end

	local _, itemLink = GetItemInfo(item);
	local itemType = GetItemFamily(itemLink);

	local freeSlots = C_Container.GetContainerNumFreeSlots(0);

	for bagID = 1, NUM_BAG_SLOTS do
		local bagItemLink = C_Container.ContainerIDToInventoryID(bagID);
		if (bagItemLink) then
			local bagType = GetItemFamily(bagItemLink);
			if (not bagType or bagType == 0 or bagType == itemType or bit.band(itemType, bagType) == bagSubType) then
				freeSlots = freeSlots + C_Container.GetContainerNumFreeSlots(bagID);
			end
		end
	end

	return freeSlots;
end

function Addon:GetCurrencyInfo(currencyItemLink, currencyName)
	local currencyID = nil;
	if (currencyName) then
		CacheCurrencies();
		currencyID = cachedCurrencies[currencyName];
	elseif (currencyItemLink) then
		currencyID = strmatch(currencyItemLink, "currency:(%d+)");
	end
	if (currencyID) then
		local info = C_CurrencyInfo.GetCurrencyInfo(currencyID);
		if (info) then
			return tonumber(currencyID), info;
		end
	end
	return nil;
end

function Addon:CanAffordMerchantItem(merchantItemIndex, unfiltered)
	if (not merchantItemIndex) then return false end

	local GetMerchantItemLink     = GetMerchantItemLink;
	local GetMerchantItemInfo     = GetMerchantItemInfo;
	local GetMerchantItemCostItem = GetMerchantItemCostItem;
	local GetMerchantItemCostInfo = GetMerchantItemCostInfo;

	if (unfiltered) then
		GetMerchantItemLink     = Addon.BlizzFunctions.GetMerchantItemLink;
		GetMerchantItemInfo     = Addon.BlizzFunctions.GetMerchantItemInfo;
		GetMerchantItemCostItem = Addon.BlizzFunctions.GetMerchantItemCostItem;
		GetMerchantItemCostInfo = Addon.BlizzFunctions.GetMerchantItemCostInfo;
	end

	local name, _, price, stackCount, numAvailable, isPurchasable, _, hasExtendedCost = GetMerchantItemInfo(merchantItemIndex);
	if (not name) then return false end

	stackCount = stackCount or 1;

	local numCanAfford = MAX_STACK_SIZE;

	if (price and price > 0) then
		numCanAfford = floor(GetMoney() / (price / stackCount));
	end

	local costsUnsplittable = false;
	if (hasExtendedCost) then
		local extendedCanAfford = MAX_STACK_SIZE;
		local currencyCount = GetMerchantItemCostInfo(merchantItemIndex);
		for index = 1, currencyCount do
			local itemTexture, requiredCurrency, currencyItemLink, currencyName = GetMerchantItemCostItem(merchantItemIndex, index);
			local currencyPerUnit = requiredCurrency and requiredCurrency / stackCount or 1;

			local currencyID, info = Addon:GetCurrencyInfo(currencyItemLink, currencyName);
			if (currencyID and info.quantity) then
				costsUnsplittable = CURRENCY_CANT_SPLIT[currencyID] == true;
				extendedCanAfford = min(extendedCanAfford, floor(info.quantity / currencyPerUnit));
			else
				local ownedCurrencyItems = Addon:GetProperItemCount(currencyItemLink);
				extendedCanAfford = min(extendedCanAfford, floor(ownedCurrencyItems / currencyPerUnit));
			end
		end

		numCanAfford = min(numCanAfford, extendedCanAfford);
	end

	if (costsUnsplittable) then
		numCanAfford = numCanAfford - (numCanAfford % stackCount);
	end

	return numCanAfford > 0, numCanAfford, hasExtendedCost;
end

local function gcd(m, n)
	while n ~= 0 do
		local q = m;
		m = n;
		n = q % n;
	end
	return m;
end

function Addon:GetMinimumSplitSize(merchantItemIndex)
	if (not merchantItemIndex) then return 1 end

	local GetMerchantItemInfo     = GetMerchantItemInfo;
	local GetMerchantItemCostItem = GetMerchantItemCostItem;
	local GetMerchantItemCostInfo = GetMerchantItemCostInfo;

	local name, _, price, stackCount, _, _, _, hasExtendedCost = GetMerchantItemInfo(merchantItemIndex);
	if (not name) then return 1 end

	stackCount = stackCount or 1;
	if (stackCount <= 1) then return 1 end

	-- Items that only cost gold can be always split to 1 unit
	if (not hasExtendedCost and price) then return 1 end

	local minimumCurrencyAmount = 1;
	local currencyCount = GetMerchantItemCostInfo(merchantItemIndex);
	for index = 1, currencyCount do
		local _, requiredCurrency, currencyItemLink, currencyName = GetMerchantItemCostItem(merchantItemIndex, index);

		local currencyID = Addon:GetCurrencyInfo(currencyItemLink, currencyName);
		if (currencyID and CURRENCY_CANT_SPLIT[currencyID]) then
			return stackCount;
		end

		minimumCurrencyAmount = math.max(minimumCurrencyAmount, requiredCurrency);
	end

	return stackCount / gcd(stackCount, minimumCurrencyAmount);
end
