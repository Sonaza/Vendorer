------------------------------------------------------------
-- Vendorer by Sonaza (https://sonaza.com)
-- Licensed under MIT License
-- See attached license text in file LICENSE
------------------------------------------------------------

local ADDON_NAME, Addon = ...;
local _;

local cached = {};

local questItems = {
	-- Equipment Blueprint: Tuskarr Fishing Net
	[128491] = 39359, -- Alliance
	[128251] = 39359, -- Horde

	-- Equipment Blueprint: Unsinkable
	[128250] = 39358, -- Alliance
	[128489] = 39358, -- Horde
};

local PET_KNOWN_PATTERN = strmatch(ITEM_PET_KNOWN, "[^%(]+");

function Addon:IsItemKnown(itemLink)
	if (cached[itemLink]) then return true end

	local itemID = Addon:GetItemID(itemLink);
	if (itemID) then
		if (questItems[itemID]) then
			if (C_QuestLog.IsQuestFlaggedCompleted(questItems[itemID])) then
				cached[itemLink] = true;
				return true;
			end

			return false;
		end

		if (Addon:IsGarrisonBlueprintKnown(itemID)) then
			cached[itemLink] = true;
			return true;
		end
	end

	if (itemLink:match("|H(.-):") == "battlepet") then
		local _, battlepetID = strsplit(":", itemLink);
		if (C_PetJournal.GetNumCollectedInfo(battlepetID)) > 0 then
			cached[itemLink] = true;
			return true;
		end

		return false;
	end

	VendorerTooltip:SetOwner(UIParent, "ANCHOR_NONE");
	VendorerTooltip:ClearLines();
	VendorerTooltip:SetHyperlink(itemLink);

	for line = 2, VendorerTooltip:NumLines() do
		local text = _G["VendorerTooltipTextLeft" .. line]:GetText();
		if (text) then
			if (text == ITEM_SPELL_KNOWN or strmatch(text, PET_KNOWN_PATTERN)) then
				cached[itemLink] = true;
				return true;
			end
		end
	end

	return false;
end

----------------------------
-- Garrison Blueprints

local garrisonBuildings = {
	-- Alchemy Lab
	[111929] = 119, -- Level 2
	[111930] = 120, -- Level 3

	-- Enchanter's Study
	[111972] = 125, -- Level 2
	[111973] = 126, -- Level 3

	-- Engineering Works
	[109256] = 123, -- Level 2
	[109257] = 124, -- Level 3

	-- Gem Boutique
	[111974] = 131, -- Level 2
	[111975] = 132, -- Level 3

	-- Salvage Yard
	[111957] = 52, -- Level 1
	[111976] = 140, -- Level 2
	[111977] = 141, -- Level 3

	-- Scribe's Quarters
	[111978] = 129, -- Level 2
	[111979] = 130, -- Level 3

	-- Storehouse
	[111982] = 142, -- Level 2
	[111983] = 143, -- Level 3

	-- Tailoring Emporium
	[111992] = 127, -- Level 2
	[111993] = 128, -- Level 3

	-- The Forge
	[111990] = 117, -- Level 2
	[111991] = 118, -- Level 3

	-- The Tannery
	[111988] = 121, -- Level 2
	[111989] = 122, -- Level 3

	-- Barn
	[111968] = 25, -- Level 2
	[111969] = 133, -- Level 3

	-- Gladiator's Sanctum
	[111980] = 160, -- Level 2
	[111981] = 161, -- Level 3

	-- Lumber Mill
	[109254] = 41, -- Level 2
	[109255] = 138, -- Level 3

	-- Lunarfall Inn / Frostwall Tavern
	[107694] = 35, -- Level 2, Alliance
	[116431] = 35, -- Level 2, Horde
	[109065] = 36, -- Level 3, Alliance
	[116432] = 36, -- Level 3, Horde

	-- Trading Post
	[111986] = 144, -- Level 2
	[111987] = 145, -- Level 3

	-- Barracks
	[111970] = 27, -- Level 2
	[111971] = 28, -- Level 3

	-- Dwarven Bunker / War Mill
	[111966] = 9, -- Level 2, Alliance
	[116185] = 9, -- Level 2, Horde
	[111967] = 10, -- Level 3, Alliance
	[116186] = 10, -- Level 3, Horde

	-- Gnomish Gearworks / Goblin Workshop
	[111984] = 163, -- Level 2, Alliance
	[116200] = 163, -- Level 2, Horde
	[111985] = 164, -- Level 3, Alliance
	[116201] = 164, -- Level 3, Horde

	-- Mage Tower / Spirit Lodge
	[109062] = 38, -- Level 2, Alliance
	[116196] = 38, -- Level 2, Horde
	[109063] = 39, -- Level 3, Alliance
	[116197] = 39, -- Level 3, Horde

	-- Stables
	[112002] = 66, -- Level 2
	[112003] = 67, -- Level 3

	-- Fishing Shack
	[111927] = 134, -- Level 2
	[111928] = 135, -- Level 3

	-- Herb Garden
	[109577] = 136, -- Level 2
	[111997] = 137, -- Level 3

	-- Lunarfall Excavation / Frostwall Mines
	[109576] = 62, -- Level 2, Alliance
	[116248] = 62, -- Level 2, Horde
	[111996] = 63, -- Level 3, Alliance
	[116249] = 63, -- Level 3, Horde

	-- Pet Menagerie
	[111998] = 167, -- Level 2
	[111999] = 168, -- Level 3
};

function Addon:IsGarrisonBlueprintKnown(itemID)
	if (not itemID) then return false end

	local buildingID = garrisonBuildings[itemID];
	if (buildingID) then
		local _, name, _, _, _, _, _, _, _, _, needsPlan = C_Garrison.GetBuildingInfo(buildingID);
		return needsPlan == false;
	end

	return false;
end

function Addon:GetKnownTransmogInfo(itemLink)
	if (not CanIMogIt) then return end

	local isOutdated = not CanIMogIt.IsEquippable or
		not CanIMogIt.IsTransmogable or
		not CanIMogIt.PlayerKnowsTransmogFromItem or
		not CanIMogIt.PlayerKnowsTransmog or
		not CanIMogIt.CharacterCanLearnTransmog;

	if (isOutdated) then
		error("CanIMogIt current version is incompatible. Please update.");
	end

	if (not CanIMogIt:IsEquippable(itemLink)) then return false end

	local isTransmogable, isKnown, anotherCharacter;

	if (CanIMogIt:IsTransmogable(itemLink)) then
		isTransmogable   = true;
		isKnown          = false;
		anotherCharacter = false;

		if (CanIMogIt:PlayerKnowsTransmogFromItem(itemLink) or CanIMogIt:PlayerKnowsTransmog(itemLink)) then
			isKnown = true;
		elseif (not CanIMogIt:CharacterCanLearnTransmog(itemLink)) then
			anotherCharacter = true;
		end
	else
		isTransmogable = false;
	end

	return isTransmogable, isKnown, anotherCharacter;
end
