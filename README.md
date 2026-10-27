# RoDevs-Submission
The work i'll submit to apply for the Scripter role
# HELIOS / Station 07

a small co-op facility recovery game i made in Roblox.

get fuel and spare fuses, restore the circuits, clear the air and evacuate. the systems depend on each other, so repairing something doesn't automatically mean it has power.

## what's in here

- server-controlled inventory and timed interactions
- equipment locks so two players can't use the same machine at once
- actions cancel if you walk out of range, without taking your materials
- power demand, overloads and ventilation
- evacuation conditions and shift resets
- saved escapes, repairs and best time

## scripts

- **GridModel** handles the power simulation and evacuation conditions
- **InteractionService** checks actions, locks equipment and handles cancellation
- **InventoryService** handles materials and carry limits
- **DataService** loads and saves progress using Roblox DataStores
- **WorldService** updates the equipment, lights and door
- **FacilityController** handles the client HUD
- **CircuitView** builds the circuit list and repair objectives
- **Config** contains the circuit definitions, actions and settings
- **Bootstrap** connects everything

## expansion

the video shows me adding circuit C, its breaker and a connected lamp.

the HUD picks up the new circuit automatically. the existing repair and power systems handle it without adding separate logic for C.

## testing

tested multiplayer on PC and my Samsung Galaxy A34. gameplay ran smoothly on the phone.

also checked that saved progress carries over after leaving and rejoining.
