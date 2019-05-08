local modPath = 'Zombies'


local ParentBeginSession = BeginSession
function BeginSession()
	ParentBeginSession()
	ForkThread(import('/mods/'..modPath..'/lua/Vampire.lua').VampireResourceThread)

	local zomThread = ForkThread(ZombieSimThread)
end

function ZombieSimThread()
	LOG("::Zombies:: Starting sim thread")
	SetZombiesSettings()
	FindZombieArmy();

	WaitSeconds(2)
	Sync.zAlert = { "Welcome", "to the Zombie horde..." };
end

function SetZombiesSettings()

	LOG("::Zombies:: Setting up settings")

	-- The speed buffs zombies can get
	local SpeedBuffs = {
		VerySlow = 0.5,
		Slow = 0.75,
		Normal = 1,
		Fast = 1.25,
		VeryFast = 1.5
	};

	local DecayRates = {
		None = 0,
		Dynamic = -1,
		VerySlow = 12,
		Slow = 8,
		Normal = 5,
		Fast = 3,
		VeryFast = 1
	}

	ScenarioInfo.Zombie = {
		-- If the Zombie army has been selected
		ZombiesSetup = false,
		-- The players actual name
		PlayerName = "",
		-- The Army slot anme. ie ARMY_7
		ArmyName = "",
		-- The Army index (slot#)
		ArmyIndex = ScenarioInfo.Options.ZombieArmy,
		-- The percentage of mass & energy vampire that is applied to kills
		VampirePercentage = tonumber(ScenarioInfo.Options.VampirePercentage),
		-- The speed buff zombie units get
		SpeedBuff = SpeedBuffs[ScenarioInfo.Options.ZombieSpeed] or SpeedBuffs.Normal,
		-- The rate at which units decay
		DecayRate = DecayRates[ScenarioInfo.Options.ZombieDecay],
		-- If the zombie players structures should also experiance decay
		StructuresDecay = true,

		SpeedBuffs = SpeedBuffs,
		DecayRates = DecayRates
	}

	LOG("    ::Zombies:: ArmyIndex: " .. ScenarioInfo.Zombie.ArmyIndex)
	LOG("    ::Zombies:: Vampire: " .. ScenarioInfo.Zombie.VampirePercentage)
	LOG("    ::Zombies:: SpeedBuff: " .. ScenarioInfo.Zombie.SpeedBuff)
	LOG("    ::Zombies:: Decay Rate: " .. ScenarioInfo.Zombie.DecayRate)

end


function FindZombieArmy()

	LOG("::Zombies:: Finding Zombie Army");
	for aindex, abrain in ArmyBrains do
		if 
			abrain.Name == "ARMY_" .. ScenarioInfo.Zombie.ArmyIndex
		then
			ScenarioInfo.Zombie.ArmyName = abrain.Name
			ScenarioInfo.Zombie.PlayerName = ArmyBrains[abrain:GetArmyIndex()].Nickname
			ScenarioInfo.Zombie.ArmyIndex = abrain:GetArmyIndex();
			ScenarioInfo.Zombie.ZombiesSetup = true

			ScenarioInfo.ZombiesInitilized = true;

			LOG("::Zombies:: Zombie army found and set: " .. ScenarioInfo.Zombie.PlayerName);
			return
		end
	end
	if ScenarioInfo.ZombiesInitilized then return end
	WARN("::Zombies:: Could not find a suitable army to assign zombies to, so this will most likely crash.")
end

--SPEW("::Zombies:: Sending Welcome Alert")

--local parent = import('/lua/ui/game/borders.lua').GetMapGroup()

--import('/mods/'..modPath..'/lua/utility.lua').ShowAlert({ "Welcome", "to the Zombie horde..." })
--import('/mods/'..modPath..'/lua/ui/CreateUi.lua').CreateModUI(parent)