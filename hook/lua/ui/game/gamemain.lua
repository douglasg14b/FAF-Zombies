local baseCreateUI = CreateUI 

function CreateUI(isReplay) 
	baseCreateUI(isReplay)

	SPEW("::Zombies:: Create UI")
	
  	if not isReplay then
		local parent = import('/lua/ui/game/borders.lua').GetMapGroup()
		import('/mods/zombies/lua/ui/ZombieUI.lua').CreateModUI(parent)
	end

end
