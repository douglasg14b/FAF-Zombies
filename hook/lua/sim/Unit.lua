do
	-- Set field as siminit runs after this hook
    ScenarioInfo.ZombiesInitilized = false

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
			--if not ScenarioInfo.ZombiesInitilized then LOG("::Zombies:: Setting up Zombies");  SetupZombies() end
			if not ScenarioInfo.ZombiesInitilized then return end

			-- Get AIs of the player who damaged the unit and the player who took damage
			local selfAiBrain = self:GetAIBrain();
			local instigatorAiBrain = instigator:GetAIBrain();
			

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
			--if not ScenarioInfo.ZombiesInitilized then LOG("::Zombies:: Setting up Zombies");  SetupZombies() end
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

		-- Turns the unit into a zombie unit
		Zombify = function ( self )
			--if not ScenarioInfo.ZombiesInitilized then SetupZombies() end	
			if not ScenarioInfo.ZombiesInitilized then return end

			local pos = self:GetPosition()
			local bpid = self:GetBlueprint().BlueprintId
			if not ScenarioInfo.ZombiesInitilized or self:IsBeingBuilt() then return end

			local newzom = CreateUnitHPR(bpid, ScenarioInfo.Zombie.ArmyName, pos.x, pos.y, pos.z, 0, 0, 0)
			newzom.IsZombie = true

			--> Structures don't get decay buff if it's not enabled
			if EntityCategoryContains(categories.STRUCTURE, newzom) and not ScenarioInfo.Zombie.StructuresDecay then 
				return
			end
			
			
			-- Set Speed multiplyer for unit
			if (not EntityCategoryContains(categories.STRUCTURE, newzom) and ScenarioInfo.Zombie.SpeedBuff > 0) then
				newzom:SetSpeedMult(ScenarioInfo.Zombie.SpeedBuff)
				newzom:SetAccMult(ScenarioInfo.Zombie.SpeedBuff)
				newzom:SetTurnMult(ScenarioInfo.Zombie.SpeedBuff)
			end
			

			--> If decay rate isn't none
			if(ScenarioInfo.Zombie.DecayRate ~= 0) then
				newzom:ForkThread(newzom.DecayUnitLoop, newzom)
			end

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
				local waitTicks = 10;
				local health = math.min(self:GetHealth(), maxHealth)

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
					SPEW("::Zombies:: using SetHealth")
					--self:SetHealth(self, health - damagePerTick)
					self:AdjustHealth(self, -damagePerTick)
				end

				WaitTicks(waitTicks)
			end
		end
    }
end