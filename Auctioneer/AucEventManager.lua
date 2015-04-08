--[[
	Auctioneer Addon for World of Warcraft(tm).
	Version: 3.9.0.1260 (Kangaroo)
	Revision: $Id: AucEventManager.lua 1090 2006-11-24 02:58:29Z mentalpower $

	AucEventManager - Auctioneer eventing system

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
--]]

-------------------------------------------------------------------------------
-- Function Imports
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Function Prototypes
-------------------------------------------------------------------------------
local registerEvent;
local unregisterEvent;
local fireEvent;
local getListeners;
local debugPrint;

-------------------------------------------------------------------------------
-- Private Data
-------------------------------------------------------------------------------
local EventListeners = {};

-------------------------------------------------------------------------------
-- Registers for an auctioneer event.
-------------------------------------------------------------------------------
function registerEvent(eventName, callbackFunc)
	return table.insert(getListeners(eventName, true), callbackFunc);
end

-------------------------------------------------------------------------------
-- Unregisters for an auctioneer event.
-------------------------------------------------------------------------------
function unregisterEvent(eventName, callbackFunc)
	local listeners = getListeners(eventName);
	if (listeners) then
		for index, thisCallbackFunc in ipairs(listeners) do
			if (thisCallbackFunc == callbackFunc) then
				table.remove(listeners, index);
				if (table.getn(listeners) == 0) then
					EventListeners[eventName] = nil;
				end
				return;
			end
		end
	end
end

-------------------------------------------------------------------------------
-- Unregisters for an auctioneer event.
-------------------------------------------------------------------------------
function fireEvent(eventName, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10) --Test is to apply the regular Event args
	local listeners = getListeners(eventName);
	if (listeners) then
		--debugPrint("Begin firing event:", eventName);
		for index, callbackFunc in ipairs(listeners) do
			callbackFunc(eventName, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10); --Test is to apply the regular Event args
		end
		--debugPrint("End firing event:", eventName);
	end
end

-------------------------------------------------------------------------------
-- Gets the list of registered listeners for the specified event.
-------------------------------------------------------------------------------
function getListeners(eventName, create)
	local listeners = EventListeners[eventName];
	if (not listeners and create) then
		listeners = {};
		EventListeners[eventName] = listeners;
	end
	return listeners;
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function debugPrint(message)
	return EnhTooltip.DebugPrint("[Auc.EventManager]"..message);
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------
Auctioneer.EventManager = {
	RegisterEvent = registerEvent;
	UnregisterEvent = unregisterEvent;
	FireEvent = fireEvent;
}
