local QBCore = GetResourceState('qb-core') == 'started' and exports['qb-core']:GetCoreObject()
local ESX = GetResourceState('es_extended') == 'started' and exports.es_extended:getSharedObject()

local ped = {}
local blips = {}

Citizen.CreateThread(function()
    for k, v in pairs(config.locations) do 
        if v.ped then 
            RequestModel(config.pedmodel)
            while not HasModelLoaded(config.pedmodel) do
                Wait(10)
            end
            ped[k] = CreatePed(4, config.pedmodel, v.coords.x, v.coords.y, v.coords.z, v.coords.w, false, true)
            if config.scenario then 
                TaskStartScenarioInPlace(ped[k], config.scenario, 0, true)
            end
            SetEntityCoordsNoOffset(ped[k], v.coords.x, v.coords.y, v.coords.z, false, false, false, true)
            Wait(100)
            FreezeEntityPosition(ped[k], true)
            SetEntityInvincible(ped[k], true)
            SetBlockingOfNonTemporaryEvents(ped[k], true)
        end

        local useBlip = v.useBlip
        if useBlip == nil then useBlip = true end

        if useBlip then
            local sprite = v.blipSprite or 326
            local scale = v.blipScale or 0.4
            local color = v.blipColor or 26

            blips[k] = AddBlipForCoord(v.coords.x, v.coords.y, v.coords.z)
            SetBlipSprite(blips[k], sprite)
            SetBlipDisplay(blips[k], 4)
            SetBlipScale(blips[k], scale)
            SetBlipAsShortRange(blips[k], true)
            SetBlipColour(blips[k], color)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName("Vehicle Rental")
            EndTextCommandSetBlipName(blips[k])
        end

        if not v.ped then 
            if config.qbtarget then 
                exports['qb-target']:AddBoxZone(k, v.coords, v.length, v.width, {
                    name = k,
                    heading = v.coords.w,
                    debugPoly = false,
                    minZ = v.coords.z,
                    maxZ = v.coords.z
                }, {
                    options = {
                        {
                            icon = 'fas fa-car',
                            label = 'Rent Vehicle',
                            action = function()
                                TriggerEvent('bd-rentals:client:rentVehicle', k)
                            end
                        },
                        {
                            icon = 'fas fa-undo',
                            label = 'Return Vehicle',
                            action = function()
                                TriggerServerEvent('bd-rentals:server:ReturnVehicle')
                            end
                        },
                    },
                    distance = 2.0
                })
            elseif config.oxtarget then 
                local menu_options = {
                    {
                        name = 'rental_ped',
                        icon = 'fas fa-car',
                        label = 'Rent Vehicle',
                        onSelect = function()
                            TriggerEvent('bd-rentals:client:rentVehicle', k)
                        end
                    },
                    {
                        name = 'rental_return',
                        icon = 'fas fa-undo',
                        label = 'Return Vehicle',
                        onSelect = function()
                            TriggerServerEvent('bd-rentals:server:ReturnVehicle')
                        end
                    },
                }
                exports.ox_target:addBoxZone({
                    coords = v.coords, 
                    size = v.size,
                    rotation = v.coords.w,
                    debug = v.debug,
                    options = menu_options
                })
            end
        else 
            if config.qbtarget then 
                exports['qb-target']:AddTargetEntity(ped[k], {
                    options = {
                        {
                            icon = 'fas fa-car',
                            label = 'Rent Vehicle',
                            action = function()
                                TriggerEvent('bd-rentals:client:rentVehicle', k)
                            end,
                        },
                        {
                            icon = 'fas fa-undo',
                            label = 'Return Vehicle',
                            action = function()
                                TriggerServerEvent('bd-rentals:server:ReturnVehicle')
                            end,
                        },
                    },
                    distance = 2.0
                })
            elseif config.oxtarget then 
                local options = {
                    {
                        name = 'rental_ped',
                        icon = 'fas fa-car',
                        label = 'Rent Vehicle',
                        onSelect = function()
                            TriggerEvent('bd-rentals:client:rentVehicle', k)
                        end
                    },
                    {
                        name = 'rental_return',
                        icon = 'fas fa-undo',
                        label = 'Return Vehicle',
                        onSelect = function()
                            TriggerServerEvent('bd-rentals:server:ReturnVehicle')
                        end
                    },
                }
                exports.ox_target:addLocalEntity(ped[k], options)
                
            end
        end
    end
        
end)

RegisterNetEvent('bd-rentals:client:rentVehicle', function(k)

    local menu_options = {}

    for location, info in pairs(config.locations) do 
        if location == k then 
            for vehicle, details in pairs(info.vehicles) do 
                table.insert(menu_options, {
                    title = vehicle:gsub("^%l", string.upper),
                    description = '$' .. details.price,
                    icon = details.image,
                    image = details.image,
                    metadata = {
                        {label = 'Price', value = '$' .. details.price},
                    },
                    onSelect = function()
                        OpenDurationMenu(vehicle, details.price, location)
                    end
                })
            end
        end
    end 

    lib.registerContext({
        id = 'vehicle_rental',
        title = 'Vehicle Rental',
        options = menu_options,
    })

    lib.showContext('vehicle_rental')
end)

function OpenDurationMenu(vehicle, price, location)
    local duration_options = {}

    for _, duration in ipairs(config.rentalDurations) do
        table.insert(duration_options, {
            title = duration.label,
            icon = 'fas fa-clock',
            description = 'Vehicle auto-returns after this time',
            onSelect = function()
                TriggerServerEvent('bd-rentals:server:MoneyAmounts', vehicle, price, location, duration.minutes)
            end
        })
    end

    lib.registerContext({
        id = 'vehicle_rental_duration',
        title = 'Select Rental Duration',
        menu = 'vehicle_rental',
        options = duration_options,
    })

    lib.showContext('vehicle_rental_duration')
end

RegisterNetEvent('bd-rentals:client:SpawnVehicle', function(vehiclename, location, duration, price)
    local player = PlayerPedId()
    local vehicle = GetHashKey(vehiclename)
    RequestModel(vehicle)
    while not HasModelLoaded(vehicle) do
        Wait(10)
    end
    local rental = CreateVehicle(vehicle, config.locations[location].vehiclespawncoords.x, config.locations[location].vehiclespawncoords.y, config.locations[location].vehiclespawncoords.z, config.locations[location].vehiclespawncoords.w, true, false)
    local plate = GetVehicleNumberPlateText(rental)
    SetVehicleNumberPlateText(rental, "RENTAL")
    SetVehicleOnGroundProperly(rental)
    TaskWarpPedIntoVehicle(player, rental, -1) 
    SetVehicleEngineOn(vehicle, true, true)

    local netId = NetworkGetNetworkIdFromEntity(rental)
    SetNetworkIdCanMigrate(netId, true)

    TriggerServerEvent('bd-rentals:server:RentVehicle', vehiclename, plate, netId, duration, price)

    -- give keys 
    if QBCore then 
        TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(plate))
    end
        
    SetModelAsNoLongerNeeded(vehicle)
end)

RegisterNetEvent('bd-rentals:client:DeleteRentalVehicle', function(netId)
    local attempts = 0
    while not NetworkDoesEntityExistWithNetworkId(netId) and attempts < 50 do
        Wait(100)
        attempts = attempts + 1
    end

    if not NetworkDoesEntityExistWithNetworkId(netId) then return end

    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(vehicle) then return end

    if NetworkHasControlOfEntity(vehicle) then
        DeleteEntity(vehicle)
    else
        NetworkRequestControlOfEntity(vehicle)
        local waited = 0
        while not NetworkHasControlOfEntity(vehicle) and waited < 1000 do
            Wait(50)
            waited = waited + 50
        end
        DeleteEntity(vehicle)
    end
end)
