------------------------------------------------------------
-- Vendorer by Sonaza
-- All rights reserved
-- http://sonaza.com
------------------------------------------------------------

local ADDON_NAME, Addon = ...;
local _;

tinsert(UISpecialFrames, "VendorerItemListsFrame");
UIPanelWindows["VendorerItemListsFrame"] = { area = "left", pushable = 1 };

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
		
		if(itemID) then
			local name, link, rarity, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemID);
			
			if(name) then
				local r, g, b = GetItemQualityColor(rarity);
				local hexcolor = string.format("%02x%02x%02x", r * 255, g * 255, b * 255);
				
				button.name:SetText(("|cff%s%s|r"):format(hexcolor, name));
				button.icon.texture:SetTexture(texture);
				
				local a = 0.9;
				if(rarity == 1) then a = 0.75 end
				button.icon.rarityBorder.border:SetVertexColor(r, g, b, a);
				button.icon.rarityBorder.highlight:SetVertexColor(r, g, b);
				button.icon.rarityBorder:Show();
				
				button:Show();
				
				button.index = index;
			end
		end
	end
	
	local totalHeight = numItems * 47;
	local displayedHeight = numButtons * 47;
	HybridScrollFrame_Update(scrollFrame, totalHeight, displayedHeight);
end

function VendorerItemListsFrame_OnLoad(self)
	SetPortraitToTexture(self.portrait, "Interface\\Icons\\INV_Artifact_tome02");
	
	VendorerItemListsFrame.itemList = {};
	
	VendorerItemListsFrameItems.update = VendorerItemListsFrameItems_Update;
	HybridScrollFrame_CreateButtons(VendorerItemListsFrameItems, "VendorerItemListItemButtonTemplate", 1, 0);
	VendorerItemListsFrameItemsScrollBar.doNotHide = true;
end

function VendorerItemListsFrame_OnShow(self)
	if(self.titleText) then
		VendorerItemListsFrameTitle:SetText(self.titleText);
	end
	
	if(self.itemList) then
		self.itemCount:SetText(("|cffffffff%d|r items"):format(#self.itemList));
	end
end

function VendorerItemListItemButton_OnEnter(self)
	if(not self.index) then return end
	
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
	local indexedItems = {};
	for itemID, _ in pairs(VendorerItemListsFrame.itemListOriginal) do
		local name = GetItemInfo(itemID);
		if(name) then -- only add found items
			tinsert(indexedItems, itemID)
		end
	end
	VendorerItemListsFrame.itemList = indexedItems;
end

function Addon:OpenVendorerItemListsFrame(title, items)
	if(VendorerItemListsFrame:IsShown()) then HideUIPanel(VendorerItemListsFrame) end

	VendorerItemListsFrame.titleText = title;
	
	VendorerItemListsFrame.itemListOriginal = items;
	VendorerItemListsFrame_ReindexItems();
	
	HybridScrollFrame_SetOffset(VendorerItemListsFrameItems, 0);
	VendorerItemListsFrameItemsScrollBar:SetValue(0);
	VendorerItemListsFrameItems_Update();
	
	ShowUIPanel(VendorerItemListsFrame);
end

function VendorerItemListItemButtonRemove_OnClick(itembutton)
	local itemID = VendorerItemListsFrame.itemList[itembutton.index];
	VendorerItemListsFrame.itemListOriginal[itemID] = nil;
	
	local _, itemLink = GetItemInfo(itemID);
	Addon:AddMessage(string.format("%s removed from the list.", itemLink));
	
	Addon:UpdateVendorerItemLists()
end

function VendorerItemListsDragReceiver_OnShow(self)
	self.hovering = false;
	self:RegisterForClicks("LeftButtonUp");
end

function VendorerItemListsDragReceiver_OnEnter(self)
	if(IsMouseButtonDown("LeftButton")) then
		self.hovering = true;
	end
end

function VendorerItemListsDragReceiver_OnLeave(self)
	self.hovering = false;
end

function VendorerItemListsDragReceiver_OnClick(self, button)
	if(button == "LeftButton") then
		if(VendorerItemListsFrame.addItemFunction) then
			VendorerItemListsFrame.addItemFunction();
		end
		
		VendorerItemListsDragReceiver:Hide();
	end
end

function VendorerItemListsDragReceiver_OnUpdate(self)
	if(not self.hovering) then return end
	
	if(not IsMouseButtonDown("LeftButton")) then
		if(VendorerItemListsFrame.addItemFunction) then
			VendorerItemListsFrame.addItemFunction();
		end
		
		VendorerItemListsDragReceiver:Hide();
	end
end

