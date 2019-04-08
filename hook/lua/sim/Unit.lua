do
	ZombieArmyNum = ScenarioInfo.Options.ZombieArmy;
	LOG("::Zombies:: Selected Zombie Army #: " .. ZombieArmyNum);
    AreZombiesSetup = false
	ZombieArmy = "ARMY_9"

	SetupZombies = function()
		LOG("::Zombies:: LISTING ABRAINS");
		for aindex, abrain in ArmyBrains do
			SPEW("::Zombies:: " .. abrain.Name);
			SPEW(abrain);
			if 
				abrain.Name == "ARMY_" .. ZombieArmyNum
			then 
				ZombieArmy = abrain.Name;
				AreZombiesSetup = true;
				LOG("::Zombies:: Zombie army found: " .. abrain.Name);
				return
			end
			--if abrain.Name == "ARMY_9" then AreZombiesSetup = true; ZombieArmy = abrain.Name; return end
			--if abrain.Name == "ARMY_12" then AreZombiesSetup = true; ZombieArmy = abrain.Name; return end
			--if abrain.Name == "NEUTRAL_CIVILIAN" then AreZombiesSetup = true; ZombieArmy = abrain.Name; end
		end
		if AreZombiesSetup then return end
		WARN("::Zombies:: Could not find a suitable army to assign zombies to, so this will most likely crash.")
	end

    local oUnit = Unit;

    Unit = Class(oUnit) {
        IsZombie = false,
		CreateWreckage = function( self, overkillRatio )
			if not AreZombiesSetup then LOG("::Zombies:: Setting up Zombies");  SetupZombies() end
			if self.IsZombie or not AreZombiesSetup then
				oUnit.CreateWreckage( self, overkillRatio )
			else
			    -- Something like this may need to happen to fix survivals:
			    -- if self.GetArmy().Name == "ARMY_9" then ZombieArmy = "NEUTRAL_CIVILIAN" end
				self:ForkThread( self.Zombify, self )
			end
		end,

		Zombify = function ( self )
			if not AreZombiesSetup then SetupZombies() end	
			local pos = self:GetPosition()
			local bpid = self:GetBlueprint().BlueprintId
			if not AreZombiesSetup or self:IsBeingBuilt() then return end
			-- WaitSeconds(1)
			local newzom = CreateUnitHPR(bpid, ZombieArmy, pos.x, pos.y, pos.z, 0, 0, 0)
			newzom.IsZombie = true
		end, 
    }
end