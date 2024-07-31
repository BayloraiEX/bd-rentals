![Baylorai](https://github.com/BayloraiEX) 

**Join Discord for support**               | https://discord.gg/hya9t8XfH8

# Vehicle Rental 
- Customize vehicle and pricing options
- Add as many locations as you'd like (Each location can have different vehicles)
- Players receive rental papers with meta data displaying renter's name, vehicle, and licence plate (rented)

# Compatibility

**Requires:** ox_lib | ox_inventory 

**Frameworks:** QB | ESX

**Targets:** qb-target | ox_target 

# Installation:

1. add `rt-rentals` to your resources folder | Make sure folder is UNZIPPED!

2. `ensure rt-rentals` in server.cfg if necessary

3. Add `Rental Papers` item to inventory:

**FOR ox_inventory Add rentalpapers.png to /ox_inventory/web/images/**

In ox_inventory --> data --> items.lua add the following:

```lua
['rentalpapers'] = {
    label = "Rental Papers",
    weight = 0,
    stack = false,
    close = false,
    description = "Rental Papers",
    client = {
        image = "rentalpapers.png",
    },
},
```

**FOR QB Inventory Add rentalpapers.png to /qb-inventory/html/images**

In qb-core --> shared --> items.lua add the following:

```lua
rentalpapers                 = { name = 'rentalpapers',          label = 'Rental Papers',         weight = 0,       type = 'item',      image = 'rentalpapers.png',      unique = false,  useable = true,  shouldClose = true, description = 'Rental Papers'},
```

4. Restart server

5. Enjoy!
