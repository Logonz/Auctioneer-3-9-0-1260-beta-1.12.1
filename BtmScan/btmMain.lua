--[[
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

BottomScanner  -  An AddOn for WoW to alert you to good purchases as they appear on the AH
$Id: btmMain.lua 1966 2007-06-03 22:36:27Z ccox $
Copyright (c) 2006, Norganna

Documentation of the various member variables used in this module:

BtmScan.interval - How many seconds between new last page Queries
	set to 1 when query isn't available for some reason, to try again in 1 second; also right after you hit the play button to schedule the first scan
	set to 6 when BTM query first starts and we are trying to zero in on last page, and also when value was previously nil (not sure how this would happen)
	set to 25 (actually BtmScanData.refresh, but I think this is only set to 25) once we have gotten the last page nailed
	set to 30 on module load, but I don't think this gets used anywhere
BtmScan.offset - how many pages back from last page to scan (will be 0 normally, 1 every 5th page scan)
BtmScan.lasttry - the .timer value from the previous attempt (I think this is used to create the Log window, and maybe to control the flashing it used to do)
BtmScan.auctPriceModel - used in creating the BtmScanner price model in Auctioneer
BtmScan.timer - seconds since the last scheduled scan start; gets reset to 0 after any purchase decision
BtmScan.pageScan - time between scans of the current query results (set to shorter than .interval in order to allow multiple passes through results without requerying, as when a purchase attempt breaks PageScan() early)
	set to 0.001 after any purchase dialog result or when piggybacking on currently running query (auctioneer scan or manual), to cause immediate search of current results
	set to 2 after a new last page query is sent to AH (to give results time to return)
	set to nil once PageScan() begins (to prevent repeated attempts to check this page of items unless we break out early for a purchase and need to resume later)
BtmScan.scanStage
	0 - no longer scanning page / reached end of query page
	1 - 0.25 seconds before next scan begins - I have no idea what this is used for
	2 - scanning page
	3 - prompting for a purchase / scanning paused
BtmScan.scanning - are we currently scanning
BtmScan.pageCount - number of pages in the AH
BtmScan.resume - index to resume bargain search for in PageScan() [needed after breaking out of scan to prompt for a bid, to avoid double bidding and generally be slightly more efficient]
	set to a value just prior to breaking out of PageScan() for a purchase opportunity
	set to nil on init, when PageScan() completes successfully, or when bottom scanning is ended
]]

BtmScanData = {}
local tr = BtmScan.Locales.Translate
local data, dataZone

-- Used to control whether BTM tooltip includes help message for items with no "sanity" price history
-- Preferred setting is true, to eliminate tooltip (for BoP items and others which can't be auctioned)
-- Right after updates when we don't have all new items uploaded, can be set to false
local upToDateConservativePrices = false

-- Used in BtmScan.CanSendAuctionQuery() to disable the additional checks
-- performed in the hooked CanSendAuctionQuery() function. This is necessary
-- since we'd otherwise lock ourselves off from scanning, instead of other
-- addons.
local hookCanSendAuctionQuery = true -- (boolean)

BTMSCAN_VERSION = "4.0.5"
if (BTMSCAN_VERSION == "<\037version%>") then
	BTMSCAN_VERSION = "3.9.0-DEV"
end
BtmScan.Version = BTMSCAN_VERSION

BtmScan.NoPrompt = {}
BtmScan.resume = nil

-- Load function gets run when this addon has loaded.
BtmScan.OnLoad = function ()
	BtmScan.Print(tr("Welcome to BottomScanner. Type /btm for help"))

	-- Register our command handlers
	SLASH_BTMSCAN1 = "/btm"
	SLASH_BTMSCAN2 = "/btmscan"
	SLASH_BTMSCAN3 = "/bottomscan"
	SLASH_BTMSCAN4 = "/bottomscanner"
	SlashCmdList["BTMSCAN"] = BtmScan.Command

	-- Ensure sane defaults
	if (not BtmScanData.config) then BtmScanData.config = {} end
	if (not BtmScanData.factions) then BtmScanData.factions = {} end

	Stubby.RegisterFunctionHook("EnhTooltip.AddTooltip", 600, BtmScan.TooltipHook)
	Stubby.RegisterFunctionHook("QueryAuctionItems", 600, BtmScan.QueryAuctionItems)
	Stubby.RegisterFunctionHook("CanSendAuctionQuery", 10, BtmScan.PostCanSendAuctionQuery)

	-- Register our temporary command hook with stubby
	Stubby.RegisterBootCode("BtmScan", "CommandHandler", [[
		local function cmdHandler(msg)
			local cmd, param = msg:lower():match("^(%w+)%s*(.*)$")
			cmd = cmd or msg:lower() or "";
			param = param or "";
			if (cmd == "load") then
				if (param == "") then
					Stubby.Print("Manually loading BottomScanner...")
					LoadAddOn("BtmScan")
				elseif (param == "auctionhouse") then
					Stubby.Print("Setting BottomScanner to load when this character visits the auction house")
					Stubby.SetConfig("BtmScan", "LoadType", param)
				elseif (param == "always") then
					Stubby.Print("Setting BottomScanner to always load for this character")
					Stubby.SetConfig("BtmScan", "LoadType", param)
					LoadAddOn("BtmScan")
				elseif (param == "never") then
					Stubby.Print("Setting BottomScanner to never load automatically for this character (you may still load manually)")
					Stubby.SetConfig("BtmScan", "LoadType", param)
				else
					Stubby.Print("Your command was not understood")
				end
			else
				Stubby.Print("BottomScanner is currently not loaded.")
				Stubby.Print("  You may load it now by typing |cffffffff/btmscan load|r")
				Stubby.Print("  You may also set your loading preferences for this character by using the following commands:")
				Stubby.Print("  |cffffffff/btmscan load auctionhouse|r - BottomScanner will load when you visit the auction house")
				Stubby.Print("  |cffffffff/btmscan load always|r - BottomScanner will always load for this character")
				Stubby.Print("  |cffffffff/btmscan load never|r - BottomScanner will never load automatically for this character (you may still load it manually)")
			end
		end
		SLASH_BTMSCAN1 = "/btm"
		SLASH_BTMSCAN2 = "/btmscan"
		SLASH_BTMSCAN3 = "/bottomscan"
		SLASH_BTMSCAN4 = "/bottomscanner"
		SlashCmdList["BTMSCAN"] = cmdHandler
	]]);
	Stubby.RegisterBootCode("BtmScan", "Triggers", [[
		function BtmScan_CheckLoad()
			local loadType = Stubby.GetConfig("BtmScan", "LoadType")
			if (loadType == "auctionhouse" or not loadType) then
				LoadAddOn("BtmScan")
			end
		end
		Stubby.RegisterFunctionHook("AuctionFrame_LoadUI", 100, BtmScan_CheckLoad)
		local loadType = Stubby.GetConfig("BtmScan", "LoadType")
		if (loadType == "always") then
			LoadAddOn("BtmScan")
		else
			Stubby.Print("BottomScanner is not loaded. Type /btmscan for more info.");
		end
	]]);

	BtmScan.timer = 0
end

-- Event handler
BtmScan.OnEvent = function(...)
	local event, arg = select(2, ...)
	if (event == "ADDON_LOADED") then
		if (string.lower(arg) == "btmscan") then
			BtmScan.OnLoad()
		end
	end
end

-- Timing routines
BtmScan.interval = 30
BtmScan.offset = 0
BtmScan.OnUpdate = function(...)
	local elapsed = select(2, ...)

	if (not BtmScan.lastTry) then BtmScan.lastTry = 0 end
	if (not BtmScan.aucPriceModel and AuctionFramePost_AdditionalPricingModels) then
		BtmScan.aucPriceModel = true
		table.insert(AuctionFramePost_AdditionalPricingModels, BtmScan.AddAuctPriceModel)
	end

	if (not BtmScan.interval) then BtmScan.interval = 6 end
	if (BtmScan.timer) then
		if (not BtmScan.LogFrame and AuctionFrame and BtmScan.lastTry < BtmScan.timer - 1 ) then
			BtmScan.CreateLogWindow()
			if (BtmScan.LogFrame) then BtmScan.LogFrame.Update() end
			BtmScan.lastTry = BtmScan.timer
		end

		BtmScan.timer = BtmScan.timer + elapsed
		
		-- Check whether we should scan the current page of query results for purchase opportunities
		if (BtmScan.pageScan) then
			if (BtmScan.timer > BtmScan.pageScan) then
				BtmScan.PageScan(BtmScan.resume)
			elseif (BtmScan.timer > BtmScan.pageScan-0.25) then
				BtmScan.scanStage = 1
			end
		end
		
		-- Now check if enough time has elapsed to do everything else - i.e. request a new last page query, among other tasks
		-- Note that if any bid opportunity happened above in PageScan(), BtmScan.timer has been reset to 0 now
		-- So you're going to wait a whole .interval from the time the last bid/BO dialog is dismissed before you get past this next section to get any new query results
		if (BtmScan.timer < BtmScan.interval) then
			return
		end
		BtmScan.timer = BtmScan.timer - BtmScan.interval
	else
		BtmScan.timer = 0
	end

	-- Set the background at the correct stage color
	if (not BtmScan.LogParent) then return end
	
	-- Don't go any farther if we're still waiting on a purchase dialog decision
	if (BtmScan.scanStage == 3) then return end 

	-- If we are supposed to be scanning, then let's do it!
	if (BtmScan.scanning) then

		-- Get the current number of auctions and pages
		local pageCount, totalCount = GetNumAuctionItems("list")
		local totalPages = math.floor((totalCount-1)/NUM_AUCTION_ITEMS_PER_PAGE)
		if (totalPages < 0) then totalPages = 0 end

		-- Set the AH page count to a signal value, if this is our first time
		if (not BtmScan.pageCount) then
			BtmScan.pageCount = -1
		end

		-- Decide whether we are just starting to use the BtmScanner queries (as opposed to piggybacking), which means we are going to do a few quick scans to get to the last page quickly
		if (totalPages ~= BtmScan.pageCount) then
			BtmScan.pageCount = totalPages
			BtmScan.interval = 6 -- Short cut the delay, we need to reload now damnit!
		else
			-- We have the last page pegged, go back to the default slow query speed
			BtmScan.interval = BtmScanData.refresh
		end

		-- Check to see if the AH is open for business
		if not (AuctionFrame and AuctionFrame:IsVisible() and BtmScan.CanSendAuctionQuery()) then
			BtmScan.interval = 1 -- Try again in one second
			return
		end

		-- Every 5 pages, go back a page just to double check that nothing got by us.
		BtmScan.offset = (BtmScan.offset + 1) % 5
		local offset = 0
		if (BtmScan.offset == 0) then offset = 1 end

		-- Show me tha money!  Either do a new AH query, or piggyback on an existing query
		--BtmScan.processing = true
		BtmScan.scanStage = 2
		local page = BtmScan.pageCount-offset or 0
		if not Auctioneer.ScanManager.IsScanning() and
		   not Auctioneer.BidScanner.IsScanning() then
			-- Auctioneer is not scanning, so  let's send  off a query
			AuctionFrameBrowse.page = page
			QueryAuctionItems("", "", "", nil, nil, nil, page, nil, nil)
		else
			-- If Auctioneer is currently scanning, then we just need to piggyback its calls.
			BtmScan.timer = 0
			BtmScan.pageScan = 0.001
		end
		
		-- Since we're getting a new set of query results, let's reset resume here to make sure we don't skip anything in the new results
		BtmScan.resume = nil
		
		AuctionFrameBid.page = page
	end
end


BtmScan.QueryAuctionItems = function(par,ret, name,lmin,lmax,itype,class,sclass,page,able,qual)
	if (not BtmScan.scanning) then return end

	-- Kewl, lets schedule a scan of this page for 2 seconds into the future.
	BtmScan.timer = 0
	BtmScan.pageScan = 2
end

BtmScan.PageScan = function(resume)
	BtmScan.pageScan = nil
	if (not BtmScan.scanStage or BtmScan.scanStage == 0 or BtmScan.scanStage == 3) then return end

	-- Make sure the current zone is loaded and has defaults
	BtmScan.GetZoneConfig("pagescan")

	-- Ok, we've just queried the auction house, page should be loaded etc.
	-- lets get the items on the list and scan them.
	local pageCount, totalCount = GetNumAuctionItems("list")

	local log = BtmScan.Log
	if (BtmScan.dryRun) then log = BtmScan.Print end

	-- Ok, lets look at all these lovely items
	if (not resume) then resume = 1 end
	i = resume
	while ((i <= pageCount) and (BtmScan.scanning == true)) do
		local itemLink = GetAuctionItemLink("list", i)
		-- If:
		--   * This item has been loaded
		if (itemLink) then

			-- Break apart the link and assemble the keys
			local itemID, itemRand, itemEnch, itemUniq = BtmScan.BreakLink(itemLink)
			local sanityKey = itemID..":"..itemRand
			local auctKey = itemID..":"..itemRand..":"..itemEnch
			
			-- Check to see that we're not ignoring this item
			if (not data.ignore[sanityKey]) then

				-- Get the auction information for this this item
				local iName, iTex, iCount, iQual, iUse, iLvl, iMin, iInc, iBuy, iCur, iHigh, iOwner = GetAuctionItemInfo("list", i)

				-- Work out what the next bid will be
				local iBid = iMin
				if (iCur and iCur > 0) then iBid = iCur + iInc end

				-- If:
				--   * This item has a buyout price
				--   * It's not owned by us
				--   * It's not gonna break the bank
				if (iOwner ~= UnitName('player')) then

					-- Check to see if we have overspent the safetynet on this item
					-- Note that it is possible to overspend the safety amount, as
					-- the safetynet only kicks in once you have met or exceeded this
					-- amount spent.
					local ignoreItem = false
					if (not BtmScan.sessionSpend) then BtmScan.sessionSpend = {} end
					if (BtmScan.sessionSpend[sanityKey]) then
						local sSpend = BtmScan.sessionSpend[sanityKey]
						if (sSpend.count >= data.safetyCount) then
							ignoreItem = true
						elseif (sSpend.cost >= data.safetyCost) then
							ignoreItem = true
						end

						if (not BtmScan.dryRun and ignoreItem and not sSpend.warned) then
							log(tr("Warning: Safety limit reached on item: %1", itemLink))
							BtmScan.sessionSpend[sanityKey].warned = true
						end
					end

					-- If this item doesn't breach the safetynet
					if (not ignoreItem) then

						-- Get vendor price if available
						local vendorValue = BtmScan.GetVendorPrice(itemID, iCount)

						-- Get disenchant value if available
						local disenchantValue = 0
						if (Enchantrix and Enchantrix.Storage) then
							if (Enchantrix.Storage.GetItemDisenchantTotals) then
								-- function added for Enchantrix 4.0.2
								local hspValue, medianValue, baselineValue, auc5Value = Enchantrix.Storage.GetItemDisenchantTotals(itemLink);
								if (auc5Value and auc5Value > 0) then
									disenchantValue = auc5Value;
								else
									disenchantValue = hspValue or 0;
								end
							else
								-- for older versions of enchantrix that don't have a totals function
								local disenchantTo = Enchantrix.Storage.GetItemDisenchants(Enchantrix.Util.GetSigFromLink(itemLink), itemName, true)
								if (disenchantTo and disenchantTo.totals and disenchantTo.totals.hspValue and iQual > 1 and iCount <= 1) then
									disenchantValue = disenchantTo.totals.hspValue * disenchantTo.totals.conf
								end
							end
						end

						-- Get snatch value if it has been set
						local snatchAmount = data.snatch[sanityKey]
						local snatchPrice, snatchCount, snatchStack
						if (type(snatchAmount) ~= "table") then
							snatchPrice = tonumber(snatchAmount) or 0
							snatchCount = 0
							snatchStack = 0
						else
							snatchPrice = tonumber(snatchAmount[1]) or 0
							snatchCount = tonumber(snatchAmount[2]) or 0
							snatchStack = tonumber(snatchAmount[3]) or 0
						end
						snatchPrice = snatchPrice * iCount
						local snatched = tonumber(data.snatched[sanityKey]) or 0
						if (snatched + iCount > snatchCount and snatchCount > 0) then
							snatchPrice = 0
						end

						local _,_,_,_,_,_,_,stackSize = GetItemInfo(itemID)
						if (not stackSize) then
							if (snatchStack > 0) then
								stackSize = snatchStack
							else
								stackSize = 1
							end
						end

						-- Initialize buyIt to false
						local buyIt = false
						local bidIt = false
						local ignoreIt = false
						local whyBuy = ""
						local noSafety = false
						local buying = itemLink
						local value = 0
						local price = 0
						local profit = 0
						local message

						if (iCount and iCount > 1) then buying = buying.."x"..iCount end

						-- If this item is not trash (grey) quality
						if (iQual > 0) then

							-- Grab the sane price from our list
							--   Note these are compiled averages from all factions and servers
							--   This is meant to "double check" the Auctioneer prices, if both
							--   agree that this item is a "good buy", only then will we buy it
							local sanity = BtmScan.ConfidenceList[sanityKey] or ""
							local bBase, bCount
							local iqm, iqwm, iqCount = strsplit(",", sanity)
							iqm = tonumber(iqm) or 0
							iqwm = tonumber(iqwm) or 0
							iqCount = tonumber(iqCount) or 0
							bCount = data.minSeen
							bBase = iqwm

							-- Use the worst case scenario from inbuilt or auctioneer prices
							-- (if available)
							local auctMedian, auctCount
							if (Auctioneer and Auctioneer.Statistic) then
								auctMedian, auctCount = Auctioneer.Statistic.GetUsableMedian(auctKey)
								bCount = 0
								if (auctMedian and auctCount) then
									if (bBase == 0 or bBase >= auctMedian) then
										bBase = auctMedian
									end
									bCount = auctCount
								end
							end

							if (not auctMedian) then auctMedian = 0 end
							if (not auctCount) then auctCount = 0 end

							if (not iCount or iCount < 1) then iCount = 1 end
							local deposit = BtmScan.GetDepositCost(itemID, iCount)
							if (not deposit) then deposit = 0 end

							if (BtmScan.BaseRule) then
								BtmScan.prices = {
									consKey = sanityKey,
									consMean = iqm * iCount,
									consPrice = iqwm * iCount,
									consSeen = iqCount,
									auctKey = auctKey,
									auctPrice = auctMedian * iCount,
									auctSeen = auctCount,
									itemID = itemID,
									itemRand = itemRand,
									itemEnch = itemEnch,
									itemCount = iCount,
									buyPrice = iBuy,
									bidPrice = iBid,
									basePrice = bBase * iCount,
									depositCost = deposit,
								}
								bBase = BtmScan.BaseRule()

								local action = BtmScan.prices.action
								if action == "bid" then
									if (not bBase or bBase == 0) then bBase = iBid*iCount end
									whyBuy = BtmScan.prices.reason or tr("Actioned")
									price = iBid
									value = bBase
									bidIt = true
								elseif action == "buy" and (tonumber(iBuy) or 0) > 0 then
									if (not bBase or bBase == 0) then bBase = iBuy*iCount end
									whyBuy = BtmScan.prices.reason or tr("Actioned")
									price = iBuy
									value = bBase
									buyIt = true
								elseif action == "ignore" then
									ignoreIt = true
								end
							else
								bBase = bBase * iCount
							end

							if (bBase > 0 and not (bidIt or buyIt or ignoreIt)) then
								-- If user has specified a specific worth for this item, use it
								if (data.worth[sanityKey]) then
									bBase = tonumber(data.worth[sanityKey]) * iCount
									bCount = data.minSeen
									noSafety = true
								end

								-- Work out what the required profit will be
								local requiredProfit = data.minProfit
								-- White or lower items have a multiplier added to them
								if (iQual < 2) then requiredProfit = requiredProfit * data.commonMult end

								-- Find out what the profitable price will be based on pctprofit
								local profitablePrice = iBuy * (1+data.pctProfit/100)
								local profitableBid = iBid * (1+data.pctProfit/100)
								-- Work out which is larger, pctProfit, or requiredProfit
								if (iBuy + requiredProfit > profitablePrice) then
									-- Use requiredProfit instead
									profitablePrice = iBuy + requiredProfit
								end
								if (iBid + requiredProfit > profitableBid) then
									profitableBid = iBid + requiredProfit
								end

								-- If:
								--    * It's base price (what we think it's worth) is better
								--      than what would be profitable for this item.
								--    * It's buyout cost is less than our maximum price
								--    * It meets our minimum seen count requirement
								if (bBase and bBase > 0 and bCount >= data.minSeen) then
									if (iBuy and iBuy>0 and bBase >= profitablePrice and iBuy <= data.maxPrice and GetMoney()-iBuy >= data.reserve) then
										whyBuy = tr("resale")
										price = iBuy
										value = bBase
										buyIt = true
									elseif (bBase >= profitableBid and iBid <= data.maxPrice and GetMoney()-iBid >= data.reserve) then
										whyBuy = tr("resale")
										price = iBid
										value = bBase
										bidIt = true
									end
								end

								if (iBuy > bBase * 100) then ignoreIt = true end
							end

							--Get the itemMinLevel for use with disenchant options
							local _, _, _, _, itemMinLevel = GetItemInfo(itemID)
							
							-- If:
							--  * The user can disenchant the item
							if (BtmScan.isDEAble(itemMinLevel)) then
								-- If:
								--   * We're not buying it
								--   * It has a disenchant value
								if (not buyIt and disenchantValue > 0) then
								
									-- We need to increase the required profit for disenchants
									-- since there is often a chance that it will not D/E into
									-- what we want it to. (/btm defactor)

									local profitablePrice = iBuy * (1+data.pctDeProfit/100)
									local profitableBid = iBid * (1+data.pctDeProfit/100)
									-- Work out which is larger, pctDeProfit, or minDeProfit
									if (iBuy + data.minDeProfit > profitablePrice) then
										-- Use minDeProfit instead
										profitablePrice = iBuy + data.minDeProfit
									end
									if (iBid + data.minDeProfit > profitableBid) then
										profitableBid = iBid + data.minDeProfit
									end
	
									-- If:
									--   * This item's de value is more than the profitable price
									--   * It's buyout cost is less than our maximum price
									if (iBuy and iBuy>0 and disenchantValue >= profitablePrice and iBuy <= data.maxPrice and GetMoney()-iBuy >= data.reserve) then
										whyBuy = tr("disenchant")
										price = iBuy
										value = disenchantValue
										buyIt = true
										noSafety = true
									elseif (not bidIt and disenchantValue >= profitableBid and iBid <= data.maxPrice and GetMoney()-iBid >= data.reserve) then
										whyBuy = tr("disenchant")
										price = iBid
										value = disenchantValue
										bidIt = true
										noSafety = true
									end
								end
							end
						end --if (not trash)

						-- If:
						--   * We're not buying it
						--   * It has a vendor value
						if (not buyIt and vendorValue and vendorValue > 0) then
							local profitablePrice = iBuy + data.vendProfit
							local profitableBid = iBid + data.vendProfit

							-- If:
							--   * This item's vendor value is more than the profitable price
							--   * It's buyout cost is less than our maximum price
							if (iBuy and iBuy>0 and vendorValue >= profitablePrice and iBuy <= data.maxPrice and GetMoney()-iBuy >= data.reserve) then
								whyBuy = tr("vendor")
								price = iBuy
								value = vendorValue
								buyIt = true
								noSafety = true
							elseif (not bidIt and vendorValue >= profitableBid and iBid <= data.maxPrice and GetMoney()-iBid >= data.reserve) then
								whyBuy = tr("vendor")
								price = iBid
								value = vendorValue
								bidIt = true
								noSafety = true
							end

							if (iBuy > vendorValue * 100) then ignoreIt = true end
						end

						-- If:
						--   * We're not buying it
						--   * It has a snatch value
						local snatching
						if (not buyIt and snatchPrice > 0) then
							if (iBuy and iBuy>0 and iBuy < snatchPrice and GetMoney()-iBuy >= data.reserve) then
								whyBuy = tr("snatch")
								price = iBuy
								value = snatchPrice
								buyIt = true
								noSafety = true
								snatching = true
							elseif (not bidIt and iBid <= snatchPrice and GetMoney()-iBid >= data.reserve) then
								whyBuy = tr("snatch")
								price = iBid
								value = snatchPrice
								bidIt = true
								noSafety = true
							end

							if (iBuy > snatchPrice * 100) then ignoreIt = true end
						end

						-- If for some reason the buyIt flag was set above, then place a bid on this item
						-- equal to the buyout price (ie: buy it out)
						if (buyIt or bidIt) then
							local bidText, bidType, bidPrice
							if (buyIt) then
								bidText = tr("Buying")
								bidType = tr("bought")
								bidPrice = iBuy
							elseif (bidIt and data.allowBids > 0 and not iHigh and not ignoreIt) then
								bidText = tr("Bidding")
								bidType = tr("bid on")
								bidPrice = iBid
							end
							profit = value - price
							message = tr("%1 %2 at %3 [%4 at %5 = %6 profit]", bidText, buying, BtmScan.GSC(price), whyBuy, BtmScan.GSC(value), BtmScan.GSC(profit))
							
							if bidPrice
							and GetMoney()-bidPrice >= data.reserve
							and bidPrice <= data.maxPrice
							and (not BtmScan.NoPrompt[sanityKey] or
								BtmScan.NoPrompt[sanityKey] > bidPrice)
							then
								if (BtmScan.dryRun) then
									BtmScan.Print(tr("Would have %1 %2 for %3, but we are doing a dry run.", bidType, buying, bidPrice))
								else
									local bidSig = itemLink.."x"..iCount
									BtmScan.PromptPurchase(i, bidSig, whyBuy, bidPrice, bidType, noSafety, snatching, iCount, stackSize, sanityKey, itemLink, iTex, price, value, profit, message)
									
									--set resume to next auction, so we don't double bid on this one immediately
									BtmScan.resume = i + 1
									return
								end
							end
						end
					end
				end
			end
		end
		i = i + 1
	end
	
	BtmScan.scanStage = 0
	
	--reached the end of the page, set resume back to nil
	BtmScan.resume = nil
	
	--BtmScan.LogParent:SetBackdropColor(0,0,0, 0.8)
	--BtmScan.processing = false
end

--Return whether the item is disenchantable give the item's level and the user's enchanting level
BtmScan.isDEAble = function(itemMinLevel)
	if (data.enchLevel) then
		if (data.enchLevel < 25) then
			if(itemMinLevel < 15) then
				return true
			else
				return false
			end
		elseif (data.enchLevel < 50) then
			if(itemMinLevel < 21) then
				return true
			else
				return false
			end
		elseif (data.enchLevel < 75) then
			if(itemMinLevel < 26) then
				return true
			else
				return false
			end
		elseif (data.enchLevel < 100) then
			if(itemMinLevel < 31) then
				return true
			else
				return false
			end
		elseif (data.enchLevel < 125) then
			if(itemMinLevel < 35) then
				return true
			else
				return false
			end
		elseif (data.enchLevel < 150) then
			if(itemMinLevel < 41) then
				return true
			else
				return false
			end
		elseif (data.enchLevel < 175) then
			if(itemMinLevel < 45) then
				return true
			else
				return false
			end
		elseif (data.enchLevel < 200) then
			if(itemMinLevel < 51) then
				return true
			else
				return false
			end
		elseif (data.enchLevel < 225) then
			if(itemMinLevel < 55) then
				return true
			else
				return false
			end
		elseif (data.enchLevel < 275) then
			if(itemMinLevel < 64) then
				return true
			else
				return false
			end
		elseif (data.enchLevel < 300) then
			if(itemMinLevel < 70) then
				return true
			else
				return false
			end
		elseif (data.enchLevel >= 300) then
			if(itemMinLevel <= 70) then
				return true
			else
				return false
			end
		end
	end
end

-------------------------------------------------------------------------------
-- Hook called after Blizzard's CanSendAuctionQuery().
-- Overrides the return value, if we are scanning the AH to make sure that no
-- other addon interferes with our scanning procedure, messing the whole scan
-- up.
-- A special version of CanSendAuctionQuery() is provided, which can be used
-- to receive the almost unaltered return value. See
-- BtmScan.CanSendAuctionQuery() for more details.
--
-- called by:
--    function hook - CanSendAuctionQuery() (position: 10)
--    globally      - BtmScan.PostCanSendAuctionQuery()
--
-- parameters:
--    _     - ignoring the first parameter, which is an empty table, since no
--            parameters are passed when registering this function with Stubby
--            (see Stubby.RegisterFunctionHook() for more details)
--    _     - ignoring the second parameter, which is a table containing the
--            return value of the original function call.
--            (see Stubby.RegisterFunctionHook() for more details)
--
-- returns:
--    first value:
--       nil, if sending an auction query is fine
--       "setreturn", otherwise
--    second value:
--       nil, if sending an auction query is fine
--       {}, otherwise
-------------------------------------------------------------------------------
BtmScan.PostCanSendAuctionQuery = function(_, _)
	if not hookCanSendAuctionQuery then
		 -- we are calling the function via BtmScan.CanSendAuctionQuery()
		 -- and therefore are asked not to alter the return value
		return
	end

	-- We are performing our own scans. Permit other addons from interfering.
	if (BtmScan.scanStage and BtmScan.scanStage > 0) then
		return "setreturn", {}
	end
end


-------------------------------------------------------------------------------
-- BottomScanner's version of CanSendAuctionQuery().
-- This function can be called, if BottomScanner should not interfere with the
-- CanSendAuctionQuery()-return value.
-- Refere to AucQueryManager.CanSendAuctionQuery() to see a more detailed
-- description on when the original return value is still being altered (not
-- by us, but by Auctioneer).
--
-- called by:
--    globally - BtmScan.CanSendAuctionQuery()
--       called in BtmScan.OnUpdate()
--
-- calls:
--    AucQueryManager.CanSendAuctionQuery() - always
--
-- returns:
--    1, if sending an auction query is fine
--    nil, otherwise
-------------------------------------------------------------------------------
BtmScan.CanSendAuctionQuery = function()
	-- Exclude our own checks in CanSendAuctionQuery() as well as use
	-- Auctioneer's special CanSendAuctionQuery()-function.
	hookCanSendAuctionQuery = false
	local ret = Auctioneer.QueryManager.CanSendAuctionQuery()
	hookCanSendAuctionQuery = true

	return ret
end

-- Get a GSC value and work out what it's worth
BtmScan.ParseGSC = function (price)
	price = string.gsub(price, "|c[0-9a-fA-F]+", " ")
	price = string.gsub(price, "[gG]", "0000 ")
	price = string.gsub(price, "[sS]", "00 ")
	price = string.gsub(price, "[^0-9]+", " ")	-- Note that we're stripping out all non-digits here, so any garbage in the input stream is automatically lost now

	local total = 0
	for q in string.gmatch(price, "(%d+)") do
		local number = tonumber(q) or 0
		total = total + number
	end
	
	return total
end

-- Break an ItemID into it's component pieces
BtmScan.BreakLink = function (link)
	if (type(link) ~= 'string') then return end
	local whole, item, name, remain = string.match(link, "(|c[0-9a-fA-F]+|Hitem:([^|]+)|h%[(.-)%]|h|r)(.*)")
	if (not item) then return end

	local itemID, enchant, gem1, gem2, gem3, gem4, randomProp, uniqID = strsplit(":", item)

	-- original search format is "[ItemLink]x(Count) at (Price)".
	local i,j, count, price, nextpart
	i,j, count, nextpart = string.find(remain or "", "^x(%d+)(.*)")
	if (i) then
		count = tonumber(count) or 0
		remain = nextpart
	else count = 0 end
	i,j, price, nextpart = string.find(remain or "", "^ at ([^ ]+)(.*)")
	if (i) then
		price = BtmScan.ParseGSC(price)
		remain = nextpart
	else price = 0 end 
	
	-- Now check for new format "[ItemLink] <price> <count>" if original format came up empty
	if (price == 0) then
		i, j, price, count, nextpart = string.find(remain or "", "^ *([%dgGsScC]+) *(%d*)(.*)")
		if (i) then
			price = BtmScan.ParseGSC(price)
			count = tonumber(count) or 0
			remain = nextpart
		else
			price = 0
			count = 0
		end
	end
	
	return tonumber(itemID) or 0, tonumber(randomProp) or 0, tonumber(enchant) or 0, tonumber(uniqID) or 0, name, whole, count, price, remain
end

-- Item Designation used in several places
BtmScan.ItemDes = function (link)
	local itemID, itemRand, _,_,_, itemLink, count, price, remain = BtmScan.BreakLink(link)
	if (not itemID) then return end
	return string.format("%d:%d", tonumber(itemID) or 0, tonumber(itemRand) or 0), tonumber(count) or 0, tonumber(price) or 0, itemID, itemRand, itemLink, remain
end

-- Item Designation used in several places
BtmScan.BreakItemDes = function (des)
	local i,j, itemID, itemRand = string.find(des, "(%d+):(%d+)")
	return tonumber(itemID) or 0, tonumber(itemRand) or 0
end

-- Makes up a pretend link based off the hyperlink code
BtmScan.FakeLink = function (hyperlink, quality, name)
	if not hyperlink then return end
	local sName, sLink, iQuality = GetItemInfo(hyperlink)
	if (quality == nil) then quality = iQuality or -1 end
	if (name == nil) then name = sName or "unknown ("..hyperlink..")" end
	local _, _, _, color = GetItemQualityColor(quality)
	return color.. "|H"..hyperlink.."|h["..name.."]|h|r"
end

BtmScan.GetGSC = function (money)
	if (money == nil) then money = 0 end
	local g = math.floor(money / 10000)
	local s = math.floor((money - (g*10000)) / 100)
	local c = math.ceil(money - (g*10000) - (s*100))
	return g,s,c
end

-- formats money text by color for gold, silver, copper
BtmScan.GSC = function (money, exact, dontUseColorCodes)
	if (type(money) ~= "number") then return end

	local TEXT_NONE = "0"

	local GSC_GOLD="ffd100"
	local GSC_SILVER="e6e6e6"
	local GSC_COPPER="c8602c"
	local GSC_START="|cff%s%d%s|r"
	local GSC_PART=".|cff%s%02d%s|r"
	local GSC_NONE="|cffa0a0a0"..TEXT_NONE.."|r"

	if (not money) then money = 0 end
	if (not exact) and (money >= 10000) then money = math.floor(money / 100 + 0.5) * 100 end
	local g, s, c = BtmScan.GetGSC(money)

	local gsc = ""
	if (not dontUseColorCodes) then
		local fmt = GSC_START
		if (g > 0) then gsc = gsc..string.format(fmt, GSC_GOLD, g, 'g') fmt = GSC_PART end
		if (s > 0) or (c > 0) then gsc = gsc..string.format(fmt, GSC_SILVER, s, 's') fmt = GSC_PART end
		if (c > 0) then gsc = gsc..string.format(fmt, GSC_COPPER, c, 'c') end
		if (gsc == "") then gsc = GSC_NONE end
	else
		if (g > 0) then gsc = gsc .. g .. "g " end
		if (s > 0) then gsc = gsc .. s .. "s " end
		if (c > 0) then gsc = gsc .. c .. "c " end
		if (gsc == "") then gsc = TEXT_NONE end
	end
	return gsc
end

BtmScan.Print = function (text, cRed, cGreen, cBlue, cAlpha, holdTime)
	local frameIndex = BtmScan.getFrameIndex()

	if (cRed and cGreen and cBlue) then
		if getglobal("ChatFrame"..frameIndex) then
			getglobal("ChatFrame"..frameIndex):AddMessage(text, cRed, cGreen, cBlue, cAlpha, holdTime)

		elseif (DEFAULT_CHAT_FRAME) then
			DEFAULT_CHAT_FRAME:AddMessage(text, cRed, cGreen, cBlue, cAlpha, holdTime)
		end

	else
		if getglobal("ChatFrame"..frameIndex) then
			getglobal("ChatFrame"..frameIndex):AddMessage(text, 0.9, 0.6, 0.2)

		elseif (DEFAULT_CHAT_FRAME) then
			DEFAULT_CHAT_FRAME:AddMessage(text, 0.9, 0.6, 0.2)
		end
	end
end

BtmScan.getFrameNames = function (index)
	local frames = {}
	local frameName = ""

	for i=1, 10 do
		local name, fontSize, r, g, b, a, shown, locked, docked = GetChatWindowInfo(i)

		if ( name == "" ) then
			if (i == 1) then
				frames[string.lower(GENERAL)] = 1

			elseif (i == 2) then
				frames[string.lower(COMBAT_LOG)] = 2
			end

		else
			frames[string.lower(name)] = i
		end
	end

	if (type(index) == "number") then
		local name, fontSize, r, g, b, a, shown, locked, docked = GetChatWindowInfo(index)

		if ( name == "" ) then
			if (index == 1) then
				frameName = GENERAL

			elseif (index == 2) then
				frameName = COMBAT_LOG
			end

		else
			frameName = name
		end
	end

	return frames, frameName
end

BtmScan.getFrameIndex = function ()
	if not BtmScanData.printFrame then return 1 end
	return tonumber(BtmScanData.printFrame) or 1
end

BtmScan.setFrame = function (frame, chatprint)
	local frameNumber
	local frameVal
	frameVal = tonumber(frame)

	--If no arguments are passed, then set it to the default frame.
	if not (frame) then
		frameNumber = 1

	--If the frame argument is a number then set our chatframe to that number.
	elseif ((frameVal) ~= nil) then
		frameNumber = frameVal

	--If the frame argument is a string, find out if there's a chatframe with that name, and set our chatframe to that index. If not set it to the default frame.
	elseif (type(frame) == "string") then
		local allFrames = BtmScan.getFrameNames()
		if (allFrames[string.lower(frame)]) then
			frameNumber = allFrames[frame]
		else
			frameNumber = 1
		end

	--If the argument is something else, set our chatframe to its default value.
	else
		frameNumber = 1
	end

	local _, frameName

	_, frameName = BtmScan.getFrameNames(frameNumber)
	if (BtmScan.getFrameIndex() ~= frameNumber) then
		BtmScan.Print(tr("BottomScanner's messages will now print on the \"%1\" chat frame", frameName))
	end

	BtmScanData.printFrame = frameNumber
	BtmScan.Print(tr("BottomScanner's messages will now print on the \"%1\" chat frame", frameName))
end

BtmScan.Log = function (msg)
	-- Make sure the current zone is loaded and has defaults
	BtmScan.GetZoneConfig("log")

	if (not data.logText) then data.logText = {} end
	table.insert(data.logText, { time(), msg })
	if (not BtmScan.LogFrame) then BtmScan.CreateLogWindow() end
	if (BtmScan.LogFrame) then BtmScan.LogFrame.Update() end
end

-- Command function handles the processing of slash commands.
BtmScan.Command = function (msg)
	local i,j, ocmd, oparam = string.find(msg, "^([^ ]+) (.*)$")
	local i,j, cmd, param = string.find(string.lower(msg), "^([^ ]+) (.*)$")
	if (not i) then cmd = msg param = nil oparam = nil end
	if (oparam == "") then param = nil oparam = nil end

	-- Make sure the current zone is loaded and has defaults
	BtmScan.GetZoneConfig("command")

	local help = false
	if (cmd == "maxprice") then
		if (param) then
			data.maxPrice = BtmScan.ParseGSC(param)
		end
		BtmScan.Print(tr("BottomScanner has set %1 to %2", tr("Maximum Price"), BtmScan.GSC(data.maxPrice,1)))
	elseif (cmd == "minprofit") then
		if (param) then
			data.minProfit = BtmScan.ParseGSC(param)
		end
		BtmScan.Print(tr("BottomScanner has set %1 to %2", tr("Minimum Profit"), BtmScan.GSC(data.minProfit,1)))
	elseif (cmd == "pctprofit") then
		if tonumber(param) then
			data.pctProfit = tonumber(param)
		end
		BtmScan.Print(tr("BottomScanner has set %1 to %2", tr("Percent Profit"), data.pctProfit.."%"))
	elseif (cmd == "mindeprofit") then
		if (param) then
			data.minDeProfit = BtmScan.ParseGSC(param)
		end
		BtmScan.Print(tr("BottomScanner has set %1 to %2", tr("Minimum Disenchant Profit"), BtmScan.GSC(data.minDeProfit,1)))
	elseif (cmd == "pctdeprofit") then
		if tonumber(param) then
			data.pctDeProfit = tonumber(param)
		end
		BtmScan.Print(tr("BottomScanner has set %1 to %2", tr("Percent Disenchant Profit"), data.pctDeProfit.."%"))
	elseif (cmd == "enchant") then
		if (param) then
			if (tonumber(param) and (tonumber(param) >= 0) and (tonumber(param) <= 375)) then
				data.enchLevel = math.floor(tonumber(param))
				BtmScan.Print(tr("BottomScanner has set %1 to %2", tr("Enchanting Level"), data.enchLevel))
			else
				BtmScan.Print("Enchanting level has to be 0-375, please try again")
			end
		elseif (data.enchLevel ~= nil) then
			BtmScan.Print(tr("BottomScanner has %1 set to %2 currently", tr("Enchanting Level"), data.enchLevel))
		else
			BtmScan.Print("Please enter your enchanting level after \"enchant\". IE: /btmscan enchant 300")
		end
	elseif (cmd == "vendprofit") then
		if (param) then
			data.vendProfit = BtmScan.ParseGSC(param)
		end
		BtmScan.Print(tr("BottomScanner has set %1 to %2", tr("Vendor Profit"), BtmScan.GSC(data.vendProfit)))
	elseif (cmd == "reserve") then
		if (param) then
			data.reserve = BtmScan.ParseGSC(param)
		end
		BtmScan.Print(tr("BottomScanner has set %1 to %2", tr("Reserve"), BtmScan.GSC(data.reserve,1)))
	elseif (cmd == "defactor") then
		if tonumber(param) then
			data.deFactor = tonumber(param)
		end
		BtmScan.Print(tr("BottomScanner has set %1 to %2", tr("Disenchant Factor"), data.deFactor))
	elseif (cmd == "commonmult") then
		if tonumber(param) then
			data.commonMult = tonumber(param)
		end
		BtmScan.Print(tr("BottomScanner has set %1 to %2", tr("Common Item Multiplier"), data.commonMult))
	elseif (cmd == "allowbids") then
		if tonumber(param) then
			data.allowBids = tonumber(param)
		end
		local allowing = tr("Not Allowed")
		if (data.allowBids > 0) then
			allowing = tr("Allowed")
		end
		BtmScan.Print(tr("BottomScanner has set %1 to %2", tr("Item Bidding"), allowing))
	elseif (cmd == "safetynet") then
		local i,j, scount, scost = string.find(oparam, "^(%d+) (%d+)")
		if (i) then
			scount = tonumber(scount)
			scost = BtmScan.ParseGSC(scost)
			if (scount < 0) then scount = 0 end
			if (scost < 0) then scost = 0 end
			data.safetyCount = scount
			data.safetyCost = scost
		end
		scount = data.safetyCount
		scost = data.safetyCost
		if (scount == 0) then scount = "unlimited" end
		if (scost == 0) then scost = "unlimited" else scost = BtmScan.GSC(scost) end
		BtmScan.Print(tr("BottomScanner has set %1 to %2", tr("Safety Net"), tr("%1 items, %2 total spend", scount, scost)))
	elseif (cmd == "minseen") then
		if (param) then
			data.minSeen = tonumber(param)
		end
		BtmScan.Print(tr("BottomScanner has set %1 to %2", tr("Minimum Seen Count"), data.minSeen))
	elseif ((cmd == "end") or (cmd == "stop") or (cmd == "cancel")) then
		BtmScan.EndScan()
	elseif ((cmd == "begin") or (cmd == "start") or (cmd == "scan")) then
		BtmScan.dryRun = false
		BtmScan.BeginScan()
	elseif (cmd == "dryrun") then
		BtmScan.dryRun = true
		BtmScan.BeginScan()
	elseif (cmd == "load") then
		if (param == "always") or (param == "never") or (param == "auctionhouse") then
			Stubby.SetConfig("BtmScan", "LoadType", param)
			BtmScan.Print(tr("Setting BottomScanner to %1 load for this toon",param))
		end
	elseif (cmd == "baserule") then
		if (oparam) then
			data.baseRule = oparam
			BtmScan.CompileBaseRule()
		else
			BtmScan.EditData("baseRule", BtmScan.CompileBaseRule)
		end
	elseif (cmd == "tooltip") then
		if (param == "on") then
			data.tooltipOn = true
		elseif (param == "off") then
			data.tooltipOn = false
		end
		
		if (data.tooltipOn ~= nil) then
			local isOn
			if (data.tooltipOn == true) then
				isOn = "on"
			else
				isOn = "off"
			end
			BtmScan.Print(tr("BottomScanner has %1 set to %2", tr("show tooltips"), tr(isOn)))
		else
			BtmScan.Print("The tooltip command requires and on or off after it.")
		end
	elseif (cmd == "ignore") then
		if (oparam) then
			local des = BtmScan.ItemDes(oparam)
			data.ignore[des] = true
			BtmScan.Print(tr("BottomScanner will now %1 %2", tr("ignore"), oparam))
		else
			BtmScan.Print(tr("Your current %1 list is:", tr("ignore")))
			if (data.ignore and next(data.ignore)) then
				for des, ignored in pairs(data.ignore) do
					local itemID, itemRand = BtmScan.BreakItemDes(des)
					local itemString = "item:"..itemID..":0:"..itemRand..":0"
					local itemLink = BtmScan.FakeLink(itemString)
					BtmScan.Print(tr("  * %1", itemLink))
				end
			else
				BtmScan.Print(tr("  -- Empty --"))
			end
		end
	elseif (cmd == "unignore") then
		if (oparam) then
			local des = BtmScan.ItemDes(oparam)
			data.ignore[des] = nil
			BtmScan.Print(tr("BottomScanner will now %1 %2", tr("not ignore"), oparam))
		end
	elseif (cmd == "worth") then
		if (oparam) then
			local des, count, price, itemid,itemrand,itemlink, remain = BtmScan.ItemDes(oparam)
			if (not des) then
				BtmScan.Print(tr("Unable to understand command. Please see /btm help"))
				return
			end

			if (price <= 0) then
				price = BtmScan.ParseGSC(remain) or 0
			end

			if (price <= 0) then
				BtmScan.Print(tr("BottomScanner will now %1 %2", tr("not value"), itemlink))
				data.worth[des] = nil
				return
			end

			local _,_,_,_,_,_,_,stack = GetItemInfo(itemid)
			if (not stack) then
				stack = 1
			end

			local stackText = ""
			if (stack > 1) then
				stackText = " ("..tr("%1 per %2 stack", BtmScan.GSC(price*stack, 1), stack)..")"
			end

			data.worth[des] = price
			BtmScan.Print(tr("BottomScanner will now %1 %2", tr("value"), tr("%1 at %2", itemlink, tr("%1 per unit", BtmScan.GSC(price, 1)))..stackText))
		else
			BtmScan.Print(tr("Your current %1 list is:", tr("worth")))
			if (data.worth and data.worth ~= {}) then
				for des, amount in pairs(data.worth) do
					local itemID, itemRand = BtmScan.BreakItemDes(des)
					local itemString = "item:"..itemID..":0:"..itemRand..":0"
					local itemLink = BtmScan.FakeLink(itemString)

					local worthLine = ""
					amount = tonumber(amount) or 0

					worthLine = worthLine..tr("%1 per unit", BtmScan.GSC(amount,1))
					local _,_,_,_,_,_,_,stack = GetItemInfo(itemID)
					stack = tonumber(stack) or 1;
					if (stack > 1) then
						worthLine = worthLine.." ("..tr("%1 per %2 stack", BtmScan.GSC(amount*stack,1), stack)..")"
					end
					BtmScan.Print(tr("  * %1 = %2", itemLink, worthLine))
				end
			else
				BtmScan.Print(tr("  -- Empty --"))
			end
		end
	elseif (cmd == "snatch") then
		if (oparam) then
			local des, count, price, itemid,itemrand,itemlink, remain = BtmScan.ItemDes(oparam)
			if (not des) then
				BtmScan.Print(tr("Unable to understand command. Please see /btm help"))
				return
			end

			if (price <= 0) then
				price = BtmScan.ParseGSC(remain) or 0
			end
			
			if (price <= 0) then
				BtmScan.Print(tr("BottomScanner will now %1 %2", tr("not snatch"), itemlink))
				data.snatched[des] = nil
				data.snatch[des] = nil
				return
			end

			local _,_,_,_,_,_,_,stack = GetItemInfo(itemid)
			if (not stack) then
				stack = 1
			end

			local stackText = ""
			if (stack > 1) then
				stackText = " ("..tr("%1 per %2 stack", BtmScan.GSC(price*stack, 1), stack)..")"
			end
			local countText =""
			if (count > 0) then
				countText = tr("up to %1", count).." "
			else
				countText = tr("unlimited").." "
			end

			data.snatch[des] = { price, count, stack }
			data.snatched[des] = 0
			BtmScan.Print(tr("BottomScanner will now %1 %2", tr("snatch"), countText..tr("%1 at %2", itemlink, tr("%1 per unit", BtmScan.GSC(price, 1)))..stackText))
		else
			BtmScan.Print(tr("Your current %1 list is:", tr("snatch")))
			if (data.snatch and data.snatch ~= {}) then
				for des, amount in pairs(data.snatch) do
					local itemID, itemRand = BtmScan.BreakItemDes(des)
					local itemString = "item:"..itemID..":0:"..itemRand..":0"
					local itemLink = BtmScan.FakeLink(itemString)

					local price, count, stack
					local snatchLine = ""
					if (type(amount) ~= "table") then
						price = tonumber(amount) or 0
						count = 0
						stack = 0
					else
						price = tonumber(amount[1]) or 0
						count = tonumber(amount[2]) or 0
						stack = tonumber(amount[3]) or 0
					end

					if (count > 0) then
						local fulfilled = tonumber(data.snatched[des]) or 0
						snatchLine = snatchLine..tr("%1 / %2 at", fulfilled, count).." "
					end
					snatchLine = snatchLine..tr("%1 per unit", BtmScan.GSC(price,1))
					if (stack > 1) then
						snatchLine = snatchLine.." ("..tr("%1 per %2 stack", BtmScan.GSC(price*stack,1), stack)..")"
					end
					BtmScan.Print(tr("  * %1 = %2", itemLink, snatchLine))
				end
			else
				BtmScan.Print(tr("  -- Empty --"))
			end
		end
	elseif (cmd == "print-in") then
		BtmScan.setFrame(oparam)
	elseif (cmd == "clear") then
		data.logText = { { time(), "--- Welcome to BottomScanner ---" } }
		if (BtmScan.LogFrame) then BtmScan.LogFrame.Update() end
	elseif (cmd == "help" or cmd == "") then
		help = true
	else
		BtmScan.Print(tr("BottomScanner: %1 [%2]", tr("Unknown command"), cmd))
		help = true
	end

	if (help) then
		BtmScan.Print(tr("BottomScanner is using %1 configuration", dataZone))
		BtmScan.Print(tr(" %1 [%2] = %3", "reserve <copper>", tr("Reserves a certain amount of your money from being spent"), BtmScan.GSC(data.reserve,1)))
		BtmScan.Print(tr(" %1 [%2] = %3", "maxprice <copper>", tr("Sets the maximum price that we will buy auctions for"), BtmScan.GSC(data.maxPrice,1)))
		BtmScan.Print(tr(" %1 [%2] = %3", "minprofit <copper>", tr("Sets the minimum profit that we consider an auction"), BtmScan.GSC(data.minProfit,1)))
		BtmScan.Print(tr(" %1 [%2] = %3", "pctprofit <percent>", tr("Sets the minimum percentage of profit to buy an auction"), data.pctProfit.."%"))
		BtmScan.Print(tr(" %1 [%2] = %3", "mindeprofit <copper>", tr("Sets the minimum disenchant profit that we consider an auction"), BtmScan.GSC(data.minDeProfit,1)))
		BtmScan.Print(tr(" %1 [%2] = %3", "pctdeprofit <percent>", tr("Sets the minimum percentage of disenchant profit to buy an auction"), data.pctDeProfit.."%"))
		BtmScan.Print(tr(" %1 [%2] = %3", "vendprofit <copper>", tr("Sets the minimum profit on vendorable items"), data.vendProfit))
		BtmScan.Print(tr(" %1 [%2] = %3", "commonmult <factor>", tr("Sets a penalty factor on white items' profitability"), data.commonMult))
		local allowing = tr("Not Allowed") if (data.allowBids > 0) then allowing = tr("Allowed") end
		BtmScan.Print(tr(" %1 [%2] = %3", "allowbids <0/1>", tr("Sets whether to allow bidding if the rules would have bought at that price"), allowing))
		BtmScan.Print(tr(" %1 [%2] = %3", "minseen <count>", tr("Sets the minimum Auctioneer \"seen count\" before we will buy an item"), data.minSeen))

		local scount, scost
		scount = data.safetyCount
		scost = data.safetyCost
		if (scount == 0) then scount = "unlimited" end
		if (scost == 0) then scost = "unlimited" else scost = BtmScan.GSC(scost) end
		BtmScan.Print(tr(" %1 [%2] = %3", "safetynet <count> <copper>", tr("Sets the maximum number / cost of any single item that will be bought in any one session (0 for unlimited)"), tr("%1 items, %2 total spend", scount, scost)))

		BtmScan.Print(tr(" %1 [%2]", "print-in (<frameIndex>[Number]|<frameName>[String])", tr("Sets the chatFrame that BottomScanner's messages will be printed to")))
		BtmScan.Print(tr(" %1 [%2]", "baserule <lua>", tr("Advanced users only: Specify your own lua code for calculating the base price")))
		BtmScan.Print(tr(" %1 [%2]", "tooltip <on/off>", tr("Turn on/off the BottomScanner tooltip")))
		BtmScan.Print(tr(" %1 [%2]", "ignore [ItemLink]", tr("Ignores the specified item")))
		BtmScan.Print(tr(" %1 [%2]", "unignore [ItemLink]", tr("Stops ignoring the specified item")))
		BtmScan.Print(tr(" %1 [%2]", "snatch [ItemLink] <copper> <count>", tr("Sets the item's snatch value, or leave off '<copper> <count>' to un-snatch")))
		BtmScan.Print(tr(" %1 [%2]", "worth [ItemLink] <copper>", tr("Sets the specified item's value, or leave off '<copper>' to un-worth")))
		BtmScan.Print(tr(" %1 [%2]", "enchant <level>", tr("Sets your enchanting level for disenchant-based purchases")))
		BtmScan.Print(tr(" %1 [%2]", "clear", tr("Clears the AH event log window")))
		BtmScan.Print(tr(" %1 [%2]", "dryrun", tr("Begins a test scanning run (must have AH open)")))
		BtmScan.Print(tr(" %1 [%2]", "begin", tr("Begins the scanning process (must have AH open)")))
		BtmScan.Print(tr(" %1 [%2]", "end", tr("Ends the scanning process")))
		BtmScan.Print(tr(" %1 [%2]", "load (always|never|auctionhouse)", tr("Set when BottomScanner will load")))
	end
end

BtmScan.BeginScan = function ()
	if (BtmScan.scanning ~= true) then
		BtmScan.PlayButton:SetButtonState("PUSHED", true)
		BtmScan.Log(tr("BottomScanner is now scanning"))
		BtmScan.scanning = true
		BtmScan.interval = 1
	end
end
BtmScan.EndScan = function ()
    if (BtmScan.scanning == true) then
		BtmScan.PlayButton:SetButtonState("NORMAL")
		BtmScan.Log(tr("BottomScanner is stopping scanning"))
		BtmScan.scanning = false
		BtmScan.resume = nil
	end
end

BtmScan.AddAuctPriceModel = function (itemID, itemRand, itemEnch, itemName, count)
	local sanityKey = itemID..":"..itemRand
	local sanity = BtmScan.ConfidenceList[sanityKey]
	local iqm, iqwm
	if (sanity) then
		local iqm, iqwm, iqCount = strsplit(",", sanity)
		iqm = tonumber(iqm)
		iqwm = tonumber(iqwm)
		if (count and count > 1) then
			iqm = iqm * count
			iqwm = iqwm * count
		end
 		return {
			text = "BottomScanner",
			note = "",
			bid = iqwm,
			buyout = iqm
		}
	end
	return nil
end

BtmScan.CompileBaseRule = function()
	if not data or not data.baseRule or data.baseRule == "default" then
		BtmScan.BaseRule = nil
		return
	end

	local script = -- Block script below:
[[
local consKey     = BtmScan.prices.consKey
local consMean    = BtmScan.prices.consMean
local consPrice   = BtmScan.prices.consPrice
local consSeen    = BtmScan.prices.consSeen
local auctKey     = BtmScan.prices.auctKey
local auctPrice   = BtmScan.prices.auctPrice
local auctSeen    = BtmScan.prices.auctSeen
local itemID      = BtmScan.prices.itemID
local itemRand    = BtmScan.prices.itemRand
local itemEnch    = BtmScan.prices.itemEnch
local itemCount   = BtmScan.prices.itemCount
local bidPrice    = BtmScan.prices.bidPrice
local buyPrice    = BtmScan.prices.buyPrice
local basePrice   = BtmScan.prices.basePrice
local depositCost = BtmScan.prices.depositCost
local depositRate = BtmScan.depositRate
local cutRate     = BtmScan.cutRate
local auctionFee  = 0
local action, reason
]]..data.baseRule..[[

BtmScan.prices.depositCost = depositCost
BtmScan.prices.auctionFee = auctionFee
BtmScan.prices.action = action
BtmScan.prices.reason = reason
return basePrice
]]
	-- End of block script --

	local scriptFunc = loadstring(script)
	if (not scriptFunc) then
		BtmScan.Print("Error compiling BottomScanner BaseRule script")
		BtmScan.BaseRule = nil
		return
	end
	BtmScan.Print(tr("BottomScanner has set %1 to %2", tr("Base Rule"), tr("the provided value")))
	BtmScan.BaseRule = scriptFunc
end

BtmScan.GetDepositCost = function (itemID, count)
	local vendorValue = BtmScan.GetVendorPrice(itemID, count)
	if (not vendorValue) then return 0 end
	local baseDeposit = math.floor(vendorValue * BtmScan.depositRate) -- 2 hr auction
	return baseDeposit * 12 -- 24 hour auction
end

BtmScan.GetVendorPrice = function(itemID, count)
	local vendorValue = BtmScan.VendorPrices[itemID]
	if (not vendorValue and Informant and Informant.GetItem) then
		local itemInfo = Informant.GetItem(itemID, true)
		if (itemInfo and itemInfo.sell) then
			vendorValue = tonumber(itemInfo.sell) or 0
		end
	end
	if not vendorValue then return end
	if (count and count > 1) then vendorValue = vendorValue * count end
	return vendorValue
end

BtmScan.ConfigZone = function (whence)
	local realmName = GetRealmName()
	local currentZone = GetMinimapZoneText()
	local factionGroup
	
	if (not BtmScanData.factions) then
		BtmScan.Print(tr("BottomScanner: %1", tr("Zone data uninitialized: %1", whence)))
		return
	end
	if (BtmScanData.factions[currentZone]) then
		factionGroup = BtmScanData.factions[currentZone]
	else
		SetMapToCurrentZone()
		local map = GetMapInfo()
		if ((map == "Tanaris") or (map == "Winterspring") or (map == "Stranglethorn")) then
			factionGroup = "Neutral"
		end
		BtmScanData.factions[currentZone] = factionGroup
	end

	if not factionGroup then factionGroup = UnitFactionGroup("player") end
	if not factionGroup then return end
	if (factionGroup == "Neutral") then
		BtmScan.cutRate = 0.15
		BtmScan.depositRate = 0.25
	else
		BtmScan.cutRate = 0.05
		BtmScan.depositRate = 0.05
	end
		
	return realmName.."-"..factionGroup
end

-- Gets the configdata for the current zone
BtmScan.GetZoneConfig = function (whence)
	local newZone = BtmScan.ConfigZone(whence.."getzone")
	if (not BtmScanData.refresh) then BtmScanData.refresh = 25 end -- Page refresh time
	if not newZone then
		BtmScan.Print(tr("BottomScanner: %1", tr("Unable to get config zone: %1", whence)))
		dataZone = ""
		data = {}
	elseif (newZone ~= dataZone) then
		BtmScan.Print(tr("BottomScanner: %1", tr("Switching to %1 config zone", newZone)))
		dataZone = newZone
		if (not BtmScanData.config[dataZone]) then BtmScanData.config[dataZone] = {} end
		data = BtmScanData.config[dataZone]

		if (not BtmScanData.version or BtmScanData.version < 115) then
			for i,j in pairs(BtmScanData) do
				-- Copy realm specific data to realm element
				if (i ~= "config" and i ~= "unlocked" and
				    i ~= "refresh" and i ~= "factions" and
				    i ~= "printFrame" and i ~= "version" and
				    not data[i]) then
					data[i] = j
					BtmScanData[i] = nil
				end
			end
			BtmScanData.version = 115
		end
	else
		return
	end

	-- Check config data
	if (not data.maxPrice) then data.maxPrice = 25000 end -- 2g50 max buyout
	if (not data.minProfit) then data.minProfit = 3000 end -- 30s min profit
	if (not data.pctProfit) then data.pctProfit = 30 end -- 30% min profit
	if (not data.minDeProfit) then data.minDeProfit = 4500 end -- 4g50
	if (not data.pctDeProfit) then data.pctDeProfit = 45 end -- 45%
	if (not data.reserve) then data.reserve = 20000 end -- 2gReserve
	if (not data.deFactor) then data.deFactor = 1.5 end -- 150%
	if (not data.minSeen) then data.minSeen = 3 end -- 150%
	if (not data.vendProfit) then data.vendProfit = 20 end -- 20c min vendor profit
	if (not data.commonMult) then data.commonMult = 1.5 end -- common multiplier
	if (not data.allowBids) then data.allowBids = 0 end -- to allow or not allow
	if (not data.ignore) then data.ignore = {} end -- ignore nothing
	if (not data.snatch) then data.snatch = {} end -- snatch list
	if (not data.snatched) then data.snatched = {} end -- snatched list
	if (not data.worth) then data.worth = {} end -- fixed price list
	if (not data.bids) then data.bids = {} end -- latest bids and reasons
	if (not data.safetyCount) then data.safetyCount = 6 end -- safetynet count
	if (not data.safetyCost) then
		data.safetyCost = data.safetyCount * data.maxPrice / 2
	end -- safetynet cost
	if (not data.enchLevel) then data.enchLevel = 300 end --Shows all disenchant deals regaurdless of user's enchanting level
	
	if (not data.tooltipOn) then
		data.tooltipOn = true	 --Sets the tooltip as on by default
	end
	
	BtmScan.CompileBaseRule()
end


BtmScan.TooltipHook = function (funcVars, retVal, frame, name, link, quality, count)
	-- Make sure the current zone is loaded and has defaults
	BtmScan.GetZoneConfig("tooltip")

	--If the tooltip option is disabled, then disable showing of the BtmScan tooltip unless we are currently BTM scanning
	if (data.tooltipOn ~= true) then
		if (not BtmScan.scanning) then return end
	end

	local ltype = EnhTooltip.LinkType(link)
	if ltype == "item" then
		local itemID, itemRand, itemEnch, itemUniq = BtmScan.BreakLink(link)
		-- Since TooltipHook is a global accessable function, we have to make sure that the given link contains all the necessary information
		if (not itemID) or (not itemRand) or (not itemEnch) then
			-- TODO: Add something to log this to identify the incompatible addon and possible bugs
			return
		end
		local sanityKey = itemID..":"..itemRand
		local auctKey = itemID..":"..itemRand..":"..itemEnch

		local sanity = BtmScan.ConfidenceList[sanityKey] or ""
		local iqm, iqwm, iqCount = strsplit(",", sanity)
		iqm = tonumber(iqm) or 0
		iqwm = tonumber(iqwm) or 0
		iqCount = tonumber(iqCount) or 0
		if (count and count > 1) then
			iqm = iqm * count
			iqwm = iqwm * count
		end

		EnhTooltip.AddLine(tr("BottomScanner prices"))
		EnhTooltip.LineColor(0.9,0.6,0.2)
		EnhTooltip.AddLine("  "..tr("IQR Mean"), iqm)
		EnhTooltip.LineColor(0.9,0.6,0.2)
		EnhTooltip.AddLine("  "..tr("Conservative"), iqwm)
		EnhTooltip.LineColor(0.9,0.6,0.2)

		local baseIs = "Conservative"
		local basePrice = iqwm
		local auctMedian, auctCount
		if (Auctioneer and Auctioneer.Statistic) then
			auctMedian, auctCount = Auctioneer.Statistic.GetUsableMedian(auctKey)
			if (auctMedian and auctCount) then
				if (auctMedian > basePrice) then
					basePrice = auctMedian
					baseIs = "Auctioneer"
				end
			end
		end
		if (not auctMedian) then auctMedian = 0 end
		if (not auctCount) then auctCount = 0 end

		if (not count or count < 1) then count = 1 end
		local deposit = BtmScan.GetDepositCost(itemID, count)
		if (not deposit) then deposit = 0 end
		if (BtmScan.BaseRule) then
			BtmScan.prices = {
				consKey = sanityKey,
				consMean = iqm,
				consPrice = iqwm,
				consSeen = iqCount,
				auctKey = auctKey,
				auctPrice = auctMedian * count,
				auctSeen = auctCount,
				itemID = itemID,
				itemRand = itemRand,
				itemEnch = itemEnch,
				itemCount = count,
				bidPrice = 0,
				buyPrice = 0,
				basePrice = basePrice * count,
				depositCost = deposit
			}
			local newBase = BtmScan.BaseRule()
			if (not newBase or newBase <= 0) then
				basePrice = 0
			elseif (newBase ~= basePrice) then
				basePrice = newBase
				baseIs = "Custom"
			end
		else
			basePrice = basePrice * count
		end

		if (data.worth[sanityKey]) then
			basePrice = tonumber(data.worth[sanityKey]) or 0
			baseIs = "Fixed Worth"
		end

		if (not basePrice or basePrice <= 0) then
			basePrice = 0
			baseIs = "Don't Buy"
		end

		local auctionFee, action, reason
		if (BtmScan.prices) then
			auctionFee = BtmScan.prices.auctionFee
			action = BtmScan.prices.action
			if not (action == "bid" or action == "buy" or action == "ignore") then
				action = nil
			end
			reason = BtmScan.prices.reason
		end
		if (not auctionFee or auctionFee <= 0) then
			auctionFee = basePrice * 0.05
		end

		if (BtmScan.prices and BtmScan.prices.depositCost and BtmScan.prices.depositCost > 0) then
			deposit = BtmScan.prices.depositCost
		end

		EnhTooltip.AddLine("  "..tr("Valuation (%1)", tr(baseIs)), basePrice)
		EnhTooltip.LineColor(0.9,0.9,0.2)
		if (basePrice > 0) then
			EnhTooltip.AddLine("    ("..tr("Auction Fee")..")", auctionFee)
			EnhTooltip.LineColor(0.9,0.8,0.4)
			EnhTooltip.AddLine("    ("..tr("Deposit Cost")..")", deposit)
			EnhTooltip.LineColor(0.9,0.8,0.4)
		end

		if (action) then
			EnhTooltip.AddLine("    "..tr("Recommend")..": "..tr(action))
			EnhTooltip.LineColor(0.9,0.8,0.4)
			if (reason) then
				EnhTooltip.AddLine("    "..tr("Because")..": "..reason)
				EnhTooltip.LineColor(0.9,0.8,0.4)
			end
		end

		if (data.snatch[sanityKey]) then
			local sdata = data.snatch[sanityKey]
			local price, count, stack
			local snatchLine = ""
			if (type(sdata) ~= "table") then
				price = tonumber(amount) or 0
				count = 0
				stack = 0
			else
				price = tonumber(sdata[1]) or 0
				count = tonumber(sdata[2]) or 0
				stack = tonumber(sdata[3]) or 0
			end
			if (count == 0) then
				EnhTooltip.AddLine("  "..tr("Snatch it at"), price)
			else
				local fulfilled = tonumber(data.snatched[sanityKey]) or 0
				EnhTooltip.AddLine("  "..tr("Snatch %1 (%2 done)", count, fulfilled), price)
			end
			EnhTooltip.LineColor(0.9,0.9,0.2)
			if (stack > 1) then
				EnhTooltip.AddLine("    "..tr("(or per %1 stack)", stack), price * stack)
				EnhTooltip.LineColor(0.9,0.9,0.2)
			end
		end

		if (BtmScan.sessionSpend and BtmScan.sessionSpend[sanityKey]) then
			local sspend = BtmScan.sessionSpend[sanityKey]
			EnhTooltip.AddLine("  "..tr("SafetyNet: %1 bought",  sspend.count), tonumber(sspend.cost) or 0)
			EnhTooltip.LineColor(0.9,0.6,0.2)
		end

		local bidSig = link.."x"..count
		if (data.bids and data.bids[bidSig]) then
			local whyBuy = data.bids[bidSig][1]
			local howMuch = data.bids[bidSig][2]
			local bidType = data.bids[bidSig][3] or tr("bought")
			local tStamp = data.bids[bidSig][4]
			local ago = ""
			if (tStamp) then
				local elapsed = time() - tStamp
				ago = tr(" (%1 ago)", SecondsToTime(elapsed))
			end
			EnhTooltip.AddLine("  "..tr("Last %1 for %2%3",  bidType, whyBuy, ago), tonumber(howMuch) or 0)
			EnhTooltip.LineColor(0.2,0.4,0.9)
		end
	end
end

BtmScan.DoTooltip = function ()
	if (not this.lineID) then return end

	local i = this.lineID
	local line = BtmScan.LogFrame.Lines[i]:GetText()

	local itemID, itemRand, itemEnch, itemUniq, itemName, wholeLink, count, cost = BtmScan.BreakLink(line)
	if (itemID and itemID > 0) then
		--GameTooltip:SetOwner(BtmScan.LogFrame, "ANCHOR_NONE")
		GameTooltip:SetOwner(AuctionFrameCloseButton, "ANCHOR_NONE")
		GameTooltip:SetHyperlink(wholeLink)
		GameTooltip:ClearAllPoints()
		GameTooltip:SetPoint("TOPLEFT", "AuctionFrame", "TOPRIGHT", 10, -20)
		if (EnhTooltip) then
			EnhTooltip.TooltipCall(GameTooltip, itemName, wholeLink, -1, count, cost)
		end
	end
end
BtmScan.PurchaseTooltip = function()
	local iLink = BtmScan.Prompt.iLink
	if (iLink) then
		local itemID, itemRand, itemEnch, itemUniq, itemName, wholeLink = BtmScan.BreakLink(iLink)
		if (itemID and itemID > 0) then
			GameTooltip:SetOwner(AuctionFrameCloseButton, "ANCHOR_NONE")
			GameTooltip:SetHyperlink(iLink)
			GameTooltip:ClearAllPoints()
			GameTooltip:SetPoint("TOPLEFT", "AuctionFrame", "TOPRIGHT", 10, -20)
			if (EnhTooltip) then
				EnhTooltip.TooltipCall(GameTooltip, itemName, wholeLink, -1, BtmScan.Prompt.iCount, BtmScan.Prompt.bidPrice)
			end
		end
	end
end
BtmScan.UndoTooltip = function ()
	GameTooltip:Hide()
end

function BtmScan.AuctionFrameTabClickHook(_,_, index)
	if (not index) then index = this:GetID(); end

	local tab = getglobal("AuctionFrameTab"..index);
	if (tab and tab:GetName() == "AuctionFrameTabBtmScan") then
		AuctionFrameTopLeft:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-TopLeft");
		AuctionFrameTop:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-Top");
		AuctionFrameTopRight:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-TopRight");
		AuctionFrameBotLeft:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-BotLeft");
		AuctionFrameBot:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-Bot");
		AuctionFrameBotRight:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-BotRight");
		BtmScan.LogParent:SetPoint("TOPLEFT", "AuctionFrame", "TOPLEFT", 10,-70)
		BtmScan.LogParent:Show();
		AuctionFrameMoneyFrame:Hide();
	else
		BtmScan.LogParent:Hide();
		AuctionFrameMoneyFrame:Show();
	end
end



BtmScan.PromptPurchase = function(i, bidSig, whyBuy, bidPrice, bidType, noSafety, snatching, iCount, stackSize, sanityKey, iLink, iTex, price, value, profit, message)
	BtmScan.scanStage = 3
	BtmScan.Prompt.index     = i
	BtmScan.Prompt.bidSig    = bidSig
	BtmScan.Prompt.whyBuy    = whyBuy
	BtmScan.Prompt.bidPrice  = bidPrice
	BtmScan.Prompt.bidType   = bidType
	BtmScan.Prompt.noSafety  = noSafety
	BtmScan.Prompt.snatching = snatching
	BtmScan.Prompt.iCount    = iCount
	BtmScan.Prompt.stackSize = stackSize
	BtmScan.Prompt.sanityKey = sanityKey
	BtmScan.Prompt.iLink     = iLink
	BtmScan.Prompt.iTex      = iTex
	BtmScan.Prompt.price     = price
	BtmScan.Prompt.value     = value
	BtmScan.Prompt.profit    = profit
	BtmScan.Prompt.message   = message

	local bidText = bidType
	if (bidText == tr("bought")) then bidText = tr("buyout") end
	
	BtmScan.Prompt.Lines[1]:SetText(tr("Do you want to %1:", bidText))
	BtmScan.Prompt.Lines[2]:SetText("  "..iLink.."x"..iCount)
	BtmScan.Prompt.Lines[3]:SetText("  "..tr("%1 price: %2", bidText, BtmScan.GSC(bidPrice)))
	BtmScan.Prompt.Lines[4]:SetText("  "..tr("Purchasing for: %1", whyBuy))
	BtmScan.Prompt.Lines[5]:SetText("  "..tr("Valued at %1 (%2 profit)", BtmScan.GSC(value), BtmScan.GSC(profit)))
	BtmScan.Prompt.Item:GetNormalTexture():SetTexture(iTex)
	BtmScan.Prompt.Item:GetNormalTexture():SetTexCoord(0,1,0,1)
	PlaySoundFile("Interface\\AddOns\\btmScan\\Sounds\\DoorBell.mp3")
	BtmScan.Prompt:Show()

end


local function checkItem(i, iLink, iCount, bidType, bidPrice)
	local isCorrect = false
	local itemLink = GetAuctionItemLink("list", i)
	if (itemLink == iLink) then
		local aName,aTex,aCount,aQual,aUse,aLvl,aMin,aInc,aBuy,aCur,aHigh,aOwner = GetAuctionItemInfo("list", i)
		if (aCount == iCount) then
			if (bidType == tr("bought")) then
				if (aBuy == bidPrice) then
					isCorrect = true
				end
			else
				if (aCur and aCur > 0) then
					if (aCur + aInc == bidPrice) then
						isCorrect = true
					end
				elseif (aMin == bidPrice) then
					isCorrect = true
				end
			end
		end
	end
	return isCorrect
end

BtmScan.PerformPurchase = function()
	local i         = BtmScan.Prompt.index
	local iLink     = BtmScan.Prompt.iLink
	local iCount    = BtmScan.Prompt.iCount
	local bidSig    = BtmScan.Prompt.bidSig
	local whyBuy    = BtmScan.Prompt.whyBuy
	local bidPrice  = BtmScan.Prompt.bidPrice
	local bidType   = BtmScan.Prompt.bidType
	local noSafety  = BtmScan.Prompt.noSafety
	local snatching = BtmScan.Prompt.snatching
	local stackSize = BtmScan.Prompt.stackSize
	local sanityKey = BtmScan.Prompt.sanityKey
	local message   = BtmScan.Prompt.message

	data.bids[bidSig] = { whyBuy, bidPrice, bidType, time() }
	
	-- Verify first that the item is still there
	local there = false
	local pageCount, totalCount = GetNumAuctionItems("list")
	if (i <= pageCount) then
		there = checkItem(i, iLink, iCount, bidType, bidPrice)
	end
	
	if (not there) then
		for j = 1, pageCount do
			there = checkItem(j, iLink, iCount, bidType, bidPrice)
			if (there) then
				i = j
				break
			end
		end
	end

	if (not there) then
		BtmScan.Prompt:Hide()
		BtmScan.Log(tr("Warning: Unable to make purchase of %1. Can't find on current page.", iLink))
		BtmScan.scanStage = 2
		return
	end
	
	BtmScan.Log(message)
	PlaceAuctionBid("list", i, bidPrice)

	-- Mark this item as "bought"
	if (not noSafety) then
		local bought = 1
		if (stackSize and stackSize > 1) then
			bought = iCount / stackSize
		end
		
		if (BtmScan.sessionSpend[sanityKey]) then
			BtmScan.sessionSpend[sanityKey].count = BtmScan.sessionSpend[sanityKey].count + bought 
			BtmScan.sessionSpend[sanityKey].cost = BtmScan.sessionSpend[sanityKey].cost + bidPrice
		else
			BtmScan.sessionSpend[sanityKey] = { count = bought, cost = bidPrice }
		end
	end
	if (snatching) then
		local snatched = tonumber(data.snatched[sanityKey]) or 0
		data.snatched[sanityKey] = snatched + iCount
	end
	BtmScan.Prompt:Hide()
	BtmScan.scanStage = 2
	BtmScan.timer = 0
	BtmScan.pageScan = 0.001
end

BtmScan.CancelPurchase = function()
	local key = BtmScan.Prompt.sanityKey
	local price = math.floor(BtmScan.Prompt.bidPrice / BtmScan.Prompt.iCount)
	if (not BtmScan.NoPrompt[key]) or (price < BtmScan.NoPrompt[key]) then
		BtmScan.NoPrompt[key] = price
		BtmScan.Print(tr("BottomScanner autoignoring %1 for more than %2 this session.", BtmScan.Prompt.iLink, BtmScan.GSC(price)))
	end
	BtmScan.scanStage = 2
	BtmScan.timer = 0
	BtmScan.pageScan = 0.001
	BtmScan.Prompt:Hide()
end

BtmScan.IgnorePurchase = function()
	local key = BtmScan.Prompt.sanityKey
	data.ignore[key] = true
	BtmScan.Print(tr("BottomScanner will now %1 %2", tr("ignore"), BtmScan.Prompt.iLink))
	BtmScan.scanStage = 2
	BtmScan.timer = 0
	BtmScan.pageScan = 0.001
	BtmScan.Prompt:Hide()
end

BtmScan.InputData = {
	dataField = nil,
	callBack = nil
}
BtmScan.InputShow = function ()
	if (BtmScan.InputData.dataField) then
		BtmScan.Input.Box:SetText(data[BtmScan.InputData.dataField] or "")
	else
		BtmScan.Input.Box:SetText("")
	end
end
BtmScan.InputDone = function ()
	if (BtmScan.InputData.dataField) then
		data[BtmScan.InputData.dataField] = BtmScan.Input.Box:GetText()
	end
	if (BtmScan.InputData.callBack) then
		BtmScan.InputData.callBack(BtmScan.Input.Box:GetText())
	end
	BtmScan.Input:Hide()
end
BtmScan.EditData = function (dataField, callBack)
	BtmScan.InputData.dataField = dataField
	BtmScan.InputData.callBack = callBack
	BtmScan.Input:Show()
end
BtmScan.InputUpdate = function()
	BtmScan.Input.Scroll:UpdateScrollChildRect()
--	local bar = getglobal(this:GetParent():GetName().."ScrollBar")
--	local min, max
--	min, max = bar:GetMinMaxValues()
--	if (max > 0 and this.max ~= max) then
--		this.max = max
--		bar:SetValue(max)
--	end
end
BtmScan.ToggleScan = function()
	if (BtmScan.scanning) then
		BtmScan.EndScan()
	else
		BtmScan.BeginScan()
	end
end

BtmScan.Frame = CreateFrame("Frame")
BtmScan.Frame:RegisterEvent("ADDON_LOADED")
BtmScan.Frame:SetScript("OnEvent", BtmScan.OnEvent)
BtmScan.Frame:SetScript("OnUpdate", BtmScan.OnUpdate)

BtmScan.Prompt = CreateFrame("Frame", "", UIParent)
BtmScan.Prompt:Hide()
BtmScan.Prompt:SetPoint("TOP", "UIParent", "TOP", 0, -100)
BtmScan.Prompt:SetFrameStrata("DIALOG")
BtmScan.Prompt:SetHeight(150)
BtmScan.Prompt:SetWidth(400)
BtmScan.Prompt:SetBackdrop({
	bgFile = "Interface/Tooltips/UI-Tooltip-Background",
	edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
	tile = true, tileSize = 32, edgeSize = 32,
	insets = { left = 9, right = 9, top = 9, bottom = 9 }
})
BtmScan.Prompt:SetBackdropColor(0,0,0, 0.8)
BtmScan.Prompt:SetMovable(true)

BtmScan.Prompt.Drag = CreateFrame("Button", "", BtmScan.Prompt)
BtmScan.Prompt.Drag:SetPoint("TOPLEFT", BtmScan.Prompt, "TOPLEFT", 10,-5)
BtmScan.Prompt.Drag:SetPoint("TOPRIGHT", BtmScan.Prompt, "TOPRIGHT", -10,-5)
BtmScan.Prompt.Drag:SetHeight(6)
BtmScan.Prompt.Drag:SetHighlightTexture("Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar")
BtmScan.Prompt.Drag:SetScript("OnMouseDown", function() BtmScan.Prompt:StartMoving() end)
BtmScan.Prompt.Drag:SetScript("OnMouseUp", function() BtmScan.Prompt:StopMovingOrSizing() end)

BtmScan.Prompt.Item = CreateFrame("Button", "", BtmScan.Prompt)
BtmScan.Prompt.Item:SetNormalTexture("Interface\\Buttons\\UI-Slot-Background")
BtmScan.Prompt.Item:GetNormalTexture():SetTexCoord(0,0.640625, 0,0.640625)
BtmScan.Prompt.Item:SetPoint("TOPLEFT", BtmScan.Prompt, "TOPLEFT", 15, -15)
BtmScan.Prompt.Item:SetHeight(37)
BtmScan.Prompt.Item:SetWidth(37)
BtmScan.Prompt.Item:SetScript("OnEnter", BtmScan.PurchaseTooltip)
BtmScan.Prompt.Item:SetScript("OnLeave", BtmScan.UndoTooltip)

BtmScan.Prompt.Lines = {}
for i = 1, 5 do
	BtmScan.Prompt.Lines[i] = BtmScan.Prompt:CreateFontString("BtmScanPromptLine"..i, "HIGH")
	if (i == 1) then
		BtmScan.Prompt.Lines[i]:SetPoint("TOPLEFT", BtmScan.Prompt.Item, "TOPRIGHT", 5, 5)
		BtmScan.Prompt.Lines[i]:SetFont("Fonts\\FRIZQT__.TTF",16)
	else
		BtmScan.Prompt.Lines[i]:SetPoint("TOPLEFT", BtmScan.Prompt.Lines[i-1], "BOTTOMLEFT")
		BtmScan.Prompt.Lines[i]:SetFont("Fonts\\FRIZQT__.TTF",13)
	end
	BtmScan.Prompt.Lines[i]:SetWidth(350)
	BtmScan.Prompt.Lines[i]:SetJustifyH("LEFT")
	BtmScan.Prompt.Lines[i]:SetText("Prompt Line "..i)
	BtmScan.Prompt.Lines[i]:Show()
end

BtmScan.Prompt.Yes = CreateFrame("Button", "", BtmScan.Prompt, "OptionsButtonTemplate")
BtmScan.Prompt.Yes:SetText(tr("Yes"))
BtmScan.Prompt.Yes:SetPoint("BOTTOMRIGHT", BtmScan.Prompt, "BOTTOMRIGHT", -10, 10)
BtmScan.Prompt.Yes:SetScript("OnClick", BtmScan.PerformPurchase)
BtmScan.Prompt.No = CreateFrame("Button", "", BtmScan.Prompt, "OptionsButtonTemplate")
BtmScan.Prompt.No:SetText(tr("No"))
BtmScan.Prompt.No:SetPoint("BOTTOMRIGHT", BtmScan.Prompt.Yes, "BOTTOMLEFT", -5, 0)
BtmScan.Prompt.No:SetScript("OnClick", BtmScan.CancelPurchase)
BtmScan.Prompt.Ignore = CreateFrame("Button", "", BtmScan.Prompt, "OptionsButtonTemplate")
BtmScan.Prompt.Ignore:SetText(tr("Ignore"))
BtmScan.Prompt.Ignore:SetPoint("BOTTOMRIGHT", BtmScan.Prompt.No, "BOTTOMLEFT", -5, 0)
BtmScan.Prompt.Ignore:SetScript("OnClick", BtmScan.IgnorePurchase)

BtmScan.Input = CreateFrame("Frame", "", UIParent)
BtmScan.Input:Hide()
BtmScan.Input:SetPoint("CENTER", "UIParent", "CENTER")
BtmScan.Input:SetFrameStrata("DIALOG")
BtmScan.Input:SetHeight(280)
BtmScan.Input:SetWidth(500)
BtmScan.Input:SetBackdrop({
	bgFile = "Interface/Tooltips/UI-Tooltip-Background",
	edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
	tile = true, tileSize = 32, edgeSize = 32,
	insets = { left = 9, right = 9, top = 9, bottom = 9 }
})
BtmScan.Input:SetBackdropColor(0,0,0, 0.8)
BtmScan.Input:SetScript("OnShow", BtmScan.InputShow)

BtmScan.Input.Done = CreateFrame("Button", "", BtmScan.Input, "OptionsButtonTemplate")
BtmScan.Input.Done:SetText(tr("Done"))
BtmScan.Input.Done:SetPoint("BOTTOMRIGHT", BtmScan.Input, "BOTTOMRIGHT", -10, 10)
BtmScan.Input.Done:SetScript("OnClick", BtmScan.InputDone)

BtmScan.Input.Scroll = CreateFrame("ScrollFrame", "BtmScanInputScroll", BtmScan.Input, "UIPanelScrollFrameTemplate")
BtmScan.Input.Scroll:SetPoint("TOPLEFT", BtmScan.Input, "TOPLEFT", 20, -20)
BtmScan.Input.Scroll:SetPoint("RIGHT", BtmScan.Input, "RIGHT", -30, 0)
BtmScan.Input.Scroll:SetPoint("BOTTOM", BtmScan.Input.Done, "TOP", 0, 10)

BtmScan.Input.Box = CreateFrame("EditBox", "BtmScanEditBox", BtmScan.Input.Scroll)
BtmScan.Input.Box:SetWidth(460)
BtmScan.Input.Box:SetHeight(85)
BtmScan.Input.Box:SetMultiLine(true)
BtmScan.Input.Box:SetAutoFocus(true)
BtmScan.Input.Box:SetFontObject(GameFontHighlight)
BtmScan.Input.Box:SetScript("OnEscapePressed", BtmScan.InputDone)
BtmScan.Input.Box:SetScript("OnTextChanged", BtmScan.InputUpdate)

BtmScan.Input.Scroll:SetScrollChild(BtmScan.Input.Box)

BtmScan.CreateLogWindow = function()
	if (BtmScan.LogFrame) then return end
	if (not AuctionFrame) then return end

	local LOG_LINES = 22

	-- Make sure the current zone is loaded and has defaults
	BtmScan.GetZoneConfig("createlog")

	BtmScan.LogParent = CreateFrame("Frame", "", AuctionFrame)
	BtmScan.LogParent:SetPoint("TOPLEFT", "AuctionFrame", "TOPLEFT", 10,-70)
--	BtmScan.LogParent:SetFrameStrata("BACKGROUND")
	BtmScan.LogParent:SetWidth(822)
	BtmScan.LogParent:SetHeight(370)
	BtmScan.LogParent:SetBackdrop({
		bgFile = "Interface\\AddOns\\BtmScan\\Textures\\Back",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true, tileSize = 128, edgeSize = 16,
		insets = { left = 6, right = 6, top = 6, bottom = 6
	}})
--	BtmScan.LogParent:SetBackdropColor(0,0,0, 1)
	BtmScan.LogParent:Hide()

	BtmScan.LogFrame = CreateFrame("ScrollFrame", "BtmScanLogFrame", BtmScan.LogParent, "FauxScrollFrameTemplate")
	BtmScan.LogFrame:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 4,
		insets = { left = 6, right = 6, top = 6, bottom = 6
	}})
	BtmScan.LogFrame:SetBackdropColor(0,0,0, 0.78)
	BtmScan.LogFrame:SetPoint("TOPLEFT", BtmScan.LogParent, "BOTTOMLEFT", 10, 250)
	BtmScan.LogFrame:SetPoint("BOTTOMRIGHT", BtmScan.LogParent, "BOTTOMRIGHT", -35, 10)

	BtmScan.LogFrame.LineFrames = {}
	BtmScan.LogFrame.Dates = {}
	BtmScan.LogFrame.Lines = {}
	for i=1, LOG_LINES do
		BtmScan.LogFrame.LineFrames[i] = CreateFrame("Frame", "BtmScanLogFrame"..i, BtmScan.LogFrame)
		if (i == 1) then
			BtmScan.LogFrame.LineFrames[i]:SetPoint("TOPLEFT", BtmScan.LogFrame, "TOPLEFT", 10, -10)
			BtmScan.LogFrame.LineFrames[i]:SetPoint("RIGHT", BtmScan.LogFrame, "RIGHT", -20, 0)
		else
			BtmScan.LogFrame.LineFrames[i]:SetPoint("TOPLEFT", BtmScan.LogFrame.LineFrames[i-1], "BOTTOMLEFT")
			BtmScan.LogFrame.LineFrames[i]:SetPoint("RIGHT", BtmScan.LogFrame.LineFrames[i-1], "RIGHT")
		end
		BtmScan.LogFrame.LineFrames[i]:SetHeight(10)
		BtmScan.LogFrame.LineFrames[i].lineID = i
		BtmScan.LogFrame.LineFrames[i]:EnableMouse(true)
		BtmScan.LogFrame.LineFrames[i]:SetScript("OnEnter", BtmScan.DoTooltip)
		BtmScan.LogFrame.LineFrames[i]:SetScript("OnLeave", BtmScan.UndoTooltip)

		BtmScan.LogFrame.Dates[i] = BtmScan.LogFrame.LineFrames[i]:CreateFontString("BtmScanLogDate"..i, "HIGH")
		BtmScan.LogFrame.Dates[i]:SetPoint("TOPLEFT", BtmScan.LogFrame.LineFrames[i], "TOPLEFT")
		BtmScan.LogFrame.Dates[i]:SetWidth(90)
		BtmScan.LogFrame.Dates[i]:SetFont("Fonts\\FRIZQT__.TTF",11)
		BtmScan.LogFrame.Dates[i]:SetJustifyH("LEFT")
		BtmScan.LogFrame.Dates[i]:SetText("Date"..i)
		BtmScan.LogFrame.Dates[i]:Show()

		BtmScan.LogFrame.Lines[i] = BtmScan.LogFrame.LineFrames[i]:CreateFontString("BtmScanLogLine"..i, "HIGH")
		BtmScan.LogFrame.Lines[i]:SetFont("Fonts\\FRIZQT__.TTF",11)
		BtmScan.LogFrame.Lines[i]:SetPoint("TOPLEFT", BtmScan.LogFrame.Dates[i], "TOPRIGHT", 5, 0)
		BtmScan.LogFrame.Lines[i]:SetPoint("RIGHT", BtmScan.LogFrame.LineFrames[i], "RIGHT")
		BtmScan.LogFrame.Lines[i]:SetJustifyH("LEFT")
		BtmScan.LogFrame.Lines[i]:SetText("Text"..i)
		BtmScan.LogFrame.Lines[i]:Show()
	end

	BtmScan.LogFrame.Update = function()
		if (not data.logText) then
			data.logText = { { time(), "--- Welcome to BottomScanner ---" } }
		end
		local rows = table.getn(data.logText)
		local scrollrows = rows
		if (scrollrows > 0 and scrollrows < LOG_LINES+1) then scrollrows = LOG_LINES+1 end
		FauxScrollFrame_Update(BtmScan.LogFrame, scrollrows, LOG_LINES, LOG_LINES*2)
		local line
		for i=1, LOG_LINES do
			line = rows - (FauxScrollFrame_GetOffset(BtmScanLogFrame) + i) + 1
			if (rows > 0 and line <= rows and line > 0) then
				BtmScan.LogFrame.Dates[i]:SetText("["..date("%d %b %H:%M", data.logText[line][1]).."]")
				BtmScan.LogFrame.Lines[i]:SetText(data.logText[line][2])
			else
				BtmScan.LogFrame.Dates[i]:SetText("")
				BtmScan.LogFrame.Lines[i]:SetText("")
			end
		end
	end
	BtmScan.LogFrame:SetScript("OnVerticalScroll", function ()
		FauxScrollFrame_OnVerticalScroll(16, BtmScan.LogFrame.Update)
	end)
	BtmScan.LogFrame:SetScript("OnShow", function()
		BtmScan.LogFrame.Update()
	end)

	-- Insert a tab into the AH
	BtmScan.ScanTab = CreateFrame("Button", "AuctionFrameTabBtmScan", AuctionFrame, "AuctionTabTemplate");
	BtmScan.ScanTab:SetText(tr("BtmScan"))
	BtmScan.ScanTab:Hide()
	BtmScan.ScanTab:Show()
	PanelTemplates_DeselectTab(BtmScan.ScanTab);

	Auctioneer.UI.InsertAHTab(BtmScan.ScanTab, BtmScan.LogParent);
	Stubby.RegisterFunctionHook("AuctionFrameTab_OnClick", 200, BtmScan.AuctionFrameTabClickHook)

	BtmScan.PlayButton = CreateFrame("Button", "", BtmScan.LogParent);
	BtmScan.PlayButton:SetNormalTexture("Interface\\AddOns\\BtmScan\\Textures\\Play")
	BtmScan.PlayButton:SetPushedTexture("Interface\\AddOns\\BtmScan\\Textures\\Stop")
	BtmScan.PlayButton:SetPoint("BOTTOMLEFT", BtmScan.LogParent, "TOPLEFT", 70, 5)
	BtmScan.PlayButton:SetHeight(24)
	BtmScan.PlayButton:SetWidth(24)
	BtmScan.PlayButton:SetScript("OnClick", BtmScan.ToggleScan)
	BtmScan.PlayButton:Show()
end
