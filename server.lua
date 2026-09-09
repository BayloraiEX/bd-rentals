local QBCore = GetResourceState('qb-core') == 'started' and exports['qb-core']:GetCoreObject()
local ESX = GetResourceState('es_extended') == 'started' and exports.es_extended:getSharedObject()

local ActiveRentals = {}

local function PlayerName(src)
    if QBCore then 
        local Player = QBCore.Functions.GetPlayer(src)
        return Player.PlayerData.charinfo.firstname..' '..Player.PlayerData.charinfo.lastname
    elseif ESX then 
        local Player = ESX.GetPlayerFromId(src)
        local first, last
        if Player.get and Player.get('firstName') and Player.get('lastName') then
            first = Player.get('firstName')
            last = Player.get('lastName')
        else
            local name = MySQL.Sync.fetchAll('SELECT `firstname`, `lastname` FROM `users` WHERE `identifier`=@identifier', { ['@identifier'] = ESX.GetIdentifier(source) })
            first, last = name[1]?.firstname or ESX.GetPlayerName(source), name[1]?.lastname or ''
        end
        return first..' '..last
    end
end

local function GivePlayerMoney(src, amount)
    amount = tonumber(amount) or 0
    if amount <= 0 then return end
    if QBCore then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            Player.Functions.AddMoney('bank', amount)
        end
    elseif ESX then
        local Player = ESX.GetPlayerFromId(src)
        if Player then
            Player.addAccountMoney('bank', amount)
        end
    end
end

local function RemoveRentalPapers(src)
    if config.InventorySystem == 'ox' then
        exports.ox_inventory:RemoveItem(src, 'rentalpapers', 1)
    elseif config.InventorySystem == 'qb' then
        exports['qb-inventory']:RemoveItem(src, 'rentalpapers', 1)
        TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items['rentalpapers'], 'remove', 1)
    end
end

local function ExpireRental(src, netId)
    local rental = ActiveRentals[src]
    if not rental or rental.netId ~= netId then return end

    TriggerClientEvent('bd-rentals:client:DeleteRentalVehicle', src, rental.netId)
    RemoveRentalPapers(src)

    local refund = math.floor((rental.price or 0) * config.expireRefundPercent + 0.5)
    GivePlayerMoney(src, refund)

    TriggerClientEvent('ox_lib:notify', src, {
        id = 'rental_expired',
        description = 'Your rental period has ended. The vehicle has been reclaimed. $'..refund..' refunded to your bank.',
        position = 'center-right',
        icon = 'clock',
        iconColor = '#C53030'
    })

    ActiveRentals[src] = nil
end

RegisterNetEvent('bd-rentals:server:RentVehicle', function(vehicle, plate, netId, duration, price)
    local src = source
    local player_name = PlayerName(src)
    if config.InventorySystem == 'ox' then
        exports.ox_inventory:AddItem(src, 'rentalpapers', 1, 
            {description = 'Owner: '..player_name..' | Plate: RENTAL | Vehicle: '..vehicle:gsub("^%l", string.upper)}
        )
    elseif config.InventorySystem == 'qb' then
        exports['qb-inventory']:AddItem(src, 'rentalpapers', 1, false, false)
        TriggerClientEvent('qb-inventory:client:ItemBox', source, QBCore.Shared.Items['rentalpapers'], 'add', 1)
    end

    ActiveRentals[src] = {
        netId = netId,
        vehicle = vehicle,
        plate = plate,
        price = tonumber(price) or 0,
    }

    if duration and tonumber(duration) and tonumber(duration) > 0 then
        local durationMs = tonumber(duration) * 60000
        SetTimeout(durationMs, function()
            ExpireRental(src, netId)
        end)
    end
end)

RegisterNetEvent('bd-rentals:server:ReturnVehicle', function()
    local src = source
    local rental = ActiveRentals[src]

    if not rental then
        TriggerClientEvent('ox_lib:notify', src, {
            id = 'no_active_rental',
            description = 'You do not have a rental vehicle to return.',
            position = 'center-right',
            icon = 'ban',
            iconColor = '#C53030'
        })
        return 
    end

    TriggerClientEvent('bd-rentals:client:DeleteRentalVehicle', src, rental.netId)
    RemoveRentalPapers(src)

    local refund = math.floor((rental.price or 0) * config.returnRefundPercent + 0.5)
    GivePlayerMoney(src, refund)

    TriggerClientEvent('ox_lib:notify', src, {
        id = 'rental_returned',
        description = 'Vehicle returned successfully. $'..refund..' refunded to your bank.',
        position = 'center-right',
        icon = 'car',
        iconColor = 'white'
    })

    ActiveRentals[src] = nil
end)

RegisterNetEvent('bd-rentals:server:MoneyAmounts', function(vehiclename, price, location, duration)
    local src = source
    local moneytype = 'bank'
    local price = tonumber(price)
    local bank 
    local cash
    if QBCore then 
        local Player = QBCore.Functions.GetPlayer(src)
        bank = Player.PlayerData.money.bank
        cash = Player.PlayerData.money.cash
    elseif ESX then 
        local Player = ESX.GetPlayerFromId(src)
        bank = Player.getAccount('bank').money
        cash = Player.getAccount('money').money
    end

    if bank < price then 
        moneytype = 'cash'
        if cash < price then 
            TriggerClientEvent('ox_lib:notify', src, {
                id = 'not_enough_money',
                description = 'You don\'t have enough money to rent this vehicle.',
                position = 'center-right',
                icon = 'ban',
                iconColor = '#C53030'
            })
            return 
        end    
    end

    if QBCore then 
        local Player = QBCore.Functions.GetPlayer(src)
        Player.Functions.RemoveMoney(moneytype, price)
    elseif ESX then
        local Player = ESX.GetPlayerFromId(src)
        if moneytype == 'cash' then
            Player.removeMoney(price)
        elseif moneytype == 'bank' then
            Player.removeAccountMoney('bank', price)
        end
    end
    TriggerClientEvent('ox_lib:notify', src, {
        id = 'rental_success',
        description = vehiclename:gsub("^%l", string.upper)..' rented for $'..price..'.',
        position = 'center-right',
        icon = 'car',
        iconColor = 'white'
    })
    TriggerClientEvent('bd-rentals:client:SpawnVehicle', src, vehiclename, location, duration, price)
end)

AddEventHandler('playerDropped', function()
    local src = source
    if ActiveRentals[src] then
        ActiveRentals[src] = nil
    end
end)

-- Version Check from https://github.com/CodineDev/cdn-fuel

local updatePath
local resourceName

CheckVersion = function(err, response, headers)
    local curVersion = LoadResourceFile(GetCurrentResourceName(), "version")
	if response == nil then print("^1"..resourceName.." check for updates failed ^7") return end
    if curVersion ~= nil and response ~= nil then
		if curVersion == response then Color = "^2" else Color = "^1" end
        print("\n^1----------------------------------------------------------------------------------^7")
        print(resourceName.."'s latest version is: ^2"..response.."!\n^7Your current version: "..Color..""..curVersion.."^7!\nIf needed, update from https://github.com"..updatePath.."")
        print("^1----------------------------------------------------------------------------------^7")
    end
end

CreateThread(function()
	updatePath = "/BayloraiEX/bd-rentals"
	resourceName = "bd-rentals ("..GetCurrentResourceName()..")"
	PerformHttpRequest("https://raw.githubusercontent.com"..updatePath.."/master/version", CheckVersion, "GET")
end)
