------------------------------------------------------------
-- Vendorer by Sonaza
-- All rights reserved
-- http://sonaza.com
------------------------------------------------------------

local ADDON_NAME, Addon = ...;
local _;

local MAX_STACK_SIZE = 100000;

VendorerStackSplitMixin = {
	split = 1,
};

function VendorerStackSplitMixin:OnHide()
	self.owner.hasStackSplit = 0;
end

function VendorerStackSplitMixin:Decrement()
	self.split = math.max(1, self.split - 1);
	self:Update();
end

function VendorerStackSplitMixin:Increment()
	self.split = math.min(self.maxPurchase, self.split + 1);
	self:Update();
end

function VendorerStackSplitMixin:Update()
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
	
	local numItems = self.split;
	if(self.maxStack > 1) then
		self.splitNumber:SetText(("%s |cff777777/ %d|r"):format(BreakUpLargeNumbers(numItems), self.maxStack));
	else
		self.splitNumber:SetText(BreakUpLargeNumbers(numItems));
	end
	
	local _, _, price = GetMerchantItemInfo(self.merchantItemIndex);
	local totalPrice = price * (numItems or 1);
	self.totalCost:SetText(GetCoinTextureString(totalPrice, 12));
end

function VendorerStackSplitMixin:Cancel()
	self:Hide();
end

function VendorerStackSplitMixin:Stack(button_or_delta)
	if(button_or_delta == "LeftButton" or button_or_delta == 1) then
		self.split = math.ceil((self.split+1) / self.maxStack) * self.maxStack;
	elseif(button_or_delta == "RightButton" or button_or_delta == -1) then
		self.split = math.floor((self.split-1) / self.maxStack) * self.maxStack;
	end
	
	self.split = math.max(1, math.min(self.maxPurchase, self.split));
	self:Update();
end

function VendorerStackSplitMixin:OnMouseWheel(delta)
	local value = delta;
	if(not IsShiftKeyDown()) then		
		self.split = math.max(1, math.min(self.maxPurchase, self.split + value));
		self:Update();
	else
		VendorerStackSplitFrame:Stack(delta);
	end
end

function VendorerStackSplitMixin:Open(merchantItemIndex, parent, anchor)
	self.merchantItemIndex = merchantItemIndex;
	self.split = 1;
	
	local maxStack = GetMerchantItemMaxStack(merchantItemIndex);
	local _, _, price, stackCount, _, _, extendedCost = GetMerchantItemInfo(merchantItemIndex);
	
	local canAfford = MAX_STACK_SIZE;
	if (price and price > 0) then
		canAfford = floor(GetMoney() / (price / stackCount));
	end

	parent.hasStackSplit = 1;
	
	self.owner          = parent;
	self.canAfford      = canAfford;
	self.maxStack       = maxStack;
	self.maxPurchase    = math.min(canAfford, MAX_STACK_SIZE);
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
	if(text < "0" or text > "9") then
		return;
	end

	if(self.typing) then
		self.typing = true;
		self.split = 0;
	end

	local split = (self.split * 10) + text;
	if(split == self.split) then
		if( self.split == 0) then
			self.split = 1;
		end
		return;
	end

	if(split <= self.maxPurchase) then
		self.split = split;
	elseif(split == 0) then
		self.split = 1;
	end
	
	self:Update();
end

function VendorerStackSplitMixin:OnKeyDown(key)
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

function Addon:GetFreeBagSlots(type)
	local freeSlots = 0;
	for bagID = 0, 4 do
		freeSlots = freeSlots + GetContainerNumFreeSlots(bagID);
	end
	
	return freeSlots;
end
