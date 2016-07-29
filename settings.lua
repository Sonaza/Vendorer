------------------------------------------------------------
-- Vendorer by Sonaza
-- All rights reserved
-- http://sonaza.com
------------------------------------------------------------

local ADDON_NAME, Addon = ...;
local _;

local DropDownMenuFrame;
function Addon:OpenSettingsMenu(anchor)
	if(not DropDownMenuFrame) then
		DropDownMenuFrame = CreateFrame("Frame", "FlashTalentContextMenuFrame", anchor, "UIDropDownMenuTemplate");
	end
	
	DropDownMenuFrame:SetPoint("BOTTOM", anchor, "CENTER", 0, 5);
	EasyMenu(Addon:GetMenuData(), DropDownMenuFrame, "cursor", 0, 0, "MENU", 2.5);
	
	DropDownList1:ClearAllPoints();
	DropDownList1:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", -1, -2);
	DropDownList1:SetClampedToScreen(true);
end

function Addon:GetMenuData()
	local transmogTooltipText = "Adds an asterisk to the item icon if you are missing the item skin.";
	if(not CanIMogIt) then
		transmogTooltipText = transmogTooltipText .. "|n|nTo enable this feature install the optional dependency |cffffffffCanIMogIt|r first.";
	end
	
	local data = {
		{
			text = "Vendorer Options", isTitle = true, notCheckable = true,
		},
		{
			text = "Highlight own armor types",
			func = function()
				self.db.global.PaintArmorTypes = not self.db.global.PaintArmorTypes;
				MerchantFrame_UpdateMerchantInfo();
			end,
			checked = function() return self.db.global.PaintArmorTypes; end,
			isNotRadio = true,
			tooltipTitle = "Highlight Own Armor Types",
			tooltipText = "Paints armor types not used by your current class red.",
			tooltipOnButton = 1,
			keepShownOnClick = 1,
		},
		{
			text = "Paint known items",
			func = function()
				self.db.global.PaintKnownItems = not self.db.global.PaintKnownItems;
				MerchantFrame_UpdateMerchantInfo();
			end,
			checked = function() return self.db.global.PaintKnownItems; end,
			isNotRadio = true,
			tooltipTitle = "Paint Known Items",
			tooltipText = "Paints known items and pets orange to make unlearned items easier to distinguish.",
			tooltipOnButton = 1,
			keepShownOnClick = 1,
		},
		{
			text = "Show icon for missing transmogs" .. (not CanIMogIt and " (disabled)" or ""),
			func = function()
				self.db.global.ShowTransmogAsterisk = not self.db.global.ShowTransmogAsterisk;
				MerchantFrame_UpdateMerchantInfo();
			end,
			checked = function() return self.db.global.ShowTransmogAsterisk; end,
			isNotRadio = true,
			tooltipTitle = "Show icon for missing transmogs",
			tooltipText = transmogTooltipText,
			tooltipOnButton = 1,
			tooltipWhileDisabled = true,
			disabled = (CanIMogIt == nil),
			keepShownOnClick = 1,
		},
		{
			text = " ", isTitle = true, notCheckable = true,
		},
		{
			text = "Use improved stack purchasing",
			func = function()
				self.db.global.UseImprovedStackSplit = not self.db.global.UseImprovedStackSplit;
				-- Close both split frames just in case
				VendorerStackSplitFrame:Cancel();
				StackSplitFrameCancel_Click();
			end,
			checked = function() return self.db.global.UseImprovedStackSplit; end,
			isNotRadio = true,
			tooltipTitle = "Use improved stack purchasing",
			tooltipText = "When buying in bulk use Vendorer's replacement window which allows buying several stacks at once among other things.",
			tooltipOnButton = 1,
			keepShownOnClick = 1,
		},
		{
			text = "Throttle purchases to a safe interval",
			func = function()
				self.db.global.UseSafePurchase = not self.db.global.UseSafePurchase;
			end,
			checked = function() return self.db.global.UseSafePurchase; end,
			isNotRadio = true,
			tooltipTitle = "Throttle purchases to a safe interval",
			tooltipText = "If you encounter errors when trying to purchase items more than one stack at a time try enabling this option. Vendorer will throttle item purchases to a slower rate.",
			tooltipOnButton = 1,
			keepShownOnClick = 1,
		},
		{
			text = " ", isTitle = true, notCheckable = true,
		},
		{
			text = "Close",
			func = function() CloseMenus(); end,
			notCheckable = true,
		},
	};
	
	return data;
end

function VendorerSettingsButton_OnClick(self)
	if(DropDownList1:IsVisible() and select(2, DropDownList1:GetPoint()) == self) then
		CloseMenus();
	else
		Addon:OpenSettingsMenu(self);
	end
end
