--[[

BottomScanner  -  An AddOn for WoW to alert you to good purchases as they appear on the AH
$Id: btmLocales.lua 1326 2007-01-12 03:25:09Z norganna $
Copyright (c) 2006, Norganna

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

]]

-- Stub for future localization function
BtmScan.Locales.GetLocalization = function (l) return l end
BtmScan.Locales.Translate = function ( localization, ... )
	localization = BtmScan.Locales.GetLocalization(localization)
	local newloc = ""

	for i = 1, select("#", ...) do
		local s, b, e
		s = 1 b = 1
		while (b > 0) do
			b,e = string.find(localization, "%"..i, s, true)
			if (b and b > 0) then
				local argv = select(i, ...) or ""
				if (type(argv) == "table") then argv = "TABLE" end
				newloc = newloc .. string.sub(localization, s, b-1) .. argv;
				s = e + 1
			else
				b = 0
			end
		end
		newloc = newloc .. string.sub(localization, s)
		localization = newloc newloc = ""
	end
	return localization
end

