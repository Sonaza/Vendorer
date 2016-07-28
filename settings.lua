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
	EasyMenu(Addon:GetMenuData(), DropDownMenuFrame, "cursor", 0, 0, "MENU", 5);
	
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
			text = "Auto sell junk items",
			func = function()
				self.db.global.AutoSellJunk = not self.db.global.AutoSellJunk;
			end,
			checked = function() return self.db.global.AutoSellJunk; end,
			isNotRadio = true,
			tooltipTitle = "Auto Sell Junk",
			tooltipText = "Toggle automatic selling of junk when visiting vendors.",
			tooltipOnButton = 1,
			keepShownOnClick = 1,
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
			disabled = (CanIMogIt ~= nil),
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
	
	for _, item in ipairs(data) do item.fontObject = "VendorerMenuFont" end
	
	return data;
end

function VendorerSettingsButton_OnClick(self)
	Addon:OpenSettingsMenu(self);
end

hooksecurefunc("UIDropDownMenu_AddButton", function(info, level)
	if ( not level ) then
		level = 1;
	end
	
	local listFrame = _G["DropDownList"..level];
	local index = listFrame and (listFrame.numButtons + 1) or 1;
	
	listFrame = listFrame or _G["DropDownList"..level];
	local listFrameName = listFrame:GetName();
	
	local button = _G[listFrameName.."Button"..index];
	
	if(info.text) then
		if(info.fontObject) then
			button:SetDisabledFontObject(info.fontObject);
			print("SETTING DISABLED FONT", button:GetText());
		end
	end
end);
