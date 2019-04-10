local modPath = 'Zombies'


local ParentBeginSession = BeginSession
function BeginSession()
	ParentBeginSession()
	ForkThread(import('/mods/'..modPath..'/lua/Vampire.lua').VampireResourceThread)

	local zomThread = ForkThread(ZombieSimThread)
end

function ZombieSimThread()
	WaitSeconds(2)
	Sync.zAlert = { "Welcome", "to the Zombie horde..." };
end



--SPEW("::Zombies:: Sending Welcome Alert")

--local parent = import('/lua/ui/game/borders.lua').GetMapGroup()

--import('/mods/'..modPath..'/lua/utility.lua').ShowAlert({ "Welcome", "to the Zombie horde..." })
--import('/mods/'..modPath..'/lua/ui/CreateUi.lua').CreateModUI(parent)