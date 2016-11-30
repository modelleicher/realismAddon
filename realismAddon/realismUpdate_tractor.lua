-- by modelleicher
-- 
--


--DebugUtil.printTableRecursively(SoundUtil, "." , 0, 1);



if g_realism == nil then
	g_realism = {};
end;

g_realism.globalRealismDebug = false;
g_realism.IMPLEMENT_FORCE_NODE_TYPE_ATTACHER = 0;


local oldSteerableLoad = Steerable.postLoad;
Steerable.postLoad = function(self, savegame)
	print("realismUpdate_tractor load init");
	
	-- create table if not already exists in this vehicle
	if self.realism == nil then
		self.realism = {};
	end;
	
	-- diff function (maybe move this to motorized if realismUpdate_motorized ever exists)
	self.newUpdateDifferentials = Steerable.newUpdateDifferentials;
	
	-- implement force nodes, nodes for implements to add additional forces to the tractor
	self.realism.implementForceNodes = {};
	
	--DebugUtil.printTableRecursively(table inputTable, string inputIndent, integer depth, integer maxDepth)

	-- DebugUtil.printTableRecursively(self, "." , 0, 0);

	--print(tostring(self.attacherJoints))
	local i = 0;
	for _, attacher in pairs(self.attacherJoints) do
		local arm = attacher.rotationNode;
		if arm ~= nil then
			
			local forceNode = {};
			forceNode.posX, forceNode.posY, forceNode.posZ = getTranslation(arm);
			forceNode.type = g_realism.IMPLEMENT_FORCE_NODE_TYPE_ATTACHER;
			forceNode.parent = getParent(arm);
			--forceNode.jointIndex = attacher.jointIndex;
			forceNode.forceNodeIndex = i;
			attacher.forceNodeIndex = i;
			table.insert(self.realism.implementForceNodes, forceNode);
			
		end;
		i = i+1;
	end;
	

	if self.wheels ~= nil and table.maxn(self.wheels) == 4 then -- check if we have basic 4 wheel configuration
		if table.maxn(self.differentials) == 3 then -- check if we have basic differential configuration
		
			
			self.realism.awdOn = false;
			self.realism.lockedOn = false;
	
		
			if self.differentials[1].diffIndex1IsWheel then -- check if first diff is between wheels
				self.differentials[1].r_isWheelDiff = true;
				self.differentials[1].torqueRatio = 0.5;
				self.differentials[1].maxSpeedRatio = 200;
				self.differentials[1].r_lockedTorqueRatio = 0.5;
				self.differentials[1].r_lockedMaxSpeedRatio = 0.0;
			else -- if not, it is diff between axles
				self.differentials[1].r_isWheelDiff = false;
				self.differentials[1].torqueRatio = 0.0;
				self.differentials[1].maxSpeedRatio = 1.2;
				self.differentials[1].r_awdTorqueRatio = 0.5;
				self.differentials[1].r_awdMaxSpeedRatio = 1.2;
			end;
			if self.differentials[2].diffIndex1IsWheel then -- check if second diff is between wheels
				self.differentials[2].r_isWheelDiff = true;
				self.differentials[2].torqueRatio = 0.5;
				self.differentials[2].maxSpeedRatio = 200;
				self.differentials[2].r_lockedTorqueRatio = 0.5;
				self.differentials[2].r_lockedMaxSpeedRatio = 0.0;
			else -- if not, it is diff between axles
				self.differentials[2].r_isWheelDiff = false;
				self.differentials[2].torqueRatio = 0.0;
				self.differentials[2].maxSpeedRatio = 1.2;
				self.differentials[2].r_awdTorqueRatio = 0.5;
				self.differentials[2].r_awdMaxSpeedRatio = 1.2;				
			end;
			if self.differentials[3].diffIndex1IsWheel then -- check if third diff is between wheels
				self.differentials[3].isWheelDiff = true;
				self.differentials[3].torqueRatio = 0.5;
				self.differentials[3].maxSpeedRatio = 200;		
				self.differentials[3].r_lockedTorqueRatio = 0.5;
				self.differentials[3].r_lockedMaxSpeedRatio = 0.0;				
			else -- if not, it is diff between axles
				self.differentials[3].r_isWheelDiff = false;
				self.differentials[3].torqueRatio = 0.0;
				self.differentials[3].maxSpeedRatio = 1.2;
				self.differentials[3].r_awdTorqueRatio = 0.5;
				self.differentials[3].r_awdMaxSpeedRatio = 1.2;
			end;
			
			self.realism.differentialsBackup = self.differentials;
		end;
	end;
	
	self:newUpdateDifferentials(false);
	
	oldSteerableLoad(self, savegame);
	
end;

Steerable.newUpdateDifferentials = function(self, fourWDState, locked)
	
	if self.realism.awdOn ~= nil or self.realism.lockedOn ~= nil then
		removeAllDifferentials(self.motorizedNode); -- since updating diffs is buggy.. remove them all, add them again.
		for i=1, 3 do -- go through diffs and add them one by one again
			local dB = self.realism.differentialsBackup[i];
			local tr = 0.0;
			local msr = 0.0;
			if not self.differentials[i].r_isWheelDiff then -- if its axle diff.. engage/disengage 4WD
				if fourWDState then
					
					self.differentials[i].torqueRatio = 0.5 --self.differentials[i].r_awdTorqueRatio;
					self.differentials[i].maxSpeedRatio = 1.2 --self.differentials[i].r_awdMaxSpeedRatio;

				else
					
					self.differentials[i].torqueRatio = 0.0 --dB.torqueRatio;
					self.differentials[i].maxSpeedRatio = 1.2 -- dB.maxSpeedRatio;

				end;
			elseif self.differentials[i].r_isWheelDiff then -- if its wheel diff.. engage/disengage lock
				if locked then
					self.differentials[i].torqueRatio = 0.5 -- self.differentials[i].r_lockedTorqueRatio;
					self.differentials[i].maxSpeedRatio = 0.0 -- self.differentials[i].r_lockedMaxSpeedRatio;
				else
					self.differentials[i].torqueRatio = 0.5 --dB.torqueRatio;
					self.differentials[i].maxSpeedRatio = 200 --dB.maxSpeedRatio;
				end;
			end;
			local d = self.differentials[i];
			addDifferential(self.motorizedNode, d.diffIndex1IsWheel and self.wheels[d.diffIndex1].wheelShape or d.diffIndex1, d.diffIndex1IsWheel,d.diffIndex2IsWheel and self.wheels[d.diffIndex2].wheelShape or d.diffIndex2, d.diffIndex2IsWheel, d.torqueRatio, d.maxSpeedRatio);
		end;
		
		self.realism.awdOn = fourWDState;
		self.realism.lockedOn = locked;
	end;
	-- TO DO => Send Event
end;

local oldSteerableUpdate = Steerable.update;
Steerable.update = function(self, dt)
	oldSteerableUpdate(self, dt);
	
	if self:getIsActive() and self.isEntered then
		if self.realism.awdOn then
			renderText(0.84, 0.21, getCorrectTextSize(0.015), "AWD on");
		else
			renderText(0.84, 0.21, getCorrectTextSize(0.015), "AWD off");
		end;
		if self.realism.lockedOn then
			renderText(0.89, 0.21, getCorrectTextSize(0.015), "Lock on");
		else
			renderText(0.89, 0.21, getCorrectTextSize(0.015), "Lock off");
		end;	
		
		if InputBinding.hasEvent(InputBinding.R_4WD) then
			self:newUpdateDifferentials(not self.realism.awdOn, self.realism.lockedOn);
		end;
		if InputBinding.hasEvent(InputBinding.R_DIFFLOCK) then
			self:newUpdateDifferentials(self.realism.awdOn, not self.realism.lockedOn);
		end;	
	end;
end;



local oldSteerableDraw = Steerable.draw;
Steerable.draw = function(self)
	if g_realism.globalRealismDebug then
		for _, forceNode in pairs(self.realism.implementForceNodes) do
			local x, y, z = localToWorld(forceNode.parent, forceNode.posX, forceNode.posY, forceNode.posZ )
			drawDebugLine(x, y, z, 1, 0, 0, x+1, y, z, 1, 0, 0);
			drawDebugLine(x, y, z, 0, 1, 0, x, y+1, z, 0, 1, 0);
			drawDebugLine(x, y, z, 0, 0, 1, x, y, z+1, 0, 0, 1);
		end;	
	end;
	
	oldSteerableDraw(self);
end;







--[[
if self.realism.awdOn then
				local diff = self.realism.differentialsOld[1];
				removeAllDifferentials(self.motorizedNode);
				addDifferential(self.motorizedNode, diff.diffIndex1IsWheel and self.wheels[diff.diffIndex1].wheelShape or diff.diffIndex1, diff.diffIndex1IsWheel,diff.diffIndex2IsWheel and self.wheels[diff.diffIndex2].wheelShape or diff.diffIndex2, diff.diffIndex2IsWheel, 0.5, 200);
				local diff = self.realism.differentialsOld[2];
				addDifferential(self.motorizedNode, diff.diffIndex1IsWheel and self.wheels[diff.diffIndex1].wheelShape or diff.diffIndex1, diff.diffIndex1IsWheel,diff.diffIndex2IsWheel and self.wheels[diff.diffIndex2].wheelShape or diff.diffIndex2, diff.diffIndex2IsWheel, 0.5, 200);
				local diff = self.realism.differentialsOld[3];
				addDifferential(self.motorizedNode, diff.diffIndex1IsWheel and self.wheels[diff.diffIndex1].wheelShape or diff.diffIndex1, diff.diffIndex1IsWheel,diff.diffIndex2IsWheel and self.wheels[diff.diffIndex2].wheelShape or diff.diffIndex2, diff.diffIndex2IsWheel, 0.5, 200);
			else
				local diff = self.realism.differentialsOld[1];
				removeAllDifferentials(self.motorizedNode);
				addDifferential(self.motorizedNode, diff.diffIndex1IsWheel and self.wheels[diff.diffIndex1].wheelShape or diff.diffIndex1, diff.diffIndex1IsWheel,diff.diffIndex2IsWheel and self.wheels[diff.diffIndex2].wheelShape or diff.diffIndex2, diff.diffIndex2IsWheel, 0.5, 200);		
				local diff = self.realism.differentialsOld[2];
				addDifferential(self.motorizedNode, diff.diffIndex1IsWheel and self.wheels[diff.diffIndex1].wheelShape or diff.diffIndex1, diff.diffIndex1IsWheel,diff.diffIndex2IsWheel and self.wheels[diff.diffIndex2].wheelShape or diff.diffIndex2, diff.diffIndex2IsWheel, 0.5, 200);
				local diff = self.realism.differentialsOld[3];
				addDifferential(self.motorizedNode, diff.diffIndex1IsWheel and self.wheels[diff.diffIndex1].wheelShape or diff.diffIndex1, diff.diffIndex1IsWheel,diff.diffIndex2IsWheel and self.wheels[diff.diffIndex2].wheelShape or diff.diffIndex2, diff.diffIndex2IsWheel, 0.0, 200);
			end;
]]--






















