do
	-- Set fields as siminit runs after this hook
	ScenarioInfo.ZombiesInitilized = false
	ScenarioInfo.ZombiesFailedToInit = false
	DebugMode = false

    local oUnit = Unit;

    Unit = Class(oUnit) {
		IsZombie = false,

		OnCreate = function(self)
			oUnit.OnCreate(self)

			if not ScenarioInfo.ZombiesInitilized then 
				self:ForkThread(self.DeferTillInitilized, self.SetupZombieUnit)
				return
			end

			local armyIndex = self:GetArmy();
			if ScenarioInfo.Zombie.ArmyIndex == armyIndex then
				self.SetupZombieUnit(self)
			end

		end,

		-- Called for the initial OnCreate
		SetupZombieUnit = function(self)
			local armyIndex = self:GetArmy();
			--> Not a Zombie army unit, return
			if ScenarioInfo.Zombie.ArmyIndex ~= armyIndex then
				return
			end

			local bp = self:GetBlueprint()

			-- Avoid applying Zombie to things like effects
			if EntityCategoryContains(categories.INSIGNIFICANTUNIT, self) or EntityCategoryContains(categories.UNTARGETABLE, self) then
				return
			end

			if DebugMode then SPEW('::Zombies:: SetupZombieUnit Called for Unit: ' .. self:GetEntityId() .. ' | ' .. self:GetUnitId() .. ' | ' .. bp.Description) end

			self.ApplyZombieBuiltRateBuff(self);
			self.Zombify(self);
		end,

		DoTakeDamage = function(self, instigator, amount, vector, damageType)
			local ok,msg = pcall(self.HandleDoTakeDamage, self, instigator, amount, vector, damageType)

			if not ok then
				local bp = self:GetBlueprint()

				WARN("::Zombies:: Exception occured when trying to perform zombie damage. Reverting to vanilla damage instead. Message follows context:")
				if bp ~= nil then
					Log("::Zombies:: BP Context: " .. bp.Description)
				end

				WARN(msg)

				oUnit.DoTakeDamage(self, instigator, amount, vector, damageType)
			end
		end,

		HandleDoTakeDamage = function(self, instigator, amount, vector, damageType)			
			if not ScenarioInfo.ZombiesInitilized then return end

			-- Get AIs of the player who damaged the unit and the player who took damage
			local selfAiBrain = self:GetAIBrain();
			local instigatorAiBrain = nil;

			--> Sometimes the instigator is nil, must handle this
			if instigator ~= nil then
				instigatorAiBrain = instigator:GetAIBrain();
			end
			

			local preAdjHealth = self:GetHealth()
			if preAdjHealth - amount > 0 then  -- Unit damaged, but not killed
				oUnit.DoTakeDamage(self, instigator, amount, vector, damageType)
				return
			elseif self.IsZombie or not ScenarioInfo.ZombiesInitilized then -- Unit killed, but is a zombie
				oUnit.DoTakeDamage(self, instigator, amount, vector, damageType)
				return
			elseif selfAiBrain.Name ~= ScenarioInfo.Zombie.ArmyName then -- Unit killed, is not a zombie, but belongs to the zombie army
				-- SPEW("::Zombies:: Unit Killed: Self: " .. self:GetArmy() .. " Instigator: " .. instigator:GetArmy())
				oUnit.DoTakeDamage(self, instigator, amount, vector, damageType)
				return
			end


			 ------------------------------------
			 -- Handle Zombie Army Frist Death --
			 ------------------------------------

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

			--> Sometimes the instigator is nil
			if instigatorAiBrain ~= nil then
				instigatorAiBrain:GiveResource('MASS', massCost * tonumber(ScenarioInfo.Options.VampirePercentage))
				instigatorAiBrain:GiveResource('ENERGY', energyCost * tonumber(ScenarioInfo.Options.VampirePercentage))
			end



			self:ForkThread( self.HandlePseudoDeath, instigator,  overkillRatio)
			self:AdjustHealth(self, maxHealth)
		end,

		-- Provides the death/explosion sound and animation.
		-- Only used when a non-zombie unit of the zombie army dies
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
			if not ScenarioInfo.ZombiesInitilized then return end

			local selfArmy = self:GetArmy()
			
			-- Zombies die normally
			if self.IsZombie or not ScenarioInfo.ZombiesInitilized then
				oUnit.CreateWreckage( self, overkillRatio )
			
			-- Self-destruct/suicide doesn't turn into zombies. Zombie player suicides still turn into zombies
			elseif ArmyBrains[selfArmy].LastUnitKilledBy == selfArmy and selfArmy ~= ScenarioInfo.Zombie.ArmyIndex  then
				oUnit.CreateWreckage( self, overkillRatio )
			else
			    -- Something like this may need to happen to fix survivals:
			    -- if self.GetArmy().Name == "ARMY_9" then ScenarioInfo.Zombie.ArmyName = "NEUTRAL_CIVILIAN" end
				self:ForkThread( self.Zombify, self )
			end
		end,

		ApplyZombieBuiltRateBuff = function(self)
			if not self then return end -- unit no longer exists

			-- Defer and exit if not initilized
			if not ScenarioInfo.ZombiesInitilized then
				self:ForkThread(self.DeferTillInitilized, self.ApplyZombieBuiltRateBuff)
				return
			end

			-- If no build rate applies, then return
			if ScenarioInfo.Zombie.BuildRate <= 1 then return end

			local hasBuildRate = self:GetBlueprint().Economy.BuildRate > 1
			local selfAiBrain = self:GetAIBrain()

			if  EntityCategoryContains(categories.ENGINEER, self) or
				EntityCategoryContains(categories.FACTORY, self) or
				EntityCategoryContains(categories.CARRIER, self) or
				EntityCategoryContains(categories.SUBCOMMANDER, self) then


				if (selfAiBrain.Name == ScenarioInfo.Zombie.ArmyName) and hasBuildRate then 
					if DebugMode then SPEW("::Zombies:: Applying build rate buff to: " .. self:GetEntityId()) end
					if DebugMode then SPEW("    " .. ScenarioInfo.Zombie.BuildRate)  end
					if DebugMode then SPEW("    " .. type(ScenarioInfo.Zombie.BuildRate))  end

					Buff.ApplyBuff(self, "ZombieBuildRate_" .. ScenarioInfo.Zombie.BuildRate )
				end
			end
		end,

		-- Turns the unit into a zombie unit
		Zombify = function ( self )
			if not self then return end -- unit no longer exists

			-- Defer and exit if not initilized
			if not ScenarioInfo.ZombiesInitilized then 
				self:ForkThread(self.DeferTillInitilized, self.Zombify)
				return
			end

			if not self.CanZombify(self) then return end

			local armyIndex = self:GetArmy();
			local zombieUnit = self;

			if DebugMode then SPEW('::Zombies:: Zombify called for unit: ' .. self:GetEntityId()) end

			-- If the unit is dead then create a zombie
			if self:IsDead() then
				if DebugMode then SPEW('::Zombies:: Zombifying killed unit: ' .. self:GetEntityId()) end

				local pos = self:GetPosition()
				local bpid = self:GetBlueprint().BlueprintId
				zombieUnit = CreateUnitHPR(bpid, ScenarioInfo.Zombie.ArmyName, pos.x, pos.y, pos.z, 0, 0, 0)

				if DebugMode then SPEW('::Zombies:: New Zombie Created from killed unit: ' .. zombieUnit:GetEntityId()) end

				return -- Return as Unit will be zombified from OnCreate
			end

			zombieUnit.IsZombie = true

			--> Structures don't get decay buff if it's not enabled
			if EntityCategoryContains(categories.STRUCTURE, zombieUnit) and not ScenarioInfo.Zombie.StructuresDecay then 
				return
			end
			
			-- Set Speed multiplyer for unit if it's on and isn't a structure
			-- TODO: Use a buff instead in the future
			if (not EntityCategoryContains(categories.STRUCTURE, zombieUnit) and ScenarioInfo.Zombie.SpeedBuff > 0) then
				zombieUnit:SetSpeedMult(ScenarioInfo.Zombie.SpeedBuff)
				zombieUnit:SetAccMult(ScenarioInfo.Zombie.SpeedBuff)
				zombieUnit:SetTurnMult(ScenarioInfo.Zombie.SpeedBuff)
			end
			

			--> If decay rate isn't none, start decay
			if(ScenarioInfo.Zombie.DecayRate ~= 0) then
				zombieUnit:ForkThread(zombieUnit.DecayUnitLoop, zombieUnit)
			end

		end,

		CanZombify = function(self)
			local armyIndex = self:GetArmy();

			-- Exit if the unit is being built, can't Zombify incomplete units.
			-- TODO: Zombify incomplete units, use their build % as their health % when zombified? 
			if self:IsBeingBuilt() then return false end
			
			-- Unit is not dead, and Zombie player zombification is off. Nothing needs to be done here
			if ScenarioInfo.Zombie.ArmyIndex == armyIndex and not ScenarioInfo.Zombie.ZombifyByDefault and not self:IsDead() then
				return false
			end

			return true
		end,

		DecayUnitLoop = function(self)
			WaitSeconds(5); --Delay start of decay by 5 seconds

			local maxHealth = self:GetMaxHealth()
			local damagePerTick = 0;

			--> If decay rate isn't dynamic
			if(ScenarioInfo.Zombie.DecayRate ~= -1) then
				damagePerTick = math.floor(math.max(1, maxHealth / (ScenarioInfo.Zombie.DecayRate * 60)));
			end

			while (self and not self:IsDead()) and (self:GetHealth() > 0) do
				local waitTicks = 10; -- about 1 second
				local health = math.min(self:GetHealth(), maxHealth)
				local maxHealth = self:GetMaxHealth()

				--> Dynamic decay rate reduced as health is lower
				if(ScenarioInfo.Zombie.DecayRate == -1) then
					local percentageOfMax = health / maxHealth
					local normalDamageRate = health / (ScenarioInfo.Zombie.DecayRates.Normal * 60)

					--> Modifies the rate to make a log curve
					local rateModifyer = math.pow(percentageOfMax, 1.2)
					local adjustedRate = normalDamageRate * rateModifyer

					--> Turn into int with a min value of 1
					damagePerTick = math.max(math.floor(adjustedRate), 1)

					--> If the damage rate is less than 1 then set to 1 and increase the wait time between damage ticks
					if(adjustedRate < 1) then
						waitTicks = math.floor(waitTicks/adjustedRate)
					end
				end


				--> TODO: FIgure out how to adjust health without the icon flicker...
				if(health - damagePerTick <= 0) then
					self.DoTakeDamage(self, self, damagePerTick, nil, "Spell")
				else
					--self:SetHealth(health - damagePerTick)
					self:AdjustHealth(self, -damagePerTick)
				end

				WaitTicks(waitTicks)
			end
		end,

		--Will defer to call until the mod is fully initilized
		DeferTillInitilized = function(self, callback)
			if DebugMode then SPEW('::Zombies:: Starting Deferral Thread for Unit: ' .. self:GetUnitId()) end
			while not ScenarioInfo.ZombiesInitilized do
				WaitSeconds(0.1)

				-- If it failed to start, exit deferral
				if ScenarioInfo.ZombiesFailedToInit then
					WARN('::Zombies:: Cancelling callback deferral, zombies failed to initilize')
					return
				end
			end

			if DebugMode then SPEW('::Zombies:: Calling deferred callback') end

			callback(self)
		end
    }
end