local Config = {}

Config.Version = 1
Config.Title = "HELIOS / STATION 07"
Config.InteractionRange = 13
Config.UpdateInterval = 0.25
Config.BroadcastInterval = 1
Config.GeneratorCapacity = 110
Config.SecurityCircuit = "A"
Config.VentilationCircuit = "B"
Config.AuxiliaryCircuit = "A"
Config.AuxiliaryDemand = 55
Config.FuelPerCan = 40
Config.FuelDrain = 0.045
Config.InitialContamination = 68
Config.PurgeRate = 2.8
Config.LeakRate = 0.065
Config.SafeContamination = 15
Config.HazardThreshold = 94
Config.HazardDamage = 3
Config.SafeZone = Vector3.new(0, 4, 31)
Config.SafeZoneRadius = 11
Config.ProfileStore = "HeliosProfiles_v1"
Config.SaveInterval = 40
Config.SessionLease = 150
Config.InventoryLimits = {Fuel = 2, Fuse = 3}
Config.Circuits = {
    A = {Name = "SECURITY", Capacity = 70, Demand = 42, Priority = 1, Initial = "Tripped"},
	B = {Name = "LIFE SUPPORT", Capacity = 60, Demand = 36, Priority = 2, Initial = "FuseMissing"},
	C = {Name = "LABORATORY", Capacity = 20, Demand = 10, Priority = 3, Initial = "Tripped"},
}
Config.Actions = {
    FuelSupply = {Label = "Collect fuel can", Duration = 0.6, Kind = "Supply", Item = "Fuel"},
    FuseSupply = {Label = "Collect spare fuse", Duration = 0.6, Kind = "Supply", Item = "Fuse"},
    Generator = {Label = "Refuel generator", Duration = 3.5, Kind = "Refuel", Item = "Fuel"},
    BreakerA = {Label = "Reset security circuit", Duration = 3, Kind = "Breaker", Circuit = "A"},
	BreakerB = {Label = "Replace life-support fuse", Duration = 4, Kind = "Fuse", Circuit = "B", Item = "Fuse"},
	BreakerC = {Label = "Reset laboratory circuit", Duration = 3, Kind = "Breaker", Circuit = "C"},
    LoadBank = {Label = "Toggle diagnostic load", Duration = 1, Kind = "Load"},
    Extraction = {Label = "Evacuate facility", Duration = 2, Kind = "Extract"},
    MissionConsole = {Label = "Start next shift", Duration = 2, Kind = "Restart"},
}

return table.freeze(Config)
