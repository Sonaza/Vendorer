------------------------------------------------------------
-- Vendorer by Sonaza (https://sonaza.com)
-- Licensed under MIT License
-- See attached license text in file LICENSE
------------------------------------------------------------

local ADDON_NAME, Addon = ...;
local _;

-- UIPanelWindows["VendorerItemListsFrame"] = { area = "left", pushable = 0 };
tinsert(UIChildWindows, "VendorerItemListsFrame");
tinsert(UISpecialFrames, "VendorerItemListsFrame");

function VendorerItemListsFrameItems_Update()
	local scrollFrame = VendorerItemListsFrameItems;
	local offset = HybridScrollFrame_GetOffset(scrollFrame);
	local buttons = scrollFrame.buttons;
	local numButtons = #buttons;

	local numItems = #VendorerItemListsFrame.itemList;

	local button, index;
	for i = 1, numButtons do
		button = buttons[i];
		index = offset + i;

		button:Hide();

		local itemID = VendorerItemListsFrame.itemList[index];

		if (itemID) then
			local name, link, rarity, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemID);

			if (name) then
				local r, g, b = GetItemQualityColor(rarity);
				local hexcolor = string.format("%02x%02x%02x", r * 255, g * 255, b * 255);

				button.name:SetText(("|cff%s%s|r"):format(hexcolor, name));
				button.icon.texture:SetTexture(texture);

				local a = 0.9;
				if (rarity == 1) then a = 0.75 end
				button.icon.rarityBorder.border:SetVertexColor(r, g, b, a);
				button.icon.rarityBorder.highlight:SetVertexColor(r, g, b);
				button.icon.rarityBorder:Show();

				button:Show();

				button.index = index;
			end
		end
	end

	local totalHeight = numItems * 33;
	local displayedHeight = numButtons * 33;
	HybridScrollFrame_Update(scrollFrame, totalHeight, displayedHeight);
end

function VendorerItemListsFrame_OnLoad(self)
	SetPortraitToTexture(self.PortraitContainer.portrait, "Interface\\Icons\\INV_Artifact_tome02");

	VendorerItemListsFrame.itemList = {};

	VendorerItemListsFrameItems.update = VendorerItemListsFrameItems_Update;
	HybridScrollFrame_CreateButtons(VendorerItemListsFrameItems, "VendorerItemListItemButtonTemplate", 1, 0);
	VendorerItemListsFrameItemsScrollBar.doNotHide = true;
end

function VendorerItemListsFrame_Reanchor()
	if (VendorerItemListsFrame.anchorframe == MerchantFrame) then
		HideUIPanel(VendorerItemListsFrame);

		VendorerItemListsFrame:ClearAllPoints();
		if (MerchantFrame:IsVisible()) then
			VendorerItemListsFrame:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", 20, 0);
		else
			VendorerItemListsFrame:SetPoint("TOP", UIParent, "CENTER", 0, 260);
		end

		ShowUIPanel(VendorerItemListsFrame);
	end
end

function VendorerItemListsFrame_OnShow(self)
	HideUIPanel(GetUIPanel("right"));

	if (self.titleText) then
		VendorerItemListsFrameTitle:SetText(self.titleText);
	end

	if (self.itemList) then
		self.itemCount:SetText(("|cffffffff%d|r items"):format(#self.itemList));
	end

	self.anchorframe = MerchantFrame;
end

function VendorerItemListItemButton_OnEnter(self)
	if (not self.index) then return end

	local itemID = VendorerItemListsFrame.itemList[self.index];

	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:SetItemByID(itemID);
	GameTooltip:Show();

	ShoppingTooltip1:Hide();
	ShoppingTooltip2:Hide();
end

function Addon:UpdateVendorerItemLists()
	VendorerItemListsFrame_ReindexItems();
	VendorerItemListsFrameItems_Update();
end

function VendorerItemListsFrame_ReindexItems()
	if (not VendorerItemListsFrame.itemListOriginal) then return end

	local indexedItems = {};
	for itemID, status in pairs(VendorerItemListsFrame.itemListOriginal) do
		local name = GetItemInfo(itemID);
		if (name) then -- only add found items
			if ((type(status) == "number" and status > 0) or (type(status) == "boolean" and status == true)) then
				tinsert(indexedItems, itemID)
			end
		end
	end
	VendorerItemListsFrame.itemList = indexedItems;
end

function Addon:OpenVendorerItemListsFrame(index, title, items)
	if (VendorerItemListsFrame:IsVisible()) then HideUIPanel(VendorerItemListsFrame) end

	VendorerItemListsFrame.index = index;
	VendorerItemListsFrame.titleText = title;

	VendorerItemListsFrame.itemListOriginal = items;
	VendorerItemListsFrame_ReindexItems();

	HybridScrollFrame_SetOffset(VendorerItemListsFrameItems, 0);
	VendorerItemListsFrameItemsScrollBar:SetValue(0);
	VendorerItemListsFrameItems_Update();

	VendorerItemListsFrame:ClearAllPoints();
	if (MerchantFrame:IsVisible()) then
		VendorerItemListsFrame:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", 20, 0);
	else
		VendorerItemListsFrame:SetPoint("TOP", UIParent, "CENTER", 0, 260);
	end

	ShowUIPanel(VendorerItemListsFrame);
end

function VendorerItemListItemButtonRemove_OnClick(itembutton)
	local itemID = VendorerItemListsFrame.itemList[itembutton.index];

	if (VendorerItemListsFrame.index == 1) then
		VendorerItemListsFrame.itemListOriginal[itemID] = 0;
	else
		VendorerItemListsFrame.itemListOriginal[itemID] = nil;
	end

	local _, itemLink = GetItemInfo(itemID);
	Addon:AddMessage(string.format("%s removed from the list.", itemLink));

	Addon:UpdateVendorerItemLists()
end

function VendorerItemListsDragReceiver_OnShow(self)
	self.hovering = false;
	self:RegisterForClicks("LeftButtonUp");
end

function VendorerItemListsDragReceiver_OnEnter(self)
	if (IsMouseButtonDown("LeftButton")) then
		self.hovering = true;
	end
end

function VendorerItemListsDragReceiver_OnLeave(self)
	self.hovering = false;
end

function VendorerItemListsDragReceiver_OnClick(self, button)
	if (button == "LeftButton") then
		if (VendorerItemListsFrame.addItemFunction) then
			VendorerItemListsFrame.addItemFunction();
		end

		VendorerItemListsDragReceiver:Hide();
	end
end

function VendorerItemListsDragReceiver_OnUpdate(self)
	if (not self.hovering) then return end

	if (not IsMouseButtonDown("LeftButton")) then
		if (VendorerItemListsFrame.addItemFunction) then
			VendorerItemListsFrame.addItemFunction();
		end

		VendorerItemListsDragReceiver:Hide();
	end
end
