local Wargroove = require "wargroove/wargroove"
local Events = require "wargroove/events"
local UnitState = require "unit_state"
local Utils = require "utils"
local io = require "io"

local Conditions = {}

-- This is called by the game when the map is loaded.
function Conditions.init()
  Events.addToConditionsList(Conditions)
end

function Conditions.populate(dst)
    dst["ap_has_item"] = Conditions.apHasItem
end

function Conditions.apHasItem(context)
    -- "Add ap has item {0} of count {1} {2} current count"
    local itemId = context:getInteger(0)
    local itemExpectedCount = context:getInteger(1)
    local op = context:getOperator(2)
    for k, v in pairs(Utils.items) do
        if v == itemId then
            local f = io.open("AP\\AP_" .. tostring(v) .. ".item", "r")
            if f ~= nil then
                itemCount = tonumber(f:read())
                if itemCount == nil then
                    io.close(f)
                    return false
                end
                io.close(f)
                return op(itemCount, itemExpectedCount)
            else
                return false
            end
        end
    end
    return false
end

return Conditions
