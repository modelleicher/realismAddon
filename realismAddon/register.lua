-- by modelleicher
--



RegistrationHelper_StuffAndThings = {};
RegistrationHelper_StuffAndThings.isLoaded = false;

if SpecializationUtil.specializations['tireFrictionUpdate'] == nil then
   -- SpecializationUtil.registerSpecialization('tireFrictionUpdate', 'tireFrictionUpdate', g_currentModDirectory .. 'tireFrictionUpdate.lua')
    RegistrationHelper_StuffAndThings.isLoaded = false;
end


function RegistrationHelper_StuffAndThings:loadMap(name)
    if not g_currentMission.RegistrationHelper_StuffAndThings_isLoaded then
        if not RegistrationHelper_StuffAndThings.isLoaded then
            self:register();
        end
        g_currentMission.RegistrationHelper_StuffAndThings_isLoaded = true
    else
        print("Error: tireFrictionUpdate has been loaded already!");
    end
end

function RegistrationHelper_StuffAndThings:deleteMap()
    g_currentMission.RegistrationHelper_StuffAndThings_isLoaded = nil
end

function RegistrationHelper_StuffAndThings:keyEvent(unicode, sym, modifier, isDown)
end

function RegistrationHelper_StuffAndThings:mouseEvent(posX, posY, isDown, isUp, button)
end

function RegistrationHelper_StuffAndThings:update(dt)
end

function RegistrationHelper_StuffAndThings:draw()
end

function RegistrationHelper_StuffAndThings:register()
    for _, vehicle in pairs(VehicleTypeUtil.vehicleTypes) do
        if vehicle ~= nil then
          --  table.insert(vehicle.specializations, SpecializationUtil.getSpecialization("tireFrictionUpdate"))
           -- table.insert(vehicle.specializations, SpecializationUtil.getSpecialization("realismUpdate_plough"))
			
			
		--	for i = 1, table.maxn(vehicle.specializations) do
		--		local vs = vehicle.specializations[i];
		--		if vs ~= nil and vs == SpecializationUtil.getSpecialization("plough") then				
		--			table.insert(vehicle.specializations, SpecializationUtil.getSpecialization("realismUpdate_plough"));
		--			print("realismUpdate_plough inserted to "..tostring(vehicle));
		--		end;
		--	end;			
        end
    end
    RegistrationHelper_StuffAndThings.isLoaded = true
end

addModEventListener(RegistrationHelper_StuffAndThings)