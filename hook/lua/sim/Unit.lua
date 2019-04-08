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

		DoTakeDamage = function(self, instigator, amount, vector, damageType)

			
			if not AreZombiesSetup then LOG("::Zombies:: Setting up Zombies");  SetupZombies() end
			
			local ownArmy = self:GetAIBrain().Name
			--SPEW("::Zombies:: Army: " .. self:GetArmy())
			--SPEW("::Zombies:: AI Brain: " .. self:GetAIBrain().Name)
			local preAdjHealth = self:GetHealth()
			if preAdjHealth - amount > 0 then 
				oUnit.DoTakeDamage(self, instigator, amount, vector, damageType)
				return
			elseif self.IsZombie or not AreZombiesSetup then
				oUnit.DoTakeDamage(self, instigator, amount, vector, damageType)
				return
			elseif ownArmy ~= ZombieArmy then
				SPEW("::Zombies:: Unit Killed: Self: " .. self:GetArmy() .. " Instigator: " .. instigator:GetArmy())
				oUnit.DoTakeDamage(self, instigator, amount, vector, damageType)
				return
			end

			local overkillRatio = 0.0
			local excess = preAdjHealth - amount
			local maxHealth = self:GetMaxHealth()
			SPEW("::Zombies:: Calculating Overkill. Max health: " .. maxHealth)
			if excess < 0 and maxHealth > 0 then
				overkillRatio = -excess / maxHealth
			end

			self.IsZombie = true

			self:ForkThread( self.HandlePseudoDeath, self, instigator,  overkillRatio)

			--local bp = self:GetBlueprint()
			--SPEW("::Zombies:: Healing Unit. Max health: " .. bp.Defense.maxHealth)
			--SPEW("::Zombies:: Healing Unit. Max health: " .. self:GetMaxHealth())
			self:AdjustHealth(self, maxHealth)
		end,

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