# Vendorer
Vendorer the NPC merchant improvement addon for World of Warcraft.

## Description
Sometimes vendors sell so many items it's impossible to find the items you require. Introducing Vendorer which expands the merchant frame to display up to 20 items at once and offers several different types of filters to help you quickly browse for what you need.

* **Basic Filtering** You can search by item name, rarity, type, slot or required currency.
* **Tooltip text** Optionally you can enable search from tooltip text. It is very resource intensive and can be disabled if it causes problems.
* **By Item ID** Prefix a number with letters id. For example id6948.
* **By Required Level** Prefix a number with the letter r. For example r92.
* **By Item Level** Prefix a number with the letter i. For example i200.
* **By Price** Enter a price value formatted like 12g34s56c.
* **Searching for Ranges of Values** Search values can be prefixed with <, <=, > and >= to search for ranges of values. For example >=r90 will find all items that require level higher than or equal to 90. Another example >=250g <=500g will find all items that cost between 250 and 500 gold.
* **Magic words (predefined filters)** usable, unusable, equippable, purchasable, unequippable, known, unknown, available, canafford, transmogable, unknowntransmog.

You can also search for phrases by putting the words in quotes. The results will only include items with the words in the same order as the ones inside the quotes.

Prefixing a query with + (a plus) will attempt exact matching and all other results are discarded. Useful for finding specific types of items.

Any and all filters can also be negated by prefixing the query word or phrase with either **!** (an exlamation mark) or **-** (a dash).

## Other features

Vendorer improves ability to bulk purchase. You can buy several stacks at a time and the window will also display total cost of your purchase. If the default setting causes problems, you can throttle purchases to slower rate in the settings.

The addon also includes buttons to sell junk and unusable soulbound items. Selling junk items can optionally be done automatically always when visiting vendors. Via settings you can also enable the buttons to destroy unsellable junk or unusable items. **If toggled on be careful of what you are destroying**. You can always ignore the item as well. No items are automatically destroyed when auto junk sell is enabled.

Automatic smart repair feature will make it easy to repair your gear when visiting a vendor that can do repairs. Smart repair will try to spend the maximal guild repair allowance if possible. However, the automatic spending of guild funds can be optionally disabled.

## Optional feature

Vendorer supports displaying whether an item skin has been added to the wardrobe. For this the addon requires an optional dependency addon [Can I Mog It](http://mods.curse.com/addons/wow/can-i-mog-it). The marker can be disabled in the settings.

### Note

This addon can and **is likely to conflict** with other addons that do modifications to merchant frames. Due to this reason, the addon must load first before all the other such addons so that it can do the modifications before the other addons. This will still not guarantee compatibility with other addons.

Still if you do not use any other such addons or the modifications by other addons are minor the risk of conflict is non-existent or small.

## Dependencies
Vendorer uses Ace3 which is included in the /libs directory.

### Note for Releases

To guarantee addon loads first the addon folder should be **!Vendorer** (as in prefixed with exclamation mark) since the game loads addons with exclamation marks before ones without.

## License
Vendorer is licensed under MIT license. See license terms in file LICENSE.
