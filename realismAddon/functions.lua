-- by modelleicher
--
-- additional functions used in realism update modelleicher


-- realism xml load functions. Used to load values either from mod-xml or config xml
-- config xml has priority if it exists, otherwise use normal xml
r_getXMLInt = function(self, path)
	if self.realism ~= nil and self.realism.configXML ~= nil and self.realism.configXMLIndex ~= nil then
		return getXMLInt(self.realism.configXML, "realismUpdateConfig.vehicle("..self.realism.configXMLIndex..")."..path);
	else
		return getXMLInt(self.xmlFile, "vehicle."..path);
	end;
end;

r_getXMLString = function(self, path)
	if self.realism ~= nil and self.realism.configXML ~= nil and self.realism.configXMLIndex ~= nil then
		return getXMLString(self.realism.configXML, "realismUpdateConfig.vehicle("..self.realism.configXMLIndex..")."..path);
	else
		return getXMLString(self.xmlFile, "vehicle."..path);
	end;
end;

r_getXMLFloat = function(self, path)
	if self.realism ~= nil and self.realism.configXML ~= nil and self.realism.configXMLIndex ~= nil then
		return getXMLFloat(self.realism.configXML, "realismUpdateConfig.vehicle("..self.realism.configXMLIndex..")."..path);
	else
		return getXMLFloat(self.xmlFile, "vehicle."..path);
	end;
end;

r_getXMLBool = function(self, path)
	print("r_getXMLBool");
	if self.realism ~= nil and self.realism.configXML ~= nil and self.realism.configXMLIndex ~= nil then
		print("r_getXMLBool a");
		return getXMLBool(self.realism.configXML, "realismUpdateConfig.vehicle("..self.realism.configXMLIndex..")."..path);
	else
		print("r_getXMLBool b");
		return getXMLBool(self.xmlFile, "vehicle."..path);
	end;
end;

-- xml functions end