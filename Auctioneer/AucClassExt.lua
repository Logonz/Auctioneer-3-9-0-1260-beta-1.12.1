--[[
	Auctioneer Addon for World of Warcraft(tm).
	Version: 3.9.0.1260 (Kangaroo)
	Revision: $Id: AucClassExt.lua 1212 2006-12-18 16:46:08Z norganna $

	Auctioneer Extended Class List

	License:
		This program is free software; you can redistribute it and/or
		modify it under the terms of the GNU General Public License
		as published by the Free Software Foundation; either version 2
		of the License, or (at your option) any later version.

		This program is distributed in the hope that it will be useful,
		but WITHOUT ANY WARRANTY; without even the implied warranty of
		MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
		GNU General Public License for more details.

		You should have received a copy of the GNU General Public License
		along with this program(see GPL.txt); if not, write to the Free Software
		Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

	Note:
		This AddOn's source code is specifically designed to work with
		World of Warcraft's interpreted AddOn system.
		You have an implicit licence to use this AddOn with these facilities
		since that is it's designated purpose as per:
		http://www.fsf.org/licensing/licenses/gpl-faq.html#InterpreterIncompat
--]]

local classes = {
	{
		id = 2,
		name = 'Weapon',
		{
			id = 0,
			name = 'One-Handed Axes',
			INVTYPE_WEAPON,
			INVTYPE_WEAPONMAINHAND,
			INVTYPE_WEAPONOFFHAND,
		},
		{
			id = 1,
			name = 'Two-Handed Axes',
		},
		{
			id = 2,
			name = 'Bows',
		},
		{
			id = 3,
			name = 'Guns',
		},
		{
			id = 4,
			name = 'One-Handed Maces',
			INVTYPE_WEAPON,
			INVTYPE_WEAPONMAINHAND,
			INVTYPE_WEAPONOFFHAND,
		},
		{
			id = 5,
			name = 'Two-Handed Maces',
		},
		{
			id = 6,
			name = 'Polearms',
		},
		{
			id = 7,
			name = 'One-Handed Swords',
			INVTYPE_WEAPON,
			INVTYPE_WEAPONMAINHAND,
			INVTYPE_WEAPONOFFHAND,
		},
		{
			id = 8,
			name = 'Two-Handed Swords',
		},
		{
			id = 10,
			name = 'Staves',
		},
		{
			id = 13,
			name = 'Fist Weapons',
			INVTYPE_WEAPON,
			INVTYPE_WEAPONMAINHAND,
			INVTYPE_WEAPONOFFHAND,
		},
		{
			id = 14,
			name = 'Miscellaneous',
			INVTYPE_WEAPON,
			INVTYPE_WEAPONMAINHAND,
			INVTYPE_WEAPONOFFHAND,
		},
		{
			id = 15,
			name = 'Daggers',
		},
		{
			id = 16,
			name = 'Thrown',
		},
		{
			id = 18,
			name = 'Crossbows',
		},
		{
			id = 19,
			name = 'Wands',
		},
		{
			id = 20,
			name = 'Fishing Pole',
		},
		{
			id = 11,
			name = 'One-Handed Exotics',
		},
		{
			id = 12,
			name = 'Two-Handed Exotics',
		},
		{
			id = 17,
			name = 'Spears',
		},
	},
	{
		id = 4,
		name = 'Armor',
		{
			id = 0,
			name = 'Miscellaneous',
			INVTYPE_BODY,
			INVTYPE_FEET,
			INVTYPE_FINGER,
			INVTYPE_HOLDABLE,
			INVTYPE_LEGS,
			INVTYPE_NECK,
			INVTYPE_ROBE,
			INVTYPE_TABARD,
			INVTYPE_TRINKET,
		},
		{
			id = 1,
			name = 'Cloth',
			INVTYPE_CHEST,
			INVTYPE_CLOAK,
			INVTYPE_FEET,
			INVTYPE_HAND,
			INVTYPE_HEAD,
			INVTYPE_LEGS,
			INVTYPE_ROBE,
			INVTYPE_SHOULDER,
			INVTYPE_WAIST,
			INVTYPE_WRIST,
		},
		{
			id = 2,
			name = 'Leather',
			INVTYPE_CHEST,
			INVTYPE_FEET,
			INVTYPE_HAND,
			INVTYPE_HEAD,
			INVTYPE_LEGS,
			INVTYPE_ROBE,
			INVTYPE_SHOULDER,
			INVTYPE_WAIST,
			INVTYPE_WRIST,
		},
		{
			id = 3,
			name = 'Mail',
			INVTYPE_CHEST,
			INVTYPE_FEET,
			INVTYPE_HAND,
			INVTYPE_HEAD,
			INVTYPE_LEGS,
			INVTYPE_SHOULDER,
			INVTYPE_WAIST,
			INVTYPE_WRIST,
		},
		{
			id = 4,
			name = 'Plate',
			INVTYPE_CHEST,
			INVTYPE_FEET,
			INVTYPE_HAND,
			INVTYPE_HEAD,
			INVTYPE_LEGS,
			INVTYPE_SHOULDER,
			INVTYPE_WAIST,
			INVTYPE_WRIST,
		},
		{
			id = 6,
			name = 'Shield',
		},
		{
			id = 7,
			name = 'Libram',
		},
		{
			id = 8,
			name = 'Idol',
		},
		{
			id = 9,
			name = 'Totem',
		},
	},
	{
		id = 1,
		name = 'Container',
		{
			id = 0,
			name = 'Bag',
		},
		{
			id = 1,
			name = 'Soul Bag',
		},
		{
			id = 2,
			name = 'Herb Bag',
		},
		{
			id = 3,
			name = 'Enchanting Bag',
		},
		{
			id = 4,
			name = 'Engineering Bag',
		},
		{
			id = 5,
			name = 'Gem Bag',
		},
		{
			id = 6,
			name = 'Mining Bag',
		},
	},
	{
		id = 0,
		name = 'Consumable',
		{
			id = 0,
			name = 'Consumable',
		},
	},
	{
		id = 7,
		name = 'Trade Goods',
		{
			id = 0,
			name = 'Trade Goods',
		},
		{
			id = 1,
			name = 'Parts',
		},
		{
			id = 2,
			name = 'Explosives',
		},
		{
			id = 3,
			name = 'Devices',
		},
		{
			id = 4,
			name = 'Gems',
		},
	},
	{
		id = 6,
		name = 'Projectile',
		{
			id = 2,
			name = 'Arrow',
		},
		{
			id = 3,
			name = 'Bullet',
		},
	},
	{
		id = 11,
		name = 'Quiver',
		{
			id = 2,
			name = 'Quiver',
		},
		{
			id = 3,
			name = 'Ammo Pouch',
		},
	},
	{
		id = 9,
		name = 'Recipe',
		{
			id = 0,
			name = 'Book',
		},
		{
			id = 1,
			name = 'Leatherworking',
		},
		{
			id = 2,
			name = 'Tailoring',
		},
		{
			id = 3,
			name = 'Engineering',
		},
		{
			id = 4,
			name = 'Blacksmithing',
		},
		{
			id = 5,
			name = 'Cooking',
		},
		{
			id = 6,
			name = 'Alchemy',
		},
		{
			id = 7,
			name = 'First Aid',
		},
		{
			id = 8,
			name = 'Enchanting',
		},
		{
			id = 9,
			name = 'Fishing',
		},
		{
			id = 10,
			name = 'Jewelcrafting',
		},
	},
	{
		id = 5,
		name = 'Reagent',
		{
			id = 0,
			name = 'Reagent',
		},
	},
	{
		id = 15,
		name = 'Miscellaneous',
		{
			id = 0,
			name = 'Junk',
			INVTYPE_BODY,
			INVTYPE_FINGER,
			INVTYPE_HOLDABLE,
			INVTYPE_NECK,
		},
	},
	{
		id = 12,
		name = 'Quest',
		{
			id = 0,
			name = 'Quest',
		},
	},
	{
		id = 13,
		name = 'Key',
		{
			id = 0,
			name = 'Key',
		},
		{
			id = 1,
			name = 'Lockpick',
		},
	},
}

local classLookup = {}
for index, class in ipairs(classes) do
	classLookup[class.name] = { id = class.id }
	for subindex, subclass in ipairs(class) do
		classLookup[subclass.name] = subclass.id
	end
end

Auctioneer.ClassExt = {}
function Auctioneer.ClassExt.GetClassId(class, subClass)
	if (subClass and classLookup[class] and classLookup[class][subClass]) then
		return classLookup[class].id, classLookup[class][subClass].id
	elseif (classLookup[class]) then
		return classLookup[class].id
	end
end
		


local extGetAuctionItemSubClasses = GetAuctionItemSubClasses
function GetAuctionItemSubClasses(index, ...)
	if (index == 5) then 
		return "Trade Goods", "Parts", "Explosives", "Devices", "Gems"; 
	else
		return extGetAuctionItemSubClasses(index, ...); 
	end 
end
