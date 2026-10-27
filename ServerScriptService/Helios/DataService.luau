local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local DataService = {}
DataService.__index = DataService

local function clean(raw)
    raw = type(raw) == "table" and raw or {}
    local function number(value, maximum)
        if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
            return 0
        end
        return math.clamp(math.floor(value), 0, maximum)
    end
    return {
        Version = 1,
        Escapes = number(raw.Escapes, 1000000),
        Repairs = number(raw.Repairs, 10000000),
        BestTime = number(raw.BestTime, 86400),
    }
end

function DataService.new(config, notify, store)
    return setmetatable({
        Config = config,
        Notify = notify,
        Store = store or DataStoreService:GetDataStore(config.ProfileStore),
        Profiles = {},
        Closed = false,
    }, DataService)
end

function DataService:Load(player)
    local token = HttpService:GenerateGUID(false)
    local record = {Data = clean(nil), Token = token, Mode = "LOADING", Busy = true, Leaving = false}
    self.Profiles[player] = record
    local success, loaded
    for attempt = 1, 3 do
        success, loaded = pcall(function()
            return self.Store:UpdateAsync("u_" .. player.UserId, function(old)
                old = type(old) == "table" and old or {}
                local lease = old.Session
                if type(lease) == "table" and lease.Token ~= token and (tonumber(lease.Expires) or 0) > os.time() then
                    return nil
                end
                local data = clean(old)
                data.Session = {Token = token, Expires = os.time() + self.Config.SessionLease}
                return data
            end)
        end)
        if success then
            break
        end
        if attempt < 3 then
            task.wait(attempt)
        end
    end
    record.Busy = false
    if success and loaded then
        record.Data = clean(loaded)
        record.Mode = "SAVED"
    elseif success then
        record.Mode = "PROFILE BUSY"
    else
        record.Mode = "SESSION ONLY"
        warn("HELIOS: persistence unavailable; continuing with session progress.")
    end
    if record.Leaving or self.Closed then
        self:Save(player, true)
        self.Profiles[player] = nil
    end
    self.Notify(player)
end

function DataService:Save(player, release)
    local record = self.Profiles[player]
    if not record or record.Mode ~= "SAVED" or record.Busy then
        return false
    end
    record.Busy = true
    local payload = clean(record.Data)
    local owned = false
    local ok = pcall(function()
        self.Store:UpdateAsync("u_" .. player.UserId, function(old)
            owned = false
            if type(old) ~= "table" or type(old.Session) ~= "table" or old.Session.Token ~= record.Token then
                return nil
            end
            owned = true
            local data = clean(payload)
            if not release then
                data.Session = {Token = record.Token, Expires = os.time() + self.Config.SessionLease}
            end
            return data
        end)
    end)
    record.Busy = false
    if ok and not owned then
        record.Mode = "SESSION ONLY"
        self.Notify(player)
    elseif not ok then
        warn("HELIOS: profile save failed; retry scheduled.")
    end
    if record.Leaving and not release then
        self:Save(player, true)
        self.Profiles[player] = nil
    end
    return ok and owned
end

function DataService:Award(player, kind, seconds)
    local record = self.Profiles[player]
    if not record or record.Mode == "LOADING" then
        return false
    end
    if kind == "Repair" then
        record.Data.Repairs += 1
    elseif kind == "Escape" then
        record.Data.Escapes += 1
        local time = math.max(1, math.floor(seconds))
        if record.Data.BestTime == 0 or time < record.Data.BestTime then
            record.Data.BestTime = time
        end
        task.defer(function()
            self:Save(player, false)
        end)
    end
    self.Notify(player)
    return true
end

function DataService:Snapshot(player)
    local record = self.Profiles[player]
    local data = record and clean(record.Data) or clean(nil)
    data.Mode = record and record.Mode or "LOADING"
    return data
end

function DataService:RemovePlayer(player)
    local record = self.Profiles[player]
    if not record then
        return
    end
    record.Leaving = true
    if not record.Busy then
        self:Save(player, true)
        self.Profiles[player] = nil
    end
end

function DataService:Start()
    task.spawn(function()
        while not self.Closed do
            task.wait(self.Config.SaveInterval)
            if self.Closed then
                break
            end
            for player in pairs(self.Profiles) do
                task.spawn(function()
                    self:Save(player, false)
                end)
            end
        end
    end)
    game:BindToClose(function()
        self.Closed = true
        local remaining = 0
        for player in pairs(self.Profiles) do
            remaining += 1
            task.spawn(function()
                local started = os.clock()
                while self.Profiles[player] and self.Profiles[player].Busy and os.clock() - started < 8 do
                    task.wait(0.1)
                end
                self:Save(player, true)
                remaining -= 1
            end)
        end
        local deadline = os.clock() + 25
        while remaining > 0 and os.clock() < deadline do
            task.wait(0.1)
        end
    end)
end

return DataService
