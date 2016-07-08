# Vendorer
Vendorer the NPC merchant improvement addon for World of Warcraft.

## Description
Sometimes vendors sell so many items it's impossible to find the items you require. Introducing Vendorer which offers several different types of filters to help you quickly browse for what you need.

Addon also makes it easier to sell junk items and unusable soulbound loot. Upon closing vendor frame the addon shows money difference if money was gained or lost.

Automatic smart repair feature will make it easy to repair your gear when visiting a vendor that can do repairs. Smart repair will try to spend the maximal guild repair allowance if possible. However, the automatic spending of guild funds can be optionally disabled.

### Filters

* **Basic Filtering** You can search by item name, rarity, type, slot or required currency.
* **By Item ID** Prefix a number with letters id. For example id6948.
* **By Required Level** Prefix a number with the letter r. For example r92.
* **By Item Level** Prefix a number with the letter i. For example i200.
* **By Price** Enter a price value formatted like 12g34s56c.
* **Searching for Ranges of Values** Search values can be prefixed with <, <=, > and >= to search for ranges of values. For example >=r90 will find all items that require level higher than or equal to 90. Another example >=250g <=500g will find all items that cost between 250 and 500 gold.

### Note

This addon can and **is very likely to conflict** with other addons that do modifications to merchant frames. Due to this reason, the addon must load first before all the other such addons so that it can do the modifications before the other addons. This will still not guarantee compatibility with other addons.

## Dependencies
Vendorer uses Ace3 which is included in the /libs directory.
