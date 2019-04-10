#****************************************************************************
#**
#**  File     :  /hook/lua/ui/game/gamemain.lua
#**  Author(s):  novaprim3
#**
#**  Summary  :  Multi-Phantom Mod for Forged Alliance
#**
#****************************************************************************

local baseCreateUI = CreateUI 

function CreateUI(isReplay) 
	baseCreateUI(isReplay)

	SPEW("::Zombies:: Create UI")
	
  	if not isReplay then
		local parent = import('/lua/ui/game/borders.lua').GetMapGroup()
		import('/mods/zombies/lua/ui/ZombieUI.lua').CreateModUI(parent)
	end

end
