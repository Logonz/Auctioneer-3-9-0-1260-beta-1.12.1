--[[
Additional function hooks to allow hooks into more tooltips
3.9.0.1237 (Kangaroo)
$Id: Tooltip.lua 1237 2006-12-22 18:21:03Z mentalpower $

You should hook into EnhTooltip using Stubby:
	Stubby.RegisterFunctionHook("EnhTooltip.HOOK", 200, myHookingFunction)
	Where myHooking function is one of your functions (see calling parameters below)
	And HOOK is one of:
		AddTooltip
		CheckPopup
		MerchantHook
		TradeHook
		BankHook
		BagHook
	The number 200 is a number that determines calling order
		A lower number will make your tooltip information display earlier (higher)
		A higher number will call your tooltip later (lower)
		Auctioneer (if installed) gets called at position 100.
		Informant  (if installed) gets called at position 300.
		Enchantrix (if installed) gets called at position 400.

	The appropriate function calls are, respectively:
		tooltip - A tooltip is being displayed, hookFunc will be called as:
		addTooltipHook(frame, name, link, quality, count, price)
		popup - A tooltip may be displayed, unless you want to popup something:
		popped = checkPopupHook(name, link, quality, count, price, hyperlink)
			If your function returns true, then we won't present a tooltip
		merchant - Get called for each of a merchant's items.
		merchantHook(frame, name, link, quality, count, price)
		trade - Get called when a tradeskill window is displayed / item selected
		tradeHook(type, selid)
			valid types: 'trade', 'craft'
			selID will be nil when the window is first displayed
		bank - You are at the bank and are able to scan it's containers
			bankHook()
		bag - One or more of the items in your bags has updated.
			bagHook()


You may use the following methods of the EnhTooltip class:

	EnhTooltip.HideTooltip()
		Causes the enhanced tooltip to vanish.

	EnhTooltip.ClearTooltip()
		Clears the current tooltip of contents and hides it.

	EnhTooltip.GetGSC(money)
		Returns the given money (in copper) amount in gold, silver and copper.

	EnhTooltip.GetTextGSC(money, exact)
		Returns the money (in copper) amount as colored text, suitable for display.
		If exact evaluates to true, then the text will be exact, otherwise rounded.

	EnhTooltip.AddLine(lineText, moneyAmount, embed)
		Adds the lineText to the tooltip.
		If moneyAmount is supplied, the line has a money amount right-aligned after it.
		It embed evaluates to true, then the line is placed at the end of the game tooltip
		and the money amount is converted to a textual form.

	EnhTooltip.AddSeparator()
		Adds an empty line to the tooltip.

	EnhTooltip.LineColor(r, g, b)
		Changes the color of the most recently added line to the given R,G,B value.
		The R,G,B values are floating point values from 0.0 (dark) to 1.0 (bright)

	EnhTooltip.LineSize(fontSize)
		Changes the size of the FontString associated with the most recently added line to the given fontSize value.

	EnhTooltip.LineQuality(quality)
		Changes the color of the most recently added line to the quality color of the
		item that is supplied in the quality parameter.

	EnhTooltip.SetIcon(iconPath)
		Adds an icon to the current tooltip, where the texture path is set to that of
		the iconPath parameter.

	EnhTooltip.NameFromLink(link)
		Given a link, returns the embedded item name.

	EnhTooltip.HyperlinkFromLink(link)
		Given a link, returns the blizzard hyperlink (eg: "item:12345:0:321:0")

	EnhTooltip.BaselinkFromLink(link)
		Given a link, returns the first 3 numbers from the item link (eg: "12345:0:321")

	EnhTooltip.QualityFromLink(link)
		Given a link, returns the numerical quality value (0=Poor/Gray ... 4=Epic/Purple)

	EnhTooltip.FakeLink(hyperlink, quality, name)
		Given a hyperlink, a numerical quality and an item name, does it's best to fabricate
		as authentic a link as it can. This link may not be suitable for messaging however.

	EnhTooltip.LinkType(link)
		Given a link, returns the type of link (eg: "item", "enchant")

	EnhTooltip.AddHook(hookType, hookFunc, position)
		Allows dependant addons to register a function for inclusion at key moments.
		Where:
			hookType = The type of event to be notified of. One of:
				tooltip - A tooltip is being displayed, hookFunc will be called as:
				addTooltipHook(frame, name, link, quality, count, price)
				popup - A tooltip may be displayed, unless you want to popup something:
				popped = checkPopupHook(name, link, quality, count, price, hyperlink)
					If your function returns true, then we won't present a tooltip
				merchant - Get called for each of a merchant's items.
				merchantHook(frame, name, link, quality, count, price)
				trade - Get called when a tradeskill window is displayed / item selected
				tradeHook(type, selid)
					valid types: 'trade', 'craft'
					selID will be nil when the window is first displayed
				bank - You are at the bank and are able to scan it's containers
				bankHook()
				bag - One or more of the items in your bags has updated.
					bagHook()
			hookFunction = Your function (prototyped as above) that we will call.
			position = A number that determines calling order
				The default position if not supplied is 100.
				A lower number will make your tooltip information display earlier (higher)
				A higher number will call your tooltip later (lower)
				Auctioneer (if installed) gets called at position 50.
				Enchantrix (if installed) gets called at position 150.

	EnhTooltip.BreakLink(link)
		Given an item link, splits it into it's component parts as follows:
			itemID, randomProperty, enchantment, uniqueID, itemName,
				gemSlot1, gemSlot2, gemSlot3, gemSlotBonus = EnhTooltip.BreakLink(link)
			Note that the return order is not the same as the order of the items in the link
			(ie: randomProp and enchant are reversed from their link order)

	EnhTooltip.FindItemInBags(findName)
		Searches through your bags to find an item with the given name (exact match)
		It returns the following information about the item:
			bag, slot, itemID, randomProp, enchant, uniqID = EnhTooltip.FindItemInBags(itemName)

	EnhTooltip.SetElapsed(elapsed)
		If a value is given, adds the elapsed interval to our own internal timer.
			Checks to see if it is time to hide the tooltip.
		Returns the total elapsed time that the tooltip has been displayed since startup.

	EnhTooltip.SetMoneySpacing(spacing)
		Sets the amount of padding (if provided) that money should be given in the tooltips.
		Returns the current spacing.

	EnhTooltip.SetPopupKey(key)
		Sets a key (if provided), which if pressed while a tooltip is being displayed, checks
			for hooked functions that may wish to provide popups.
		Returns the current key.

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

-- setting version number
ENHTOOLTIP_VERSION = "3.9.0.1237"
if (ENHTOOLTIP_VERSION == "<".."%version%>") then
	ENHTOOLTIP_VERSION = "3.9.DEV"
end

-- Initialize a storage space that all our functions can see
local self = {
	showIgnore = false,
	moneySpacing = 4,
	embedLines = {},
	eventTimer = 0,
	hideTime = 0,
	currentGametip = nil,
	currentItem = nil,
	forcePopupKey = "alt",
	oldChatItem = nil,
	lastFontStringIndex = 1,
	lastMoneyObjectIndex = 0,
	lastHeaderFontStringIndex = 1,
	numberHeaderLines = 0,
}

-- =============== LOCAL FUNCTIONS =============== --

-- prototypes for all local functions
local addLine					-- AddLine(lineText,moneyAmount,embed)
local addHeader					-- AddLine(lineText,moneyAmount,embed)
local addSeparator				-- AddSeparator(embed)
local addTooltip				-- AddTooltip(frame,name,link,quality,count,price)
local afHookOnEnter				-- AfHookOnEnter(type,index)
local bagHook					-- BagHook()
local bankHook					-- BankHook()
local baselinkFromLink			-- BaselinkFromLink(link)
local breakLink					-- BreakLink(link)
local callBagHook				-- CallBagHook(event,bagNumber)
local callBankHook				-- CallBankHook()
local callCheckPopup			-- CallCheckPopup(name,link,quality,count,price,hyperlink)
local callTradeHook				-- CallTradeHook(type,event,selID)
local cfHookUpdate				-- CfHookUpdate(frame)
local chatHookOnHyperlinkShow	-- ChatHookOnHyperlinkShow(reference,link,button)
local checkHide					-- CheckHide()
local checkPopup				-- CheckPopup(name,link,quality,count,price,hyperlink)
local clearTooltip				-- ClearTooltip()
local debugPrint				-- DebugPrint(...)
local doHyperlink				-- DoHyperlink(reference,link,button)
local embedRender				-- EmbedRender()
local fakeLink					-- FakeLink(hyperlink,quality,name)
local findItemInBags			-- FindItemInBags(findName)
local getglobalIterator			-- GetglobalIterator(format,first,last)
local getGSC					-- GetGSC(money)
local getLootLinkLink			-- GetLootLinkLink(name)
local getLootLinkServer			-- GetLootLinkServer()
local getRect					-- GetRect(object,curRect)
local getTextGSC				-- GetTextGSC(money,exact)
local getTooltipHeight			-- GetTooltipHeight(enhTooltip, currentTooltip)
local getTooltipWidth			-- GetTooltipWidth(enhTooltip, currentTooltip)
local gtHookOnHide				-- GtHookOnHide()
local gtHookSetAuctionSellItem	-- GtHookSetAuctionSellItem(frame)
local gtHookSetBagItem			-- GtHookSetBagItem(frame,frameID,buttonID,retVal)
local gtHookSetCraftItem		-- GtHookSetCraftItem(frame,skill,slot)
local gtHookSetCraftSpell		-- GtHookSetCraftSpell(frame,skill,slot)
local gtHookSetInboxItem		-- GtHookSetinboxItem(frame,index)
local gtHookSetInventoryItem	-- GtHookSetInventoryItem(frame,unit,slot,retVal)
local gtHookSetLootItem			-- GtHookSetLootItem(frame,slot)
local gtHookSetMerchantItem		-- GtHookSetMerchantItem(frame,slot)
local gtHookSetOwner			-- GtHookSetOwner(frame,owner,anchor)
local gtHookSetQuestItem		-- GtHookSetQuestItem(frame,qtype,slot)
local gtHookSetQuestLogItem		-- GtHookSetQuestLogItem(frame,qtype,slot)
local gtHookSetTradeSkillItem	-- GtHookSetTradeSkillItem(frame,skill,slot)
local gtHookSetText				-- GtHookSetText(funcArgs, retval, frame, text, r, g, b, unknown1, unknown2)
local gtHookAppendText			-- GtHookAppendText(funcArgs, retVal, frame)
local gtHookShow				-- GtHookShow(funcArgs, retVal, frame)
local headerColor				-- HeaderColor(r, g, b)
local headerQuality				-- HeaderQuality(quality)
local headerSize				-- HeaderSize(fontSize)
local hideTooltip				-- HideTooltip()
local hyperlinkFromLink			-- HyperlinkFromLink(link)
local imHookOnEnter				-- ImHookOnEnter()
local imiHookOnEnter			-- ImiHookOnEnter()
local lineColor					-- LineColor(r,g,b)
local lineQuality				-- LineQuality(quality)
local lineSize					-- LineSize(fontSize)
local lineSize_Large			-- LineSize_Large()
local lineSize_Small			-- LineSize_Small()
local linkType					-- LinkType()
local llHookOnEnter				-- LlHookOnEnter()
local merchantHook				-- MerchantHook(merchant,slot,name,link,quality,count,price,limit)
local merchantScanner			-- MerchantScanner()
local nameFromLink				-- NameFromLink(link)
local onLoad					-- OnLoad
local qualityFromLink			-- QualityFromLink(link)
local setElapsed				-- SetElapsed(elapsed)
local setIcon					-- SetIcon(iconPath)
local setMoneySpacing			-- SetMoneySpacing(spacing)
local setPopupKey				-- SetPopupKey(key)
local showTooltip				-- ShowTooltip(currentTooltip,skipEmbedRender)
local tooltipCall				-- TooltipCall(frame,name,link,quality,count,price,forcePopup,hyperlink)
local tradeHook					-- TradeHook(type,selID)
local ttInitialize				-- TtInitialize()


------------------------
--  Hookable functions
------------------------

function addTooltip(frame, name, link, quality, count, price)
	-- This is it.
	-- Hook this function when you have something to put into the
	-- tooltip and use the AddLine etc methods to do so.
end

function checkPopup(name, link, quality, count, price, hyperlink)
	-- Hook this function to stop EnhTooltip putting up a tooltip
	-- Return true to stop EnhTooltip's tooltip.
end

function merchantHook(merchant, slot, name, link, quality, count, price, limit)
	-- Hook this function to be notified of an item at a merchant
end

function bankHook()
	-- Hook this function to be alerted to do a bank scan
end

function bagHook()
	-- Hook this function to be alerted to do a bag scan
end

function tradeHook(type,selID)
	-- Hook this function to be notified when a trade window is
	-- displayed or an item therein is selected.
	--   type is one of: "trade", or "craft"
	--   selID can be nil when first opened, or the id of the selected item.
end

------------------------
-- Function definitions
------------------------

function hideTooltip()
	EnhancedTooltip:Hide()
	self.currentItem = ""
	self.hideTime = 0
end

-- Iterate over numbered global objects
function getglobalIterator(fmt, first, last)
	local i = tonumber(first) or 1
	return function()
		if last and (i > last) then
			return
		end
		local obj = getglobal(fmt:format(i))
		i = i + 1
		return obj, i - 1
	end
end

--Create a new fontstring
function createNewFontString(tooltip)
	local tooltipName = tooltip:GetName()
	local currentFontStringIndex = self.lastFontStringIndex
	self.lastFontStringIndex = currentFontStringIndex + 1

	local newFontString = tooltip:CreateFontString(tooltipName.."Text"..self.lastFontStringIndex, "INFO", "GameFontNormal")
	newFontString:SetPoint("TOPLEFT", tooltipName.."Text"..currentFontStringIndex, "BOTTOMLEFT", 0, -1)
	newFontString:Hide()
	newFontString:SetTextColor(1.0,1.0,1.0)
	newFontString:SetFont(STANDARD_TEXT_FONT, 10)
	return newFontString
end

--Create a new money object
function createNewMoneyObject(tooltip)
	self.lastMoneyObjectIndex = self.lastMoneyObjectIndex + 1

	local newMoneyObject = CreateFrame("Frame", tooltip:GetName().."Money"..self.lastMoneyObjectIndex, tooltip, "EnhancedTooltipMoneyTemplate")
	newMoneyObject:SetPoint("LEFT", tooltip:GetName().."Text1", "LEFT")
	newMoneyObject:Hide()
	return newMoneyObject
end

--Create a new header fontstring
function createNewHeaderFontString(tooltip)
	local tooltipName = tooltip:GetName()
	local currentHeaderFontStringIndex = self.lastHeaderFontStringIndex
	self.lastHeaderFontStringIndex = currentHeaderFontStringIndex + 1

	local newFontString = tooltip:CreateFontString(tooltipName.."Header"..self.lastHeaderFontStringIndex, "INFO", "GameFontNormal")
	newFontString:SetPoint("TOPLEFT", tooltipName.."Header"..currentHeaderFontStringIndex, "BOTTOMLEFT", 0, -1)
	newFontString:Hide()
	newFontString:SetTextColor(1.0,1.0,1.0)
	newFontString:SetFont(STANDARD_TEXT_FONT, 10)
	return newFontString
end

function clearTooltip()
	hideTooltip()
	EnhancedTooltip.hasEmbed = false
	EnhancedTooltip.curEmbed = false
	EnhancedTooltip.hasData = false
	EnhancedTooltip.hasIcon = false
	EnhancedTooltip.curHeaderEmbed = false
	EnhancedTooltipIcon:Hide()
	EnhancedTooltipIcon:SetTexture("Interface\\Buttons\\UI-Quickslot2")

	for ttText in getglobalIterator("EnhancedTooltipText%d") do
		ttText:Hide()
		ttText.myMoney = nil
		ttText:SetTextColor(1.0,1.0,1.0)
		ttText:SetFont(STANDARD_TEXT_FONT, 10)
	end

	for ttHeader in getglobalIterator("EnhancedTooltipHeader%d") do
		ttHeader:Hide()
		ttHeader.myMoney = nil
		ttHeader:SetTextColor(1.0,1.0,1.0)
		ttHeader:SetFont(STANDARD_TEXT_FONT, 10)
	end

	for ttMoney in getglobalIterator("EnhancedTooltipMoney%d") do
		ttMoney.myLine = nil
		ttMoney:Hide()
	end

	EnhancedTooltipText1:SetPoint("TOPLEFT", EnhancedTooltip, "TOPLEFT", 10, -10)

	EnhancedTooltip.lineCount = 0
	EnhancedTooltip.headerCount = 0
	EnhancedTooltip.moneyCount = 0
	EnhancedTooltip.minWidth = 0
	for curLine in pairs(self.embedLines) do
		self.embedLines[curLine] = nil
	end
end

function getRect(object, curRect)
	local rect = curRect
	if (not rect) then
		rect = {}
	end

	local left, bottom, width, height = object:GetRect()
	left = left or 0
	bottom = bottom or 0
	width = width or 0
	height = height or 0

	rect.top = bottom + height
	rect.left = left
	rect.bottom = bottom
	rect.right = left + width
	rect.width = width
	rect.height = height
	rect.xCenter = left + (width / 2)
	rect.yCenter = bottom + (height / 2)

	return rect
end

function showTooltip(currentTooltip, skipEmbedRender)
	if (self.showIgnore) then return end
	if (EnhancedTooltip.hasEmbed and (not skipEmbedRender)) then
		embedRender()
		self.showIgnore=true
		currentTooltip:Show()
		self.showIgnore=false
	end
	if (not EnhancedTooltip.hasData) then
		return
	end

	local lineCount = EnhancedTooltip.lineCount
	local headerCount = EnhancedTooltip.headerCount
	if ((lineCount == 0) and (headerCount == 0)) then
		if (not EnhancedTooltip.hasEmbed) then
			hideTooltip()
			return
		end
	end

	if (headerCount > 0) then
		EnhancedTooltipText1:SetPoint("TOPLEFT", "EnhancedTooltipHeader"..EnhancedTooltip.headerCount, "BOTTOMLEFT", 0, -1)
	end

	local width, height = getTooltipWidth(EnhancedTooltip, currentTooltip), getTooltipHeight(EnhancedTooltip, currentTooltip)
	local sWidth, sHeight = GetScreenWidth(), GetScreenHeight()

	local cWidth = currentTooltip:GetWidth()
	if (cWidth < width) then
		currentTooltip:SetWidth(width - 20)
		self.showIgnore=true
		currentTooltip:Show()
		self.showIgnore=false
	else
		width = cWidth
	end

	local parentObject = currentTooltip.owner
	if (parentObject) then
		local align = currentTooltip.anchor

		enhTooltipParentRect = getRect(currentTooltip.owner, enhTooltipParentRect)

		local xAnchor, yAnchor
		if (enhTooltipParentRect.left - width < sWidth * 0.2) then
			xAnchor = "RIGHT"
		elseif (enhTooltipParentRect.right + width > sWidth * 0.8) then
			xAnchor = "LEFT"
		elseif (align == "ANCHOR_RIGHT") then
			xAnchor = "RIGHT"
		elseif (align == "ANCHOR_LEFT") then
			xAnchor = "LEFT"
		else
			xAnchor = "RIGHT"
		end
		if (enhTooltipParentRect.yCenter < sHeight/2) then
			yAnchor = "TOP"
		else
			yAnchor = "BOTTOM"
		end

		-- Handle the situation where there isn't enough room on the choosen side of
		-- the parent to display the tooltip. In that case we'll just shift tooltip
		-- enough to the left or right so that it doesn't hang off the screen.
		local xOffset = 0
		if (xAnchor == "RIGHT" and enhTooltipParentRect.right + width > sWidth - 5) then
			xOffset = -(enhTooltipParentRect.right + width - sWidth + 5)
		elseif (xAnchor == "LEFT" and enhTooltipParentRect.left - width < 5) then
			xOffset = -(enhTooltipParentRect.left - width - 5)
		end

		-- Handle the situation where there isn't enough room on the top or bottom of
		-- the parent to display the tooltip. In that case we'll just shift tooltip
		-- enough up or down so that it doesn't hang off the screen.
		local yOffset = 0
		local totalHeight = height + currentTooltip:GetHeight()
		if (yAnchor == "TOP" and enhTooltipParentRect.top + totalHeight > sHeight - 5) then
			yOffset = -(enhTooltipParentRect.top + totalHeight - sHeight + 5)
		elseif (yAnchor == "BOTTOM" and enhTooltipParentRect.bottom - totalHeight < 5) then
			yOffset = -(enhTooltipParentRect.bottom - totalHeight - 5)
		end

		currentTooltip:ClearAllPoints()
		EnhancedTooltip:ClearAllPoints()
		local anchor = yAnchor..xAnchor

		if (anchor == "TOPLEFT") then
			EnhancedTooltip:SetPoint("BOTTOMRIGHT", parentObject, "TOPLEFT", -5 + xOffset, 5 + yOffset)
			currentTooltip:SetPoint("BOTTOMRIGHT", EnhancedTooltip, "TOPRIGHT", 0,0)
		elseif (anchor == "TOPRIGHT") then
			EnhancedTooltip:SetPoint("BOTTOMLEFT", parentObject, "TOPRIGHT", 5 + xOffset, 5 + yOffset)
			currentTooltip:SetPoint("BOTTOMLEFT", EnhancedTooltip, "TOPLEFT", 0,0)
		elseif (anchor == "BOTTOMLEFT") then
			currentTooltip:SetPoint("TOPRIGHT", parentObject, "BOTTOMLEFT", -5 + xOffset, -5 + yOffset)
			EnhancedTooltip:SetPoint("TOPRIGHT", currentTooltip, "BOTTOMRIGHT", 0,0)
		else--if (anchor == "BOTTOMRIGHT") then
			currentTooltip:SetPoint("TOPLEFT", parentObject, "BOTTOMRIGHT", 5 + xOffset, -5 + yOffset)
			EnhancedTooltip:SetPoint("TOPLEFT", currentTooltip, "BOTTOMLEFT", 0,0)
		end

	else
		-- No parent
		-- The only option is to tack the object underneath / shuffle it up if there aint enuff room
		self.showIgnore=true
		currentTooltip:Show()
		self.showIgnore=false
		enhTooltipTipRect = getRect(currentTooltip, enhTooltipTipRect)

		if (enhTooltipTipRect.bottom - height < 60) then
			currentTooltip:ClearAllPoints()
			currentTooltip:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", enhTooltipTipRect.left, height+60)
		end
		EnhancedTooltip:ClearAllPoints()
		if (enhTooltipTipRect.xCenter < 6*sWidth/10) then
			EnhancedTooltip:SetPoint("TOPLEFT", currentTooltip, "BOTTOMLEFT", 0,0)
		else
			EnhancedTooltip:SetPoint("TOPRIGHT", currentTooltip, "BOTTOMRIGHT", 0,0)
		end
	end

	EnhancedTooltip:SetHeight(height)
	EnhancedTooltip:SetWidth(width)
	currentTooltip:SetWidth(width)
	EnhancedTooltip:Show()

	for ttMoney in getglobalIterator("EnhancedTooltipMoney%d") do
		if (ttMoney.myLine) then
			local myLine = getglobal(ttMoney.myLine)
			local ttMoneyWidth = ttMoney:GetWidth()
			local ttMoneyLineWidth = myLine:GetWidth()
			ttMoney:ClearAllPoints()
			if ((EnhancedTooltip.hasIcon) and (ttMoney.myLineNumber + headerCount < 4)) then
				ttMoney:SetPoint("LEFT", myLine, "RIGHT", width - ttMoneyLineWidth - ttMoneyWidth - self.moneySpacing * 2 - 34, 0)
			else
				ttMoney:SetPoint("LEFT", myLine, "RIGHT", width - ttMoneyLineWidth - ttMoneyWidth - self.moneySpacing * 2, 0)
			end
		end
	end
end

function getTooltipWidth(enhTooltip, currentTooltip)
	local width = 0
	local headerCount = enhTooltip.headerCount
	for headerLine, index in getglobalIterator(enhTooltip:GetName().."Header%d", 1, headerCount) do
		if (headerLine.myMoney) then
			if ((enhTooltip.hasIcon) and (index < 4)) then
				width = math.max(width, headerLine:GetWidth() + headerLine.myMoney:GetWidth() + self.moneySpacing + 20 + enhTooltip.hasIcon:GetWidth())
			else
				width = math.max(width, headerLine:GetWidth() + headerLine.myMoney:GetWidth() + self.moneySpacing + 20)
			end
		else
			if ((enhTooltip.hasIcon) and (index < 4)) then
				width = math.max(width, headerLine:GetWidth() + 20 + enhTooltip.hasIcon:GetWidth())
			else
				width = math.max(width, headerLine:GetWidth() + 20)
			end
		end
	end

	for currentLine, index in getglobalIterator(enhTooltip:GetName().."Text%d", 1, lineCount) do
		if (currentLine.myMoney) then
			if ((enhTooltip.hasIcon) and (index + headerCount < 4)) then
				width = math.max(width, currentLine:GetWidth() + currentLine.myMoney:GetWidth() + self.moneySpacing + 20 + enhTooltip.hasIcon:GetWidth())
			else
				width = math.max(width, currentLine:GetWidth() + currentLine.myMoney:GetWidth() + self.moneySpacing + 20)
			end
		else
			if ((enhTooltip.hasIcon) and (index + headerCount < 4)) then
				width = math.max(width, currentLine:GetWidth() + 20 + enhTooltip.hasIcon:GetWidth())
			else
				width = math.max(width, currentLine:GetWidth() + 20)
			end
		end
	end
	return width
end

function getTooltipHeight(enhTooltip, currentTooltip)
	local height = 0
	local lineCount = enhTooltip.lineCount
	local headerCount = enhTooltip.headerCount

	for headerLine in getglobalIterator(enhTooltip:GetName().."Header%d", 1, headerCount) do
		height = height + headerLine:GetHeight() + 1
	end

	for currentLine in getglobalIterator(enhTooltip:GetName().."Text%d", 1, lineCount) do
		height = height + currentLine:GetHeight() + 1
	end

	if (enhTooltip.hasIcon) then
		height = math.max(height, enhTooltip.hasIcon:GetHeight() - 6)
	end
	height = height + 20

	return height
end

-- calculate the gold, silver, and copper values based the amount of copper
function getGSC(money)
	if (not money) then money = 0 end
	local g = math.floor(money / 10000)
	local s = math.floor((money - (g*10000)) / 100)
	local c = math.ceil(money - (g*10000) - (s*100))
	return g,s,c
end

-- formats money text by color for gold, silver, copper
function getTextGSC(money, exact, dontUseColorCodes)
	local TEXT_NONE = "0"

	local GSC_GOLD="ffd100"
	local GSC_SILVER="e6e6e6"
	local GSC_COPPER="c8602c"
	local GSC_START="|cff%s%d|r"
	local GSC_PART=".|cff%s%02d|r"
	local GSC_NONE="|cffa0a0a0"..TEXT_NONE.."|r"

	if (not exact) and (money >= 10000) then
		-- Round to nearest silver
		money = math.floor(money / 100 + 0.5) * 100
	end
	local g, s, c = getGSC(money)

	local gsc = ""
	if (not dontUseColorCodes) then
		local fmt = GSC_START
		if (g > 0) then
			gsc = gsc..fmt:format(GSC_GOLD, g)
			fmt = GSC_PART
		end
		if (s > 0) or (c > 0) then
			gsc = gsc..fmt:format(GSC_SILVER, s)
			fmt = GSC_PART
		end
		if (c > 0) then
			gsc = gsc..fmt:format(GSC_COPPER, c)
		end
		if (gsc == "") then
			gsc = GSC_NONE
		end
	else
		if (g > 0) then
			gsc = gsc .. g .. "g "
		end
		if (s > 0) then
			gsc = gsc .. s .. "s "
		end
		if (c > 0) then
			gsc = gsc .. c .. "c "
		end
		if (gsc == "") then
			gsc = TEXT_NONE
		end
	end
	return gsc
end

function embedRender()
	for pos, lData in pairs(self.embedLines) do
		self.currentGametip:AddLine(lData.line)
		if (lData.r) then
			local lastLine = getglobal(self.currentGametip:GetName().."TextLeft"..self.currentGametip:NumLines())
			lastLine:SetTextColor(lData.r,lData.g,lData.b)
		end
	end
end

--[[
	@param bExact (boolean) - optional parameter
		if true, then the copper value of the given moneyAmount will always be printed out
		if false (default), then the copper value of the given moneyAmount will not be printed out, if the moneyAmount is too high (see getTextGSC for the exact limit)
		bExact has no meaning, if moneyAmount is nil.
]]
function addLine(lineText, moneyAmount, embed, bExact)
	if (embed) and (self.currentGametip) then
		EnhancedTooltip.hasEmbed = true
		EnhancedTooltip.curEmbed = true
		local line = ""
		if (moneyAmount) then
			line = lineText .. ": " .. getTextGSC(moneyAmount, bExact)
		else
			line = lineText
		end
		table.insert(self.embedLines, {line = line})
		return
	end
	EnhancedTooltip.hasData = true
	EnhancedTooltip.curEmbed = false

	local curLine = EnhancedTooltip.lineCount + 1

	local line
	if (curLine > self.lastFontStringIndex) then
		line = createNewFontString(EnhancedTooltip)
	else
		line = getglobal("EnhancedTooltipText"..curLine)
	end

	line:SetText(lineText)
	line:SetTextColor(1.0, 1.0, 1.0)
	line:Show()
	local lineWidth = line:GetWidth()

	EnhancedTooltip.lineCount = curLine
	if (moneyAmount and moneyAmount > 0) then
		local curMoney = EnhancedTooltip.moneyCount + 1

		local money
		if (curMoney > self.lastMoneyObjectIndex) then
			money = createNewMoneyObject(EnhancedTooltip)
		else
			money = getglobal("EnhancedTooltipMoney"..curMoney)
		end

		money:SetPoint("LEFT", line, "RIGHT", self.moneySpacing, 0)
		TinyMoneyFrame_Update(money, math.floor(moneyAmount))
		money.myLine = line:GetName()
		money.myLineNumber = curLine
		line.myMoney = money
		money:Show()
		getglobal("EnhancedTooltipMoney"..curMoney.."SilverButtonText"):SetTextColor(1.0,1.0,1.0)
		getglobal("EnhancedTooltipMoney"..curMoney.."CopperButtonText"):SetTextColor(0.86,0.42,0.19)
		EnhancedTooltip.moneyCount = curMoney
	end
end

function addHeaderLine(lineText, moneyAmount, embed, bExact)
	moneyAmount = nil
	if (not lineText) then
		return
	end
	local curHeader = EnhancedTooltip.headerCount + 1
	EnhancedTooltip.headerCount = curHeader

	if (embed) and (self.currentGametip) then
		EnhancedTooltip.hasEmbed = true
		EnhancedTooltip.curHeaderEmbed = true
		local line = ""
		if (moneyAmount) then
			line = lineText .. ": " .. getTextGSC(moneyAmount, bExact)
		else
			line = lineText
		end
		table.insert(self.embedLines, curHeader, {line = line})
		return
	end
	EnhancedTooltip.hasData = true
	EnhancedTooltip.curHeaderEmbed = false


	local line
	if (curHeader > self.lastHeaderFontStringIndex) then
		line = createNewHeaderFontString(EnhancedTooltip)
	else
		line = getglobal("EnhancedTooltipHeader"..curHeader)
	end

	line:SetText(lineText)
	line:SetTextColor(1.0, 1.0, 1.0)
	line:Show()
	local lineWidth = line:GetWidth()


	if (moneyAmount and moneyAmount > 0) then
		local curMoney = EnhancedTooltip.moneyCount + 1

		local money
		if (curMoney > self.lastMoneyObjectIndex) then
			money = createNewMoneyObject(EnhancedTooltip)
		else
			money = getglobal("EnhancedTooltipMoney"..curMoney)
		end

		money:SetPoint("LEFT", line, "RIGHT", self.moneySpacing, 0)
		TinyMoneyFrame_Update(money, math.floor(moneyAmount))
		money.myLine = line:GetName()
		money.myLineNumber = curHeader
		line.myMoney = money
		money:Show()
		getglobal("EnhancedTooltipMoney"..curMoney.."SilverButtonText"):SetTextColor(1.0,1.0,1.0)
		getglobal("EnhancedTooltipMoney"..curMoney.."CopperButtonText"):SetTextColor(0.86,0.42,0.19)
		EnhancedTooltip.moneyCount = curMoney
	end
end

function addSeparator(embed)
	if (embed) and (self.currentGametip) then
		EnhancedTooltip.hasEmbed = true
		EnhancedTooltip.curEmbed = true
		table.insert(self.embedLines, {line = " "})
		return
	end
	EnhancedTooltip.hasData = true
	EnhancedTooltip.curEmbed = false

	local curLine = EnhancedTooltip.lineCount + 1
	local line = getglobal("EnhancedTooltipText"..curLine)
	line:SetText(" ")
	line:SetTextColor(1.0, 1.0, 1.0)
	line:Show()
	EnhancedTooltip.lineCount = curLine
end

function lineColor(r, g, b)
	if (EnhancedTooltip.curEmbed) and (self.currentGametip) then
		local n = #self.embedLines
		self.embedLines[n].r = r
		self.embedLines[n].g = g
		self.embedLines[n].b = b
		return
	end
	local curLine = EnhancedTooltip.lineCount
	if (curLine == 0) then return end
	local line = getglobal("EnhancedTooltipText"..curLine)
	return line:SetTextColor(r, g, b)
end

function lineSize(fontSize)
	if (EnhancedTooltip.curEmbed) and (self.currentGametip) then
		return
	end

	local curLine = EnhancedTooltip.lineCount
	if (curLine == 0) then
		return
	end

	local line = getglobal("EnhancedTooltipText"..curLine)
	return line:SetFont(STANDARD_TEXT_FONT, fontSize)
end

function headerColor(r, g, b)
	local curLine = EnhancedTooltip.headerCount
	if (EnhancedTooltip.curHeaderEmbed) and (self.currentGametip) then
		self.embedLines[curLine].r = r
		self.embedLines[curLine].g = g
		self.embedLines[curLine].b = b
		return
	end
	if (curLine == 0) then return end
	local line = getglobal("EnhancedTooltipHeader"..curLine)
	return line:SetTextColor(r, g, b)
end

function headerSize(fontSize)
	if (EnhancedTooltip.curHeaderEmbed) and (self.currentGametip) then
		return
	end

	local curLine = EnhancedTooltip.headerCount
	if (curLine == 0) then
		return
	end

	local line = getglobal("EnhancedTooltipHeader"..curLine)
	return line:SetFont(STANDARD_TEXT_FONT, fontSize)
end

function headerQuality(quality)
	if ( quality ) then
		return headerColor(GetItemQualityColor(quality))
	else
		return headerColor(1.0, 1.0, 1.0)
	end
end

function lineSize_Large()
	debugPrint("lineSize_Large() Called. This function is DEPRECATED. Use lineSize(12) instead.")
	return lineSize(12)
end

function lineSize_Small()
	debugPrint("lineSize_Large() Called. This function is DEPRECATED. Use lineSize(11) instead.")
	return lineSize(10)
end

function lineQuality(quality)
	if ( quality ) then
		return lineColor(GetItemQualityColor(quality))
	else
		return lineColor(1.0, 1.0, 1.0)
	end
end

function setIcon(iconPath)
	EnhancedTooltipIcon:SetTexture(iconPath)
	EnhancedTooltipIcon:Show()
	EnhancedTooltip.hasIcon = EnhancedTooltipIcon
end

function gtHookOnHide()
	local curName = ""
	local hidingName = this:GetName()
	if (self.currentGametip) then curName = self.currentGametip:GetName() end
	if (curName == hidingName) then
		HideObj = hidingName
		self.hideTime = self.eventTimer + 0.1
	end
end

function doHyperlink(reference, link, button)
	if (ItemRefTooltip:IsVisible()) then
		local itemName = ItemRefTooltipTextLeft1:GetText()
		if (itemName and self.currentItem ~= itemName) then
			self.currentItem = itemName

			local testPopup = false
			if (button == "RightButton") then
				testPopup = true
			end
			local callRes = tooltipCall(ItemRefTooltip, itemName, link, -1, 1, 0, testPopup, reference)
			if (callRes == true) then
				self.oldChatItem = {reference = reference, link = link, button = button, embed = EnhancedTooltip.hasEmbed}
			elseif (callRes == false) then
				return false
			end
		end
	end
end

function checkHide()
	if (self.hideTime == 0) then return end

	if (self.eventTimer >= self.hideTime) then
		hideTooltip()
		if (HideObj and HideObj == "ItemRefTooltip") then
			-- closing chatreferenceTT?
			self.oldChatItem = nil -- remove old chatlink data
		elseif self.oldChatItem then
			-- closing another tooltip
			-- redisplay old chatlinkdata, if it was not embeded
			if not self.oldChatItem.embed then
				doHyperlink(self.oldChatItem.reference, self.oldChatItem.link, self.oldChatItem.button)
			end
		end
	end
end

------------------------
-- ItemLink functions
------------------------

function linkType(link)
	if type(link) ~= "string" then
		return
	end
	return link:match("|H(%a+):")
end

function nameFromLink(link)
	if (not link) then
		return
	end
	return link:match("|c%x+|Hitem:%p?%d+:%p?%d+:%p?%d+:%p?%d+:%p?%d+:%p?%d+:%p?%d+:%p?%d+|h%[(.-)%]|h|r")
end

function hyperlinkFromLink(link)
	if( not link ) then
		return
	end
	return link:match("|H([^|]+)|h")
end

function baselinkFromLink(link)
	if( not link ) then
		return
	end
	return link:match("|Hitem:(%p?%d+:%p?%d+:%p?%d+:%p?%d+:%p?%d+:%p?%d+:%p?%d+:%p?%d+):%p?%d+|h")
end

function qualityFromLink(link)
	if (not link) then return end
	local color = link:match("(|c%x+)|Hitem:%p?%d+:%p?%d+:%p?%d+:%p?%d+:%p?%d+:%p?%d+:%p?%d+:%p?%d+|h%[.-%]|h|r")
	if (color) then
		for i = 0, 6 do
			local _, _, _, hex = GetItemQualityColor(i)
			if color == hex then
				return i
			end
		end
	end
	return -1
end

function fakeLink(hyperlink, quality, name)
	-- make this function nilSafe, as it's a global one and might be used by external addons
	if (not hyperlink) then
		return
	end
	local sName, sLink, iQuality = GetItemInfo(hyperlink)

	if (sLink) then
		return sLink
	else
		if (not quality) then
			quality = iQuality or -1
		end
		if (not name) then
			name = sName or "unknown"
		end
		local _, _, _, color = GetItemQualityColor(quality)
		return color.. "|H"..hyperlink.."|h["..name.."]|h|r"
	end
end

-- Given a Blizzard item link, breaks it into it's itemID, randomProperty, enchantProperty, uniqueness, name and the four gemSlots.
function breakLink(link)
	if (type(link) ~= 'string') then return end
	local itemID, enchant, gemSlot1, gemSlot2, gemSlot3, gemSocketBonus, randomProp, uniqID, name = link:match("|Hitem:(%p?%d+):(%p?%d+):(%p?%d+):(%p?%d+):(%p?%d+):(%p?%d+):(%p?%d+):(%p?%d+)|h%[(.-)%]|h")
	return tonumber(itemID) or 0, tonumber(randomProp) or 0, tonumber(enchant) or 0, tonumber(uniqID) or 0, tostring(name), tonumber(gemSlot1) or 0, tonumber(gemSlot2) or 0, tonumber(gemSlot3) or 0, tonumber(gemSocketBonus) or 0
end

------------------------
-- Tooltip generating function
------------------------

function tooltipCall(frame, name, link, quality, count, price, forcePopup, hyperlink)
	self.currentGametip = frame
	self.hideTime = 0

	local itemSig = frame:GetName()
	if (link) then itemSig = itemSig..link end
	if (count) then itemSig = itemSig..count end
	if (price) then itemSig = itemSig..price end

	if (self.currentItem and self.currentItem == itemSig) then
		-- We are already showing this... No point doing it again.
		showTooltip(self.currentGametip)
		return
	end

	self.currentItem = itemSig

	quality = quality or qualityFromLink(link)
	hyperlink = hyperlink or link
	local extract = hyperlinkFromLink(hyperlink)
	hyperlink = extract or hyperlink

	local showTip = true
	local popupKeyPressed = (
		(self.forcePopupKey == "ctrl" and IsControlKeyDown()) or
		(self.forcePopupKey == "alt" and IsAltKeyDown()) or
		(self.forcePopupKey == "shift" and IsShiftKeyDown())
	)

	if ((forcePopup == true) or ((forcePopup == nil) and (popupKeyPressed))) then
		local popupTest = checkPopup(name, link, quality, count, price, hyperlink)
		if (popupTest) then
			showTip = false
		end
	end

	if (showTip) then
		clearTooltip()
		self.showIgnore = true
		EnhTooltip.AddTooltip(frame, name, link, quality, count, price)
		self.showIgnore = false
		showTooltip(frame)
		self.currentItem = itemSig
		return true
	else
		frame:Hide()
		hideTooltip()
		return false
	end
end

------------------------
-- Hook calling functions
------------------------

function callCheckPopup(name, link, quality, count, price, hyperlink)
	if (EnhTooltip.CheckPopup(name, link, quality, count, price, hyperlink)) then
		return true
	end
	return false
end

function merchantScanner()
	local npcName = UnitName("NPC")
	local numMerchantItems = GetMerchantNumItems()
	local link, quality, name, texture, price, quantity, numAvailable, isUsable
	for i=1, numMerchantItems, 1 do
		link = GetMerchantItemLink(i)
		quality = qualityFromLink(link)
		name, texture, price, quantity, numAvailable, isUsable = GetMerchantItemInfo(i)
		return EnhTooltip.MerchantHook(npcName, i, name, link, quality, quantity, price, numAvailable)
	end
end

function callBankHook()
	if not (BankFrame and BankFrame:IsVisible()) then return end
	return EnhTooltip.BankHook(0)
end

function callBagHook(funcVars, event, bagNumber)
	if (bagNumber >= 5) and (bagNumber < 10) then
		if not (BankFrame and BankFrame:IsVisible()) then return end
		return EnhTooltip.BankHook(bagNumber)
	else
		return EnhTooltip.BagHook(bagNumber)
	end
end

function callTradeHook(funcVars, event, selID)
	return EnhTooltip.TradeHook(funcVars[1], selID)
end



------------------------
-- Tooltip functions that we have hooked
------------------------

function chatHookOnHyperlinkShow(funcArgs, retVal, reference, link, button)
	if (IsAltKeyDown()) and AuctionFrame and (AuctionFrame:IsVisible()) then
		AuctionFrameTab_OnClick(1)
		local itemName = GetItemInfo(tostring(link))
		if (itemName) then
			BrowseName:SetText(itemName)
			BrowseMinLevel:SetText("")
			BrowseMaxLevel:SetText("")
			AuctionFrameBrowse.selectedInvtype = nil
			AuctionFrameBrowse.selectedInvtypeIndex = nil
			AuctionFrameBrowse.selectedClass = nil
			AuctionFrameBrowse.selectedClassIndex = nil
			AuctionFrameBrowse.selectedSubclass = nil
			AuctionFrameBrowse.selectedSubclassIndex = nil
			AuctionFrameFilters_Update()
			IsUsableCheckButton:SetChecked(0)
			UIDropDownMenu_SetSelectedValue(BrowseDropDown, -1)
			AuctionFrameBrowse_Search()
			BrowseNoResultsText:SetText(BROWSE_NO_RESULTS)
			ItemRefTooltip:Hide()
		end
		return
	end
	return doHyperlink(reference, link, button)
end

function afHookOnEnter(funcArgs, retVal, type, index)
	local link = GetAuctionItemLink(type, index)
	if (link) then
		local name = nameFromLink(link)
		if (name) then
			local aiName, aiTexture, aiCount, aiQuality, aiCanUse, aiLevel, aiMinBid, aiMinIncrement, aiBuyoutPrice, aiBidAmount, aiHighBidder, aiOwner = GetAuctionItemInfo(type, index)
			return tooltipCall(GameTooltip, name, link, aiQuality, aiCount)
		end
	end
end

function cfHookUpdate(funcArgs, retVal, frame)
	local frameID = frame:GetID()
	local frameName = frame:GetName()
	local iButton
	for iButton = 1, frame.size do
		local button = getglobal(frameName.."Item"..iButton)
		if (GameTooltip:IsOwned(button)) then
			local buttonID = button:GetID()
			local link = GetContainerItemLink(frameID, buttonID)
			local name = nameFromLink(link)

			if (name) then
				local texture, itemCount, locked, quality, readable = GetContainerItemInfo(frameID, buttonID)
				quality = quality or qualityFromLink(link)

				return tooltipCall(GameTooltip, name, link, quality, itemCount)
			end
		end
	end
end

function gtHookSetLootItem(funcArgs, retVal, frame, slot)
	local link = GetLootSlotLink(slot)
	local name = nameFromLink(link)
	if (name) then
		local texture, item, quantity, quality = GetLootSlotInfo(slot)
		quality = quality or qualityFromLink(link)
		return tooltipCall(GameTooltip, name, link, quality, quantity)
	end
end

function gtHookSetQuestItem(funcArgs, retVal, frame, qtype, slot)
	local link = GetQuestItemLink(qtype, slot)
	if (link) then
		local name, texture, quantity, quality, usable = GetQuestItemInfo(qtype, slot)
		return tooltipCall(GameTooltip, name, link, quality, quantity)
	end
end

function gtHookSetQuestLogItem(funcArgs, retVal, frame, qtype, slot)
	local link = GetQuestLogItemLink(qtype, slot)
	if (link) then
		local name, texture, quantity, quality, usable = GetQuestLogRewardInfo(slot)
		name = name or nameFromLink(link)
		quality = qualityFromLink(link) -- I don't trust the quality returned from the above function.

		return tooltipCall(GameTooltip, name, link, quality, quantity)
	end
end

function gtHookSetBagItem(funcArgs, retVal, frame, frameID, buttonID)
	local link = GetContainerItemLink(frameID, buttonID)
	local name = nameFromLink(link)

	if (name) then
		local texture, itemCount, locked, quality, readable = GetContainerItemInfo(frameID, buttonID)
		quality = (quality ~= -1 and quality) or qualityFromLink(link)

		return tooltipCall(GameTooltip, name, link, quality, itemCount)
	end
end

function gtHookSetInboxItem(funcArgs, retVal, frame, index)
	local inboxItemName, itemTexture, inboxItemCount, inboxItemQuality = GetInboxItem(index)
	local itemName, itemLink, itemQuality

	for itemID = 1, 30000 do
		itemName, itemLink, itemQuality = GetItemInfo(itemID)
		if (itemName and itemName == inboxItemName) then
			return tooltipCall(GameTooltip, inboxItemName, itemLink, inboxItemQuality, inboxItemCount)
		end
	end
end

function gtHookSetInventoryItem(funcArgs, retVal, frame, unit, slot)
	local link = GetInventoryItemLink(unit, slot)
	if (link) then
		local name = nameFromLink(link)
		local quantity
		if (slot >= 20 and slot <= 23) then
			-- Workaround for bag slots. Quiver slots report the number of
			-- arrows in there instead of 1 for the actual bag.
			-- And well, bags aren't stackable anyway, so here you go:
			quantity = 1
		else
			-- Should be 1 for anything but quivers, because even empty slots
			-- return 1.. but who knows what crazy stuff Blizzard will add ;)
			quantity = GetInventoryItemCount(unit, slot)
		end
		local quality = GetInventoryItemQuality(unit, slot)
		quality = quality or qualityFromLink(link)

		return tooltipCall(GameTooltip, name, link, quality, quantity)
	end
end

function gtHookSetMerchantItem(funcArgs, retVal, frame, slot)
	local link = GetMerchantItemLink(slot)
	if (link) then
		local name, texture, price, quantity, numAvailable, isUsable = GetMerchantItemInfo(slot)
		local quality = qualityFromLink(link)
		return tooltipCall(GameTooltip, name, link, quality, quantity, price)
	end
end

function gtHookSetCraftItem(funcArgs, retVal, frame, skill, slot)
	local link
	if (slot) then
		link = GetCraftReagentItemLink(skill, slot)
		if (link) then
			local name, texture, quantity, quantityHave = GetCraftReagentInfo(skill, slot)
			local quality = qualityFromLink(link)
			return tooltipCall(GameTooltip, name, link, quality, quantity, 0)
		end
	else
		link = GetCraftItemLink(skill)
		if (link) then
			local name = nameFromLink(link)
			local quality = qualityFromLink(link)
			return tooltipCall(GameTooltip, name, link, quality, 1, 0)
		end
	end
end

function gtHookSetCraftSpell(funcArgs, retVal, frame, slot)
	local name = GetCraftInfo(slot)
	local link = GetCraftItemLink(slot)
	if name and link then
		return tooltipCall(GameTooltip, name, link)
	end
end

function gtHookSetTradeSkillItem(funcArgs, retVal, frame, skill, slot)
	local link
	if (slot) then
		link = GetTradeSkillReagentItemLink(skill, slot)
		if (link) then
			local name, texture, quantity, quantityHave = GetTradeSkillReagentInfo(skill, slot)
			local quality = qualityFromLink(link)
			return tooltipCall(GameTooltip, name, link, quality, quantity, 0)
		end
	else
		link = GetTradeSkillItemLink(skill)
		if (link) then
			local name = nameFromLink(link)
			local quality = qualityFromLink(link)
			return tooltipCall(GameTooltip, name, link, quality, 1, 0)
		end
	end
end

function findItemInBags(findName)
	for bag = 0, 4, 1 do
		size = GetContainerNumSlots(bag)
		if (size) then
			for slot = size, 1, -1 do
				local link = GetContainerItemLink(bag, slot)
				if (link) then
					local itemID, randomProp, enchant, uniqID, itemName = breakLink(link)
					if (itemName == findName) then
						return bag, slot, itemID, randomProp, enchant, uniqID
					end
				end
			end
		end
	end
end

function gtHookSetAuctionSellItem(funcArgs, retVal, frame)
	local name, texture, quantity, quality, canUse, price = GetAuctionSellItemInfo()
	if (name) then
		local bag, slot = findItemInBags(name)
		if (bag) then
			local link = GetContainerItemLink(bag, slot)
			if (link) then
				return tooltipCall(GameTooltip, name, link, quality, quantity, price)
			end
		end
	end
end

function gtHookSetText(funcArgs, retval, frame, text, r, g, b, a, textWrap)
	-- Nothing to do for plain text
	if (self.currentGametip == frame) then
		return clearTooltip()
	end
end

function gtHookAppendText(funcArgs, retVal, frame)
	if (self.currentGametip and self.currentItem and self.currentItem ~= "") then
		return showTooltip(self.currentGametip, true)
	end
end

function gtHookShow(funcArgs, retVal, frame)
	if (self.hookRecursion) then
		return
	end
	if (self.currentGametip and self.currentItem and self.currentItem ~= "") then
		self.hookRecursion = true
		showTooltip(self.currentGametip, true)
		self.hookRecursion = nil
	end
end

function imiHookOnEnter()
	if(not IM_InvList) then return end
	local id = this:GetID()

	if(id == 0) then
		id = this:GetParent():GetID()
	end
	local offset = FauxScrollFrame_GetOffset(ItemsMatrix_IC_ScrollFrame)
	local item = IM_InvList[id + offset]

	if (not item) then return end
	local imlink = ItemsMatrix_GetHyperlink(item.name)
	local link = fakeLink(imlink, item.quality, item.name)
	if (link) then
		return tooltipCall(GameTooltip, item.name, link, item.quality, item.count, 0)
	end
end

function imHookOnEnter()
	local imlink = ItemsMatrix_GetHyperlink(this:GetText())
	if (imlink) then
		local name = this:GetText()
		local link = fakeLink(imlink, -1, name)
		return tooltipCall(GameTooltip, name, link, -1, 1, 0)
	end
end

function getLootLinkServer()
	return LootLinkState.ServerNamesToIndices[GetCVar("realmName")]
end

function getLootLinkLink(name)
	local itemLink = ItemLinks[name]
	if (itemLink and itemLink.c and itemLink.i and LootLink_CheckItemServer(itemLink, getLootLinkServer())) then
		local item = itemLink.i:gsub("(%d+):(%d+):(%d+):(%d+)", "%1:0:%3:%4")
		local link = "|c"..itemLink.c.."|Hitem:"..item.."|h["..name.."]|h|r"
		return link
	end
	return
end

function llHookOnEnter()
	local name = this:GetText()
	local link = getLootLinkLink(name)
	if (link) then
		local quality = qualityFromLink(link)
		return tooltipCall(LootLinkTooltip, name, link, quality, 1, 0)
	end
end

function gtHookSetOwner(funcArgs, retVal, frame, owner, anchor)
	frame.owner = owner
	frame.anchor = anchor
end

------------------------
-- Operation functions
------------------------

function setElapsed(elapsed)
	if (elapsed) then
		self.eventTimer = self.eventTimer + elapsed
	end
	checkHide()
	return self.eventTimer
end

function setMoneySpacing(spacing)
	self.moneySpacing = spacing or self.moneySpacing
	return self.moneySpacing
end

function setPopupKey(key)
	self.forcePopupKey = key or self.forcePopupKey
	return self.forcePopupKey
end


------------------------
-- Debug functions
------------------------

local function dump(...)
	local out = ""
	local numVarArgs = select("#", ...)
	for i = 1, numVarArgs do
		local d = select(i, ...)
		local t = type(d)
		if (t == "table") then
			out = out .. "{"
			local first = true
			if (d) then
				for k, v in pairs(d) do
					if (not first) then out = out .. ", " end
					first = false
					out = out .. dump(k)
					out = out .. " = "
					out = out .. dump(v)
				end
			end
			out = out .. "}"
		elseif (t == "nil") then
			out = out .. "NIL"
		elseif (t == "number") then
			out = out .. d
		elseif (t == "string") then
			out = out .. "\"" .. d .. "\""
		elseif (t == "boolean") then
			if (d) then
				out = out .. "true"
			else
				out = out .. "false"
			end
		else
			out = out .. t:upper() .. "??"
		end

		if (i < numVarArgs) then out = out .. ", " end
	end
	return out
end

local lastOut = ""
function debugPrint(...)
	local debugWin
	for i=1, NUM_CHAT_WINDOWS do
		if (GetChatWindowInfo(i):lower() == "ettdebug") then
			debugWin = i
			break
		end
	end
	if (not debugWin) then
		return
	end

	local out = ""
	for i = 1, select("#", ...) do
		if (i > 1) then out = out .. ", " end
		local currentArg = select(i, ...)
		local argType = type(currentArg)
		if (argType == "string") then
			out = out .. '"'..currentArg..'"'
		elseif (argType == "number") then
			out = out .. currentArg
		else
			out = out .. dump(currentArg)
		end
	end

	if (out ~= lastOut) then
		getglobal("ChatFrame"..debugWin):AddMessage(out, 1.0, 1.0, 0.3)
		lastOut = out
	end
end


------------------------
-- Load and initialization functions
------------------------

--The new blizzard addons are called:
--	Blizzard_TrainerUI,		Blizzard_MacroUI,		Blizzard_RaidUI,		Blizzard_TradeSkillUI,
--	Blizzard_InspectUI,		Blizzard_BattlefieldMinimap,	Blizzard_TalentUI,
--	Blizzard_AuctionUI,		Blizzard_BindingUI,		Blizzard_CraftUI


-- Hook in alternative Auctionhouse tooltip code
local function hookAuctionHouse()
	Stubby.RegisterFunctionHook("AuctionFrameItem_OnEnter", 200, afHookOnEnter)
end

-- Hook the ItemsMatrix tooltip functions
local function hookItemsMatrix()
	Stubby.RegisterFunctionHook("IMInv_ItemButton_OnEnter", 200, imiHookOnEnter)
	Stubby.RegisterFunctionHook("ItemsMatrixItemButton_OnEnter", 200, imHookOnEnter)
end

-- Hook the LootLink tooltip function
local function hookLootLink()
	if (LootLinkItemButton_OnEnter) then
		Stubby.RegisterFunctionHook("LootLinkItemButton_OnEnter", 200, llHookOnEnter)
	end
end

-- Hook tradeskill functions
local function hookTradeskill()
	Stubby.RegisterFunctionHook("TradeSkillFrame_Update", 200, callTradeHook, "trade", "")
	Stubby.RegisterFunctionHook("TradeSkillFrame_SetSelection", 200, callTradeHook, "trade", "")
end

-- Hook craft functions
local function hookCraft()
	Stubby.RegisterFunctionHook("CraftFrame_Update", 200, callTradeHook, "craft", "")
	Stubby.RegisterFunctionHook("CraftFrame_SetSelection", 200, callTradeHook, "craft", "")
end

function ttInitialize()
	----  Establish hooks to all the game tooltips.

	-- Hook in alternative Chat/Hyperlinking code
	Stubby.RegisterFunctionHook("ChatFrame_OnHyperlinkShow", 200, chatHookOnHyperlinkShow)

	-- Container frame linking
	Stubby.RegisterFunctionHook("ContainerFrame_Update", 200, cfHookUpdate)

	-- Game tooltips
	Stubby.RegisterFunctionHook("GameTooltip.SetLootItem", 200, gtHookSetLootItem)
	Stubby.RegisterFunctionHook("GameTooltip.SetQuestItem", 200, gtHookSetQuestItem)
	Stubby.RegisterFunctionHook("GameTooltip.SetQuestLogItem", 200, gtHookSetQuestLogItem)
	Stubby.RegisterFunctionHook("GameTooltip.SetInboxItem", 200, gtHookSetInboxItem)
	Stubby.RegisterFunctionHook("GameTooltip.SetInventoryItem", 200, gtHookSetInventoryItem)
	Stubby.RegisterFunctionHook("GameTooltip.SetBagItem", 200, gtHookSetBagItem)
	Stubby.RegisterFunctionHook("GameTooltip.SetMerchantItem", 200, gtHookSetMerchantItem)
	Stubby.RegisterFunctionHook("GameTooltip.SetCraftItem", 200, gtHookSetCraftItem)
	Stubby.RegisterFunctionHook("GameTooltip.SetCraftSpell", 200, gtHookSetCraftSpell)
	Stubby.RegisterFunctionHook("GameTooltip.SetTradeSkillItem", 200, gtHookSetTradeSkillItem)
	Stubby.RegisterFunctionHook("GameTooltip.SetAuctionSellItem", 200, gtHookSetAuctionSellItem)
	Stubby.RegisterFunctionHook("GameTooltip.SetText", 200, gtHookSetText)
	Stubby.RegisterFunctionHook("GameTooltip.AppendText", 200, gtHookAppendText)
	Stubby.RegisterFunctionHook("GameTooltip.SetOwner", 200, gtHookSetOwner)
	Stubby.RegisterFunctionHook("GameTooltip.Show", 200, gtHookShow)
	Stubby.RegisterFunctionHook("GameTooltip_OnHide", 200, gtHookOnHide)

	-- Establish hooks for us to use.
	Stubby.RegisterAddOnHook("Blizzard_AuctionUI", "EnhTooltip", hookAuctionHouse)
	Stubby.RegisterAddOnHook("ItemsMatrix", "EnhTooltip", hookItemsMatrix)
	Stubby.RegisterAddOnHook("LootLink", "EnhTooltip", hookLootLink)
	Stubby.RegisterAddOnHook("Blizzard_TradeSkillUI", "EnhTooltip", hookTradeskill)
	Stubby.RegisterAddOnHook("Blizzard_CraftUI", "EnhTooltip", hookCraft)

	-- Register event notification
	Stubby.RegisterEventHook("MERCHANT_SHOW", "EnhTooltip", merchantScanner)
	Stubby.RegisterEventHook("TRADE_SKILL_SHOW", "EnhTooltip", callTradeHook, 'trade')
	Stubby.RegisterEventHook("TRADE_SKILL_CLOSE", "EnhTooltip", callTradeHook, 'trade')
	Stubby.RegisterEventHook("CRAFT_SHOW", "EnhTooltip", callTradeHook, 'craft')
	Stubby.RegisterEventHook("CRAFT_CLOSE", "EnhTooltip", callTradeHook, 'craft')
	Stubby.RegisterEventHook("BANKFRAME_OPENED", "EnhTooltip", callBankHook)
	Stubby.RegisterEventHook("PLAYERBANKSLOTS_CHANGED", "EnhTooltip", callBankHook)
	Stubby.RegisterEventHook("BAG_UPDATE", "EnhTooltip", callBagHook)
end


-- =============== EVENT HANDLERS =============== --

function onLoad()
	EnhancedTooltip:SetBackdropColor(0,0,0)
	clearTooltip()
	ttInitialize()
end

-- =============== DEFINE ACCESS OBJECT =============== --

-- Global object
EnhTooltip = {
	AddTooltip			= addTooltip,
	CheckPopup			= checkPopup,
	MerchantHook		= merchantHook,
	TradeHook			= tradeHook,
	BankHook			= bankHook,
	BagHook				= bagHook,

	AddLine				= addLine,
	AddSeparator		= addSeparator,
	LineColor			= lineColor,
	LineQuality			= lineQuality,
	LineSize			= lineSize,
	LineSize_Large		= lineSize_Large, --Deprecated, use EnhTooltip.LineSize instead
	LineSize_Small		= lineSize_Small, --Deprecated, use EnhTooltip.LineSize instead
	SetIcon				= setIcon,

	AddHeaderLine		= addHeaderLine,
	HeaderColor			= headerColor,
	HeaderQuality		= headerQuality,
	HeaderSize			= headerSize,

	ClearTooltip		= clearTooltip,
	HideTooltip			= hideTooltip,
	ShowTooltip			= showTooltip,

	GetglobalIterator	= getglobalIterator,
	GetRect				= getRect,
	GetGSC				= getGSC,
	GetTextGSC			= getTextGSC,
	BaselinkFromLink	= baselinkFromLink,
	BreakLink			= breakLink,
	FindItemInBags		= findItemInBags,

	FakeLink			= fakeLink,
	HyperlinkFromLink	= hyperlinkFromLink,
	NameFromLink		= nameFromLink,
	QualityFromLink		= qualityFromLink,
	LinkType			= linkType,

	SetMoneySpacing		= setMoneySpacing,
	SetPopupKey			= setPopupKey,
	TooltipCall			= tooltipCall,

	SetElapsed			= setElapsed,
	DebugPrint			= debugPrint,
	OnLoad				= onLoad,

	Version				= ENHTOOLTIP_VERSION,
}
