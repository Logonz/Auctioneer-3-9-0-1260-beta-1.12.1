--[[
	Auctioneer Addon for World of Warcraft(tm).
	Version: 3.9.0.1260 (Kangaroo)
	Revision: $Id: AucLocale.lua 1090 2006-11-24 02:58:29Z mentalpower $

	AucLocale
	Functions for localizing Auctioneer
	Thanks to Telo for the LootLink code from which this was based.

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
]]

Auctioneer_CustomLocalizations = {
	['TextGeneral'] = GetLocale(),
	['TextCombat'] = GetLocale(),
}

function _AUCT(stringKey, locale)
	if (locale) then
		if (type(locale) == "string") then
			return Babylonian.FetchString(AuctioneerLocalizations, locale, stringKey);
		else
			return Babylonian.FetchString(AuctioneerLocalizations, GetLocale(), stringKey);
		end
	elseif (Auctioneer_CustomLocalizations[stringKey]) then
		return Babylonian.FetchString(AuctioneerLocalizations, Auctioneer_CustomLocalizations[stringKey], stringKey)
	else
		return Babylonian.GetString(AuctioneerLocalizations, stringKey) or stringKey
	end
end

