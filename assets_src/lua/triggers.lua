local Events = require "wargroove/events"
local Wargroove = require "wargroove/wargroove"

local Triggers = {}

function Triggers.getRandomCOTrigger()
    local trigger = {}
    trigger.id =  "Randomize CO"
    trigger.recurring = "oncePerPlayer"
    trigger.players = { 1, 1, 1, 1, 1, 1, 1, 1 }
    trigger.conditions = {}
    trigger.actions = {}

    table.insert(trigger.conditions, { id = "start_of_turn", parameters = { } })
    table.insert(trigger.actions, { id = "unit_random_co", parameters = { "current" }  })
    
    return trigger
end

function Triggers.replaceProductionWithAP()
    local trigger = {}
    trigger.id =  "Replace Human Production with AP Structures"
    trigger.recurring = "repeat"
    trigger.players = { 1, 1, 1, 1, 1, 1, 1, 1 }
    trigger.conditions = {}
    trigger.actions = {}

    table.insert(trigger.actions, { id = "ap_replace_production", parameters = { "current" }  })

    return trigger
end

return Triggers