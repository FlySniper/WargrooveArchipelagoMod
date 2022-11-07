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

return Actions
