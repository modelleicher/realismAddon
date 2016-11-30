-- by modelleicher
-- www.schwabenmodding.de
--
-- 


if g_realism == nil then
	g_realism = {};
end;


local oldBalerLoad = Baler.load;
Baler.load = function(self, savegame)
	print("realismUpdate_baler load init");
	self.isRealism2 = r_getXMLBool(self, "realism#useRealism2");
	
	oldBalerLoad(self, savegame);
		
	if self.isRealism2 then
		-- create table if not already exists in this vehicle
		if self.realism == nil then
			self.realism = {};
		end;
		-- baler specific stuff..
		local baler = {};
		baler.isSquare = Utils.getNoNil(r_getXMLBool(self, "realism.baler#isSquareBaler"), false);
		baler.isRound = Utils.getNoNil(r_getXMLBool(self, "realism.baler#isRoundBaler"), false);
		
		local xmlKey = "realism.baler.squareBaler";
		
		if baler.isSquare then
			-- strokes per minute
			baler.strokesPerMinute = Utils.getNoNil(r_getXMLFloat(self, xmlKey.."#strokesPerMinute"), 14);
			
			baler.strokeDuration = 1000*60/baler.strokesPerMinute; -- stroke per ms, thanks dural (realisticBaler.lua) :)
			baler.halfStrokeDuration = baler.strokeDuration / 2;
			
			baler.timeForNextStroke = 0;
			--baler.strokeEndDuration = 1000*60/baler.strokesPerMinute; -- stroke per ms, thanks dural (realisticBaler.lua) :) 
			--baler.strokeStartDuration = baler.strokeEndDuration*0.4; -- compressing starts a little bit after plunger is half way round
			--baler.strokeDuration = baler.strokeEndDuration - baler.strokeStartDuration;
			
		
			baler.doStroke = false;
		
			
			baler.basePowerUsage = Utils.getNoNil(r_getXMLFloat(self, xmlKey.."#basePowerUsage"), 40); -- kw
			baler.turnOnPowerMultiplier = Utils.getNoNil(r_getXMLFloat(self, xmlKey.."#turnOnPowerMultiplier"), 2); 
			baler.turnOnPowerTime = Utils.getNoNil(r_getXMLFloat(self, xmlKey.."#turnOnPowerTime"), 3)*1000 -- in ms;
			
			baler.maxPowerIncreaseStroke = Utils.getNoNil(r_getXMLFloat(self, xmlKey.."#maxPowerIncreaseStroke"), 5); -- kw
			
			baler.powerIncreasePerLiterFx = Utils.getNoNil(r_getXMLFloat(self, xmlKey.."#powerIncreasePerLiterFx"), 1); -- kw per liter per second
			-- or 1 kw per 0.001l per ms --> * 1000;
			
			
			baler.powerIncreaseHayMultiplier = Utils.getNoNil(r_getXMLFloat( self, xmlKey.."#powerIncreaseHayMultiplier"), 0.45);
			baler.powerIncreaseStrawMultiplier = Utils.getNoNil(r_getXMLFloat( self, xmlKey.."#powerIncreaseStrawMultiplier"), 0.35);
			baler.powerIncreaseGrassMultiplier =  Utils.getNoNil(r_getXMLFloat( self, xmlKey.."#powerIncreaseGrassMultiplier"), 0.7);
			

			baler.deltaLevel = 0;
			baler.lastDeltaLevel = 0;

			baler.averageCapacity = Utils.getNoNil(r_getXMLInt(self, xmlKey.."#averageCapacity"), self.fillUnits[self.baler.fillUnitIndex].capacity);
			self.fillUnits[self.baler.fillUnitIndex].capacity = baler.averageCapacity;
			baler.wantedCapacity = baler.averageCapacity;
		end;
		
		if baler.isRound then
			xmlKey = "realism.baler.roundBaler";
			baler.canUnload = false;
			baler.hasToUnload = false;
			
			baler.averageCapacity = Utils.getNoNil(r_getXMLInt(self, xmlKey.."#averageCapacity"), self.fillUnits[self.baler.fillUnitIndex].capacity);
			baler.maxCapacity = Utils.getNoNil(r_getXMLInt(self, xmlKey.."#maximumCapacity"), baler.averageCapacity*1.07);
			self.fillUnits[self.baler.fillUnitIndex].capacity = baler.maxCapacity;
			
			
			baler.basePowerUsage = Utils.getNoNil(r_getXMLFloat(self, xmlKey.."#basePowerUsage"), 10); -- kw
			baler.turnOnPowerMultiplier = Utils.getNoNil(r_getXMLFloat(self, xmlKey.."#turnOnPowerMultiplier"), 2.5); 
			baler.turnOnPowerTime = Utils.getNoNil(r_getXMLFloat(self, xmlKey.."#turnOnPowerTime"), 3)*1000 -- in ms;
			
			
			baler.powerIncreasePerLiterFx = Utils.getNoNil(r_getXMLFloat(self, xmlKey.."#powerIncreasePerLiterFx"), 1); -- kw per liter per second
			-- or 1 kw per 0.001l per ms --> * 1000;
			
			
			baler.powerIncreaseHayMultiplier = Utils.getNoNil(r_getXMLFloat( self, xmlKey.."#powerIncreaseHayMultiplier"), 0.45);
			baler.powerIncreaseStrawMultiplier = Utils.getNoNil(r_getXMLFloat( self, xmlKey.."#powerIncreaseStrawMultiplier"), 0.35);
			baler.powerIncreaseGrassMultiplier =  Utils.getNoNil(r_getXMLFloat( self, xmlKey.."#powerIncreaseGrassMultiplier"), 0.7);			
		end;
		
		baler.turnedOnTime = 0;
		baler.turnOnTimer = nil;

		baler.lastUsedFillType = nil;
		
		baler.lastPowerUsage = 0;
		baler.powerUsageSmoothingFactor = 0.85;
		baler.maxPowerUsageExpected = 200;
		
		baler.lastTotalLiters = 0;
		baler.totalLitersSmoothingFactor = 0.5;
		
		baler.drawPowerUsage = true;
			
		self.realism.baler = baler;
	end;
end;


local oldBalerUpdate = Baler.update;
Baler.update = function(self, dt)
	if self.isRealism2 then
		
		-- only on first run (get bales if alreay in there)
		if self.firstTimeRun and self.baler.balesToLoad ~= nil then
	        if table.getn(self.baler.balesToLoad) > 0 then
	            local v = self.baler.balesToLoad[1];
	
	            if v.targetBaleTime == nil then
	                self:createBale(v.fillType, v.fillLevel)
	                self:setBaleTime(table.getn(self.baler.bales), 0, true);
	                v.targetBaleTime = v.baleTime;
	                v.baleTime = 0;
	            else
	                v.baleTime = math.min(v.baleTime + dt / 1000, v.targetBaleTime);
	                self:setBaleTime(table.getn(self.baler.bales), v.baleTime, true);
	
	                if v.baleTime == v.targetBaleTime then
	
	                    local index = table.getn(self.baler.balesToLoad);
	                    if index == 1 then
	                        self.baler.balesToLoad = nil;
	                    else
	                        table.remove(self.baler.balesToLoad, 1);
	                    end;
	                end;
	            end;
	        end;
	    end
	
		-- inputs only
	    if self:getIsActiveForInput() then
	        if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA3) then
	            if self:isUnloadingAllowed() then
	                if self.baler.baleUnloadAnimationName ~= nil or self.baler.allowsBaleUnloading then
	                    if self.baler.unloadingState == Baler.UNLOADING_CLOSED then
							if self.realism.baler.canUnload then
								if self.baler.baleTypes ~= nil then
									-- create bale
									if self.baler.baleUnloadAnimationName ~= nil then
										self:createBale(self.realism.baler.lastUsedFillType, self:getUnitFillLevel(self.baler.fillUnitIndex))
										g_server:broadcastEvent(BalerCreateBaleEvent:new(self, self.realism.baler.lastUsedFillType, 0), nil, nil, self)
										self:setIsUnloadingBale(true)
										self.realism.baler.canUnload = false;
									end
								end
							elseif table.getn(self.baler.bales) > 0 then
	                            self:setIsUnloadingBale(true)
	                        end
	                    elseif self.baler.unloadingState == Baler.UNLOADING_OPEN then
	                        if self.baler.baleUnloadAnimationName ~= nil then
	                            self:setIsUnloadingBale(false)
	                        end
	                    end
	                end
	            end
	        end
	    end
	
		-- graphics/animations only
	    if self.isClient then
	        Utils.updateRotationNodes(self, self.baler.turnedOnRotationNodes, dt, self:getIsActive() and self:getIsTurnedOn() )
	        Utils.updateScrollers(self.baler.uvScrollParts, dt, self:getIsActive() and self:getIsTurnedOn())
	    end

	else
		oldBalerUpdate(self, dt);
	end;
end;


local oldBalerUpdateTick = Baler.updateTick;
Baler.updateTick = function(self, dt)
	
	
	if self.isRealism2 then 
		-- GIANTS --
		self.baler.isSpeedLimitActive = false

		if self.isServer then
			self.baler.lastAreaBiggerZero = false
		end
		-- END
		
		-- square baler stuff..
		if self.realism.baler.isSquare then
			if self:getIsActive() then
				if self:getIsTurnedOn() then
					local currentPowerUsage = self.realism.baler.basePowerUsage;
					self.realism.baler.turnedOnTime = self.realism.baler.turnedOnTime + dt;

					-- draw more power during turning on since everything has to come up to speed
					if self.realism.baler.turnOnTimer == nil then
						self.realism.baler.turnOnTimer = true;
						self.realism.baler.turnOnTimerTime = self.realism.baler.turnedOnTime;
					elseif self.realism.baler.turnOnTimer and (self.realism.baler.turnOnTimerTime + self.realism.baler.turnOnPowerTime) < self.realism.baler.turnedOnTime then
						self.realism.baler.turnOnTimer = false;
						self.realism.baler.turnOnTimerTime = 0;
					elseif self.realism.baler.turnOnTimer then
						currentPowerUsage = self.realism.baler.basePowerUsage * self.realism.baler.turnOnPowerMultiplier;
					end;
					
					
					self.realism.baler.doStroke = false;
					
					-- do stroke calculation
					if self.realism.baler.turnedOnTime >= (self.realism.baler.timeForNextStroke - self.realism.baler.halfStrokeDuration) then -- power side of the stroke
						
						if self.realism.baler.turnedOnTime >= self.realism.baler.timeForNextStroke then -- max stroke reached
							self.realism.baler.doStroke = true;
							self.realism.baler.timeForNextStroke = self.realism.baler.turnedOnTime + self.realism.baler.strokeDuration;
							
							print(tostring(self.realism.baler.turnedOnTime));
						else
							-- half the stroke is compressing, the more we compress the more power is needed (although in theory the flywheel takes all that up it still have it in here)
							local add = self.realism.baler.maxPowerIncreaseStroke * ((self.realism.baler.turnedOnTime - self.realism.baler.timeForNextStroke) / self.realism.baler.halfStrokeDuration);
							currentPowerUsage = currentPowerUsage + add;
						end;
					end;
					

					-- DEBUG RENDER
					if Vehicle.debugRendering and self:getIsActive() then
						renderText(0.3, 0.8, getCorrectTextSize(0.02), "Realism Baler:");
						renderText(0.2, 0.78, getCorrectTextSize(0.02), "base Power Usage: "..tostring(self.realism.baler.basePowerUsage));
						renderText(0.2, 0.76, getCorrectTextSize(0.02), "base+stroke Power Usage: "..tostring(currentPowerUsage));
					end;
					
					-----------------------------------------------------------
					-- things that happen only if doStroke
					if self.realism.baler.doStroke then
						-- move all the bales			
						local deltaTime = self:getTimeFromLevel(self.realism.baler.deltaLevel)
						self:moveBales(deltaTime)
						self.realism.baler.deltaLevel = 0;
					
						-- create a new bale if fillLevel reached wanted capacity
						if self:getUnitFillLevel(self.baler.fillUnitIndex) >= self.realism.baler.wantedCapacity then
							if self.baler.baleTypes ~= nil and self.baler.baleAnimCurve ~= nil then
								self:createBale(self.realism.baler.lastUsedFillType, self:getUnitFillLevel(self.baler.fillUnitIndex)) -- creates the bale
								self:setUnitFillLevel(self.baler.fillUnitIndex, 0, self.realism.baler.lastUsedFillType, true) -- does dummy bale stuff and fill level
								
								-- get the last bale
								local numBales = table.getn(self.baler.bales)
								local bale = self.baler.bales[numBales]
								-- move the newly created bale in place (it should always be at first bale marker, so we use averageCapacity)
								self:moveBale(numBales, self:getTimeFromLevel(self.realism.baler.averageCapacity), true)
								-- note: self.baler.bales[numBales] can not be accessed anymore since the bale might be dropped already
								g_server:broadcastEvent(BalerCreateBaleEvent:new(self, self.realism.baler.lastUsedFillType, bale.time), nil, nil, self)
							end;
						end;
					
					end;
					
					-- DEBUG
					if Vehicle.debugRendering and self:getIsActive() then
						renderText(0.2, 0.66, getCorrectTextSize(0.02), "last used filltype: "..tostring(self.realism.baler.lastUsedFillType));
					end;
					
					if self:allowPickingUp() then
						self.baler.isSpeedLimitActive = true -- to do -> change speed limit stuff
						
						local newLiters = 0;
						-- server only stuff
	                    if self.isServer then
							
							-- get current fill amount
	                        local workAreas, _, _ = self:getTypedNetworkAreas(WorkArea.AREATYPE_BALER, false)
	                        local totalLiters = 0
	                        local usedFillType = FillUtil.FILLTYPE_UNKNOWN
							
	                        if table.getn(workAreas) > 0 then
	                            totalLiters, usedFillType = self:processBalerAreas(workAreas, self.baler.pickupFillTypes)
	                        end
							
							-- got something..
							if totalLiters > 0 then
								self.realism.baler.lastUsedFillType = usedFillType;
								 
								self.baler.lastAreaBiggerZero = true
	                            if self.baler.lastAreaBiggerZero ~= self.baler.lastAreaBiggerZeroSent then -- only area stuff
	                                self:raiseDirtyFlags(self.baler.dirtyFlag)
	                                self.baler.lastAreaBiggerZeroSent = self.baler.lastAreaBiggerZero
	                            end
								
								-- actual new level
	                            local deltaLevel = totalLiters * self.baler.fillScale
								
								
								-- realism delta level is added until next stroke
								if self.realism.baler.isSquare then
									self.realism.baler.deltaLevel = self.realism.baler.deltaLevel + deltaLevel;
								end;
								
								-- set the new level to the baler
	                            local oldFillLevel = self:getUnitFillLevel(self.baler.fillUnitIndex)
	                            self:setUnitFillLevel(self.baler.fillUnitIndex, oldFillLevel+deltaLevel, usedFillType, true)
								
								
								
								-- calculate extra needed power
								-- total liters = liters since last frame = liters while deltaTime ms
						        local literPerMs = totalLiters / dt;
								local literPerSecond = literPerMs * 1000;
								local literPower = self.realism.baler.powerIncreasePerLiterFx * literPerSecond;
								if self.realism.baler.lastUsedFillType == FillUtil.FILLTYPE_GRASS_WINDROW then
									literPower = literPower * self.realism.baler.powerIncreaseGrassMultiplier;
								elseif self.realism.baler.lastUsedFillType == FillUtil.FILLTYPE_DRYGRASS_WINDROW then
									literPower = literPower * self.realism.baler.powerIncreaseHayMultiplier;
								elseif self.realism.baler.lastUsedFillType == FillUtil.FILLTYPE_STRAW then
									literPower = literPower * self.realism.baler.powerIncreaseStrawMultiplier;
								end;				

								currentPowerUsage = currentPowerUsage + literPower;								
								
								
								newLiters = literPerSecond;
								
								-- DEBUG RENDER
								if Vehicle.debugRendering and self:getIsActive() then
									renderText(0.2, 0.74, getCorrectTextSize(0.02), "liter add Power Usage: "..tostring(literPower));
									renderText(0.2, 0.72, getCorrectTextSize(0.02), "final Power Usage: "..tostring(currentPowerUsage));
									renderText(0.2, 0.70, getCorrectTextSize(0.02), "total liters ms: "..tostring(totalLiters));
									renderText(0.2, 0.68, getCorrectTextSize(0.02), "total liters s: "..tostring(literPerSecond));
								end;		
								
							end;
						
						end;
					
					end;
					
					if self.realism.baler.lastPowerUsage > currentPowerUsage then
						self.realism.baler.lastPowerUsage = math.max(self.realism.baler.lastPowerUsage - (self.realism.baler.powerUsageSmoothingFactor*dt*currentPowerUsage/2), currentPowerUsage);
					elseif self.realism.baler.lastPowerUsage < currentPowerUsage then
						self.realism.baler.lastPowerUsage = math.min(self.realism.baler.lastPowerUsage + (self.realism.baler.powerUsageSmoothingFactor*dt*currentPowerUsage), currentPowerUsage);
					end;
					
					if self.realism.baler.lastTotalLiters > newLiters then
						self.realism.baler.lastTotalLiters = math.max(self.realism.baler.lastTotalLiters - (self.realism.baler.totalLitersSmoothingFactor*dt*currentPowerUsage/2), newLiters);
					elseif self.realism.baler.lastTotalLiters < newLiters then
						self.realism.baler.lastTotalLiters = math.min(self.realism.baler.lastTotalLiters + (self.realism.baler.totalLitersSmoothingFactor*dt*currentPowerUsage), newLiters);
					end;
					
					self.realism.lastRealNeededPtoPower = self.realism.baler.lastPowerUsage;
					self.powerConsumer.neededPtoPower = self.realism.baler.lastPowerUsage;
					self.neededPtoPower = self.realism.baler.lastPowerUsage;
					
					
					-- DEBUG RENDER
					if Vehicle.debugRendering and self:getIsActive() then
						renderText(0.2, 0.60, getCorrectTextSize(0.02), "smooth power usage: "..tostring(self.realism.baler.lastPowerUsage));
					end;					
					
				else
					-- reset stroke timer
					self.realism.baler.turnedOnTime = 0;
					self.realism.baler.timeForNextStroke = self.realism.baler.strokeDuration;
					
					self.realism.baler.turnOnTimer = nil;
					
					self.realism.lastRealNeededPtoPower = self.realism.baler.basePowerUsage;
					self.powerConsumer.neededPtoPower = self.realism.baler.basePowerUsage;
					self.neededPtoPower = self.realism.baler.basePowerUsage;
				end;
			end;
		
		
		-- roundbaler stuff..
		elseif self.realism.baler.isRound then
			if self:getIsActive() then
				if self:getIsTurnedOn() then
					local currentPowerUsage = self.realism.baler.basePowerUsage;
					self.realism.baler.turnedOnTime = self.realism.baler.turnedOnTime + dt;

					-- draw more power during turning on since everything has to come up to speed
					if self.realism.baler.turnOnTimer == nil then
						self.realism.baler.turnOnTimer = true;
						self.realism.baler.turnOnTimerTime = self.realism.baler.turnedOnTime;
					elseif self.realism.baler.turnOnTimer and (self.realism.baler.turnOnTimerTime + self.realism.baler.turnOnPowerTime) < self.realism.baler.turnedOnTime then
						self.realism.baler.turnOnTimer = false;
						self.realism.baler.turnOnTimerTime = 0;
					elseif self.realism.baler.turnOnTimer then
						currentPowerUsage = self.realism.baler.basePowerUsage * self.realism.baler.turnOnPowerMultiplier;
					end;		

					-- DEBUG RENDER
					if Vehicle.debugRendering and self:getIsActive() then
						renderText(0.3, 0.8, getCorrectTextSize(0.02), "Realism Baler:");
						renderText(0.2, 0.78, getCorrectTextSize(0.02), "base Power Usage: "..tostring(self.realism.baler.basePowerUsage));
						
						renderText(0.2, 0.66, getCorrectTextSize(0.02), "is grass: "..tostring(self.realism.baler.lastUsedFillType == FillUtil.FILLTYPE_GRASS));
						renderText(0.2, 0.64, getCorrectTextSize(0.02), "is straw: "..tostring(self.realism.baler.lastUsedFillType == FillUtil.FILLTYPE_STRAW));
						renderText(0.2, 0.62, getCorrectTextSize(0.02), "is grass windrow: "..tostring(self.realism.baler.lastUsedFillType == FillUtil.FILLTYPE_GRASS_WINDROW));
					end;
					
					local newLiters = 0;
								
					if self:allowPickingUp() then
						self.baler.isSpeedLimitActive = true -- to do -> change speed limit stuff
						
						-- server only stuff
						if self.isServer then
							
							-- get fill
							local workAreas, _, _ = self:getTypedNetworkAreas(WorkArea.AREATYPE_BALER, false)
							local totalLiters = 0
							local usedFillType = FillUtil.FILLTYPE_UNKNOWN
							
							if table.getn(workAreas) > 0 then
								totalLiters, usedFillType = self:processBalerAreas(workAreas, self.baler.pickupFillTypes)
							end

							
							-- if fill > 0
							if totalLiters > 0 then
								self.realism.baler.lastUsedFillType = usedFillType;
								
								self.baler.lastAreaBiggerZero = true
								if self.baler.lastAreaBiggerZero ~= self.baler.lastAreaBiggerZeroSent then -- only area stuff
									self:raiseDirtyFlags(self.baler.dirtyFlag)
									self.baler.lastAreaBiggerZeroSent = self.baler.lastAreaBiggerZero
								end
								
								-- actual new level
								local deltaLevel = totalLiters * self.baler.fillScale
								
								
								-- set the new level to the baler
								local oldFillLevel = self:getUnitFillLevel(self.baler.fillUnitIndex)
								self:setUnitFillLevel(self.baler.fillUnitIndex, oldFillLevel+deltaLevel, usedFillType, true)
										
										
								-- calculate extra needed power
								-- total liters = liters since last frame = liters while deltaTime ms
						        local literPerMs = totalLiters / dt;
								local literPerSecond = literPerMs * 1000;
								local literPower = self.realism.baler.powerIncreasePerLiterFx * literPerSecond;
								if self.realism.baler.lastUsedFillType == FillUtil.FILLTYPE_GRASS_WINDROW then
									literPower = literPower * self.realism.baler.powerIncreaseGrassMultiplier;
								elseif self.realism.baler.lastUsedFillType == FillUtil.FILLTYPE_DRYGRASS_WINDROW then
									literPower = literPower * self.realism.baler.powerIncreaseHayMultiplier;
								elseif self.realism.baler.lastUsedFillType == FillUtil.FILLTYPE_STRAW then
									literPower = literPower * self.realism.baler.powerIncreaseStrawMultiplier;
								end;
								
								newLiters = literPerSecond;
							
								currentPowerUsage = currentPowerUsage + literPower;
								-- DEBUG RENDER
								if Vehicle.debugRendering and self:getIsActive() then
									renderText(0.2, 0.74, getCorrectTextSize(0.02), "liter add Power Usage: "..tostring(literPower));
									renderText(0.2, 0.72, getCorrectTextSize(0.02), "final Power Usage: "..tostring(currentPowerUsage));
									renderText(0.2, 0.70, getCorrectTextSize(0.02), "total liters ms: "..tostring(totalLiters));
									renderText(0.2, 0.68, getCorrectTextSize(0.02), "total liters s: "..tostring(literPerSecond));
								end;	
								
								if self.realism.baler.isRound then
									-- bale is "full" -- to do roundbale overfilling ability
									if self:getUnitFillLevel(self.baler.fillUnitIndex) >= self.realism.baler.averageCapacity then
										self.realism.baler.canUnload = true;
										if self:getUnitFillLevel(self.baler.fillUnitIndex) >= self.realism.baler.maxCapacity then
											self.realism.baler.hasToUnload = true;
											self.realism.baler.canUnload = false;
											if self.baler.baleTypes ~= nil then
												-- create bale
												if self.baler.baleUnloadAnimationName ~= nil then
													self:createBale(self.realism.baler.lastUsedFillType, self:getUnitFillLevel(self.baler.fillUnitIndex))
													g_server:broadcastEvent(BalerCreateBaleEvent:new(self, self.realism.baler.lastUsedFillType, 0), nil, nil, self)
												end
											end
										end;
									end;
								end;
							end
						end
					end
					
					if self.realism.baler.lastPowerUsage > currentPowerUsage then
						self.realism.baler.lastPowerUsage = math.max(self.realism.baler.lastPowerUsage - (self.realism.baler.powerUsageSmoothingFactor*dt/2), currentPowerUsage);
					elseif self.realism.baler.lastPowerUsage < currentPowerUsage then
						self.realism.baler.lastPowerUsage = math.min(self.realism.baler.lastPowerUsage + (self.realism.baler.powerUsageSmoothingFactor*dt), currentPowerUsage);
					end;
					
					if self.realism.baler.lastTotalLiters > newLiters then
						self.realism.baler.lastTotalLiters = math.max(self.realism.baler.lastTotalLiters - (self.realism.baler.totalLitersSmoothingFactor*dt/2), newLiters);
					elseif self.realism.baler.lastTotalLiters < newLiters then
						self.realism.baler.lastTotalLiters = math.min(self.realism.baler.lastTotalLiters + (self.realism.baler.totalLitersSmoothingFactor*dt), newLiters);
					end;					
					
					self.realism.lastRealNeededPtoPower = self.realism.baler.lastPowerUsage;
					self.powerConsumer.neededPtoPower = self.realism.baler.lastPowerUsage;
					self.neededPtoPower = self.realism.baler.lastPowerUsage;
					
					-- DEBUG RENDER
					if Vehicle.debugRendering and self:getIsActive() then
						renderText(0.2, 0.60, getCorrectTextSize(0.02), "smooth power usage: "..tostring(self.realism.baler.lastPowerUsage));
					end;
					
					
				else
					self.realism.baler.turnOnTimer = nil;
					self.realism.baler.turnedOnTime = 0;
					
					self.realism.lastRealNeededPtoPower = self.realism.baler.basePowerUsage;
					self.powerConsumer.neededPtoPower = self.realism.baler.basePowerUsage;
					self.neededPtoPower = self.realism.baler.basePowerUsage;
				end;
			end;
		end;
		if self:getIsActive() then
		
	        if self:getIsTurnedOn() then
				
				-- area stuff, why?
	            if self.baler.lastAreaBiggerZero and self.fillUnits[self.baler.fillUnitIndex].lastValidFillType ~= FillUtil.FILLTYPE_UNKNOWN then
	                self.baler.lastAreaBiggerZeroTime = 500
	            else
	                if self.baler.lastAreaBiggerZeroTime > 0 then
	                    self.baler.lastAreaBiggerZeroTime = self.baler.lastAreaBiggerZeroTime - dt
	                end
	            end
	
				-- client only
	            if self.isClient then
					-- effects animations
	                if self.baler.fillEffects ~= nil then
	                    if self.baler.lastAreaBiggerZeroTime > 0 then
	                        EffectManager:setFillType(self.baler.fillEffects, self.fillUnits[self.baler.fillUnitIndex].lastValidFillType)
	                        EffectManager:startEffects(self.baler.fillEffects)
	                    else
	                        EffectManager:stopEffects(self.baler.fillEffects)
	                    end
	                end
					
					-- particle animations
	                local currentFillParticleSystem = self.baler.fillParticleSystems[self.fillUnits[self.baler.fillUnitIndex].lastValidFillType]
	                if currentFillParticleSystem ~= self.baler.currentFillParticleSystem then
	                    if self.baler.currentFillParticleSystem ~= nil then
	                        for _, ps in pairs(self.baler.currentFillParticleSystem) do
	                            ParticleUtil.setEmittingState(ps, false)
	                        end
	                        self.baler.currentFillParticleSystem = nil
	                    end
	                    self.baler.currentFillParticleSystem = currentFillParticleSystem
	                end
	
	                if self.baler.currentFillParticleSystem ~= nil then
	                    for _, ps in pairs(self.baler.currentFillParticleSystem) do
	                        ParticleUtil.setEmittingState(ps, self.baler.lastAreaBiggerZeroTime > 0)
	                    end
	                end
					
					-- sound stuff
	                if self:getIsActiveForSound() then
	                    if self.baler.knotCleaningTime <= g_currentMission.time then
	                        SoundUtil.playSample(self.baler.sampleBalerKnotCleaning, 1, 0, nil)
	                        self.baler.knotCleaningTime = g_currentMission.time + 120000
	                    end
	                    SoundUtil.playSample(self.baler.sampleBaler, 0, 0, nil)
	                end
	            end
	        else	
				-- unloading when turned off
	            if self.baler.isBaleUnloading and self.isServer then
	                local deltaTime = dt / self.baler.baleUnloadingTime
	                self:moveBales(deltaTime)
	            end
	        end
	
			-- more client stuff -> sound
	        if self.isClient then
	            if not self:getIsTurnedOn() then
	                SoundUtil.stopSample(self.baler.sampleBalerKnotCleaning)
	                SoundUtil.stopSample(self.baler.sampleBaler)
	            end
	
				-- beeping sound math stuff found here!!
	            if self:getIsTurnedOn() and self:getUnitFillLevel(self.baler.fillUnitIndex) > (self:getUnitCapacity(self.baler.fillUnitIndex) * 0.8) and self:getUnitFillLevel(self.baler.fillUnitIndex) < self:getUnitCapacity(self.baler.fillUnitIndex) then
	                -- start alarm sound
	                if self:getIsActiveForSound() then
	                    SoundUtil.playSample(self.baler.sampleBalerAlarm, 0, 0, nil)
	                end
					if self:getUnitFillLevel(self.baler.fillUnitIndex) > self.realism.baler.averageCapacity then
						SoundUtil.setSamplePitch(self.baler.sampleBalerAlarm, 1.6)
					end;
	            else
	                SoundUtil.stopSample(self.baler.sampleBalerAlarm)
					SoundUtil.setSamplePitch(self.baler.sampleBalerAlarm, 1)
	            end
	
	            --delete dummy bale on client after physical bale is displayed
	            if self.baler.unloadingState == Baler.UNLOADING_OPEN then
	                if getNumOfChildren(self.baler.baleAnimRoot) > 0 then
	                    delete(getChildAt(self.baler.baleAnimRoot, 0));
	                end;
	            end;
	        end;
	
			-- unloading 
	        if self.baler.unloadingState == Baler.UNLOADING_OPENING then
	            local isPlaying = self:getIsAnimationPlaying(self.baler.baleUnloadAnimationName)
	            local animTime = self:getRealAnimationTime(self.baler.baleUnloadAnimationName)
	            if not isPlaying or animTime >= self.baler.baleDropAnimTime then
	                if table.getn(self.baler.bales) > 0 then
	                    self:dropBale(1)
	                    if self.isServer then
	                        self:setUnitFillLevel(self.baler.fillUnitIndex, 0, self:getUnitFillType(self.baler.fillUnitIndex), true)
	                    end
	                end
	                if not isPlaying then
	                    self.baler.unloadingState = Baler.UNLOADING_OPEN
	
	                    if self.isClient then
	                        SoundUtil.stopSample(self.baler.sampleBalerEject)
	                        SoundUtil.stopSample(self.baler.sampleBalerDoor)
	                    end
	                end
	            end
	        elseif self.baler.unloadingState == Baler.UNLOADING_CLOSING then
	            if not self:getIsAnimationPlaying(self.baler.baleCloseAnimationName) then
	                self.baler.unloadingState = Baler.UNLOADING_CLOSED
	                if self.isClient then
	                    SoundUtil.stopSample(self.baler.sampleBalerDoor)
	                end
	            end
	        end
	    end	
	
	
	else
	
		oldBalerUpdateTick(self, dt);	
		
	end;

end;


-- nothing changed in this function, yet.
local oldBalerGetTimeFromLevel = Baler.getTimeFromLevel;
Baler.getTimeFromLevel = function(self, level)
	if self.isRealism2 then
	    -- level = capacity -> time = firstBaleMarker
	    -- level = 0           -> time = 0
	    if self.baler.firstBaleMarker ~= nil then
	    return level / self.realism.baler.averageCapacity * self.baler.firstBaleMarker
	    end
		return 0;
	else
		oldBalerGetTimeFromLevel(self, level)
	end;
end;


-- nothing changed in this function, yet.
local oldBalerSetBaleTime = Baler.setBaleTime;
Baler.setBaleTime = function(self, i, baleTime, noEventSend)
	if self.isRealism2 then
		if self.baler.baleAnimCurve ~= nil then
	        local bale = self.baler.bales[i]
	        bale.time = baleTime
	        if self.isServer then
	            local v = self.baler.baleAnimCurve:get(bale.time)
	            setTranslation(bale.baleJointNode, v[1], v[2], v[3])
	            setRotation(bale.baleJointNode, v[4], v[5], v[6])
	            if bale.baleJointIndex ~= 0 then
	                setJointFrame(bale.baleJointIndex, 0, bale.baleJointNode)
	            end
	        end
	        if bale.time >= 1 then
	            self:dropBale(i)
	        end
	        if table.getn(self.baler.bales) == 0 then
	            self.baler.isBaleUnloading = false
	        end
	        if self.isServer then
	            if noEventSend == nil or not noEventSend then
	                g_server:broadcastEvent(BalerSetBaleTimeEvent:new(self, i, bale.time), nil, nil, self)
	            end
	        end
	    end
	else
		oldBalerSetBaleTime(self, baleTime, noEventSend);
	end;
end;

local oldBalerDraw = Baler.draw;
Baler.draw = function(self)
	oldBalerDraw(self);
	
	if self.realism.baler.drawPowerUsage then
		renderText(0.84, 0.5, getCorrectTextSize(0.016), "Realism Baler Power:");
		renderText(0.84, 0.48, getCorrectTextSize(0.016), "total power: "..tostring(math.floor(self.realism.baler.lastPowerUsage)));
		renderText(0.84, 0.46, getCorrectTextSize(0.016), "total liters/S: "..tostring(math.floor(self.realism.baler.lastTotalLiters)));
	end;

end;


-- nothing changed in this function, yet.
local oldBalerSetUnitFillLevel = Baler.setUnitFillLevel;
Baler.setUnitFillLevel = function(self, fillUnitIndex, fillLevel, fillType, force, fillInfo)
	if self.isRealism2 then
		if self.realism.baler.doStroke then
			if fillUnitIndex == self.baler.fillUnitIndex then
				if self.baler.dummyBale.baleNode ~= nil and fillLevel > 0 and fillLevel < self:getUnitCapacity(fillUnitIndex) and (self.baler.dummyBale.currentBale == nil or self.baler.dummyBale.currentBaleFillType ~= fillType) then
					if self.baler.dummyBale.currentBale ~= nil then
						delete(self.baler.dummyBale.currentBale)
						self.baler.dummyBale.currentBale = nil
					end
					local t = self.baler.baleTypes[self.baler.currentBaleTypeId]
		
					local baleType = BaleUtil.getBale(fillType, t.width, t.height, t.length, t.diameter, t.isRoundBale)
		
					local baleRoot = Utils.loadSharedI3DFile(baleType.filename, self.baseDirectory, false, false)
					local baleId = getChildAt(baleRoot, 0)
					setRigidBodyType(baleId, "NoRigidBody")
					link(self.baler.dummyBale.baleNode, baleId)
					delete(baleRoot)
					self.baler.dummyBale.currentBale = baleId
					self.baler.dummyBale.currentBaleFillType = fillType
				end
		
				if self.baler.dummyBale.currentBale ~= nil then
					local percent = fillLevel / self:getUnitCapacity(fillUnitIndex)
					local y = 1
					if getUserAttribute(self.baler.dummyBale.currentBale, "isRoundbale") then
						y = percent
					end
					setScale(self.baler.dummyBale.scaleNode, 1, y, percent)
				end
			end
		end;
	else
		oldBalerSetUnitFillLevel(self, fillUnitIndex, fillLevel, fillType, force, fillInfo)
	end;
	
end;




























