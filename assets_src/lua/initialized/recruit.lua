local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local OldRecruit = require "verbs/recruit"
local Utils = require "utils"
local UnitState = require "unit_state"

local Recruit = Verb:new()


function Recruit.init()
    OldRecruit.canExecuteWithTarget = Recruit.canExecuteWithTarget
end


function Recruit:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if strParam == nil or strParam == "" then
        return true
    end

    if Wargroove.isHuman(unit.playerId) then
        if strParam == "trebuchet" then
            return false
        end
        if unit.unitClass.id == "barracks" then
            for k, v in pairs(Utils.items) do
                if v <= 52006 then
                    local count = UnitState.getState(k)
                    if strParam == k and tonumber(count) > 0 then
                        local uc = Wargroove.getUnitClass(strParam)
                        return Wargroove.canStandAt(strParam, targetPos) and Wargroove.getMoney(unit.playerId) >= uc.cost
                    end
                end
            end
            local uc = Wargroove.getUnitClass(strParam)
            return (Wargroove.canStandAt(strParam, targetPos) and Wargroove.getMoney(unit.playerId) >= uc.cost) and (strParam == "dog" or strParam == "soldier")
        end
        if unit.unitClass.id == "tower" then
            for k, v in pairs(Utils.items) do
                if v > 52006 and v <= 52010 then
                    local count = UnitState.getState(k)
                    if strParam == k and tonumber(count) > 0 then
                        local uc = Wargroove.getUnitClass(strParam)
                        return Wargroove.canStandAt(strParam, targetPos) and Wargroove.getMoney(unit.playerId) >= uc.cost
                    end
                end
            end
            return false
        end
        if unit.unitClass.id == "port" then
            for k, v in pairs(Utils.items) do
                if v > 52010 and v <= 52015 then
                    local count = UnitState.getState(k)
                    if strParam == k and tonumber(count) > 0 then
                        local uc = Wargroove.getUnitClass(strParam)
                        return Wargroove.canStandAt(strParam, targetPos) and Wargroove.getMoney(unit.playerId) >= uc.cost
                    end
                end
            end
            return false
        end
        if unit.unitClass.id == "hideout" then
            for k, v in pairs(Utils.items) do
                if v > 52015 and v <= 52017 then
                    local count = UnitState.getState(k)
                    if strParam == k and tonumber(count) > 0 then
                        local uc = Wargroove.getUnitClass(strParam)
                        return Wargroove.canStandAt(strParam, targetPos) and Wargroove.getMoney(unit.playerId) >= uc.cost
                    end
                end
            end
            return false
        end
        return false
    end
    -- Check if this can recruit that type of unit
    local ok = false
    for i, uid in ipairs(unit.recruits) do
        if uid == strParam then
            ok = true
        end
    end
    if not ok then
        return false
    end

    -- Check if this player can recruit this type of unit
    if not Wargroove.canPlayerRecruit(unit.playerId, strParam) then
        return false
    end

    local uc = Wargroove.getUnitClass(strParam)
    return Wargroove.canStandAt(strParam, targetPos) and Wargroove.getMoney(unit.playerId) >= uc.cost
end


return Recruit
