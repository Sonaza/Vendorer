------------------------------------------------------------
-- Vendorer by Sonaza (https://sonaza.com)
-- Licensed under MIT License
-- See attached license text in file LICENSE
------------------------------------------------------------

local ADDON_NAME, Addon = ...;
local _;

function Addon:GetGuildAllowance(triggeredByUser)
	if (not CanGuildBankRepair() or not GetGuildInfo("player")) then
		return 0;
	end

	if (not triggeredByUser and not Addon.db.global.SmartAutoRepair) then
		return 0;
	end

	local guildBankMoney = GetGuildBankMoney();
	local withdrawMoney = GetGuildBankWithdrawMoney();
	if (withdrawMoney == -1) then
		return guildBankMoney;
	end
	return math.min(guildBankMoney, withdrawMoney);
end

local repairableSlots = { 1, 3, 5, 6, 7, 8, 9, 10, 16, 17, }

function Addon:GetItemRepairCost()
	local itemRepairs = {};

	for index, slotID in ipairs(repairableSlots) do
		local hasItem, hasCooldown, repairCost = VendorerTooltip:SetInventoryItem("player", slotID);
		if (hasItem and repairCost and repairCost > 0) then
			tinsert(itemRepairs, { slot = slotID, cost = repairCost });
		end
	end

	for containerID = 0, 4 do
		local containerSlots = C_Container.GetContainerNumSlots(containerID);
		if (containerSlots > 0) then
			for containerSlotID = 1, containerSlots do
				local hasCooldown, repairCost = VendorerTooltip:SetBagItem(containerID, containerSlotID);
				if (repairCost and repairCost > 0) then
					tinsert(itemRepairs, { slot = containerID .. ":" .. containerSlotID, cost = repairCost });
				end
			end
		end
	end

	table.sort(itemRepairs, function(a, b)
		if (a == nil and b == nil) then return false end
		if (a == nil) then return true end
		if (b == nil) then return false end

		return a.cost < b.cost;
	end);

	return itemRepairs;
end

function Addon:GetContainerRepairCost()
	local containerRepair = {};

	for index, slotID in ipairs(repairableSlots) do
		local hasItem, hasCooldown, repairCost = VendorerTooltip:SetInventoryItem("player", slotID);
		if (hasItem and repairCost and repairCost > 0) then
			slotRepair[slotID] = repairCost;
		end
	end

	return slotRepair;
end

function Addon:RepairSlot(slot)
	if (not CanMerchantRepair() or not slot) then return end

	if (not InRepairMode()) then
		ClearCursor();
		ShowRepairCursor();
	end

	if (type(slot) == "string") then
		local container, slot = strsplit(":", slot);
		C_Container.PickupContainerItem(container, slot)
	else
		PickupInventoryItem(slot);
	end

	HideRepairCursor();
end

function Addon:DoAutoRepair(triggeredByUser)
	if (not CanMerchantRepair()) then return end

	local totalRepairCost, shouldRepair = GetRepairAllCost();
	if (totalRepairCost == 0) then return end

	local playerMoney, guildMoney = Addon:GetAutoRepairCost(triggeredByUser)
	if (playerMoney > 0 or guildMoney > 0) then
		Addon:AddMessage("Smart Repair:");

		if (guildMoney > 0) then
			Addon:AddMessage("Guild: %s", GetCoinTextureString(guildMoney));
		end

		if (playerMoney > 0) then
			Addon:AddMessage("Player: %s", GetCoinTextureString(playerMoney));
		end
	end

	local guildRepairMoney = Addon:GetGuildAllowance(triggeredByUser);

	if (guildRepairMoney > 0 and totalRepairCost > guildRepairMoney) then
		local itemRepairCosts = Addon:GetItemRepairCost();

		for index, data in ipairs(itemRepairCosts) do
			-- Check if you can't repair even the cheapest item
			if (data.cost > guildRepairMoney) then break end

			if (totalRepairCost > guildRepairMoney) then
				if (GetMoney() >= data.cost) then
					Addon:RepairSlot(data.slot);
					totalRepairCost = totalRepairCost - data.cost;
				else
					return;
				end
			else
				RepairAllItems(true);
				totalRepairCost = 0;
				break;
			end
		end
	elseif (guildRepairMoney > 0 and totalRepairCost <= guildRepairMoney) then
		RepairAllItems(true);
		totalRepairCost = 0;
	end

	if (totalRepairCost > 0 and GetMoney() >= GetRepairAllCost()) then
		RepairAllItems(false);
	end
end

function Addon:GetAutoRepairCost(triggeredByUser)
	local playerMoney = 0;
	local guildMoney = 0;

	local totalRepairCost = GetRepairAllCost();

	if (totalRepairCost > 0) then
		local guildRepairMoney = Addon:GetGuildAllowance(triggeredByUser);

		if (guildRepairMoney > 0 and totalRepairCost > guildRepairMoney) then
			local itemRepairCosts = Addon:GetItemRepairCost();

			for index, data in ipairs(itemRepairCosts) do
				-- Check if you can't repair even the cheapest item
				if (data.cost > guildRepairMoney) then break end

				if (totalRepairCost > guildRepairMoney) then
					playerMoney = playerMoney + data.cost;
					totalRepairCost = totalRepairCost - data.cost;
				else
					guildMoney = guildMoney + totalRepairCost;
					totalRepairCost = 0;
					break;
				end
			end
		elseif (guildRepairMoney > 0 and totalRepairCost <= guildRepairMoney) then
			guildMoney = guildMoney + totalRepairCost;
			totalRepairCost = 0;
		end

		if (totalRepairCost > 0) then
			playerMoney = playerMoney + totalRepairCost;
		end
	end

	return playerMoney, guildMoney;
end

function Addon:UPDATE_INVENTORY_DURABILITY()
	local repairAllCost, canRepair = GetRepairAllCost();
	if (not canRepair) then
		SetDesaturation(VendorerSmartRepairButtonIcon, true);
		VendorerSmartRepairButton:Disable();
	else
		SetDesaturation(VendorerSmartRepairButtonIcon, false);
		VendorerSmartRepairButton:Enable();
	end
end

hooksecurefunc("MerchantFrame_UpdateRepairButtons", function() Addon:UpdateRepairButtons() end);

function Addon:UpdateRepairButtons()
	if (CanMerchantRepair() and CanGuildBankRepair()) then
		MerchantRepairAllButton:SetPoint("BOTTOMRIGHT", MerchantFrame, "BOTTOMLEFT", 83, 29)
		VendorerSmartRepairButton:Show();

		local repairAllCost, canRepair = GetRepairAllCost();
		if (not canRepair) then
			SetDesaturation(VendorerSmartRepairButtonIcon, true);
			VendorerSmartRepairButton:Disable();
		else
			SetDesaturation(VendorerSmartRepairButtonIcon, false);
			VendorerSmartRepairButton:Enable();
		end
	else
		VendorerSmartRepairButton:Hide();
	end
end

function VendorerSmartRepairButton_OnEnter(self)
	local playerMoney, guildMoney = Addon:GetAutoRepairCost(true);

	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:AddLine("Smart Repair Items");
	GameTooltip:AddLine("Repair items by maximizing the guild bank repairs.", 1, 1, 1);
	GameTooltip:AddLine(" ");

	if (guildMoney > 0) then
		GameTooltip:AddLine("The Guild Bank Covers");
		SetTooltipMoney(GameTooltip, guildMoney, "GUILD_REPAIR");
	end

	if (playerMoney > 0) then
		GameTooltip:AddLine("You Cover");
		SetTooltipMoney(GameTooltip, playerMoney, "GUILD_REPAIR");
	end

	if (playerMoney == 0 and guildMoney == 0) then
		GameTooltip:AddLine(" ");
		GameTooltip:AddLine("All of your items have full durability.");
	end

	GameTooltip:AddLine(" ");
	local amount = GetGuildBankWithdrawMoney();
	local guildBankMoney = GetGuildBankMoney();
	if (amount == -1) then
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
