--[[
	Babylonian
	A sub-addon that manages the locales for other addons.
	<%version%> (<%codename%>)
	$Id: Babylonian.lua 1112 2006-12-05 15:24:14Z norganna $

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
		http://www.fsf.org/licensing/licenses/gpl-faq.html
]]

local self = {}
self.update = {}
--Local function prototypes
local setOrder, getOrder, fetchString, getString, registerAddOn

--Function Imports
local tinsert = table.insert

function setOrder(order)
	if (not order) then
		self.order = {}
	else
		--self.order = string.match(order, '([^,]+)');
		--self.order = { strsplit(",", order) }
		DEFAULT_CHAT_FRAME:AddMessage("Order: "..order);
		self.order = {}
	end

	tinsert(self.order, GetLocale())
	tinsert(self.order, "enUS")

	return SetCVar("BabylonianOrder", order)
end

function getOrder()
	return GetCVar("BabylonianOrder")
end

function fetchString(stringTable, locale, stringKey)
	if ((type(stringTable) == "table") and (type(stringTable[locale]) == "table") and (stringTable[locale][stringKey])) then
		return stringTable[locale][stringKey]
	end
end

function getString(stringTable, stringKey, default)
	local val
	for i = 1, table.getn(self.order) do
		val = fetchString(stringTable, self.order[i], stringKey)
		if (val) then
			return val
		end
	end
	return default
end

if (not Babylonian) then
	Babylonian = {
		SetOrder = setOrder,
		GetOrder = getOrder,
		GetString = getString,
		FetchString = fetchString,
	}
	RegisterCVar("BabylonianOrder", "")
	setOrder(getOrder())
end
