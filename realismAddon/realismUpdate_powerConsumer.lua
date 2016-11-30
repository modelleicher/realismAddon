-- by modelleicher
-- www.schwabenmodding.de
--

-- initialize global realism table if not exists already (do this in each realism script)
if g_realism == nil then
	g_realism = {};
end;

--DebugUtil.printTableRecursively(SoundUtil, "---" , 0, 1);


-- overwriting the powerConsumer load function with our own
local oldPowerConsumerLoad = PowerConsumer.load;
PowerConsumer.load = function(self, savegame)

	print("power consumer load called on mod "..tostring(self.configFileName));
	self.isRealism = r_getXMLBool(self, "realism#useRealism"); -- check if mod uses realism
	print(tostring(self.isRealism));
	if self.isRealism == nil or self.isRealism == false or self.realism3 then -- isRealism is enough, realism2 and realism3 is for baler debugging only.. 
		oldPowerConsumerLoad(self, savegame); -- use old function if realism isn't used in this mod
	else
		if self.realism == nil then -- initialize self.realism table if not already exists
			self.realism = {};
		end;
		print("isRealism");
		-- old power consumer
		if self.powerConsumer == nil then
			self.powerConsumer = {};
		end;
		
		-- new power consumer
		self.realism.pc = {};
		self.realism.pc.totalMass = self:getTotalMass(false);
		self.realism.pc.workingWidth = Utils.getNoNil(r_getXMLFloat(self, "realism.powerConsumer#workingWidth"), 1); -- working width and depth in meters
		self.realism.pc.workingDepth = Utils.getNoNil(r_getXMLFloat(self, "realism.powerConsumer#workingDepth"), 1);
		self.realism.pc.staticForceFactor = Utils.getNoNil(r_getXMLFloat(self, "realism.powerConsumer#staticForceFactor"), 1); -- static force as soon as lowered
		self.realism.pc.dynamicForceFactor = Utils.getNoNil(r_getXMLFloat(self, "realism.powerConsumer#dynamicForceFactor"), 1); -- dynamic force 0 when standing still, increases with speed
		
		self.realism.pc.forceNode = Utils.indexToObject(self.components, r_getXMLString(self, "realism.powerConsumer#forceNode"));
		self.realism.pc.forceDir = Utils.getNoNil(r_getXMLFloat(self, "realism.powerConsumer#forceDir"), 1);
		
		self.realism.pc.staticWeightFactor = Utils.getNoNil(r_getXMLFloat(self, "realism.powerConsumer#staticWeightFactor"), 1);
		self.realism.pc.dynamicWeightFactor = Utils.getNoNil(r_getXMLFloat(self, "realism.powerConsumer#dynamicWeightFactor"), 1);
		
		self.realism.pc.groundResistance = 1;
		
		self.realism.pc.currentTractorForceNode = nil;
		
		self.realism.pc.ptoRpm = Utils.getNoNil(r_getXMLFloat(self, "realism.powerConsumer#ptoRpm"), 0);
		self.realism.pc.neededPtoPower = Utils.getNoNil(r_getXMLFloat(self, "realism.powerConsumer#ptoRpm"), 0);
		
		self.powerConsumer.ptoRpm = self.realism.pc.ptoRpm;
		self.powerConsumer.neededPtoPower = self.realism.pc.neededPtoPower;
		self.realism.lastRealNeededPtoPower = 0;
		print("Realism Power Consumer Init"); -- debug
		
		if self.realism2 then -- baler still run on old load function.. to do.
			oldPowerConsumerLoad(self, savegame);
		end;
	end;
end;

-- overwrite the powerConsumer update function
local oldPowerConsumerUpdate = PowerConsumer.update;
PowerConsumer.update = function(self, dt)
	if self.isRealism == nil or self.isRealism == false or self.realism3 then
		oldPowerConsumerUpdate(self, dt); -- old func if realism isn't used
	else
		if self:getIsActive() and self.isServer then
			
			-- get friction force
			if self.realism.pc.forceNode ~= nil and self.ploughHasGroundContact or self.cultivatorHasGroundContact or self.sowingMachineHasGroundContact then
				local pc = self.realism.pc
				local force = (pc.workingWidth * pc.workingDepth*2) * pc.groundResistance * pc.staticForceFactor + ((self:getLastSpeed()^2) * pc.workingWidth * pc.workingDepth * pc.dynamicForceFactor);
				local dx,dy,dz = localDirectionToWorld(self.realism.pc.forceNode, 0, 0, -force);
				local px,py,pz = getCenterOfMass(self.realism.pc.forceNode);
				addForce(self.realism.pc.forceNode, dx,dy,dz, px,py,pz, true);
				
				if Vehicle.debugRendering and self:getIsActiveForInput() then
					renderText(0.3, 0.4, getCorrectTextSize(0.02), "Realism Power Consumer:");
					--renderText(0.01, 0.775, getCorrectTextSize(0.02), "force = workingWidth * workingDepth * groundResistance * staticForceFactor + lastSpeed ^ 2 * workingWidth * workingDepth * dynamicForceFactor");
					renderText(0.02, 0.35, getCorrectTextSize(0.02), tostring(force).." = "..tostring(pc.workingWidth).." * "..tostring(pc.workingDepth).." * "..tostring(pc.groundResistance).." * "..tostring(pc.staticForceFactor).." + ("..tostring(self:getLastSpeed()).."^2 * "..tostring(pc.workingWidth).." * "..tostring(pc.workingDepth).." * "..tostring(pc.dynamicForceFactor)..")")
					renderText(0.02, 0.325, getCorrectTextSize(0.02), "dx dy dz = "..tostring(dx).."-"..tostring(dy)..tostring(dz));
				end;
			end;
			
			-- get dynamic load on tractor
			if self.attacherVehicle ~= nil and self.attacherVehicle.realism ~= nil then
				if self.ploughHasGroundContact or self.cultivatorHasGroundContact or self.sowingMachineHasGroundContact and self.realism.pc.currentTractorForceNode ~= nil then
					-- 
					local forceNode = self.realism.pc.currentTractorForceNode;
					local pc = self.realism.pc;
					local downForce = pc.totalMass * pc.staticWeightFactor + self:getLastSpeed()^2 * pc.totalMass * pc.dynamicWeightFactor;
					
					local a, b, c = localToWorld(forceNode.parent, forceNode.posX, forceNode.posY, forceNode.posZ);
					a, b, c = worldToLocal(self.attacherVehicle.rootNode, a, b, c);
					addForce(self.attacherVehicle.rootNode, 0, -downForce, 0, a, b, c, true);
					
					if Vehicle.debugRendering and self:getIsActiveForInput() then
						renderText(0.22, 0.3, getCorrectTextSize(0.02), "Downforce: "..tostring(downForce));
					end;
						
				end;
			end;
		end;
	end;
end;

--local oldGetConsumedPtoTorque = PowerConsumer.getConsumedPtoTorque;
--PowerConsumer.getConsumedPtoTorque = function(self)
	--if self.isRealism2 then
	--	if self:getDoConsumePtoPower() then
	--        local rpm = self.realism.pc.ptoRpm;
	--        if rpm > 0.001 then
	--			local power = self.realism.pc.neededPtoPower + self.realism.lastRealNeededPtoPower;
	--            return power / (rpm*math.pi/30);
	--        end
	--    end
	--    return 0;
	--else
		--oldGetConsumedPtoTorque(self);
	--end;
--end;

-- add onAttached function to power consumer. Used to get the force nodes for downforce adding
PowerConsumer.onAttached = function(self, attacherVehicle, implement)
	if self.isRealism then
		local attacher = attacherVehicle.attacherJoints[implement.jointDescIndex];
		
		if attacherVehicle.realism ~= nil and attacherVehicle.realism.implementForceNodes ~= nil then -- tractor uses realism and has forceNodes (every tractor should have since its global)
			for _, forceNode in pairs(attacherVehicle.realism.implementForceNodes) do
				if forceNode.forceNodeIndex == attacher.forceNodeIndex then -- found right attacher - force node combination
					self.realism.pc.currentTractorForceNode = forceNode;
				end;
			end;
		end;
	end;
end;

-- add onDetach function to powerConsumer
PowerConsumer.onDetach = function(self, attacherVehicle, jointDescIndex)
	if self.isRealism then
		self.realism.pc.currentTractorForceNode = nil; -- remove current force node when implement is detached.
	end;
end;























