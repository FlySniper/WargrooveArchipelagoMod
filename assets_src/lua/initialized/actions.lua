local Events = require "initialized/events"
local Wargroove = require "wargroove/wargroove"
local UnitState = require "unit_state"
local Utils = require "utils"
local io = require "io"
local json = require "json"

local Actions = {}

function Actions.init()
  Events.addToActionsList(Actions)
end

function Actions.populate(dst)
    dst["ap_location_send"] = Actions.apLocationSend
    dst["ap_item_check"] = Actions.apItemCheck
    dst["ap_count_item"] = Actions.apCountItem
    dst["ap_victory"] = Actions.apVictory
    dst["ap_income_boost"] = Actions.apIncomeBoost
    dst["ap_co_defense_boost"] = Actions.apDefenseBoost
    dst["unit_random_co"] = Actions.unitRandomCO
    dst["unit_random_teleport"] = Actions.unitRandomTeleport
end

-- Local functions

local function findCentreOfLocation(location)
    local centre = { x = 0, y = 0 }
    for i, pos in ipairs(location.positions) do
        centre.x = centre.x + pos.x
        centre.y = centre.y + pos.y
    end
    centre.x = centre.x / #(location.positions)
    centre.y = centre.y / #(location.positions)

    return centre
end

local function findPlaceInLocation(location, unitClassId)
    local candidates = {}
    local centre = nil
    local positions = nil

    if location == nil then
        -- No location, use whole map
        local mapSize = Wargroove.getMapSize()
        positions = {}
        for x = 0, mapSize.x - 1 do
            for y = 0, mapSize.y - 1 do
                table.insert(positions, { x = x, y = y })
            end
        end
        centre = { x = math.floor(mapSize.x / 2), y = math.floor(mapSize.y / 2) }
    else
        positions = location.positions
        centre = findCentreOfLocation(location)
    end

    -- All candidates
    for i, pos in ipairs(positions) do
        if Wargroove.getUnitIdAt(pos) == -1 and Wargroove.canStandAt(unitClassId, pos) then
            local dx = pos.x - centre.x
            local dy = pos.y - centre.y
            local dist = dx * dx + dy * dy
            table.insert(candidates, { pos = pos, dist = dist })
        end
    end

    -- Sort candidates
    table.sort(candidates, function(a, b) return a.dist < b.dist end)
    return candidates
end

function Actions.apItemCheck(context)
    -- "Add ap item check"
    for k, v in pairs(Utils.items) do
        local f = io.open("AP\\AP_" .. tostring(v) .. ".item", "r")
        if f ~= nil then
            local itemCount = tonumber(f:read())
            if itemCount == nil then
                itemCount = 0
            end
            UnitState.setState(k, itemCount)
            io.close(f)
        else
            UnitState.setState(k, 0)
        end
    end
end

function Actions.apCountItem(context)
    -- "Add ap count item {0} and store into {1}"
    local itemId = context:getInteger(0)
    for k, v in pairs(Utils.items) do
        if v == itemId then
            local f = io.open("AP\\AP_" .. tostring(v) .. ".item", "r")
            if f ~= nil then
                local itemCount = tonumber(f:read())
                if itemCount == nil then
                    context:setMapCounter(1, 0)
                    io.close(f)
                    return
                end
                context:setMapCounter(1, itemCount)
                io.close(f)
                return
            else
                context:setMapCounter(1, 0)
                return
            end
        end
    end
    context:setMapCounter(1, 0)
    return
end


function Actions.apLocationSend(context)
    -- "Send ap Location ID {0}"
    local locationId = context:getInteger(0)
    local f = io.open("AP\\send" .. tostring(locationId), "w")
    f:write("")
    io.close(f)
end

function Actions.apVictory(context)
    -- "Send AP Victory"
    local locationId = context:getInteger(0)
    local f = io.open("AP\\victory", "w")
    f:write("")
    io.close(f)
end


function Actions.apIncomeBoost(context)
    -- "Read the income boost setting and apply it to player {0}"
    local playerId = context:getPlayerId(0)
    local f = io.open("AP\\AP_settings.json", "r")
    if f == nil then
        return
    end
    local content = f:read("*all")
    io.close(f)
    local item = io.open("AP\\AP_" .. tostring(52023) .. ".item", "r")
    local itemCount = 0
    if item ~= nil then
        itemCount = tonumber(item:read())
        io.close(item)
    end
    print("1 " .. tostring(content))
    local settings = json.parse(content)
    print(2)
    Wargroove.changeMoney(playerId, settings["income_boost"] * itemCount)
    print(3)
end

function Actions.apDefenseBoost(context)
    -- "Read the defense boost setting and stores it into {0}"
    local f = io.open("AP\\AP_settings.json", "r")
    if f == nil then
        return
    end
    local content = f:read("*all")
    io.close(f)
    local item = io.open("AP\\AP_" .. tostring(52024) .. ".item", "r")
    local itemCount = 0
    if item ~= nil then
        itemCount = tonumber(item:read())
        io.close(item)
    end
    local settings = json.parse(content)
    local units = Wargroove.getUnitsAtLocation(nil)
    for i, unit in ipairs(units) do
        if Wargroove.isHuman(unit.playerId) and unit.unitClass.isCommander then
            unit.damageTakenPercent = math.max(100 - (settings["co_defense_boost"] * itemCount), 1)
            Wargroove.updateUnit(unit)
        end
    end
end

function Actions.unitRandomCO(context)
    local playerId = context:getPlayerId(0)
    local units = Wargroove.getUnitsAtLocation(nil)
    for i, unit in ipairs(units) do
        if unit.playerId == playerId and unit.unitClass.isCommander and unit.unitClass.id ~= "commander_sedge" then
            local random = math.floor(Wargroove.pseudoRandomFromString(tostring(Wargroove.getOrderId() .. tostring(playerId).. tostring(unit.id))) * (18 - 1 + 1)) + 1
            unit.unitClassId = Utils.COs[random]
            Wargroove.updateUnit(unit)
            Wargroove.waitFrame()
            Wargroove.clearCaches()
        end
    end
end

function Actions.unitRandomTeleport(context)
    -- "Randomly Teleport all {0} owned by {1} from {2} to {3} (silent = {4})"
    local units = context:gatherUnits(1, 0, 2)
    local target = context:getLocation(3)
    local silent = context:getBoolean(4)

    for i, unit in ipairs(units) do
        local candidates = findPlaceInLocation(target, unit.unitClassId)
        local oldPos = unit.pos
        local numcandidates = #candidates
        if numcandidates > 0 then
            local random = math.floor(Wargroove.pseudoRandomFromString(tostring(Wargroove.getOrderId() .. tostring(unit.playerId).. tostring(unit.id))) * (numcandidates - 1 + 1)) + 1
            unit.pos = candidates[random].pos
        end

        if not unit.inTransport then
            if (not silent) and Wargroove.canCurrentlySeeTile(oldPos) then
                Wargroove.spawnMapAnimation(oldPos, 0, "fx/mapeditor_unitdrop")
                Wargroove.waitFrame()
                Wargroove.setVisibleOverride(unit.id, false)
            end

            Wargroove.updateUnit(unit)

            if (not silent) then
                Wargroove.waitTime(0.2)
                Wargroove.unsetVisibleOverride(unit.id)
            end

            if (not silent) and Wargroove.canCurrentlySeeTile(unit.pos) then
                Wargroove.trackCameraTo(unit.pos)
                Wargroove.spawnMapAnimation(unit.pos, 0, "fx/mapeditor_unitdrop")
                Wargroove.playMapSound("spawn", unit.pos)
                Wargroove.waitTime(0.2)
            end
        end
    end
end



return Actions
