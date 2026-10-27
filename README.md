# RoDevs submission

the code for my Scripter application.

i made a co-op facility recovery game for the submission. get supplies, refuel the generator, repair the circuits and wait for the air to clear before evacuating.

## what it does

- inventory with carry limits
- timed repairs and refuelling
- equipment locks so two players can't work on the same thing at once
- cancellation if you walk too far away, without losing materials
- power demand and overloads
- ventilation and air toxicity
- evacuation and starting another shift
- saved escapes, repairs and best time

repairing a circuit doesn't automatically power it. the generator needs fuel, ventilation needs power, and the exit stays locked until the required circuits are powered and the air is safe.

## scripts

- **GridModel** handles power, overloads, air toxicity and exit conditions
- **InteractionService** checks actions, locks equipment and cancels interrupted actions
- **InventoryService** handles materials and carry limits
- **DataService** loads and saves player progress
- **WorldService** updates the equipment, lights and door
- **FacilityController** handles the HUD
- **CircuitView** builds the circuit list and picks repair objectives
- **Config** has the circuit settings and action definitions
- **Bootstrap** connects everything

## adding more stuff

in [the video](https://youtu.be/tBULAf-sEAo) (linked just in case), i add circuit C, a breaker and a lamp connected to it.

i add the circuit and repair action in Config, then set up the equipment. C shows up in the HUD automatically, and repairing it powers the lamp. no separate C logic needed in the simulation or HUD.

## testing

tested multiplayer using my PC and my A34 for the second account. it ran smoothly on the phone too.

i also checked that progress saves after leaving and rejoining. the extra clip at the end shows an action cancelling when i walk away, with the fuel can still in my inventory.
