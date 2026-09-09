config = {}

-- target resource (only one of these can be true)
-------------------------------------------------------
config.qbtarget = true
config.oxtarget = false
-------------------------------------------------------

config.InventorySystem = 'qb' -- Supports 'ox' & 'qb'
config.pedmodel = 'a_m_m_prolhost_01' -- ped model hash

config.scenario = 'WORLD_HUMAN_CLIPBOARD' -- scenario for ped to play, false to disable

config.locations = {
    ['legion'] = {
        ped = true, -- if false uses boxzone (below)
        coords = vector4(214.79, -806.52, 30.81, 337.16),
        -------- boxzone (only used if ped is false) --------
        length = 1.0,  
        width = 1.0,   
        minZ = 30.81,  
        maxZ = 30.81,  
        debug = false, 
        -----------------------------------------------------
        -------- blip (each location can have its own) --------
        useBlip = true,   -- set to false to hide the blip for this location only
        blipSprite = 326,
        blipScale = 0.4,
        blipColor = 48,   -- see https://docs.fivem.net/docs/game-references/blips/#blip-colors
        ---------------------------------------------------------
        vehicles = {
            ['panto'] = {
                price = 50,
                image = 'https://docs-backend.fivem.net/vehicles/panto.webp',
            },
            ['bmx'] = {
                price = 0,
                image = 'https://docs-backend.fivem.net/vehicles/bmx.webp',
            },
        },
        vehiclespawncoords = vector4(212.64, -797.12, 30.87, 339.09), -- where vehicle spawns when rented
    },
    ['hospital'] = {
        ped = true,
        coords = vector4(246.93, -559.06, 43.27, 159.85),
        -------- boxzone (only used if ped is false) --------
        length = 1.0,  
        width = 1.0,   
        minZ = 30.81,  
        maxZ = 30.81,  
        debug = false, 
        -----------------------------------------------------
        -------- blip (each location can have its own) --------
        useBlip = true,
        blipSprite = 326,
        blipScale = 0.4,
        blipColor = 48,
        ---------------------------------------------------------
        vehicles = {
            ['panto'] = {
                price = 50,
                image = 'https://docs-backend.fivem.net/vehicles/panto.webp',
            },
            ['bmx'] = {
                price = 0,
                image = 'https://docs-backend.fivem.net/vehicles/bmx.webp',
            },
        },
        vehiclespawncoords = vector4(253.77, -564.2, 43.27, 152.49),
    },
    -- add as many locations as you'd like with any type of vehicle (air, water, land) follow same format as above
}

config.rentalDurations = {
    {label = '30 Minutes', minutes = 30},
    {label = '1 Hour',     minutes = 60},
    {label = '2 Hours',    minutes = 120},
    {label = '4 Hours',    minutes = 240},
}

config.returnRefundPercent = 0.75 -- paid back when the player manually uses "Return Vehicle"
config.expireRefundPercent = 0.25 -- paid back when the rental timer runs out on its own
