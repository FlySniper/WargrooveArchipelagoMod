local Events = require "initialized/events"
local Wargroove = require "wargroove/wargroove"
local UnitState = require "unit_state"
local Utils = require "utils"
local io = require "io"
local json = require "json"
local prng = require "PRNG"

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
    dst["ap_commander_defense_boost"] = Actions.apDefenseBoost
    dst["ap_prng_seed_num"] = Actions.apPRNGSeedNumber
    dst["ap_random"] = Actions.apRandom
    dst["unit_random_teleport"] = Actions.unitRandomTeleport
    dst["location_unit_random_teleport"] = Actions.locationRandomTeleportToUnit
    dst["eliminate"] = Actions.eliminate

    -- Unlisted actions
    dst["ap_replace_production"] = Actions.replaceProduction
    dst["unit_random_co"] = Actions.unitRandomCO
    dst["ap_set_co_groove"] = Actions.apSetCOGroove
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
        local print_file_item = io.open("AP\\AP_" .. tostring(v) .. ".item.print", "r+")
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
        if print_file_item ~= nil then
            local print_text = print_file_item:read()
            if print_text ~= nil and print_text ~= "" then
                Wargroove.showMessage(print_text)
            end
            io.close(print_file_item)

            local print_file_clear = io.open("AP\\AP_" .. tostring(v) .. ".item.print", "w+")
            io.close(print_file_clear)
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
    Wargroove.showMessage("Discovered location (" .. Utils.getLocationName(locationId) .. ")")
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
    local item = io.open("AP\\AP_" .. tostring(52023) .. ".item", "r")
    local itemValue = 0
    if item ~= nil then
        itemValue = tonumber(item:read())
        io.close(item)
    end
    Wargroove.changeMoney(playerId, itemValue)
end

function Actions.apDefenseBoost(context)
    -- "Read the defense boost setting and stores it into {0}"
    local item = io.open("AP\\AP_" .. tostring(52024) .. ".item", "r")
    local itemValue = 0
    if item ~= nil then
        itemValue = tonumber(item:read())
        io.close(item)
    end
    local units = Wargroove.getUnitsAtLocation(nil)
    for i, unit in ipairs(units) do
        if Wargroove.isHuman(unit.playerId) and unit.unitClass.isCommander then
            unit.damageTakenPercent = math.max(100 - (itemValue), 1)
            Wargroove.updateUnit(unit)
        end
    end
end

function Actions.unitRandomCO(context)
    local playerId = context:getPlayerId(0)
    local units = Wargroove.getUnitsAtLocation(nil)
    for i, unit in ipairs(units) do
        if unit.unitClass.isCommander and unit.unitClass.id ~= "commander_sedge" and unit.playerId ~= -1 then
            --local random = math.floor(Wargroove.pseudoRandomFromString(tostring(Wargroove.getOrderId() .. tostring(playerId).. tostring(unit.id))) * (18 - 1 + 1)) + 1
            local commander, starting_groove = Utils.getCommanderData()
            if commander ~= "seed" and Wargroove.isHuman(unit.playerId) then
                unit.unitClassId = commander
            else
                local random = (prng.get_random_32() % 18) + 1
                unit.unitClassId = Utils.COs[random]
            end
            Wargroove.updateUnit(unit)
            Wargroove.waitFrame()
            Wargroove.clearCaches()
        end
    end
end

function Actions.apSetCOGroove(context)
    local playerId = context:getPlayerId(0)
    local units = Wargroove.getUnitsAtLocation(nil)
    for i, unit in ipairs(units) do
        if unit.playerId == playerId and unit.unitClass.isCommander and unit.unitClass.id ~= "commander_sedge" then
            --local random = math.floor(Wargroove.pseudoRandomFromString(tostring(Wargroove.getOrderId() .. tostring(playerId).. tostring(unit.id))) * (18 - 1 + 1)) + 1
            local commander, starting_groove = Utils.getCommanderData()
            if commander ~= "seed" and Wargroove.isHuman(unit.playerId) then
                unit.grooveCharge = starting_groove
                Wargroove.updateUnit(unit)
            end
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
            -- local random = math.floor(Wargroove.pseudoRandomFromString(tostring(Wargroove.getOrderId() .. tostring(unit.playerId).. tostring(unit.id))) * (numcandidates - 1 + 1)) + 1
            local random = (prng.get_random_32() % numcandidates) + 1
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

function Actions.locationRandomTeleportToUnit(context)
    -- "Randomly Move location {0} to {1} owned by {2} at {3}."
    local location = context:getLocation(0)
    local units = context:gatherUnits(2, 1, 3)
    local num_units = #units
    if num_units == 0 then
       return
    end
    local random = (prng.get_random_32() % num_units) + 1
    local unit = units[random]
    if (unit.inTransport) then
        local transport = Wargroove.getUnitById(unit.transportedBy)
        Wargroove.moveLocationTo(location.id, transport.pos)
    else
        Wargroove.moveLocationTo(location.id, unit.pos)
    end
end

local function replaceProductionStructure(playerId, unit, productionClassStr, productionApClassStr)

    if unit.playerId == playerId and Wargroove.isHuman(unit.playerId) and unit.unitClass.id == productionClassStr then
        unit.unitClassId = productionApClassStr
        Wargroove.updateUnit(unit)
        Wargroove.waitFrame()
        Wargroove.clearCaches()
    end
    if Wargroove.isNeutral(unit.playerId) and unit.unitClass.id == productionApClassStr then
        unit.unitClassId = productionClassStr
        Wargroove.updateUnit(unit)
        Wargroove.waitFrame()
        Wargroove.clearCaches()
    end
    if unit.playerId == playerId and not Wargroove.isHuman(unit.playerId) and unit.unitClass.id == productionApClassStr then
        unit.unitClassId = productionClassStr
        Wargroove.updateUnit(unit)
        Wargroove.waitFrame()
        Wargroove.clearCaches()
    end
end

function Actions.replaceProduction(context)
    local playerId = context:getPlayerId(0)
    local units = Wargroove.getUnitsAtLocation(nil)
    for i, unit in ipairs(units) do
        replaceProductionStructure(playerId, unit, "barracks", "barracks_ap")
        replaceProductionStructure(playerId, unit, "tower", "tower_ap")
        replaceProductionStructure(playerId, unit, "port", "port_ap")
        replaceProductionStructure(playerId, unit, "hideout", "hideout_ap")
    end
end

function Actions.apPRNGSeedNumber(context)
    -- "Seed our unique PRNG algorithm"
    local seedId = context:getInteger(0)
    local seedFile = io.open("AP\\seed" .. tostring(seedId), "r")
    local seed = 0
    if seedFile ~= nil then
        seed = tonumber(seedFile:read())
        io.close(seedFile)
    end
    prng.set_seed(seed)
end

function Actions.apRandom(context)
    -- "Counter {0}: Set to a random number between {1} and {2} (inclusive)."
    local counterId = context:getInteger(0)
    local min = context:getInteger(1)
    local max = context:getInteger(2)

    local value = math.floor((prng.get_random_32() % (max - min + 1)) + min)

    context:setMapCounter(0, value)
end

function Actions.eliminate(context)
    local playerId = context:getPlayerId(0)
    Wargroove.eliminate(playerId)
    if Wargroove.isHuman(playerId) and Wargroove.getCurrentPlayerId() ~= playerId then
        print("Deathlink Sent")
        local f = io.open("AP\\deathLinkSend", "w+")
        f:write("to reach the enemy stronghold")
        io.close(f)
    end
end

return Actions
