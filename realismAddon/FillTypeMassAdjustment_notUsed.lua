-- by modelleicher
-- www.schwabenmodding.de
-- Version 4 (FS17 conversion)
-- added real individual masses for each filltype
-- now FS17 ready! :) 

FillTypeMassAdjustment = {};

function FillTypeMassAdjustment:loadMap(name)
	print("- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ")
	print("FillType Mass Adjustment FS17 by modelleicher loaded. Visit www.schwabenmodding.de for more Mods and Support");
	print("............................................................................................................")
	-- all new mass values according to real values:
	local realMass = {};
	realMass.potato = 0.000730 -- potatos around 720kg to 740kg per m³
	realMass.sugarBeet = 0.000740 -- sugar beet around 740kg per m³
	realMass.chaff = 0.000460  -- chaff between 350kg and 700kg per m³ depending on how dry, so we use a value in between
	realMass.dryGrass = 0.000070 -- between 70kg and 170kg (baled)
	realMass.dryGrass_windrow = 0.000070 -- same as dryGrass i guess..
	realMass.maize = 0.000800 -- 800kg per m³ of corn
	realMass.silage = 0.000700 -- 700kg per m³ of maize silage, grass a bit ligher.. Not sure on this value.
	realMass.barley_windrow = 0.000040 -- 40kg per m³
	realMass.wheat_windrow = 0.000040 -- 40kg per m³
	realMass.manure = 0.000790 -- between 600kg and even 850kg in extreme situations for 1m³ of manure
	realMass.liquidManure = 0.000980 -- between 950m³ and over 1000kg per m³
	realMass.rape = 0.000720 -- 700kg to 750kg says google
	realMass.wheat = 0.000790 -- 710kg to 820kg says google
	realMass.barley = 0.000630 -- 580kg to 780kg says google
	realMass.water = 0.001000 -- well thats easy :D 
	realMass.fuel = 0.000840 -- 1m³ diesel has a mass of 840kg
	realMass.grass = 0.000350 -- 350kg per 1m³ of fresh cut grass
	realMass.grass_windrow = 0.000350 -- same as grass 
	
	realMass.forage = 0.000320 -- not sure about this one
	realMass.forage_mixing = 0.000310 -- not sure about this one either
	
	realMass.milk = 0.001030 -- about 1030kg per m³ according to google, depending on fat percentage
	realMass.wool = 0.0002 -- i guess 200kg per m³ of fresh sheep whool is about right.. dont know
	realMass.egg = 0.0001 -- no way to get a accurate measurement for that
	realMass.treeSaplings = 0.0002 -- no way to get a accurate measurement for that
	realMass.fertilizer = 0.001100 -- most dry fertilizer are way over 1t per m³, but since FS doesn't difference between liquid and dry
	realMass.seeds = 0.000350 -- well.. grass seeds are 350kg per m³, wheat seeds probably heavier..
	
	-- this is a difficult one.. depending on tree and water percentage it varies very much.
	-- fresh woodchips are way heavier than dried one. Since most of the time in FS you haul fresh ones, we
	-- take that as a value.. And since most trees are soft wood we take that into account..
	realMass.woodChips = 0.000360 -- about 360kg per m³
	
	-- new FS17 filltypes:
	-- -----------------------------
	-- all the bales have a default value of 1, i think it is for the stacking wagon but i have no idea.. 
	realMass.squareBaleBarley = 1;
	realMass.squareBaleWheat = 1;
	realMass.squareBale = 1;
	realMass.roundBaleBarley = 1;
	realMass.roundBaleWheat = 1;
	realMass.roundBaleDryGrass = 1;
	realMass.roundBaleGrass = 1;
	realMass.roundBale = 1;
	
	realMass.poplar = 0.00045; -- not sure about this one
	
	realMass.sunflower = 0.00035; -- according to google
	realMass.soybean = 0.0007; -- according to google
	realMass.straw = 0.00004; -- 40kg per m³ i think is about right.. default was 30kg
	realMass.pig = 0.0002; -- 200kg per pig is about right.. i guess
	realMass.cow = 0.00064; -- 640kg per cow.. maybe?
	realMass.sheep = 0.0001; -- 100kg for a sheep might be a bit much
	realMass.chicken = 0.000003; -- 3kg a chicken
	
	realMass.pigFoodProtein = 0.0006; -- not sure, default is 0.00045	
	realMass.pigFoodGrain = 0.0006; -- again.. not sure
	realMass.pigFoodEarth = 0.00064;
	realMass.pigFoodBase = 0.0006;
	realMass.digestate = 0.0005;
	realMass.liquidFertilizer = 0.0009; -- probably closer to 1:1 with water but not sure
	realMass.oilseedRadish = 0.00075; -- according to google, giants default was 0.000205
	realMass.pigFood = 0.0006;
	
	
	-----
	-- all fillTypes that aren't in the realMass Table are multiplied by 2 as done in previous versions.
	-- if you want to add a custom fruitType with a custom mass you can just add it to the realMass Table
	-- realMass.NAME_OF_CUSTOM_FRUITTYPE = VALUE_IN_TONS_PER_LITER
	-----
	
	-- multiplier, all fruit mass values that are not found in the realMass Table (custom fill types) will be multiplied by that. Values above 1 increase the mass, values below 1 decrease it.
	multiplier = 2; -- Hier verändern, Wert von 1 = normale LS Werte, über 1 = schwerer (2 = 100% = etwa real) Werte unter 1, z.b. 0.1 dann nur ein Zehntel des normalen LS Werts usw.
	
	for k, v in pairs(FillUtil.fillTypeNameToDesc) do
		if realMass[k] ~= nil then
			FillUtil.fillTypeNameToDesc[k].massPerLiter = realMass[k];
			print("Fillable mass of Filltype "..tostring(k).." changed to "..tostring(FillUtil.fillTypeNameToDesc[k].massPerLiter*1000).." tons per 1000 Liter (according to real mass table)");
		else
			print("################ NOT IN LIST YET: "..tostring(k).." cur. Val: "..tostring(FillUtil.fillTypeNameToDesc[k].massPerLiter*1000));
			FillUtil.fillTypeNameToDesc[k].massPerLiter = FillUtil.fillTypeNameToDesc[k].massPerLiter * multiplier;	
			print("Fillable mass of Filltype "..tostring(k).." changed to "..tostring(FillUtil.fillTypeNameToDesc[k].massPerLiter*1000).." tons per 1000 Liter (using the multiplier of "..tostring(multiplier).." )");
		end;
	end;
	print("FillTypeMassAdjustment all fillType mass values have been updated. Note: This Log entry should only exist once, if you have several of these please check to make sure you don't have several FillTypeMassAdjustment Versions in your Modfolder.")
	print("- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ")
end;
function FillTypeMassAdjustment:keyEvent(unicode, sym, modifier, isDown)
end;
function FillTypeMassAdjustment:update(dt)
end;
function FillTypeMassAdjustment:draw()
end;
function FillTypeMassAdjustment:deleteMap()
end;
function FillTypeMassAdjustment:mouseEvent(posX, posY, isDown, isUp, button)
end;

addModEventListener(FillTypeMassAdjustment);







