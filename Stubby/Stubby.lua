--[[  Stubby

$Id: Stubby.lua 1252 2006-12-26 19:57:55Z mentalpower $
Version: 3.9.0.1252 (Kangaroo)

Stubby is an addon that allows you to register boot code for
your addon.

This bootcode will be run whenever your addon does not demand
load on startup so that you can setup your own conditions for
loading.

A quick example of this is:
-------------------------------------------
	Stubby.RegisterBootCode("myAddOn", "CommandHandler", [=[
		local function cmdHandler(msg)
			LoadAddOn("myAddOn")
			MyAddOn_Command(msg)
		end
		SLASH_MYADDON1 = "/myaddon"
		SlashCmdList['MYADDON'] = cmdHandler
	]=])
-------------------------------------------
So, what did this just do? It registered some boot code
(called "CommandHandler") with Stubby that Stubby will
(in the case you are not demand loaded) execute on your
behalf.

In the above example, your boot code sets up a command handler
which causes your addon to load and process the command.

Another example:
-------------------------------------------
Stubby.CreateAddOnLoadBootCode("myAddOn", "Blizzard_AuctionUI")
-------------------------------------------
Ok, what was that? Well you just setup some boot code
for your addon that will register an addon hook when
Stubby loads and your addon doesn't. This addon hook
will cause your addon to load when the AuctionUI does.


The primary functions that you will be interested in are:
	CreateAddOnLoadBootCode(ownerAddOn, triggerAddOn)
	CreateEventLoadBootCode(ownerAddOn, triggerEvent)
	CreateFunctionLoadBootCode(ownerAddOn, triggerFunction)
And the manual, but vastly more powerful:
	RegisterBootCode(ownerAddOn, bootName, bootCode)


Stubby can also save variables for you if you wish to retain
stateful information in your boot code. (maybe you have
recieved notification from your user that they wish always
to have your addon load for the current toon?)

These are the variable functions:
	SetConfig(ownerAddOn, variable, value, isGlobal)
GetConfig(ownerAddOn, variable)
	ClearConfig(ownerAddOn, variable)

The SetConfig function sets the configuration variable
"variable" for ownerAddOn to value. The variable is
per-toon unless isGlobal is set.

The GetConfig function gets "variable" for ownerAddOn
it will return per-toon values before global ones.

The ClearConfig function clears the toon specific and
global "variable" for ownerAddOn.


The following functions are also available for you to use
if you need to use some manual boot code and want to
hook into some function, addon or event within your boot
code:
	Stubby.RegisterFunctionHook(triggerFunction, position, hookFunction, ...)
	Stubby.RegisterAddOnHook(triggerAddOn, ownerAddOn, hookFunction, ...)
	Stubby.RegisterEventHook(triggerEvent, ownerAddOn, hookFunction, ...)

RegisterFunctionHook allows you to hook into a function.
* The triggerFunction is a string that names the function you
	want to hook into. eg: "GameTooltip.SetOwner"
* The position is a negative or positive number that defines
	the actual calling order of the addon. The smaller or more
	negative the number, the earlier in the call sequence your
	hookFunction will be called, the larger the number, the
	later your hook will be called. The actual original (hooked)
	function is called at position 0, so if your addon is hooked
	at a negative position, you will not have access to any
	return values.
* You pass (by reference) your function that you wish called
	as hookFunction. This function will be called with the
	following parameters:
		hookFunction(hookParams, returnValue, hook1, hook2 .. hookN)
	- hookParams is a table containing the additional parameters
	passed to the RegisterFunctionHook function (the "..." params)
	- returnValue is an array of the returned values of the function
	or nil if none.
	- hook1..hookN are the original parameters of the hooked
	function in the original order.

RegisterAddOnHook is very much like the register function hook
call except that there is no positioning (you may get notified in
any order with respect to any other addons which may be hooked)
* The triggerAddOn specifies the name of the addon of which you
	want to be notified of it's loading.
* The ownerAddOn is your addon's name (used for removing hooks)
* The hookFunction is a function that gets called when the
	triggerAddOn loads or if it is already loaded straight away.
	This function will be called with the following parameters
		hookFunction(hookParams)
	- hookParams is a table containing the additional parameters
	passed to the RegisterAddOnHook function (the "..." params)

RegisterEventHook allows you to hook an event in much the same
way as the above functions.
* The triggerEvent is an event which causes your hookFunction to
	be executed.
* The ownerAddOn is your addon's name (used for removing hooks)
* The hookFunction is a function that gets called whenever the
	triggerEvent fires (until canceled with UnregisterEventHook)
	This function will be called with the following parameters:
		hookFunction(hookParams, event, hook1, hook2 .. hookN)
- hookParams is a table containing the additional parameters
passed to the RegisterEventHook function (the "..." params)
- event is the event string that has just been fired
- hook1..hookN are the original parameters of the event
function in the original order.

Other functions which may be of interest are:
	UnregisterFunctionHook(triggerFunction, hookFunc)
	UnregisterAddOnHook(triggerAddOn, ownerAddOn)
	UnregisterEventHook(triggerEvent, ownerAddOn)
	UnregisterBootCode(ownerAddOn, bootName)

There is also a single exposed 'constant' allowing you to do
some basic version checking for compatibility:
Stubby.VERSION                (introduced in revision 507)
This constant is Stubby's revision number, a simple positive
integer that will increase by an arbitrary amount with each
new version of Stubby.
Current $Revision: 1252 $

Example:
-------------------------------------------
if (Stubby.VERSION and Stubby.VERSION >= 507) then
	-- Register boot code
else
	Stubby.Print("You need to update your version of Stubby!")
end
-------------------------------------------

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
		along with this program(see GLP.txt); if not, write to the Free Software
		Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

	Note:
		This AddOn's source code is specifically designed to work with
		World of Warcraft's interpreted AddOn system.
		You have an implicit licence to use this AddOn with these facilities
		since that is it's designated purpose as per:
		http://www.fsf.org/licensing/licenses/gpl-faq.html#InterpreterIncompat
]]

local cleanList
local config = {
	hooks = { functions={}, origFuncs={} },
	calls = { functions={}, callList={} },
	loads = {},
	events = {},
}


StubbyConfig = {}


-- Function prototypes
local chatPrint						-- chatPrint(...)
local checkAddOns					-- checkAddOns()
local clearConfig					-- clearConfig(ownerAddOn, variable)
local createAddOnLoadBootCode		-- createAddOnLoadBootCode(ownerAddOn, triggerAddOn)
local createEventLoadBootCode		-- createEventLoadBootCode(ownerAddOn, triggerEvent)
local createFunctionLoadBootCode	-- createFunctionLoadBootCode(ownerAddOn, triggerFunction)
local errorHandler					-- errorHandler(stackLevel, ...)
local eventWatcher					-- eventWatcher(event)
local events						-- events(event, param)
local getConfig						-- getConfig(ownerAddOn, variable)
local getOrigFunc					-- getOrigFunc(triggerFunction)
local hookCall						-- hookCall(funcName, a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20)
local hookInto						-- hookInto(triggerFunction)
local inspectAddOn					-- inspectAddOn(addonName, title, info)
local loadWatcher					-- loadWatcher(loadedAddOn)
local onLoaded						-- onLoaded()
local onWorldStart					-- onWorldStart()
local rebuildNotifications			-- rebuildNotifications(notifyItems)
local registerAddOnHook				-- registerAddOnHook(triggerAddOn, ownerAddOn, hookFunction, ...)
local registerBootCode				-- registerBootCode(ownerAddOn, bootName, bootCode)
local registerEventHook				-- registerEventHook(triggerEvent, ownerAddOn, hookFunction, ...)
local registerFunctionHook			-- registerFunctionHook(triggerFunction, position, hookFunc, ...)
local runBootCodes					-- runBootCodes()
local searchForNewAddOns			-- searchForNewAddOns()
local cleanUpAddOnData				-- cleanUpAddOnData()
local cleanUpAddOnConfigs			-- cleanUpAddOnConfigs()
local setConfig						-- setConfig(ownerAddOn, variable, value, isGlobal)
local shouldInspectAddOn			-- shouldInspectAddOn(addonName)
local unregisterAddOnHook			-- unregisterAddOnHook(triggerAddOn, ownerAddOn)
local unregisterBootCode			-- unregisterBootCode(ownerAddOn, bootName)
local unregisterEventHook			-- unregisterEventHook(triggerEvent, ownerAddOn)
local unregisterFunctionHook		-- unregisterFunctionHook(triggerFunction, hookFunc)


-- Function definitions

-- This function takes all the items and their requested orders
-- and assigns an actual ordering to them.
function rebuildNotifications(notifyItems)
	local notifyFuncs = {}
	for hookType, hData in pairs(notifyItems) do
		notifyFuncs[hookType] = {}

		-- Sort all hooks for this type in ascending numerical order.
		local sortedPositions = {}
		for requestedPos in pairs(hData) do
			table.insert(sortedPositions, requestedPos)
		end
		table.sort(sortedPositions)

		-- Process the sorted request list and insert in correct
		-- order into the call list.
		for _,requestedPos in ipairs(sortedPositions) do
			local func = hData[requestedPos]
			table.insert(notifyFuncs[hookType], func)
		end
	end
	return notifyFuncs
end

-- This function's purpose is to execute all the attached
-- functions in order and the original call at just before
-- position 0.
function hookCall(funcName, ...)
	local orig = Stubby.GetOrigFunc(funcName)
	if (not orig) then return end

	local res
	local retVal

	local callees
	if config.calls and config.calls.callList and config.calls.callList[funcName] then
		callees = config.calls.callList[funcName]
	end

	if (callees) then
		for _, func in ipairs(callees) do
			if (orig and func.p >= 0) then
				retVal = {pcall(orig, ...)}
				if (not table.remove(retVal, 1)) then
					Stubby.ErrorHandler(2, "Error occured while running hooks for: ", tostring(funcName), "\n", retVal[1])
				end
				orig = nil
			end

			local result, res, addit = pcall(func.f, func.a, retVal, ...)
			if (result) then
				if (res == 'abort') then
					return
				elseif (res == 'killorig') then
					orig = nil
				elseif (res == 'setreturn') then
					retVal = addit
					returns = true
				end
				--[[
				--This option has been disabled permanently, since there is no way to do this via the current varArg (...) construct implementation.
				if (res == 'setparams') then
					-- Don't use unpack() since that doesn't correctly handle nil values in the middle of the arg list.
					a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20 =
						addit[1], addit[2], addit[3], addit[4], addit[5], addit[6], addit[7], addit[8], addit[9], addit[10], addit[11], addit[12], addit[13], addit[14], addit[15], addit[16], addit[17], addit[18], addit[19], addit[20]
				end
				--]]

			else
				Stubby.ErrorHandler(2, "Error occured while running hooks for: ", tostring(funcName), "\n", res)
			end
		end
	end

	if (orig) then
		retVal = {pcall(orig, ...)}
		if (not table.remove(retVal, 1)) then
			Stubby.ErrorHandler(2, "Error occured while running hooks for: ", tostring(funcName), "\n", retVal[1])
		end
	end

	if (retVal) then
		return unpack(retVal, 1, table.maxn(retVal))
	end
end

-- This function automatically hooks Stubby in place of the
-- original function, dynamically.
Stubby_OldFunction = nil
Stubby_NewFunction = nil
function hookInto(triggerFunction)
	if ((not triggerFunction) or config.hooks.origFuncs[triggerFunction]) then return end
	local stringToLoad = [[
		Stubby_OldFunction = ]]..triggerFunction..[[;
		local functionString = ']]..triggerFunction..[[';

		if (not (type(Stubby_OldFunction) == "function")) then
			return Stubby.ErrorHandler(3, "Error occured while compiling hook: ", tostring(functionString), "is not a valid function")
		end

		Stubby_NewFunction = function(...)
			return Stubby.HookCall(functionString, ...);
		end;
		]]..triggerFunction..[[ = Stubby_NewFunction
	]];
	local loadedFunction, errorMessage = loadstring(stringToLoad, "StubbyHookingFunction")

	if (loadedFunction) then
		loadedFunction()
	else
		Stubby_NewFunction = nil
		Stubby_OldFunction = nil

		return Stubby.ErrorHandler(2, "Error occured while compiling hook:", tostring(triggerFunction), "\n", errorMessage)
	end

	config.hooks.functions[triggerFunction] = Stubby_NewFunction
	config.hooks.origFuncs[triggerFunction] = Stubby_OldFunction

	Stubby_NewFunction = nil
	Stubby_OldFunction = nil
end

function errorHandler(stackLevel, ...)
	local msg = tostring(select(1, ...))
	for i = 2, select("#", ...) do
		msg = msg.." "..tostring(select(i, ...))
	end
	
	stackLevel = (stackLevel or 1) + 1
	
	if (Swatter and Swatter.IsEnabled()) then
		return Swatter.OnError(msg, Stubby, debugstack(stackLevel, 3, 6))
	else
		return Stubby.Print(msg, "\nCall Chain:\n", debugstack(2, 3, 6))
	end
end

function getOrigFunc(triggerFunction)
	if (config.hooks) and (config.hooks.origFuncs) then
		return config.hooks.origFuncs[triggerFunction]
	end
end

--[[
	This function causes a given function to be hooked by stubby and configures the hook function to be called at the given position.
	The original function gets executed a position 0. Use a negative number to get called before the original function, and positive
	number to get called after the original function. Default position is 200. If someone else is already using your number, you will get
	automatically moved up for after or down for before. Please also leave space for other people who may need to position their hooks
	in between your hook and the original.
 ]]
function registerFunctionHook(triggerFunction, position, hookFunc, ...)
	if (not (triggerFunction and hookFunc)) then
		return
	end
	local insertPos = tonumber(position) or 200
	local funcObj
	if (select("#", ...) == 0) then
		funcObj = {
			f = hookFunc,
			p = position,
		}
	else
		funcObj = {
			f = hookFunc,
			a = {select(1, ...)},
			p = position
		}
	end

	if (not config.calls) then config.calls = {} end
	if (not config.calls.functions) then config.calls.functions = {} end
	if (config.calls.functions[triggerFunction]) then
		while (config.calls.functions[triggerFunction][insertPos]) do
			if (position >= 0) then
				insertPos = insertPos + 1
			else
				insertPos = insertPos - 1
			end
		end
		config.calls.functions[triggerFunction][insertPos] = funcObj
	else
		config.calls.functions[triggerFunction] = {}
		config.calls.functions[triggerFunction][insertPos] = funcObj
	end
	config.calls.callList = rebuildNotifications(config.calls.functions)
	return hookInto(triggerFunction)
end

function unregisterFunctionHook(triggerFunction, hookFunc)
	if not (config.calls and config.calls.functions and config.calls.functions[triggerFunction]) then return end
	for pos, funcObj in ipairs(config.calls.functions[triggerFunction]) do
		if (funcObj and funcObj.f == hookFunc) then
			config.calls.functions[triggerFunction][pos] = nil
		end
	end
end

--[[
	This function registers a given function to be called when a given addon is loaded, or immediatly if it is already loaded (this can be
	used to setup a hooking function to execute when an addon is loaded but not before)
 ]]
function registerAddOnHook(triggerAddOn, ownerAddOn, hookFunction, ...)
	if (IsAddOnLoaded(triggerAddOn)) then
		if (select("#", ...) == 0) then
			hookFunction()
		else
			hookFunction({select(1, ...)})
		end
	else
		local addon = triggerAddOn:lower()
		if (not config.loads[addon]) then config.loads[addon] = {} end
		config.loads[addon][ownerAddOn] = nil
		if (hookFunction) then
			if (select("#", ...) == 0) then
				config.loads[addon][ownerAddOn] = {
					f = hookFunction,
				}
			else
				config.loads[addon][ownerAddOn] = {
					f = hookFunction,
					a = {select(1, ...)},
				}
			end
		end
	end
end

function unregisterAddOnHook(triggerAddOn, ownerAddOn)
	local addon = triggerAddOn:lower()
	if (config.loads and config.loads[addon] and config.loads[addon][ownerAddOn]) then
		config.loads[addon][ownerAddOn] = nil
	end
end

function loadWatcher(loadedAddOn)
	local addon = loadedAddOn:lower()
	if (config.loads[addon]) then
		for ownerAddOn, hookDetail in pairs(config.loads[addon]) do
			hookDetail.f(hookDetail.a)
		end
	end
end

-- This function registers a given function to be called when a given
-- event is fired (this can be used to activate an addon upon receipt
-- of a given event etc)
function registerEventHook(triggerEvent, ownerAddOn, hookFunction, ...)
	if (not config.events[triggerEvent]) then
		config.events[triggerEvent] = {}
		StubbyFrame:RegisterEvent(triggerEvent)
	end
	config.events[triggerEvent][ownerAddOn] = nil
	if (hookFunction) then
		if (select("#", ...) == 0) then
			config.events[triggerEvent][ownerAddOn] = {
				f = hookFunction,
			}
		else
			config.events[triggerEvent][ownerAddOn] = {
				f = hookFunction,
				a = {select(1, ...)},
			}
		end
	end
end

function unregisterEventHook(triggerEvent, ownerAddOn)
	if (config.events and config.events[triggerEvent] and config.events[triggerEvent][ownerAddOn]) then
		config.events[triggerEvent][ownerAddOn] = nil
	end
end

function eventWatcher(event, ...)
	if (config.events[event]) then
		for ownerAddOn, hookDetail in pairs(config.events[event]) do
			hookDetail.f(hookDetail.a, event, ...)
		end
	end
end

-- This function registers boot code. This is a piece of code
-- specified as a string, which Stubby will execute on your behalf
-- when we are first loaded. This code can do anything a normal
-- lua script can, such as create global functions, register a
-- command handler, hook into functions, load your addon etc.
-- Leaving bootCode nil will remove your boot.
function registerBootCode(ownerAddOn, bootName, bootCode)
	local ownerIndex = ownerAddOn:lower()
	local bootIndex = bootName:lower()
	if (not StubbyConfig.boots) then StubbyConfig.boots = {} end
	if (not StubbyConfig.boots[ownerIndex]) then StubbyConfig.boots[ownerIndex] = {} end
	StubbyConfig.boots[ownerIndex][bootIndex] = nil
	if (bootCode) then
		StubbyConfig.boots[ownerIndex][bootIndex] = bootCode
	end
end

function unregisterBootCode(ownerAddOn, bootName)
	local ownerIndex = ownerAddOn:lower()
	local bootIndex = bootName:lower()
	if not (StubbyConfig.boots) then return end
	if not (ownerIndex and StubbyConfig.boots[ownerIndex]) then return end
	if (bootIndex == nil) then
		StubbyConfig.boots[ownerIndex] = nil
	else
		StubbyConfig.boots[ownerIndex][bootIndex] = nil
	end
end

function createAddOnLoadBootCode(ownerAddOn, triggerAddOn)
	registerBootCode(ownerAddOn, triggerAddOn.."AddOnLoader",
		'local function hookFunction() '..
			'LoadAddOn("'..ownerAddOn..'") '..
			'Stubby.UnregisterAddOnHook("'..triggerAddOn..'", "'..ownerAddOn..'") '..
		'end '..
		'Stubby.RegisterAddOnHook("'..triggerAddOn..'", "'..ownerAddOn..'", hookFunction)'
	)
end

function createFunctionLoadBootCode(ownerAddOn, triggerFunction)
	registerBootCode(ownerAddOn, triggerFunction.."FunctionLoader",
		'local function hookFunction() '..
			'LoadAddOn("'..ownerAddOn..'") '..
			'Stubby.UnregisterFunctionHook("'..triggerFunction..'", hookFunction) '..
		'end '..
		'Stubby.RegisterFunctionHook("'..triggerFunction..'", 200, hookFunction)'
	)
end

function createEventLoadBootCode(ownerAddOn, triggerEvent)
	registerBootCode(ownerAddOn, triggerEvent.."FunctionLoader",
		'local function hookFunction() '..
			'LoadAddOn("'..ownerAddOn..'") '..
			'Stubby.UnregisterEventHook("'..triggerEvent..'", "'..ownerAddOn..'") '..
		'end '..
		'Stubby.RegisterEventHook("'..triggerEvent..'", "'..ownerAddOn..'", hookFunction)'
	)
end

-- Functions to check through all addons for dependants.
-- If any exist that we don't know about, and have a dependancy of us, then we will load them
-- once to give them a chance to register themselves with us.
function checkAddOns()
	if not StubbyConfig.inspected then return end
	local goodList = {}
	local addonCount = GetNumAddOns()
	local name, title, notes
	for i=1, addonCount do
		name, title, notes = GetAddOnInfo(i)
		if (StubbyConfig.inspected and StubbyConfig.inspected[name]) then
			local infoCompare = title.."|"..(notes or "")
			if (infoCompare == StubbyConfig.addinfo[name]) then
				goodList[name] = true
			end
		end
	end
	for name in pairs(StubbyConfig.inspected) do
		if (not goodList[name]) then
			StubbyConfig.inspected[name] = nil
			StubbyConfig.addinfo[name] = nil
		end
	end
end

-- Cleans up boot codes for removed addons and prompts for deletion of their
-- configurations.
function cleanUpAddOnData()
	if (not StubbyConfig.boots) then return end

	for b in pairs(StubbyConfig.boots) do
		local _,title = GetAddOnInfo(b)
		if (not title) then
			StubbyConfig.boots[b] = nil

			if (StubbyConfig.configs) then
				if (cleanList == nil) then cleanList = {} end
				table.insert(cleanList, b)
			end
		end
	end

	if (cleanList) then cleanUpAddOnConfigs() end
end

-- Shows confirmation dialogs to clean configuration for addons that have
-- just been removed. Warning: Calls itself recursively until done.
function cleanUpAddOnConfigs()
	if (not cleanList) then return end

	local addonIndex = #cleanList
	local addonName = cleanList[addonIndex]

	if (addonIndex == 1) then
		cleanList = nil
	else
		table.remove(cleanList, addonIndex)
	end

	StaticPopupDialogs["CLEANUP_STUBBY" .. addonIndex] = {
		text = "The AddOn \"" .. addonName .. "\" is no longer available. Do you wish to delete it's loading preferences?",
		button1 = "Delete",
		button2 = "Keep",
		OnAccept = function()
			StubbyConfig.configs[addonName] = nil
			cleanUpAddOnConfigs()
		end,
		OnCancel = function()
			cleanUpAddOnConfigs()
		end,
		timeout = 0,
		whileDead = 1,
	}
	StaticPopup_Show("CLEANUP_STUBBY" .. addonIndex, "","")
end

function shouldInspectAddOn(addonName)
	if not StubbyConfig.inspected[addonName] then return true end
	return false
end

function inspectAddOn(addonName, title, info)
	LoadAddOn(addonName)
	StubbyConfig.inspected[addonName] = true
	StubbyConfig.addinfo[addonName] = title.."|"..(info or "")
end

function searchForNewAddOns()
	local addonCount = GetNumAddOns()
	local name, title, notes, enabled, loadable, reason, security, requiresLoad
	for i=1, addonCount do
		requiresLoad = false
		name, title, notes, enabled, loadable, reason, security = GetAddOnInfo(i)
		if (IsAddOnLoadOnDemand(i) and shouldInspectAddOn(name) and loadable) then
			local addonDeps = { GetAddOnDependencies(i) }
			for _, dependancy in pairs(addonDeps) do
				if (dependancy:lower() == "stubby") then
					requiresLoad = true
				end
			end
		end

		if (requiresLoad) then inspectAddOn(name, title, notes) end
	end
end

-- This function runs through the boot scripts we have, and if the
-- related addon is not loaded yet, runs the boot script.
function runBootCodes()
	if (not StubbyConfig.boots) then return end
	for addon, boots in pairs(StubbyConfig.boots) do
		if (not IsAddOnLoaded(addon) and IsAddOnLoadOnDemand(addon)) then
			local _, _, _, _, loadable = GetAddOnInfo(addon)
			if (loadable) then
				for bootname, boot in pairs(boots) do
					RunScript(boot)
				end
			end
		end
	end
end


function onWorldStart()
	-- Check for expired or updated addons and remove their boot codes.
	checkAddOns()

	-- Run all of our boots to setup the respective addons functions.
	runBootCodes()

	-- The search for new life and new civilizations... or just addons maybe.
	searchForNewAddOns()

	-- Delete data for removed addons
	cleanUpAddOnData()
end

function onLoaded()
	if (not (type(StubbyConfig) == "table")) then
		StubbyConfig = {}
	end
	if (not StubbyConfig.inspected) then
		StubbyConfig.inspected = {}
	end
	if (not StubbyConfig.addinfo) then
		StubbyConfig.addinfo = {}
	end
	Stubby.RegisterEventHook("PLAYER_LOGIN", "Stubby", onWorldStart)
end

function events(event, ...)
	if (not event) then event = "" end
	local firstArg = select(1, ...)
	if (event == "ADDON_LOADED") then
		if (firstArg and (firstArg:lower() == "stubby")) then
			onLoaded()
		end
		Stubby.LoadWatcher(...)
	end
	Stubby.EventWatcher(event, ...)
end

function chatPrint(...)
	if ( DEFAULT_CHAT_FRAME ) then
		local msg = ""
		for i = 1, select("#", ...) do
			if (i == 1) then
				msg = select(i, ...)
			else
				msg = msg.." "..select(i, ...)
			end
		end
		DEFAULT_CHAT_FRAME:AddMessage(msg, 1.0, 0.35, 0.15)
	end
end

-- This function allows boot code to store a configuration variable
-- by default the variable is per character unless isGlobal is set.
function setConfig(ownerAddOn, variable, value, isGlobal)
	local ownerIndex = ownerAddOn:lower()
	local varIndex = variable:lower()
	if (not isGlobal) then
		varIndex = UnitName("player"):lower() .. ":" .. varIndex
	end

	if (not StubbyConfig.configs) then StubbyConfig.configs = {} end
	if (not StubbyConfig.configs[ownerIndex]) then StubbyConfig.configs[ownerIndex] = {} end
	StubbyConfig.configs[ownerIndex][varIndex] = value
end

-- This function gets a config variable stored by the above function
-- it will prefer a player specific variable over a global with the
-- same name
function getConfig(ownerAddOn, variable)
	local ownerIndex = ownerAddOn:lower()
	local globalIndex = variable:lower()
	local playerIndex = UnitName("player"):lower() .. ":" .. globalIndex

	if (not StubbyConfig.configs) then return end
	if (not StubbyConfig.configs[ownerIndex]) then return end
	local curValue = StubbyConfig.configs[ownerIndex][playerIndex]
	if (curValue == nil) then
		curValue = StubbyConfig.configs[ownerIndex][globalIndex]
	end
	return curValue
end

-- This function clears the config variable specified (both the
-- global and player specific) or all config variables for the
-- ownerAddOn if no variable is specified
function clearConfig(ownerAddOn, variable)
	local ownerIndex = ownerAddOn:lower()
	if (not StubbyConfig.configs) then return end
	if (not StubbyConfig.configs[ownerIndex]) then return end
	if (variable) then
		local globalIndex = variable:lower()
		local playerIndex = UnitName("player"):lower() .. ":" .. globalIndex
		StubbyConfig.configs[ownerIndex][globalIndex] = nil
		StubbyConfig.configs[ownerIndex][playerIndex] = nil
	else
		StubbyConfig.configs[ownerIndex] = nil
	end
end

-- Extract the revision number from SVN keyword string
local function getRevision()
	return tonumber(("$Revision: 1252 $"):match("(%d+)"))
end

-- Setup our Stubby global object. All interaction is done
-- via the methods exposed here.
Stubby = {
	VERSION = getRevision(),
	Print = chatPrint,
	Events = events,
	HookCall = hookCall,
	SetConfig = setConfig,
	GetConfig = getConfig,
	ClearConfig = clearConfig,
	GetOrigFunc = getOrigFunc,
	LoadWatcher = loadWatcher,
	ErrorHandler = errorHandler,
	EventWatcher = eventWatcher,
	RegisterBootCode = registerBootCode,
	RegisterEventHook = registerEventHook,
	RegisterAddOnHook = registerAddOnHook,
	RegisterFunctionHook = registerFunctionHook,
	UnregisterBootCode = unregisterBootCode,
	UnregisterEventHook = unregisterEventHook,
	UnregisterAddOnHook = unregisterAddOnHook,
	UnregisterFunctionHook = unregisterFunctionHook,
	CreateAddOnLoadBootCode = createAddOnLoadBootCode,
	CreateEventLoadBootCode = createEventLoadBootCode,
	CreateFunctionLoadBootCode = createFunctionLoadBootCode,
	GetName = function() return "Stubby" end,
}
