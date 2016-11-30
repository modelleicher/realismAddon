-- by modelleicher
-- www.schwabenmodding.de
--
-- this spec contains all modifications or updates that are not for one particular type of vehicles but everything that uses vehicle.lua
-- this is only a specialization, if possible no functions will be overwritten within it. For that we have realismUpdate_ scripts.
-- (This is just to keep things easy to understand and find in case of bugs)


realismSpec_generalVehicleUpdates = {};



--realismSpec_generalVehicleUpdates.GLOBALS.fieldTireFrictionModifier = 0.71; -- change this to change tire friction value in fields only

function realismSpec_generalVehicleUpdates.prerequisitesPresent(specializations)
    return true;
end

function realismSpec_generalVehicleUpdates:preLoad(savegame)
end

function realismSpec_generalVehicleUpdates:load(savegame)
	local val = getXMLFloat(g_realism.realismXMLConfigFile, "realismUpdateConfig.globalSettings.overallTireFrictionModifier#value");
	print("val: "..tostring(val));
	local overallTireFrictionModifier = Utils.getNoNil(getXMLFloat(g_realism.realismXMLConfigFile, "realismUpdateConfig.globalSettings.overallTireFrictionModifier#value"),0.92); -- changes the overall tire friction 


	-- lower tire friction according to global modifier. 
    if self.wheels ~= nil and table.getn(self.wheels) > 0 then
		for _, wheel in pairs(self.wheels) do
			wheel.origFrictionScale = wheel.frictionScale; -- backup the orig. value
			wheel.frictionScale = wheel.frictionScale*overallTireFrictionModifier;
			--wheel.oldFrictionScale = wheel.frictionScale
			--wheel.fieldFrictionScale = wheel.frictionScale * realismSpec_generalVehicleUpdates.GLOBALS.fieldTireFrictionModifier;
		end;
	end;	
end


function realismSpec_generalVehicleUpdates:delete()
end

function realismSpec_generalVehicleUpdates:mouseEvent(posX, posY, isDown, isUp, button)
end

function realismSpec_generalVehicleUpdates:keyEvent(unicode, sym, modifier, isDown)
end

function realismSpec_generalVehicleUpdates:update(dt)
    --if not self.realismSpec_generalVehicleUpdates.isActive then
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


function realismSpec_generalVehicleUpdates:updateTick(dt)
end

function realismSpec_generalVehicleUpdates:draw()
end




