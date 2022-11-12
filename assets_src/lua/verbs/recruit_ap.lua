local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Utils = require "utils"
local UnitState = require "unit_state"
local OldTeleportBeam = require "verbs/groove_teleport_beam"

local RecruitAP = Verb:new()

local costMultiplier = 1

local defaultUnits = {"soldier", "dog"}

local function getCost(cost)
    return math.floor(cost * costMultiplier + 0.5)
end

function RecruitAP:getMaximumRange(unit, endPos)
    return 1
end

function RecruitAP:getTargetType()
    return "empty"
end

RecruitAP.classToRecruit = nil

function RecruitAP:getRecruitableTargets(unit)
    local allUnits = Wargroove.getAllUnitsForPlayer(unit.playerId, true)
    local recruitableUnits = {}
    for i, recruit in pairs(unit.recruits) do

        if not OldTeleportBeam.recruitsContain(self, recruitableUnits, recruit) then
            if Wargroove.isHuman(unit.playerId) and recruit ~= "dog" and recruit ~= "soldier" then

                for k, v in pairs(Utils.items) do
                    if v <= 52017 then
                        local count = UnitState.getState(k)
                        if recruit == k and tonumber(count) > 0 then
                            recruitableUnits[#recruitableUnits + 1] = recruit
                        end
                    end
                end
            else
                recruitableUnits[#recruitableUnits + 1] = recruit
            end
        end
    end

    if #recruitableUnits == 0 and unit.unitClassId == "barracks_ap" then
        recruitableUnits = defaultUnits
    end

    return recruitableUnits
end

function RecruitAP:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if RecruitAP.classToRecruit == nil then
        return true
    end

    if not self:canSeeTarget(targetPos) then
        return false
    end

    local classToRecruit = RecruitAP.classToRecruit
    if classToRecruit == nil then
        classToRecruit = strParam
    end

    local u = Wargroove.getUnitAt(targetPos)
    if (classToRecruit == "") then
        return u == nil
    end

    local uc = Wargroove.getUnitClass(classToRecruit)

    return (unit.x ~= targetPos.x or unit.y ~= targetPos.y) and (u == nil or unit.id == u.id) and Wargroove.canStandAt(classToRecruit, targetPos) and Wargroove.getMoney(unit.playerId) >= getCost(uc.cost)
end


function RecruitAP:preExecute(unit, targetPos, strParam, endPos)
    local recruitableUnits = RecruitAP:getRecruitableTargets(unit);
    Wargroove.openRecruitMenu(unit.playerId, unit.id, unit.pos, unit.unitClassId, recruitableUnits, costMultiplier);

    while Wargroove.recruitMenuIsOpen() do
        coroutine.yield()
    end

    RecruitAP.classToRecruit = Wargroove.popRecruitedUnitClass();

    if RecruitAP.classToRecruit == nil then
        return false, ""
    end

    Wargroove.selectTarget()

    while Wargroove.waitingForSelectedTarget() do
        coroutine.yield()
    end

    local target = Wargroove.getSelectedTarget()

    if (target == nil) then
        return false, ""
    end

    return true, RecruitAP.classToRecruit .. "," .. tostring(target.x) .. "," .. tostring(target.y)
end

function RecruitAP:execute(unit, targetPos, strParam, path)
    RecruitAP.classToRecruit = nil

    if strParam == "" then
        print("RecruitAP was not given a class to recruit.")
        return
    end

    local split = strParam:gmatch("([^,]+)")
    local unitClassStr = split()
    local targetPos = {x = split(), y = split()}

    local uc = Wargroove.getUnitClass(unitClassStr)
    Wargroove.changeMoney(unit.playerId, -uc.cost)
    Wargroove.spawnUnit(unit.playerId, targetPos, unitClassStr, true)
    if Wargroove.canCurrentlySeeTile(targetPos) then
        Wargroove.spawnMapAnimation(targetPos, 0, "fx/mapeditor_unitdrop")
        Wargroove.playMapSound("spawn", targetPos)
        Wargroove.playPositionlessSound("recruit")
    end
    Wargroove.notifyEvent("unit_recruit", unit.playerId)
    Wargroove.setMetaLocation("last_recruit", targetPos)

    strParam = ""
end

return RecruitAP