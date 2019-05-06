AIOpts = {
    {
        default = 1,
        label = "<LOC zombies_0001>Zombies: Player Slot",
        help = "<LOC zombies_0002>The map slot that will be designated as the zombie",
        key = 'ZombieArmy',
        value_text = "%s",
        value_help = "<LOC zombies_0003>Slow %s will be zombie",
        values = {
            '1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20'
        }
    },
    {
        default = 1,
        label = "<LOC zombies_0004>Vampire",
        help = "<LOC zombies_0005>Recieve Mass and Energy cost of whatever you kill",
        key = 'VampirePercentage',
        value_text = "%s",
        value_help = "<LOC zombies_0006>%s times mass & energy vampire",
        values = {
            '0','0.25','0.5','0.75','1.0','1.25','1.5','1.75','2.0'
        }
    },
    {
        default = 3,
        label = "<LOC zombies_0007>Zombies: Speed",
        help = "<LOC zombies_0008>How fast should zombies move?",
        key = 'ZombieSpeed',
        value_text = "%s",
        values = {
            {
                text = "<LOC zombies_0009>Very Slow",
                help = "<LOC zombies_00010>Zombies move at 50 percent speed",
                key = 'VerySlow',
            },
            {
                text = "<LOC zombies_00011>Slow",
                help = "<LOC zombies_00012>Zombies move at 75 percent speed",
                key = 'Slow',
            },
            {
                text = "<LOC zombies_00013>Normal",
                help = "<LOC zombies_00014>Zombies move at normal speed",
                key = 'Normal',
            },
            {
                text = "<LOC zombies_00015>Fast",
                help = "<LOC zombies_00016>Zombies move at 125 percent speed",
                key = 'Fast',
            },
            {
                text = "<LOC zombies_00017>Very Fast",
                help = "<LOC zombies_00018>Zombies move at 150 percent speed",
                key = 'VeryFast',
            },
        }
    },
    {
        default = 1,
        label = "<LOC zombies_0007>Zombies: Unit Decay",
        help = "<LOC zombies_0008>At what rate shuld zombie units decay? Note that regen or repair extends the units lifespan past the decay time.",
        key = 'ZombieDecay',
        values = {
            {
                text = "<LOC zombies_00019>No Decay",
                help = "<LOC zombies_00020>Zombies do not decay",
                key = 'None',
            },
            {
                text = "<LOC zombies_00021>Dynamic",
                help = "<LOC zombies_00022>Decay slows down logarithmically as unit health is reduced. Starts at normal decay rate.",
                key = 'Dynamic',
            },
            {
                text = "<LOC zombies_00023>Very Slow",
                help = "<LOC zombies_00024>Zombies will decay within 12 minutes",
                key = 'VerySlow',
            },
            {
                text = "<LOC zombies_00025>Slow",
                help = "<LOC zombies_00026>Zombies will decay within 8 minutes",
                key = 'Slow',
            },
            {
                text = "<LOC zombies_00027>Normal",
                help = "<LOC zombies_00028>Zombies will decay within 5 minutes",
                key = 'Normal',
            },
            {
                text = "<LOC zombies_00029>Fast",
                help = "<LOC zombies_00030>Zombies will decay within 3 minutes",
                key = 'Fast',
            },
            {
                text = "<LOC zombies_00018>Very Fast",
                help = "<LOC zombies_00018>Zombies will decay within 1 minute",
                key = 'VeryFast',
            }
        }
    }
}