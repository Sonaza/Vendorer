------------------------------------------------------------
-- Vendorer by Sonaza
-- All rights reserved
-- http://sonaza.com
------------------------------------------------------------

local ADDON_NAME, Addon = ...;
local _;

local MAX_STACK_SIZE = 100000;

local cachedCurrencies = nil;
local function CacheCurrencies()
	if(cachedCurrencies) then return end
	cachedCurrencies = {};
	
	-- Super dirty indexing for currencies
	for currencyIndex = 1, 1600 do
		local name = GetCurrencyInfo(currencyIndex);
		if(name and strlen(name) > 0) then
			cachedCurrencies[name] = currencyIndex;
		end
	end
end

VendorerStackSplitMixin = {
	split = 1,
};

StaticPopupDialogs["VENDORER_CONFIRM_BIG_PURCHASE"] = {
	text = "Are you sure you want to buy|n|n%s x %s",
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		VendorerStackSplitFrame:DoPurchase();
	end,
	timeout = 0,
	hideOnEscape = true,
};

function VendorerStackSplitMixin:OnHide()
	self.owner.hasStackSplit = 0;
	
	if(self.dialog and self.dialog:IsVisible()) then
		self.dialog:Hide();
	end
	self.dialog = nil;
	
	if(self:IsPurchasing()) then
		self:CancelPurchase();
		Addon:Announce("Pending bulk purchase canceled due to merchant window being closed.");
	end
	self.waiting:Hide();
end

function VendorerStackSplitMixin:Decrement()
	if(self.purchasing) then return end
	self.split = math.max(1, self.split - 1);
	self:Update();
end

function VendorerStackSplitMixin:Increment()
	if(self.purchasing) then return end
	self.split = math.min(self.maxPurchase, self.split + 1);
	self:Update();
end

function VendorerStackSplitMixin:Update()
	self.split = math.max(1, math.min(self.maxPurchase, self.split));
	
	if(self.split == 1) then
		self.leftButton:Disable();
	else
		self.leftButton:Enable();
	end
	
	if(self.split == self.maxPurchase) then
		self.rightButton:Disable();
	else
		self.rightButton:Enable();
	end
	
	if(self.canAfford == 1) then
		self.setMax:Disable();
	else
		self.setMax:Enable();
	end
	
	local numItems = self.split;
	if(self.maxStack > 1) then
		self.splitNumber:SetText(("%s |cff777777/ %d|r"):format(BreakUpLargeNumbers(numItems), self.maxStack));
	else
		self.splitNumber:SetText(BreakUpLargeNumbers(numItems));
	end
	
	self.totalCost:SetText(self:GetTotalPriceString());
end

local ICON_PATTERN = "|T%s:12:12:0:0|t";
function VendorerStackSplitMixin:GetTotalPriceString()
	local text = "";
	
	local _, _, price, stackCount, _, _, extendedCost = GetMerchantItemInfo(self.merchantItemIndex);
	if(price and price > 0) then
		local totalPrice = (price / stackCount) * self.split;
		text = ("%s %s "):format(text, GetCoinTextureString(totalPrice, 12));
	end
	
	if(extendedCost) then
		local currencyCount = GetMerchantItemCostInfo(self.merchantItemIndex);
		for index = 1, currencyCount do
			local itemTexture, requiredCurrency = GetMerchantItemCostItem(self.merchantItemIndex, index);
			local totalPrice = (requiredCurrency / stackCount) * self.split;
			text = ("%s %s%s"):format(text, BreakUpLargeNumbers(totalPrice), ICON_PATTERN:format(itemTexture));
		end
	end
	
	return strtrim(text);
end

function VendorerStackSplitMixin:IsPurchasing()
	return self.purchasing;
end

function VendorerStackSplitMixin:CancelPurchase()
	self.waiting:Hide();
	self.purchasing = false;
	self.purchaseInfo = nil;
	self:UnregisterEvent("BAG_UPDATE_DELAYED");
	self:Cancel();
end

function VendorerStackSplitMixin:Okay()
	if(self.purchasing) then return end
	
	local _, icon, price, stackCount, _, _, extendedCost = GetMerchantItemInfo(self.merchantItemIndex);
	local itemLink = GetMerchantItemLink(self.merchantItemIndex);
	if(self.split > self.maxStack) then
		local priceString = self:GetTotalPriceString();
		self.dialog = StaticPopup_Show("VENDORER_CONFIRM_BIG_PURCHASE",
			BreakUpLargeNumbers(self.split),
			("%s %s?|n|nTotal Cost: %s"):format(ICON_PATTERN:format(icon), itemLink, priceString)
		);
	else
		if(self.owner.extendedCost) then
			MerchantFrame_ConfirmExtendedItemCost(self.owner, self.split)
		elseif(self.owner.showNonrefundablePrompt) then
			MerchantFrame_ConfirmExtendedItemCost(self.owner, self.split)
		elseif(self.split > 0) then
			BuyMerchantItem(self.merchantItemIndex, self.split);
		end
		self:Cancel();
	end
end

function VendorerStackSplitMixin:DoPurchase()
	if(self.purchasing) then return end
	
	if(Addon.db.global.UseSafePurchase) then
		self.purchasing = true;
		self.purchaseInfo = {
			remaining = self.split,
			itemIndex = self.merchantItemIndex,
			stackSize = self.maxStack,
		};
		
		self.waiting:Show();
		
		self:RegisterEvent("BAG_UPDATE_DELAYED");
		self:PurchaseNext();
	else
		local remaining = self.split;
		repeat
			local quantity = math.min(remaining, self.maxStack);
			BuyMerchantItem(self.merchantItemIndex, quantity);
			
			remaining = remaining - quantity;
		until(remaining <= 0);
	end
end

function VendorerStackSplitMixin:PurchaseNext()
	if(not self.purchasing) then return end
	
	local quantity = math.min(self.purchaseInfo.remaining, self.purchaseInfo.stackSize);
	if(quantity > 0) then
		BuyMerchantItem(self.purchaseInfo.itemIndex, quantity);
		self.purchaseInfo.remaining = self.purchaseInfo.remaining - quantity;
	else
		self.purchasing = false;
		self.purchaseInfo = nil;
	end
end

function VendorerStackSplitMixin:OnEvent(event, ...)
	self:PurchaseNext();
	if(not self.purchasing) then
		self:CancelPurchase();
	end
end

function VendorerStackSplitMixin:Cancel()
	self:Hide();
end

function VendorerStackSplitMixin:Stack(button_or_delta)
	if(self.purchasing) then return end
	
	if(button_or_delta == "LeftButton" or button_or_delta == 1) then
		self.split = math.ceil((self.split+1) / self.maxStack) * self.maxStack;
	elseif(button_or_delta == "RightButton" or button_or_delta == -1) then
		self.split = math.floor((self.split-1) / self.maxStack) * self.maxStack;
	end
	
	self:Update();
end

function VendorerStackSplitFrameStackButton_OnEnter(self)
	GameTooltip:SetOwner(VendorerStackSplitFrame, "ANCHOR_NONE");
	GameTooltip:SetPoint("TOPLEFT", VendorerStackSplitFrame, "TOPRIGHT", 5, 0);
	
	GameTooltip:AddLine("Stack");
	GameTooltip:AddLine("Increases or decreases current number of items a full stack at a time. You can also do the same by holding down shift and using the mouse wheel.", 1, 1, 1, true);
	GameTooltip:AddLine(" ");
	GameTooltip:AddLine("|cff00ff00Left-click|r  Increase by a full stack", 1, 1, 1, true);
	GameTooltip:AddLine("|cff00ff00Right-click|r  Decrease by a full stack", 1, 1, 1, true);
	
	GameTooltip:Show();
end

function VendorerStackSplitMixin:SetMax(button)
	if(self.purchasing) then return end
	
	if(button == "LeftButton") then
		self.split = self.maxPurchase;
	elseif(button == "RightButton") then
		self.split = 1;
	end
	
	self:Update();
end

function VendorerStackSplitFrameSetMaxButton_OnEnter(self)
	GameTooltip:SetOwner(VendorerStackSplitFrame, "ANCHOR_NONE");
	GameTooltip:SetPoint("TOPLEFT", VendorerStackSplitFrame, "TOPRIGHT", 5, 0);
	
	local frame = VendorerStackSplitFrame;
	
	GameTooltip:AddLine("Set Max");
	GameTooltip:AddLine("Quickly set the number of items to the maximum you can fit, afford or are available.", 1, 1, 1, true);
	GameTooltip:AddLine(" ");
	if(frame.maxPurchase == frame.canFitItems) then
		GameTooltip:AddLine(("You can currently fit at most |cffffd200%s|r stacks or |cffffd200%s|r items."):format(frame.canFitStacks, BreakUpLargeNumbers(frame.canFitItems)), 1, 1, 1, true);
	elseif(frame.maxPurchase == frame.canAfford) then
		GameTooltip:AddLine(("You can currently afford at most |cffffd200%s|r items."):format(BreakUpLargeNumbers(frame.canAfford)), 1, 1, 1, true);
	elseif(frame.maxPurchase == frame.numAvailable) then
		GameTooltip:AddLine(("There is up to |cffffd200%s|r items available."):format(BreakUpLargeNumbers(frame.numAvailable)), 1, 1, 1, true);
	end
	GameTooltip:AddLine(" ");
	GameTooltip:AddLine("|cff00ff00Left-click|r  Set to maximum", 1, 1, 1, true);
	GameTooltip:AddLine("|cff00ff00Right-click|r  Set to minimum", 1, 1, 1, true);
	
	GameTooltip:Show();
end

function VendorerStackSplitMixin:OnMouseWheel(delta)
	if(self.purchasing) then return end
	
	local value = delta;
	if(not IsShiftKeyDown()) then
		self.split = self.split + delta;
		self:Update();
	else
		self:Stack(delta);
	end
end

function Addon:GetProperItemCount(item)
	if(not item) then return 0 end
	
	local _, itemLink = GetItemInfo(item);
	local itemCount = GetItemCount(itemLink);
	
	local numSlots = GetContainerNumSlots(REAGENTBANK_CONTAINER);
	for slotIndex = 1, numSlots do
		local _, containerItemCount, _, _, _, _, containerItemLink = GetContainerItemInfo(REAGENTBANK_CONTAINER, slotIndex);
		if(itemLink and containerItemLink == itemLink) then
			itemCount = itemCount + containerItemCount;
		end
	end
	
	return itemCount;
end

function VendorerStackSplitMixin:Open(merchantItemIndex, parent, anchor)
	if(self.purchasing) then return end
	
	CacheCurrencies();
	
	self.merchantItemIndex = merchantItemIndex;
	self.split = 1;
	
	local maxStack = GetMerchantItemMaxStack(merchantItemIndex);
	local _, _, price, stackCount, numAvailable, _, extendedCost = GetMerchantItemInfo(merchantItemIndex);
	local itemLink = GetMerchantItemLink(merchantItemIndex);
	
	if(numAvailable < 0) then numAvailable = MAX_STACK_SIZE end
	
	local isUnique = select(8, Addon:GetItemTooltipInfo(itemLink));
	if(isUnique) then return end
	
	local canAfford = MAX_STACK_SIZE;
	if (price and price > 0) then
		canAfford = floor(GetMoney() / (price / stackCount));
	end
	if(extendedCost) then
		local extendedCanAfford = MAX_STACK_SIZE;
		local currencyCount = GetMerchantItemCostInfo(merchantItemIndex);
		for index = 1, currencyCount do
			local itemTexture, requiredCurrency, currencyItemLink, currencyName = GetMerchantItemCostItem(merchantItemIndex, index);
			if(currencyItemLink) then
				local ownedCurrencyItems = Addon:GetProperItemCount(currencyItemLink);
				extendedCanAfford = min(extendedCanAfford, floor(ownedCurrencyItems / requiredCurrency));
			elseif(currencyName) then
				local currencyID = cachedCurrencies[currencyName];
				local name, ownedCurrencyAmount = GetCurrencyInfo(currencyID);
				extendedCanAfford = min(extendedCanAfford, floor(ownedCurrencyAmount / requiredCurrency));
			end
		end
		
		canAfford = min(canAfford, extendedCanAfford);
	end
	if(canAfford == 0) then return end

	parent.hasStackSplit = 1;
	
	self.owner          = parent;
	self.canAfford      = canAfford;
	self.maxStack       = maxStack;
	self.canFitStacks   = Addon:GetFreeBagSlotsForItem(itemLink);
	self.canFitItems    = self.canFitStacks * maxStack;
	self.numAvailable   = numAvailable;
	self.maxPurchase    = math.min(canAfford, self.canFitItems, numAvailable, MAX_STACK_SIZE);
	self.typing         = false;
	
	self.hasExtendedCost = extendedCost;
	
	self:Update();
	
	self:ClearAllPoints();
	self:SetPoint("BOTTOMLEFT", parent, "TOPLEFT", 0, 0);
	self:Show();
end

local _MerchantItemButton_OnModifiedClick = MerchantItemButton_OnModifiedClick;
function MerchantItemButton_OnModifiedClick(self, button)
	if(Addon.db.global.UseImprovedStackSplit) then
		local merchantItemIndex = self:GetID();
		if(MerchantFrame.selectedTab == 1) then
			-- Is merchant frame
			if(HandleModifiedItemClick(GetMerchantItemLink(merchantItemIndex))) then
				return;
			end
			if(IsModifiedClick("SPLITSTACK")) then
				local maxStack = GetMerchantItemMaxStack(merchantItemIndex);
				local _, _, price, stackCount, _, _, extendedCost = GetMerchantItemInfo(merchantItemIndex);
				
				-- TODO: Support shift-click for stacks of extended cost items
				if (stackCount > 1 and extendedCost) then
					MerchantItemButton_OnClick(self, button);
					return;
				end
				
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
	if(self.purchasing) then return end
	if(text < "0" or text > "9") then return end

	if(not self.typing) then
		self.typing = true;
		self.split = 0;
	end

	local split = (self.split * 10) + tonumber(text);
	if(split <= self.maxPurchase) then
		self.split = split;
	end
	
	self:Update();
end

function VendorerStackSplitMixin:OnKeyDown(key)
	if(self.purchasing) then return end
	
	local numKey = gsub(key, "NUMPAD", "");
	if(key == "BACKSPACE" or key == "DELETE") then
		if(self.typing or self.split == 1) then
			return;
		end

		self.split = floor(self.split / 10);
		if(self.split <= 1) then
			self.split = 1;
			self.typing = false;
		end
	elseif(key == "ENTER") then
		-- StackSplitFrameOkay_Click();
	elseif(GetBindingFromClick(key) == "TOGGLEGAMEMENU") then
		self:Cancel();
	elseif(key == "LEFT" or key == "DOWN") then
		self:Decrement();
	elseif(key == "RIGHT" or key == "UP") then
		self:Increment();
	elseif(key == "PRINTSCREEN") then
		Screenshot();
	end
	
	self:Update();
end

function Addon:GetFreeBagSlotsForItem(item)
	if(not item) then return end
	
	local _, itemLink = GetItemInfo(item);
	local itemType = GetItemFamily(itemLink);
	
	local freeSlots = GetContainerNumFreeSlots(0);
	
	for bagID = 1, NUM_BAG_SLOTS do
		local bagItemLink = GetInventoryItemLink("player", 19 + bagID);
		if(bagItemLink) then
			local bagType = GetItemFamily(bagItemLink);
			if(bagType == 0 or bagType == itemType or bit.band(itemType, bagType) == bagSubType) then
				freeSlots = freeSlots + GetContainerNumFreeSlots(bagID);
			end
		end
	end
	
	return freeSlots;
end
