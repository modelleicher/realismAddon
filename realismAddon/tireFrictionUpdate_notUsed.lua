-- by modelleicher
-- 
--

tireFrictionUpdate = {};

tireFrictionUpdate.GLOBALS = {};
tireFrictionUpdate.GLOBALS.overallTireFrictionModifier = 0.92; -- change this to change overall tire friction 



--tireFrictionUpdate.GLOBALS.fieldTireFrictionModifier = 0.71; -- change this to change tire friction value in fields only

function tireFrictionUpdate.prerequisitesPresent(specializations)
    return true;
end

function tireFrictionUpdate:preLoad(savegame)
end

function tireFrictionUpdate:load(savegame)

    self.tireFrictionUpdate = {};
    self.tireFrictionUpdate.isActive = self.wheels ~= nil and table.getn(self.wheels) > 0;

	for _, wheel in pairs(self.wheels) do
		wheel.origFrictionScale = wheel.frictionScale; -- backup the orig. value
		wheel.frictionScale = wheel.frictionScale*tireFrictionUpdate.GLOBALS.overallTireFrictionModifier;
		--wheel.oldFrictionScale = wheel.frictionScale
		--wheel.fieldFrictionScale = wheel.frictionScale * tireFrictionUpdate.GLOBALS.fieldTireFrictionModifier;
	end;
end


function tireFrictionUpdate:delete()
end

function tireFrictionUpdate:mouseEvent(posX, posY, isDown, isUp, button)
end

function tireFrictionUpdate:keyEvent(unicode, sym, modifier, isDown)
end

function tireFrictionUpdate:update(dt)
    --if not self.tireFrictionUpdate.isActive then
   --     return;
    --end

--    if self:getIsActive() then
		--for _, wheel in pairs(self.wheels) do
			-- if tire is on field, lower friction
			--if wheel.contact == Vehicle.WHEEL_GROUND_CONTACT and wheel.hasTireTracks then
			--	local wx, wy, wz = wheel.netInfo.x, wheel.netInfo.y, wheel.netInfo.z;
			--	wy = wy - wheel.radius;
			--	wx = wx + wheel.xOffset;
			--	wx, wy, wz = localToWorld(wheel.node, wx,wy,wz);
				
			--	local densityBits = getDensityAtWorldPos(g_currentMission.terrainDetailId, wx, wy, wz);
				
				--renderText(0.1, 0.1, 0.03, tostring(densityBits));
				
			--	if densityBits ~= 0 then
			--		wheel.frictionScale = wheel.fieldFrictionScale;
			--	else
			--		wheel.frictionScale = wheel.oldFrictionScale;
			--	end;
		
			--end
		--end
	--end;
end


function tireFrictionUpdate:updateTick(dt)
end

function tireFrictionUpdate:draw()
end




