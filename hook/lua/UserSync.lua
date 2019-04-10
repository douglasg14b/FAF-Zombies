#****************************************************************************
#**
#**  File     :  /hook/lua/UserSync.lua
#**  Author(s):  novaprim3
#**
#**
#****************************************************************************
local modPath = 'Zombies'

local baseOnSync = OnSync

function OnSync()
    baseOnSync()

    # Sim to UI
    if Sync.zAlert then
        import('/mods/' .. modPath .. '/lua/ui/ZombieUI.lua').ShowAlert(Sync.zAlert)
    end
end
