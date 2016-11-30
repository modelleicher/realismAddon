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
	
	
	
	oldSteerableLoad(self, savegame);
	
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
































