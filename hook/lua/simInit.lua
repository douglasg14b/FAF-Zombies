local modPath = 'Zombies'


local ParentBeginSession = BeginSession
function BeginSession()
	local zomThread = ForkThread(ZombieSimThread)

	ParentBeginSession()
end

function ZombieSimThread()
	LOG("::Zombies:: Starting sim thread")

	SetZombiesSettings()
	FindZombieArmy();

	Sync.zAlert = { "Welcome", "to the Zombie horde..." };

	ForkThread(import('/mods/'..modPath..'/lua/Vampire.lua').VampireResourceThread)
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

	local BuildRates = {
		None = 1,
		1.25,
		1.5,
		1.75,
		2.0,
		2.5,
		3.0,
		4.0
	}

	ScenarioInfo.Zombie = {
		-- If the Zombie army has been selected
		Initilized = false,
		-- If the setup failed
		FailedToInitilized = false,
		-- The players actual name
		PlayerName = "",
		-- The Army slot name. ie ARMY_7
		ArmyName = "",
		-- The slot# of the zombie army
		ArmySlot = ScenarioInfo.Options.ZombieArmy,
		-- The Army index. This is set when the zombie player is found. Is not related to slot#
		ArmyIndex = 0,
		-- The percentage of mass & energy vampire that is applied to kills
		VampirePercentage = tonumber(ScenarioInfo.Options.VampirePercentage),
		-- The speed buff zombie units get
		SpeedBuff = SpeedBuffs[ScenarioInfo.Options.ZombieSpeed] or SpeedBuffs.Normal,
		-- The rate at which units decay
		DecayRate = DecayRates[ScenarioInfo.Options.ZombieDecay],
		-- The Zombie players build rate
		BuildRate = tonumber(ScenarioInfo.Options.ZombieBuildRate),


		-- If the zombie players structures should also experiance decay when there is a decay rate
		StructuresDecay = true,
		-- When true all Zombie player units are zombified immediately upon creation.
		ZombifyByDefault = true,

		SpeedBuffs = SpeedBuffs,
		DecayRates = DecayRates,
		BuildRates = BuildRates
	}

	LOG("    ::Zombies:: ArmySlot: " .. ScenarioInfo.Zombie.ArmySlot)
	LOG("    ::Zombies:: Vampire: " .. ScenarioInfo.Zombie.VampirePercentage)
	LOG("    ::Zombies:: SpeedBuff: " .. ScenarioInfo.Zombie.SpeedBuff)
	LOG("    ::Zombies:: Decay Rate: " .. ScenarioInfo.Zombie.DecayRate)
	LOG("    ::Zombies:: Build Rate: " .. ScenarioInfo.Zombie.BuildRate)


	LOG("    ::Zombies:: Building Decay: " .. (ScenarioInfo.Zombie.StructuresDecay and 'true' or 'false'))
	LOG("    ::Zombies:: Zombie Player Zombified: " .. (ScenarioInfo.Zombie.ZombifyByDefault and 'true' or 'false'))

end


function FindZombieArmy()

	LOG("::Zombies:: Finding Zombie Army");
	for aindex, abrain in ArmyBrains do
		if 
			abrain.Name == "ARMY_" .. ScenarioInfo.Zombie.ArmySlot
		then
			ScenarioInfo.Zombie.ArmyName = abrain.Name
			ScenarioInfo.Zombie.PlayerName = ArmyBrains[abrain:GetArmyIndex()].Nickname
			ScenarioInfo.Zombie.ArmyIndex = abrain:GetArmyIndex();
			ScenarioInfo.Zombie.Initilized = abrain:GetArmyIndex();

			ScenarioInfo.ZombiesInitilized = true; -- Used by scripts that start before siminit

			LOG("::Zombies:: Zombie army found and set:");
			LOG("    ::Zombies:: Army Index: " .. ScenarioInfo.Zombie.ArmyName);
			LOG("    ::Zombies:: Army Name: " .. ScenarioInfo.Zombie.ArmyIndex);
			LOG("    ::Zombies:: Player Name: " .. ScenarioInfo.Zombie.PlayerName);

			return
		end
	end
	if ScenarioInfo.Zombie.Initilized then return end

	ScenarioInfo.ZombiesFailedToInitilized = true; -- Used by scripts that start before siminit
	ScenarioInfo.Zombie.FailedToInitilized = true;

	WARN("::Zombies:: Could not find a suitable army to assign zombies to.")
end

--SPEW("::Zombies:: Sending Welcome Alert")

--local parent = import('/lua/ui/game/borders.lua').GetMapGroup()

--import('/mods/'..modPath..'/lua/utility.lua').ShowAlert({ "Welcome", "to the Zombie horde..." })
--import('/mods/'..modPath..'/lua/ui/CreateUi.lua').CreateModUI(parent)