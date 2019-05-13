------------------------------------------------------------------------
-----    Original script by novaprim3. Modified by douglasg14b     -----
------------------------------------------------------------------------


local state = {
	config = { 
        mass = tonumber(ScenarioInfo.Options.VampirePercentage), 
        energy = tonumber(ScenarioInfo.Options.VampirePercentage) 
    },
	delta = { 
        mass = {}, 
        energy = {} 
	},
	totals = {
		mass= {},
		energy = {}
	},
	trash = nil
}


-- Provide each player with their vampire acquired resources
function VampireResourceThread()
	while true do
		WaitSeconds(0.1)
		for army, brain in ArmyBrains do
			if state.totals.mass[army] == nil then state.totals.mass[army] = 0 end
			if state.totals.energy[army] == nil then state.totals.energy[army] = 0 end

			if ArmyIsOutOfGame(army) == false then
				--brain = ArmyBrains[army]
				local mass = brain:GetArmyStat("Enemies_MassValue_Destroyed",0.0).Value
				local energy = brain:GetArmyStat("Enemies_EnergyValue_Destroyed",0.0).Value
				if state.delta.mass[army] > 0 then
					local deltaMass = (mass - state.delta.mass[army]) * state.config.mass
					local deltaEnergy = (energy - state.delta.energy[army]) * state.config.energy

					brain:GiveResource('MASS', deltaMass)
					brain:GiveResource('ENERGY', deltaEnergy)

					state.totals.mass[army] = state.totals.mass[army] + deltaMass
					state.totals.energy[army] = state.totals.energy[army] + deltaEnergy
				end
				state.delta.mass[army] = mass
				state.delta.energy[army] = energy
			end
		end
	end
end