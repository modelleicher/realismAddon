-- by modelleicher
-- 
--
if g_realism == nil then
	g_realism = {};
end;

-- mod folder path:
local modFolderPath = g_modsDirectory
	
-- check if config file exists
local configFile = modFolderPath.."realismUpdateConfig.xml";
print("realism_update: config file path: "..tostring(configFile));
if fileExists(configFile) then
	local xmlFile = loadXMLFile( "realismUpdateConfig", configFile);
	g_realism.realismXMLConfigFile = xmlFile; -- config file globally loaded
	print("realism_update: config file found and loaded.");
else
	print("realism_update: did not find config file at given path.");
end;


local oldVehicleLoad = Vehicle.load;
Vehicle.load = function(self, vehicleData, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)

	--oldVehicleLoad(self, vehicleData, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	
	
	-- -- -- -- -- --
	--   GIANTS    --
	local modName, baseDirectory = Utils.getModNameAndBaseDirectory(vehicleData.filename);
	
	self.configFileName = vehicleData.filename;
	self.baseDirectory = baseDirectory;
	self.customEnvironment = modName;
	self.typeName = vehicleData.typeName;
	self.isVehicleSaved = Utils.getNoNil(vehicleData.isVehicleSaved, true);
	self.configurations = Utils.getNoNil(vehicleData.configurations, {});
	self.boughtConfigurations = Utils.getNoNil(vehicleData.boughtConfigurations, {});
	local typeDef = VehicleTypeUtil.vehicleTypes[self.typeName];
	self.specializations = typeDef.specializations;
	self.specializationNames = typeDef.specializationNames;
	self.xmlFile = loadXMLFile("TempConfig", vehicleData.filename);
	self.isAddedToPhysics = false

	local data = {};
	data[1] = {posX=vehicleData.posX, posY=vehicleData.posY, posZ=vehicleData.posZ, yOffset=vehicleData.yOffset, isAbsolute=vehicleData.isAbsolute};
	data[2] = {rotX=vehicleData.rotX, rotY=vehicleData.rotY, rotZ=vehicleData.rotZ};
	data[3] = vehicleData.isVehicleSaved;
	data[4] = vehicleData.propertyState;
	data[5] = vehicleData.price;
	data[6] = vehicleData.savegame;
	data[7] = asyncCallbackFunction;
	data[8] = asyncCallbackObject;
	data[9] = asyncCallbackArguments;

	for i=1, table.getn(self.specializations) do
		if self.specializations[i].preLoad ~= nil then
			local vehicleLoadState = self.specializations[i].preLoad(self, vehicleData.savegame);
			if vehicleLoadState ~= nil and vehicleLoadState ~= BaseMission.VEHICLE_LOAD_OK then
				print("Error: " .. self.specializationNames[i] .. "-specialization 'preLoad' failed");
				if asyncCallbackFunction ~= nil then
					asyncCallbackFunction(asyncCallbackObject, nil, vehicleLoadState, asyncCallbackArguments);
				end;
				return vehicleLoadState;
			end;
		end;
	end;
	-- GIANTS END  --
	-- -- -- -- -- --
	
	-- create realism table if not already exists.. (do this in every realism spec)
	if self.realism == nil then
		self.realism = {};
	end;
	
	print("DEBUG");
	print("...............................");
	print("self.configFileName = "..tostring(self.configFileName));
	print("self.baseDirectory = "..tostring(self.baseDirectory));
	print("self.customEnvironment = "..tostring(self.customEnvironment));
	print("self.typeName = "..tostring(self.typeName));
	
	-- get xml file name from complete path (data/vehicles/steerable/tractor.xml => tractor.xml)
	local localStrings = Utils.splitString("/" , self.configFileName);
	local xmlNameOnly = localStrings[table.maxn(localStrings)];
	
	
	print("xmlName = "..tostring(xmlNameOnly));
	print("DEBUG - - END");
	
	
	-- check if config file is loaded
	if g_realism.realismXMLConfigFile ~= nil then
		local xml = g_realism.realismXMLConfigFile;
		-- check if current vehicle is in config file
		local hasConfigs = false;
		local configIndex = nil;
		local i = 0;
		while true do
			local zipName = getXMLString(xml, "realismUpdateConfig.vehicle("..i..")#zipName");
			local xmlName = getXMLString(xml, "realismUpdateConfig.vehicle("..i..")#xmlName");
			if zipName ~= nil and zipName ~= "" then 
				if zipName == self.customEnvironment then 
					-- found current mod now check for right XML
					if xmlName == xmlNameOnly then -- found the right xml, too
						hasConfigs = true;
						configIndex = i;
						-- do the thing!!!
						print("found mod "..zipName.." with xml "..xmlName.." in config file at intex "..tostring(configIndex));
						break;
			
					end;
				elseif zipName == "baseGame" then -- base game vehicle doesn't have a zip name
					if xmlName == self.configFileName then 
						-- found current base vehicle
						hasConfigs = true;
						configIndex = i;
						-- do the thing!!!
						print("found base game vehicle with xml "..xmlName.." in config file at intex "..tostring(configIndex));
						break;
					end;
				end;
			else 
				break;
			end;
	
			i = i+1;
		end;
		
		if hasConfigs then
		
			-- the replacing of existing xml values.. (or setting new ones in the original xml file)
			local i2 = 0;
			while true do
				local path = "realismUpdateConfig.vehicle("..configIndex..").overrideValue("..i2..")";
				if hasXMLProperty(xml, path) then --
					local replaceType = getXMLString(xml, path.."#valueType");
					local replacePath = getXMLString(xml, path.."#path");
					if replaceType == "string" then
						setXMLString(self.xmlFile, replacePath, getXMLString(xml, path.."#value"));
					elseif replaceType == "bool" then
						setXMLBool(self.xmlFile, replacePath, getXMLBool(xml, path.."#value"));
					elseif replaceType == "int" then
						setXMLInt(self.xmlFile, replacePath, getXMLInt(xml, path.."#value"));
					elseif replaceType == "float" then
						setXMLFloat(self.xmlFile, replacePath, getXMLFloat(xml, path.."#value"));
					end;
						
				else
					break;
				end;
				i2 = i2 + 1;
			end;
			
			-- set up the variables needed to get the xml values later
			self.realism.configXML = xml;
			self.realism.configXMLIndex = configIndex;
			print(tostring(self.realism.configXML).."<= config xml");
			print(tostring(self.realism.configXMLIndex).."<= config xml index");
			
		end;
		
	end;

	
	-- -- -- -- -- --
	--   GIANTS    --
	self.i3dFilename = getXMLString(self.xmlFile, "vehicle.filename");

	if asyncCallbackFunction ~= nil then
		Utils.loadSharedI3DFile(self.i3dFilename, baseDirectory, true, false, true, self.loadFinished, self, data);
	else
		local i3dNode = Utils.loadSharedI3DFile(self.i3dFilename, baseDirectory, true, false, true);
		return self:loadFinished(i3dNode, data)
	end
	-- GIANTS END  --
	-- -- -- -- -- --
end;


-- xml file setup:
--[[

<realismUpdateConfig>
		
	<vehicle zipName="FS17_myMod" xmlName="myXml.xml" >
		
		<realism>
			
		</realism>
		
		<overrideValue path="vehicle.testpath#valueName" value="10" valueType="bool" />
	
	
	</vehicle>



</realismUpdateConfig>





]]--






























