## 4.0.3
* TOC bump for phase 2 10.0.2
* Fixed bag container API namespace C_Container change.
* Fix Item tooltip hook callback.
* Fix junk/ignore list selling.

## 4.0.2
* Dragonflight pre-patch update
* TOC bump for 10.0.0
* Updated Ace3 libs to r1284
* Added Evoker class to Mail filter.
* Renamed Blizzard function to close split stacks.
* Renamed Blizzard event for cursor updates.
* Wiggled Contract/Expand buttons, Filtering button so that they don't overflow edge.
* Fixed SetPoint errror with Hint Tooltip next to search field.
* Fixed portrait icon error for ignore/junk list.
* Fixed backdrop color error with the Blizzard changes.
* Fixed rarity color error when purchasing currency items.

## 4.0.1
* Attempted blind fix at a nil error.

## 4.0.0
* Patch 9.0.1 fixes by fubaWOW (https://github.com/fubaWoW)
* Removed new feature icons because it's very not new.

## 3.0.4
* Attempted fixes for the overzealous auto sell ignoring. Now merchant will only be ignored if the error given is absolute in regards to the merchant buying items.
* A forced reset is performed on all merchant auto sell ignores in order to fix addon functionality if a previous version was installed.
* Added a way to remove auto sell ignores by holding CTRL and clicking the Sell Junk button for cases where the ignore wasn't intended but the addon somehow did it anyway. Hope there aren't a lot of those cases.

## 3.0.3
* Patch 8.2.5.
* Fixed auto sell operations attempting to sell items to merchants that don't buy any. Now upon encountering any NPC that doesn't wish to buy your items via auto sell will add them to an ignore list in case of future encounters.

## 3.0.2
* Patch 8.2.0.

## 3.0.1
* Increased currency caching up to currency id 20000. Future proof?
* Still fixing ancient PlaySound errors.

## 3.0.0
* Updated for Battle for Azeroth.
* Removed artifact power junk selling since all old artifact power items have been removed from the game.

## 2.7.0
* TOC bump for 7.3.5.
* Marked all artifact power items as junk after character has completed the artifact retirement quest "The Power in Our Hands".
* Optional choice to sell all Artifact Power items before completing the quest.

## 2.6.1
* Fixed errors with currency items sold by vendors.

## 2.6.0
* Fixed errors caused by return value changes for GetMerchantItemInfo in patch 7.2.0. Blizz please, don't add return values in the middle of the sequence. PLEEEEEASE.
* Fixed guild repairing trying to repair when guild bank has no money.
* Fixed stack purchasing being weirdly borked.
* Added new search magic word *purchasable*.

## 2.5.5
* TOC bump for 7.2.0.

## 2.5.4
* Added toggle option for verbose mode which is enabled by default. If disabled chat output will be kept minimal, only listing gold changes and repair costs.

## 2.5.3
* Re-hid the Can I Mog It-overlay icons after the frame name changed.
* TOC bump for 7.1.0.

## 2.5.2
* Disabled automatic guild repair if character is not allowed to use guild funds for repair.
* Fixed a bug that caused overwritten merchant functions throw errors if called before merchant frames are opened. This should fix a compability error with FreeRefills addon.

## 2.5.1
* Added Starlight Rosedust to default ignore list since despite being a grey item it is used for a herbalist quest and shouldn't be sold.
* Fixed an error where items that were on the default ignore list couldn't be removed from the list.
* Transmog asterisk option now hides the icon added by Can I Mog It. The addon doesn't support extended item list by Vendorer. If you wish you can still display the other icons by disabling the Vendorer's asterisks from the settings.

## 2.5.0
* Added an option to destroy unsellable items.
	* Sell Junk Items button will destroy unsellable poor quality items or items marked as junk.
	* Sell Unusables will destroy unusable unsellable soulbound equipment or tokens.
	* **The option is disabled by default.** Just be careful of what you are destroying.
* Added an option to use character's personal ignore and junk item lists. By default the global lists are enabled.
* Added option to display on item tooltip if item is ignored or marked as junk.
* Added ranged type to quick filter list.
* Fixed localization independence error with recipe items.
* Fixed stack buying text on tooltip for items that are stackable.
* Made vendor frame movable only with left mouse button.

## 2.4.1
* Fixed bugs with frame update if merchant had no items for sale.
* Fixed error related to query negation.

## 2.4.0
* Added additional filter options:
	* Prefixing a query word or a phrase with a + (a plus) will now perform an exact search. Vendorer will attempt to match a compared value exactly and discard all other results.
	* Range searching by item rarity e.g. >=rare will find all rare or better items.
	* New magic words: canafford, transmogable, unknowntransmog. Transmog related filters require the dependency Can I Mog It.
* Added a filters menu where you can choose common filtering options quickly.
* Attempted minor performance optimizations by caching filtering results temporarily. It may or may not help.

## 2.3.4
* Fixed paging error (again) caused by the previous fix.
* Fixed GetMerchantItemInfo errors happening upon login.

## 2.3.3
* Tweaked the popup alert threshold to prevent alerts if there was no real problem.

## 2.3.2
* Fixed paging error when switching frame extension.
* Added a popup suggesting disabling tooltip text filtering if it is causing significant framerate drops.

## 2.3.1
* Fixed color picker cancel function bug.

## 2.3.0
* Added an optional dependency for the addon **CanIMogIt** and a marker to display if an item's appearance has not yet been added to the wardrobe.
* Added a bulk purchase system. When enabled shift-clicking merchant items will bring up the Vendorer's bulk purchase window.
	* Bulk purchase window allows buying items more than one stack at a time and shows the total price of items being purchased.
	* Additionally you can instantly set maximum purchase or change number of items stack at a time.
	* Optionally this feature can be disabled to use Blizzard's stock system.
	* Disclaimer: there is no warranty for any lost items or currency if this feature works incorrectly. Use at your own risk.
* Added new filtering options:
	* You can now filter by item tooltip text. This is enabled by default but can be **very resource intensive** and can be disabled from the settings.
	* You can search for sentences by surrounding words with quotation marks.
* Added a new options menu to replace some of the checkboxes.
* Added option to paint known items and pets sold by vendors to make unknown items esaier to distinguish. You can change the color in the settings. Option is enabled by default.
* Added a dedicated menu window for ignored item and junk item lists where you can browse the items in more detail and remove them one by one. You can open the menu by left clicking the drop areas on the side panel or by using the new slash commands.
* Added slash commands available by typing **/vendorer** or **/vd**.
* Fixed error filtering currencies sold by vendors.
* Made merchant frame movable.
* Improved localization independence further.
* Moved the next page button and page info text to more logical places.
* Code refactoring.

## 2.2.4
* Mages, Warlocks and Priests don't use plate. Oops.

## 2.2.3
* Added some items with passive or otherwise useful bonuses to the default ignore list.
* If using the wide frame the merchant window will now automatically temporarily collapse to the narrow width if a vendor has only one page's worth of goods. 
* Improved compability with other localization languages than English.
* Fixed error causing class armor highlight to be permanently enabled.

## 2.2.2
* Made narrow frame the default again.
* Added notification about ability to switch frame width.

## 2.2.1
* Restored the old "narrow" 10 items per page width. You can now choose between WoW default, extended narrow and extended wide using the arrows in the top right corner.

## 2.2.0
* Expanded the merchant frame size to 20 items per page. Look at all of this space.
* Added item rarity coloring to merchant buyback item on the main tab.
* Fixed item rarity color not appearing if class armor type wasn't toggled on.
* Fixed attempting guild repair on characters that aren't in a guild.

## 2.1.0
* Added item rarity coloring to merchant frame items.

## 2.0.0
* Legion update.
  * With the removal of under 40 level armor types (e.g. for hunters or warriors) the addon will now sell the old types as unusable.
  * Clearing lists now requires shift right click, instead of right click only.
