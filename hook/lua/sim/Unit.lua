do
	ZombieArmyNum = ScenarioInfo.Options.ZombieArmy;
	ScenarioInfo.Zombie = {}

	LOG("::Zombies:: Selected Zombie Army #: " .. ZombieArmyNum);
    AreZombiesSetup = false
	ZombieArmy = "ARMY_9"

	SetupZombies = function()
		LOG("::Zombies:: LISTING ABRAINS");
		for aindex, abrain in ArmyBrains do
			SPEW("::Zombies:: " .. abrain.Name);
			if 
				abrain.Name == "ARMY_" .. ZombieArmyNum
			then 
				ZombieArmy = abrain.Name;
				AreZombiesSetup = true;
				LOG("::Zombies:: Zombie army found: " .. ArmyBrains[abrain:GetArmyIndex()].Nickname);
				ScenarioInfo.Zombie.Army = ArmyBrains[abrain:GetArmyIndex()].Nickname;
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

		DoTakeDamage = function(self, instigator, amount, vector, damageType)
			local ok,msg = pcall(self.HandleDoTakeDamage, self, instigator, amount, vector, damageType)

			if not ok then
				WARN("::Zombies:: Exception occured when trying to perform zombie damage. Reverting to vanilla damage instead. Message on next line:")
				WARN(msg)
				oUnit.DoTakeDamage(self, instigator, amount, vector, damageType)
			end
		end,

		HandleDoTakeDamage = function(self, instigator, amount, vector, damageType)			
			if not AreZombiesSetup then LOG("::Zombies:: Setting up Zombies");  SetupZombies() end
			
			-- Get AIs of the player who damaged the unit and the player who took damage
			local selfAiBrain = self:GetAIBrain();
			local instigatorAiBrain = instigator:GetAIBrain();

			

			local preAdjHealth = self:GetHealth()
			if preAdjHealth - amount > 0 then  -- Unit damaged, but not killed
				oUnit.DoTakeDamage(self, instigator, amount, vector, damageType)
				return
			elseif self.IsZombie or not AreZombiesSetup then -- Unit killed, but is a zombie
				oUnit.DoTakeDamage(self, instigator, amount, vector, damageType)
				return
			elseif selfAiBrain.Name ~= ZombieArmy then -- Unit killed, is not a zombie, but belongs to the zombie army
				-- SPEW("::Zombies:: Unit Killed: Self: " .. self:GetArmy() .. " Instigator: " .. instigator:GetArmy())
				oUnit.DoTakeDamage(self, instigator, amount, vector, damageType)
				return
			end

			local overkillRatio = 0.0
			local excess = preAdjHealth - amount
			local maxHealth = self:GetMaxHealth()

			if excess < 0 and maxHealth > 0 then
				overkillRatio = -excess / maxHealth
			end

			self.IsZombie = true

			-- Notify instigator of kill and spread veterancy
			-- We prevent any vet spreading if the instigator isn't part of the vet system (EG - Self destruct)
			-- This is so that you can bring a damaged Experimental back to base, kill, and rebuild, without granting
			-- instant vet to the enemy army, as well as other obscure reasons
			if self.totalDamageTaken > 0 and not self.veterancyDispersed then
				self:VeterancyDispersal(not instigator or not IsUnit(instigator))
			end

			local bp = self:GetBlueprint()
			local massCost = bp.Economy.BuildCostMass
			local energyCost = bp.Economy.BuildCostEnergy

			instigatorAiBrain:GiveResource('MASS', massCost * tonumber(ScenarioInfo.Options.VampirePercentage))
			instigatorAiBrain:GiveResource('ENERGY', energyCost * tonumber(ScenarioInfo.Options.VampirePercentage))

			self:ForkThread( self.HandlePseudoDeath, self, instigator,  overkillRatio)
			self:AdjustHealth(self, maxHealth)
		end,

		-- Provides the death/explosion sound and animation
		HandlePseudoDeath = function(self, instigator, overkillRatio)
			local layer = self:GetCurrentLayer()
			local bp = self:GetBlueprint()
			if layer == 'Water' and bp.Physics.MotionType == 'RULEUMT_Hover' then
				self:PlayUnitSound('HoverKilledOnWater')
			elseif layer == 'Land' and bp.Physics.MotionType == 'RULEUMT_AmphibiousFloating' then
				-- Handle ships that can walk on land
				self:PlayUnitSound('AmphibiousFloatingKilledOnLand')
			else
				self:PlayUnitSound('Killed')
			end

			-- BOOM!
			if self.PlayDestructionEffects then
				self:CreateDestructionEffects(overkillRatio)
			end

			-- Flying bits of metal and whatnot. More bits for more overkill.
			if self.ShowUnitDestructionDebris and overkillRatio then
				self.CreateUnitDestructionDebris(self, true, true, overkillRatio > 2)
			end

		end,

		CreateWreckage = function( self, overkillRatio )
			if not AreZombiesSetup then LOG("::Zombies:: Setting up Zombies");  SetupZombies() end
			
			-- Zombies die normally
			if self.IsZombie or not AreZombiesSetup then
				oUnit.CreateWreckage( self, overkillRatio )
			
			-- Self-destruct/suicide doesn't turn into zombies
			elseif ArmyBrains[self:GetArmy()].LastUnitKilledBy == self:GetArmy() then
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