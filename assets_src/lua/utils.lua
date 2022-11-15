local io = require "io"
local json = require "json"

local Utils = {}
Utils.items = {
    spearman = 52000,
    wagon = 52001,
    mage = 52002,
    archer = 52003,
    knight = 52004,
    ballista = 52005,
    giant = 52006,
    harpy = 52007,
    witch = 52008,
    dragon = 52009,
    balloon = 52010,
    travelboat = 52011,
    merman = 52012,
    turtle = 52013,
    harpoonship = 52014,
    warship = 52015,
    thief = 52016,
    rifleman = 52017,

    EasternBridges = 52018,
    SouthernWalls = 52019,
    FinalBridges = 52020,
    FinalWalls = 52021,
    FinalSickle = 52022,

    IncomeBoost = 52023,
    CommanderDefenseBoost = 52024,

    CherrystoneCommanders = 52025,
    FelheimCommanders = 52026,
    FloranCommanders = 52027,
    HeavensongCommanders = 52028,
    RequiemCommanders = 52029,
    OutlawCommanders = 52030,
}

Utils.COs = {
    "commander_caesar",
    "commander_darkmercia",
    "commander_elodie",
    "commander_emeric",
    "commander_greenfinger",
    "commander_koji",
    "commander_mercia",
    "commander_mercival",
    "commander_nuru",
    "commander_ragna",
    "commander_ryota",
    "commander_sedge",
    "commander_sigrid",
    "commander_tenri",
    "commander_twins",
    "commander_valder",
    "commander_vesper",
    "commander_wulfar"
}

Utils.locations = {}
Utils.locations["Humble Beginnings: Caesar"]=53001
Utils.locations["Humble Beginnings: Chest 1"]=53002
Utils.locations["Humble Beginnings: Chest 2"]=53003
Utils.locations["Humble Beginnings: Victory"]=53004
Utils.locations["Best Friendssss: Find Sedge"]=53005
Utils.locations["Best Friendssss: Victory"]=53006
Utils.locations["A Knight's Folly: Caesar"]=53007
Utils.locations["A Knight's Folly: Victory"]=53008
Utils.locations["Denrunaway: Chest"]=53009
Utils.locations["Denrunaway: Victory"]=53010
Utils.locations["Dragon Freeway: Victory"]=53011
Utils.locations["Deep Thicket: Find Sedge"]=53012
Utils.locations["Deep Thicket: Victory"]=53013
Utils.locations["Corrupted Inlet: Victory"]=53014
Utils.locations["Mage Mayhem: Caesar"]=53015
Utils.locations["Mage Mayhem: Victory"]=53016
Utils.locations["Endless Knight: Victory"]=53017
Utils.locations["Ambushed in the Middle: Victory (Blue)"]=53018
Utils.locations["Ambushed in the Middle: Victory (Green)"]=53019
Utils.locations["The Churning Sea: Victory"]=53020
Utils.locations["Frigid Archery: Light the Torch"]=53021
Utils.locations["Frigid Archery: Victory"]=53022
Utils.locations["Archery Lessons: Chest"]=53023
Utils.locations["Archery Lessons: Victory"]=53024
Utils.locations["Surrounded: Caesar"]=53025
Utils.locations["Surrounded: Victory"]=53026
Utils.locations["Darkest Knight: Victory"]=53027
Utils.locations["Robbed: Victory"]=53028
Utils.locations["Open Season: Caesar"]=53029
Utils.locations["Open Season: Victory"]=53030
Utils.locations["Doggo Mountain: Find all the Dogs"]=53031
Utils.locations["Doggo Mountain: Victory"]=53032
Utils.locations["Tenri's Fall: Victory"]=53033
Utils.locations["Master of the Lake: Victory"]=53034
Utils.locations["A Ballistas Revenge: Victory"]=53035
Utils.locations["Rebel Village: Victory (Pink)"]=53036
Utils.locations["Rebel Village: Victory (Red)"]=53037

function Utils.getLocationName(id)
    for k,v in pairs(Utils.locations) do
        if v == id then
            return k
        end
    end
    return ""
end

function Utils.getCommanderData()
    local f = io.open("AP\\commander.json", "r")
    if f == nil then
        -- Return Mercival and 0 starting groove in case the player closes the client. This prevents cheating
        return "commander_mercival", 0
    end
    local fileText = f:read("*all")
    local commanderData = json.parse(fileText)
    return commanderData["commander"], commanderData["starting_groove"]
end

return Utils