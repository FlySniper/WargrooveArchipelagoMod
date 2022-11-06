local Events = require "wargroove/events"
local Wargroove = require "wargroove/wargroove"

local Triggers = {}

function Triggers.getSpawnTrigger(referenceTrigger)
    local trigger = {}
    trigger.id =  "AW Fire Spawn Trigger"
    trigger.recurring = "oncePerPlayer"
    trigger.players = referenceTrigger.players
    trigger.conditions = {}
    trigger.actions = {}
    
    table.insert(trigger.conditions, { id = "player_turn", parameters = { "current" } })
    table.insert(trigger.conditions, { id = "start_of_turn", parameters = { } })
    table.insert(trigger.actions, { id = "aw_fire_spawn", parameters = { "current" }  })
    
    return trigger
end

function Triggers.getVisionTrigger(referenceTrigger)
    local trigger = {}
    trigger.id =  "AW Fire Vision Trigger"
    trigger.recurring = "repeat"
    trigger.players = referenceTrigger.players
    trigger.conditions = {}
    trigger.actions = {}
    
    table.insert(trigger.conditions, { id = "player_turn", parameters = { "current" } })
    table.insert(trigger.conditions, { id = "start_of_turn", parameters = { } })
    table.insert(trigger.actions, { id = "aw_fire_vision", parameters = { "current" }  })
    
    return trigger
end

return Triggers